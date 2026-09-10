shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.95, 0.7, 0.25, 0.72);
uniform float thickness : hint_range(0.5, 8.0) = 3.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 pixel = TEXTURE_PIXEL_SIZE * thickness;
	float outline = 0.0;
	outline = max(outline, texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a);
	outline = max(outline, texture(TEXTURE, UV - vec2(pixel.x, 0.0)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(0.0, pixel.y)).a);
	outline = max(outline, texture(TEXTURE, UV - vec2(0.0, pixel.y)).a);
	outline = max(outline, texture(TEXTURE, UV + pixel).a);
	outline = max(outline, texture(TEXTURE, UV - pixel).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(pixel.x, -pixel.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(-pixel.x, pixel.y)).a);
	float alpha = max(outline - source.a, 0.0) * glow_color.a;
	COLOR = vec4(glow_color.rgb, alpha);
}
