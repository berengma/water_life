
local abs = math.abs
local pi = math.pi
local floor = math.floor
local ceil = math.ceil
local sqrt = math.sqrt
local max = math.max
local min = math.min
local pow = math.pow
local sign = math.sign
local time = os.time
local rad = math.rad
local random = water_life.random
local deg=math.deg
local tan = math.tan
local cos = math.cos
local atan=math.atan



local neighbors ={
	{x=1,z=0},
	{x=1,z=1},
	{x=0,z=1},
	{x=-1,z=1},
	{x=-1,z=0},
	{x=-1,z=-1},
	{x=0,z=-1},
	{x=1,z=-1}
	}

	
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
	biome.temp = math.floor((table.heat-32)*5/9)				--turn fahrenheit into celsius
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


function water_life.dumbstep(self,height,tpos,speed_factor,idle_duration)
	if height <= 0.001 then
		mobkit.lq_turn2pos(self,tpos) 
		water_life.lq_dumbwalk(self,tpos,speed_factor)
	else
		mobkit.lq_turn2pos(self,tpos) 
		water_life.lq_dumbjump(self,height) 
	end
	idle_duration = idle_duration or 6
	mobkit.lq_idle(self,random(ceil(idle_duration*0.5),idle_duration))
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




function water_life.get_close_drops(self,name)
	
	
	local objs = minetest.get_objects_inside_radius(self.object:get_pos(), water_life.abr * 16)
	if #objs < 1 then return nil end
	
	for i = #objs,1,-1 do
		local entity = objs[i]:get_luaentity()
		if not entity or not entity.name == "__builtin:item" then table.remove(objs,i) end   -- remove any entity different from a drop
	end
	
	if #objs < 1 then return nil end
	if not name then return objs[random(#objs)] end 									-- no name, return random drop
	
	for i=#objs,1,-1 do
		local entity = objs[i]:get_luaentity()
		if not entity.itemstring then 
			table.remove(objs,i)
		else
			if not string.match(entity.itemstring,name) then table.remove(objs,i) end			-- remove anything different from name 
		end
	end
	
	if #objs < 1 then
		return nil
	else
		return objs[random(#objs)]
	end
end
	

function water_life.inwater(obj)
	if not obj then return nil end
	local pos = obj:get_pos()
	local node = minetest.get_node(pos)
	if not node or node.name == 'ignore' then return nil end
	if not minetest.registered_nodes[node.name] then return nil end						-- handle unknown nodes
		
	local type = minetest.registered_nodes[node.name]["liquidtype"]
	if type == "none" then return nil end
	return true
end

function water_life.aqua_radar_dumb(pos,yaw,range,reverse,shallow) -- same as mobkit's but added shallow water if true
	range = range or 4
	
	local function okpos(p)
		local node = mobkit.nodeatpos(p)
		if node then 
			if node.drawtype == 'liquid' then 
				local nodeu = mobkit.nodeatpos(mobkit.pos_shift(p,{y=1}))
				local noded = mobkit.nodeatpos(mobkit.pos_shift(p,{y=-1}))
				if ((nodeu and nodeu.drawtype == 'liquid') or (noded and noded.drawtype == 'liquid')) or shallow then
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
	
	if entity and entity.name then
			if not hasil[entity.name] then
				hasil[entity.name] = 1
			else
				hasil[entity.name] = hasil[entity.name] +1
			end
		end
	end

	return hasil
end


function water_life.get_herd_members(self,radius)
	
	local pos = mobkit.get_stand_pos(self)
	local name = self.name
	
	if not radius then radius = water_life.abo * 16 end

	local all_objects = minetest.get_objects_inside_radius(pos, radius)
	if #all_objects < 1 then return nil end

	for i = #all_objects,1,-1 do
	local entity = all_objects[i]:get_luaentity()
		
		if entity and entity.name ~= name then
				table.remove(all_objects,i)
		end
		
	end
	
	if #all_objects < 1 then
		return nil
	else
		return all_objects
	end
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






function water_life.isinliquid(target)
	if not target then return false end
	local nodepos = mobkit.get_stand_pos(target)
	local node1 = mobkit.nodeatpos(nodepos)
	nodepos.y = nodepos.y -1
	local node2 = mobkit.nodeatpos(nodepos)
	if node1 and node1.drawtype=='liquid' or (node2 and node2.drawtype=='liquid' and node1 and node1.drawtype=='airlike') then
		return true
	end
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
       -- minetest.chat_send_all(dump(water_life.radar_debug).."  left = "..left.."   right = "..right.."   up = "..up.."   down = "..down.."   under = "..under.."   above = "..above)
    end
    return left, right, up, down, under, above
end


-- function to find liquid surface and depth at that position
function water_life.water_depth(pos,max)
	
	
	local surface = {}
	local depth = 0
	local type = ""
	if not max then max = 10 end
	if not pos then return nil end
	local tempos = {}
	local node = minetest.get_node(pos)
	if not node or node.name == 'ignore' then return nil end
	if not minetest.registered_nodes[node.name] then return nil end						-- handle unknown nodes
		
	local type = minetest.registered_nodes[node.name]["liquidtype"]
	local found = false
	--minetest.chat_send_all(">>>"..dump(node.name).." <<<")
	if type == "none" then 															-- start in none liquid try to find surface
		
		local under = water_life.find_collision(pos,{x=pos.x, y=pos.y - max, z=pos.z}, true)
		--minetest.chat_send_all(dump(under).."  "..dump(node.name))
		if under then
			local check = {x=pos.x, y=pos.y - under-1, z=pos.z}
			local cname = minetest.get_node(check).name
			if not minetest.registered_nodes[cname] then return nil end					-- handle unknown nodes
			if minetest.registered_nodes[cname]["liquidtype"] == "source" then
				surface = check
				found = true
			end
		end
		if not found then
			return nil
		end
	
	else																			-- start in liquid find way up first
		
		local lastpos = pos
		for i = 1,max,1 do
			tempos = {x=pos.x, y=pos.y+i, z= pos.z}
			node = minetest.get_node(tempos)
			if not minetest.registered_nodes[node.name] then return nil end				-- handle unknown nodes
			local ctype = minetest.registered_nodes[node.name]["liquidtype"]

			if ctype == "none" then
				surface = lastpos
				found = true
				break
			end
			lastpos = tempos
		end
		if not found then surface = lastpos end
	end
	
	pos = surface
	type = minetest.get_node(pos).name or ""
	local under = water_life.find_collision(pos,{x=pos.x, y=pos.y - max, z=pos.z}, false)
	depth = under or max

	return depth, type, surface
end
	
	
-- amphibious version of mobkit
function water_life.get_next_waypoint_fast(self,tpos,nogopos)
	local pos = mobkit.get_stand_pos(self)
	local dir=vector.direction(pos,tpos)
	local neighbor = mobkit.dir2neighbor(dir)
	local height, pos2, liquidflag = mobkit.is_neighbor_node_reachable(self,neighbor)
	local heightr = nil
	local heightl = nil
	local liq = nil
	
	if height then
		local fast = false
		heightl = mobkit.is_neighbor_node_reachable(self,mobkit.neighbor_shift(neighbor,-1))
		if heightl and abs(heightl-height)<0.001 then
			heightr = mobkit.is_neighbor_node_reachable(self,mobkit.neighbor_shift(neighbor,1))
			if heightr and abs(heightr-height)<0.001 then
				fast = true
				dir.y = 0
				local dirn = vector.normalize(dir)
				local npos = mobkit.get_node_pos(mobkit.pos_shift(pos,neighbors[neighbor]))
				local factor = abs(dirn.x) > abs(dirn.z) and abs(npos.x-pos.x) or abs(npos.z-pos.z)
				pos2=mobkit.pos_shift(pos,{x=dirn.x*factor,z=dirn.z*factor})
			end
		end
		return height, pos2, fast
	else

		for i=1,4 do
			-- scan left
			height, pos2, liq = mobkit.is_neighbor_node_reachable(self,mobkit.neighbor_shift(neighbor,-i))
			if height then return height,pos2 end
			-- scan right
			height, pos2, liq = mobkit.is_neighbor_node_reachable(self,mobkit.neighbor_shift(neighbor,i))
			if height then return height,pos2 end
		end
	end
end

-- amphibious version of mobkit
function water_life.goto_next_waypoint(self,tpos)
	local height, pos2 = water_life.get_next_waypoint_fast(self,tpos)
	
	if not height then return false end
	
	if height <= 0.01 then
		local yaw = self.object:get_yaw()
		local tyaw = minetest.dir_to_yaw(vector.direction(self.object:get_pos(),pos2))
		if abs(tyaw-yaw) > 1 then
			mobkit.lq_turn2pos(self,pos2) 
		end
		mobkit.lq_dumbwalk(self,pos2)
	else
		mobkit.lq_turn2pos(self,pos2) 
		mobkit.lq_dumbjump(self,height) 
	end
	return true
end



function water_life.get_next_waypoint(self,tpos)
	local pos = mobkit.get_stand_pos(self)
	local dir=vector.direction(pos,tpos)
	local neighbor = mobkit.dir2neighbor(dir)
	local function update_pos_history(self,pos)
		table.insert(self.pos_history,1,pos)
		if #self.pos_history > 2 then table.remove(self.pos_history,#self.pos_history) end
	end
	local nogopos = self.pos_history[2]
	
	local height, pos2, liquidflag = mobkit.is_neighbor_node_reachable(self,neighbor)
--minetest.chat_send_all('pos2 ' .. minetest.serialize(pos2))
--minetest.chat_send_all('nogopos ' .. minetest.serialize(nogopos))	
	if height and not (nogopos and mobkit.isnear2d(pos2,nogopos,0.1)) then

		local heightl = mobkit.is_neighbor_node_reachable(self,mobkit.neighbor_shift(neighbor,-1))
		if heightl and abs(heightl-height)<0.001 then
			local heightr = mobkit.is_neighbor_node_reachable(self,mobkit.neighbor_shift(neighbor,1))
			if heightr and abs(heightr-height)<0.001 then
				dir.y = 0
				local dirn = vector.normalize(dir)
				local npos = mobkit.get_node_pos(mobkit.pos_shift(pos,neighbors[neighbor]))
				local factor = abs(dirn.x) > abs(dirn.z) and abs(npos.x-pos.x) or abs(npos.z-pos.z)
				pos2=mobkit.pos_shift(pos,{x=dirn.x*factor,z=dirn.z*factor})
			end
		end
		update_pos_history(self,pos2)
		return height, pos2
	else

		for i=1,3 do
			-- scan left
			local height, pos2, liq = mobkit.is_neighbor_node_reachable(self,mobkit.neighbor_shift(neighbor,-i*self.path_dir))
			if height and not liq 
			and not (nogopos and mobkit.isnear2d(pos2,nogopos,0.1)) then
				update_pos_history(self,pos2)
				return height,pos2 
			end			
			-- scan right
			height, pos2, liq = mobkit.is_neighbor_node_reachable(self,mobkit.neighbor_shift(neighbor,i*self.path_dir))
			if height and not liq 
			and not (nogopos and mobkit.isnear2d(pos2,nogopos,0.1)) then
				update_pos_history(self,pos2)
				return height,pos2 
			end
		end
		--scan rear
		height, pos2, liquidflag = mobkit.is_neighbor_node_reachable(self,mobkit.neighbor_shift(neighbor,4))
		if height and not liquidflag 
		and not (nogopos and mobkit.isnear2d(pos2,nogopos,0.1)) then
			update_pos_history(self,pos2)
			return height,pos2 
		end
	end
	-- stuck condition here
	table.remove(self.pos_history,2)
	self.path_dir = self.path_dir*-1	-- subtle change in pathfinding
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


-- flying stuff

local function chose_turn(self,a,b)
    
    local remember = mobkit.recall(self,"turn")
    if not remember then
        if water_life.leftorright() then
            remember = "1"
            mobkit.remember(self,"time", self.time_total)
            mobkit.remember(self,"turn", "1")
        else
            remember = "0"
            mobkit.remember(self,"time", self.time_total)
            mobkit.remember(self,"turn", "0")
        end
    end
    
    if a > b then 
        mobkit.remember(self,"turn", "1")
        mobkit.remember(self,"time", self.time_total)
        return false
        
    elseif a < b then
        mobkit.remember(self,"turn","0")
        mobkit.remember(self,"time", self.time_total)
        return true
        
    else 
        
        if remember == "0" then return true else return false end
    
    end
end


local function pitchroll2pitchyaw(aoa,roll)
	if roll == 0.0 then return aoa,0 end 
	-- assumed vector x=0,y=0,z=1
	local p1 = tan(aoa)
	local y = cos(roll)*p1
	local x = sqrt(p1^2-y^2)
	local pitch = atan(y)
	local yaw=atan(x)*math.sign(roll)
	return pitch,yaw
end

function water_life.lq_fly_aoa(self,lift,aoa,roll,acc,anim)
	aoa=rad(aoa)
	roll=rad(roll)
	local hpitch = 0
	local hyaw = 0
	local caoa = 0
	local laoa = nil
	local croll=roll
	local lroll = nil 
	local lastrot = nil
	local init = true
	local func=function(self)
		local rotation=self.object:get_rotation()
		local vel = self.object:get_velocity()	
		local vrot = mobkit.dir_to_rot(vel,lastrot)
		lastrot = vrot
		if init then
			if anim then mobkit.animate(self,anim) end
			init = false	
		end
		
		local accel=self.object:get_acceleration()
		
				-- gradual changes
		if abs(roll-rotation.z) > 0.5*self.dtime then
			croll = rotation.z+0.5*self.dtime*math.sign(roll-rotation.z)
		end		
		
		if 	croll~=lroll then 
			hpitch,hyaw = pitchroll2pitchyaw(aoa,croll)
			lroll = croll
		end
		
		local hrot = {x=vrot.x+hpitch,y=vrot.y-hyaw,z=croll}
		self.object:set_rotation(hrot)
		local hdir = mobkit.rot_to_dir(hrot)
		local cross = vector.cross(vel,hdir)
		local lift_dir = vector.normalize(vector.cross(cross,hdir))	
		
		local daoa = deg(aoa)
		local lift_coefficient = 0.24*abs(daoa)*(1/(0.025*daoa+1))^4*math.sign(aoa)	-- homegrown formula
		local lift_val = lift*vector.length(vel)^2*lift_coefficient
		
		local lift_acc = vector.multiply(lift_dir,lift_val)
		lift_acc=vector.add(vector.multiply(minetest.yaw_to_dir(rotation.y),acc),lift_acc)

		self.object:set_acceleration(vector.add(accel,lift_acc))
	end
	mobkit.queue_low(self,func)
end

function water_life.lq_fly_pitch(self,lift,pitch,roll,acc,anim)
	pitch = rad(pitch)
	roll=rad(roll)
	local cpitch = pitch
	local croll = roll
	local hpitch = 0
	local hyaw = 0
	local lpitch = nil
	local lroll = nil 
	local lastrot = nil
	local init = true

	local func=function(self)
		if init then
			if anim then mobkit.animate(self,anim) end
			init = false	
		end
		local rotation=self.object:get_rotation()
		local accel=self.object:get_acceleration()
		local vel = self.object:get_velocity()	
		local speed = vector.length(vel)
		local vdir = vector.normalize(vel)
		local vrot = mobkit.dir_to_rot(vel,lastrot)
		lastrot = vrot
		
		-- gradual changes
		if abs(roll-rotation.z) > 0.5*self.dtime then
			croll = rotation.z+0.5*self.dtime*math.sign(roll-rotation.z)
		end		
		if abs(pitch-rotation.x) > 0.5*self.dtime then
			cpitch = rotation.x+0.5*self.dtime*math.sign(pitch-rotation.x)
		end
		
		if cpitch~=lpitch or croll~=lroll then 
			hpitch,hyaw = pitchroll2pitchyaw(cpitch,croll)
			lpitch = cpitch lroll = croll
		end
		
		local aoa = deg(-vrot.x+cpitch)							-- angle of attack
		local hrot = {x=hpitch, y=vrot.y-hyaw, z=croll}			-- hull rotation
		self.object:set_rotation(hrot)
		local hdir = mobkit.rot_to_dir(hrot)					-- hull dir
		
		local cross = vector.cross(hdir,vel)					
		local lift_dir = vector.normalize(vector.cross(hdir,cross))
		
		local lift_coefficient = 0.24*max(aoa,0)*(1/(0.025*max(aoa,0)+1))^4	-- homegrown formula
--		local lift_val = mobkit.minmax(lift*speed^2*lift_coefficient,speed/self.dtime)
--		local lift_val = max(lift*speed^2*lift_coefficient,0)
		local lift_val = min(lift*speed^2*lift_coefficient,20)
--if lift_val > 10 then minetest.chat_send_all('lift: '.. lift_val ..' vel:'.. speed ..' aoa:'.. aoa) end
		
		local lift_acc = vector.multiply(lift_dir,lift_val)
		lift_acc=vector.add(vector.multiply(minetest.yaw_to_dir(rotation.y),acc),lift_acc)
		accel=vector.add(accel,lift_acc)
		accel=vector.add(accel,vector.multiply(vdir,-speed*speed*0.02))	-- drag
		accel=vector.add(accel,vector.multiply(hdir,acc))				-- propeller

		self.object:set_acceleration(accel)

	end
	mobkit.queue_low(self,func)
end


-- back to my code
-- hq functions self explaining
function water_life.hq_climb(self,prty,fmin,fmax)
	if not max then max = 30 end
	if not min then min = 20 end
	
	local func=function(self)
		if mobkit.timer(self,1) then
			local remember = mobkit.recall(self,"time")
            if remember then
                if self.time_total - remember > 15 then
                    mobkit.forget(self,"turn")
                    mobkit.forget(self,"time")
                    
                end
            end
			self.action = "fly"
			local pos = self.object:get_pos()
			local yaw = self.object:get_yaw()
			
			local left, right, up, down, under, above = water_life.radar(pos,yaw,32,true)
			
			if  (down < 3) and (under >= fmax) then 
				water_life.hq_glide(self,prty,fmin,fmax)
				return true
			end
            if left > 3 or right > 3 then
                local lift = 0.6
                local pitch = 8
                local roll = 6
                local acc = 1.2
                --roll = (max(left,right)/30 *3)+(down/100)*3+roll
				roll = (max(left,right)/30 * 7.5)
				lift = lift + (down - up) /400
				pitch = pitch + (down - up) /30
				--lift = lift + (down/100) - (up/100)
                local turn = chose_turn(self,left,right)
                if turn then
                    mobkit.clear_queue_low(self)
                    water_life.lq_fly_pitch(self,lift,pitch,roll*-1,acc,'fly')
                else 
                    mobkit.clear_queue_low(self)
                    water_life.lq_fly_pitch(self,lift,pitch,roll,acc,'fly')
                end
            end
		end
		if mobkit.timer(self,15) then mobkit.clear_queue_low(self) end
		if mobkit.is_queue_empty_low(self) then water_life.lq_fly_pitch(self,0.6,8,(random(2)-1.5)*30,1.2,'fly') end 
	end
	mobkit.queue_high(self,func,prty)
end

function water_life.hq_glide(self,prty,fmin,fmax)
	if not max then fmax = 30 end
	if not min then fmin = 20 end
	
	local func = function(self)
		if mobkit.timer(self,1) then
			self.action = "glide"
            local remember = mobkit.recall(self,"time")
            if remember then
                if self.time_total - remember > 15 then
                    mobkit.forget(self,"turn")
                    mobkit.forget(self,"time")
                    
                end
            end
			local pos = self.object:get_pos()
			local yaw = self.object:get_yaw()
            local left, right, up, down, under, above = water_life.radar(pos,yaw,32,true)
			if  (down > 10) or (under < fmin) then 
				water_life.hq_climb(self,prty,fmin,fmax)
				return true
			end
            if left > 3 or right > 3 then
				local lift = 0.6
                local pitch = 8
                local roll = 0
                local acc = 1.2
                --roll = (max(left,right)/30 *3)+(down/100)*3+roll
				roll = (max(left,right)/30 *7.5)
                local turn = chose_turn(self,left,right)
                if turn then
                    mobkit.clear_queue_low(self)
                    water_life.lq_fly_pitch(self,lift,pitch,roll*-1,acc,'glide')
                else 
                    mobkit.clear_queue_low(self)
                    water_life.lq_fly_pitch(self,lift,pitch,roll,acc,'glide')
                end
            end
		end	
	if mobkit.timer(self,20) then mobkit.clear_queue_low(self) end
	if mobkit.is_queue_empty_low(self) then water_life.lq_fly_pitch(self,0.6,-4,(random(2)-1.5)*30,0,'glide') end
	end
	mobkit.queue_high(self,func,prty)
end

