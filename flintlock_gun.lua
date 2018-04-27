minetest.register_craftitem("sniper:flintlock_bullet", {
	description = "Flintlock Cartridge and Bullet",
	stack_max = 500,
	inventory_image = "flintlock_bullet.png",
})

minetest.register_craftitem("sniper:gunpowder", {
	description = "Gunpowder",
	stack_max = 500,
	inventory_image = "gunpowder.png",
})

minetest.register_tool("sniper:flintlock_gun", {
	description = "Flintlock Rifle",
	inventory_image = "flintlock.png",
	wield_scale = {x = 1, y = 1, z = 1},
	on_use = function(itemstack, user, pointed_thing)
		local inv = user:get_inventory()
		if not inv:contains_item("main", "sniper:flintlock_bullet 1") then
			minetest.sound_play("empty", {object=user})
			return itemstack
		end
		if not minetest.setting_getbool("creative_mode") then
			inv:remove_item("main", "sniper:flintlock_bullet")
		end
		local pos = user:getpos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_yaw()
		if pos and dir and yaw then
			pos.y = pos.y + 1.4
			local obj = minetest.add_entity(pos, "sniper:flintlock_bullet")
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

local FLINTLOCK_BULLET = {
	physical = false,
	timer = 0,
	visual = "sprite",
	visual_size = {x=0.075, y=0.075,},
	textures = {'xtraores_titanium_shot.png'},
	lastpos = {},
	die = 3, -- penetration power
	shot_by = "",
	collisionbox = {0, 0, 0, 0, 0, 0},
	on_step = function(self, dtime) bulletUpdate(self, dtime, 20, "sniper:flintlock_bullet") end
}

minetest.register_entity("sniper:flintlock_bullet", FLINTLOCK_BULLET)

minetest.register_craft({
   output = "sniper:gunpowder",
   recipe = {{"deafult:coal_lump", "", ""},
             {"technic:sulfur_lump", "", ""},
             {"deafult:coal_lump", "", ""}}
})

minetest.register_craft({
   output = "sniper:flintlock_gun",
   recipe = {{"fire:flint_and_steel", "default:steel_ingot", "default:steel_ingot"},
             {"group:wood", "default:steel_ingot", "group:wool"},
             {"group:wood", "", ""}}
})

minetest.register_craft({
   output = "sniper:flintlock_bullet 5",
   recipe = {{"default:paper", "", ""},
             {"sniper:gunpowder", "", "default:copper_ingot"},
             {"default:paper", "", ""}}
})
