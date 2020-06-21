water_life = {}
water_life.version = "210620"
water_life.shark_food = {}
water_life.petz = minetest.get_modpath("petz")
water_life.mobsredo = minetest.get_modpath("mobs")
water_life.abr = tonumber(minetest.settings:get('active_block_range')) or 2
water_life.abo = tonumber(minetest.settings:get('active_object_send_range_blocks')) or 3
water_life.whale_spawn_rate =  tonumber(minetest.settings:get("water_life_whale_spawn_rate")) or 100     
water_life.shark_spawn_rate =  tonumber(minetest.settings:get("water_life_shark_spawn_rate")) or 100
water_life.urchin_spawn_rate =  tonumber(minetest.settings:get("water_life_urchin_spawn_rate")) or 700
water_life.clams_spawn_rate = tonumber(minetest.settings:get("water_life_clams_spawn_rate")) or 500
water_life.fish_spawn_rate = tonumber(minetest.settings:get("water_life_fish_spawn_rate")) or 1000
water_life.maxwhales = tonumber(minetest.settings:get("water_life_maxwhales")) or 1
water_life.maxsharks = tonumber(minetest.settings:get("water_life_maxsharks")) or 5
water_life.maxmobs = tonumber(minetest.settings:get("water_life_maxmobs")) or 60
water_life.apionly = minetest.settings:get_bool("water_life_apionly") or false
water_life.radar_debug = minetest.settings:get_bool("water_life_radar_debug") or false
water_life.muddy_water = minetest.settings:get_bool("water_life_muddy_water") or false

local path = minetest.get_modpath(minetest.get_current_modname())


dofile(path.."/api.lua")               											-- load water_life api
if water_life.muddy_water then dofile(path.."/mapgen.lua") end						-- load muddy_water
dofile(path.."/crafts.lua")				 									-- load crafts
dofile(path.."/buoy.lua")													-- load buoy
dofile(path.."/chatcommands.lua")												-- load chatcommands
dofile(path.."/behaviors.lua")												-- load behaviors

if not water_life.apionly then
	dofile(path.."/spawn.lua")												-- load spawn function
	dofile(path.."/animals/whale.lua")											-- load whales
	dofile(path.."/animals/shark.lua")											-- load sharks
	dofile(path.."/animals/riverfish.lua")										-- load riverfish
	dofile(path.."/animals/piranha.lua")										-- load piranha
	dofile(path.."/animals/sea_urchin.lua")										-- load sea urchin
	dofile(path.."/animals/clams.lua")											-- load clams
	dofile(path.."/flora/plants.lua")											-- load water plants
	dofile(path.."/flora/corals.lua")											-- load corals
	dofile(path.."/animals/jellyfish.lua")										-- load jellyfish
	dofile(path.."/animals/coralfish.lua")										-- load coralfish
	dofile(path.."/animals/clownfish.lua")										-- load clownfish
	dofile(path.."/animals/crocodile.lua")										-- load crocodile
end


--check which lasso to use
if water_life.mobsredo then 
	water_life.catchBA = "mobs:lasso"
	if water_life.petz then minetest.unregister_item("petz:lasso") end
	
elseif water_life.petz then
	water_life.catchBA = "petz:lasso"
	
else
	water_life.catchBA = "water_life:lasso"
end




math.randomseed(os.time()) --init random seed



--remove old sharks
minetest.register_entity(":sharks:shark", {
	on_activate = function(self, staticdata)
		self.object:remove()
	end,
})

minetest.register_entity(":zombiestrd:shark", {
	on_activate = function(self, staticdata)
		self.object:remove()
	end,
})



-- register shark food


if minetest.get_modpath("wildlife") then
	water_life.register_shark_food("wildlife:deer")
	water_life.register_shark_food("wildlife:deer_tamed")
	water_life.register_shark_food("wildlife:wolf")
end

if minetest.get_modpath("aerotest") then
	water_life.register_shark_food("aerotest:eagle")
end

if minetest.get_modpath("petz") then
	water_life.register_shark_food("petz:kitty")
	water_life.register_shark_food("petz:rat")
	water_life.register_shark_food("petz:goat")
	water_life.register_shark_food("petz:puppy")
	water_life.register_shark_food("petz:ducky")
	water_life.register_shark_food("petz:lamb")
	water_life.register_shark_food("petz:camel")
	water_life.register_shark_food("petz:calf")
	water_life.register_shark_food("petz:chicken")
	water_life.register_shark_food("petz:piggy")
	water_life.register_shark_food("petz:hamster")
	water_life.register_shark_food("petz:chimp")
	water_life.register_shark_food("petz:beaver")
	water_life.register_shark_food("petz:turtle")
	water_life.register_shark_food("petz:penguin")
	water_life.register_shark_food("petz:lion")
	water_life.register_shark_food("petz:grizzly")
	water_life.register_shark_food("petz:pony")
	water_life.register_shark_food("petz:wolf")
	water_life.register_shark_food("petz:elephant")
	water_life.register_shark_food("petz:elephant_female")
	water_life.register_shark_food("petz:foxy")
	water_life.register_shark_food("petz:polar_bear")
	water_life.register_shark_food("petz:tarantula")
end
