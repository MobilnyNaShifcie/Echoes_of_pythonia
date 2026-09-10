shader_type canvas_item;

uniform vec4 accent_color : source_color = vec4(0.94, 0.69, 0.25, 1.0);

void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(1.0, 3.4);
	float radius = length(p);
	float ring_outer = 1.0 - smoothstep(0.0, 0.035, abs(radius - 0.43));
	float ring_inner = 1.0 - smoothstep(0.0, 0.025, abs(radius - 0.31));
	float fill = smoothstep(0.48, 0.12, radius);
	float axis = (1.0 - smoothstep(0.01, 0.026, abs(p.x))) * smoothstep(0.42, 0.12, abs(p.y));
	float alpha = ring_outer * 0.82 + ring_inner * 0.32 + fill * 0.16 + axis * 0.25;
	COLOR = vec4(accent_color.rgb, alpha);
}
