using Godot;

[Tool]
public partial class CreepField : Node2D
{
    public override void _Draw()
    {
        if (Engine.IsEditorHint())
        {
            DrawRect(LocalBounds(), new Color(0.7f, 0.3f, 0.9f), false, 2.0f);
        }
    }
}