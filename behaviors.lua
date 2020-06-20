
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


------------------
-- LQ behaviors --
------------------


function water_life.lq_dumbjump(self,height,anim)
	anim = anim or 'stand'
	local jump = true
	local func=function(self)
	local yaw = self.object:get_yaw()
		
			if jump then
				mobkit.animate(self,anim)
				local dir = minetest.yaw_to_dir(yaw)
				dir.y = -mobkit.gravity*sqrt((height+0.35)*2/-mobkit.gravity)
				self.object:set_velocity(dir)
				jump = false
			else				-- the eagle has landed
				return true
			end
		
		
	end
	mobkit.queue_low(self,func)
end


function water_life.lq_dumbwalk(self,dest,speed_factor)
	local timer = 3			-- failsafe
	speed_factor = speed_factor or 1
	local func=function(self)
		mobkit.animate(self,'walk')
		timer = timer - self.dtime
		if timer < 0 then return true end
		
		local pos = mobkit.get_stand_pos(self)
		local y = self.object:get_velocity().y
		local dir = vector.normalize(vector.direction({x=pos.x,y=0,z=pos.z},
											{x=dest.x,y=0,z=dest.z}))
		dir = vector.multiply(dir,self.max_speed*speed_factor)
		mobkit.turn2yaw(self,minetest.dir_to_yaw(dir))
		dir.y = y
		self.object:set_velocity(dir)

	end
	mobkit.queue_low(self,func)
end




------------------
-- HQ behaviors --
------------------



function water_life.hq_catch_drop(self,prty,tgt)
	
	local func = function(self)
	
	if self.isinliquid then return true end
		if not tgt then return true end
		if mobkit.is_queue_empty_low(self) then
			local pos = mobkit.get_stand_pos(self)
			local tpos = tgt:get_pos()
			local dist = vector.distance(pos,tpos)
			if dist < 2 then 
				tgt:remove()
				return true
			else
				water_life.lq_dumbwalk(self,tpos,0.1)
			end
		end
	end
	mobkit.queue_high(self,func,prty)
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



function water_life.hq_aqua_roam(self,prty,speed) -- this is the same as mobkit's, but allows movement in shallow water
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
			local nyaw,height = water_life.aqua_radar_dumb(pos,yaw,speed,true,true)
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
		if mobkit.timer(self,1) then
			if vector.distance(pos,center) > water_life.abr*16*0.5 then
				tyaw = minetest.dir_to_yaw(vector.direction(pos,{x=center.x+random()*10-5,y=center.y,z=center.z+random()*10-5}))
			else
				if random(10)>=9 then tyaw=tyaw+random()*pi - pi*0.5 end
			end
		end
		
		mobkit.turn2yaw(self,tyaw,3)
--		local yaw = self.object:get_yaw()
		mobkit.go_forward_horizontal(self,speed)
	end
	mobkit.queue_high(self,func,prty)
end


function water_life.hq_attack(self,prty,tgtobj)
	local func = function(self)
		if self.isinliquid then return true end
		if not mobkit.is_alive(tgtobj) then return true end
		if mobkit.is_queue_empty_low(self) then
			local pos = mobkit.get_stand_pos(self)
--			local tpos = tgtobj:get_pos()
			local tpos = mobkit.get_stand_pos(tgtobj)
			local dist = vector.distance(pos,tpos)
			if dist > 3 then 
				return true
			else
				mobkit.lq_turn2pos(self,tpos)
				local height = tgtobj:is_player() and 0.35 or tgtobj:get_luaentity().height*0.6
				if tpos.y+height>pos.y then 
					mobkit.lq_jumpattack(self,tpos.y+height-pos.y,tgtobj) 
				else
					mobkit.lq_dumbwalk(self,mobkit.pos_shift(tpos,{x=random()-0.5,z=random()-0.5}))
				end
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end


function water_life.hq_hunt(self,prty,tgtobj,lost)
	if not lost then lost = self.view_range end
	
	local func = function(self)
		if not mobkit.is_alive(tgtobj) then return true end
		if self.isinliquid then return true end
		if mobkit.is_queue_empty_low(self) and self.isonground then
			local pos = mobkit.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			local dist = vector.distance(pos,opos)
			if mobkit.is_in_deep(tgtobj) then
				return true --water_life.hq_water_attack(self,tgtobj,prty+1,7)
			end
			if dist > lost or math.abs(pos.y - opos.y) > 5 then
				return true
			elseif dist > 3 then
				mobkit.goto_next_waypoint(self,opos)
			else
				water_life.hq_attack(self,prty+1,tgtobj)					
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end

function water_life.hq_slow_roam(self,prty)
	local func=function(self)
		if self.isinliquid then return true end
		if mobkit.is_queue_empty_low(self) and self.isonground then
			local pos = mobkit.get_stand_pos(self)
			local neighbor = random(8)

			local height, tpos, liquidflag = mobkit.is_neighbor_node_reachable(self,neighbor)
			if height and not liquidflag then mobkit.dumbstep(self,height,tpos,0.1,random(120)) end
		end
	end
	mobkit.queue_high(self,func,prty)
end

function water_life.hq_go2water(self,prty)
	local pos = mobkit.get_stand_pos(self)
	local target = minetest.find_node_near(pos, self.view_range, {"group:water"})
	--if target then water_life.temp_show(target,10,10) end
	
	local func=function(self)
		--minetest.chat_send_all(dump(vector.distance(pos,target)))
		if self.isinliquid or not target then return true end
		if mobkit.is_queue_empty_low(self) and self.isonground then
			pos = mobkit.get_stand_pos(self)
			local height = target.y - pos.y
			water_life.dumbstep(self,height,target,0.1,5)
		end
	end
	mobkit.queue_high(self,func,prty)
end

function water_life.hq_go2land(self,prty,tgt) 
	local init = false
	local offset = 1
	local target = nil
	local start = 1
	if tgt then
		local ayaw = water_life.get_yaw_to_object(self,tgt)
		if ayaw then start = math.deg(ayaw) -15 end
	end
	
	local func = function(self)
		
		
		local fpos = nil
		local pos = mobkit.get_stand_pos(self)
		
		if not init then
			
			for i = start,359,15 do
				local yaw = rad(i)
				target = mobkit.pos_translate2d(pos,yaw,self.view_range)
				fpos = water_life.find_collision(pos,target,false)
				if fpos then
					target = mobkit.pos_translate2d(pos,yaw,fpos+0.5)
					local node=minetest.get_node({x=target.x,y=target.y+1,z=target.z})
					 
					 if node.name == "air" then
						--water_life.temp_show(target,5,2)
						break
					 else
						 target = nil
					 end
				else
					target = nil
				end
			end
			init = true
		end
		
		if self.isonground then return true end
		
		if target then
			local y=self.object:get_velocity().y
			local pos2d = {x=pos.x,y=0,z=pos.z}
			local dir=vector.normalize(vector.direction(pos2d,target))
			local yaw = minetest.dir_to_yaw(dir)
			
			if mobkit.timer(self,1) then
				local pos1 = mobkit.pos_shift(mobkit.pos_shift(pos,{x=-dir.z*offset,z=dir.x*offset}),dir)
				local h,l = mobkit.get_terrain_height(pos1)
				if h and h>pos.y then
					mobkit.lq_freejump(self)
				else 
					local pos2 = mobkit.pos_shift(mobkit.pos_shift(pos,{x=dir.z*offset,z=-dir.x*offset}),dir)
					local h,l = mobkit.get_terrain_height(pos2)
					if h and h>pos.y then
						mobkit.lq_freejump(self)
					end
				end
			elseif mobkit.turn2yaw(self,yaw) then
				dir.y = y
				self.object:set_velocity(dir)
			end
		else
			return true
		end
            --minetest.chat_send_all("angel= "..dump(yaw).."  viewrange= "..dump(self.view_range).." distance= "..dump(vector.distance(pos,opos)))

        
		
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
		
		if mobkit.timer(self,1) then
			if vector.distance(pos,endpos) > 1 then
						
						--minetest.chat_send_all(vector.distance(pos,endpos))
						if endpos.y > pos.y  then
							local vel = self.object:get_velocity()
							vel.y = vel.y+0.4
							self.object:set_velocity(vel)
						end	
						if endpos.y < pos.y then
							local vel = self.object:get_velocity()
							vel.y = vel.y-0.1
							self.object:set_velocity(vel)
						end
						mobkit.hq_aqua_turn(self,prty+5,yaw,speed)
						pos = self.object:get_pos() --mobkit.get_stand_pos(self)
						yaw = water_life.get_yaw_to_pos(self,endpos)
					
			else			
				return true
			end
		end
    
end
	mobkit.queue_high(self,func,prty)
    
end


function water_life.hq_water_attack(self,tgtobj,prty,speed,shallow)
	
	local pos = self.object:get_pos()
	local selfbox = self.object:get_properties().collisionbox
	local tgtbox = tgtobj:get_properties().collisionbox
	if not speed then speed = 1 end
    
	local func = function(self)
    
		if not mobkit.is_alive(self) or not mobkit.is_alive(tgtobj) or tgtobj:get_attach() ~= nil then return true end
		local pos = self.object:get_pos()
		local endpos = tgtobj:get_pos()
		if not shallow then
			if not mobkit.is_in_deep(tgtobj) and vector.distance (pos,endpos) > 2 then return true end
		else
			if not water_life.isinliquid(tgtobj) and vector.distance (pos,endpos) > 2 then return true end
		end
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


