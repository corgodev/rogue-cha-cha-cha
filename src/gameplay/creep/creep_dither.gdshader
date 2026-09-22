shader_type canvas_item;
render_mode unshaded;

// TEXTURE is CreepField's generated density image. Its alpha is the creep mask.
// brush_texture is a horizontal atlas of equally-sized brush tiles.
uniform sampler2D brush_texture : source_color, filter_nearest, repeat_disable;
uniform vec2 world_size = vec2(5760.0, 3240.0);
uniform float cell_size = 13.0;
uniform float drift_speed = 4.0; // World pixels per second; positive moves right.
uniform float brush_count = 6.0;
uniform float brush_0_drift_multiplier = 1.0;
uniform float brush_1_drift_multiplier = 1.0;
uniform float brush_2_drift_multiplier = 1.0;
uniform float brush_3_drift_multiplier = 1.0;
uniform float brush_4_drift_multiplier = 1.0;
uniform float brush_5_drift_multiplier = 1.0;


float drift_multiplier_for(float brush_index) {
    if (brush_index < 0.5) return brush_0_drift_multiplier;
    if (brush_index < 1.5) return brush_1_drift_multiplier;
    if (brush_index < 2.5) return brush_2_drift_multiplier;
    if (brush_index < 3.5) return brush_3_drift_multiplier;
    if (brush_index < 4.5) return brush_4_drift_multiplier;
    return brush_5_drift_multiplier;
}


void fragment() {
    float density = texture(TEXTURE, UV).a;
    if (density <= 0.0) {
        discard;
    }

    // Select a tile from left to right: sparse density uses tile 0; dense uses tile 5.
    float brush_index = min(floor(density * brush_count), brush_count - 1.0);

    // One brush tile occupies one creep cell (13 world pixels by default).
    vec2 brush_uv = UV * (world_size / cell_size);
    brush_uv.x += TIME * drift_speed * drift_multiplier_for(brush_index) / cell_size;
    brush_uv = fract(brush_uv);

    vec2 atlas_uv = vec2((brush_index + brush_uv.x) / brush_count, brush_uv.y);
    vec4 brush = texture(brush_texture, atlas_uv);

    COLOR = vec4(brush.rgb, brush.a * density);
}
