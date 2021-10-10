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
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
			formspec_version[4]
			size[9,7]
			style_type[label;font=normal,bold;font_size=*1.5]
			]] ..
			"label[1.5,1;Set up bouncing direction and\n maximum height and distance:]" ..
			[[
			style_type[label;font=normal,bold;font_size=]
			label[1.5,2.5;Max Height:]
			label[5.5,2.5;Max Distance:]
			label[3.5,4;Direction:]
			field[1.5,3;2,0.5;max_height;;]
			field[5.5,3;2,0.5;max_distance;;]
			field[3.5,4.5;2,0.5;direction;;]
			button[3,5.5;3,1;save;Save]
		]])
	end
})
