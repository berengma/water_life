water_life = {}
water_life.version = "140220"
water_life.shark_food = {}
water_life.abr = minetest.get_mapgen_setting('active_block_range') or 2
water_life.abo = minetest.get_mapgen_setting('active_object_send_range_blocks') or 3
water_life.whale_spawn_rate =  minetest.settings:get("water_life_whale_spawn_rate") or 100     
water_life.shark_spawn_rate =  minetest.settings:get("water_life_shark_spawn_rate") or 100
water_life.urchin_spawn_rate =  minetest.settings:get("water_life_urchin_spawn_rate") or 700
water_life.fish_spawn_rate = minetest.settings:get("water_life_fish_spawn_rate") or 1000
water_life.maxwhales = minetest.settings:get("water_life_maxwhales") or 1
water_life.maxsharks = minetest.settings:get("water_life_maxsharks") or 5
water_life.maxmobs = minetest.settings:get("water_life_maxmobs") or 30
water_life.apionly = minetest.settings:get("water_life_apionly") or false
water_life.radar_debug = minetest.settings:get("water_life_radar_debug") or false
water_life.muddy_water = minetest.settings:get("water_life_muddy_water") or false

local path = minetest.get_modpath(minetest.get_current_modname())

dofile(path.."/api.lua")               										-- load water_life api
if water_life.muddy_water then dofile(path.."/mapgen.lua") end				-- load muddy_water
dofile(path.."/crafts.lua")				 									-- load crafts
if not water_life.apionly then
    dofile(path.."/spawn.lua")												-- load spawn function
    dofile(path.."/whale.lua")												-- load whales
    dofile(path.."/shark.lua")												-- load sharks
    dofile(path.."/riverfish.lua")											-- load riverfish
	dofile(path.."/piranha.lua")											-- load piranha
	dofile(path.."/sea_urchin.lua")											-- load sea urchin
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
--[[
water_life.register_shark_food("water_life:fish")   --fish is too small for sharks
water_life.register_shark_food("water_life:fish_tamed")
]]

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
