local random = water_life.random



if not water_life.petz and not water_life.mobsredo then
-- lasso

	minetest.register_tool("water_life:lasso", {
		description = ("Lasso (right-click animal to capture it)"),
		inventory_image = "water_life_lasso.png",
		groups = {flammable = 2}
	})

	if minetest.get_modpath("farming") then
		minetest.register_craft({
			output = "water_life:lasso",
			recipe = {
				{"farming:string", "", "farming:string"},
				{"", "default:diamond", ""},
				{"farming:string", "", "farming:string"}
			}
		})
	end
	

end


-- only one kind of meat if mobs_redo is present
if not water_life.mobsredo then
	
	-- raw meat
	minetest.register_craftitem("water_life:meat_raw", {
		description = ("Raw Meat"),
		inventory_image = "water_life_meat_raw.png",
		on_use = minetest.item_eat(3),
		groups = {food_meat_raw = 1, flammable = 2}
	})

	-- cooked meat
	minetest.register_craftitem("water_life:meat", {
		description = ("Meat"),
		inventory_image = "water_life_meat.png",
		on_use = minetest.item_eat(8),
		groups = {food_meat = 1, flammable = 2}
	})

	minetest.register_craft({
		type = "cooking",
		output = "water_life:meat",
		recipe = "water_life:meat_raw",
		cooktime = 5
	})

	minetest.register_alias("mobs:meat_raw","water_life:meat_raw")
	minetest.register_alias("mobs:meat","water_life:meat")
	
else
	minetest.register_alias("water_life:meat_raw","mobs:meat_raw")
	minetest.register_alias("water_life:meat","mobs:meat")
	
end

-- revive corals if a living one is around
minetest.register_abm({
	nodenames = {"default:coral_skeleton","water_life:artificial_skeleton"},
	neighbors = {"default:water_source"},
	interval = 30,  --30
	chance = 5,	--10
	catch_up = false,
	action = function(pos, node)
		local table = minetest.find_nodes_in_area({x=pos.x-2, y=pos.y-2, z=pos.z-2}, {x=pos.x+2, y=pos.y+2, z=pos.z+2}, water_life.urchinspawn)
		local nname = "default:coral_skeleton"
		if table and #table > 0 then nname = minetest.get_node(table[water_life.random(#table)]).name end
		minetest.set_node(pos, {name = nname})
	end,
})


minetest.register_node("water_life:artificial_skeleton", {
	description = "artificial coral skeleton",
	tiles = {"default_coral_skeleton.png"},
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
		
		output = "water_life:artificial_skeleton 4",
		type   = "shapeless",
		recipe = {"default:silver_sandstone","default:silver_sandstone","default:silver_sandstone","default:coral_skeleton"}
	})



if not water_life.apionly then
	
		minetest.register_craftitem("water_life:riverfish", {
			description = ("Riverfish"),
			inventory_image = "water_life_riverfish_item.png",
			wield_scale = {x = 0.5, y = 0.5, z = 0.5},
			stack_max = 10,
			liquids_pointable = false,
			range = 10,
			on_use = minetest.item_eat(3),                                    
			groups = {food_meat = 1, flammable = 2},
			on_place = function(itemstack, placer, pointed_thing)
				if placer and not placer:is_player() then return itemstack end
				if not pointed_thing then return itemstack end
				if not pointed_thing.type == "node" then return itemstack end
				
				local pos = pointed_thing.above
				local number = water_life.count_objects(pos)
				if number.all > water_life.maxmobs or number.fish > 10 then return itemstack end
															
				local name = placer:get_player_name()
				if minetest.is_protected(pos,name) then return itemstack end

				local obj = minetest.add_entity(pos, "water_life:fish_tamed")
				obj = obj:get_luaentity()
				itemstack:take_item()
				obj.owner = name
				return itemstack
			end,
		})

		minetest.register_craftitem("water_life:piranha", {
			description = ("Piranha"),
			inventory_image = "water_life_piranha_item.png",
			wield_scale = {x = 0.5, y = 0.5, z = 0.5},
			stack_max = 10,
			liquids_pointable = false,
			range = 10,
			on_use = minetest.item_eat(5),                                    
			groups = {food_meat = 1, flammable = 2},
			on_place = function(itemstack, placer, pointed_thing)
				if placer and not placer:is_player() then return itemstack end
				if not pointed_thing then return itemstack end
				if not pointed_thing.type == "node" then return itemstack end
				
				local pos = pointed_thing.above
				local number = water_life.count_objects(pos,nil,"water_life:piranha")
				if number.all > water_life.maxmobs or number.name > 10 then return itemstack end
															
				local name = placer:get_player_name()
				if minetest.is_protected(pos,name) then return itemstack end

				local obj = minetest.add_entity(pos, "water_life:piranha_tamed")
				obj = obj:get_luaentity()
				itemstack:take_item()
				--obj.owner = name
				return itemstack
			end,
		})

minetest.register_craftitem("water_life:coralfish", {
			description = ("Coralfish"),
			inventory_image = "water_life_coralfish_item.png",
			wield_scale = {x = 0.5, y = 0.5, z = 0.5},
			stack_max = 10,
			liquids_pointable = false,
			range = 10,
			on_use = minetest.item_eat(1),                                    
			groups = {food_meat = 1, flammable = 2},
			on_place = function(itemstack, placer, pointed_thing)
				if placer and not placer:is_player() then return itemstack end
				if not pointed_thing then return itemstack end
				if not pointed_thing.type == "node" then return itemstack end
				
				local pos = pointed_thing.above
				local number = water_life.count_objects(pos,nil,"water_life:coralfish_tamed")
				if number.all > water_life.maxmobs or number.name > 10 then return itemstack end
															
				local name = placer:get_player_name()
				if minetest.is_protected(pos,name) then return itemstack end

				local obj = minetest.add_entity(pos, "water_life:coralfish_tamed")
				if obj then
							local entity = obj:get_luaentity()
							entity.base = nil
							entity.owner = name
							entity.head = random(65535)
				end
				itemstack:take_item()
				
				return itemstack
			end,
		})

minetest.register_craftitem("water_life:clownfish", {
			description = ("Clownfish"),
			inventory_image = "water_life_clownfish_item.png",
			wield_scale = {x = 0.5, y = 0.5, z = 0.5},
			stack_max = 10,
			liquids_pointable = false,
			range = 10,
			on_use = minetest.item_eat(1),                                    
			groups = {food_meat = 1, flammable = 2},
			on_place = function(itemstack, placer, pointed_thing)
				if placer and not placer:is_player() then return itemstack end
				if not pointed_thing then return itemstack end
				if not pointed_thing.type == "node" then return itemstack end
				
				local pos = pointed_thing.above
				local number = water_life.count_objects(pos,nil,"water_life:clownfish_tamed")
				if number.all > water_life.maxmobs or number.name > 10 then return itemstack end
															
				local name = placer:get_player_name()
				if minetest.is_protected(pos,name) then return itemstack end

				local obj = minetest.add_entity(pos, "water_life:clownfish_tamed")
				obj = obj:get_luaentity()
				itemstack:take_item()
				obj.owner = name
				return itemstack
			end,
		})

		minetest.register_craftitem("water_life:urchin_item", {
			description = ("Sea urchin"),
			inventory_image = "water_life_urchin_item.png",
			wield_scale = {x = 0.4, y = 0.4, z = 0.4},
			stack_max = 10,
			liquids_pointable = false,
			range = 10,
			on_use = minetest.item_eat(2),                                    
			groups = {food_meat = 1, flammable = 2},
			on_place = function(itemstack, placer, pointed_thing)
				if placer and not placer:is_player() then return itemstack end
				if not pointed_thing then return itemstack end
				if not pointed_thing.type == "node" then return itemstack end
				
				local pos = pointed_thing.above
				local number = water_life.count_objects(pos,10,"water_life:urchin")
				if number.all > water_life.maxmobs or number.name > 10 then return itemstack end
															
				local name = placer:get_player_name()
				if minetest.is_protected(pos,name) then return itemstack end

				local obj = water_life.set_urchin(pos)
				obj = obj:get_luaentity()
				itemstack:take_item()
				--obj.owner = name
				return itemstack
			end,
		})
		
		


		minetest.register_craftitem("water_life:jellyfish_item", {
			description = ("Jellyfish"),
			inventory_image = "water_life_jellyfish_item.png",
			wield_scale = {x = 0.4, y = 0.4, z = 0.4},
			stack_max = 10,
			liquids_pointable = false,
			range = 10,
			on_use = minetest.item_eat(1),                                    
			groups = {food_meat = 1, flammable = 2},
			on_place = function(itemstack, placer, pointed_thing)
				if placer and not placer:is_player() then return itemstack end
				if not pointed_thing then return itemstack end
				if not pointed_thing.type == "node" then return itemstack end
				
				local pos = pointed_thing.above
				local number = water_life.count_objects(pos,10,"water_life:jellyfish")
				if number.all > water_life.maxmobs or number.name > 10 then return itemstack end
															
				local name = placer:get_player_name()
				if minetest.is_protected(pos,name) then return itemstack end

				local obj = minetest.add_entity(pos, "water_life:jellyfish")
				
				if obj then itemstack:take_item() end
				
				return itemstack
			end,
		})
end

--muddy water

if water_life.muddy_water then

		minetest.register_node("water_life:muddy_river_water_source", {
			description = "Muddy river water source",
			drawtype = "liquid",
			waving = 3,
			tiles = {
				{
					name="water_life_muddy_river_water_flowing.png",
					animation = {
						type = "vertical_frames",
						aspect_w = 16,
						aspect_h = 16,
						length = 2.0,
					},
				},
			},
			special_tiles = {
				{
					name="water_life_muddy_river_water_flowing.png",
					animation = {
						type = "vertical_frames",
						aspect_w = 16,
						aspect_h = 16,
						length = 2.0,
					},
					backface_culling = false,
				},
			},
			alpha = 224,
			paramtype = "light",
			walkable = false,
			pointable = false,
			diggable = false,
			buildable_to = true,
			is_ground_content = false,
			drop = "",
			drowning = 1,
			liquidtype = "source",
			liquid_alternative_flowing = "water_life:muddy_river_water_flowing",
			liquid_alternative_source = "water_life:muddy_river_water_source",
			liquid_viscosity = 1,
			liquid_renewable = true,
			liquid_range = 3,
			post_effect_color = {a = 232, r = 92, g = 80, b = 48},
			groups = {water = 3, liquid = 3, puts_out_fire = 1},
		})

		minetest.register_node("water_life:muddy_river_water_flowing", {
			description = "Flowing muddy river water",
			drawtype = "flowingliquid",
			waving = 3,
			tiles = {"water_life_muddy_river_water_source.png"},
			special_tiles = {
				{
					image="water_life_muddy_river_water_flowing.png",
					backface_culling = false,
					animation = {
						type = "vertical_frames",
						aspect_w = 16,
						aspect_h = 16,
						length = 0.8,
					},
				},
				{
					image="water_life_muddy_river_water_flowing.png",
					backface_culling = true,
					animation = {
						type = "vertical_frames",
						aspect_w = 16,
						aspect_h = 16,
						length = 0.8,
					},
				},
			},
			alpha = 224,
			paramtype = "light",
			paramtype2 = "flowingliquid",
			walkable = false,
			pointable = false,
			diggable = false,
			buildable_to = true,
			is_ground_content = false,
			drop = "",
			drowning = 1,
			liquidtype = "flowing",
			liquid_alternative_flowing = "water_life:muddy_river_water_flowing",
			liquid_alternative_source = "water_life:muddy_river_water_source",
			liquid_viscosity = 1,
			liquid_renewable = true,
			liquid_range = 3,
			post_effect_color = {a = 232, r = 92, g = 80, b = 48},
			groups = {water = 3, liquid = 3, puts_out_fire = 1,
				not_in_creative_inventory = 1},
		})

		if minetest.get_modpath("bucket") then
			bucket.register_liquid(
				"water_life:muddy_river_water_source",
				"water_life:muddy_river_water_flowing",
				"water_life:bucket_muddy_river_water",
				"water_life_bucket_muddy_water.png",
				"Muddy Water Bucket",
				{water_bucket = 1}
			)
		end
end



-- make corals to dye 
if minetest.get_modpath("dye") then
		
		minetest.register_craft({
			type = "shapeless",
			output = "dye:green",
			recipe = {"default:coral_green"},
		})
		
		minetest.register_craft({
			type = "shapeless",
			output = "dye:cyan",
			recipe = {"default:coral_cyan"},
		})
		
		minetest.register_craft({
			type = "shapeless",
			output = "dye:pink",
			recipe = {"default:coral_pink"},
		})
		
		minetest.register_craft({
			type = "shapeless",
			output = "dye:magenta",
			recipe = {"water_life:coralmagenta"},
		})
		
		minetest.register_craft({
			type = "shapeless",
			output = "dye:blue",
			recipe = {"water_life:coralskyblue"},
		})
	end
