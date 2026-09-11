// Data texture, deliberately NOT source_color: CPU and GPU read identical IDs.
uniform sampler2D region_ids : filter_nearest, repeat_disable;
uniform float hover_code = -1.0;
uniform float hover_strength : hint_range(0.0, 1.0) = 0.0;

vec3 highlight_region(vec3 color, vec2 world_uv) {
	vec3 data = texture(region_ids, world_uv).rgb;
	float matched = 1.0 - step(0.5, abs(data.r * 255.0 - hover_code));
	float amount = matched * hover_strength * (1.0 - data.g);
	vec3 warmed = color + (color * 0.22 + vec3(0.10, 0.068, 0.018)) * (vec3(1.0) - color);
	return mix(color, warmed, amount);
}
