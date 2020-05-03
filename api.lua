
local abs = math.abs
local pi = math.pi
local floor = math.floor
local sqrt = math.sqrt
local max = math.max
local min = math.min
local pow = math.pow
local sign = math.sign
local time = os.time


-- pseudo random generator, init and call function
water_life.randomtable = PcgRandom(math.random(2^23)+1)

function water_life.random(min,max)
	if not min and not max then return math.abs(water_life.randomtable:next() / 2^31) end
	if not max then
		max = min
		min = 1
	end
	if max and not min then min = 1 end
	return water_life.randomtable:next(min,max)
end

local random = water_life.random



function water_life_get_biome_data(pos)
	if not pos then return nil end
	local table = minetest.get_biome_data(pos)
	if not table then return nil end
	local biome = {}
	biome.id = table.biome
	biome.name = minetest.get_biome_name(table.biome)
	biome.temp = math.floor((table.heat-32)*5/9)
	biome.humid = math.floor(table.humidity*100)/100
	return biome
end


--sets an urchin somewhere but not in the center of a node
function water_life.set_urchin(pos,name)
	if not pos then return end
	if not name then name = "water_life:urchin" end
	local x = random()/2
	local z = random()/2
	if water_life.leftorright() then pos.x = pos.x +x else pos.x=pos.x - x end
	if water_life.leftorright() then pos.z = pos.z +z else pos.z=pos.z - z end
	local obj = minetest.add_entity(pos, name)
	return obj
end
	
-- add vector cross function for flying behavior if not yet there
if vector and not vector.cross then	
	function vector.cross(a, b)
		return {
			x = a.y * b.z - a.z * b.y,
			y = a.z * b.x - a.x * b.z,
			z = a.x * b.y - a.y * b.x
		}
	end
end



-- show temp marker
function water_life.temp_show(pos,time,pillar)
	if not pos then return end
	if not time then time = 5 end
	local step = 1
	if not pillar then pillar = 1 end
	if pillar < 0 then step = -1 end
	
	for i = 1,pillar,step do
		
		local obj = minetest.add_entity({x=pos.x, y=pos.y+i, z=pos.z}, "water_life:pos")
		minetest.after(time, function(obj) obj:remove() end, obj)
	end
	
end


-- throws a coin
function water_life.leftorright()
    local rnd = random()
    if rnd > 0.5 then return true else return false end
end


-- distance from self to target
function water_life.dist2tgt(self,tgt)
	local pos = mobkit.get_stand_pos(self)
	local tpos = tgt:get_pos()
	return vector.distance(pos,tpos)
end



 -- drop on death what is definded in the entity table
function water_life.handle_drops(self)   
    if not self.drops then return end
    
    for _,item in ipairs(self.drops) do
        
        local amount = random (item.min, item.max)
        local chance = random(1,100) 
        local pos = self.object:get_pos()
		pos.y = pos.y + self.collisionbox[5] +1
        
        if chance < (100/item.chance) then
            local obj = minetest.add_item(pos, item.name.." "..tostring(amount))
        end
        
    end
end



function water_life.register_shark_food(name)
    table.insert(water_life.shark_food,name)
end


function water_life.feed_shark(self)
	for i = 1,#water_life.shark_food,1 do
		if water_life.shark_food[i] ~= "water_life:fish" and water_life.shark_food[i] ~= "water_life:fish_tamed" then
			local target = mobkit.get_closest_entity(self,water_life.shark_food[i])
			if target then
				return target
			end
		end
	end
	return nil
end


function water_life.aqua_radar_dumb(pos,yaw,range,reverse)
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



-- counts animals in specified radius or active_object_send_range_blocks, returns a table containing numbers
function water_life.count_objects(pos,radius,name)

if not radius then radius = water_life.abo * 16 end

local all_objects = minetest.get_objects_inside_radius(pos, radius)
local hasil = {}
hasil.whales = 0
hasil.sharks = 0
hasil.fish = 0
hasil.name = 0
hasil.all = #all_objects or 0

local _,obj
for _,obj in ipairs(all_objects) do
    local entity = obj:get_luaentity()
	if name then
		if entity and entity.name == name then
			hasil.name = hasil.name +1
		end
	end
	if entity and entity.name == "water_life:whale" then
		hasil.whales = hasil.whales +1
    elseif entity and entity.name == "water_life:shark" then
		hasil.sharks = hasil.sharks +1
    elseif entity and (entity.name == "water_life:fish" or entity.name == "water_life:fish_tamed") then
        hasil.fish = hasil.fish +1
	end
end
return hasil
end




-- returns 2D angle from self to target in radians
function water_life.get_yaw_to_object(self,target)

    local pos = mobkit.get_stand_pos(self)
    local tpos = target:get_pos()
	local tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos))
    return tyaw
end

-- returns 2D angle from self to pos in radians
function water_life.get_yaw_to_pos(self,tpos)

    local pos = mobkit.get_stand_pos(self)
    local tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos))
    
    return tyaw
end

-- turn around 180degrees from tgtob and swim away until out of sight
function water_life.hq_swimfrom(self,prty,tgtobj,speed,outofsight) 
	
	local func = function(self)
		if not outofsight then outofsight = self.view_range * 1.5 end
		
		if not mobkit.is_alive(tgtobj) then return true end
        
            local pos = mobkit.get_stand_pos(self)
            local opos = tgtobj:get_pos()
			local yaw = water_life.get_yaw_to_object(self,tgtobj) + math.rad(random(-30,30))+math.rad(180)
            local distance = vector.distance(pos,opos)
            
            if distance < outofsight then
                
                local swimto, height = water_life.aqua_radar_dumb(pos,yaw,3)
                if height and height > pos.y then
                    local vel = self.object:get_velocity()
                    vel.y = vel.y+0.1
                    self.object:set_velocity(vel)
                end	
                mobkit.hq_aqua_turn(self,51,swimto,speed)
                
            else
                return true
            end
                
            --minetest.chat_send_all("angel= "..dump(yaw).."  viewrange= "..dump(self.view_range).." distance= "..dump(vector.distance(pos,opos)))

        
		
	end
	mobkit.queue_high(self,func,prty)
end



-- same as mobkit.hq_aqua_turn but for large mobs
function water_life.big_hq_aqua_turn(self,prty,tyaw,speed)
    
	local func = function(self)
    if not speed then speed = 0.4 end
    if speed < 0 then speed = speed * -1 end
        
        local finished=mobkit.turn2yaw(self,tyaw,speed)
        if finished then return true end
	end
	mobkit.queue_high(self,func,prty)
end



-- same as mobkit.hq_aqua_roam but for large mobs
function water_life.big_aqua_roam(self,prty,speed)
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
			local nyaw,height = water_life.aqua_radar_dumb(pos,yaw,speed,true)
			if height and height > pos.y then
				local vel = self.object:get_velocity()
				vel.y = vel.y+0.1
				self.object:set_velocity(vel)
			end	
			if yaw ~= nyaw then
				tyaw=nyaw
				mobkit.hq_aqua_turn(self,prty+1,tyaw,speed)
				return
			end
		end
		if mobkit.timer(self,10) then
			if vector.distance(pos,center) > water_life.abr*16*0.5 then
				tyaw = minetest.dir_to_yaw(vector.direction(pos,{x=center.x+random()*10-5,y=center.y,z=center.z+random()*10-5}))
			else
				if random(10)>=9 then tyaw=tyaw+random()*pi - pi*0.5 end
			end
		end
		
		if mobkit.timer(self,20) then mobkit.turn2yaw(self,tyaw,-1) end
		--local yaw = self.object:get_yaw()
		mobkit.go_forward_horizontal(self,speed)
	end
	mobkit.queue_high(self,func,prty)
end



function water_life.hq_snail_move(self,prty)
	local ground = mobkit.get_stand_pos(self)
	local coraltable = minetest.find_nodes_in_area({x=ground.x-3, y=ground.y-1, z=ground.z-3}, {x=ground.x+3, y=ground.y, z=ground.z+3}, water_life.urchinspawn)
	if not coraltable or #coraltable < 1 then return end
	local tgpos = coraltable[random(#coraltable)]
	
	local func = function(self)
		if not mobkit.is_alive(self) then return true end
		local pos = mobkit.get_stand_pos(self)
		local dist = vector.distance(pos,tgpos)
		
		mobkit.drive_to_pos(self,tgpos,0.01,0.1,1.5)
		--minetest.chat_send_all(dump(dist))
		if dist <= 1.8 then return true end
	end
	
	mobkit.queue_high(self,func,prty)
end
	

function water_life.hq_idle(self,prty,duration,anim)
	anim = anim or 'stand'
	local init = true
	
	local func=function(self)
		if init then 
			mobkit.animate(self,anim) 
			init=false
		end
		duration = duration-self.dtime
		if duration <= 0 then return true end
	end
	mobkit.queue_high(self,func,prty)
end


-- swim to the next "node" which is inside viewrange or quit -- node can be string or table of string
-- if tgtpos is given node will be ignored
function water_life.hq_swimto(self,prty,speed,node,tgtpos)
	
	local endpos = tgtpos
	local pos = self.object:get_pos()
	local r = self.view_range
	if not tgtpos then
		endpos = minetest.find_node_near(pos, r, node)
	end
    if not endpos then return true end
    
    
	local func = function(self)
	
	
		local yaw = water_life.get_yaw_to_pos(self,endpos)
		if not mobkit.is_alive(self) then return true end
		local pos = self.object:get_pos()
		
		
		if vector.distance(pos,endpos) > 1 then
					
					--minetest.chat_send_all(vector.distance(pos,endpos))
					if endpos.y > pos.y then
						local vel = self.object:get_velocity()
						vel.y = vel.y+0.3
						self.object:set_velocity(vel)
					end	
					mobkit.hq_aqua_turn(self,prty+5,yaw,speed)
					pos = self.object:get_pos() --mobkit.get_stand_pos(self)
					yaw = water_life.get_yaw_to_pos(self,endpos)
				
		else			
			return true
		end
    
end
	mobkit.queue_high(self,func,prty)
    
end


function water_life.hq_water_attack(self,tgtobj,prty,speed)
	
	local pos = self.object:get_pos()
	local selfbox = self.object:get_properties().collisionbox
	local tgtbox = tgtobj:get_properties().collisionbox
	if not speed then speed = 1 end
    
	local func = function(self)
    
		if not mobkit.is_alive(self) or not mobkit.is_alive(tgtobj) or tgtobj:get_attach() ~= nil then return true end
		local pos = self.object:get_pos()
		local endpos = tgtobj:get_pos()
		if not mobkit.is_in_deep(tgtobj) and vector.distance (pos,endpos) > 2 then return true end
		local yaw = water_life.get_yaw_to_pos(self,endpos)
		local entity = nil
		if not tgtobj:is_player() then entity = tgtobj:get_luaentity() end
		
		if vector.distance(pos,endpos) > selfbox[5]+tgtbox[5] then
					--minetest.chat_send_all(dump(vector.distance(pos,endpos)).."   "..dump(selfbox[5]+tgtbox[5]))
					if endpos.y > pos.y +tgtbox[5] then
						local vel = self.object:get_velocity()
						vel.y = vel.y+0.4
						self.object:set_velocity(vel)
					end
					if endpos.y < pos.y  then
						local vel = self.object:get_velocity()
						vel.y = vel.y-0.1
						self.object:set_velocity(vel)
					end
					mobkit.hq_aqua_turn(self,prty+5,yaw,speed)
					
		else
			if mobkit.is_alive(tgtobj) then
				
				--minetest.chat_send_all("<<<HIT>>>")
				tgtobj:punch(self.object,1,self.attack)
				return true
				
				
			else
				return true
			end
		end
		if entity and string.match(entity.name,"petz") and vector.distance(pos,endpos) < 2 then
			if mobkit.is_alive(tgtobj) then
				--minetest.chat_send_all("<<<HIT>>>")
				mobkit.hurt(entity,self.attack.damage_groups.fleshy or 4)
				
			else
				return true
			end
		end
    
end
	mobkit.queue_high(self,func,prty)
    
end

-- find if there is a node between pos1 and pos2
-- water = true means water = obstacle
-- returns distance to obstacle in nodes or nil

function water_life.find_collision(pos1,pos2,water)
    local ray = minetest.raycast(pos1, pos2, false, water)
            for pointed_thing in ray do
                if pointed_thing.type == "node" then
                    local dist = math.floor(vector.distance(pos1,pointed_thing.under))
                    return dist
                end
            end
            return nil
end


-- radar function for obstacles lying in front of an entity 
-- use water = true if water should be an obstacle

function water_life.radar(pos, yaw, radius, water)
    
    if not radius or radius < 1 then radius = 16 end
    local left = 0
    local right = 0
    if not water then water = false end
    for j = 0,3,1 do
        for i = 0,4,1 do
            local pos2 = mobkit.pos_translate2d(pos,yaw+(i*pi/16),radius)
            local pos3 = mobkit.pos_translate2d(pos,yaw-(i*pi/16),radius)
            --minetest.set_node(pos2,{name="default:stone"})
            if water_life.find_collision(pos,{x=pos2.x, y=pos2.y + j*2, z=pos2.z}, water) then
                left = left + 5 - i
            end
            if water_life.find_collision(pos,{x=pos3.x, y=pos3.y + j*2, z=pos3.z},water) then
                right = right + 5 - i
            end
        end
    end
    local up =0
    local down = 0
    for j = -4,4,1 do
        for i = -3,3,1 do
            local k = i
            local pos2 = mobkit.pos_translate2d(pos,yaw+(i*pi/16),radius)
            local collide = water_life.find_collision(pos,{x=pos2.x, y=pos2.y + j, z=pos2.z}, water)
            if k < 0 then k = k * -1 end
            if collide and j <= 0 then 
                down = down + math.floor((7+j-k)*collide/radius*2)
            elseif collide and j >= 0 then
                up = up + math.floor((7-j-k)*collide/radius*2)
            end
        end
    end
    local under = water_life.find_collision(pos,{x=pos.x, y=pos.y - radius, z=pos.z}, water)
    if not under then under = radius end
    local above = water_life.find_collision(pos,{x=pos.x, y=pos.y + radius, z=pos.z}, water)
    if not above then above = radius end
    if water_life.radar_debug then
        minetest.chat_send_all(dump(water_life.radar_debug).."  left = "..left.."   right = "..right.."   up = "..up.."   down = "..down.."   under = "..under.."   above = "..above)
    end
    return left, right, up, down, under, above
end


-- function to find liquid surface and depth at that position
function water_life.water_depth(pos,max)
	
	local depth = {}
	depth.surface = {}
	depth.depth = 0
	depth.type = ""
	if not max then max = 10 end
	if not pos then return depth end
	local tempos = {}
	local node = minetest.get_node(pos)
	if not node or node.name == 'ignore' then return depth end
	if not minetest.registered_nodes[node.name] then return depth end						-- handle unknown nodes
		
	local type = minetest.registered_nodes[node.name]["liquidtype"]
	local found = false
	--minetest.chat_send_all(">>>"..dump(node.name).." <<<")
	if type == "none" then 															-- start in none liquid try to find surface
		
		local under = water_life.find_collision(pos,{x=pos.x, y=pos.y - max, z=pos.z}, true)
		--minetest.chat_send_all(dump(under).."  "..dump(node.name))
		if under then
			local check = {x=pos.x, y=pos.y - under-1, z=pos.z}
			local cname = minetest.get_node(check).name
			if not minetest.registered_nodes[cname] then return depth end					-- handle unknown nodes
			if minetest.registered_nodes[cname]["liquidtype"] == "source" then
				depth.surface = check
				found = true
			end
		end
		if not found then
			return depth
		end
	
	else																			-- start in liquid find way up first
		
		local lastpos = pos
		for i = 1,max,1 do
			tempos = {x=pos.x, y=pos.y+i, z= pos.z}
			node = minetest.get_node(tempos)
			if not minetest.registered_nodes[node.name] then return depth end				-- handle unknown nodes
			local ctype = minetest.registered_nodes[node.name]["liquidtype"]

			if ctype ~= "source" then
				depth.surface = lastpos
				found = true
				break
			end
			lastpos = tempos
		end
		if not found then depth.surface = lastpos end
	end
	
	pos = depth.surface
	depth.type = minetest.get_node(pos).name or ""
	local under = water_life.find_collision(pos,{x=pos.x, y=pos.y - max, z=pos.z}, false)
	depth.depth = under or max

	return depth
end
	
	

-- Entity definitions

-- entity for showing positions in debug
minetest.register_entity("water_life:pos", {
	initial_properties = {
		visual = "cube",
        collide_with_objects = false,                  
		visual_size = {x=1.1, y=1.1},
		textures = {"water_life_pos.png", "water_life_pos.png",
			"water_life_pos.png", "water_life_pos.png",
			"water_life_pos.png", "water_life_pos.png"},
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
		physical = false,
	}
})

if water_life.radar_debug then
minetest.register_on_player_hpchange(function(player, hp_change, reason)
        if not player or hp_change >= 0 then return hp_change end
        local name = player:get_player_name()
        local privs = minetest.get_player_privs(name)
        if not privs.god then return hp_change end
        return 0
        end, true)
        
minetest.register_privilege("god", {description ="unvulnerable"})
end

 --chatcommands

minetest.register_chatcommand("wl_bdata", {
	params = "",
	description = "biome id,name,heat and humidity",
	privs = {server = true},
	func = function(name, action)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		local pos = player:get_pos()
		local table = minetest.get_biome_data(pos)
		
		minetest.chat_send_player(name,dump(minetest.registered_biomes[minetest.get_biome_name(table.biome)]))
                                           
		minetest.chat_send_player(name,"ID :"..dump(table.biome).."  /Name :"..dump(minetest.get_biome_name(table.biome)).."  /Temp. in C :"..dump(math.floor((table.heat-32)*5/9)).."  /Humidity in % :"..dump(math.floor(table.humidity*100)/100))
		
	end
})

minetest.register_chatcommand("wl_version", {
	params = "",
	description = "shows water_life version number",
	privs = {server = true},
	func = function(name, action)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		
		minetest.chat_send_player(name,core.colorize("#14ee00","Your water_life version # is: "..water_life.version))
        
	end
})
