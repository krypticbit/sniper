minetest.register_privilege("keep_zoom", {description = "Grant this along with the 'zoom' priv to allowing zooming", give_to_singleplayer = false})
player_crosshairs = {}

minetest.register_alias("sniper:338", "sniper:sniper_bullet") -- These two are the same bullet, just a different name
minetest.register_alias("sniper:artic_warfare", "sniper:sniper_rifle") -- These two are the same rifle, just a different name

technic.register_alloy_recipe({input = {"xtraores:titanium_bar 5", "technic:chromium_ingot"}, output = "sniper:chromoly 6", time = 10})

local modpath = minetest.get_modpath("sniper")
dofile(modpath .. "/sniper.lua")
dofile(modpath .. "/gunbench.lua")
dofile(modpath .. "/flintlock_gun.lua")

-- Define useful functions
function bulletUpdate(s, dtime, damage, n)
	local pos = s.object:getpos()
	local node = minetest.get_node(pos)
	local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 2)
	for k, obj in pairs(objs) do
		if not (obj:is_player() and obj:get_player_name() == s.shot_by) then
			if obj:get_luaentity() ~= nil then
				local name = obj:get_luaentity().name
				if name ~= n and name ~= "__builtin:item" then
					obj:punch(s.object, 1.0, {
						full_punch_interval = 1.0,
						damage_groups= {fleshy = damage},
					}, nil)
					minetest.sound_play("default_dig_cracky", {pos = s.lastpos, gain = 0.8})
					s.object:remove()
				end
			else
				obj:punch(s.object, 1.0, {
					full_punch_interval = 1.0,
					damage_groups= {fleshy = damage},
				}, nil)
				minetest.sound_play("default_dig_cracky", {pos = s.lastpos, gain = 0.8})
				s.object:remove()
			end
		end
	end
	if s.die <= 0 then
		minetest.sound_play("default_dig_cracky", {pos = s.lastpos, gain = 0.8})
		s.object:remove()
	end
	if s.lastpos.x ~= nil then
		if minetest.registered_nodes[node.name].walkable then
			s.die = s.die - 1
		end
	end
	s.lastpos = {x = pos.x, y = pos.y, z = pos.z}
end
