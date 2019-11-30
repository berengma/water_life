local timer = 0
local pi = math.pi


local function spawnstep(dtime)

    timer = timer + dtime
    if timer > 5 then
        
        for _,plyr in ipairs(minetest.get_connected_players()) do
            
            local coin = math.random(1000)
            --minetest.chat_send_all(dump(coin))
            if plyr  then	-- each player gets a spawn chance every 5s on average
        
                local pos = plyr:get_pos()
                local yaw = plyr:get_look_horizontal()
                
                local animal = water_life.count_objects(pos)
            
                --minetest.chat_send_all("yaw = "..dump(yaw).."   mobs: "..dump(all_objects).."  sharks: "..dump(ms).."  whales: "..dump(mw))
                if animal.all > water_life.maxmobs then break end
                
                -- find a pos randomly in look direction of player
                local radius = (water_life.abo * 12) - 1                                           -- 75% from 16 = 12 nodes
                radius = math.random(7,radius)
                local angel = math.random() * (pi/4)                                    -- look for random angel 0 - 45 degrees
                if water_life.leftorright() then yaw = yaw + angel else yaw = yaw - angel end       -- add or substract to/from yaw
                
                local pos2 = mobkit.pos_translate2d(pos,yaw,radius)
                
                
                local height, liquidflag = mobkit.get_terrain_height(pos2,32)
                --minetest.chat_send_all(dump(height).."  "..dump(liquidflag))
        
                if height and liquidflag then
                    

                    
                        
                        local mobname = 'water_life:shark'
                        if water_life.shark_spawn_rate >= coin then
                            pos2.y = height+1.01
                            
                            local a=pos2.x
                            local b=pos2.y
                            local c=pos2.z
                            
                            local water = minetest.find_nodes_in_area({x=a-3, y=b-3, z=c-3}, {x=a+4, y=b+4, z=c+4}, {"default:water_source"})
                            
                            if #water < 128 then break end    -- sharks need water, much water
                        
                            if animal.sharks > (water_life.maxsharks-1) then break end  -- sharks are no sardines

                            local obj=minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
                            
                        end
                    
                        local mobname = 'water_life:fish'
                        if water_life.fish_spawn_rate >= coin then
                            pos2.y = height+1.01
                            
                            local a=pos2.x
                            local b=pos2.y
                            local c=pos2.z
                            
                            local nearlife = water_life.count_objects(pos2,16)
                            local water = minetest.find_nodes_in_area({x=a-2, y=b-2, z=c-2}, {x=a+2, y=b+2, z=c+2}, {"default:river_water_source"})
                            
                            if water and #water < 10 then break end    -- little fish need little water
                            --minetest.chat_send_all("water ="..dump(#water).."   mobs="..dump(all_objects))
                        
                            if animal.all > (water_life.maxmobs-5) or nearlife.fish > 5 then break end  

                            local obj=minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
                                
                            
                        end
                        
                        if water_life.whale_spawn_rate >= coin  then
                            pos2.y = height+4.01
                            
                            mobname = 'water_life:whale'
                            local a=pos2.x
                            local b=pos2.y
                            local c=pos2.z
                            
                            local water = minetest.find_nodes_in_area({x=a-5, y=b-5, z=c-5}, {x=a+5, y=b+5, z=c+5}, {"default:water_source"})
                            
                            if #water < 900 then break end    -- whales need water, much water
                            
                            if animal.whales > (water_life.maxwhales-1) then break end -- whales are no sardines
                            

                            local obj=minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
                        end
                    
                end
            end
        end
        timer = 0
end
end



minetest.register_globalstep(spawnstep)

