water_life = {}
water_life.shark_food = {}
water_life.abr = minetest.get_mapgen_setting('active_block_range') or 2
water_life.abo = minetest.get_mapgen_setting('active_object_send_range_blocks') or 3
water_life.whale_spawn_rate =  30           -- chances in promille 30 promille = 3%
water_life.shark_spawn_rate =  100
water_life.fish_spawn_rate = 1000
water_life.maxwhales = 1 
water_life.maxsharks = water_life.abo/2
water_life.maxmobs = 30

math.randomseed(os.time()) --init random seed


local path = minetest.get_modpath(minetest.get_current_modname())

dofile(path.."/api.lua")                -- load water_life api
dofile(path.."/crafts.lua")             -- load crafts
dofile(path.."/spawn.lua")              -- load spawn function
dofile(path.."/whale.lua")              -- load whales
dofile(path.."/shark.lua")              -- load sharks
dofile(path.."/riverfish.lua")          -- load riverfish



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
if minetest.get_modpath("wildlife") then
    water_life.register_shark_food("wildlife:deer")
    water_life.register_shark_food("wildlife:wolf")
end

