-- sea urchins spawn next to these
water_life.urchinspawn = {
							"default:coral_brown",
							"default:coral_cyan",
							"default:coral_green",
							"default:coral_pink",
							"default:coral_orange",
							"default:coral_skeleton"
}



local function urchin_brain(self)
	
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
        water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	if mobkit.timer(self,1) then 
		local target = mobkit.get_nearby_player(self)
		if target and target:is_player() then
			local distance = vector.distance(mobkit.get_stand_pos(self),target:get_pos())
			if distance < 1 then
				target:punch(self.object,1,self.attack)
			end
	   end
	   
    end
end


---------------
-- the Entities
---------------



minetest.register_entity("water_life:urchin",{
											-- common props
	physical = true,
	stepheight = 0.5,				
	collide_with_objects = false,
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	visual = "mesh",
	mesh = "water_life_urchin.b3d",
	textures = {"water_life_urchin.png"},
	visual_size = {x = 1, y = 1}, --2.5
	static_save = true,
	makes_footstep_sound = false,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 1.07,					-- portion of hitbox submerged
	max_speed = 1,                     
	jump_height = 0.5,
	view_range = 2,
--	lung_capacity = 0, 		-- seconds
	max_hp = 10,
	timeout=180,
    wild = true,
	attack={range=0.1,damage_groups={fleshy=5}},
	drops = {
		{name = "default:diamond", chance = 20, min = 1, max = 1,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 1,},
	},
                                            --[[
    animation = {
		def={range={x=1,y=35},speed=40,loop=true},	--35
		fast={range={x=1,y=35},speed=80,loop=true},
        idle={range={x=36,y=75},speed=20,loop=true},
		},
                                            ]]
	brainfunc = urchin_brain,
    on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
						
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

		end
	end,
                                            --[[
    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local inv = clicker:get_inventory()
        local item = clicker:get_wielded_item()
        
        if not item or item:get_name() ~= "fireflies:bug_net" then return end
        if not inv:room_for_item("main", "water_life:fish") then return end
                                            
        inv:add_item("main", "water_life:riverfish")
        self.object:remove()
    end,
                                            ]]
})



