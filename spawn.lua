local timer = 0
local pi = math.pi
local random = water_life.random



local function spawnstep(dtime)

	timer = timer + dtime
	if timer > 10 then
        
	for _,plyr in ipairs(minetest.get_connected_players()) do
            
		local toomuch = false
            
		if plyr and plyr:is_player() and plyr:get_pos().y > -50 and plyr:get_pos().y < 150 then	-- each player gets a spawn chance every 5s on average
        
			local pos = plyr:get_pos()
			local yaw = plyr:get_look_horizontal()
			local animal = water_life.count_objects(pos)
            
			if animal.all > water_life.maxmobs then toomuch = true end
                
																						-- find a pos randomly in look direction of player
			local radius = (water_life.abr * 12)												-- 75% from 16 = 12 nodes
			radius = random(7,radius)														-- not nearer than 7 nodes in front of player
			local angel = math.rad(random(75))                                       					-- look for random angel 0 - 75 degrees
			if water_life.leftorright() then yaw = yaw + angel else yaw = yaw - angel end   			-- add or substract to/from yaw
                
			local pos2 = mobkit.pos_translate2d(pos,yaw,radius)									-- calculate position
			local depth = water_life.water_depth(pos2,25)										-- get surface pos and water depth
				
			if depth.depth > 0 then									
				if water_life.radar_debug then
					water_life.temp_show(depth.surface,1,5)
					minetest.chat_send_all(">>> Depth ="..dump(depth.depth).." <<<   "..dump(depth.type))
				end
				pos2 = depth.surface												
			end
                
			local liquidflag = nil
                
			if depth.type == "default:water_source" then 
				liquidflag = "sea"
                    
			elseif depth.type == "default:river_water_source" then
				liquidflag = "river"
					
			elseif depth.type == "water_life:muddy_river_water_source" then
				liquidflag = "muddy"
                    
			end
        
			if liquidflag and not toomuch then
                        
				local mobname = 'water_life:shark'
				if water_life.shark_spawn_rate >= random(1000) then
						
					local bcheck = water_life.count_objects(pos2,12,"water_life:shark_buoy")
					if animal.sharks < (water_life.maxsharks) and liquidflag == "sea" and bcheck.name == 0 then
                                
						if depth.depth > 4 then      --shark min water depth
						local obj=minetest.add_entity({x=pos2.x,y=pos2.y-depth.depth+1,z=pos2.z},mobname)			-- ok spawn it already damnit
						end
					end
                            
				end
                    
				mobname = "water_life:urchin"
				if water_life.urchin_spawn_rate >= random(1000) then
					local ground = depth.surface
						ground.y = ground.y - depth.depth
						local coraltable = minetest.find_nodes_in_area({x=ground.x-5, y=ground.y-2, z=ground.z-5}, {x=ground.x+5, y=ground.y+2, z=ground.z+5}, water_life.urchinspawn)
						local nearlife = water_life.count_objects(ground,5,"water_life:urchin")
						if coraltable and #coraltable > 0 and nearlife.name < 5 and liquidflag == "sea" then
							local coralpos = coraltable[random(#coraltable)]
							coralpos.y = coralpos.y +1
							local node = minetest.get_node(coralpos)
								
							if node.name == "default:water_source" then
								local obj= water_life.set_urchin(coralpos)  --minetest.add_entity(coralpos,mobname)
							end
						end
				end
				
				mobname = "water_life:clams"
				if water_life.clams_spawn_rate >= random(1000) then
					local ground = depth.surface
						ground.y = ground.y - depth.depth
						local coraltable = minetest.find_nodes_in_area({x=ground.x-8, y=ground.y-2, z=ground.z-8}, {x=ground.x+8, y=ground.y+2, z=ground.z+8}, water_life.clams_spawn)
						local nearlife = water_life.count_objects(ground,8,"water_life:clams")
						if coraltable and #coraltable > 0 and nearlife.name < 5 and liquidflag == "sea" then
							local coralpos = coraltable[random(#coraltable)]
							coralpos.y = coralpos.y +1
							local node = minetest.get_node(coralpos)
								
							if node.name == "default:water_source" then
								local obj= water_life.set_urchin(coralpos,"water_life:clams")  --minetest.add_entity(coralpos,mobname)
							end
						end
				end
				
				mobname = "water_life:jellyfish"
				
				local ground = depth.surface
				local nearlife = water_life.count_objects(ground,nil,"water_life:jellyfish")
				local faktor = 100 - nearlife.name * 10
				if random(100) < faktor and liquidflag == "sea" then
					local obj=minetest.add_entity(ground,mobname)
				end
				
				
					mobname = 'water_life:fish'
					local nearlife = water_life.count_objects(pos2,24,"water_life:piranha")
					if water_life.fish_spawn_rate >= random(1000) and ((animal.all < (water_life.maxmobs-5)) or nearlife.fish < 5) and (liquidflag == "river" or liquidflag == "muddy") then
                            
						local table = minetest.get_biome_data(pos)
						if table and water_life.piranha_biomes[minetest.get_biome_name(table.biome)] then mobname = "water_life:piranha" end
						
							if depth.depth > 2 then										-- min water depth for piranha and riverfish
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
                        
					if water_life.whale_spawn_rate >= random(1000) and animal.whales < (water_life.maxwhales) and liquidflag == "sea" then
						mobname = 'water_life:whale'
						
						if depth.depth > 8 then																-- min water depth for whales
									
							local gotwhale = true
							local whpos = mobkit.pos_shift(depth.surface,{y=-3})
							for i = 0,3,1 do
								local whpos2 = mobkit.pos_translate2d(whpos,math.rad(i*90),30)
								local under = water_life.find_collision(whpos,whpos2, false)
								--minetest.chat_send_all(dump(under))
								if under and under < 25 then
									gotwhale = false
									break
								end
							end
							if gotwhale then local obj=minetest.add_entity(depth.surface,mobname) end		-- ok spawn it already damnit
										
						end
					end
                    
				end
			end
		end
		timer = 0
	end
end



minetest.register_globalstep(spawnstep)

