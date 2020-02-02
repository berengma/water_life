local timer = 0
local pi = math.pi


local function spawnstep(dtime)

    timer = timer + dtime
    if timer > 5 then
        
        for _,plyr in ipairs(minetest.get_connected_players()) do
            
            local coin = math.random(1000)
            --minetest.chat_send_all(dump(coin))
            if plyr and plyr:is_player() then	-- each player gets a spawn chance every 5s on average
        
                local pos = plyr:get_pos()
                local yaw = plyr:get_look_horizontal()
                
                local animal = water_life.count_objects(pos)
            
                --minetest.chat_send_all("yaw = "..dump(yaw).."   mobs: "..dump(animal.all).."  sharks: "..dump(animal.sharks).."  whales: "..dump(animal.whales))
                if animal.all > water_life.maxmobs then break end
                
                -- find a pos randomly in look direction of player
                local radius = (water_life.abr * 12) - 1                                           -- 75% from 16 = 12 nodes
                radius = math.random(7,radius)
                local angel = math.random() * 1.1781                                                -- look for random angel 0 - 75 degrees
                if water_life.leftorright() then yaw = yaw + angel else yaw = yaw - angel end       -- add or substract to/from yaw
                
                local pos2 = mobkit.pos_translate2d(pos,yaw,radius)
                
                pos2.y = pos2.y - math.random(water_life.abr * 5)
                local node = minetest.get_node(pos2)
                --minetest.chat_send_all(dump(node.name))
                local liquidflag = nil
                
                if node.name == "default:water_source" then 
                    
                    liquidflag = "sea"
                    
                elseif node.name == "default:river_water_source" then
                    
                    liquidflag = "river"
                    
                end
        
                if liquidflag then
                        
                        local mobname = 'water_life:shark'
                        if water_life.shark_spawn_rate >= coin then
                            if animal.sharks < (water_life.maxsharks) and liquidflag == "sea" then
                                
                                
                                local a=pos2.x
                                local b=pos2.y
                                local c=pos2.z
                                
                                local water = minetest.find_nodes_in_area({x=a-3, y=b-3, z=c-3}, {x=a+4, y=b+4, z=c+4}, {"default:water_source"})
                                
                                if #water > 128 then     -- sharks need water, much water
                            
                                    
                                    local obj=minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
                                end
                            end
                            
                        end
                    
                        local mobname = 'water_life:fish'
                        local nearlife = water_life.count_objects(pos2,16,"water_life:piranha")
                        if water_life.fish_spawn_rate >= coin and ((animal.all < (water_life.maxmobs-5)) or nearlife.fish > 5) and liquidflag == "river" then
                            --pos2.y = height+1.01
                            
                            local a=pos2.x
                            local b=pos2.y
                            local c=pos2.z
                            local table = minetest.get_biome_data(pos)
							if table and minetest.get_biome_name(table.biome) == "rainforest" then mobname = "water_life:piranha" end
                            
                            local water = minetest.find_nodes_in_area({x=a-2, y=b-2, z=c-2}, {x=a+2, y=b+2, z=c+2}, {"default:river_water_source"})
                            
                            if water and #water > 10 then -- little fish need little water
								if mobname == "water_life:fish" then
									local obj=minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
								else
									if nearlife.name < 10 then
										for i = 1,3,1 do
												local obj=minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
										end
									end
								end
                            end
                                
                            
                        end
                        
                        if water_life.whale_spawn_rate >= coin and animal.whales < (water_life.maxwhales) and liquidflag == "sea" then
                            pos2.y = pos2.y -4
                            
                            mobname = 'water_life:whale'
                            local a=pos2.x
                            local b=pos2.y
                            local c=pos2.z
                            
                            local water = minetest.find_nodes_in_area({x=a-5, y=b-5, z=c-5}, {x=a+5, y=b+5, z=c+5}, {"default:water_source"})
                            --minetest.chat_send_all(dump(#water))
                            if #water > 900 then    -- whales need water, much water
                                local obj=minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
                            end
                        end
                    
                end
            end
        end
        timer = 0
end
end



minetest.register_globalstep(spawnstep)

