extends GutTest


func test_project_version_is_v0250() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/version"), "0.25.0")


func test_main_scene_is_configured() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/app/app.tscn"
	)


func test_logical_resolution_is_full_hd_and_windowed_preview_fits_the_desktop() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_width_override"), 1600)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_height_override"), 900)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")


func test_windows_export_preset_is_versioned_for_stage_seven() -> void:
	var config := ConfigFile.new()
	assert_eq(config.load("res://export_presets.cfg"), OK)
	assert_eq(config.get_value("preset.0", "name"), "Windows Desktop")
	assert_eq(config.get_value("preset.0", "platform"), "Windows Desktop")
	assert_eq(
		config.get_value("preset.0", "export_path"),
		"../build/windows/Echoes_of_Pythonia_v0.25.0.exe",
	)
	assert_eq(config.get_value("preset.0", "export_filter"), "all_resources")
	assert_eq(
		config.get_value("preset.0", "exclude_filter"),
		"tests/*,addons/gut/*",
	)
	assert_eq(config.get_value("preset.0.options", "application/file_version"), "0.25.0")
