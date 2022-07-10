-----------------------------------------------------------
--
-- Water_life copyright 2022 by Gundul
-- see software and media licenses in the doc folder
-- 
-----------------------------------------------------------

water_life = {}
water_life.version = "220710"
water_life.shark_food = {}
water_life.repellant = {}
water_life.gull_bait = {}
water_life.catchNet = "water_life:placeholder"
water_life.petz = minetest.get_modpath("petz")
water_life.mobsredo = minetest.get_modpath("mobs")
water_life.farming = minetest.get_modpath("farming")
water_life.swampz = minetest.get_modpath("swaz")
water_life.abr = tonumber(minetest.settings:get('active_block_range')) or 2
water_life.abo = tonumber(minetest.settings:get('active_object_send_range_blocks')) or 3
water_life.avg_dtime = 0
water_life.max_dtime = 0

-- settingtypes
water_life.whale_spawn_rate =  tonumber(minetest.settings:get("water_life_whale_spawn_rate")) or 100
water_life.shark_spawn_rate =  tonumber(minetest.settings:get("water_life_shark_spawn_rate")) or 100
water_life.urchin_spawn_rate =  tonumber(minetest.settings:get("water_life_urchin_spawn_rate")) or 700
water_life.clams_spawn_rate = tonumber(minetest.settings:get("water_life_clams_spawn_rate")) or 500
water_life.fish_spawn_rate = tonumber(minetest.settings:get("water_life_fish_spawn_rate")) or 1000
water_life.maxwhales = tonumber(minetest.settings:get("water_life_maxwhales")) or 1
water_life.maxsharks = tonumber(minetest.settings:get("water_life_maxsharks")) or 5
water_life.maxmobs = tonumber(minetest.settings:get("water_life_maxmobs")) or 60
water_life.apionly = minetest.settings:get_bool("water_life_apionly") or false
water_life.dangerous = minetest.settings:get_bool("water_life_dangerous") or false
water_life.soundadjust = tonumber(minetest.settings:get("water_life_soundadjust")) or 1.0

-- lifetime in sec. ( <15 = no reproducing)
water_life.moskitolifetime = tonumber(minetest.settings:get("water_life_moskitolifetime")) or 120
water_life.radar_debug = minetest.settings:get_bool("water_life_radar_debug") or false
water_life.muddy_water = minetest.settings:get_bool("water_life_muddy_water") or false

-- the repellent lasts half a minetest day
water_life.repeltime = math.floor (720 / (tonumber(minetest.settings:get("time_speed")) or 72)*60)

-- 5 days savety from rattlenakes for new players
water_life.newplayerbonus = tonumber(minetest.settings:get("water_life_newplayerbonus")) or 5
water_life.ihateinsects = minetest.settings:get_bool("water_life_hate_insects") or false

-- let there be blood !
water_life.bloody = minetest.settings:get_bool("water_life_bloody") or true

local path = minetest.get_modpath(minetest.get_current_modname())

-- load water_life api
dofile(path.."/api.lua")
dofile(path.."/compat.lua")

-- load pathfinding
dofile(path.."/paths.lua")

-- load muddy_water
if water_life.muddy_water then dofile(path.."/mapgen.lua") end

dofile(path.."/crafts.lua")
dofile(path.."/tools/buoy.lua")
dofile(path.."/chatcommands.lua")
dofile(path.."/behaviors.lua")
dofile(path.."/bio.lua")

if not water_life.apionly then
	dofile(path.."/hud.lua")
	dofile(path.."/spawn.lua")
	dofile(path.."/animals/whale.lua")
	dofile(path.."/animals/riverfish.lua")
	dofile(path.."/animals/sea_urchin.lua")
	dofile(path.."/animals/clams.lua")
	dofile(path.."/flora/plants.lua")
	dofile(path.."/flora/corals.lua")
	dofile(path.."/animals/jellyfish.lua")
	dofile(path.."/animals/coralfish.lua")
	dofile(path.."/animals/clownfish.lua")
	dofile(path.."/animals/gulls.lua")
	dofile(path.."/animals/gecko.lua")
	dofile(path.."/animals/beaver.lua")
	if not water_life.dangerous then
		dofile(path.."/animals/snake.lua")
		dofile(path.."/animals/piranha.lua")
		dofile(path.."/animals/shark.lua")
		dofile(path.."/animals/crocodile.lua")
		dofile(path.."/animals/moskito.lua")
		if water_life.swampz then
			dofile(path.."/animals/alligator.lua")
		end
	end
end


--check which lasso to use
if water_life.mobsredo then 
	water_life.catchBA = "mobs:lasso"
	water_life.catchNet = "mobs:net"
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
	water_life.register_shark_food("petz:leopard")
	water_life.register_shark_food("petz:snow_leopard")
	water_life.register_shark_food("petz:panda")
	water_life.register_shark_food("petz:santa_killer")
	water_life.register_shark_food("petz:mr_pumpkin")
	water_life.register_shark_food("petz:hen")
	water_life.register_shark_food("petz:rooster")
end

if minetest.get_modpath("better_fauna") then
	water_life.register_shark_food("better_fauna:chicken")
	water_life.register_shark_food("better_fauna:cow")
	water_life.register_shark_food("better_fauna:pig")
	water_life.register_shark_food("better_fauna:sheep")
	water_life.register_shark_food("better_fauna:turkey")
end

-- register gull bait
water_life.register_gull_bait("water_life:clownfish")
water_life.register_gull_bait("water_life:coralfish")
water_life.register_gull_bait("water_life:riverfish")
water_life.register_gull_bait("water_life:piranha")
water_life.register_gull_bait("water_life:urchin_item")
water_life.register_gull_bait("water_life:snake_item")
water_life.register_gull_bait("water_life:meat_raw")
water_life.register_gull_bait("water_life:meat")

if minetest.get_modpath("farming") then
	water_life.register_gull_bait("farming:bread")
end
