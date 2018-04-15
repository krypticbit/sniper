minetest.register_privilege("keep_zoom", {description = "Grant this along with the 'zoom' priv to allowing zooming", give_to_singleplayer = false})
player_crosshairs = {}

minetest.register_craft({
   output = "sniper:artic_warfare",
   recipe = {{"", "sniper:scope", ""},
             {"sniper:long_barrel", "xtraores:titanium_bar", "group:wool"},
             {"", "xtraores:titanium_bar", ""}}
})

minetest.register_craft({
   output = "sniper:scope",
   recipe = {{"technic:carbon_steel_ingot", "technic:carbon_steel_ingot", "technic:carbon_steel_ingot"},
             {"default:glass", "", "default:glass"},
             {"technic:carbon_steel_ingot", "technic:carbon_steel_ingot", "technic:carbon_steel_ingot"}}
})

minetest.register_craft({
   output = "sniper:long_barrel",
   recipe = {{"sniper:chromoly", "sniper:chromoly", "sniper:chromoly"},
             {"", "", ""},
             {"sniper:chromoly", "sniper:chromoly", "sniper:chromoly"}}
})

minetest.register_craft({
   output = "sniper:338 2",
   recipe = {{"default:copper_ingot", "", ""},
             {"technic:brass_ingot", "", ""},
             {"technic:brass_ingot", "", ""}}
})

technic.register_alloy_recipe({input = {"xtraores:titanium_bar 5", "technic:chromium_ingot"}, output = "sniper:chromoly 6", time = 10})

function bullet_on_step(s, dtime, bulletName, damage)
	s.timer = s.timer + dtime
	local pos = s.object:getpos()
	local node = minetest.get_node(pos)

	if s.timer > 0.08 then
		local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 2)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= bulletName and obj:get_luaentity().name ~= "__builtin:item" then
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

	if s.lastpos.x ~= nil then
		if minetest.registered_nodes[node.name].walkable then
			if not minetest.setting_getbool("creative_mode") then
				minetest.add_item(s.lastpos, "")
			end
			minetest.sound_play("default_dig_cracky", {pos = s.lastpos, gain = 0.8})
			s.object:remove()
		end
	end
	s.lastpos= {x = pos.x, y = pos.y, z = pos.z}
end

function check_for_hold(dtime)
   for _, p in pairs(minetest.get_connected_players()) do
      local n = p:get_player_name()
      local w = p:get_wielded_item():get_name()
      local privs = minetest.get_player_privs(n)
      if w == "sniper:artic_warfare" then
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

minetest.register_craftitem("sniper:338", {
	description = "338. (Ammo for Arctic Warfare)",
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

minetest.register_tool("sniper:artic_warfare", {
	description = "Arctic Warfare (needs 338. to shoot | deals 130 dmg)",
	inventory_image = "AW_inv.png",
	wield_scale = {x = 1, y = 1, z = 1},
	on_use = function(itemstack, user, pointed_thing)
		local inv = user:get_inventory()
		if not inv:contains_item("main", "sniper:338 1") then
			minetest.sound_play("empty", {object=user})
			return itemstack
		end
		if not minetest.setting_getbool("creative_mode") then
			inv:remove_item("main", "sniper:338")
		end
		local pos = user:getpos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_yaw()
		if pos and dir and yaw then
			pos.y = pos.y + 1.6
			local obj = minetest.add_entity(pos, "sniper:aw")
			if obj then
				minetest.sound_play("shot", {object=obj})
				obj:setvelocity({x=dir.x * 60, y=dir.y * 60, z=dir.z * 60})
				obj:setacceleration({x=dir.x * 0, y=0, z=dir.z * 0})
				obj:setyaw(yaw + math.pi)
				local ent = obj:get_luaentity()
				if ent then
					ent.player = ent.player or user
				end
			end
		end
		return itemstack
	end,
})


local SNIPER_AW = {
	physical = false,
	timer = 0,
	visual = "sprite",
	visual_size = {x=0.075, y=0.075},
	textures = {'xtraores_precious_shot.png'},
	lastpos= {},
	collisionbox = {0, 0, 0, 0, 0, 0},
}

minetest.register_entity("sniper:aw", SNIPER_AW)

minetest.register_globalstep(check_for_hold)

SNIPER_AW.on_step = function(self, dtime)
	bullet_on_step(self, dtime, "sniper:aw", 130)
end
