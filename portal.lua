-- PORTALS --

portal = {}

-- Return unit direction of node with position 'pos'.
portal.dir = function(pos)
	local node = minetest.get_node(pos)
	return -minetest.facedir_to_dir(node.param2)
end

-- Rotates obj`s collision and selection boxes angles 'rot' (in radians).
-- Rotation occurs relatively to obj`s box rotation!!!
portal.rotate_entity_bounding_box = function(obj, rot)
	if not obj:get_luaentity() then return end

	if not (math.deg(rot.x) % 90 == 0) or not (math.deg(rot.y) % 90 == 0) or not (math.deg(rot.z) % 90 == 0) then return end

	local def = obj:get_properties()
	local colbox = def.collisionbox
	local selbox = def.selectionbox
	local new_colbox = {}
	local new_selbox = {}

	new_colbox[1] = vector.rotate({x=colbox[1], y=colbox[2], z=colbox[3]}, rot)
	new_colbox[2] = vector.rotate({x=colbox[4], y=colbox[5], z=colbox[6]}, rot)

	new_selbox[1] = vector.rotate({x=selbox[1], y=selbox[2], z=selbox[3]}, rot)
	new_selbox[2] = vector.rotate({x=selbox[4], y=selbox[5], z=selbox[6]}, rot)

	local res_colbox = {
		new_colbox[1].x, new_colbox[1].y, new_colbox[1].z,
		new_colbox[2].x, new_colbox[2].y, new_colbox[2].z
	}

	local res_selbox = {
		new_selbox[1].x, new_selbox[1].y, new_selbox[1].z,
		new_selbox[2].x, new_selbox[2].y, new_selbox[2].z
	}

	return res_colbox, res_selbox
end

-- Called each the node timer step.
--If there are objects within 'catch_box' box and their collision boxes are located at 0.1 distance to the portal surface, then teleport them saving their impulse.
portal.teleport_entity = function(pos)
	local meta = minetest.get_meta(pos)
	local connected_to = minetest.deserialize(meta:get_string("connected_to"))
	--minetest.debug("connected_to: " .. (connected_to and minetest.pos_to_string(connected_to) or tostring(nil)))

	if not connected_to then
		--minetest.debug("Nothing can be teleported at the moment as the portal at " .. minetest.pos_to_string(pos) .. " is unconnected!")
		return
	end

	if minetest.get_item_group(minetest.get_node(connected_to).name, "portal") ~= 1 then
		meta:set_string("connected_to", "")
		return
	end

	local pdir = -portal.dir(pos)
	local pdir2 = -portal.dir(connected_to)
	local pdir_rot = vector.dir_to_rotation(pdir)
	local pdir2_rot = vector.dir_to_rotation(pdir2)

	local surf = {vector.new(-0.5, -0.5, -0.5), vector.new(0.5, 1.5, -0.5)}
	local rot_surf = table.copy(surf)

	--rot_surf[1] = vector.rotate(rot_surf[1], pdir_rot)
	--rot_surf[2] = vector.rotate(rot_surf[2], pdir_rot)

	local top_dir = vector.from_string(meta:get_string("dir_to_top"))
	--top_dir = top_dir.y == 0 and -top_dir or top_dir
	local tdir_rot = vector.dir_to_rotation(top_dir)
	pdir_rot.y = pdir_rot.y + tdir_rot.y

	rot_surf[1] = vector.rotate(rot_surf[1], pdir_rot)
	rot_surf[2] = vector.rotate(rot_surf[2], pdir_rot)

	--rot_surf[1] = vector.rotate_around_axis(rot_surf[1], vector.new(0, 1, 0), tdir_rot_y)
	--rot_surf[2] = vector.rotate_around_axis(rot_surf[2], vector.new(0, 1, 0), tdir_rot_y)

	-- Catch_box coordinates are relative to the node`s origin (pos)
	local catch_box = table.copy(rot_surf)
	catch_box[2] = catch_box[2] + pdir*0.5

	local catched_objs = minetest.get_objects_in_area(pos + catch_box[1], pos + catch_box[2])
	--minetest.debug("#catched_objs: " .. #catched_objs)

	local iter_func = function(obj)
		local centre = (pos+rot_surf[1] + pos+rot_surf[2])/2
		local v_to_obj = obj:get_pos() - centre

		local rots_diff = pdir2_rot - pdir_rot
		local new_v = vector.rotate(v_to_obj, rots_diff)

		--local top_dir2 = vector.from_string(minetest.get_meta(connected_to):get_string("dir_to_top"))
		--local tdir2_rot = vector.dir_to_rotation(top_dir2)
		--pdir2_rot.y = pdir2_rot.y + tdir2_rot.y

		local rot_surf2 = table.copy(surf)
		rot_surf2[1] = vector.rotate(rot_surf2[1], pdir2_rot)
		rot_surf2[2] = vector.rotate(rot_surf2[2], pdir2_rot)

		local centre2 = (connected_to+rot_surf2[1] + connected_to+rot_surf2[2])/2

		local proj_vec = pdir2*vector.dot(new_v, pdir2)
		local shift = new_v - proj_vec
		local new_pos = centre2 + (pdir2*0.75 + shift)

		obj:set_pos(new_pos)

		if obj:is_player() then
			obj:set_look_horizontal(pdir2_rot.y)
			local last_vel = vector.from_string(obj:get_meta():get_string("last_vel"))
			local new_vel = vector.rotate(-last_vel, rots_diff)
			obj:add_velocity(-vector.copy(obj:get_velocity())+new_vel)
			--minetest.debug("catch_box: [1]=" .. minetest.pos_to_string(catch_box[1]) .. ", [2]=" .. minetest.pos_to_string(catch_box[2]))
		end

		--[[local centre_point = vector.add(pos, vector.divide(vector.add(catch_box[1], vector.rotate(vector.new(0.4, 1.4, -0.5), pdir_rot)), 2))
		--minetest.debug("centre_point: " .. minetest.pos_to_string(centre_point))
		local epos_dir = vector.subtract(obj:get_pos(), centre_point)

		local origin_epos_dir = vector.rotate(epos_dir, vector.multiply(vector.dir_to_rotation(epos_dir), -1))
		local epos_horiz_dir = vector.rotate(vector.new(origin_epos_dir.x, 0, origin_epos_dir.z), vector.dir_to_rotation(epos_dir))
		local abs_epos_horiz_dir = vector.add(centre_point, epos_horiz_dir)

		local dist_to_epos = vector.length(epos_dir)*math.cos(vector.angle(epos_dir, pdir))
		--minetest.debug("dist_to_epos: " .. dist_to_epos)
		local rel_epos_horiz_dir = vector.subtract(epos_dir, vector.multiply(pdir, dist_to_epos))
		local abs_epos_horiz_dir = vector.add(centre_point, vector.multiply(rel_epos_horiz_dir, -1))

		local raycast = minetest.raycast(abs_epos_horiz_dir, obj:get_pos())

		for pt in raycast do
			if pt.type == "object" and pt.ref == obj then
				local dist_to_psurface = vector.distance(abs_epos_horiz_dir, pt.intersection_point)
				minetest.0debug("dist_to_psurface: " .. dist_to_psurface)

				if not (dist_to_psurface < 0.15) then
					return
				end
			end
		end

		local cportal_dir = minetest.facedir_to_dir(minetest.get_node(connected_to).param2)
		minetest.debug("cportal_dir: " .. minetest.pos_to_string(cportal_dir))
		local box_rot = vector.subtract(vector.dir_to_rotation(cportal_dir), vector.dir_to_rotation(pdir_rot))

		local new_colbox, new_selbox = portal.rotate_entity_bounding_box(obj, box_rot)
		local target_pos = vector.add(connected_to, vector.multiply(vector.divide(cportal_dir, 2), dist_to_epos))
		minetest.debug("target_pos: " .. minetest.pos_to_string(target_pos))

		if minetest.get_node(target_pos).name ~= "air" and not portal.is_pos_busy_by_portal(target_pos) then
			return
		end

		minetest.debug("set_pos()...")
		obj:set_pos(target_pos)
		obj:set_properties({collisionbox = new_colbox, selectionbox = new_selbox})

		if obj:is_player() then
			obj:set_look_vertical(obj:get_look_vertical()+box_rot.x)
			obj:set_look_horizontal(obj:get_look_horizontal()+box_rot.y)
		else
			obj:set_rotation(vector.add(obj:get_rotation(), box_rot))
		end

		local cur_vel = obj:get_velocity()
		local target_vel = vector.rotate(cur_vel, box_rot)

		obj:add_velocity(vector.subtract(target_vel, cur_vel))]]
	end

	for _, obj in ipairs(catched_objs) do
		iter_func(obj)
	end
end

-- Checks for if a portal can be placed in 'above' position in case 'check_exist = false',
-- otherwise checks for existence conditions (moonpanels and free space avialability)
portal.can_exist = function(under, above, top_dir, check_exist)
	check_exist = check_exist or false
	local tdir = vector.copy(top_dir)
	local check1 = minetest.get_item_group(minetest.get_node(under).name, "moonpanel") == 1
	local check2 = minetest.get_item_group(minetest.get_node(under+tdir).name, "moonpanel") == 1
	local check3 = minetest.get_node(above).name == "air"
	local check4 = minetest.get_node(above+tdir).name == "air"
	local check5 = minetest.get_item_group(minetest.get_node(above-tdir).name, "portal") ~= 1

	local total_check

	if not check_exist then
		total_check = check1 and check2 and check3 and check4 and check5
	else
		total_check = check1 and check2 and check4 and check5
	end
	return total_check
end

portal.is_pos_busy_by_portal = function(pos)
	local portal_pos = minetest.find_node_near(pos, 1, {"portaltest:portal_orange", "portaltest:portal_blue"}, true)

	if not portal_pos then return end

	local dir_to_top = vector.from_string(minetest.get_meta(portal_pos):get_string("dir_to_top"))
	local portal_pos2 = vector.add(portal_pos, dir_to_top)

	return vector.distance(pos, portal_pos) < 0.5 or
			vector.distance(pos, portal_pos2) < 0.5
end

--[[portal.check_for_portal_footing = function(pos)
	local dir_to_top = vector.from_string(minetest.get_meta(pos):get_string("dir_to_top"))
	local back_dir = -minetest.facedir_to_dir(minetest.get_node(pos).param2)

	local node1 = minetest.get_node(pos + back_dir)
	local node2 = minetest.get_node(pos + back_dir + dir_to_top)

	if minetest.get_item_group(node1.name, "moonpanel") == 0 or minetest.get_item_group(node2.name, "moonpanel") == 0 then
		minetest.remove_node(pos)
	end
end]]

portal.remove = function(pos)
	local connected_to = minetest.deserialize(minetest.get_meta(pos):get_string("connected_to"))

	if not connected_to or connected_to == {} then
		return
	end

	minetest.get_meta(connected_to):set_string("connected_to", "")

	minetest.remove_node(pos)
end

minetest.register_entity("portaltest:halo_particle", {
    visual = "upright_sprite",
    visual_size = {x=0.5, y=0.5, z=0.5},
    physical = false,
    collide_with_objects = false,
    textures = {"portaltest_halo.png", "portaltest_halo.png"},
    collisionbox = {0, 0, 0, 0, 0, 0},
    use_texture_alpha = true,
    glow = 25,
    on_activate = function(self, staticdata, dtime_s)
		if staticdata ~= "" then
			local data = minetest.deserialize(staticdata)
			self.orig_ang = data.orig_ang
			self.up = vector.copy(data.up)
			self.dir = vector.copy(data.dir)
			self.ppos = data.ppos
			self.color = data.color
		end

		self.object:set_properties({
			textures={"portaltest_" .. self.color .. "_halo.png", "portaltest_" .. self.color .. "_halo.png"}
		})
    end,
    on_step = function(self, dtime)
		local name = minetest.get_node(self.ppos).name

		if minetest.get_item_group(name, "portal") == 0 then
			self.object:remove()
			return
		end

		local dt = 45*dtime
		local ang_to_deg = math.deg(self.orig_ang)

		self.orig_ang = math.rad(ang_to_deg + dt > 360 and dt-(360-ang_to_deg) or ang_to_deg + dt)
		local rpos = vector.rotate_around_axis(self.up, self.dir, self.orig_ang)
		self.object:set_pos(self.ppos+self.up*0.5+self.dir*0.4+rpos*0.75)
		local cur_rot = self.object:get_rotation()
		cur_rot.z = self.orig_ang
		self.object:set_rotation(cur_rot)
    end,
    get_staticdata = function(self)
		return minetest.serialize({ppos=self.ppos, orig_ang=self.orig_ang, up=self.up, dir=self.dir, color=self.color})
    end
})

local function spawn_portal_halo(pos, color)
	local dir = -minetest.facedir_to_dir(minetest.get_node(pos).param2)
	local up = vector.from_string(minetest.get_meta(pos):get_string("dir_to_top"))

	local angles = {
		0,
		math.pi/4,
		math.pi/2,
		math.pi/4 * 3,
		math.pi,
		math.pi/4 * 5,
		math.pi/2 * 3,
		math.pi/4 * 7
	}

	local rot = vector.dir_to_rotation(dir)
	local rot2 = vector.dir_to_rotation(up)

	local centre = pos + up*0.5
	for i, ang in ipairs(angles) do
		local rpos = vector.rotate_around_axis(up, dir, ang)
		local particle = minetest.add_entity(centre + rpos*0.75 + dir*0.4, "portaltest:halo_particle", minetest.serialize({ppos=pos, orig_ang=ang, up=up, dir=dir, color=color}))
		particle:set_rotation(vector.new(rot.x, rot.y+rot2.y, 0))
	end
end

local portals_defs = {
	["orange_uncon"] = {color="orange", uncon=true},
	["orange"] = {color="orange", uncon=false},
	["blue_uncon"] = {color="blue", uncon=true},
	["blue"] = {color="blue", uncon=false}
}

for name, def in pairs(portals_defs) do
	local flame_anim_tile = def.uncon and {
		name = "portaltest_portal_" .. def.color .. "_flame_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 2.0
		}
	} or "portaltest_portal_" .. def.color .. "_flame_animated.png^[opacity:0^[colorize:white"
	minetest.register_node("portaltest:portal_" .. name, {
		description = "Portal",
		drawtype = "mesh",
		mesh = "portaltest_portal.b3d",
		tiles = {"portaltest_" .. def.color .. "_portal.png", flame_anim_tile},
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		groups = {not_in_creative_inventory=1, portal=1},
		light_source = 14,
		collision_box = {
			type = "fixed",
			fixed = {0, 0, 0, 0, 0, 0}
		},
		selection_box = {
			type = "fixed",
			fixed = {0, 0, 0, 0, 0, 0}
		},
		on_construct = function(pos)
			local timer = minetest.get_node_timer(pos)
			timer:start(0.1)
			minetest.after(0.1, function() spawn_portal_halo(pos, def.color) end)
		end,
		on_timer = function(pos, elapsed)
			local dir = portal.dir(pos)
			local under = vector.add(pos, dir)

			local meta = minetest.get_meta(pos)
			if not portal.can_exist(under, pos, vector.from_string(meta:get_string("dir_to_top")), true) then
				local connected_to = minetest.deserialize(meta:get_string("connected_to"))
				if connected_to then
					local oppose_color = def.color == "blue" and "orange" or "blue"
					local oppose_p = minetest.get_node(connected_to)
					minetest.swap_node(connected_to, {name="portaltest:portal_" .. oppose_color .. "_uncon", param1=oppose_p.param1, param2=oppose_p.param2})
				end
				minetest.remove_node(pos)
			end
			portal.teleport_entity(pos)
			return true
		end
	})
end
