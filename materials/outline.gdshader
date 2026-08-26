shader_type spatial;
render_mode unshaded, cull_front, depth_draw_always;

uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;
uniform float outline_enabled : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
    ALPHA = outline_enabled;
}