extends GutTest


func test_project_version_is_v0250() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/version"), "0.25.0")


func test_main_scene_is_configured() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/app/app.tscn"
	)


func test_default_resolution_is_full_hd() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_width_override"), 1920)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_height_override"), 1080)
