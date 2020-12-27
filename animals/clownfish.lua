local random = water_life.random


local function fish_brain(self)
	if not mobkit.is_alive(self) then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	
	if mobkit.timer(self,5) then
		local pos = self.object:get_pos()
		local obj = self.object
		if self.base and vector.distance(self.base,pos) > 5 then
			water_life.hq_swimto(self,20,0.5,nil,self.base)
		else
			local coraltable = minetest.find_nodes_in_area({x=pos.x-5, y=pos.y-5, z=pos.z-5}, {x=pos.x+5, y=pos.y+5, z=pos.z+5},water_life.urchinspawn)
			if #coraltable > 0 then self.base = coraltable[random(#coraltable)] end
		end
	end
	
	if mobkit.timer(self,1) then 
        if not self.isinliquid	then 
            --minetest.chat_send_all(dump(self.isinliquid))
            mobkit.hurt(self,1)
        end
        local plyr = mobkit.get_nearby_player(self)
        if plyr and plyr:is_player() and self.wild then
            mobkit.animate(self,"fast")
            water_life.hq_swimfrom(self,50,plyr,1)
        end
        if self.isinliquid and self.isinliquid =="default:river_water_source" then
            water_life.hq_swimto(self,30,1,"default:water_source")
        end
        if mobkit.is_queue_empty_high(self) then
            mobkit.animate(self,"def")
            mobkit.hq_aqua_roam(self,10,0.5) 
        end
    end
end


---------------
-- the Entities
---------------



minetest.register_entity("water_life:clownfish",{
											-- common props
	physical = true,
	stepheight = 0.3,				
	collide_with_objects = false,
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	visual = "mesh",
	mesh = "water_life_clownfish.b3d",
	textures = {"water_life_clownfish.png"},
	visual_size = {x = 0.2, y = 0.2, z = 0.2}, --2.5
	static_save = false,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 1.0,					-- portion of hitbox submerged
	max_speed = 2,                     
	jump_height = 0.5,
	view_range = 2,
--	lung_capacity = 0, 		-- seconds
	max_hp = 5,
	timeout=300,
	wild = true,
	base = nil,
	drops = {},
	--	{name = "default:diamond", chance = 20, min = 1, max = 1,},		
	--	{name = "water_life:meat_raw", chance = 2, min = 1, max = 1,},
	
    animation = {
		def={range={x=1,y=80},speed=40,loop=true},	--35
		fast={range={x=81,y=155},speed=80,loop=true},
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
        if not inv:room_for_item("main", "water_life:clownfish") then return end
                                            
        inv:add_item("main", "water_life:clownfish")
        self.object:remove()
    end,
})



minetest.register_entity("water_life:clownfish_tamed",{
											-- common props
	physical = true,
	stepheight = 0.3,				
	collide_with_objects = false,
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	visual = "mesh",
	mesh = "water_life_clownfish.b3d",
	textures = {"water_life_clownfish.png"},
	visual_size = {x = 0.2, y = 0.2, z = 0.2},
	static_save = true,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 1.0,					-- portion of hitbox submerged
	max_speed = 2,                     
	jump_height = 0.5,
	view_range = 3,
--	lung_capacity = 0, 		-- seconds
	max_hp = 5,
--	timeout=60,
	wild = false,
	base = nil,
	owner = "",
	drops = {},
	--	{name = "default:diamond", chance = 20, min = 1, max = 1,},		
	--	{name = "water_life:meat_raw", chance = 2, min = 1, max = 1,},
	
    animation = {
		def={range={x=1,y=80},speed=40,loop=true},	
		fast={range={x=81,y=155},speed=80,loop=true},
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
        if not inv:room_for_item("main", "water_life:clownfish") then return end
        if self.owner and self.owner ~= clicker:get_player_name() and self.owner ~= "" then return end
                                            
        inv:add_item("main", "water_life:clownfish")
        self.object:remove()
    end,
})

