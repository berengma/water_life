local random = water_life.random

water_life.register_shark_food("water_life:gull")


local function gull_brain(self)
	if not mobkit.is_alive(self) then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	
	--
	--get prorities !
	local prty = mobkit.get_queue_priority(self)
	--
	--
	
	
	if mobkit.timer(self,10) then
		if random(100) < 10 then
			mobkit.make_sound(self,"idle")
		end
	end
	
	-- die if crashed somewhere
	if mobkit.timer(self,5) then
		local vel = self.object:get_velocity()
		local speed = vector.length(vel)
		if speed < 1 and not self.isinliquid then
			mobkit.clear_queue_high(self)
			mobkit.hq_die(self)
		end
	end
	
	
	--land, water and air
	if mobkit.timer(self,5) then
		
		local land = mobkit.recall(self,"landlife")
		local water = mobkit.recall(self,"waterlife")
		local air = mobkit.recall(self,"airlife")
		
		if air then
			air = math.floor(os.clock()-air)
			if random(500) < air then
				--minetest.chat_send_all("Time to land")
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
				--water_life.hq_landon_water(self,15)
			end
		end
		
		if land then
			land = math.floor(os.clock()-land)
			if random(500) < land then
				--minetest.chat_send_all("Land takeoff")
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
				--water_life.hq_takeoff(self,15)
				
			end
		end
		
		if water then
			water = math.floor(os.clock()-water)
			if random (500) < water then
				--minetest.chat_send_all("Go to land")
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
				water_life.hq_go2land(self,15)
			end
		end
		
		--minetest.chat_send_all("Land: "..dump(land).." :  Water: "..dump(water))
	end
	
	
	
	if mobkit.timer(self,1) then
	
		--minetest.chat_send_all(dump(prty)..")  "..dump(self.isinliquid)) --.."    :    "..dump(self.dtime)) --colinfo.collides))
		
		if self.isinliquid then
			
			mobkit.remember(self,"waterlife",os.clock())
			mobkit.forget(self,"landlife")
			mobkit.forget(self,"airlife")
			
			-- anything else from inwater behavior
			if prty < 20 or prty > 30 then 
				mobkit.clear_queue_high(self)
				mobkit.clear_queue_low(self)
				water_life.hq_idle(self,21,20,'float')
				water_life.hq_water_takeoff(self,20,'takeoff')
				water_life.hq_climb(self,15,4,16)
			end
			
		end
		
		if self.isonground then
			
			mobkit.remember(self,"landlife",os.clock())
			mobkit.forget(self,"waterlife")
			mobkit.forget(self,"airlife")
			
		end
	end
	
	
	if mobkit.is_queue_empty_high(self) then
		
		--self.object:add_velocity({x=2,y=4,z=2})
		water_life.hq_climb(self,15,4,16)
		mobkit.remember(self,"airlife",os.clock())
		mobkit.forget(self,"landlife")
		mobkit.forget(self,"waterlife")
		
	end
	
	
end


---------------
-- the Entities
---------------



minetest.register_entity("water_life:gull",{
											-- common props
	physical = true,
	stepheight = 0.5,				
	collide_with_objects = false,
	collisionbox = {-0.45, -0.15, -0.85, 0.65, 0.15, 0.25},
	visual = "mesh",
	mesh = "water_life_gull.b3d",
	textures = {"water_life_gull1.png","water_life_gull2.png","water_life_gull3.png"},
	visual_size = {x = 0.75, y = 0.5, z = 0.75},
	static_save = false,
	makes_footstep_sound = false,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 0.89,					-- portion of hitbox submerged
	max_speed = 3,                     
	jump_height = 1.5,
	view_range = 16,
--	lung_capacity = 0, 		-- seconds
	max_hp = 5,
	timeout=60,
	wild = true,
	drops = {},
	--	{name = "default:diamond", chance = 20, min = 1, max = 1,},		
	--	{name = "water_life:meat_raw", chance = 2, min = 1, max = 1,},
	predators = {"water_life:shark",
                  "water_life:alligator",
                  "water_life:whale"
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
						
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

		end
	end,
})

