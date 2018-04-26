minetest.register_privilege("keep_zoom", {description = "Grant this along with the 'zoom' priv to allowing zooming", give_to_singleplayer = false})
player_crosshairs = {}

minetest.register_alias("sniper:338", "sniper:sniper_bullet") -- These two are the same bullet, just a different name
minetest.register_alias("sniper:artic_warfare", "sniper:sniper_rifle") -- These two are the same rifle, just a different name

technic.register_alloy_recipe({input = {"xtraores:titanium_bar 5", "technic:chromium_ingot"}, output = "sniper:chromoly 6", time = 10})

local modpath = minetest.get_modpath("sniper")
dofile(modpath .. "/sniper.lua")
dofile(modpath .. "/gunbench.lua")
