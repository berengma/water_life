


local function fish_brain(self)
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
	   local predator = mobkit.get_nearby_entity(self,"water_life:snake")
	   local value = mobkit.get_queue_priority(self)
	   
	   if value < 50 then
		if value < 45 and predator then
			mobkit.animate(self,"fast")
			water_life.hq_swimfrom(self,45,predator,3)
			
		elseif plyr and plyr:is_player() and self.wild then
			mobkit.animate(self,"fast")
			water_life.hq_swimfrom(self,50,plyr,3)
		end
	   end
        if self.isinliquid and self.isinliquid ~="default:river_water_source" then
            water_life.hq_swimto(self,30,1,"default:river_water_source")
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



minetest.register_entity("water_life:fish",{
											-- common props
	physical = true,
	stepheight = 0.3,				
	collide_with_objects = false,
	collisionbox = {-0.15, -0.15, -0.15, 0.15, 0.15, 0.15},
	visual = "mesh",
	mesh = "water_life_riverfish.b3d",
	textures = {"water_life_riverfish.png"},
	visual_size = {x = 2.5, y = 2.5}, --2.5
	static_save = false,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 1.0,					-- portion of hitbox submerged
	max_speed = 3,                     
	jump_height = 0.5,
	view_range = 4,
--	lung_capacity = 0, 		-- seconds
	max_hp = 10,
	timeout=180,
    wild = true,
	drops = {
		{name = "default:diamond", chance = 20, min = 1, max = 1,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 1,},
	},
    animation = {
		def={range={x=1,y=35},speed=40,loop=true},	--35
		fast={range={x=1,y=35},speed=80,loop=true},
        idle={range={x=36,y=75},speed=20,loop=true},
		},
	brainfunc = fish_brain,
    on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
						
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

		end
	end,
    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local inv = clicker:get_inventory()
        local item = clicker:get_wielded_item()
        
        if not item or item:get_name() ~= "fireflies:bug_net" then return end
        if not inv:room_for_item("main", "water_life:fish") then return end
                                            
        inv:add_item("main", "water_life:riverfish")
        self.object:remove()
    end,
})



minetest.register_entity("water_life:fish_tamed",{
											-- common props
	physical = true,
	stepheight = 0.3,				
	collide_with_objects = false,
	collisionbox = {-0.15, -0.15, -0.15, 0.15, 0.15, 0.15},
	visual = "mesh",
	mesh = "water_life_riverfish.b3d",
	textures = {"water_life_riverfish_tamed.png"},
	visual_size = {x = 2.5, y = 2.5},
	static_save = true,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 1.0,					-- portion of hitbox submerged
	max_speed = 3,                     
	jump_height = 0.5,
	view_range = 4,
--	lung_capacity = 0, 		-- seconds
	max_hp = 10,
--	timeout=60,
    wild = false,
    owner = "",
	drops = {
		{name = "default:diamond", chance = 20, min = 1, max = 1,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 1,},
	},
    animation = {
		def={range={x=1,y=35},speed=40,loop=true},	
		fast={range={x=1,y=35},speed=80,loop=true},
        idle={range={x=36,y=75},speed=20,loop=true},
		},
	brainfunc = fish_brain,
    on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
            
            
            if self.owner and self.owner ~= puncher:get_player_name() and self.owner ~= "" then return end
            if not puncher or not puncher:is_player() then return end
            
                mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

		end
	end,
                                                
    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local inv = clicker:get_inventory()
        local item = clicker:get_wielded_item()
        
        if not item or (item:get_name() ~= "fireflies:bug_net" and item:get_name() ~= water_life.catchNet) then return end
        if not inv:room_for_item("main", "water_life:fish") then return end
        if self.owner and self.owner ~= clicker:get_player_name() and self.owner ~= "" then return end
                                            
        inv:add_item("main", "water_life:riverfish")
        self.object:remove()
    end,
})

