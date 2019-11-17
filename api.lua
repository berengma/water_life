 
local pi = math.pi


function water_life.handle_drops(self)
    if not self.drops then return end
    
    for _,item in ipairs(self.drops) do
        
        local amount = math.random (item.min, item.max)
        local chance = math.random(1,100) 
        local pos = self.object:get_pos()
        pos.x = pos.x + math.random(-1,1)
        pos.z = pos.z + math.random(-1,1)
        
        if chance < (100/item.chance) then
            minetest.add_item(pos, item.name.." "..tostring(amount))
        end
        
    end
end


function water_life.register_shark_food(name)
    table.insert(water_life.shark_food,name)
end


function water_life.feed_shark()
    local index = math.random(1,#water_life.shark_food)
    return water_life.shark_food[index]
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


-- returns angle from self to target in radians
function water_life.get_yaw_to_object(self,target)
    if not self or target then return nil end
    
    local pos = mobkit.get_stand_pos(self)
    local opos = target:get_pos()
    local ankat = pos.x - opos.x
    local gegkat = pos.z - opos.z
    local yaw = math.atan2(ankat, gegkat)
    
    return yaw
end

function water_life.hq_swimfrom(self,prty,tgtobj)
	
	local func = function(self)
	
		if not mobkit.is_alive(tgtobj) then return true end
        
		
			local pos = mobkit.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			local ankat = pos.x - opos.x
            local gegkat = pos.z - opos.z
            local yaw = math.atan2(ankat, gegkat) - math.pi   -- turn around from target direction
            local distance = vector.distance(pos,opos)
            
            if distance < self.view_range then
                
                local swimto, height = water_life.aqua_radar_dumb(pos,yaw,3)
                if height and height > pos.y then
                    local vel = self.object:get_velocity()
                    vel.y = vel.y+0.1
                    self.object:set_velocity(vel)
                end	
                mobkit.hq_aqua_turn(self,51,swimto,3)
                
            else
                return true
            end
                
            --minetest.chat_send_all("angel= "..dump(yaw).."  viewrange= "..dump(self.view_range).." distance= "..dump(vector.distance(pos,opos)))

        
		
	end
	mobkit.queue_high(self,func,prty)
end
