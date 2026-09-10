shader_type canvas_item;

#include "res://ui/screens/world_map/region_highlight.gdshaderinc"

uniform vec4 world_rect_uv = vec4(0.0390625, 0.243055556, 0.33203125, 0.590277778);

// The approved RGB source contains a pale baked backdrop. Remove it at runtime
// and blend the dry eastern terrain over the untouched Twilight Plains layer.
// Defaults also keep the scene preview usable before the controller is ready.
uniform vec2 neutral_range = vec2(0.045, 0.14);
uniform vec2 pale_range = vec2(0.62, 0.82);
uniform vec2 white_range = vec2(0.74, 0.90);
uniform vec2 east_blend_range = vec2(0.78, 0.94);
uniform vec2 city_polygon[16];
uniform float city_hover_strength : hint_range(0.0, 1.0) = 0.0;

float city_mask(vec2 point) {
	bool inside = false;
	int previous = 15;
	for (int current = 0; current < 16; current++) {
		vec2 a = city_polygon[current];
		vec2 b = city_polygon[previous];
		if ((a.y > point.y) != (b.y > point.y)) {
			float crossing = (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x;
			if (point.x < crossing) {
				inside = !inside;
			}
		}
		previous = current;
	}
	return inside ? 1.0 : 0.0;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float highest = max(source.r, max(source.g, source.b));
	float lowest = min(source.r, min(source.g, source.b));
	float neutral = 1.0 - smoothstep(neutral_range.x, neutral_range.y, highest - lowest);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float pale = smoothstep(pale_range.x, pale_range.y, luminance);
	float white = smoothstep(white_range.x, white_range.y, lowest);
	float alpha = source.a * (1.0 - max(neutral * pale, white));
	// Reduce pale backdrop contamination on the outer antialiased edge.
	vec3 terrain = source.rgb * mix(0.80, 1.0, smoothstep(0.15, 0.85, alpha));
	alpha *= 1.0 - smoothstep(east_blend_range.x, east_blend_range.y, UV.x);
	vec2 world_uv = world_rect_uv.xy + UV * world_rect_uv.zw;
	terrain = highlight_region(terrain, world_uv);
	float highlight = 0.0;
	if (city_hover_strength > 0.0) {
		highlight += city_hover_strength * city_mask(UV);
	}
	vec3 warmed = terrain * 1.18 + vec3(0.11, 0.074, 0.018);
	COLOR = vec4(mix(terrain, warmed, clamp(highlight, 0.0, 1.0)), alpha);
}
