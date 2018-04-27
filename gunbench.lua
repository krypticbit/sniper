-- Items: Required:
-- <item> <material>
-- <item> <material>
-- <item> <material>
-- <item> <material>
-- .      .
-- .      .
--         
-- < inventory slots (src, 10)> <outputs (dst, 4)>
-- < inventory slots (src, 10)> <outputs (dst, 4)>


local gun_parts = {"sniper:scope", "sniper:long_barrel", "sniper:sniper_bullet 5"}
local recipes = {["sniper:scope"] = {"default:glass", "technic:carbon_steel_ingot 6"},
                 ["sniper:long_barrel"] = {"sniper:chromoly 6"},
                 ["sniper:sniper_bullet 5"] = {"technic:brass_ingot 2", "default:copper_ingot"},
                }
local time_to_make = {["sniper:scope"] = 3,
                      ["sniper:long_barrel"] = 2.5,
                      ["sniper:sniper_bullet 5"] = 0.5,
                     }
local demand = 3000

local function image_list(items, x_start, y_start, y_offset)
   local fs = ""
   for index, item in pairs(items) do
      fs = fs .. "item_image_button[" .. tostring(x_start) .. "," .. tostring(y_start + y_offset * (index - 1)) .. ";1,1;" .. item .. ";" .. item .. ";]"
   end
   return fs
end

local function image_table(items, x_start, y_start, offset, max_height)
   local fs = ""
   local len = #items
   local times = (len - (len % offset)) / offset
   local columns = {}
   for i=1,times do 
      local c = {}
      for j=1,max_height do
         table.insert(c, items[(i - 1) * max_height + j])
      end
      fs = fs .. image_list(c, x_start + (i - 1) * offset, y_start, offset)
   end
   return fs
end

local function can_dig(pos, player)
   local meta = minetest.get_meta(pos)
   local inv = meta:get_inventory()
   return inv:is_empty("src") and inv:is_empty("dst")
end

local function get_formspec(part)
   -- Create item buttons
   return "size[8,11]" ..
          image_table(gun_parts, 0, 0.5, 1, 4) ..
          "label[0,0;Please select an item:]" ..
          "list[context;src;0,5;5,2]" ..
          "label[0,4.5;Materials:]" ..
          image_list(recipes[part], 4, 0.5, 1) ..
          "label[4,0;Necesarry materials:]" ..
          "list[context;dst;6,5;2,2]" ..
          "label[6,4.5;Output:]" ..
          "list[current_player;main;0,7.2;8,4;]"
end

local on_receive_fields = function(pos, formname, fields, sender)
   for _, part in pairs(gun_parts) do
      if fields[part] then
         local meta = minetest.get_meta(pos)
         meta:set_string("formspec", get_formspec(part))
         meta:set_string("selected", part)
      end
   end
end

local allow_metadata_inventory_put = function(pos, listname, index, stack, player)
   if minetest.is_protected(pos, player:get_player_name()) then
      return 0
   end
   if listname == "src" then
      return stack:get_count()
   elseif listname == "dst" then
      return 0
   end
end

local allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
   if minetest.is_protected(pos, player:get_player_name()) then
      return 0
   end
   if to_list == "dst" then
      return 0
   else
      return count
   end
end

local allow_metadata_inventory_take = function(pos, listname, index, stack, player)
   if minetest.is_protected(pos, player:get_player_name()) then
      return 0
   end
   return stack:get_count()
end

local run = function(pos, node)
   local meta = minetest.get_meta(pos)
   -- Check for meta creation
   local eu_in = meta:get_int("MV_EU_input")
   if not eu_in then
      meta:set_int("MV_EU_demand", 0)
      meta:set_int("MV_EU_input", 0)
      meta:set_int("active", 0)
      return
   end
   -- Check if item can be created
   local inv = meta:get_inventory()
   local required = recipes[meta:get_string("selected")]
   has_needed = true
   for _, item in pairs(required) do
      local s = ItemStack(item)
      if not inv:contains_item("src", s) then
         has_needed = false
      end
   end
   -- Update based on item creation status
   -- If unpowered, wait for power
   if eu_in < meta:get_int("MV_EU_demand") then
      meta:set_string("infotext", "Gun Bench Unpowered")
      meta:set_int("active", 0)
      name = "sniper:gunbench"
   else
      -- Otherwise
      -- Check for required craft items
      local s = meta:get_string("selected")
      if has_needed and inv:room_for_item("dst", s) then -- Required items found, space in dst
         -- Start making
         meta:set_string("infotext", "Gun Bench Active")
         meta:set_int("MV_EU_demand", demand)
         local make_time = time_to_make[s] * 10
         local count = meta:get_int("active") + 1
         if count > make_time then
            count = 0
            local required = recipes[s]
            for _, item in pairs(required) do
               inv:remove_item("src", item)
            end
            inv:add_item("dst", s)
         end
         -- Set "name" so that appearence will be updated
         local r = math.floor(count / make_time * 4 + 0.5) -- math.floor(x + 0.5) = math.round(x)
         name = "sniper:gunbench_active_" .. r
         meta:set_int("active", count)
      else
         -- Not the correct materials
         name = "sniper:gunbench"
         meta:set_string("infotext", "Gun Bench Idle")
         meta:set_int("MV_EU_demand", 0)
         meta:set_int("active", 0)
      end
   end
   -- Update node appearence
   if node.name ~= name then
      minetest.swap_node(pos, {name = name, param2 = node.param2})
   end
end

-- Register gunbench nodes
minetest.register_node("sniper:gunbench", {
   description = "Gun Bench, Makes Gun Parts and Bullets",
   tiles = {"gunbench_top.png", "gunbench_top.png^pipeworks_tube_connection_metallic.png", "gunbench_side.png", "gunbench_side.png", "gunbench_side.png", "gunbench_front.png"},
   paramtype2 = "facedir",
   groups = {cracky = 1, choppy = 2, technic_machine = 1, technic_mv = 1},
   connect_sides = {"bottom"},
   can_dig = can_dig,
   technic_run = run,
   on_construct = function(pos)
      local meta = minetest.get_meta(pos)
      meta:set_string("formspec", get_formspec(gun_parts[1]))
      meta:set_string("selected", gun_parts[1])
      local inv = meta:get_inventory()
      inv:set_size("src", 10)
      inv:set_size("dst", 4)
   end,
   on_receive_fields = on_receive_fields,
   allow_metadata_inventory_put = allow_metadata_inventory_put,
   allow_metadata_inventory_move = allow_metadata_inventory_move,
   allow_metadata_inventory_take = allow_metadata_inventory_take
})

technic.register_machine("MV", "sniper:gunbench", technic.receiver)

for i=0,4 do
   minetest.register_node("sniper:gunbench_active_" .. i, {
      description = "Gun Bench, Makes Gun Parts and Bullets",
      tiles = {"gunbench_top.png", "gunbench_top.png^pipeworks_tube_connection_metallic.png", "gunbench_side.png", "gunbench_side.png", "gunbench_side.png", "gunbench_active_front_" .. i .. ".png"},
      paramtype2 = "facedir",
      groups = {cracky = 1, choppy = 2, technic_machine = 1, technic_mv = 1, not_in_creative_inventory = 1},
      connect_sides = {"bottom"},
      can_dig = can_dig,
      technic_run = run,
      on_receive_fields = on_receive_fields,
      allow_metadata_inventory_put = allow_metadata_inventory_put,
      allow_metadata_inventory_move = allow_metadata_inventory_move,
      allow_metadata_inventory_take = allow_metadata_inventory_take
   })
   
   technic.register_machine("MV", "sniper:gunbench_active_" .. i, technic.receiver)
end

-- Register gunbench craft
minetest.register_craft({
   output = "sniper:gunbench",
   recipe = {{"technic:stainless_steel_block", "technic:motor", "technic:stainless_steel_block"},
             {"mesecons_button:button_off", "technic:diamond_drill_head", "technic:mv_cable"},
             {"technic:rubber", "technic:machine_casing", "technic:rubber"}}
})
