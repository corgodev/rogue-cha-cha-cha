using Godot;

public partial class CreepField : Node2D
{
    private static readonly Shader CreepDitherShader = GD.Load<Shader>(
        "res://src/gameplay/creep/creep_dither.gdshader"
    );

    [Export] public Color CreepColor { get; set; } = new(0.65f, 0.2f, 0.65f);
    [Export] public Texture2D DitherBrush { get; set; }
    [Export(PropertyHint.Range, "1,6,1")] public int DitherBrushCount { get; set; } = 6;
    [Export] public float DitherDriftSpeed { get; set; } = 4.0f;
    [Export] public float Brush0DriftMultiplier { get; set; } = 1.0f;
    [Export] public float Brush1DriftMultiplier { get; set; } = 1.0f;
    [Export] public float Brush2DriftMultiplier { get; set; } = 1.0f;
    [Export] public float Brush3DriftMultiplier { get; set; } = 1.0f;
    [Export] public float Brush4DriftMultiplier { get; set; } = 1.0f;
    [Export] public float Brush5DriftMultiplier { get; set; } = 1.0f;

    private Image _image;
    private ImageTexture _texture;
    private Sprite2D _view;

    private void InitializeView()
    {
        _image = Image.CreateEmpty(_grid.Size.X, _grid.Size.Y, false, Image.Format.Rgba8);
        _image.Fill(Colors.Transparent);
        _texture = ImageTexture.CreateFromImage(_image);

        _view = new Sprite2D
        {
            Texture = _texture,
            Centered = false,
            ZIndex = -1,
            TextureFilter = CanvasItem.TextureFilterEnum.Nearest,
            RegionEnabled = true,
            RegionRect = new Rect2(Vector2.Zero, (Vector2)WorldSize / CellSize),
            Position = LocalBounds().Position,
            Scale = Vector2.One * CellSize,
        };

        if (DitherBrush != null)
        {
            var material = new ShaderMaterial { Shader = CreepDitherShader };
            material.SetShaderParameter("brush_texture", DitherBrush);
            material.SetShaderParameter("world_size", (Vector2)WorldSize);
            material.SetShaderParameter("cell_size", CellSize);
            material.SetShaderParameter("drift_speed", DitherDriftSpeed);
            material.SetShaderParameter("brush_count", (float)DitherBrushCount);
            material.SetShaderParameter("brush_0_drift_multiplier", Brush0DriftMultiplier);
            material.SetShaderParameter("brush_1_drift_multiplier", Brush1DriftMultiplier);
            material.SetShaderParameter("brush_2_drift_multiplier", Brush2DriftMultiplier);
            material.SetShaderParameter("brush_3_drift_multiplier", Brush3DriftMultiplier);
            material.SetShaderParameter("brush_4_drift_multiplier", Brush4DriftMultiplier);
            material.SetShaderParameter("brush_5_drift_multiplier", Brush5DriftMultiplier);
            _view.Material = material;
        }

        AddChild(_view);
    }

    private void RefreshCreep()
    {
        foreach (var index in _grid.Active)
        {
            var color = CreepColor;
            color.A *= 1.0f - Mathf.Exp(-_grid.Mass[index] / (CellSize * CellSize));
            _image.SetPixel(index % _grid.Width, index / _grid.Width, color);
        }
        _texture.Update(_image);
    }
}
