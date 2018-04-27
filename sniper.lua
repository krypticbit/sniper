function check_for_hold(dtime)
   for _, p in pairs(minetest.get_connected_players()) do
      local n = p:get_player_name()
      local w = p:get_wielded_item():get_name()
      local privs = minetest.get_player_privs(n)
      if w == "sniper:artic_warfare" or w == "sniper:sniper_rifle" then
         -- Add custom scope crasshairs
         if not player_crosshairs[n] then
            p:hud_set_flags({crosshair = false})
            player_crosshairs[n] = p:hud_add({
               hud_elem_type = "image",
               scale = {x = 1, y = 1},
               text = "crosshairs.png",
               position = {x = 0.5, y = 0.5},
               alignment = {x = 0, y = 0},
               offset = {x = 0, y = 0}
            })
         end
         -- Allow "scope" zooming
         if not privs["zoom"] then
            privs["zoom"] = true
            minetest.set_player_privs(n, privs)
         end
      else
         if player_crosshairs[n] then
	        p:hud_remove(player_crosshairs[n])
	        player_crosshairs[n] = nil
	        p:hud_set_flags({crosshair = true})
	     end
	     if not privs["keep_zoom"] and privs["zoom"] then
	        privs["zoom"] = nil
	        minetest.set_player_privs(n, privs)
         end
      end
   end
end



minetest.register_craftitem("sniper:sniper_bullet", {
	description = "Basic Sniper Bullet",
	stack_max = 500,
	inventory_image = "338.png",
})

minetest.register_craftitem("sniper:scope", {
   description = "Scope",
   stack_max = 5,
   inventory_image = "scope.png"
})

minetest.register_craftitem("sniper:long_barrel", {
   description = "Long rifle barrel",
   stack_max = 2,
   inventory_image = "l_barrel.png"
})

minetest.register_craftitem("sniper:chromoly", {
   description = "Chromoly - used in making gun barrels",
   stack_max = 99,
   inventory_image = "chromoly.png"
})

minetest.register_craft({
   output = "sniper:sniper_rifle",
   recipe = {{"", "sniper:scope", ""},
             {"sniper:long_barrel", "xtraores:titanium_bar", "group:wool"},
             {"", "xtraores:titanium_bar", ""}}
})

local SNIPER_BULLET = {
	physical = false,
	timer = 0,
	visual = "sprite",
	visual_size = {x=0.075, y=0.075,},
	textures = {'xtraores_titanium_shot.png'},
	lastpos = {},
	die = 3, -- penetration power
	shot_by = "",
	collisionbox = {0, 0, 0, 0, 0, 0},
	on_step = function(self, dtime) bulletUpdate(self, dtime, 130, "sniper:sniper_bullet") end
}

minetest.register_entity("sniper:sniper_bullet", SNIPER_BULLET)

minetest.register_tool("sniper:sniper_rifle", {
	description = "Basic Sniper Rifle",
	inventory_image = "sniper.png",
	wield_scale = {x = 1, y = 1, z = 1},
	on_use = function(itemstack, user, pointed_thing)
		local inv = user:get_inventory()
		if not inv:contains_item("main", "sniper:sniper_bullet 1") and not inv:contains_item("main", "sniper:338 1") then
			minetest.sound_play("empty", {object=user})
			return itemstack
		end
		if not minetest.setting_getbool("creative_mode") then
			inv:remove_item("main", "sniper:sniper_bullet")
		end
		local pos = user:getpos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_yaw()
		if pos and dir and yaw then
			pos.y = pos.y + 1.4
			local obj = minetest.add_entity(pos, "sniper:sniper_bullet")
			if obj then
				minetest.sound_play("shot", {object=obj})
				obj:setvelocity({x=dir.x * 60, y=dir.y * 60, z=dir.z * 60})
				obj:setacceleration({x=dir.x * -0, y=-0, z=dir.z * -0})
				obj:setyaw(yaw + math.pi)
				local ent = obj:get_luaentity()
				ent.shot_by = user:get_player_name()
				if ent then
					ent.player = ent.player or user
				end
			end
		end
		return itemstack
	end
})

minetest.register_globalstep(check_for_hold)

