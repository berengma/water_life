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

local function alligator_brain(self)
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
			land = math.floor(os.time()-land)
			if random(500) < land then
				mobkit.clear_queue_high(self)
				water_life.hq_go2water(self,15)
				
			end
		end
		if water then
			water = math.floor(os.time()-water)
			if random (500) < water then
				mobkit.clear_queue_high(self)
				water_life.hq_go2land(self,15)
			end
		end
	end
	if mobkit.timer(self,1) then
		if not mobkit.recall(self,"landlife") and not mobkit.recall(self,"waterlife") then
			mobkit.remember(self,"waterlife",os.time())
		end
		if self.isinliquid then
			if mobkit.recall(self,"landlife") then
				mobkit.remember(self,"waterlife",os.time())
				mobkit.forget(self,"landlife")
			end
		end
		if self.isonground then
			if mobkit.recall(self,"waterlife") then
				mobkit.remember(self,"landlife",os.time())
				mobkit.forget(self,"waterlife")
			end
		end
        local prty = mobkit.get_queue_priority(self)
		if prty < 11 and self.isinliquid then
			if water_life.check_for_pool(self) then
				mobkit.clear_queue_high(self)
				water_life.hq_aquaidle(self,12,"stand")
			end
		end
		if prty < 20 then 
			local target = mobkit.get_nearby_player(self)
			local aliveinwater = target and mobkit.is_alive(target) and water_life.isinliquid(target)
			local corpse = water_life.get_close_drops(self,"meat")
			local food = water_life.feed_shark(self)
			if target and mobkit.is_alive(target)  and target:get_attach() == nil
				and water_life.isinliquid(target) then
					local dist = water_life.dist2tgt(self,target)
					if dist > 3 then
						water_life.hq_water_attack(self,target,24,7,true)
					end
			end
			if food and mobkit.is_in_deep(food) and not aliveinwater then
				local dist = water_life.dist2tgt(self,food)
				if dist > 3 then
					mobkit.clear_queue_high(self)
					water_life.hq_water_attack(self,food,25,7,true)
				end
			end
			if self.isinliquid then
				if target and mobkit.is_alive(target)  and target:get_attach() == nil
					and not water_life.isinliquid(target) then
						local dist = water_life.dist2tgt(self,target)
						if dist < 10 then
							mobkit.clear_queue_high(self)
							water_life.hq_go2land(self,20,target)
						end
				end
				if food and mobkit.is_alive(food) and not water_life.isinliquid(food) then
					local dist = water_life.dist2tgt(self,food)
					if dist < 10 then
						mobkit.clear_queue_high(self)
						water_life.hq_go2land(self,20,food)
					end
				end
			end
			if self.isonground then
				local rnd = random(1000)
				if rnd < 30 then
					mobkit.make_sound(self,"idle")
				end
				if target and mobkit.is_alive(target)  then
					local dist = water_life.dist2tgt(self,target)
					if dist < 7 then
						water_life.hq_hunt(self,24,target)
					end
				end
				if food and mobkit.is_alive(food) then
					local dist = water_life.dist2tgt(self,food)
					if dist < 7 then
						water_life.hq_hunt(self,25,food)
					end
				end
				if corpse and not water_life.inwater(corpse) then
					local dist = water_life.dist2tgt(self,corpse)
					if dist < 16 and prty < 23 then
						mobkit.clear_queue_high(self)
						mobkit.clear_queue_low(self)
						water_life.hq_catch_drop(self,23,corpse)
					end
				end
			end
		end
	end
	
	if mobkit.is_queue_empty_high(self) then
		if self.isinliquid then water_life.hq_aqua_roam(self,10,1) end
		if self.isonground then  water_life.hq_slow_roam(self,10) end
	end
	
	
	
end



minetest.register_entity("water_life:alligator",{
	initial_properties =
	{
		physical = true,
		stepheight = 0.5,
		collide_with_objects = true,
		collisionbox = {-0.25, -0.1, -0.25, 0.25, 0.5, 0.25},
		visual = "mesh",
		mesh = "water_life_alligator.b3d",
		textures = {"water_life_alligator.png"},
		visual_size = {x = 8, y = 8},
		static_save = false,
		makes_footstep_sound = true
	},
	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	springiness=0,
	buoyancy = 0.98,
	max_speed = 9,                        
	jump_height = 1.96,
	view_range = water_life.abo * 12,
	max_hp = 50,
	timeout=30,
	drops = {
		{name = "default:diamond", chance = 5, min = 1, max = 5,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 5,},
		{name = "water_life:crocleather", chance = 3, min = 1, max = 2},
	},
	attack={range=0.8,damage_groups={fleshy=7}},
	sounds = {
		attack='water_life_crocattack',
		idle={
			{name = "water_life_croc1",
               gain = water_life.soundadjust},
			{name = "water_life_croc2",
			gain = water_life.soundadjust},
			{name = "water_life_croc3",
			gain = water_life.soundadjust},
			{name = "water_life_croc4",
			gain = water_life.soundadjust},
			{name = "water_life_croc5",
			gain = water_life.soundadjust}
			}
		},
	animation = {
		def={range={x=150,y=180},speed=25,loop=true},
		stand={range={x=1,y=60},speed=25,loop=true},
		walk={range={x=70,y=100},speed=25,loop=true},	
		swim={range={x=150,y=180},speed=25,loop=true},
		bite={range={x=110,y=140},speed=25,loop=false},
		roll={range={x=190,y=215},speed=25,loop=false},
		},
	brainfunc = alligator_brain,
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
			local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
			self.object:set_velocity({x=hvel.x,y=2,z=hvel.z})
			if water_life.bloody then water_life.spilltheblood(self.object) end
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)
			if type(puncher)=='userdata' and puncher:is_player() then
				mobkit.clear_queue_high(self)
				water_life.hq_water_attack(self,puncher,20,6,true)
			end
		end
	end,
})
