minetest.register_node("portaltest:gun", {
    drawtype = "mesh",
    visual_scale = 0.5,
    tiles = {"portaltest_gun.png"},
    mesh = "portaltest_gun.b3d",
    description = "Portal Gun",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    collision_box = {0, 0, 0, 0, 0, 0},
    selection_box = {0, 0, 0, 0, 0, 0},
    on_construct = function(pos)
        return nil
    end,
    on_place = function(itemstack, placer, pointed_thing)
        return nil
    end
}) 
