-- PORTALS -- 

portal = {}

-- Return unit direction of node with position 'pos'.
portal.dir = function(pos)
	local node = minetest.get_node(pos)
	local back_dir = minetest.facedir_to_dir(node.param2)
	
	local dir = vector.multiply(back_dir, -1)
	
	return dir
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
	local connected_to = minetest.deserialize(minetest.get_meta(pos):get_string("connected_to"))
	--minetest.debug("connected_to: " .. (connected_to and minetest.pos_to_string(connected_to) or tostring(nil)))
	
	if not connected_to then
		--minetest.debug("Nothing can be teleported at the moment as the portal at " .. minetest.pos_to_string(pos) .. " is unconnected!")
		return
	end
	
	local pdir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
	-- Catch_box coordinates are relative to the node`s origin (pos)
	local catch_box = {vector.new(-0.4, -0.4, -0.5), vector.new(0.4, 1.4, -0.5)}
	local pdir_rot = vector.dir_to_rotation(pdir)
	
	catch_box[1] = vector.rotate(catch_box[1], pdir_rot)
	catch_box[2] = vector.add(vector.rotate(catch_box[2], pdir_rot), vector.multiply(pdir, 1.45))
	minetest.debug("catch_box: [1]=" .. minetest.pos_to_string(vector.add(pos, catch_box[1])) .. ", [2]=" .. minetest.pos_to_string(vector.add(pos, catch_box[2])))
	
	local catched_objs = minetest.get_objects_in_area(vector.add(pos, catch_box[1]), vector.add(pos, catch_box[2]))
	--minetest.debug("#catched_objs: " .. #catched_objs)
	
	local iter_func = function(obj)
		local centre_point = vector.add(pos, vector.divide(vector.add(catch_box[1], vector.rotate(vector.new(0.4, 1.4, -0.5), pdir_rot)), 2))
		--minetest.debug("centre_point: " .. minetest.pos_to_string(centre_point))
		local epos_dir = vector.subtract(obj:get_pos(), centre_point)
		
		--[[local origin_epos_dir = vector.rotate(epos_dir, vector.multiply(vector.dir_to_rotation(epos_dir), -1))
		local epos_horiz_dir = vector.rotate(vector.new(origin_epos_dir.x, 0, origin_epos_dir.z), vector.dir_to_rotation(epos_dir))
		local abs_epos_horiz_dir = vector.add(centre_point, epos_horiz_dir)]]
		
		local dist_to_epos = vector.length(epos_dir)*math.cos(vector.angle(epos_dir, pdir))
		--minetest.debug("dist_to_epos: " .. dist_to_epos)
		local rel_epos_horiz_dir = vector.subtract(epos_dir, vector.multiply(pdir, dist_to_epos))
		local abs_epos_horiz_dir = vector.add(centre_point, vector.multiply(rel_epos_horiz_dir, -1))
		
		local raycast = minetest.raycast(abs_epos_horiz_dir, obj:get_pos())
		
		for pt in raycast do
			if pt.type == "object" and pt.ref == obj then
				local dist_to_psurface = vector.distance(abs_epos_horiz_dir, pt.intersection_point)
				minetest.debug("dist_to_psurface: " .. dist_to_psurface)
				
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
		
		obj:add_velocity(vector.subtract(target_vel, cur_vel))
	end
	
	for _, obj in ipairs(catched_objs) do
		iter_func(obj)
	end
end
					
portal.is_pos_busy_by_portal = function(pos)
	local portal_pos = minetest.find_node_near(pos, 1, {"portaltest:portal_orange", "portaltest:portal_blue"}, true)
	
	if not portal_pos then return end
	
	local dir_to_top = minetest.deserialize(minetest.get_meta(portal_pos):get_string("dir_to_top"))
	local portal_pos2 = vector.add(portal_pos, dir_to_top)
	
	return vector.distance(pos, portal_pos) < 0.5 or
			vector.distance(pos, portal_pos2) < 0.5
end

portal.check_for_portal_footing = function(pos)
	local dir_to_top = minetest.deserialize(minetest.get_meta(pos):get_string("dir_to_top"))
	local back_dir = vector.multiply(minetest.facedir_to_dir(minetest.get_node(pos).param2), -1)
	
	local node1 = minetest.get_node(vector.add(pos, back_dir))
	local node2 = minetest.get_node(vector.add(pos, vector.add(back_dir, dir_to_top)))
	
	if node1.name == "air" or node2.name == "air" then
		minetest.remove_node(pos)
	end
end

portal.remove = function(pos)
	local connected_to = minetest.deserialize(minetest.get_meta(pos):get_string("connected_to"))
	
	if not connected_to or connected_to == {} then
		return
	end
	
	minetest.get_meta(connected_to):set_string("connected_to", "")
	
	minetest.remove_node(pos)
end

minetest.register_node("portaltest:portal_orange", {
	description = "Portal",
	drawtype = "mesh",
	mesh = "portaltest_portal.b3d",
	tiles = {"portaltest_orange_portal.png"},	
	paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
	groups = {not_in_creative_inventory=1},
	light_source = 14,
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.4, -0.4},   	-- Bottom Box
			{-0.5, -0.4, -0.5, -0.4, 1.4, -0.4},	-- Left Box
			{0.4, -0.4, -0.5, 0.5, 1.4, -0.4},		-- Right Box
			{-0.5, 1.4, -0.5, 0.5, 1.5, -0.4}		-- Top Box
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {0, 0, 0, 0, 0, 0}
	},
	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(0.1)
	end,
	on_destruct = function(pos)
		portal.remove(pos)
	end,
	on_timer = function(pos, elapsed)
		portal.teleport_entity(pos)
		portal.check_for_portal_footing(pos)
		return true
	end
}) 

minetest.register_node("portaltest:portal_blue", {
	description = "Portal",
	drawtype = "mesh",
	mesh = "portaltest_portal.b3d",
	tiles = {"portaltest_blue_portal.png"},	
	paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
	groups = {not_in_creative_inventory=1},
	light_source = 14,
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.4, -0.4},   	-- Bottom Box
			{-0.5, -0.4, -0.5, -0.4, 1.4, -0.4},	-- Left Box
			{0.4, -0.4, -0.5, 0.5, 1.4, -0.4},		-- Right Box
			{-0.5, 1.4, -0.5, 0.5, 1.5, -0.4}		-- Top Box
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {0, 0, 0, 0, 0, 0}
	},
	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(0.1)
	end,
	on_destruct = function(pos)
		portal.remove(pos)
	end,
	on_timer = function(pos, elapsed)
		portal.teleport_entity(pos)
		portal.check_for_portal_footing(pos)
		return true
	end
}) 
