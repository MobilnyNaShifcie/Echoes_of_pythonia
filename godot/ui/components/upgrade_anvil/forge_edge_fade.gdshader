shader_type canvas_item;
render_mode unshaded;

void fragment() {
	float sides = smoothstep(0.0, 0.09, UV.x) * smoothstep(0.0, 0.09, 1.0 - UV.x);
	float ends = smoothstep(0.0, 0.16, UV.y) * smoothstep(0.0, 0.22, 1.0 - UV.y);
	COLOR.a *= sides * ends;
}
