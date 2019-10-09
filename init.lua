
math.randomseed(os.time()) --init random seed



minetest.register_entity(":sharks:shark", {
        on_activate = function(self, staticdata)
            self.object:remove()
        end,
    })


local abr = minetest.get_mapgen_setting('active_block_range') or 1
local abo = minetest.get_mapgen_setting('active_object_send_range_blocks') or 2
local nodename_water = minetest.registered_aliases.mapgen_water_source
local maxwhales = 1 
local maxsharks = (2 ^ (abr -1)) + 1

local abs = math.abs
local pi = math.pi
local floor = math.floor
local random = math.random
local sqrt = math.sqrt
local max = math.max
local min = math.min
local pow = math.pow
local sign = math.sign

local time = os.time

local spawn_rate = 1 - max(min(minetest.settings:get('whale_spawn_chance') or 0.6,1),0)
local spawn_reduction = minetest.settings:get('whale_spawn_reduction') or 0.4





local function leftorright()
    local rnd = math.random()
    if rnd > 0.5 then return true else return false end
end

-- count sharks at position
local function count_sharks(pos)

local all_objects = minetest.get_objects_inside_radius(pos, abo * 16)
local sharks = 0
local _,obj
for _,obj in ipairs(all_objects) do
    local entity = obj:get_luaentity()
	if entity and entity.name == "water_life:shark" then
		sharks = sharks +1
	end
end
return sharks
end


-- count whales at position
local function count_whales(pos)

local all_objects = minetest.get_objects_inside_radius(pos, abo * 16)
local whales = 0
local _,obj
for _,obj in ipairs(all_objects) do
    local entity = obj:get_luaentity()
	if entity and entity.name == "water_life:whale" then
		whales = whales +1
	end
end
return whales
end

local function aqua_radar_dumb(pos,yaw,range,reverse)
	range = range or 4
	
	local function okpos(p)
		local node = mobkit.nodeatpos(p)
		if node then 
			if node.drawtype == 'liquid' then 
				local nodeu = mobkit.nodeatpos(mobkit.pos_shift(p,{y=1}))
				local noded = mobkit.nodeatpos(mobkit.pos_shift(p,{y=-1}))
				if (nodeu and nodeu.drawtype == 'liquid') or (noded and noded.drawtype == 'liquid') then
					return true
				else
					return false
				end
			else
				local h,l = mobkit.get_terrain_height(p)
				if h then 
					local node2 = mobkit.nodeatpos({x=p.x,y=h+1.99,z=p.z})
					if node2 and node2.drawtype == 'liquid' then return true, h end
				else
					return false
				end
			end
		else
			return false
		end
	end
	
	local fpos = mobkit.pos_translate2d(pos,yaw,range)
	local ok,h = okpos(fpos)
	if not ok then
		local ffrom, fto, fstep
		if reverse then 
			ffrom, fto, fstep = 3,1,-1
		else
			ffrom, fto, fstep = 1,3,1
		end
		for i=ffrom, fto, fstep  do
			local ok,h = okpos(mobkit.pos_translate2d(pos,yaw+i,range))
			if ok then return yaw+i,h end
			ok,h = okpos(mobkit.pos_translate2d(pos,yaw-i,range))
			if ok then return yaw-i,h end
		end
		return yaw+pi,h
	else 
		return yaw, h
	end	
end


local function big_hq_aqua_turn(self,prty,tyaw,speed)
	local func = function(self)
		local finished=mobkit.turn2yaw(self,tyaw,0.4)
		if finished then return true end
	end
	mobkit.queue_high(self,func,prty)
end




local function big_aqua_roam(self,prty,speed)
	local tyaw = 0
	local init = true
	local prvscanpos = {x=0,y=0,z=0}
	local center = self.object:get_pos()
	local func = function(self)
		if init then
			mobkit.animate(self,'def')
			init = false
		end
		local pos = mobkit.get_stand_pos(self)
		local yaw = self.object:get_yaw()
		local scanpos = mobkit.get_node_pos(mobkit.pos_translate2d(pos,yaw,speed))
		if not vector.equals(prvscanpos,scanpos) then
			prvscanpos=scanpos
			local nyaw,height = aqua_radar_dumb(pos,yaw,speed,true)
			if height and height > pos.y then
				local vel = self.object:get_velocity()
				vel.y = vel.y+1
				self.object:set_velocity(vel)
			end	
			if yaw ~= nyaw then
				tyaw=nyaw
				mobkit.hq_aqua_turn(self,prty+1,tyaw,speed)
				return
			end
		end
		if mobkit.timer(self,10) then
			if vector.distance(pos,center) > abr*16*0.5 then
				tyaw = minetest.dir_to_yaw(vector.direction(pos,{x=center.x+random()*10-5,y=center.y,z=center.z+random()*10-5}))
			else
				if random(10)>=9 then tyaw=tyaw+random()*pi - pi*0.5 end
			end
		end
		
		if mobkit.timer(self,20) then mobkit.turn2yaw(self,tyaw,-1) end
		local yaw = self.object:get_yaw()
		mobkit.go_forward_horizontal(self,yaw,speed)
	end
	mobkit.queue_high(self,func,prty)
end


local function chose_turn(self,pos,yaw)
    
    local remember = mobkit.recall(self,"turn") or "0"
    local clockpos = mobkit.pos_translate2d(pos,yaw+(pi/4),10)
    local clockpos1 = mobkit.pos_shift(clockpos,{x=-3,y=-2,z=-3})
    clockpos = mobkit.pos_shift(clockpos,{x=3,y=3,z=3})
    local revpos = mobkit.pos_translate2d(pos,yaw-(pi/4),10)
    local revpos1 = mobkit.pos_shift(revpos,{x=-3,y=-2,z=-3})
    revpos = mobkit.pos_shift(revpos,{x=3,y=3,z=3})
    
    local ccheck= minetest.find_nodes_in_area(clockpos,clockpos1, {"group:water","default:sand_with_kelp"})
    local rcheck = minetest.find_nodes_in_area(revpos,revpos1, {"group:water","default:sand_with_kelp"})
    --minetest.chat_send_all(dump(#rcheck).." : "..dump(#ccheck).."    "..dump(remember).."     --> "..dump(self.isonground))
    local a = #ccheck
    local b = #rcheck
    
    if a > b+15 then 
        mobkit.remember(self,"turn", "1")
        return false
        
    elseif a < b-15 then
        mobkit.remember(self,"turn","0")
        return true
        
    else 
        
        if remember == "0" then return true else return false end
    
    end
end
    


local function whale_brain(self)
    
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
		mobkit.hq_die(self)
		return
	end
    
    
    -- big animals need to avoid obstacles
    
    
    if mobkit.timer(self,1) then
        local yaw =  self.object:get_yaw() + pi
        local pos = mobkit.get_stand_pos(self)
        
        local spos = mobkit.pos_translate2d(pos,yaw,15)
                
        local left = mobkit.pos_shift(spos,{x=-3,y=3,z=-3})
        local right = mobkit.pos_shift(spos,{x=3,y=3,z=3})
        
        
        local up = mobkit.pos_shift(spos,{x=-1,y=3,z=-1})
        local down = mobkit.pos_shift(spos,{x=1,y=-2,z=1})
        
        
        
        yaw = yaw - pi
        
        
        local vcheck= minetest.find_nodes_in_area(up,down, {"group:water","default:sand_with_kelp"})
        local hcheck = minetest.find_nodes_in_area(left,right, {"group:water","default:sand_with_kelp"})
        --minetest.chat_send_all(dump(#vcheck).." - "..dump(#hcheck))
        if #vcheck < 54 or #hcheck < 49 then
            mobkit.clear_queue_high(self)
            if chose_turn(self,pos,yaw) then
                big_hq_aqua_turn(self,30,yaw+(pi/24),-0.5)
            else
                big_hq_aqua_turn(self,30,yaw-(pi/24),-0.5)
            end
           
        end
        
    end
        
    
	if mobkit.is_queue_empty_high(self) then big_aqua_roam(self,20,-1) end
end




-- spawning is too specific to be included in the api, this is an example.
-- a modder will want to refer to specific names according to games/mods they're using 
-- in order for mobs not to spawn on treetops, certain biomes etc.

local function spawnstep(dtime)

	for _,plyr in ipairs(minetest.get_connected_players()) do
		if random()<dtime*0.2 then	-- each player gets a spawn chance every 5s on average
			local vel = plyr:get_player_velocity()
			local spd = vector.length(vel)
			local chance = spawn_rate * 1/(spd*0.75+1)  -- chance is quadrupled for speed=4
			local yaw
			if spd > 1 then
				-- spawn in the front arc
				yaw = minetest.dir_to_yaw(vel) + random()*0.35 - 0.75
			else
				-- random yaw
				yaw = random()*pi*2 - pi
			end
			local pos = plyr:get_pos()
			local dir = vector.multiply(minetest.yaw_to_dir(yaw),abr*16)
			local pos2 = vector.add(pos,dir)
			pos2.y=pos2.y-5
			local height, liquidflag = mobkit.get_terrain_height(pos2,32)
            
            if not liquidflag then return end
	
			if height and mobkit.nodeatpos({x=pos2.x,y=height-0.01,z=pos2.z}).is_ground_content then

				local objs = minetest.get_objects_inside_radius(pos,abr*16+5)
				local wcnt=0
				local dcnt=0
				local mobname = 'water_life:whale'
				if liquidflag then		-- whales
					local spnode = mobkit.nodeatpos({x=pos2.x,y=height+0.01,z=pos2.z})
					local spnode2 = mobkit.nodeatpos({x=pos2.x,y=height+1.01,z=pos2.z}) -- node above to make sure won't spawn in shallows
					nodename_water = nodename_water or minetest.registered_aliases.mapgen_water_source
					if spnode and spnode2 and spnode.name == nodename_water and spnode2.name == nodename_water then
						
					mobname = 'water_life:whale'
					else
						return
					end
					
				
				end
				if chance < random() then
					pos2.y = height+1.01
					objs = minetest.get_objects_inside_radius(pos2,abr*16-2)
					for _,obj in ipairs(objs) do				-- do not spawn if another player around
						if obj:is_player() then return end
					end
                    local a=pos2.x
                    local b=pos2.y
                    local c=pos2.z
                    
                    local water = minetest.find_nodes_in_area({x=a-5, y=b-5, z=c-5}, {x=a+5, y=b+5, z=c+5}, {"default:water_source"})
                    
                    if #water < 900 then return end    -- whales need water, much water
                    local ms = count_whales(pos)
                    local mw = count_whales(pos2)
                    --minetest.chat_send_all("Maxwhales = "..maxwhales.."  counted: "..ms.." - "..mw.." abo="..abo.." abr="..abr)
                    if ms > (maxwhales-1) then return end  -- whales are no sardines

                    local obj=minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
				end
			end
		end
	end
end




minetest.register_entity("water_life:whale",{
											-- common props
	physical = true,
	stepheight = 0.1,				--EVIL!
	collide_with_objects = true,
	collisionbox = {-3, -2, -3, 3, 2, 3},
	visual = "mesh",
	mesh = "water_life_whale.b3d",
	textures = {"water_life_whale.png"},
	visual_size = {x = 3.5, y = 3.5},
	static_save = true,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 0.98,					-- portion of hitbox submerged
	max_speed = -1,                        -- no matter which number is here, whales always at same speed
	jump_height = 1.26,
	view_range = 32,
--	lung_capacity = 0, 		-- seconds
	max_hp = 500,
	timeout=300,
	attack={range=1.5,damage_groups={fleshy=15}},
	sounds = {
      random = "water_life_whale",
      death = "water_life_whale",
      distance = 50,
	},
    
	animation = {
		def={range={x=1,y=59},speed=5,loop=true},	
		fast={range={x=1,y=59},speed=20,loop=true},
		back={range={x=15,y=1},speed=7,loop=false},
		},
	
	brainfunc = whale_brain,
    
    on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
			local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
			self.object:set_velocity({x=hvel.x,y=2,z=hvel.z})
            self.object:add_velocity({x=0,y=-5, z=0})
			
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

			
		end
	end,
	
})

minetest.register_globalstep(spawnstep)




--sharks



local function shark_brain(self)
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
		mobkit.hq_die(self)
		return
	end
	
	if mobkit.timer(self,1) then
		
        local whale =  mobkit.get_closest_entity(self,"water_life:whale")
        if whale then
            local spos = self.object:get_pos()
            local wpos = whale:get_pos()
            local distance =  math.floor(vector.distance(spos,wpos))
            if distance < 15 then
                local yaw = self.object:get_yaw()
                mobkit.clear_queue_high(self)
                mobkit.hq_aqua_turn(self,40,yaw+(pi/2),5)
            end
        end
        local prty = mobkit.get_queue_priority(self)
		if prty < 20 then
			local target = mobkit.get_nearby_player(self)
			local food = mobkit.get_nearby_entity(self,"wildlife:deer")
			if target and mobkit.is_alive(target) and mobkit.is_in_deep(target) then
				mobkit.hq_aqua_attack(self,20,target,7)
			end

			if food and mobkit.is_in_deep(food) then
                                mobkit.clear_queue_high(self)
                                mobkit.hq_aqua_attack(self,30,food,7)
                        end
		end
	end
	if mobkit.is_queue_empty_high(self) then mobkit.hq_aqua_roam(self,10,5) end
end
-- spawning is too specific to be included in the api, this is an example.
-- a modder will want to refer to specific names according to games/mods they're using 
-- in order for mobs not to spawn on treetops, certain biomes etc.

local function shark_spawnstep(dtime)

	for _,plyr in ipairs(minetest.get_connected_players()) do
		if random()<dtime*0.2 then	-- each player gets a spawn chance every 5s on average
			local vel = plyr:get_player_velocity()
			local spd = vector.length(vel)
			local chance = spawn_rate * 1/(spd*0.75+1)  -- chance is quadrupled for speed=4
			local yaw
			if spd > 1 then
				-- spawn in the front arc
				yaw = minetest.dir_to_yaw(vel) + random()*0.35 - 0.75
			else
				-- random yaw
				yaw = random()*pi*2 - pi
			end
			local pos = plyr:get_pos()
			local dir = vector.multiply(minetest.yaw_to_dir(yaw),abr*16)
			local pos2 = vector.add(pos,dir)
			pos2.y=pos2.y-5
			local height, liquidflag = mobkit.get_terrain_height(pos2,32)
            
            if not liquidflag then return end
	
			if height and mobkit.nodeatpos({x=pos2.x,y=height-0.01,z=pos2.z}).is_ground_content then

				local objs = minetest.get_objects_inside_radius(pos,abr*16+5)
				local wcnt=0
				local dcnt=0
				local mobname = 'water_life:shark'
				if liquidflag then		-- sharks
					local spnode = mobkit.nodeatpos({x=pos2.x,y=height+0.01,z=pos2.z})
					local spnode2 = mobkit.nodeatpos({x=pos2.x,y=height+1.01,z=pos2.z}) -- node above to make sure won't spawn in shallows
					nodename_water = nodename_water or minetest.registered_aliases.mapgen_water_source
					if spnode and spnode2 and spnode.name == nodename_water and spnode2.name == nodename_water then
						
					mobname = 'water_life:shark'
					else
						return
					end
					
				
				end
				if chance < random() then
					pos2.y = height+1.01
					objs = minetest.get_objects_inside_radius(pos2,abr*16-2)
					for _,obj in ipairs(objs) do				-- do not spawn if another player around
						if obj:is_player() then return end
					end
                    local a=pos2.x
                    local b=pos2.y
                    local c=pos2.z
                    
                    local water = minetest.find_nodes_in_area({x=a-4, y=b-4, z=c-4}, {x=a+4, y=b+4, z=c+4}, {"default:water_source"})
                    
                    if #water < 128 then return end    -- sharks need water, much water
                    local ms = count_sharks(pos)
                    --minetest.chat_send_all("Maxsharks = "..maxsharks.."  counted: "..ms.." abo="..abo.." abr="..abr)
                    if ms > (maxsharks-1) then return end  -- sharks are no sardines

                    local obj=minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
				end
			end
		end
	end
end


minetest.register_entity("water_life:shark",{
											-- common props
	physical = true,
	stepheight = 0.1,				--EVIL!
	collide_with_objects = true,
	collisionbox = {-0.5, -0.3, -0.5, 0.5, 0.3, 0.5},
	visual = "mesh",
	mesh = "water_life_shark.b3d",
	textures = {"water_life_shark3tex.png"},
	visual_size = {x = 1.5, y = 1.5},
	static_save = true,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 0.98,					-- portion of hitbox submerged
	max_speed = 7,                        -- no matter which number is here, sharks always at same speed
	jump_height = 1.26,
	view_range = 32,
--	lung_capacity = 0, 		-- seconds
	max_hp = 50,
	timeout=60,
	attack={range=0.8,damage_groups={fleshy=7}},
	sounds = {
		attack='water_life_sharkattack',
		},
	animation = {
		def={range={x=1,y=59},speed=40,loop=true},	
		fast={range={x=1,y=59},speed=80,loop=true},
		back={range={x=15,y=1},speed=-15,loop=false},
		},
	
	brainfunc = shark_brain,
	
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
			local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
			self.object:set_velocity({x=hvel.x,y=2,z=hvel.z})
			
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

			if type(puncher)=='userdata' and puncher:is_player() then	-- if hit by a player
				mobkit.clear_queue_high(self)							-- abandon whatever they've been doing
				mobkit.hq_aqua_attack(self,20,puncher,6)				-- get revenge
			end
		end
	end,
})

minetest.register_globalstep(shark_spawnstep)
