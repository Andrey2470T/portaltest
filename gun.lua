local gun = {}

gun.SPLASH_STREAM_GRAVITY = 9.8
gun.SPLASH_STREAM_SPEED = 50        -- metres/second
gun.SPLASH_DROP_LIFETIME = 2		-- seconds

gun.generate_splash_bounces = function(pos, normal, splash_color)
    local rand_amount = math.random(20, 25)
    
    local side = vector.rotate_around_axis({x=normal.x, y=0, z=normal.z}, {x=0, y=1, z=0}, math.pi/2)
    
    local signs = {-1, 1}
    for i = 1, rand_amount do
        local rand_pitch = math.rad(math.random(10, 45)) * signs[math.random(1, 2)]
        local rand_yaw = math.rad(math.random(10, 45)) * signs[math.random(1, 2)]
        
        normal = vector.rotate_around_axis(normal, side, rand_pitch)
        local up = vector.cross(side, normal)
        
        local res_dir = vector.rotate_around_axis(normal, up, rand_yaw)
        
        local splash_drop = minetest.add_entity(pos, "portaltest:splash_drop")
        splash_drop:set_properties({textures={"portaltest_splash_drop.png^[multiply:" .. splash_color}})
        splash_drop:set_velocity(vector.multiply(res_dir, 10))
    end
end

gun.bounce_splash_drop = function(drop, surface_normal)
	local self = drop:get_luaentity()
	
	if not self then return end
	
	local new_vel = vector.multiply(self.last_velocity, -1)
	local cross = vector.cross(new_vel, surface_normal)
	new_vel = vector.rotate_around_axis(new_vel, cross, vector.angle(surface_normal, new_vel)*2)
	
	drop:set_velocity(new_vel)
end

gun.global_step_through_players_with_guns = function()
    local players = minetest.get_connected_players()
    
    for i, player in ipairs(players) do
        if player:get_wielded_item():get_name() == "portaltest:gun_empty" then
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
            local rel_offset_pos = vector.add(vector.new(0, 0, 1), vector.new(1, 0, 0))
            
            rel_offset_pos = vector.rotate(rel_offset_pos, {x=player:get_look_vertical(), y=player:get_look_horizontal(), z=0})
            local pos = vector.add(pl_pos, rel_offset_pos)
            local splash_stream = minetest.add_entity(pos, "portaltest:splash_stream")
            splash_stream:set_properties({textures={"portaltest_splash_stream.png^[multiply:" .. color}})
            splash_stream:set_velocity(vector.multiply(player:get_look_dir(), gun.SPLASH_STREAM_SPEED))
                
            minetest.after(0.5, function()
                player:set_wielded_item(ItemStack("portaltest:gun_empty"))
            end)
        end
    end
end

minetest.register_node("portaltest:gun_empty", {
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
})




minetest.register_entity("portaltest:splash_stream", {
    visual = "sprite",
    visual_size = {x=1, y=1, z=1},
    physical = true,
    collide_with_objects = true,
    collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
	selectionbox = {0, 0, 0, 0, 0, 0},
    textures = {"portaltest_splash_stream.png"},
    backface_culling = false,
    glow = 7,
    on_activate = function(self, staticdata, dtime_s)
        self.object:set_acceleration({x=0, y=-gun.SPLASH_STREAM_GRAVITY, z=0})
    end,
    on_step = function(self, dtime, moveresult)
        if moveresult.collides then
            local colls = moveresult.collisions
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
                                                          
            self.object:remove()
        end
    end
})

minetest.register_entity("portaltest:splash_drop", {
    visual = "sprite",
    visual_size = {x=1, y=1, z=1},
    physical = true,
    collide_with_objects = true,
    textures = {"portaltest_splash_drop.png"},
    collisionbox = {-0.05, -0.05, -0.05, 0.05, 0.05, 0.05},
	selectionbox = {0, 0, 0, 0, 0, 0},
    backface_culling = false,
    glow = 7,
    on_activate = function(self, staticdata, dtime_s)
        self.object:set_acceleration({x=0, y=-gun.SPLASH_STREAM_GRAVITY, z=0})
		self.last_velocity = self.object:get_velocity()
		self.dtime = 0
    end,
    on_step = function(self, dtime, moveresult)
		self.dtime = self.dtime + dtime
		
		if not moveresult.collides then
			self.last_velocity = self.object:get_velocity()
		else
			local pos = self.object:get_pos()
			local vel = self.object:get_velocity()
			local pos2 = vector.add(pos, vector.multiply(vel, dtime))
			local raycast = minetest.raycast(pos, pos2)
			local pt = raycast:next()
		
			if pt then
				gun.bounce_splash_drop(self.object, pt.intersection_normal)
			end
        end
                                                   
		if self.dtime >= gun.SPLASH_DROP_LIFETIME then
			self.object:remove()
		end
    end    
})


minetest.register_globalstep(function(dtime)
    gun.global_step_through_players_with_guns()
end)
