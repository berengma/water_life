local random = water_life.random

water_life.register_shark_food("water_life:gull")


local function gull_brain(self)
	if not mobkit.is_alive(self) then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	
	if mobkit.timer(self,10) then
		if random(100) < 15 then
			mobkit.make_sound(self,"idle")
		end
	end
	
	if mobkit.timer(self,5) then
		local vel = self.object:get_velocity()
		local speed = vector.length(vel)
		if speed < 1 and not self.isinliquid then
			mobkit.clear_queue_high(self)
			mobkit.hq_die(self)
		end
	end
	
	
	if mobkit.is_queue_empty_high(self) then
		
		self.object:add_velocity({x=2,y=4,z=2})
		water_life.hq_climb(self,20,2,12)
		
	end
	
end


---------------
-- the Entities
---------------



minetest.register_entity("water_life:gull",{
											-- common props
	physical = true,
	stepheight = 0.3,				
	collide_with_objects = false,
	collisionbox = {-0.45, -0.15, -0.85, 0.65, 0.15, 0.25},
	visual = "mesh",
	mesh = "water_life_gull.b3d",
	textures = {"water_life_gull_gray.png","water_life_gull_black.png","water_life_gull_grayblue.png"},
	visual_size = {x = 0.5, y = 0.5, z = 0.5},
	static_save = false,
	makes_footstep_sound = false,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 1.0,					-- portion of hitbox submerged
	max_speed = 2,                     
	jump_height = 0.5,
	view_range = 16,
--	lung_capacity = 0, 		-- seconds
	max_hp = 5,
	timeout=300,
	wild = true,
	drops = {},
	--	{name = "default:diamond", chance = 20, min = 1, max = 1,},		
	--	{name = "water_life:meat_raw", chance = 2, min = 1, max = 1,},
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
		def={range={x=1,y=95},speed=100,loop=true},
		fly={range={x=1,y=95},speed=100,loop=true},
		glide={range={x=75,y=75},speed=40,loop=false},
		--fast={range={x=81,y=155},speed=80,loop=true},
		},
	brainfunc = gull_brain,
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
						
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

		end
	end,
})

