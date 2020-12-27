local random = water_life.random
local abs = math.abs
local pi = math.pi
local floor = math.floor
local sqrt = math.sqrt
local max = math.max
local min = math.min
local pow = math.pow
local sign = math.sign
local rad = math.rad





local function snake_brain(self)
	
	-- handling death
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	
	
	-- handling life in water and on land
	if mobkit.timer(self,5) then
		
		local land = mobkit.recall(self,"landlife")
		local water = mobkit.recall(self,"waterlife")
		
		if land then
			land = math.floor(os.clock()-land)
			--minetest.chat_send_all(dump(land))
			if random(240,360) < land then
				--minetest.chat_send_all("Go to water")
				mobkit.clear_queue_high(self)
				water_life.hq_go2water(self,15)
				
			end
		end
		
		if water then
			water = math.floor(os.clock()-water)
			if random (60,120) < water then
				--minetest.chat_send_all("Go to land")
				mobkit.clear_queue_high(self)
				water_life.hq_go2land(self,25)
			end
		end
		
		--minetest.chat_send_all("Land: "..dump(land).." :  Water: "..dump(water))
	end
	
	
	
	if mobkit.timer(self,1) then
			
		if not mobkit.recall(self,"landlife") and not mobkit.recall(self,"waterlife") then
			mobkit.remember(self,"waterlife",os.clock())
		end
			
		if self.isinliquid then
			if mobkit.recall(self,"landlife") then
				mobkit.remember(self,"waterlife",os.clock())
				mobkit.forget(self,"landlife")
			end
		end
		
		if self.isonground then
			if mobkit.recall(self,"waterlife") then
				mobkit.remember(self,"landlife",os.clock())
				mobkit.forget(self,"waterlife")
			end
		end
			
		local prty = mobkit.get_queue_priority(self)
		
			if prty < 20 then 
				local target = mobkit.get_nearby_player(self)
				local aliveinwater = target and mobkit.is_alive(target) and mobkit.is_in_deep(target)
				
				
				if target and mobkit.is_alive(target)  and target:get_attach() == nil and aliveinwater then
					
					local dist = water_life.dist2tgt(self,target)
					if dist < self.view_range then
						-- snakes do not attack when in water
					end
				end
				
				
				if self.isinliquid then
					
					mobkit.clear_queue_high(self)
					mobkit.clear_queue_low(self)
					water_life.hq_aqua_roam(self,21,1,"swim")
					
					 --[[
					if target and mobkit.is_alive(target)  and target:get_attach() == nil and not water_life.isinliquid(target) then --.is_in_deep(target) then
						
						local dist = water_life.dist2tgt(self,target)
						if dist < 10 then
							mobkit.clear_queue_high(self)
							water_life.hq_go2land(self,20,target)
						end
						
					end]]
					
				end
				
				if self.isonground then
					
					if target and mobkit.is_alive(target)  then
						local action = mobkit.recall(self,"warned")
						local pname = target:get_player_name()
						local dist = water_life.dist2tgt(self,target)
						
						if  dist > 4 and dist < self.view_range and not action then
							mobkit.clear_queue_high(self)
							mobkit.clear_queue_low(self)
							water_life.hq_snake_warn(self,target,30,8)
						elseif dist < 5 or action == pname then
							mobkit.forget(self,"warned")
							
							local meta = target:get_meta()
							--minetest.chat_send_all(dump(action).." "..pname.."   poison level = "..dump(meta:get_int("snakepoison")))
							if meta:get_int("snakepoison") > 0 then
								water_life.hq_snakerun(self,31,target)
							else
								water_life.hq_hunt(self,31,target)
							end
						end
					end
					
				end
				
		end
	end
	
	if mobkit.is_queue_empty_high(self) then
		if self.isinliquid then water_life.hq_aqua_roam(self,21,1,"swim") end
		if self.isonground then
			
			water_life.hq_snake_move(self,10)
			water_life.hq_idle(self,9,random(60,180),"sleep")
			
			
		end
	end
	
	
	
end



minetest.register_entity("water_life:snake",{
											-- common props
	physical = true,
	stepheight = 0.1,				--EVIL!
	collide_with_objects = false,
	collisionbox = {-0.35, -0.01, -0.35, 0.35, 0.2, 0.35},
	visual = "mesh",
	mesh = "water_life_snake.b3d",
	textures = {"water_life_snake.png"},
	visual_size = {x = 0.05, y = 0.05},
	static_save = false,
	makes_footstep_sound = false,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 0.99,					-- portion of hitbox submerged
	max_speed = 7,                        
	jump_height = 2.5, --1.26,
	view_range = 7,
--	lung_capacity = 0, 		-- seconds
	max_hp = 20,
	timeout=300,
	drops = {
		{name = "default:diamond", chance = 5, min = 1, max = 5,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 2,},
	},
	attack={range=0.8,damage_groups={fleshy=7}},
	
	animation = {
		def={range={x=80,y=100},speed=20,loop=true},
		stand={range={x=80,y=100},speed=20,loop=false},
		walk={range={x=80,y=100},speed=20,loop=true},	
		swim={range={x=140,y=160},speed=20,loop=true},
		warn={range={x=1000,y=1320},speed=40,loop=true},
		bite={range={x=1350,y=1420},speed=20,loop=false},
		sleep={range={x=1504,y=2652},speed=20,loop=false},
		look={range={x=2660,y=2920},speed=20,loop=false},
		},

	sounds = {
		warn={
                name='water_life_snake',
                gain = water_life.soundadjust,
                }
		},                                  
	brainfunc = snake_brain,
	
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
			local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
			self.object:set_velocity({x=hvel.x,y=2,z=hvel.z})
			
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

			if type(puncher)=='userdata' and puncher:is_player() then	-- if hit by a player
				mobkit.clear_queue_high(self)							-- abandon whatever they've been doing
				if self.isinliquid then
					water_life.hq_water_attack(self,puncher,31,4,true)
				end
				if self.isonground then
					water_life.hq_hunt(self,31,puncher)
				end
			end
		end
	end,
                                             
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then return end
		local inv = clicker:get_inventory()
		local item = clicker:get_wielded_item()
		local name = clicker:get_player_name()
        
		if not item or (item:get_name() ~= "fireflies:bug_net" and item:get_name() ~= water_life.catchNet) then return end
		if not inv:room_for_item("main", "water_life:snake_item") then return end
                                            
		if random(1000) < 333 then
			inv:add_item("main", "water_life:snake_item")
			self.object:remove()
		else
			minetest.chat_send_player(name,"*** You missed the snake")
		end
	end,
})
