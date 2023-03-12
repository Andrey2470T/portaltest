-- GUN CONFIGURATION --

gsettings = {}
-- splash drop gravity acceleration (metres/second^2)
gsettings.SPLASH_DROP_GRAVITY = tonumber(minetest.settings:get("portaltest_splash_drop_gravity")) or 9.8

-- speed of gun ball (metres/second)
gsettings.GUN_BALL_SPEED = tonumber(minetest.settings:get("portaltest_gun_ball_speed")) or 50.0

-- lifetime of splash drop (seconds)
gsettings.SPLASH_DROP_LIFETIME = tonumber(minetest.settings:get("portaltest_splash_drop_lifetime")) or 2.0

-- gun ball collision box
local gball_cbox_min = minetest.setting_get_pos("portaltest_gun_ball_collision_box_min_edge") or {x=-0.01, y=-0.01, z=-0.01}
local gball_cbox_max = minetest.setting_get_pos("portaltest_gun_ball_collision_box_max_edge") or {x=0.01, y=0.01, z=0.01}
gsettings.GUN_BALL_COLLISION_BOX = {
	gball_cbox_min.x, gball_cbox_min.y, gball_cbox_min.z,
	gball_cbox_max.x, gball_cbox_max.y, gball_cbox_max.z
}

-- splash drop collision box
local sdrop_cbox_min = minetest.setting_get_pos("portaltest_splash_drop_collision_box_min_edge") or {x=-0.005, y=-0.005, z=-0.005}
local sdrop_cbox_max = minetest.setting_get_pos("portaltest_splash_drop_collision_box_max_edge") or {x=0.005, y=0.005, z=0.005}
gsettings.SPLASH_DROP_COLLISION_BOX = {
	sdrop_cbox_min.x, sdrop_cbox_min.y, sdrop_cbox_min.z,
	sdrop_cbox_max.x, sdrop_cbox_max.y, sdrop_cbox_max.z
}

-- gun shift position
gsettings.GUN_POSITION_SHIFT = minetest.setting_get_pos("portaltest_gun_position_shift") or {x=0.3, y=1.2, z=0.5}
