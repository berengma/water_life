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





local function gecko_brain(self)
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	
	if mobkit.timer(self,60) then
		local time = water_life.get_game_time()
		
		if time == 4 and random(100) < 15 then
			mobkit.make_sound(self,"idle")
		end
	end
	
	
	if mobkit.timer(self,5) then
		
		local land = mobkit.recall(self,"landlife")
		local water = mobkit.recall(self,"waterlife")
		
		
		if land then
			land = math.floor(os.clock()-land)
			
			if random(1000) < land then
				--minetest.chat_send_all("Go to water")
				mobkit.clear_queue_high(self)
				water_life.hq_go2water(self,15)
				
			end
		end
		
		if water then
			water = math.floor(os.clock()-water)
			if random (500) < water then
				--minetest.chat_send_all("Go to land")
				mobkit.clear_queue_high(self)
				water_life.hq_go2land(self,15)
			end
		end
		
		
		--minetest.chat_send_all("Land: "..dump(land).." :  Water: "..dump(water))
	end
	
	if mobkit.timer(self,1) then
		local pos = self.object:get_pos()
		local value = mobkit.get_queue_priority(self)
		
		if not mobkit.recall(self,"landlife") and not mobkit.recall(self,"waterlife") then
			mobkit.remember(self,"waterlife",os.clock())
		end
			
		if self.isinliquid then
			if mobkit.recall(self,"landlife") then
				mobkit.remember(self,"waterlife",os.clock())
				mobkit.forget(self,"landlife")
			end
			local pred = water_life.get_closest_enemy(self,true)
			if pred and value < 25 then 
				water_life.hq_swimfrom(self,25,pred,4,8)
				water_life.hq_go2land(self,24)
			end
		end
		
		if self.isonground then
			if mobkit.recall(self,"waterlife") then
				mobkit.remember(self,"landlife",os.clock())
				mobkit.forget(self,"waterlife")
			end
			local pred = water_life.get_closest_enemy(self,true)
			if pred and value < 20 then 
				mobkit.hq_runfrom(self,20,pred)
			end
		end
			
		
		
		if mobkit.is_queue_empty_high(self) then
			if self.isinliquid then water_life.hq_aqua_roam(self,10,1) end
			if self.isonground then  water_life.hq_slow_roam(self,10,30) end
		end
	end
	
	
	
end



minetest.register_entity("water_life:gecko",{
											-- common props
	physical = true,
	stepheight = 0.1,				--EVIL!
	collide_with_objects = true,
	collisionbox = {-0.2, 0, -0.2, 0.2, 0.2, 0.2},
	visual = "mesh",
	mesh = "water_life_gecko.b3d",
	textures = {"water_life_geckoskin.png"},
	visual_size = {x = 0.15, y = 0.15},
	static_save = false,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 0.98,					-- portion of hitbox submerged
	max_speed = 9,                        
	jump_height = 2.26,
	view_range = 12,
--	lung_capacity = 0, 		-- seconds
	max_hp = 20,
	timeout=300,
	drops = {
		{name = "default:diamond", chance = 5, min = 1, max = 1,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 5,},
	},
	attack={range=0.8,damage_groups={fleshy=7}},
                                             
	predators = {["wildlife:wolf"] = 1,
                  ["water_life:snake"] = 1,
                  ["water_life:croc"] = 1,
                  ["aerotest:eagle"] = 1,
                  ["water_life:shark"] = 1,
                  },
	
	animation = {
		def={range={x=20,y=260},speed=40,loop=true},
		stand={range={x=300,y=420},speed=40,loop=true},
		walk={range={x=440,y=500},speed=40,loop=true},	
		die={range={x=510,y=700},speed=40,loop=false},
		},
                                             
	sounds = {
		idle={
                name='water_life_tokeh',
                gain = water_life.soundadjust
                }
		},
	
	brainfunc = gecko_brain,
	
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
			local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
			self.object:set_velocity({x=hvel.x,y=2,z=hvel.z})
			
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

			if type(puncher)=='userdata' and puncher:is_player() then	-- if hit by a player
				mobkit.clear_queue_high(self)							-- abandon whatever they've been doing
				water_life.hq_water_attack(self,puncher,20,6,true)
			end
		end
	end,
})
