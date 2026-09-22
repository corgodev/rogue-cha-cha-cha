using System;
using System.Collections.Generic;
using Godot;

/// <summary>Dense creep storage with a sparse list of cells that have become active.</summary>
public sealed class Grid
{
    private readonly byte[] _known;

    public Vector2I Size { get; }
    public int Width => Size.X;
    public int Count => Mass.Length;
    public float[] Mass { get; }
    public float[] Changes { get; }
    public byte[] Blocked { get; }
    public List<int> Active { get; }

    public Grid(Vector2I size, byte[] blocked)
    {
        if (size.X <= 0 || size.Y <= 0)
            throw new ArgumentOutOfRangeException(nameof(size));

        var count = checked(size.X * size.Y);
        if (blocked == null || blocked.Length != count)
            throw new ArgumentException("Blocked mask must match the grid size.", nameof(blocked));

        Size = size;
        Mass = new float[count];
        Changes = new float[count];
        Blocked = blocked;
        Active = new List<int>();
        _known = new byte[count];
    }

    public bool IsValid(Vector2I cell) =>
        (uint)cell.X < (uint)Size.X && (uint)cell.Y < (uint)Size.Y;

    public int IndexOf(Vector2I cell) => cell.X + cell.Y * Size.X;

    public void ActivateCell(int index)
    {
        if (_known[index] != 0)
            return;

        _known[index] = 1;
        Active.Add(index);
    }

    public int Neighbor(int index, int direction)
    {
        return direction switch
        {
            0 when index % Size.X != 0 => index - 1,
            1 when index % Size.X != Size.X - 1 => index + 1,
            2 when index >= Size.X => index - Size.X,
            3 when index < Count - Size.X => index + Size.X,
            _ => -1,
        };
    }

    public float TotalMass()
    {
        var total = 0.0f;
        foreach (var index in Active)
            total += Mass[index];
        return total;
    }
}
