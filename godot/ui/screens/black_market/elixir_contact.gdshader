shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
	float radius = length(local_position.xz) / 0.21;
	ALBEDO = vec3(0.025, 0.012, 0.006);
	ALPHA = 0.32 * (1.0 - smoothstep(0.12, 1.0, radius));
}
