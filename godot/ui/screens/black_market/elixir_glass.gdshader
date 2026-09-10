shader_type spatial;
render_mode depth_prepass_alpha, cull_back;

void fragment() {
	float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.0);
	ALBEDO = mix(vec3(0.15, 0.25, 0.42), vec3(0.47, 0.67, 0.78), rim);
	METALLIC = 0.1;
	ROUGHNESS = 0.13;
	SPECULAR = 0.85;
	ALPHA = 0.17 + rim * 0.58;
}
