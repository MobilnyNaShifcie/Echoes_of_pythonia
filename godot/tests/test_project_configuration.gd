extends GutTest


func test_project_version_is_v0250() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/version"), "0.25.0")


func test_main_scene_is_configured() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/app/app.tscn"
	)
