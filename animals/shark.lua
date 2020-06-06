
local abs = math.abs
local pi = math.pi
local floor = math.floor
local random = math.random
local sqrt = math.sqrt
local max = math.max
local min = math.min
local pow = math.pow
local sign = math.sign
local rad = math.rad




local function shark_brain(self)
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	
	if mobkit.timer(self,1) then
		
        local whale =  mobkit.get_closest_entity(self,"water_life:whale")
		local buoy = mobkit.get_closest_entity(self,"water_life:buoy")
		
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
		
		if buoy then
            local spos = self.object:get_pos()
            local wpos = buoy:get_pos()
            local distance =  math.floor(vector.distance(spos,wpos))
            if distance < 10 then
                local yaw = self.object:get_yaw()
                mobkit.clear_queue_high(self)
                mobkit.hq_aqua_turn(self,45,yaw+rad(30),5)
            end
        end
		
        local prty = mobkit.get_queue_priority(self)
		if prty < 20 then
			local target = mobkit.get_nearby_player(self)
			local aliveinwater = target and mobkit.is_alive(target) and mobkit.is_in_deep(target)
			local food = water_life.feed_shark(self)
			
			if target and mobkit.is_alive(target) and mobkit.is_in_deep(target) and target:get_attach() == nil then
				--mobkit.hq_aqua_attack(self,20,target,9)
				local ppos = target:get_pos()
				local tbuoy = water_life.count_objects(ppos,10,"water_life:buoy")
				local dist = water_life.dist2tgt(self,target)
				if dist > 3 and tbuoy.name == 0 then
					water_life.hq_water_attack(self,target,20,9)
				end
			end

			if food and mobkit.is_in_deep(food) and not aliveinwater then
								local dist = water_life.dist2tgt(self,food)
								if dist > 3 then
									mobkit.clear_queue_high(self)
									--mobkit.hq_aqua_attack(self,30,food,7)
									water_life.hq_water_attack(self,food,20,9)
								end
                        end
		end
	end
	if mobkit.is_queue_empty_high(self) then mobkit.hq_aqua_roam(self,10,5) end
end



minetest.register_entity("water_life:shark",{
											-- common props
	physical = true,
	stepheight = 0.1,				--EVIL!
	collide_with_objects = false,
	collisionbox = {-0.5, -0.3, -0.5, 0.5, 0.3, 0.5},
	visual = "mesh",
	mesh = "water_life_shark.b3d",
	textures = {"water_life_shark3tex.png"},
	visual_size = {x = 1.5, y = 1.5},
	static_save = false,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 0.98,					-- portion of hitbox submerged
	max_speed = 9,                        
	jump_height = 1.26,
	view_range = water_life.abo * 12,
--	lung_capacity = 0, 		-- seconds
	max_hp = 50,
	timeout=60,
	drops = {
		{name = "default:diamond", chance = 5, min = 1, max = 5,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 5,},
	},
	attack={range=0.8,damage_groups={fleshy=7}},
	--sounds = {
	--	attack='water_life_sharkattack',
	--	},
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
				--mobkit.hq_aqua_attack(self,20,puncher,6)				-- get revenge
				water_life.hq_water_attack(self,puncher,20,6)
			end
		end
	end,
})
