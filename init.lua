local modpath = minetest.get_modpath("portaltest")

local DEFAULT_GRAVITY = -9.8

-- Load separate files
dofile(modpath .. "/aerial_faith_plate.lua")
dofile(modpath .. "/config.lua")
dofile(modpath .. "/gun.lua")
dofile(modpath .. "/panels.lua")
dofile(modpath .. "/portal.lua")

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

		local name = player:get_player_name()
        if player:get_wielded_item():get_name() == "portaltest:gun_item" then
			local gun_pos, gun_rot = gun.calculate_gun_pos_and_rot(player)
			if not gun.spawned_guns[name] then
				minetest.debug("add gun entity")
				gun.spawned_guns[name] = minetest.add_entity(gun_pos, "portaltest:gun")
				player_api.set_model(player, "portaltest_player_with_gun.b3d")
			else
				gun.spawned_guns[name]:set_pos(gun_pos)
			end

			gun.spawned_guns[name]:set_rotation(gun_rot)


			local ctrls = player:get_player_control()

			local anim
			local speed = 30
			local meta = player:get_meta()
			if ctrls.up or ctrls.right then
				anim = "walk_forward"
			elseif ctrls.down or ctrls.left then
				anim = "walk_backward"
			elseif ctrls.LMB or ctrls.RMB then
				if meta:get_string("is_shooting") == "" then
					minetest.debug("\'is_shooting\' is empty!")
					anim = "shoot"
					speed = 10

					local gun_color = ctrls.LMB and "blue" or "orange"
					meta:set_string("is_shooting", "1")
					minetest.debug("\'is_shooting\' is 1!")

					gun.spawned_guns[name]:set_properties({textures={"portaltest_gun.png", "portaltest_gun_" .. gun_color .. "_tube.png"}})

					gun.shoot(player, gun.spawned_guns[name], gun_color)
					gun.knockback_gun(player, gun.spawned_guns[name])
				end


			elseif meta:get_string("is_shooting") == "" then
				anim = "stand"
			end

			player_api.set_animation(player, anim, speed)
		else
			if gun.spawned_guns[name] then
				minetest.debug("remove gun entity")
				gun.spawned_guns[name]:remove()
				gun.spawned_guns[name] = nil
				player_api.set_model(player, "character.b3d")
			end
		end
	end
end)
