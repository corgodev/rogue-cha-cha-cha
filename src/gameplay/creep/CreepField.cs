using System;
using Godot;
using System.Collections.Generic;

[GlobalClass]
public partial class CreepField : Node2D
{
    [Export] public Vector2I WorldSize { get; set; } = new(5760, 3240);
    [Export] public float CellSize { get; set; } = 13.0f;
    [Export] public float SpreadingRate { get; set; } = 0.5f;
    [Export] public float StepSeconds { get; set; } = 0.5f;
    [Export] public byte[] BlockedCells { get; set; } = Array.Empty<byte>();

    public int ActiveCellCount => _grid?.Active.Count ?? 0;
    public double LastStepMs { get; private set; }

    private Grid _grid;
    private float _producedMass;
    private float _accumulator;
    private readonly List<Node2D> _sources = new();

    public Rect2 LocalBounds()
    {
        var size = (Vector2)WorldSize;
        return new Rect2(-size * 0.5f, size);
    }


    public void RegisterSource(Node2D source)
    {
        if (!_sources.Contains(source))
            _sources.Add(source);
    }

    public void UnregisterSource(Node2D source) => _sources.Remove(source);

    public override void _Ready()
    {
        if (Engine.IsEditorHint())
        {
            SetProcess(false);
            return;
        }

        InitializeCreep();
        InitializeView();
    }

    public void InitializeCreep()
    {
        if (CellSize <= 0.0f || WorldSize.X <= 0 || WorldSize.Y <= 0)
            throw new InvalidOperationException("CellSize and WorldSize must be positive.");

        var gridSize = new Vector2I(
            Mathf.CeilToInt(WorldSize.X / CellSize),
            Mathf.CeilToInt(WorldSize.Y / CellSize)
        );
        var count = gridSize.X * gridSize.Y;
        if (BlockedCells.Length == 0)
            BlockedCells = new byte[count];
        if (BlockedCells.Length != count)
            throw new InvalidOperationException("Blocked mask must match the grid size.");
        _grid = new Grid(gridSize, BlockedCells);
        _producedMass = 0.0f;
        _accumulator = 0.0f;
    }

    public override void _Process(double delta)
    {
        if (Engine.IsEditorHint() || StepSeconds <= 0.0f)
            return;

        _accumulator = Mathf.Min(_accumulator + (float)delta, StepSeconds * 3.0f);
        var changed = false;
        while (_accumulator >= StepSeconds)
        {
            _accumulator -= StepSeconds;
            StepCreep(StepSeconds);
            changed = true;
        }
        if (changed)
            RefreshCreep();
    }

    public void StepCreep(float dt)
    {
        if (dt < 0.0f || float.IsNaN(dt) || float.IsInfinity(dt))
            throw new ArgumentOutOfRangeException(nameof(dt));

        var started = Time.GetTicksUsec();
        foreach (var source in _sources)
        {
            if (!GodotObject.IsInstanceValid(source) || !source.IsInsideTree())
                continue;

            var point = source.Call("emission_position").AsVector2();
            if (!LocalBounds().HasPoint(ToLocal(point)))
                continue;

            var cell = WorldToCell(point);
            if (!_grid.IsValid(cell))
                continue;

            var index = _grid.IndexOf(cell);
            if (_grid.Blocked[index] != 0)
                continue;

            var amount = Mathf.Max(source.Get("production_rate").AsSingle(), 0.0f) * dt;
            if (amount <= 0.0f)
                continue;

            _grid.ActivateCell(index);
            _grid.Mass[index] += amount;
            _producedMass += amount;
        }

        var rate = Mathf.Max(SpreadingRate, 0.0f) * dt;
        var donorCount = _grid.Active.Count;
        for (var slot = 0; slot < donorCount; slot++)
        {
            var index = _grid.Active[slot];
            if (_grid.Blocked[index] != 0 || _grid.Mass[index] <= 0.0f)
                continue;

            var requested = 0.0f;
            for (var direction = 0; direction < 4; direction++)
            {
                var neighbor = _grid.Neighbor(index, direction);
                if (neighbor >= 0 && _grid.Blocked[neighbor] == 0)
                    requested += Mathf.Max(_grid.Mass[index] - _grid.Mass[neighbor], 0.0f) * rate;
            }
            if (requested <= 0.0f)
                continue;

            var factor = Mathf.Min(1.0f, _grid.Mass[index] / requested);
            for (var direction = 0; direction < 4; direction++)
            {
                var neighbor = _grid.Neighbor(index, direction);
                if (neighbor < 0 || _grid.Blocked[neighbor] != 0)
                    continue;

                var flow = Mathf.Max(_grid.Mass[index] - _grid.Mass[neighbor], 0.0f) * rate * factor;
                if (flow <= 0.0f)
                    continue;

                _grid.ActivateCell(neighbor);
                _grid.Changes[index] -= flow;
                _grid.Changes[neighbor] += flow;
            }
        }

        foreach (var index in _grid.Active)
        {
            _grid.Mass[index] = Mathf.Max(0.0f, _grid.Mass[index] + _grid.Changes[index]);
            _grid.Changes[index] = 0.0f;
        }
        LastStepMs = (Time.GetTicksUsec() - started) / 1000.0;
    }

    public Vector2I WorldToCell(Vector2 worldPosition)
    {
        var local = ToLocal(worldPosition) - LocalBounds().Position;
        return new Vector2I(
            Mathf.FloorToInt(local.X / CellSize),
            Mathf.FloorToInt(local.Y / CellSize)
        );
    }

    public float DensityAt(Vector2 worldPosition)
    {
        if (!LocalBounds().HasPoint(ToLocal(worldPosition)))
            return 0.0f;
        var cell = WorldToCell(worldPosition);
        if (!_grid.IsValid(cell))
            return 0.0f;
        return _grid.Mass[_grid.IndexOf(cell)] / (CellSize * CellSize);
    }

    public void SetCellBlocked(Vector2I cell, bool blocked = true)
    {
        if (!_grid.IsValid(cell))
            throw new ArgumentOutOfRangeException(nameof(cell));
        _grid.Blocked[_grid.IndexOf(cell)] = blocked ? (byte)1 : (byte)0;
    }

    public float TotalMass() => _grid.TotalMass();

}
