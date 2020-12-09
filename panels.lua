minetest.register_node("portaltest:panel_mono", {
    description = "Mono Panel",
    drawtype = "normal",
    tiles = {"portaltest_while_panel.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    groups = {cracky=1.5},
    sounds = default.node_sound_stone_defaults()
}) 
