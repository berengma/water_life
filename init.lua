water_life = {}
water_life.shark_food = {}
water_life.abr = minetest.get_mapgen_setting('active_block_range') or 2
water_life.abo = minetest.get_mapgen_setting('active_object_send_range_blocks') or 3
water_life.whale_spawn_rate =  minetest.settings:get("water_life_whale_spawn_rate") or 100     
water_life.shark_spawn_rate =  minetest.settings:get("water_life_shark_spawn_rate") or 100
water_life.fish_spawn_rate = minetest.settings:get("water_life_fish_spawn_rate") or 1000
water_life.maxwhales = minetest.settings:get("water_life_maxwhales") or 1
water_life.maxsharks = minetest.settings:get("water_life_maxsharks") or 5
water_life.maxmobs = minetest.settings:get("water_life_maxmobs") or 30
water_life.apionly = minetest.settings:get("water_life_apionly") or false
water_life.radar_debug = minetest.settings:get("water_life_radar_debug") or false


math.randomseed(os.time()) --init random seed


local path = minetest.get_modpath(minetest.get_current_modname())

dofile(path.."/api.lua")                -- load water_life api
if not water_life.apionly then
    dofile(path.."/crafts.lua")             -- load crafts
    dofile(path.."/spawn.lua")              -- load spawn function
    dofile(path.."/whale.lua")              -- load whales
    dofile(path.."/shark.lua")              -- load sharks
    dofile(path.."/riverfish.lua")          -- load riverfish
end



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
water_life.register_shark_food("water_life:fish")   --fish is too small for sharks
water_life.register_shark_food("water_life:fish_tamed")
if minetest.get_modpath("wildlife") then
    water_life.register_shark_food("wildlife:deer")
    water_life.register_shark_food("wildlife:wolf")
end
if minetest.get_modpath("aerotest") then
    water_life.register_shark_food("aerotest:eagle")
end
