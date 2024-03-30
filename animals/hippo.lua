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

local function hippo_brain(self)

	local prty = mobkit.get_queue_priority(self)

	--die
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end

	--chose between land and water
	if mobkit.timer(self,10) then
		local land = mobkit.recall(self,"landlife")
		local water = mobkit.recall(self,"waterlife")
		if land and prty < 15 then
			land = math.floor(os.time() - land)
			if land > 30 and random(100) < land then
				water_life.hq_go2water(self,15)
			end
		end
		if water and prty < 15 then
			water = math.floor(os.time() - water)
			if water > 30 and random (100) < water then
				water_life.hq_go2land(self,15)
			end
		end
	end

	--every other action check each second
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

		if prty > 5 and prty < 20 then 
			local target = mobkit.get_nearby_player(self)
			local aliveinwater = target and mobkit.is_alive(target) and water_life.isinliquid(target)
			local corpse = water_life.get_close_drops(self,"meat")
			if target and mobkit.is_alive(target)  and target:get_attach() == nil 
				and water_life.isinliquid(target) then
				local dist = water_life.dist2tgt(self,target)
				if dist > 2 and dist < 8 then
					water_life.hq_water_attack(self,target,26,7,true)
				end
			end
			if self.isinliquid then
				if target and mobkit.is_alive(target)  and target:get_attach() == nil
					and not water_life.isinliquid(target) then
						local dist = water_life.dist2tgt(self,target)
						if dist < 8 then
							water_life.hq_go2land(self,20,target)
						end
				end
			end

			--on land
			if self.isonground then
				local rnd = random(1000)
				if rnd < 30 then
					mobkit.make_sound(self,"idle")
				end
				if target and mobkit.is_alive(target)  then
					local dist = water_life.dist2tgt(self,target)
					if dist < self.view_range then
						--water_life.hq_hunt(self,24,target,7)
						water_life.hq_findpath(self, 24, mobkit.get_stand_pos(target), dist, 1, 1)
					end
				end
				if corpse and not water_life.inwater(corpse) then
					local dist = water_life.dist2tgt(self,corpse)
					if dist < 16 and prty < 23 then
						water_life.hq_catch_drop(self,23,corpse)
					end
				end
			end
		end
	end
	if mobkit.is_queue_empty_high(self) then
		if self.isinliquid then 
			water_life.hq_aqua_roam(self,10,1) 
		else
			water_life.hq_slow_roam(self,12) 
		end
	end
end

minetest.register_entity("water_life:hippo",{
	physical = true,
	stepheight = 1.1,
	collide_with_objects = true,
	collisionbox = {-0.49, 0, -0.49, 0.49, 1.99, 0.49},
	visual = "mesh",
	mesh = "water_life_hippo.b3d",
	textures = {"water_life_hippo.png"},
	visual_size = {x = 1.5, y = 1.5},
	static_save = true,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	springiness=0,
	buoyancy = 0.98,
	max_speed = 5,                        
	jump_height = 0.5,
	view_range = 16,
	max_hp = 50,
	timeout=300,
	drops = {
		{name = "default:diamond", chance = 5, min = 1, max = 5,},		
		{name = "water_life:meat_raw", chance = 1, min = 2, max = 5,},
	},
	attack={range=0.8,damage_groups={fleshy=7}},
	sounds = {
		attack={
			{name = 'water_life_hippoattack',
			gain = water_life.soundadjust}
			},
		idle={
			{name = "water_life_hippo1",
               gain = water_life.soundadjust},
			{name = "water_life_hippo2",
			gain = water_life.soundadjust},
			}
		},
	animation = {
		def={range={x=0,y=100},speed=5,loop=true},
		stand={range={x=0,y=100},speed=1,loop=false},
		die={range={x=100,y=200},speed=1,loop=false},
		walk={range={x=300,y=400},speed=15,loop=true},	
		swim={range={x=300,y=400},speed=30,loop=true},
		},
	
	brainfunc = hippo_brain,
	
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
