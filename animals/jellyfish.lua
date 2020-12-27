


local function jellyfish_brain(self)
	if not mobkit.is_alive(self) then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	if mobkit.timer(self,1) then 
        if not self.isinliquid	then 
            --minetest.chat_send_all(dump(self.isinliquid))
            mobkit.hurt(self,1)
        end
        local plyr = mobkit.get_nearby_player(self)
        if plyr and plyr:is_player() then
            water_life.hq_swimfrom(self,50,plyr,1)
        end
        
        if mobkit.is_queue_empty_high(self) then
            mobkit.animate(self,"def")
            mobkit.hq_aqua_roam(self,10,1) 
        end
    end
end


---------------
-- the Entities
---------------



minetest.register_entity("water_life:jellyfish",{
											-- common props
	physical = true,
	stepheight = 0.3,				
	collide_with_objects = false,
	collisionbox = {-0.15, -0.65, -0.15, 0.15, 0.3, 0.15},
	visual = "mesh",
	mesh = "water_life_jellyfish.b3d",
	textures = {"water_life_jellyfish.png"},
	visual_size = {x = 1.5, y = 1.5}, --2.5
	static_save = false,
	makes_footstep_sound = false,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 1.0,					-- portion of hitbox submerged
	max_speed = 1,                     
	jump_height = 0.5,
	view_range = 4,
--	lung_capacity = 0, 		-- seconds
	max_hp = 10,
	glow = 4,
	drops = {
		--{name = "default:diamond", chance = 90, min = 1, max = 1,},		
		{name = "water_life:meat_raw", chance = 5, min = 1, max = 1,},
	},
	brainfunc = jellyfish_brain,
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
						
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

		end
	end,
    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local inv = clicker:get_inventory()
        local item = clicker:get_wielded_item()
        
        if not item or (item:get_name() ~= "fireflies:bug_net" and item:get_name() ~= water_life.catchNet) then return end
        if not inv:room_for_item("main", "water_life:jellyfish_item") then return end
                                            
        inv:add_item("main", "water_life:jellyfish_item")
        self.object:remove()
    end,
})




