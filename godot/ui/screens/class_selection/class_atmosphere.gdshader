shader_type canvas_item;

uniform vec4 primary_color : source_color = vec4(0.38, 0.18, 0.68, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.02, 0.04, 0.08, 1.0);
uniform vec2 focus = vec2(0.64, 0.43);
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec2 uv = UV;
	float distance_from_focus = distance(uv, focus);
	float halo = smoothstep(0.78, 0.05, distance_from_focus);
	float ring = 1.0 - smoothstep(0.0, 0.018, abs(distance_from_focus - 0.29));
	float rays = pow(max(0.0, sin(atan(uv.y - focus.y, uv.x - focus.x) * 10.0 + distance_from_focus * 18.0)), 10.0);
	float diamond = abs(fract((uv.x + uv.y) * 8.0) - 0.5) + abs(fract((uv.x - uv.y) * 8.0) - 0.5);
	float pattern = smoothstep(0.92, 0.76, diamond) * 0.025;
	vec3 color = vec3(0.004, 0.009, 0.016);
	color += secondary_color.rgb * 0.24;
	color += primary_color.rgb * halo * 0.22 * intensity;
	color += primary_color.rgb * (ring * 0.045 + rays * halo * 0.018 + pattern);
	float vignette = smoothstep(0.96, 0.34, distance(uv, vec2(0.5)));
	COLOR = vec4(color * (0.55 + vignette * 0.45), 1.0);
}
