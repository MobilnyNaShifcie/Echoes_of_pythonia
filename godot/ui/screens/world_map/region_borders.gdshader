shader_type canvas_item;

// B is the antialiased seam generated from the same path as the ID partition.
void fragment() {
	float coverage = texture(TEXTURE, UV).b;
	COLOR = vec4(0.88, 0.69, 0.40, coverage);
}
