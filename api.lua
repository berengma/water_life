
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
	
water_life.randomtable = PcgRandom(math.random(2^23)+1)

function water_life.random(min,max)
	if not min and not max then return math.abs(water_life.randomtable:next() / 2^31) end
	if not max then
		max = min
		min = 1
	end
	if max and not min then min = 1 end
	if max < min then return water_life.randomtable:next(max,min) end
	return water_life.randomtable:next(min,max)
end

--
local random = water_life.random -- do not delete, this MUST be here!
--

--checks if entity is in a small water pool
function water_life.check_for_pool(self,deep,minr,pos)
	if not self and not pos then return nil end
	if not deep then deep = 3 end
	if not minr then minr = 3 end
	local max = 16
	if not pos then
		pos = self.object:get_pos()
	end
	local d,t,s = water_life.water_depth(pos,max)
	if not d then return nil end
	local cpos = {}
	local ispool = 0
	for i = 0,270,90 do
		cpos = mobkit.pos_translate2d(pos,rad(i),minr)
		if water_life.find_collision(pos,cpos,false) then ispool = ispool + 1 end
	end
	if ispool > 2 and d < deep then return true end
	return false
end


-- returns ingame time, 1 = morning, 2 = noon, 3 = afternoon, 4 = night
function water_life.get_game_time()
	local time = minetest.get_timeofday()
	local hour = math.floor(time*24)
	if hour >= 5 and hour < 10 then return 1 end
	if hour >= 10 and hour < 15 then return 2 end
	if hour >= 15 and hour < 20 then return 3 end
	if hour > 20 or hour < 5 then return 4 end
end

--compatibility function
function water_life_get_biome_data(pos)
	return water_life.get_biome_data(pos)
end

function water_life.get_biome_data(pos)
	if not pos then return nil end
	local table = minetest.get_biome_data(pos)
	if not table then return nil end
	local biome = {}
	biome.id = table.biome
	biome.name = minetest.get_biome_name(table.biome)
	biome.temp = math.floor((table.heat-32)*5/9)	--turn fahrenheit into celsius
	biome.humid = math.floor(table.humidity*100)/100
	return biome
end

-- get list of biome names
function water_life.get_biomes()
	local biomes = {}
	for k,v in pairs(minetest.registered_biomes) do
		table.insert(biomes, k)
	end
	if #biomes > 0 then return biomes else return nil end
end

-- returns closest enemy or player, if player is true
-- enemies must be in entity definition: predators = {[name1]=1,[name2]=1,.....}
function water_life.get_closest_enemy(self,player)	
	local cobj = nil
	local dist = water_life.abo * 16
	local pos = self.object:get_pos()
	local otable = minetest.get_objects_inside_radius(pos, self.view_range)
	if not self.predators and not player then return nil end
	for _,obj in ipairs(otable) do
		local luaent = obj:get_luaentity()
		local opos = obj:get_pos()
		local odist = abs(opos.x-pos.x) + abs(opos.z-pos.z)
		if mobkit.is_alive(obj) and not obj:is_player() and luaent and
				self.predators[luaent.name] then
			if odist < dist then
				dist=odist
				cobj=obj
			end
		elseif mobkit.is_alive(obj) and obj:is_player() and player then
			if odist < dist then
				dist=odist
				cobj=obj
			end
		end
	end
	return cobj
end

--player knockback from entity
function water_life.knockback_player(self,target,force)
	if not target:is_player() then return end
	if not self.object then return end
	if not force then force = 10 end
	local dir = minetest.yaw_to_dir(self.object:get_yaw())
	dir = vector.multiply(dir, force)
	dir = {x=dir.x, y=dir.y+force/2, z= dir.z}
	target:add_player_velocity(dir)
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
		if obj then
			minetest.after(time, function(obj) obj:remove() end, obj)
		end
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
	if (not tgt or not self) then
		return 100
	else
		return vector.distance(pos,tpos)
	end
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

function water_life.no_spawn_of(mobname)
	if not mobname then
		return
	end
	table.insert(water_life.no_spawn_table, mobname)
end

function water_life.register_shark_food(name)
	if not name then
		return
	end
    table.insert(water_life.shark_food, name)
end

function water_life.register_gull_bait(name)
    if not name then 
		return
	end
	water_life.gull_bait[name] = 1
end

function water_life.feed_shark(self)
	for i = 1,#water_life.shark_food,1 do
		if water_life.shark_food[i] ~= "water_life:fish" and
			water_life.shark_food[i] ~= "water_life:fish_tamed" then
				local target = mobkit.get_closest_entity(self,water_life.shark_food[i])
				if target then
					return target
				end
		end
	end
	return nil
end

function water_life.get_close_drops(self,name)
	local objs = minetest.get_objects_inside_radius(self.object:get_pos(), self.view_range)
	if #objs < 1 then return nil end
	for i = #objs,1,-1 do
		local entity = objs[i]:get_luaentity()
		if not entity or entity.name ~= "__builtin:item" then
			table.remove(objs,i)
		end
	end
	if #objs < 1 then return nil end
	if not name then return objs[random(#objs)] end
	for i=#objs,1,-1 do
		local entity = objs[i]:get_luaentity()
		if not entity.itemstring then 
			table.remove(objs,i)
		else
			if not string.match(entity.itemstring,name) then
				table.remove(objs,i)
			end
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
	if not minetest.registered_nodes[node.name] then return nil end
	local type = minetest.registered_nodes[node.name]["liquidtype"]
	if type == "none" then return nil end
	return true
end

function water_life.aqua_radar_dumb(pos,yaw,range,reverse,shallow)
	range = range or 4
	local function okpos(p)
		local node = mobkit.nodeatpos(p)
		if node then 
			if node.drawtype == 'liquid' then 
				local nodeu = mobkit.nodeatpos(mobkit.pos_shift(p,{y=1}))
				local noded = mobkit.nodeatpos(mobkit.pos_shift(p,{y=-1}))
				if ((nodeu and nodeu.drawtype == 'liquid') or (noded and
					noded.drawtype == 'liquid')) or shallow then
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

-- counts animals in specified radius or active_block_range, returns a table containing numbers
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
	elseif entity and (entity.name == "water_life:fish" or
		entity.name == "water_life:fish_tamed") then
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
	if not self or not target then return 0 end
	local pos = mobkit.get_stand_pos(self)
	local tpos = target:get_pos()
	local tyaw = 0
	if pos and tpos then
		tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos))
	end
    return tyaw
end

-- returns 2D angle from self to pos in radians
function water_life.get_yaw_to_pos(self,tpos)
	if not self then return 0 end
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
	if node1 and node1.drawtype=='liquid' or (node2 and node2.drawtype=='liquid' and node1
		and node1.drawtype=='airlike') then
			return true
	end
end

-- find if there is a node between pos1 and pos2
-- water = true means water = obstacle
-- returns distance to obstacle in nodes or nil
function water_life.find_collision(pos1,pos2,water,objects)
	local ray = minetest.raycast(pos1, pos2, objects, water)
	for pointed_thing in ray do
		if pointed_thing.type == "node" then
			local dist = math.floor(vector.distance(pos1,pointed_thing.under))
			return dist
		end
	end
	return nil
end

-- fast radar, less accurate
-- yaw-x to the right, yaw + x to the left !
-- sonar = true water is no obstacle
function water_life.radar_fast(self,dist,sonar)
	local water = not sonar 
	if not dist then dist = self.view_range end
	local angel = atan(3/dist)
	local yaw = self.object:get_yaw()
	local tpos = self.object:get_pos()
	local tapos = mobkit.pos_translate2d(tpos,(yaw-angel),dist)
	local tbpos = mobkit.pos_translate2d(tpos,yaw,dist)
	local tcpos = mobkit.pos_translate2d(tpos,(yaw+angel),dist)
	local tupos = mobkit.pos_shift(tbpos,{y=2})
	local tdpos = mobkit.pos_shift(tbpos,{y=-2})
	local right = water_life.find_collision(tpos,tapos,water)
	local left  = water_life.find_collision(tpos,tcpos,water)
	local center = water_life.find_collision(tpos,tbpos,water)
	local up = water_life.find_collision(tpos,tupos,water)
	local down = water_life.find_collision(tpos,tdpos,water)
	return left,right,center,up,down
end

-- WIP radar, not ready to use 
--sonar = true, water no obstacle  :: rev = true array contains possible positions
function water_life.radar_fast_cols(obj,dist,sonar,rev)
	if not dist then dist = 3 end
	local pos = obj:get_pos()
	local yaw = 0
	local box = {}
	local counter = 1
	local rarray = {}
	if obj:is_player() then
		yaw = obj:get_look_horizontal()
		box = obj:get_properties().collisionbox
	else
		yaw = obj:get_yaw()
		if obj:get_luaentity().name == "water_life:whale" then yaw = yaw + rad(180) end
		box = obj:get_luaentity().collisionbox
	end
	local vec = minetest.yaw_to_dir(yaw)
	local crasha = mobkit.get_box_displace_cols(pos,box,vec,dist)
	if crasha then
		for i = #crasha,1,-1 do
			for j = #crasha[i],1,-1 do
				local cpos ={x=crasha[i][j].x, y= pos.y, z= crasha[i][j].z}
				local node = minetest.get_node(cpos)
				if minetest.registered_nodes[node.name] then
					local kill = false
					if minetest.registered_nodes[node.name]["drawtype"] == "airlike" then
						kill = true
					end
					if minetest.registered_nodes[node.name]["buildable_to"] then
						kill = true
					end
					if minetest.registered_nodes[node.name]["drawtype"] == "liquid" then
							kill = sonar
					end
					if kill then
						if not rev then
							table.remove(crasha[i],j)
						else
							rarray[counter] = cpos
							counter = counter +1
						end
					else 
						if not rev then
							rarray[counter] = cpos
							counter = counter +1
						else
							table.remove(crasha[i],j)
						end
					end
				end
			end
			
		end
	end
	return rarray
end

-- radar function for obstacles lying in front of an entity 
-- use water = true if water should be an obstacle
function water_life.radar(pos, yaw, radius, water,fast)
	local function is_airlike(pos)
		local node = nil
		node = mobkit.nodeatpos(pos)
		if node and node.drawtype == "airlike" then
			return true
		end
		return false
	end

    if not radius or radius < 1 then
		radius = 16
	end
    local left = 0
    local right = 0
    local up =0
    local down = 0
	local node = nil
    if not water then
		water = false
	end
	local ignore = water_life.random(3)
    for j = 0,3,1 do
        for i = 0,4,1 do
            local pos2 = mobkit.pos_translate2d(pos,yaw+(i*pi/16),radius)
            local pos3 = mobkit.pos_translate2d(pos,yaw-(i*pi/16),radius)
			-- in case of sonar and limited world size, we have to take
			-- care of ignore nodes because they are not recognized by
			-- the raycast object if water is set to false
			if not water and i == ignore then
				if is_airlike(pos2) then
					left = left + 10
				else 
					if is_airlike(pos3) then
						right = right + 10
					end
				end
			end
            if water_life.find_collision(pos,{x=pos2.x, y=pos2.y + j*2, z=pos2.z}, water) then
                left = left + 5 - i
            end
            if water_life.find_collision(pos,{x=pos3.x, y=pos3.y + j*2, z=pos3.z},water) then
                right = right + 5 - i
            end
        end
    end
    if not fast then
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
    end
    local under = water_life.find_collision(pos,{x=pos.x, y=pos.y - radius, z=pos.z}, water)
    if not under then under = radius end
    local above = water_life.find_collision(pos,{x=pos.x, y=pos.y + radius, z=pos.z}, water)
    if not above then above = radius end
    return left, right, up, down, under, above
end


--find a spawn position under air
function water_life.find_node_under_air(pos,radius,name)
	if not pos then return nil end
	if not radius then radius = 3 end
	if not name then name={"group:crumbly","group:stone","group:tree"} end
	local pos1 = {x=pos.x-radius, y=pos.y-radius, z=pos.z-radius}
	local pos2 = {x=pos.x+radius, y=pos.y+radius, z=pos.z+radius}
	local spawner = minetest.find_nodes_in_area_under_air(pos1, pos2, name)
	if not spawner or #spawner < 1 then
		return nil
	else
		local rpos = spawner[random(#spawner)]
		rpos = mobkit.pos_shift(rpos,{y=1})
		return rpos
	end
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
	if not minetest.registered_nodes[node.name] then return nil end
	local type = minetest.registered_nodes[node.name]["liquidtype"]
	local found = false
	if type == "none" then
		local under = water_life.find_collision(pos,{x=pos.x, y=pos.y - max, z=pos.z}, true)
		if under then
			local check = {x=pos.x, y=pos.y - under-1, z=pos.z}
			local cname = minetest.get_node(check).name
			if not minetest.registered_nodes[cname] then return nil end
			if minetest.registered_nodes[cname]["liquidtype"] == "source" then
				surface = check
				found = true
			end
		end
		if not found then
			return nil
		end
	else
		local lastpos = pos
		for i = 1,max,1 do
			tempos = {x=pos.x, y=pos.y+i, z= pos.z}
			node = minetest.get_node(tempos)
			if not minetest.registered_nodes[node.name] then return nil end
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
			height, pos2, liq = mobkit.is_neighbor_node_reachable(
				self,mobkit.neighbor_shift(neighbor,-i))
			if height then return height,pos2 end
			height, pos2, liq = mobkit.is_neighbor_node_reachable(
				self,mobkit.neighbor_shift(neighbor,i))
			if height then return height,pos2 end
		end
	end
end

function water_life.getLandPos(self, start)
	local target = nil
	local fpos = nil
	local pos = mobkit.get_stand_pos(self)

	for i = start,359,15 do
		local yaw = rad(i)
		target = mobkit.pos_translate2d(pos,yaw,self.view_range)
		fpos = water_life.find_collision(pos,target,false)
		if fpos then
			target = mobkit.pos_translate2d(pos,yaw,fpos+0.5)
			local node=minetest.get_node({x=target.x,y=target.y+1,
				z=target.z})
			 if node.name == "air" then
				return target	
			 else
				 target = nil
			 end
		else
			target = nil
		end
	end
	return target
end

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
			local height, pos2, liq = mobkit.is_neighbor_node_reachable(
				self,mobkit.neighbor_shift(neighbor,-i*self.path_dir))
			if height and not liq 
			and not (nogopos and mobkit.isnear2d(pos2,nogopos,0.1)) then
				update_pos_history(self,pos2)
				return height,pos2 
			end			
			height, pos2, liq = mobkit.is_neighbor_node_reachable(
				self,mobkit.neighbor_shift(neighbor,i*self.path_dir))
			if height and not liq 
			and not (nogopos and mobkit.isnear2d(pos2,nogopos,0.1)) then
				update_pos_history(self,pos2)
				return height,pos2 
			end
		end
		height, pos2, liquidflag = mobkit.is_neighbor_node_reachable(
			self,mobkit.neighbor_shift(neighbor,4))
		if height and not liquidflag 
		and not (nogopos and mobkit.isnear2d(pos2,nogopos,0.1)) then
			update_pos_history(self,pos2)
			return height,pos2 
		end
	end
	table.remove(self.pos_history,2)
	self.path_dir = self.path_dir*-1
end

-- blood effects
function water_life.spilltheblood(object,size)
	if not water_life.bloody then return end
	if not size then size = 1 end
	local particlespawner_id = minetest.add_particlespawner({
				amount = 50,
				time = 1,
				minpos = vector.new(-0.3, size/2, -0.3),
				maxpos = vector.new( 0.3,   size,  0.3),
				minvel = {x = -1, y = 0, z = -1},
				maxvel = {x =  1, y = 1, z =  1},
				minacc = {x =  0, y = 2, z =  0},
				maxacc = {x =  0, y = 3, z =  0},
				minexptime = 0.5,
				maxexptime = 1,
				minsize = 1,
				maxsize = 2,
				texture = "water_life_bloodeffect1.png",
				collisiondetection = true,
				collision_removal = true,
				object_collision = true,
				attached = object,
			})
end


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

--check here for antiserum group of eaten food
minetest.register_on_item_eat(function(hp_change, replace_with_item, itemstack, user, pointed_thing)
	if not user or not user:is_player() then return end
	if not itemstack then return end
	local name = user:get_player_name()
	local antiserum = itemstack:get_definition().groups.antiserum
	if antiserum then
		local meta = user:get_meta()
		local score = user:get_hp()
		if meta:get_int("snakepoison") > 0 then meta:set_int("snakepoison",0) end
		water_life.change_hud(user,"poison",0)
	end
	return
end)

--new players are immune to snakepoison
minetest.register_on_newplayer(function(player)
	if not player or not player:is_player() then return end
	local meta = player:get_meta()
	local join = os.time()
	meta:set_int("jointime",join)
end)

-- but not forever
minetest.register_on_joinplayer(function(player)
	if not player or not player:is_player() then return end
	local meta = player:get_meta()
	meta:set_int("bitten",0)
	meta:set_int("repellant",0)
end)
