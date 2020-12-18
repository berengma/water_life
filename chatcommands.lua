 --chatcommands

minetest.register_chatcommand("wl_bdata", {
	params = "",
	description = "biome id,name,heat and humidity",
	privs = {server = true},
	func = function(name, action)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		local pos = player:get_pos()
		local table = minetest.get_biome_data(pos)
          
		minetest.chat_send_player(name,dump(minetest.registered_biomes[minetest.get_biome_name(table.biome)]))
                                           
		minetest.chat_send_player(name,"ID :"..dump(table.biome).."  /Name :"..dump(minetest.get_biome_name(table.biome)).."  /Temp. in C :"..dump(math.floor((table.heat-32)*5/9)).."  /Humidity in % :"..dump(math.floor(table.humidity*100)/100))
		
	end
})

minetest.register_chatcommand("wl_version", {
	params = "",
	description = "shows water_life version number",
	privs = {server = true},
	func = function(name, action)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		
		minetest.chat_send_player(name,core.colorize("#14ee00","Your water_life version # is: "..water_life.version))
        
	end
})

minetest.register_chatcommand("wl_objects", {
	params = "",
	description = "find #objects in abo",
	privs = {server = true},
	func = function(name, action)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		local pos = player:get_pos()
		
		local showit = water_life.count_objects(pos)
		minetest.chat_send_player(name,dump(showit))
          
		
	end
})


minetest.register_chatcommand("wl_kill", {
	params = "<mob_name>",
	description = "kill all mobs <mob_name> in abo",
	privs = {server = true},
	func = function(name, mob_name)
		
		if not name or not mob_name then return end
		
		local plyr = minetest.get_player_by_name(name)
		local pos = plyr:get_pos()
		local radius = water_life.abo * 16
		local all_objects = minetest.get_objects_inside_radius(pos, radius)
		local _,obj
                                         
		for _,obj in ipairs(all_objects) do
			local entity = obj:get_luaentity()
                                         
			if entity and entity.name == mob_name then
				obj:remove()
			end
		
		end

	end
})

minetest.register_chatcommand("wl_test", {
	params = "<mob_name>",
	description = "test",
	privs = {server = true},
	func = function(name, mob_name)
		
		local mob_name = "__builtin:item" 
		
		local plyr = minetest.get_player_by_name(name)
		local pos = plyr:get_pos()
		local radius = water_life.abo * 16
		local all_objects = minetest.get_objects_inside_radius(pos, radius)
		local _,obj
                                         
		for _,obj in ipairs(all_objects) do
			local entity = obj:get_luaentity()
                                         
			if entity and entity.name == mob_name then
				minetest.chat_send_player(name,dump(entity))
			end
		
		end

	end
})
