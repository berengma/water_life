water_life.piranha_biomes= {	["rainforest"]=1,
						["rainforest_ocean"]=1,
						["rainforest_swamp"]=1,
						["savanna"]=1,
						["savanna_shore"]=1,
						["savanna_ocean"]=1,
}


local function piranha_ff(self)
	for i = 1,#water_life.shark_food,1 do
		if water_life.shark_food[i] ~= "water_life:fish" and water_life.shark_food[i] ~= "water_life:fish_tamed" then
			local target = mobkit.get_closest_entity(self,water_life.shark_food[i])
			if target then
				return target
			end
		end
	end
	return nil
end


local function piranha_brain(self)
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
        local target = mobkit.get_nearby_player(self)
		
        if target then
			local dist = water_life.dist2tgt(self,target)
			mobkit.animate(self,"fast")
			if dist > 2 and mobkit.is_alive(target) and mobkit.is_in_deep(target) and target:get_attach() == nil then
				mobkit.clear_queue_high(self)
				water_life.hq_water_attack(self,target,50,5)
			elseif target and mobkit.is_alive(target) and ((not mobkit.is_in_deep(target)) or (target:get_attach() ~= nil)) then
				water_life.hq_swimfrom(self,30,target,4,5)
			end
		end
		local prio = mobkit.get_queue_priority(self)
		if prio < 50 then
			local food = piranha_ff(self)
			if food and mobkit.is_alive(food) and mobkit.is_in_deep(food) then
				local dist = water_life.dist2tgt(self,food)
				if dist > 2 then 
					mobkit.clear_queue_high(self)
					water_life.hq_water_attack(self,food,40,5)
				end
			end
		end
		
	
        if self.isinliquid and self.isinliquid == "default:water_source" then
			
			water_life.hq_swimto(self,20,1,{"water_life:muddy_river_water_source","default:river_water_source"})
			
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



minetest.register_entity("water_life:piranha",{
											-- common props
	physical = true,
	stepheight = 0.3,				
	collide_with_objects = false,
	collisionbox = {-0.15, 0, -0.15, 0.15, 0.3, 0.15},
	visual = "mesh",
	mesh = "water_life_piranha.b3d",
	textures = {"water_life_piranha.png"},
	visual_size = {x = 0.3, y = 0.3}, --2.5
	static_save = false,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 1.0,					-- portion of hitbox submerged
	max_speed = 6,                     
	jump_height = 0.5,
	view_range = 16,
--	lung_capacity = 0, 		-- seconds
	max_hp = 10,
	timeout=360,
    wild = true,
	attack={range=0.4,damage_groups={fleshy=5}},
	drops = {
		{name = "default:diamond", chance = 30, min = 1, max = 1,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 1,},
	},
    animation = {
		def={range={x=1,y=20},speed=10,loop=true},	--35
		fast={range={x=1,y=20},speed=20,loop=true},
        --idle={range={x=36,y=75},speed=20,loop=true},
		},
	brainfunc = piranha_brain,
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
                                            
        inv:add_item("main", "water_life:piranha")
        self.object:remove()
    end,
})


minetest.register_entity("water_life:piranha_tamed",{
											-- common props
	physical = true,
	stepheight = 0.3,				
	collide_with_objects = false,
	collisionbox = {-0.15, 0, -0.15, 0.15, 0.3, 0.15},
	visual = "mesh",
	mesh = "water_life_piranha.b3d",
	textures = {"water_life_piranha.png"},
	visual_size = {x = 0.3, y = 0.3}, --2.5
	static_save = true,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 1.0,					-- portion of hitbox submerged
	max_speed = 6,                     
	jump_height = 0.5,
	view_range = 16,
--	lung_capacity = 0, 		-- seconds
	max_hp = 10,
	wild = false,
	attack={range=0.4,damage_groups={fleshy=5}},
	drops = {
		{name = "default:diamond", chance = 30, min = 1, max = 1,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 1,},
	},
    animation = {
		def={range={x=1,y=20},speed=10,loop=true},	--35
		fast={range={x=1,y=20},speed=20,loop=true},
        --idle={range={x=36,y=75},speed=20,loop=true},
		},
	brainfunc = piranha_brain,
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
        if not inv:room_for_item("main", "water_life:fish") then return end
                                            
        inv:add_item("main", "water_life:piranha")
        self.object:remove()
    end,
})
