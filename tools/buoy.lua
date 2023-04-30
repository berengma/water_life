
minetest.register_node("water_life:shark_buoy", {
	description = "Shark-buoy, keeps off sharks in radius of 10 nodes",
	drawtype = "plantlike_rooted",
	waving = 1,
	tiles = {"water_life_shark_net_top.png","default_tin_block.png","default_tin_block.png",
		"default_tin_block.png","default_tin_block.png","default_tin_block.png"},
	special_tiles = {{name = "water_life_sharknet.png", tileable_vertical = true}},
	inventory_image = "water_life_shark_buoy_item.png",
	paramtype = "light",
	paramtype2 = "leveled",
	is_ground_content = false,
	groups = {cracky = 1, level = 2},
	walkable = true,
	selection_box = {
		type = "fixed",
		fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
				{-0.1,  0.5, -0.1, 0.1, 2.0, 0.1}
		}
	},          
	node_dig_prediction = "default:water",
	node_placement_prediction = "water_life:shark_buoy",
	sounds = default.node_sound_metal_defaults(),
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		local id = minetest.sha1(water_life.random());
		local buoy = nil;
		-- max must be specified and >12 or buoys will always be set
		local depth,sytpe,surface = water_life.water_depth(pos,20)
		if not surface then
			return itemstack
		end
		local height = depth-1 
		pos = surface
		pos.y = pos.y - height
		local pos_top = surface
		local node_top = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z})
		local def_top = minetest.registered_nodes[node_top.name]
		local player_name = placer:get_player_name()
		if def_top and def_top.liquidtype == "source" and height > 1 and height < 11 
			and minetest.get_item_group(node_top.name, "water") > 0 then
				if not minetest.is_protected(pos, player_name) and not
						minetest.is_protected(pos_top, player_name) then
							minetest.set_node(pos, {name = "water_life:shark_buoy",
								param2 = height * 16 })
							buoy = minetest.add_entity({x=pos.x, y=pos.y+height, z=pos.z},
								"water_life:buoy")
							local meta = minetest.get_meta(pos)
							meta:set_string("WL_ID", id)
							if buoy then
								mobkit.remember(buoy:get_luaentity(), "buoy", id);
							end							
							if not (creative and creative.is_enabled_for and
								creative.is_enabled_for(player_name)) then
									itemstack:take_item()
							end
				else
					minetest.chat_send_player(player_name, "Node is protected")
					minetest.record_protection_violation(pos, player_name)
				end
		end
		return itemstack
	end,
	on_destruct = function(pos)
		local meta=minetest.get_meta(pos)
		local nodeId = nil
		local height = nil
		if  not meta then
			return
		end
		nodeId = meta:get_string("WL_ID")
		height = meta:get_int("buoy")
		if height then -- compatibility for old buoys, will be removed in the future
			local cpos = {x=pos.x, y= pos.y + height, z=pos.z}
			local object = minetest.get_objects_inside_radius(cpos, 1)
			for _,obj in ipairs(object) do
				local entity = obj:get_luaentity()
				if entity and entity.name == "water_life:buoy" then
					obj:remove()
					return
				end
			end
		end
		if not nodeId then
			return
		end
		local object = minetest.get_objects_inside_radius(pos, water_life.abo * 16)
		for _,obj in ipairs(object) do
			local entity = obj:get_luaentity()
			if not obj:is_player() and entity and 
				entity.name == "water_life:buoy" then
				local buoyId = mobkit.recall(entity, "buoy")
				if buoyId and buoyId == nodeId then
					obj:remove()
					return
				end
			end
		end
	end,
})

minetest.register_entity("water_life:buoy",{
	physical = true,
	stepheight = 0.5,				
	collide_with_objects = true,
	collisionbox = {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
	visual = "mesh",
	mesh = "water_life_buoy.b3d",
	textures = {"water_life_buoy.png"},
	visual_size = {x = 5, y = 5},
	static_save = true,
	makes_footstep_sound = false,
	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	springiness=0,
	buoyancy = 0.93,
	max_hp = 65535,
	timeout = 0,
	brainfunc = function(self) return end,
    on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		local bpos = self.object:get_pos()
		if puncher:is_player() then
			minetest.log("warning", puncher:get_player_name().." punched a buoy!  -  "..
			minetest.pos_to_string(bpos, 1))
		end
		minetest.after(5, function(self, bpos)
			self.object:set_pos(bpos)
		end, self, bpos)
		return
	end,
    on_rightclick = function(self, clicker)
		return
    end,
                                            
})

minetest.register_craft({
	output = "water_life:shark_buoy",
	recipe = {
		{"default:tin_ingot", "dye:orange", "default:tin_ingot"},
		{"default:tin_ingot", "default:diamond", "default:tin_ingot"},
		{"default:tin_ingot", "default:tin_ingot", "default:tin_ingot"}
	}
})
