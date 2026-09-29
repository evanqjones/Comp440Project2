extends GutTest
## Production startup must use one daylight sky through its Store instance.

const MAIN_SCENE: PackedScene = preload("res://systems/core/main.tscn")


func test_main_scene_has_one_production_store_sky() -> void:
	var main := MAIN_SCENE.instantiate() as Node3D
	add_child_autofree(main)
	var environments := main.find_children("*", "WorldEnvironment", true, false)
	assert_eq(environments.size(), 1, "main scene should use exactly one sky environment")
	if environments.size() != 1:
		return
	var world_environment := environments[0] as WorldEnvironment
	assert_eq(world_environment.get_parent(), main.get_node("Store"))
	assert_not_null(world_environment.environment)
	if world_environment.environment == null:
		return
	assert_eq(world_environment.environment.background_mode, Environment.BG_SKY)
	assert_not_null(world_environment.environment.sky)
	if world_environment.environment.sky != null:
		var sky_material := world_environment.environment.sky.sky_material as ProceduralSkyMaterial
		assert_not_null(sky_material)
		if sky_material != null:
			assert_almost_eq(sky_material.sun_angle_max, 0.0, 0.001, "the two scene lights must not create sun artifacts")
