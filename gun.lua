-- PORTAL GUN --

gun = {}

-- Table for referencing to a gun entity of each player that is wielding that currently
gun.spawned_guns = {}

local gun_shift = {x=0.3, y=1.2, z=0.5}

gun.generate_splash_particles = function(pos, normal, splash_color)
    local rand_amount = math.random(20, 25)

	local min_vel_dir = vector.rotate(normal, {x=-math.pi/4, y=-math.pi/4, z=0})
	local max_vel_dir = vector.rotate(normal, {x=math.pi/4, y=math.pi/4, z=0})

	minetest.add_particlespawner({
		amount = rand_amount,
		time = 0.1,
		minpos = pos,
		maxpos = pos,
		minvel = vector.multiply(min_vel_dir, 5),
		maxvel = vector.multiply(max_vel_dir, 5),
		minacc = {x=0, y=-gsettings.SPLASH_STREAM_GRAVITY, z=0},
		maxacc = {x=0, y=-gsettings.SPLASH_STREAM_GRAVITY, z=0},
		minexptime = 1.5,
		maxexptime = 2.5,
		minsize = 3,
		maxsize = 3.5,
		collisiondetection = false,
		collision_removal = false,
		object_collision = false,
		texture = "portaltest_splash_drop.png^[multiply:" .. splash_color,
		glow = 7
	})
end

-- Recalculates a new position and rotation for gun relatively to the player`s rotation.
gun.calculate_gun_pos_and_rot = function(player)
	local rot = {x=-player:get_look_vertical(), y=player:get_look_horizontal(), z=0}

	local pos = vector.add(player:get_pos(), vector.rotate(gun_shift, {x=0, y=player:get_look_horizontal(), z=0}))

	return pos, rot
end

-- Shifts the gun entity backward and turns right a bit for a visual effect while shooting. Also knockback a bit the player`s camera.
gun.knockback_gun = function(player, gun)
	local shift_back = -0.05
	local rot_right = -math.rad(1)
	local cam_rot_d = -math.rad(5)

	local elapsed = 0.0
	local dtime = 0.05

	local orig_cam_dir = player:get_look_dir()
	minetest.debug("gun.knockback_gun()")
	local function knockback(gun)
		elapsed = elapsed + dtime
		minetest.debug("elapsed: " .. tostring(elapsed))
		if not gun:get_luaentity() then
			return
		end

		if elapsed >= 0.5 and elapsed < 0.55 or elapsed > 0.45 and elapsed <= 0.5 then
			minetest.debug("elapsed = 0.5")
			rot_right = -rot_right
			shift_back = -shift_back
			cam_rot_d = -cam_rot_d
		end

		player:set_look_vertical(player:get_look_vertical()+cam_rot_d)

		gun:set_pos(vector.add(gun:get_pos(), vector.multiply(orig_cam_dir, shift_back)))
		local cur_rot = gun:get_rotation()
		gun:set_rotation({x=cur_rot.x, y=cur_rot.y+rot_right, z=cur_rot.z})


		if elapsed < 1.0 then
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
	local gun_pos = gun:get_pos()

	local gun_ball = minetest.add_entity(gun_pos, "portaltest:gun_ball")
	gun_ball:set_properties({textures={"portaltest_gun_ball.png^[multiply:" .. ball_color}})
	gun_ball:set_velocity(vector.multiply(dir, gsettings.SPLASH_STREAM_SPEED))

	return true
end

gun.global_step_through_players_with_guns = function()
    local players = minetest.get_connected_players()

    for _, player in ipairs(players) do
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
				gun.spawned_guns[name]:remove()
				gun.spawned_guns[name] = nil
				player_api.set_model(player, "character.b3d")
			end
		end


		--[[
            local ctrls = player:get_player_control()
            local color = ""

            if ctrls.LMB then
                color = "blue"
            elseif ctrls.RMB then
                color = "orange"
            else
                return
            end

            player:set_wielded_item(ItemStack("portaltest:gun_" .. color))
            local pl_pos = player:get_pos()
            local rel_offset_pos = vector.new(0.5, 0, 0)
			rel_offset_pos.y = 0.5

			local dir = player:get_look_dir()
			local dir_rot = vector.dir_to_rotation(dir)
            rel_offset_pos = vector.rotate(rel_offset_pos, dir_rot)
            local pos = vector.add(pl_pos, rel_offset_pos)
            local splash_stream = minetest.add_entity(pos, "portaltest:splash_stream")
            splash_stream:set_properties({textures={"portaltest_splash_stream.png^[multiply:" .. color}})
            splash_stream:set_velocity(vector.multiply(dir, gsettings.SPLASH_STREAM_SPEED))

			local self = splash_stream:get_luaentity()
			self.stream_emitter = player:get_player_name()

            minetest.after(0.5, function()
                player:set_wielded_item(ItemStack("portaltest:gun_empty"))
            end)
        end]]
    end
end

gun.get_pointedthing_info = function(pos, dir, ray_length)
	local pos2 = vector.add(pos, vector.multiply(dir, ray_length))
	local raycast = minetest.raycast(pos, pos2)

	local target_pt
	for pt in raycast do
		--[[if pt.type == "object" then
			local self = pt.ref:get_luaentity()
			if self then
				minetest.debug("ray has intersected an object with name: " .. self.name)
				if self.name ~= "portaltest:splash_stream" then
					target_pt = pt
					break
				else
					--minetest.debug("raycast: " .. self.name)
				end
			end
		else]]
		if pt.type == "node" then
			--minetest.debug("raycast has intersected a node with name: " .. minetest.get_node(pt.under).name)
			return pt
			--target_pt = pt
			--break
		end
	end

	return
end

gun.update_player_portals_datas = function(player_meta)
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
end

gun.place_portal = function(placer, pt, color, param2, dir_to_top)
	local meta = placer:get_meta()
	gun.update_player_portals_datas(meta)
	local player_portals = minetest.deserialize(meta:get_string("portals"))

	if not player_portals or player_portals == {} then
		player_portals = {}
	end

	if portal.is_pos_busy_by_portal(pt.above) then
		return
	end

	if player_portals[color] then
		minetest.remove_node(player_portals[color])
	end

	player_portals[color] = pt.above

	meta:set_string("portals", minetest.serialize(player_portals))

	minetest.add_node(pt.above, {name = "portaltest:portal_" .. color, param2 = param2})

	local setp_meta = minetest.get_meta(player_portals[color])

	local cp_pos

	if color == "orange" then
		if player_portals["blue"] then
			cp_pos = player_portals["blue"]
		end
	elseif color == "blue" then
		if player_portals["orange"] then
			cp_pos = player_portals["orange"]
		end
	end

	if cp_pos then
		setp_meta:set_string("connected_to", minetest.serialize(cp_pos))

		local cp_meta = minetest.get_meta(cp_pos)
		cp_meta:set_string("connected_to", minetest.serialize(player_portals[color]))
	end

	setp_meta:set_string("dir_to_top", minetest.serialize(dir_to_top))
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
	textures = {"portaltest_gun.png"},
	glow = 4,
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
    collisionbox = gsettings.SPLASH_STREAM_COLLISION_BOX,
	selectionbox = {0, 0, 0, 0, 0, 0},
    textures = {"portaltest_gun_ball.png"},
    backface_culling = false,
    glow = 7,
    on_activate = function(self, staticdata, dtime_s)
		self.move_dir = vector.normalize(self.object:get_velocity())
    end,
    on_step = function(self, dtime, moveresult)
        if not moveresult.collides then
			self.move_dir = vector.normalize(self.object:get_velocity())
		else
			local pos = self.object:get_pos()
			local vel = self.object:get_velocity()
			minetest.debug("cur_vel: " .. vector.length(vel))
			local texture = self.object:get_properties().textures[1]

			self.object:remove()
			--minetest.debug("self.last_velocity: " .. minetest.pos_to_string(self.last_velocity))
			--minetest.debug("current velocity: " .. minetest.pos_to_string(vel))

			local pt = gun.get_pointedthing_info(pos, self.move_dir, 1)
			--[[if vector.length(self.move_dir) == 0 then
				pt = gun.get_pointedthing_info(pos, vector.normalize(vel), 1)
			else
				pt = gun.get_pointedthing_info(pos, self.move_dir, 1)
			end]]

			if pt then
				minetest.debug("\'pt\' is not nil!")
				--minetest.debug("pt.type: " .. pt.type)
				--minetest.debug("pt.intersection_normal: " .. minetest.pos_to_string(pt.intersection_normal))
				--minetest.debug("pt.type: " .. pt.type)
				local s, e = texture:find("%^%[multiply:", 1)
				local color = texture:sub(e+1, texture:len())
				--local player = minetest.get_player_by_name(self.stream_emitter)
				--[[if pt.type == "node" then
					if pt.intersection_normal.y == 0 then
						-- Portal is placed on the wall
						local node = minetest.get_node_or_nil(pt.under)
						local node2 = minetest.get_node_or_nil(vector.new(pt.under.x, pt.under.y+1, pt.under.z))

						if (node and node.name == "portaltest:panel_mono") and
							(node2 and node2.name == "portaltest:panel_mono") and
							minetest.get_node({x=pt.above.x, y=pt.above.y+1, z=pt.above.z}).name == "air" then

							gun.place_portal(player, pt, color, minetest.dir_to_facedir(pt.intersection_normal), {x=0, y=1, z=0})
						end
					else
						-- Portal is placed on the floor/ceiling
						local look_dir = player:get_look_dir()
						local horiz_look_dir = vector.new(look_dir.x, 0, look_dir.z)
						local x_horiz_dir = vector.new(look_dir.x, 0, 0)
						local z_horiz_dir = vector.new(0, 0, look_dir.z)
						local target_horiz_dir = vector.angle(x_horiz_dir, horiz_look_dir) < vector.angle(horiz_look_dir, z_horiz_dir) and x_horiz_dir or z_horiz_dir

						local node = minetest.get_node_or_nil(pt.under)
						local node2 = minetest.get_node_or_nil(vector.add(pt.under, target_horiz_dir))
						local node3 = minetest.get_node_or_nil(vector.add(pt.under, vector.add(pt.intersection_normal, target_horiz_dir)))

						if (node and node.name == "portaltest:panel_mono") and
							(node2 and node2.name == "portaltest:panel_mono") and
							(node3 and node3.name == "air") then

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
							local dir_to_top

							local nrmlzed_thd = vector.normalize(target_horiz_dir)
							local target_y_rots = pt.intersection_normal.y == 1 and y_up_rots or y_down_rots

							for p2, dir in pairs(target_y_rots) do
								if vector.equals(nrmlzed_thd, dir) then
									target_param2 = p2
									dir_to_top = dir
									break
								end
							end

							gun.place_portal(player, pt, color, target_param2, dir_to_top)
						end
					end
				end]]

				gun.generate_splash_particles(pt.intersection_point, pt.intersection_normal, color)

			end
            --[[local colls = moveresult.collisions
			minetest.debug("moveresult.collisions: " .. #moveresult.collisions)

            local sum_normal = vector.new()
            for _, coll in ipairs(colls) do
                if coll.axis == "x" then
                    sum_normal = vector.add(sum_normal, vector.normalize({x=coll.old_velocity.x, y=0, z=0}))
                elseif coll.axis == "y" then
                    sum_normal = vector.add(sum_normal, vector.normalize({x=0, y=coll.old_velocity.y, z=0}))
                elseif coll.axis == "z" then
                    sum_normal = vector.add(sum_normal, vector.normalize({x=0, y=0, z=coll.old_velocity.z}))
                end
            end

            sum_normal = vector.multiply(sum_normal, -1)
            local pos = self.object:get_pos()
            local texture = self.object:get_properties().textures[1]
            local s, e = texture:find("%^%[multiply:", 1)
            gun.generate_splash_bounces(pos, sum_normal, texture:sub(e+1, texture:len()))

            self.object:remove()]]
        end
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

minetest.register_on_shutdown(function()
	for i, player in ipairs(minetest.get_connected_players()) do
		player:get_meta():set_string("is_shooting", "")
	end
end)

minetest.register_globalstep(function(dtime)
    gun.global_step_through_players_with_guns()
end)
