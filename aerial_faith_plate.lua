local aerial_faith_plate_f = [[
	formspec_version[4]
	size[10,5.5]
	style_type[label;font=normal,bold;font_size=*1.5]
	label[0.5,1;Set up bouncing maximum height and distance:]
	field[1.5,2.5;3,1;max_height;Max Height:;]
	field[5.5,2.5;3,1;max_distance;Max Distance:;]
	button[3.5,4;3,1;save;Save]
	style_type[label;font=normal,bold;font_size=]
]]

minetest.register_node("portaltest:aerial_faith_plate_idle", {
	description = "Aerial Faith Plate (Click to set up parameters of bouncing)",
	drawtype = "mesh",
	mesh = "portaltest_aerial_faith_plate_idle.b3d",
	tiles = {"portaltest_aerial_faith_plate.png"},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "facedir",
	collision_box = {
		type = "fixed",
		fixed = {
			--{-0.85, -1.5, -0.85, 0.85, -0.5, 0.85},
			{-1.5, -0.5, -1.5, 1.5, -0.3, 1.5},
			{-0.85, -0.3, -0.85, 0.85, -0.2, 0.85}
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			--{-0.85, -1.5, -0.85, 0.85, -0.5, 0.85},
			{-1.5, -0.5, -1.5, 1.5, -0.3, 1.5},
			{-0.85, -0.3, -0.85, 0.85, -0.2, 0.85}
		}
	},
	groups = {choppy=2.5},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local owner = minetest.get_meta(pos):get_string("owner")
		local clickername = clicker:get_player_name()

		if owner ~= clickername then
			minetest.chat_send_player(clickername, "You can not edit the parameters of the aerial faith plate as you are not an owner of it!")
			return
		end

		clicker:get_meta():set_string("cur_edited_afp_node_pos", minetest.serialize(pos))
		minetest.show_formspec(clickername, "portaltest:afp_params_form", aerial_faith_plate_f)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		minetest.get_meta(pos):set_string("owner", placer:get_player_name())
	end
})

minetest.register_node("portaltest:aerial_faith_plate_active", {
	description = "Aerial Faith Plate (Click to set up parameters of bouncing)",
	drawtype = "mesh",
	mesh = "portaltest_aerial_faith_plate_active.b3d",
	tiles = {"portaltest_aerial_faith_plate.png"},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "facedir",
	drop = "portaltest:aerial_faith_plate_idle",
	collision_box = {
		type = "fixed",
		fixed = {
			--{-0.85, -1.5, -0.85, 0.85, -0.5, 0.85},
			{-1.5, -0.5, -1.5, 1.5, -0.3, 1.5},
			{-0.1, -0.3, -0.1, 0.1, 0.2, 0.1},
			{-0.85, 0.2, -0.85, 0.85, 0.3, 0.85}
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			--{-0.85, -1.5, -0.85, 0.85, -0.5, 0.85},
			{-1.5, -0.5, -1.5, 1.5, -0.3, 1.5},
			{-0.1, -0.3, -0.1, 0.1, 0.2, 0.1},
			{-0.85, 0.2, -0.85, 0.85, 0.3, 0.85}
		}
	},
	groups = {choppy=2.5, not_in_creative_inventory=1},
	sounds = default.node_sound_wood_defaults(),
	on_timer = function(pos, elapsed)
		minetest.swap_node(pos, {name = "portaltest:aerial_faith_plate_idle", param2 = minetest.get_node(pos).param2})
	end
})
