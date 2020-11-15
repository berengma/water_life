local random = water_life.random
local abs = math.abs
local pi = math.pi
local floor = math.floor
local sqrt = math.sqrt
local max = math.max
local min = math.min
local pow = math.pow
local sign = math.sign
local rad = math.rad



minetest.register_on_player_hpchange(function(player, hp_change, reason)

	if not player then return hp_change end
	if hp_change > 0 then return hp_change end
	local meta = player:get_meta()
	local repel = meta:get_int("repellant")
	local name = player:get_player_name()
	
	
	if reason then
		--minetest.chat_send_all(dump(repel).."/"..dump(math.floor(os.clock()) - repel).." : "..dump(water_life.repeltime))
		if reason.type == "node_damage" and reason.node == "water_life:moskito" and repel == 0 then
                                    
			minetest.sound_play("water_life_moskito", {
							to_player = player:get_player_name(),
							gain = 1.0,
							})
			return hp_change
		
		elseif reason.type == "node_damage" and reason.node == "water_life:moskito" and repel ~= 0 then
			--minetest.chat_send_player(name,"repellant working for another "..dump(math.floor(os.clock())-meta:get_int("repellant")).." seconds")
			return 0
		else
			return hp_change
		end
		
	end
end, true)



minetest.register_node("water_life:moskito", {
	description = ("Moskito"),
	drawtype = "plantlike",
	tiles = {{
		name = "water_life_moskito_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1.5
		},
	}},
	inventory_image = "water_life_moskito.png",
	wield_image =  "water_life_moskito.png",
	waving = 1,
	paramtype = "light",
	sunlight_propagates = true,
	buildable_to = true,
	walkable = false,
	groups = {catchable = 1},
	damage_per_second = 1,
	selection_box = {
		type = "fixed",
		fixed = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	},
	floodable = true,
	on_place = function(itemstack, placer, pointed_thing)
		local player_name = placer:get_player_name()
		local pos = pointed_thing.above

		if not minetest.is_protected(pos, player_name) and
				not minetest.is_protected(pointed_thing.under, player_name) and
				minetest.get_node(pos).name == "air" then
					minetest.set_node(pos, {name = "water_life:moskito"})
					minetest.get_node_timer(pos):start(1)
					local pmeta = minetest.get_meta(pos)
					pmeta:set_int("mlife",math.floor(os.clock()))
					itemstack:take_item()
		end
		return itemstack
	end,
	on_timer = function(pos, elapsed)
		local ptime = water_life.get_game_time()
		local level = minetest.get_node_light(pos)
		local mmeta = minetest.get_meta(pos)
		local killer = math.floor(os.clock()) - mmeta:get_int("mlife")
		--minetest.chat_send_all("liftime : "..dump(killer).." seconds")
                                             
		if  (ptime and ptime < 3 and level and level > 7) or killer > water_life.moskitolifetime then
			minetest.set_node(pos, {name = "air"})
		else
			local bdata = water_life_get_biome_data(pos)
			local nodes = minetest.find_nodes_in_area({x=pos.x-4, y=pos.y-2, z=pos.z-4}, {x=pos.x+4, y=pos.y+1, z=pos.z+4}, {"air"})
                if nodes and #nodes > 0 then                             
				local spos = nodes[random(#nodes)]
				local rnd = random (200)
				--minetest.chat_send_all(dump(bdata.temp).." : "..dump(bdata.humid).." : "..dump(rnd).." : "..dump(spos))
										
				if bdata.temp > 16 and spos then
						if rnd < bdata.humid then
							minetest.set_node(spos, {name = "water_life:moskito"})
							minetest.get_node_timer(spos):start(random(15,45))
							local pmeta = minetest.get_meta(spos)
							pmeta:set_int("mlife",math.floor(os.clock()))
						end
				end
			end
			minetest.get_node_timer(pos):start(random(15,45))
		end
		
	end
})
