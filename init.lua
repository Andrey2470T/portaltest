local modpath = minetest.get_modpath("portaltest")

local DEFAULT_GRAVITY = -9.8

-- Load separate files
dofile(modpath .. "/aerial_faith_plate.lua")
dofile(modpath .. "/config.lua")
dofile(modpath .. "/portal.lua")
dofile(modpath .. "/gun.lua")
dofile(modpath .. "/panels.lua")
--dofile(modpath .. "/portal.lua")

-- Global callbacks

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "portaltest:afp_params_form" then
		local cur_edited_afp_node_pos = minetest.deserialize(player:get_meta():get_string("cur_edited_afp_node_pos"))

		if not cur_edited_afp_node_pos then
			return
		end

		if fields.quit then
			player:get_meta():set_string("cur_edited_afp_node_pos", "")
			return true
		end
		if fields.save then
			local params = {height = tonumber(fields.max_height), distance = tonumber(fields.max_distance)}

			minetest.get_meta(cur_edited_afp_node_pos):set_string("params", minetest.serialize(params))
			player:get_meta():set_string("cur_edited_afp_node_pos", "")
			minetest.show_formspec(player:get_player_name(), formname, "")
			return true
		end
	end
end)

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local cur_vel = player:get_velocity()

		if vector.length(cur_vel) > 0.05 then
			player:get_meta():set_string("last_vel", vector.to_string(cur_vel))
		end
		local pos = player:get_pos()
		local under_node = minetest.get_node(pos)
		--minetest.debug("under_node: " .. under_node.name)

		if under_node.name == "portaltest:aerial_faith_plate_idle" then
			local node_dir = minetest.facedir_to_dir(under_node.param2)
			local params = minetest.deserialize(minetest.get_meta(pos):get_string("params"))

			if params and params.height and params.distance then
				local gravity = DEFAULT_GRAVITY * player:get_physics_override().gravity

				local v_y = math.sqrt(19.6 * params.height)
				local v_z = 2 * -DEFAULT_GRAVITY * params.distance / v_y

				local v = {x=0, y=v_y, z=v_z}

				v = vector.rotate_around_axis(v, {x=0, y=1, z=0}, vector.dir_to_rotation(node_dir).y)

				player:add_velocity(v)

				minetest.swap_node(pos, {name = "portaltest:aerial_faith_plate_active", param2 = under_node.param2})
				local timer = minetest.get_node_timer(pos)
				timer:start(2)
			end
		end

		gun.global_step_through_player_with_gun(player)
	end
end)
