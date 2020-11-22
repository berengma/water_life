
local phasearmor = {
	[0]={fleshy=0},
	[1]={fleshy=30},
	[2]={fleshy=70}
}

--spawning:
water_life.clams_spawn = {"water_life:seagrassgreen","water_life:seagrassred"}


--entity def

minetest.register_entity("water_life:clams", {
	description="White shelled clams",
	hp_max = 15,
	physical = true,
	collisionbox = {-0.2,-0.2,-0.2, 0.2,0.2,0.2},
	visual = "sprite",
	visual_size = {x=0.5, y=0.5},
	textures = {"water_life_clams.png^[makealpha:128,128,0"},
	spritediv = {x=1, y=3},
	initial_sprite_basepos = {x=0, y=0},
	static_save = false,
	drops = {
		{name = "water_life:meat_raw", chance = 1, min = 1, max = 1},
	},
	buoyancy = 2,
	phase = 0,
	phasetimer = 0,
	makes_footstep_sound = true,
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
	on_step = function(self, dtime)
		self.phasetimer = self.phasetimer + dtime
		if self.phasetimer > 2.0 then
			self.phasetimer = self.phasetimer - 2.0
			self.phase = self.phase + 1
			if self.phase >= 3 then
				self.phase = 0
			end
			self.object:set_sprite({x=0, y=self.phase})
			self.object:set_armor_groups(phasearmor[self.phase])
		end
	end,

	on_punch = function(self, hitter)
			
			if self.object:get_hp() <= 5 then					
			  
			  minetest.add_item(self.object:getpos(), "water_life:meat_raw")
			  self.object:set_hp(0)
			end
		end,
})

