shader_type canvas_item;

#include "res://ui/screens/world_map/region_highlight.gdshaderinc"

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(highlight_region(source.rgb, UV), source.a);
}
