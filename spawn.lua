local timer = 0
local landtimer = 0
local dttot=0
local dtavg=0
local dtnum=0
local dtmax=0
local dttimer = 10
local pi = math.pi
local random = water_life.random
local landinterval = 120
local waterinterval = 30

local function getcount(name)
	if not name then
		return 0 
	else
		return name
	end
end

local function spawnstep(dtime)
	-- dtime measurement by Termos
	if dtnum < 10001 then
		dttot=dttot+dtime
		dtnum=dtnum+1
		dtmax = dtime>dtmax and dtime or dtmax
		
		if dttot>dttimer then
			dttimer=dttimer+10
			water_life.avg_dtime = dttot/dtnum
			water_life.max_dtime = dtmax
			dtmax=0
		end
	else -- reset after 10000 steps
		dtnum = 0
		dtavg = 0
		dttot = 0
		dtmax = 0
		dttimer = 10
	end
	-- end dtime measurement

	timer = timer + dtime
	landtimer = landtimer + dtime
	if timer > waterinterval then
		for _,plyr in ipairs(minetest.get_connected_players()) do
			local toomuch = false
			if plyr and plyr:is_player() then
				local meta = plyr:get_meta()
				if meta:get_int("snakepoison") > 0 then
					local score = plyr:get_hp()
					plyr:set_hp(score - 1)
				end
				if meta:get_int("repellant") > 0 then
					if math.floor(os.time()) - meta:get_int("repellant") 
						> water_life.repeltime then
						water_life.change_hud(plyr,"repellant",0)
						meta:set_int("repellant",0)
					end
				end
			end
			-- spawn only between -50 < y < 150
			if plyr and plyr:is_player() and plyr:get_pos().y > -50 
				and plyr:get_pos().y < 150 and not water_life.apionly then
				local pos = plyr:get_pos()
				local yaw = plyr:get_look_horizontal()
				local animal = water_life.count_objects(pos)
				local meta = plyr:get_meta()
				if animal.all > water_life.maxmobs then toomuch = true end
				local radius = (water_life.abo * 12)
				radius = random(7,radius)
				local angel = math.rad(random(75))
				if water_life.leftorright() then 
					yaw = yaw + angel 
				else 
					yaw = yaw - angel 
				end
				local pos2 = mobkit.pos_translate2d(pos,yaw,radius)
				local depth, stype, surface = water_life.water_depth(pos2,25)
				local bdata =  water_life_get_biome_data(pos2)
				local ground = {}
				local dalam = depth
				local landpos = nil
				local geckopos = nil
				local moskitopos = nil
				local mobname = ""
				
				-- no need of so many postions on land
				if landtimer > landinterval then
					landpos = water_life.find_node_under_air(pos2)
					geckopos = water_life.find_node_under_air(pos2,5,
						{"group:tree","group:leaves","default:junglegrass"})
					if not water_life.ihateinsects then
						moskitopos = water_life.find_node_under_air(pos2,5,
							{"group:water","group:flora","group:crumbly"})
					end
				end
				
				-- mosqitos only bettween -10 < y < 100
				if moskitopos and not water_life.dangerous 
					and moskitopos.y > -10 and moskitopos.y < 100 then
					local mlevel = minetest.get_node_light(moskitopos)
					local ptime = water_life.get_game_time()
					local mdata = water_life_get_biome_data(moskitopos)
					if ((ptime and ptime > 2) or mlevel < 8) 
						and mdata.temp > 20 then			
						minetest.set_node(moskitopos, 
							{name = "water_life:moskito"})
						minetest.get_node_timer(moskitopos):start(
							random(15,45))
						local pmeta = minetest.get_meta(moskitopos)
						pmeta:set_int("mlife",math.floor(os.time()))
					end
				end
				
				if landpos then
					local landdata =  water_life_get_biome_data(landpos)
					if not water_life.dangerous then
						mobname = 'water_life:snake'
						local faktor = (100 - getcount(animal[mobname]) * 50) 
						if random(100) < faktor then
							local fits = minetest.is_protected(
								landpos,mobname)
							if (string.match(landdata.name,"desert") or 
								string.match(landdata.name,"savanna"))
								and not fits and 
								landdata.temp > 15 then
								local obj=minetest.add_entity(
									landpos,mobname)
							end
						end
					end
					
					mobname = 'water_life:beaver'
					local faktor = (100 - getcount(animal[mobname]) * 25) 
					if random(100) < faktor then
						if string.match(landdata.name,"coniferous") 
							and landdata.temp > -5 and landdata.temp < 20 then
							local obj=minetest.add_entity(landpos,mobname)
						end
					end
				end
				
				if geckopos then
					local landdata =  water_life_get_biome_data(geckopos)
					mobname = 'water_life:gecko'
					local faktor = (100 - getcount(animal[mobname]) * 50)
					if random(100) < faktor then
						if (string.match(landdata.name,"rainforest") 
							or string.match(landdata.name,"savanna"))
							and landdata.temp > 20 then
							local obj=minetest.add_entity(geckopos,mobname)
						end
					end
				end
				
				--water spawn
					
				if depth and depth > 0 then									
					if water_life.radar_debug then
						water_life.temp_show(surface,9,5)
						minetest.chat_send_all(">>> Depth ="..dump(depth)..
							" <<<   "..dump(stype))
						minetest.chat_send_all(dump(bdata.name))
					end
					pos2 = surface
				end
				
				local liquidflag = nil
				if stype == "default:water_source" or stype == "islands:water_source" then 
					liquidflag = "sea"
				elseif stype == "default:river_water_source" then
					liquidflag = "river"
				elseif stype == "water_life:muddy_river_water_source" then
					liquidflag = "muddy"
				elseif water_life.swampz and stype == "swaz:water_source" then
					liquidflag = "swamp"
				end
		
				if liquidflag and not toomuch and surface then
					ground = mobkit.pos_shift(surface,{y=(dalam*-1)})
					local pool = water_life.check_for_pool(nil,4,8,surface)
					if water_life.radar_debug then
						minetest.chat_send_all(">> A pool: "..dump(pool).." <<")
					end
					if not water_life.dangerous then
						if water_life.swampz then
							mobname = 'water_life:alligator'
							local faktor = 100 - getcount(animal[mobname]) * 20
							if random(100) < faktor then
								local fits = false
								if string.match(bdata.name,"swampz") and 
									liquidflag == "swamp" then fits = true end
								if depth < 4 and fits then
									local obj=minetest.add_entity(surface,mobname)
								end
							end
						end
						
						mobname = 'water_life:croc'
						local faktor = 100 - getcount(animal[mobname]) * 33
						if random(100) < faktor then
							local fits = false
							if string.match(bdata.name,"rainforest") or 
								string.match(bdata.name,"savanna") then 
								fits = true 
							end
							if depth < 4 and fits and pool == false then
								local obj=minetest.add_entity(surface,mobname)
							end
						end
						
						mobname = 'water_life:snake'
						local faktor = (100 - getcount(animal[mobname]) * 50) +25
						if random(100) < faktor then
							local fits = false
							if string.match(bdata.name,"desert") or 
								string.match(bdata.name,"savanna") then 
								fits = true 
							end
							if depth < 3 and fits then
								local obj=minetest.add_entity(surface,mobname)
							end
						end
							
						mobname = 'water_life:shark'
						if water_life.shark_spawn_rate >= random(1000) then
							local bcheck = water_life.count_objects(pos2,12)
							if getcount(animal[mobname]) < water_life.maxsharks and 
								liquidflag == "sea" and 
								not bcheck["water_life:shark_buoy"] and
								not animal["water_life:croc"] then
									if depth > 4 and pool == false then
										local obj=minetest.add_entity(
											mobkit.pos_shift(ground,{y=2}),mobname)
									end
							end
						end
					end
					
					mobname = "water_life:gull"
					local faktor = 100 - getcount(animal[mobname]) * 20
					if random(100) < faktor and (liquidflag == "sea" or liquidflag == "river") then
						if depth > 2 and not water_life.check_for_pool(nil,2,10,surface)then
							local obj=minetest.add_entity(surface,mobname)
						end
					end
					
					mobname = "water_life:urchin"
					if water_life.urchin_spawn_rate >= random(1000) then
						local upos1 = mobkit.pos_shift(ground,{x=-5,y=-2,z=-5})
						local upos2 = mobkit.pos_shift(ground,{x=5,y=2,z=5})
						local coraltable = minetest.find_nodes_in_area(upos1,
							upos2, water_life.urchinspawn)
						if coraltable and #coraltable > 0 and 
							getcount(animal[mobname]) < 15 and 
							liquidflag == "sea" then
							local coralpos = coraltable[random(#coraltable)]
							coralpos.y = coralpos.y +1
							local node = minetest.get_node(coralpos)
							if node.name == "default:water_source" then
								local obj= water_life.set_urchin(coralpos)
							end
						end
					end
					
					mobname = "water_life:clams"
					if water_life.clams_spawn_rate >= random(1000) then
						local clpos1 = mobkit.pos_shift(ground,{x=-8, y=-2, z=8})
						local clpos2 = mobkit.pos_shift(ground,{x=8, y=2, z=8})
						local coraltable = minetest.find_nodes_in_area(clpos1, 
							clpos2, water_life.clams_spawn)
						local nearlife = water_life.count_objects(
							ground,8,"water_life:clams")
						if coraltable and #coraltable > 0 and 
							getcount(animal[mobname]) < 10 and 
							liquidflag == "sea" then
							local coralpos = mobkit.pos_shift(
								coraltable[random(#coraltable)],{y=1})
							local node = minetest.get_node(coralpos)
							if node.name == "default:water_source" then
								local obj= water_life.set_urchin(
								coralpos,"water_life:clams")
							end
						end
					end
					
					mobname = "water_life:jellyfish"
					local faktor = 100 - getcount(animal[mobname]) * 20
					if random(100) < faktor and liquidflag == "sea" and 
						depth > 2 then
						local obj=minetest.add_entity(
						mobkit.pos_shift(ground,{y=2}),mobname)
					end
					
					mobname = "water_life:coralfish"
					local cfpos1 = mobkit.pos_shift(ground,{x=-5,y=-2,z=-5})
					local cfpos2 = mobkit.pos_shift(ground,{x=5,y=2,z=5})
					local coraltable = minetest.find_nodes_in_area(
						cfpos1,cfpos2,water_life.urchinspawn)
					faktor = 100 - getcount(animal[mobname]) * 6.66
					if random(100) < faktor and liquidflag == "sea" and 
						#coraltable > 1 then
						local cfish = coraltable[random(#coraltable)]
						cfish.y = cfish.y +1
						local maxfish = random(3,7)
						for i = 1,maxfish,1 do
							local obj=minetest.add_entity(cfish,mobname)
							if obj then
								local entity = obj:get_luaentity()
								entity.base = cfish
								entity.head = random(65535)
							end
						end
					end
					
					mobname = "water_life:clownfish"
					faktor = 100 - getcount(animal[mobname]) * 50
					if random(100) < faktor and liquidflag == "sea" and 
						#coraltable > 1 then
						local cfish = coraltable[random(#coraltable)]
						cfish.y = cfish.y +1
						local obj=minetest.add_entity(cfish,mobname)
						if obj then
							local entity = obj:get_luaentity()
							entity.base = cfish
						end
					end
					
					mobname = 'water_life:fish'
					if water_life.fish_spawn_rate >= random(1000) and 
						((animal.all < (water_life.maxmobs-5)) or 
						getcount(animal[mobname]) < 5) and (((liquidflag == 
						"river" or liquidflag == "muddy")) or 
						(water_life.spawn_on_islands and not 
						water_life.check_for_pool(nil,2,3,pos2) and
						water_life.check_for_pool(nil,2,16,pos2))) then
						local table = minetest.get_biome_data(pos)
						if not water_life.dangerous and 
							((table and water_life.piranha_biomes[
							minetest.get_biome_name(table.biome)])
							or water_life.spawn_on_islands) then
								mobname = "water_life:piranha"
						end
						if depth > 2 then
							if mobname == "water_life:fish" then
								local obj=minetest.add_entity(pos2,mobname)
							else
								if getcount(animal[mobname]) < 10 then
									for i = 1,3,1 do
										local obj=minetest.add_entity(pos2,mobname)
									end
								end
							end
						end
					end
						
					mobname = 'water_life:whale'
					if water_life.whale_spawn_rate >= random(1000) and 
						getcount(animal[mobname]) < (
						water_life.maxwhales) and 
						liquidflag == "sea" then
						if depth > 8 then
							local gotwhale = true
							local whpos = mobkit.pos_shift(surface,{y=-3})
							for i = 0,3,1 do
								local whpos2 = mobkit.pos_translate2d(whpos,math.rad(i*90),30)
								local under = water_life.find_collision(whpos,whpos2, false)
								if under and under < 25 then
									gotwhale = false
									break
								end
							end
							if gotwhale then 
								local obj=minetest.add_entity(surface,mobname) 
							end
						end
					end
				end
			end
		end
		timer = 0
		if landtimer > landinterval then 
			landtimer = 0 
		end
	end
end

minetest.register_globalstep(spawnstep)
