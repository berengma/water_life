local random = water_life.random
local rad = math.rad

water_life.register_shark_food("water_life:gull")

local function gull_brain(self)
	if not mobkit.is_alive(self) then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		--mobkit.hq_die(self)
		water_life.hq_die(self,'float')
		return
	end
	
	local prty = mobkit.get_queue_priority(self)
	-- 
	-- 10-19 fly		20-29 water		30-39 land
	--
	if mobkit.timer(self,10) then
		local rnd = random (100)
		local force = false
		if rnd < 11 then
			mobkit.make_sound(self,"idle")
		end
		local plyr = mobkit.get_nearby_player(self)
		local whale = mobkit.get_nearby_entity(self,"water_life:whale")
		local wname = ""
		if whale and rnd > 10 then
			mobkit.clear_queue_high(self)
			mobkit.clear_queue_low(self)
			water_life.hq_fly2obj(self,18,whale,4,true)
		end
		if plyr then
			local stack = plyr:get_wielded_item()
			wname = stack:get_name()
			if rnd < 10 then force = true end
		end
		if plyr and prty < 17 and (water_life.gull_bait[wname] or force) then
			mobkit.clear_queue_high(self)
			mobkit.clear_queue_low(self)
			water_life.hq_fly2obj(self,18,plyr,2,force)
		end
	end
	if mobkit.timer(self,5) then
		local vel = self.object:get_velocity()
		local speed = vector.length(vel)
		if speed < 1 and not self.isinliquid then
			mobkit.clear_queue_high(self)
			water_life.hq_die(self,'float')
		end
	end
	if mobkit.timer(self,5) then
		local land = mobkit.recall(self,"landlife")
		local water = mobkit.recall(self,"waterlife")
		local air = mobkit.recall(self,"airlife")
		if air then
			air = math.floor(os.time()-air)
			if random(500) < air then
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
			end
		end
		
		if land then
			land = math.floor(os.time()-land)
			if random(500) < land then
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
			end
		end
		if water then
			water = math.floor(os.time()-water)
			if random (500) < water then
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
				water_life.hq_go2land(self,15)
			end
		end
	end
	if mobkit.timer(self,1) then
		local enemy = water_life.get_closest_enemy(self)
		if self.isinliquid then
			mobkit.remember(self,"waterlife",os.time())
			mobkit.forget(self,"landlife")
			mobkit.forget(self,"airlife")
			if prty > 19 and prty < 22 and enemy then
				local eyaw = enemy:get_yaw()
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
				water_life.hq_water_takeoff(self,22,'takeoff',eyaw)
				water_life.hq_climb(self,15,4,16)
			end
			if prty < 20 or prty > 30 then 
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
				water_life.hq_idle(self,21,20,'float')
				water_life.hq_water_takeoff(self,20,'takeoff')
				water_life.hq_climb(self,15,4,16)
			end
		end
		if self.isonground then
			mobkit.remember(self,"landlife",os.time())
			mobkit.forget(self,"waterlife")
			mobkit.forget(self,"airlife")
		end
	end
	if mobkit.is_queue_empty_high(self) then
		if not self.isinliquid then
			self.object:add_velocity({x=2,y=4,z=2})
			water_life.hq_climb(self,15,4,16)
			mobkit.remember(self,"airlife",os.time())
			mobkit.forget(self,"landlife")
			mobkit.forget(self,"waterlife")
		else
			water_life.hq_idle(self,21,20,'float')
			water_life.hq_water_takeoff(self,20,'takeoff')
			water_life.hq_climb(self,15,4,16)
		end
	end
end

minetest.register_entity("water_life:gull",{
	physical = true,
	stepheight = 0.5,				
	collide_with_objects = false,
	collisionbox = {-0.45, -0.25, -0.45, 0.45, 0.15, 0.45},
	visual = "mesh",
	mesh = "water_life_gull.b3d",
	textures = {"water_life_gull1.png","water_life_gull2.png","water_life_gull3.png"},
	visual_size = {x = 0.75, y = 0.5, z = 0.75},
	static_save = true,
	makes_footstep_sound = false,
	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	springiness=0,
	buoyancy = 0.59,
	max_speed = 3,                     
	jump_height = 1.5,
	view_range = water_life.abo * 16,
	max_hp = 5,
	timeout=10,
	wild = true,
	drops = {},
	predators = {["water_life:shark"] = 1,
                  ["water_life:alligator"] = 1,
                  ["water_life:whale"] = 1,
                  ["water_life:piranha"] = 1,
                  ["water_life:snake"] = 1,
                  ["water_life:croc"] = 1
                  },
	sounds = {
		idle={
			{name = "water_life_seagull1",
               gain = water_life.soundadjust},
			{name = "water_life_seagull2",
			gain = water_life.soundadjust},
			{name = "water_life_seagull3",
			gain = water_life.soundadjust},
			{name = "water_life_seagull4",
			gain = water_life.soundadjust},
			{name = "water_life_seagull5",
			gain = water_life.soundadjust}
			}
		},
	animation = {
		def={range={x=200,y=220},speed=25,loop=true},
		fly={range={x=200,y=220},speed=25,loop=true},
		glide={range={x=270,y=290},speed=25,loop=true},
		idle={range={x=0,y=20},speed=25,loop=true},
		jump={range={x=40,y=60},speed=25,loop=false},
		walk={range={x=80,y=100},speed=25,loop=true},
		takeoff={range={x=120,y=160},speed=25,loop=false},
		dive={range={x=380,y=390},speed=25,loop=true},
		float={range={x=510,y=520},speed=25,loop=true},
		swim={range={x=520,y=540},speed=25,loop=true},
		fly2attk={range={x=560,y=570},speed=25,loop=false},
		attack={range={x=570,y=630},speed=25,loop=true},
		attk2fly={range={x=650,y=660},speed=25,loop=false},
		peck={range={x=680,y=710},speed=25,loop=false},
		look={range={x=720,y=740},speed=25,loop=false},
		clean={range={x=750,y=865},speed=25,loop=false},
		},
	brainfunc = gull_brain,
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
			if water_life.bloody then water_life.spilltheblood(self.object) end			
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

		end
	end,
})
