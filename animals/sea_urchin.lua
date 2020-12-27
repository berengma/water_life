-- sea urchins spawn next to these
water_life.urchinspawn = {
							"default:coral_brown",
							"default:coral_cyan",
							"default:coral_green",
							"default:coral_pink",
							"default:coral_orange",
							"water_life:coralmagenta",
							"water_life:coralskyblue",
							"seacoral:seacoralsandaqua",
							"seacoral:seacoralsandcyan",
							"seacoral:seacoralsandlime",
							"seacoral:seacoralsandmagenta",
							"seacoral:seacoralsandredviolet",
							"seacoral:seacoralsandskyblue"
}



local function urchin_brain(self)
	
	if not mobkit.is_alive(self) then	
		mobkit.clear_queue_high(self)
        water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	
	if mobkit.timer(self,30) then
		local ground = mobkit.get_stand_pos(self)
		local coraltable = minetest.find_nodes_in_area({x=ground.x-2, y=ground.y-2, z=ground.z-2}, {x=ground.x+2, y=ground.y+2, z=ground.z+2}, water_life.urchinspawn)
		if not coraltable or #coraltable < 1 then mobkit.hurt(self,1) end
	end
	
	if mobkit.timer(self,60) then
		local obj = mobkit.get_closest_entity(self,"water_life:urchin")
		if obj then
			local friend = vector.distance(mobkit.get_stand_pos(self), mobkit.get_stand_pos(obj))
			if friend < 1 then
				local eaten = mobkit.pos_shift(mobkit.get_stand_pos(self),{y=-1})
				local check = minetest.get_node(eaten).name
				local makanlah = false
				for i=1,#water_life.urchinspawn,1 do
					if water_life.urchinspawn[i] == check then
						makanlah = true
						break
					end
				end
				if makanlah then minetest.set_node(eaten, {name="default:coral_skeleton"}) end
			end
		end
	end
		
	if mobkit.timer(self,1) then 
		local nature = water_life_get_biome_data(mobkit.get_stand_pos(self))
		
		if not self.isinliquid or self.isinliquid ~= "default:water_source" or nature.temp < 20 then mobkit.hurt(self,1) end
		
		local target = mobkit.get_nearby_player(self)
		if target and target:is_player() then
			local distance = vector.distance(mobkit.get_stand_pos(self),target:get_pos())
			if distance < 1 then
				target:punch(self.object,1,self.attack)
			end
	   end
	   
	   if water_life.random(100) < 30 then
			if mobkit.get_queue_priority(self) < 99 then
				water_life.hq_idle(self,99,water_life.random(30,120))
			end
	   end
	   
	   if mobkit.is_queue_empty_high(self) then
			water_life.hq_snail_move(self,10)
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
	max_speed = 0.2,                     
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
                                            
    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local inv = clicker:get_inventory()
        local item = clicker:get_wielded_item()
        
        if not item or (item:get_name() ~= "fireflies:bug_net" and item:get_name() ~= water_life.catchNet) then return end
        if not inv:room_for_item("main", "water_life:urchin_item") then return end
                                            
        inv:add_item("main", "water_life:urchin_item")
        self.object:remove()
    end,
                                            
})



