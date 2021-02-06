
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



------------------
-- LQ behaviors --
------------------
--[[
params:
lift: [number]
multiplier for lift. faster objects need less, slower need more. typical value: 0.6 for speeds around 4 m/s

pitch: [degrees]
angle between the longitudinal axis and horizontal plane. typical range: <-15.15>

aoa:
[degrees] angle of attack - the angle between the longitudinal axis and velocity vector.

roll: [degrees]
bank angle. positive is right, negative is left, this is how they turn. if set too large they'll loose height rapidly

acc: [number]
propulsion. use with positive pitch to make them fly level or climb, set it to 0 with slight negative pitch to make
them glide. typical value: around 1.0

anim: [string]
animation.
The example uses two simple high level behaviors to keep them between 18 and 24 nodes above ground, seems good already for ambient type flying creatures.
warning: never set_velocity when using these behaviors.
]]

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


function water_life.lq_jumpattack(self,height,target,extra)
	local phase=1		
	local timer=0.5
	local tgtbox = target:get_properties().collisionbox
	local func=function(self)
		local selfname = self.object:get_luaentity().name
		if not mobkit.is_alive(target) then return true end
		if self.isonground then
			if phase==1 then	-- collision bug workaround
				local vel = self.object:get_velocity()
				vel.y = -mobkit.gravity*sqrt(height*2/-mobkit.gravity)
				self.object:set_velocity(vel)
				mobkit.make_sound(self,'charge')
				phase=2
			else
				mobkit.lq_idle(self,0.3)
				return true
			end
		elseif phase==2 then
			local dir = minetest.yaw_to_dir(self.object:get_yaw())
			local vy = self.object:get_velocity().y
			dir=vector.multiply(dir,6)
			dir.y=vy
			self.object:set_velocity(dir)
			phase=3
		elseif phase==3 then	-- in air
			local tgtpos = target:get_pos()
			local pos = self.object:get_pos()
			-- calculate attack spot
			local yaw = self.object:get_yaw()
			local dir = minetest.yaw_to_dir(yaw)
			local apos = mobkit.pos_translate2d(pos,yaw,self.attack.range)

			if mobkit.is_pos_in_box(apos,tgtpos,tgtbox) then	--bite
				target:punch(self.object,1,self.attack)
				if selfname and target:is_player() then
					if selfname == "water_life:snake" then
						local meta = target:get_meta()
						local name = target:get_player_name()
						local join = meta:get_int("jointime")
						if not join or (os.time() - join) > water_life.newplayerbonus * 86400 then
							meta:set_int("snakepoison",1)
							water_life.change_hud(target,"poison")
						else
							local left = water_life.newplayerbonus - math.floor((os.time() - join)/86400*100)/100
							minetest.chat_send_player(target:get_player_name(),minetest.colorize('#fd4000',">>> A rattlesnake bit you. New player bonus of "..left..
							                                                                     " days left. Catch 3 snakes to craft antiserum"))
							meta:set_int("bitten",1)
							
							minetest.after(10,function()
								meta:set_int("bitten",0)
								end,meta)
						end
					end
				end
					-- bounce off
				local vy = self.object:get_velocity().y
				self.object:set_velocity({x=dir.x*-3,y=vy,z=dir.z*-3})	
					-- play attack sound if defined
				mobkit.make_sound(self,'attack')
				phase=4
			end
		end
	end
	mobkit.queue_low(self,func)
end     



------------------
-- HQ behaviors --
------------------


-- on land only, go to tgt and remove it
function water_life.hq_catch_drop(self,prty,tgt)
	
	local func = function(self)
	
	if self.isinliquid then return true end
		if not tgt then return true end
		if mobkit.is_queue_empty_low(self) then
			local pos = mobkit.get_stand_pos(self)
			local tpos = tgt:get_pos()
			if pos and tpos then 
				local dist = vector.distance(pos,tpos)
				if dist < 2 then 
					tgt:remove()
					return true
				else
					if pos.y +0.5 >= tpos.y then
						water_life.lq_dumbwalk(self,tpos,0.1)
					else
						water_life.lq_dumbjump(self,1)
					end
				end
			else
				return true
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end


function water_life.hq_aquaidle(self,prty,anim)
	local init = true
	if not anim then anim = 'def' end
	
	local func = function(self)
		if init then
			mobkit.animate(self,anim)
			self.object:set_velocity({x=0,y=0,z=0})
			init = false
		end
		
		if self.name == "water_life:alligator" then
			if random(100) < 5 then
				mobkit.animate(self,'roll')
			end
		end
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
function water_life.big_aqua_roam(self,prty,speed,anim)
	local tyaw = 0
	local init = true
	local prvscanpos = {x=0,y=0,z=0}
	local center = self.object:get_pos()
	if not anim then anim = 'def' end
	
	local func = function(self)
		if init then
			mobkit.animate(self,anim)
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


-- this is the same as mobkit's, but allows movement in shallow water
function water_life.hq_aqua_roam(self,prty,speed,anim)
	if not anim then anim = "def" end
	local tyaw = 0
	local init = true
	local prvscanpos = {x=0,y=0,z=0}
	local center = self.object:get_pos()
	local func = function(self)
		if init then
			mobkit.animate(self,anim)
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
			local meta = nil
			local poison = 0
			local pos = mobkit.get_stand_pos(self)
--			local tpos = tgtobj:get_pos()
			local tpos = mobkit.get_stand_pos(tgtobj)
			local dist = vector.distance(pos,tpos)
			if tgtobj:is_player() then
				meta = tgtobj:get_meta()
				poison = meta:get_int("snakepoison")
				noob = meta:get_int("bitten")
			end
			
			if dist > 3 or poison > 0 or noob > 0 then 
				return true
			else
				mobkit.lq_turn2pos(self,tpos)
				local height = tgtobj:is_player() and 0.35 or tgtobj:get_luaentity().height*0.6
				if tpos.y+height>pos.y then 
					mobkit.make_sound(self,"attack")
					water_life.lq_jumpattack(self,tpos.y+height-pos.y,tgtobj) 
				else
					mobkit.lq_dumbwalk(self,mobkit.pos_shift(tpos,{x=random()-0.5,z=random()-0.5}))
				end
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end


function water_life.hq_hunt(self,prty,tgtobj,lost,anim)
	if not lost then lost = self.view_range end
	if random(100) < 20 then mobkit.make_sound(self,"attack") end
	
	
	local func = function(self)
		if not mobkit.is_alive(tgtobj) then return true end
		if self.isinliquid then return true end
		if mobkit.is_queue_empty_low(self) and self.isonground then
			local pos = mobkit.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			local dist = vector.distance(pos,opos)
			local meta = nil
			local poison = 0
			local noob = 0
			
			if tgtobj:is_player() then
				meta = tgtobj:get_meta()
				poison = meta:get_int("snakepoison")
				noob = meta:get_int("bitten")
			end
			
			if poison > 0 or noob > 0 then return true end
			
			if mobkit.is_in_deep(tgtobj) then
				return true --water_life.hq_water_attack(self,tgtobj,prty+1,7)
			end
			if dist > lost or math.abs(pos.y - opos.y) > 5 then
				return true
			elseif dist > 3 then
				water_life.goto_next_waypoint(self,opos)
			else
				water_life.hq_attack(self,prty+1,tgtobj)					
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end

-- slowly roam on land, breaks are taken with max of 120 seconds
function water_life.hq_slow_roam(self,prty,idle)
	if not idle then idle = random(30,120) end
	
	local func=function(self)
		if self.isinliquid then return true end
		if mobkit.is_queue_empty_low(self) and self.isonground then
			local pos = mobkit.get_stand_pos(self)
			local neighbor = random(8)

			local height, tpos, liquidflag = mobkit.is_neighbor_node_reachable(self,neighbor)
			if height and not liquidflag then mobkit.dumbstep(self,height,tpos,0.1,idle) end
		end
	end
	mobkit.queue_high(self,func,prty)
end


--find any water nearby and go into it
function water_life.hq_go2water(self,prty,speed)
	local pos = mobkit.get_stand_pos(self)
	local target = minetest.find_node_near(pos, self.view_range, {"group:water"})
	--if target then water_life.temp_show(target,10,10) end
	if not speed then speed = 0.1 end
	
	local func=function(self)
		--minetest.chat_send_all(dump(vector.distance(pos,target)))
		if self.isinliquid or not target then return true end
		
		if mobkit.is_queue_empty_low(self) and self.isonground then
			pos = mobkit.get_stand_pos(self)
			local height = target.y - pos.y
			water_life.dumbstep(self,height,target,speed,0)
		end
	end
	mobkit.queue_high(self,func,prty)
end


-- looks for a landing point on shore under air. tgt is optional
-- and must be an object, so it will start searching yaw2tgt - 15 degrees
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



-- turn around 180degrees from tgtob and swim away until out of sight
function water_life.hq_swimfrom(self,prty,tgtobj,speed,outofsight)
		local init = true

        local func = function(self)
			if not outofsight then outofsight = self.view_range * 1.5 end
			if not mobkit.is_alive(tgtobj) then return true end

			
			local pos = mobkit.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			local yaw = water_life.get_yaw_to_object(self,tgtobj) + math.rad(random(-30,30))+math.rad(180)
			local distance = vector.distance(pos,opos)
			if self.isonground then return true end
			
			if init then 
			
				mobkit.animate(self,"swim")
				init=false
			
			end
			
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
					if endpos.y > pos.y+selfbox[5] then
						local vel = vector.add(self.object:get_velocity(),{x=0,y=0.5,z=0})
						self.object:set_velocity(vel)
					end
					if endpos.y < pos.y-selfbox[5]  then
						local vel = vector.add(self.object:get_velocity(),{x=0,y=-0.5,z=0})
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


--  hq flying behaviors

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
			
			--local tim = minetest.get_us_time()
			local left, right, up, down, under, above = water_life.radar(pos,yaw,32,true)
			--minetest.chat_send_all(minetest.get_us_time()-tim)
			
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


function water_life.hq_water_takeoff(self,prty,anim,tyaw)
	local init = true
	local startup = true
	local turned = false
	local timer = 0
	if not anim then anim = 'def' end
	local pos2 = {}
	
	
	local func=function(self)
	
		local yaw = self.object:get_yaw()
		local pos = self.object:get_pos()
		
		if startup then
			if tyaw then yaw = tyaw end
			--water_life.temp_show(pos,5,1)
			for i = 0,330,30 do
				pos2 = mobkit.pos_translate2d(pos,yaw+rad(i),self.view_range*2)
				
				if not water_life.find_collision(pos,pos2,false) then
					tyaw = yaw + rad(i)
					--water_life.temp_show(pos2,5,10)
					break
				end
			end
			startup = false
		end

		if not startup then
			if not tyaw then return true end
			if mobkit.turn2yaw(self,tyaw,5) then turned = true end
		end
		
		if turned then
			if init then
				self.object:set_velocity({x=0, y=0.5, z=0})
				minetest.after(2,function()
					mobkit.animate(self,anim)
				end)
				init = false
			end
			
			
			minetest.after(4,function()
				mobkit.animate(self,'fly')
			              end)
			
			if timer > 3 then
				self.object:add_velocity({x=0,y=0.25,z=0})
			end
			
			mobkit.go_forward_horizontal(self,3)
			timer = timer + self.dtime
			
			if timer > 8 then
				local vec = vector.multiply(minetest.yaw_to_dir(tyaw),2)
				vec.y = vec.y + 4
				self.object:add_velocity(vec)
				mobkit.remember(self,"airlife",os.time())
				mobkit.forget(self,"landlife")
				mobkit.forget(self,"waterlife")
				return true
			end
		end
	end
	
	mobkit.queue_high(self,func,prty)
end
	
	
function water_life.hq_fly2obj(self,prty,tgt,break_dist,force)
	
	local func=function(self)
			if not break_dist then break_dist = 5 end
			if not tgt then
				mobkit.clear_queue_high(self)
				water_life.hq_climb(self,prty)
				return true
			end
			
			local wname = ""
			local roll = 0
			local pos = self.object:get_pos()
			local yaw = self.object:get_yaw()
			local tgtpos = tgt:get_pos()
			if not tgtpos then return true end
			
			local tgtyaw = tgt:get_yaw() --water_life.get_yaw_to_object(self,tgt)
			local tgtspeed = math.floor(vector.length(tgt:get_velocity() or {x=0,y=0,z=0}))
			if not tgt:is_player() and tgt:get_luaentity() and tgt:get_luaentity().name == "water_life:whale" then tgtyaw = tgtyaw + rad(180) end -- whales moving backwards XD
			
			if tgt:is_player() then
				tgtyaw = tgt:get_look_horizontal()
				local stack = tgt:get_wielded_item()
				wname = stack:get_name()
			end
			
			
			if tgtpos.y < 0 then tgtpos.y = 1 end
			
			
			
			if not water_life.gull_bait[wname] and not force then
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
				water_life.hq_climb(self,15,4,16)
				return true
			end
			--minetest.chat_send_all(dump(tgtpos).." "..dump(tgtyaw).." "..dump(tgtspeed))
			if not tgtyaw or not tgtspeed or not mobkit.is_alive(tgt) or self.isonground or self.isinliquid then
				mobkit.clear_queue_high(self)
				water_life.hq_climb(self,prty)
				return true
			end
			local turn = 0
			local diff = 0
			local lift = 1.2
			local pitch = 5
			local acc = 0.6
			local anim = "fly"
			local truetpos=mobkit.pos_translate2d(tgtpos,tgtyaw,tgtspeed*3)
			local ddistance = vector.distance(pos,{x=truetpos.x,y= pos.y, z=truetpos.z})
			local alpha = atan((pos.y - truetpos.y)/ ddistance)
			local truetyaw = water_life.get_yaw_to_pos(self,truetpos)
			local realdistance = vector.distance(pos,tgtpos)
			local ang2tgt = mobkit.pos_translate2d(pos,truetyaw,15)
			
			--chose right or left turn
			if yaw < truetyaw then 
				turn = -1
			elseif yaw > truetyaw then
				turn = 1
			end
			
			diff = abs(truetyaw - yaw)
			
			-- or chose straight ahead
			if ddistance > 30 and diff <= 0.5 then
				turn = 0
			end
			if ddistance > 20 and diff <= 0.3 then
				turn = 0
			end
			if diff <= 0.1 then
				turn = 0
			end
			--minetest.chat_send_all(">>> "..dump(math.floor(diff*100)/100).." <<<")
			--minetest.chat_send_all("distance ="..dump(math.floor(ddistance*100)/100).."   yawdiff ="..dump(math.floor((truetyaw-yaw)*100)/100))
			
			if ddistance > 32 then
				roll = 15 * turn
			elseif ddistance > 22 then
				roll = 10 * turn
			elseif ddistance > 12 then
				roll = 5 * turn
			elseif ddistance <= 12 then
				roll = 2 * turn
			end
			
			--water_life.temp_show(truetpos,1,3)
			--minetest.chat_send_all(dump(minetest.pos_to_string(truetpos,2)).." -- "..dump(minetest.pos_to_string(pos,2)))
			
			if pos.y > truetpos.y + 1 and pos.y > 2 and ddistance < 25 then
				anim = "glide"
				pitch = -10
			elseif pos.y < truetpos.y - 1 then
				pitch = 15
			else
				pitch = 5
			end
			
			
			--tim = minetest.get_us_time()
			local left,right,center,up,down = water_life.radar_fast(self,20)
			--minetest.chat_send_all(minetest.get_us_time()-tim)
			
			if down and down < 16 then pitch = 15 end
			if up and not down and not center then pitch = -10 end
			if right and not center then roll = 10 end
			if left and not center then roll = -10 end
			if left and right and not center then roll = 0 end
			if center and down and center < 5 then
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
				water_life.hq_climb(self,15,4,16)
				return true
			end
			
			if water_life.radar_debug then
				water_life.temp_show(ang2tgt,1)
				for i = 1,10,1 do
					water_life.temp_show({x=truetpos.x, y=truetpos.y+i*2, z=truetpos.z},1)
				end
				--minetest.chat_send_all("Alpha= "..dump(alpha)..", Hight= "..dump(math.floor(pos.y)).." ###"..dump(yaw).."###   hityaw="..dump(truetyaw))
				--minetest.chat_send_all("distance ="..dump(math.floor(ddistance*100)/100).."   Alpha ="..dump(math.floor(deg(alpha)*100)/100))
				--minetest.chat_send_all("distance2prey ="..dump(vector.distance(pos,tgtpos)))
			end
               
				mobkit.clear_queue_low(self)
				
				
				if realdistance < break_dist+0.5 then 					-- steal bait from players
					-- minetest.chat_send_all(">>> "..dump(math.floor(ddistance*100)/100).."<<< ###"..dump(math.floor(realdistance*100)/100).." ###")
					if tgt:is_player() then
						local bstack = tgt:get_wielded_item()
						local bait  = bstack:get_name()
						if water_life.gull_bait[bait] then
							bstack:take_item(1)
							tgt:set_wielded_item(bstack)
						end
					end
					mobkit.clear_queue_high(self)
					mobkit.clear_queue_low(self)
					water_life.hq_climb(self,15,4,16)
					return true
					
				else
					water_life.lq_fly_pitch(self,lift,pitch,roll,acc,anim)
				end
				
				
		
	end
	mobkit.queue_high(self,func,prty)
end

--snakes
function water_life.hq_snake_warn(self,target,prty,duration,anim)
	anim = anim or 'warn'
	local init = true
	
	local func=function(self)
		if init then 
			mobkit.make_sound(self,"warn")
			minetest.after(1,function(anim)
				mobkit.animate(self,anim)
			end,anim)
			init=false
		end
		local yaw = water_life.get_yaw_to_object(self,target)
		self.object:set_yaw(yaw)
		duration = duration-self.dtime
		local dist = water_life.dist2tgt(self,target)
		if  dist > self.view_range then
			minetest.after(3,function()
				return true
			end)
		end
		if duration <= 0 or dist < 4 then
			mobkit.remember(self,"warned",target:get_player_name())
			return true
		end
	end
	mobkit.queue_high(self,func,prty)
end



function water_life.hq_snake_move(self,prty,anim)
	anim = anim or 'look'
	local init = true
	local getpos = nil
	
	local func=function(self)
		local getpos = nil
		local pos = mobkit.get_stand_pos(self) --self.object:get_pos()
		local yaw = 0
		
		if init then 
			mobkit.animate(self,anim)
			init=false
			yaw = rad(random(360))
			pos = mobkit.pos_translate2d(pos,yaw,self.view_range+5)
			getpos = water_life.find_node_under_air(pos,self.view_range)
			--water_life.temp_show(getpos,5,5)
			              
		end
		
		
		if getpos then
			
			water_life.hq_idle(self,prty+2,5,anim)
			water_life.hq_findpath(self,prty+1,getpos, 1.5,0.1,true)
			return true
			
			
		else
			return true
			
			
		end
		
		
	end
	mobkit.queue_high(self,func,prty)
end


function water_life.hq_snakerun(self,prty,tgtobj)
	local init=true
	local timer=6
	local func = function(self)
	
		if not mobkit.is_alive(tgtobj) then return true end
		if self.isinliquid then return true end
		
		if init then
			timer = timer-self.dtime
			if timer <=0 or vector.distance(self.object:get_pos(),tgtobj:get_pos()) < 8 then
				mobkit.make_sound(self,'scared')
				init=false
			end
			return
		end
		
		if mobkit.is_queue_empty_low(self) and self.isonground then
			local pos = mobkit.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			if vector.distance(pos,opos) < (self.view_range*3) then
				--minetest.chat_send_all(dump(vector.distance(pos,opos)).."  "..dump(self.view_range*3))
				local tpos = {x=2*pos.x - opos.x,
								y=opos.y,
								z=2*pos.z - opos.z}
				water_life.goto_next_waypoint(self,tpos)
			else
				mobkit.clear_queue_low(self)
				mobkit.clear_queue_high(self)
				--water_life.hq_idle(self,10,random(60,120),"sleep")
				water_life.hq_snake_move(self,15)
				return true
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end


function water_life.hq_runfrom(self,prty,tgtobj)
	local init=true
	local timer=6
	local func = function(self)
	
		if self.isinliquid then return true end
		if not mobkit.is_alive(tgtobj) then return true end
		--[[if init then
			timer = timer-self.dtime
			if timer <=0 or vector.distance(self.object:get_pos(),tgtobj:get_pos()) < 8 then
				mobkit.make_sound(self,'scared')
				init=false
			end
			return
		end]]
		
		if mobkit.is_queue_empty_low(self) and self.isonground then
			local pos = mobkit.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			if vector.distance(pos,opos) < self.view_range*1.1 then
				local tpos = {x=2*pos.x - opos.x,
								y=opos.y,
								z=2*pos.z - opos.z}
				mobkit.goto_next_waypoint(self,tpos)
			else
				self.object:set_velocity({x=0,y=0,z=0})
				return true
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end


-- dying
function water_life.hq_die(self,anim)
	local timer = 5
	local start = true
	local func = function(self)
		if start then 
			
			if not anim then
				mobkit.lq_fallover(self)
			else
				mobkit.animate(self,anim)
			end
			self.logic = function(self) end	-- brain dead as well
			start=false
		end
		timer = timer-self.dtime
		if timer < 0 then self.object:remove() end
	end
	mobkit.queue_high(self,func,100)
end
