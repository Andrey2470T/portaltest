-- PORTAL GUN --

gun = {}

-- Table for referencing to a gun entity of each player that is wielding that currently
gun.spawned_guns = {}

local crosshair_hud_props = {
	hud_elem_type = "image",
	position = {x=0.5, y=0.5},
	scale = {x=2, y=2},
	text = "portaltest_gun_crosshair.png",
	alignment = {x=0, y=0},
	offset = {x=0, y=0}
}

gun.generate_splash_particles = function(pos, normal, splash_color)
	normal = vector.normalize(normal)

	local minvel_rot
	local maxvel_rot

	if vector.dot(normal, vector.new(0, 1, 0)) == 0 then
		minvel_rot = vector.new(math.pi/8, -math.pi/8, 0)
		maxvel_rot = vector.new(-math.pi/8, math.pi/8, 0)
	else
		minvel_rot = vector.new(math.pi/8, 0, -math.pi/8)
		maxvel_rot = vector.new(-math.pi/8, 0, math.pi/8)
	end
	local splash_particles_def = {
		amount = math.random(20, 25),
		time = 0.1,
		minpos = pos,
		maxpos = pos,
		minvel = vector.rotate(normal, minvel_rot) * 5,
		maxvel = vector.rotate(normal, maxvel_rot) * 5,
		minacc = {x=0, y=-gsettings.SPLASH_DROP_GRAVITY, z=0},
		maxacc = {x=0, y=-gsettings.SPLASH_DROP_GRAVITY, z=0},
		minexptime = 1.5,
		maxexptime = 2.5,
		minsize = 3,
		maxsize = 3.5,
		collisiondetection = true,
		collision_removal = false,
		object_collision = false,
		texture = "portaltest_splash_drop.png^[multiply:" .. splash_color,
		glow = 14
	}

	minetest.add_particlespawner(splash_particles_def)
end

-- Shifts the gun entity backward and turns right a bit for a visual effect while shooting. Also knockback a bit the player`s camera.
gun.knockback_gun = function(player, gun)
	local shift_back = -0.2
	local cam_rot_d = -math.rad(2)

	local elapsed = 0.0
	local dtime = 0.1

	local orig_cam_dir = player:get_look_dir()
	local orig_pitch = player:get_look_vertical()

	local function knockback(gun)
		elapsed = math.floor((elapsed + dtime)*10)/10

		if not gun:get_luaentity() then
			return
		end

		if elapsed == 0.4 then
			shift_back = -shift_back
			cam_rot_d = -cam_rot_d
		end

		if elapsed == 0.6 then
			player:set_look_vertical(orig_pitch)
		else
			player:set_look_vertical(player:get_look_vertical()+cam_rot_d)
		end

		local p, b, pos, rot, fv = gun:get_attach()
		pos.z = pos.z + shift_back
		gun:set_attach(p, b, pos, rot, fv)

		if elapsed < 0.6 then
			minetest.after(dtime, knockback, gun)
		else
			player:get_meta():set_string("is_shooting", "")
		end

		return true
	end

	minetest.after(dtime, knockback, gun)

	return true
end

gun.bounce_splash_drop = function(drop, surface_normal)
	local self = drop:get_luaentity()

	if not self then return end

	local new_vel = vector.multiply(self.last_velocity, -1)
	local cross = vector.cross(surface_normal, new_vel)
	new_vel = vector.rotate_around_axis(new_vel, cross, vector.angle(surface_normal, new_vel)*2)

	drop:set_velocity(new_vel)
end

gun.shoot = function(player, gun, ball_color)
	if not gun:get_luaentity() then
		return
	end

	local dir = player:get_look_dir()

	local ball_pos = vector.add(gun:get_pos(), vector.rotate(gsettings.GUN_POSITION_SHIFT, {x=-player:get_look_vertical(), y=player:get_look_horizontal(), z=0}))
	local gun_ball = minetest.add_entity(ball_pos, "portaltest:gun_ball")--, vector.multiply(dir, -0.3)), "portaltest:gun_ball")
	local self = gun_ball:get_luaentity()
	self.move_dir = dir
	self.stream_emitter = player:get_player_name()
	gun_ball:set_properties({textures={"portaltest_gun_ball.png^[multiply:" .. ball_color}})
	gun_ball:set_velocity(vector.multiply(dir, gsettings.GUN_BALL_SPEED))

	return true
end

gun.global_step_through_player_with_gun = function(player)
	local name = player:get_player_name()
	local meta = player:get_meta()
	if player:get_wielded_item():get_name() == "portaltest:gun_item" then
		if meta:get_string("gun_crosshair_id") == "" then
			local id = player:hud_add(crosshair_hud_props)
			meta:set_string("gun_crosshair_id", tostring(id))
		end
		if not gun.spawned_guns[name] then
			gun.spawned_guns[name] = minetest.add_entity(player:get_pos(), "portaltest:gun")
			gun.spawned_guns[name]:set_attach(player, "", vector.multiply(gsettings.GUN_POSITION_SHIFT, 10), {x=0, y=0, z=0}, true)
			player_api.set_model(player, "portaltest_player_with_gun.b3d")
		end

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
				anim = "shoot"
				speed = 1

				local gun_color = ctrls.LMB and "blue" or "orange"
				meta:set_string("is_shooting", "1")

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
			gun.spawned_guns[name]:remove()
			gun.spawned_guns[name] = nil
			player_api.set_model(player, "character.b3d")

			player:hud_remove(tonumber(meta:get_string("gun_crosshair_id")))
			meta:set_string("gun_crosshair_id", "")
		end
	end
end

gun.get_pointedthing_info = function(pos, dir)
	local pos2 = vector.add(pos, dir)
	local raycast = minetest.raycast(pos, pos2)

	local target_pt
	for pt in raycast do
		if pt.type == "node" then
			return pt
		end
	end

	return
end

--[[gun.update_player_portals_datas = function(player_meta)
	local player_portals = minetest.deserialize(player_meta:get_string("portals"))

	if not player_portals or player_portals == {} then
		return
	end

	local new_datas = {}

	for color, pos in pairs(player_portals) do
		local actual_node = minetest.get_node(player_portals[color])

		if actual_node.name == "portaltest:portal_" .. color then
			new_datas[color] = {x=pos.x, y=pos.y, z=pos.z}
		end
	end

	player_meta:set_string("portals", minetest.serialize(new_datas))
end]]

gun.place_portal = function(placer, pt, color, param2, dir_to_top)
	local meta = placer:get_meta()
	local player_portals = minetest.deserialize(meta:get_string("portals")) or {}

	local oppose_color = color == "orange" and "blue" or "orange"
	local pname

	if not player_portals[oppose_color] or minetest.get_item_group(minetest.get_node(player_portals[oppose_color]).name, "portal") ~= 1 then
		pname = "portaltest:portal_" .. color .. "_uncon"
	else
		local op_portal = minetest.get_node(player_portals[oppose_color])
		minetest.swap_node(player_portals[oppose_color], {name="portaltest:portal_"..oppose_color, param1=op_portal.param1,param2=op_portal.param2})
		pname = "portaltest:portal_" .. color
	end

	if player_portals[color] then
		if minetest.get_node(player_portals[color]).name == pname then
			minetest.remove_node(player_portals[color])
		end
	end

	player_portals[color] = pt.above

	meta:set_string("portals", minetest.serialize(player_portals))

	minetest.add_node(pt.above, {name = pname, param2 = param2})

	local setp_meta = minetest.get_meta(player_portals[color])
	setp_meta:set_string("dir_to_top", vector.to_string(dir_to_top))

	if player_portals[oppose_color] then
		setp_meta:set_string("connected_to", minetest.serialize(player_portals[oppose_color]))

		local cp_meta = minetest.get_meta(player_portals[oppose_color])
		cp_meta:set_string("connected_to", minetest.serialize(player_portals[color]))
	end
end


-- Player model with gun
player_api.register_model("portaltest_player_with_gun.b3d", {
	animations = {
		stand = {x = 1, y = 80},
		sit = {x = 81, y = 161},
		lay = {x = 162, y = 167},
		walk_forward = {x = 168, y = 188},
		walk_backward = {x = 188, y = 168},
		shoot = {x = 189, y = 199}
	}
})


-- Portal gun
minetest.register_entity("portaltest:gun", {
	visual_size = {x=3, y=3, z=3},
	physical = false,
	collision_box = {0, 0, 0, 0, 0, 0},
	pointable = false,
	visual = "mesh",
	mesh = "portaltest_gun.b3d",
	use_texture_alpha = true,
	textures = {"portaltest_gun.png", "portaltest_gun_empty_tube.png"},
	glow = 12,
	static_save = false
})

minetest.register_craftitem("portaltest:gun_item", {
	description = "Portal Gun",
	inventory_image = "portaltest_gun_inv.png",
	wield_image = "portaltest_gun_inv.png^[opacity:0",
	range = 0.0
})
-- Legacy code

--[[minetest.register_node("portaltest:gun_empty", {
    drawtype = "mesh",
    visual_scale = 0.5,
    tiles = {"portaltest_gun.png^portaltest_gun_empty_tube.png"},
    mesh = "portaltest_gun.b3d",
    description = "Portal Gun",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    collision_box = {0, 0, 0, 0, 0, 0},
    selection_box = {0, 0, 0, 0, 0, 0},
    stack_max = 1,
    on_construct = function(pos)
        return nil
    end,
	on_place = function(itemstack, placer, pointed_thing)
		return nil
	end
})


minetest.register_node("portaltest:gun_orange", {
    drawtype = "mesh",
    visual_scale = 0.5,
    tiles = {"portaltest_gun.png^portaltest_gun_orange_tube.png"},
    mesh = "portaltest_gun.b3d",
    description = "Portal Gun",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    collision_box = {0, 0, 0, 0, 0, 0},
    selection_box = {0, 0, 0, 0, 0, 0},
    stack_max = 1,
    groups = {not_in_creative_inventory=1},
    on_construct = function(pos)
        return nil
    end,
	on_place = function(itemstack, placer, pointed_thing)
		return nil
	end
})

minetest.register_node("portaltest:gun_blue", {
    drawtype = "mesh",
    visual_scale = 0.5,
    tiles = {"portaltest_gun.png^portaltest_gun_blue_tube.png"},
    mesh = "portaltest_gun.b3d",
    description = "Portal Gun",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    collision_box = {0, 0, 0, 0, 0, 0},
    selection_box = {0, 0, 0, 0, 0, 0},
    stack_max = 1,
    groups = {not_in_creative_inventory=1},
    on_construct = function(pos)
        return nil
    end,
	on_place = function(itemstack, placer, pointed_thing)
		return nil
	end
})]]




minetest.register_entity("portaltest:gun_ball", {
    visual = "sprite",
    visual_size = {x=1, y=1, z=1},
    physical = true,
    collide_with_objects = false,
    collisionbox = gsettings.GUN_BALL_COLLISION_BOX,
	selectionbox = {0, 0, 0, 0, 0, 0},
    textures = {"portaltest_gun_ball.png"},
    backface_culling = false,
    glow = 25,
    on_activate = function(self, staticdata, dtime_s)
		if staticdata ~= "" then
			local data = minetest.deserialize(staticdata)
			self.move_dir = data[1]
			self.stream_emitter = data[2]
		end
    end,
    on_step = function(self, dtime, moveresult)
		if not self.move_dir then return end

		if moveresult.collides then
			local pos = self.object:get_pos()
			local texture = self.object:get_properties().textures[1]

			self.object:remove()

			local pt = gun.get_pointedthing_info(pos, self.move_dir)

			if pt then
				local s, e = texture:find("%^%[multiply:", 1)
				local color = texture:sub(e+1, texture:len())
				local player = minetest.get_player_by_name(self.stream_emitter)
				if player then
					if pt.intersection_normal.y == 0 then
						-- Portal is placed on the wall
						if portal.can_exist(pt.under, pt.above, vector.new(0, 1, 0)) then
							gun.place_portal(player, pt, color, minetest.dir_to_facedir(pt.intersection_normal), {x=0, y=1, z=0})
						end
					else
						-- Portal is placed on the floor/ceiling
						local md = self.move_dir
						local horiz_look_dir = vector.new(md.x, 0, md.z)
						local x_horiz_dir = vector.new(md.x, 0, 0)
						local z_horiz_dir = vector.new(0, 0, md.z)
						local x_ang_less_y = vector.angle(x_horiz_dir, horiz_look_dir) < vector.angle(horiz_look_dir, z_horiz_dir)
						local is_invert = pt.intersection_normal.y > 0 and 1 or -1
						local target_horiz_dir = vector.normalize(x_ang_less_y and x_horiz_dir or z_horiz_dir)

						if portal.can_exist(pt.under, pt.above, is_invert*target_horiz_dir) then
							-- Keys are param2 values, values are corresponding directions
							local y_up_rots = {
								[6] = {x=0, y=0, z=1},
								[8] = {x=0, y=0, z=-1},
								[15] = {x=1, y=0, z=0},
								[17] = {x=-1, y=0, z=0}
							}

							local y_down_rots = {
								[4] = {x=0, y=0, z=-1},
								[10] = {x=0, y=0, z=1},
								[13] = {x=-1, y=0, z=0},
								[19] = {x=1, y=0, z=0}
							}

							local target_param2
							local target_y_rots = pt.intersection_normal.y == 1 and y_up_rots or y_down_rots

							for p2, dir in pairs(target_y_rots) do
								if vector.equals(target_horiz_dir, dir) then
									target_param2 = p2
									break
								end
							end

							gun.place_portal(player, pt, color, target_param2, is_invert*target_horiz_dir)
						end
					end
				end

				gun.generate_splash_particles(pt.intersection_point, pt.intersection_normal, color)

			end
        end
    end,
    get_staticdata = function(self)
		return minetest.serialize({self.move_dir, self.stream_emitter})
    end
})

--[[minetest.register_entity("portaltest:splash_drop", {
    visual = "sprite",
    visual_size = {x=1, y=1, z=1},
    physical = true,
    collide_with_objects = true,
    textures = {"portaltest_splash_drop.png"},
    collisionbox = gsettings.SPLASH_DROP_COLLISION_BOX,
	selectionbox = {0, 0, 0, 0, 0, 0},
    backface_culling = false,
    glow = 7,
    on_activate = function(self, staticdata, dtime_s)
        self.object:set_acceleration({x=0, y=-gsettings.SPLASH_STREAM_GRAVITY, z=0})
		self.last_velocity = self.object:get_velocity()
		self.dtime = 0
    end,
    on_step = function(self, dtime, moveresult)
		self.dtime = self.dtime + dtime

		if not moveresult.collides then
			self.last_velocity = self.object:get_velocity()
		else
			local min_cb_pos = {
				x = gsettings.SPLASH_DROP_COLLISION_BOX[1],
				y = gsettings.SPLASH_DROP_COLLISION_BOX[2],
				z = gsettings.SPLASH_DROP_COLLISION_BOX[3]
			}

			local pt = gun.get_pointedthing_info(self.object:get_pos(), self.last_velocity, 1, dtime)

			if pt and pt.intersection_normal then
				gun.bounce_splash_drop(self.object, pt.intersection_normal)
			end
        end

		if self.dtime >= gsettings.SPLASH_DROP_LIFETIME then
			self.object:remove()
		end
    end
})]]



minetest.register_on_leaveplayer(function(player)
	local meta = player:get_meta()
	meta:set_string("gun_crosshair_id", "")
	meta:set_string("is_shooting", "")

	local portals = minetest.deserialize(meta:get_string("portals"))

	if portals then
		if portals["orange"] and minetest.get_node(portals["orange"]).name == "portaltest:portal_orange" then
			minetest.remove_node(portals["orange"])
		end
		if portals["blue"] and minetest.get_node(portals["blue"]).name == "portaltest:portal_blue" then
			minetest.remove_node(portals["blue"])
		end
		meta:set_string("portals", "")
	end
end)
