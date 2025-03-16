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
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.hq_die(self)
		return
	end
	if mobkit.timer(self,5) then
		local land = mobkit.recall(self,"landlife")
		local water = mobkit.recall(self,"waterlife")
		if land then
			land = math.floor(os.time() - land)
			if random(240,360) < land then
				water_life.hq_go2water(self, 5)
			end
		end
		if water then
			water = math.floor(os.time()-water)
			if random (60,120) < water then
				water_life.hq_go2land(self, 5)
			end
		end
	end
	if mobkit.timer(self,1) then
		if not mobkit.recall(self,"landlife") and 
			not mobkit.recall(self,"waterlife") then
				mobkit.remember(self,"waterlife", os.time())
		end
		if self.isinliquid then
			if mobkit.recall(self,"landlife") then
				mobkit.remember(self,"waterlife", os.time())
				mobkit.forget(self,"landlife")
			end
		end
		if self.isonground then
			if mobkit.recall(self,"waterlife") then
				mobkit.remember(self,"landlife", os.time())
				mobkit.forget(self,"waterlife")
			end
		end
		local prty = mobkit.get_queue_priority(self)
		if prty < 20 then 
			local target = mobkit.get_nearby_player(self)
			local aliveinwater = target and mobkit.is_alive(target)
				and mobkit.is_in_deep(target)
			if target and mobkit.is_alive(target) 
				and target:get_attach() == nil 
				and aliveinwater then
				local dist = water_life.dist2tgt(self,target)
				if dist < self.view_range then
					-- snakes do not attack when in water
				end
			end
			if self.isinliquid  and prty < 21 then
				water_life.hq_aqua_roam(self, 21, 1, "swim")
			end
			if self.isonground and prty < 30 then
				if target and mobkit.is_alive(target)  then
					local action = mobkit.recall(self,"warned")
					local pname = target:get_player_name()
					local dist = water_life.dist2tgt(self, target)
					if  dist > 4 and dist < self.view_range and not action then
						water_life.hq_snake_warn(self, target, 30, 8)
					else --if dist < 5 or action == pname then
						mobkit.forget(self, "warned")
						local meta = target:get_meta()
						if meta:get_int("snakepoison") > 0 or meta:get_int("bitten") > 0 then
							water_life.hq_snakerun(self, 31, target)
						else
							water_life.hq_hunt(self, 31, target)
						end
					end
				end
			end
		end
	end
	if mobkit.is_queue_empty_high(self) then
		if self.isinliquid then water_life.hq_aqua_roam(self, 21, 1, "swim") end
		if self.isonground then
			water_life.hq_snake_move(self, 10)
			water_life.hq_idle(self, 9, random(60,180), "sleep")
		end
	end
end

minetest.register_entity("water_life:snake",{
	initial_properties =
	{
		physical = true,
		stepheight = 1.1,
		collide_with_objects = true,
		collisionbox = {-0.35, -0.01, -0.35, 0.35, 0.2, 0.35},
		visual = "mesh",
		mesh = "water_life_snake.b3d",
		textures = {"water_life_snake.png"},
		visual_size = {x = 0.05, y = 0.05},
		static_save = false,
		makes_footstep_sound = false
	},
	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	springiness=0,
	buoyancy = 0.99,
	max_speed = 7,                        
	jump_height = 2.5,
	view_range = 7,
	max_hp = 20,
	timeout=-60,
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
			if water_life.bloody then water_life.spilltheblood(self.object) end
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)
			if type(puncher)=='userdata' and puncher:is_player() then
				mobkit.clear_queue_high(self)
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
		if not clicker or not clicker:is_player() then
			return
		end
		local inv = clicker:get_inventory()
		local item = clicker:get_wielded_item()
		local name = clicker:get_player_name()
		local meta = clicker:get_meta()
		local snakeCount = meta:get_int("snakecount")

		if not item or (item:get_name() ~= "fireflies:bug_net" 
			and item:get_name() ~= water_life.catchNet) then
				return
		end
		if not inv:room_for_item("main", "water_life:snake_item") then
			if snakeCount < 666 then
				meta:set_int("snakecount", snakeCount + 1)
			end
			return
		end
		if random(1000) < 333 + snakeCount then
			inv:add_item("main", "water_life:snake_item")
			self.object:remove()
			if snakeCount < 666 then
				meta:set_int("snakecount", snakeCount + 1)
			end
		else
			minetest.chat_send_player(name,"*** You missed the snake")
		end
	end,
})
