local random = water_life.random
local abs = math.abs
local pi = math.pi
local floor = math.floor
local sqrt = math.sqrt
local max = math.max
local min = math.min
local pow = math.pow
local sign = math.sign
local rad = math.rad





local function beaver_brain(self)
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	
	if mobkit.timer(self,5) then
		
		local land = mobkit.recall(self,"landlife")
		local water = mobkit.recall(self,"waterlife")
		
		if land then
			land = math.floor(os.clock()-land)
			if random(500) < land then
				--minetest.chat_send_all("Go to water")
				--mobkit.clear_queue_high(self)
				water_life.hq_go2water(self,25)
				
			end
		end
		
		if water then
			water = math.floor(os.clock()-water)
			if random (500) < water then
				--minetest.chat_send_all("Go to land")
				--mobkit.clear_queue_high(self)
				water_life.hq_go2land(self,25)
			end
		end
		
		--minetest.chat_send_all("Land: "..dump(land).." :  Water: "..dump(water))
	end
	
	if mobkit.timer(self,1) then
		local target = mobkit.get_nearby_player(self)
		local spos = mobkit.get_stand_pos(self)
		local dist = nil
		local prty = mobkit.get_queue_priority(self)
		
		if target and spos then
			dist = math.floor(vector.distance(spos,target:get_pos())*100)/100
		end
		
		--minetest.chat_send_all(dump(dist).." : "..dump(self.isonground).." : "..dump(self.isinliquid).." : "..dump(prty))
		
		if not mobkit.recall(self,"landlife") and not mobkit.recall(self,"waterlife") then
			mobkit.remember(self,"waterlife",os.clock())
		end
			
		if self.isinliquid then
			if mobkit.recall(self,"landlife") then
				mobkit.remember(self,"waterlife",os.clock())
				mobkit.forget(self,"landlife")
			end
			
			-- run if player nearby
			if dist and dist < 7 and prty < 30 then
				water_life.hq_swimfrom(self,30,target,3)
			end
		end
		
		if self.isonground then
			if mobkit.recall(self,"waterlife") then
				mobkit.remember(self,"landlife",os.clock())
				mobkit.forget(self,"waterlife")
			end
			
			-- run if player nearby, when possible to water first
			if dist and dist < 7 and prty < 30 then
				
				water_life.hq_go2water(self,31,1)
				water_life.hq_runfrom(self,30,target)
			end
		end
			
		
		
		if prty < 20 then 
			
			
			
			if self.isinliquid then
				water_life.hq_aqua_roam(self,21,1,"swim")
			end
			
			if self.isonground then
				water_life.hq_slow_roam(self,21,30)
			end
					
		end
	end
		
	if mobkit.is_queue_empty_high(self) then
		if self.isinliquid then water_life.hq_aqua_roam(self,10,1,"swim") end
		if self.isonground then  water_life.hq_slow_roam(self,10) end
	end
		
		
		
end



minetest.register_entity("water_life:beaver",{
											-- common props
	physical = true,
	stepheight = 0.1,				--EVIL!
	collide_with_objects = true,
	collisionbox = {-0.2, 0, -0.2, 0.2, 0.2, 0.2},
	visual = "mesh",
	mesh = "water_life_beaver.b3d",
	textures = {"water_life_beaver.png"},
	visual_size = {x = 0.2, y = 0.2},
	static_save = false,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 0.98,					-- portion of hitbox submerged
	max_speed = 4,                        
	jump_height = 1.26,
	view_range = 8,
--	lung_capacity = 0, 		-- seconds
	max_hp = 25,
	--timeout=300,
	drops = {
		{name = "water_life:beaver_fur", chance = 5, min = 1, max = 1,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 3,},
	},
	attack={range=0.8,damage_groups={fleshy=7}},
	
	animation = {
		def={range={x=250,y=400},speed=40,loop=true},
		stand={range={x=250,y=400},speed=40,loop=true},
		gnaw={range={x=610,y=920},speed=40,loop=true},
		walk={range={x=940,y=965},speed=40,loop=true},	
		swim={range={x=980,y=1005},speed=20,loop=true},
		jump={range={x=1020,y=1055},speed=40,loop=false},
		attack={range={x=1045,y=1060},speed=40,loop=true},
		},
	
	brainfunc = beaver_brain,
	
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
                                              
		if mobkit.is_alive(self) then
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)
		end
	end,
})
