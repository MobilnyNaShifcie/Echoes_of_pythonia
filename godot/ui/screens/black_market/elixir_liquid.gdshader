shader_type spatial;
varying vec3 local_position;

void vertex() { local_position = VERTEX; }

void fragment() {
	float height = smoothstep(0.19, 0.67, local_position.y);
	vec3 wine = vec3(0.19, 0.018, 0.09);
	vec3 violet = vec3(0.12, 0.065, 0.33);
	ALBEDO = mix(wine, violet, height);
	ROUGHNESS = 0.21;
	METALLIC = 0.12;
	SPECULAR = 0.7;
	EMISSION = ALBEDO * 0.14;
}
