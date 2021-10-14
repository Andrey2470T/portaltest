-- GUN CONFIGURATION --

gsettings = {}
-- splash drop gravity acceleration (metres/second^2)
gsettings.SPLASH_DROP_GRAVITY = tonumber(minetest.settings:get("portaltest_splash_drop_gravity")) or 9.8

-- speed of gun ball (metres/second)
gsettings.GUN_BALL_SPEED = tonumber(minetest.settings:get("portaltest_gun_ball_speed")) or 50.0

-- lifetime of splash drop (seconds)
gsettings.SPLASH_DROP_LIFETIME = tonumber(minetest.settings:get("portaltest_splash_drop_lifetime")) or 2.0

-- gun ball collision box
gsettings.GUN_BALL_COLLISION_BOX = {
	table.unpack(minetest.setting_get_pos("portaltest_gun_ball_collision_box_min_edge") or {-0.01, -0.01, -0.01}),
	table.unpack(minetest.setting_get_pos("portaltest_gun_ball_collision_box_max_edge") or {0.01, 0.01, 0.01})
}

-- splash drop collision box
gsettings.SPLASH_DROP_COLLISION_BOX = {
	table.unpack(minetest.setting_get_pos("portaltest_splash_drop_collision_box_min_edge") or {-0.005, -0.005, -0.005}),
	table.unpack(minetest.setting_get_pos("portaltest_splash_drop_collision_box_max_edge") or {0.005, 0.005, 0.005})
}

-- gun shift position
gsettings.GUN_POSITION_SHIFT = minetest.setting_get_pos("portaltest_gun_position_shift") or {0.3, 1.2, 0.5}
