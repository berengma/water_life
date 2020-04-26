
local abs = math.abs
local pi = math.pi
local floor = math.floor
local random = water_life.random
local sqrt = math.sqrt
local max = math.max
local min = math.min
local pow = math.pow
local sign = math.sign

-- this is whale specific, so keeping it local
local function chose_turn(self,a,b)
    
	local remember = mobkit.recall(self,"turn")
	if not remember then
		if water_life.leftorright() then
			remember = "1"
			mobkit.remember(self,"time", self.time_total)
			mobkit.remember(self,"turn", "1")
		else
			remember = "0"
			mobkit.remember(self,"time", self.time_total)
			mobkit.remember(self,"turn", "0")
		end
	end
    
	if a > b+15 then 
		mobkit.remember(self,"turn", "1")
		mobkit.remember(self,"time", self.time_total)
		return false
        
	elseif a < b-15 then
		mobkit.remember(self,"turn","0")
		mobkit.remember(self,"time", self.time_total)
		return true
        
	else 
        
		if remember == "0" then return true else return false end
    
	end
end
    


-- The Brain  !
local function whale_brain(self)
    
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
		water_life.handle_drops(self)
		mobkit.make_sound(self,"death")
		mobkit.hq_die(self)
		return
	end
    
    -- check every 2 seconds what is under whale's belly
	if mobkit.timer(self,2) then
		local stand = mobkit.get_stand_pos(self)
		if stand then stand.y = stand.y - 1 end
            
		local node = mobkit.nodeatpos(stand)
		if node and minetest.registered_nodes[node.name] then 
			if minetest.registered_nodes[node.name]["liquidtype"] == "none" then
				mobkit.hurt(self, 20)
			end
		end
	end
    
    
    -- big animals need to avoid obstacles
    
    
	if mobkit.timer(self,1) then
		local remember = mobkit.recall(self,"time")
		if remember then
			if self.time_total - remember > 59 then
				mobkit.forget(self,"turn")
				mobkit.forget(self,"time")
                
			end
		end
		local yaw =  self.object:get_yaw() + pi
		local pos = mobkit.get_stand_pos(self)
        
		local kiri, kanan = water_life.radar(pos,yaw,25)
        
		local hpos = mobkit.pos_translate2d(pos,yaw,6)
		local head = mobkit.pos_shift(hpos,{y=4})
		local node = minetest.get_node(head)
        
		yaw = yaw - pi
        
		if node and minetest.registered_nodes[node.name] then -- anything above head ? dive.
            
			if minetest.registered_nodes[node.name]["liquidtype"] == "none" and node.name  ~= "air" then
				local hvel = vector.multiply(vector.normalize({x=head.x,y=0,z=head.z}),4)
				self.object:set_velocity({x=hvel.x,y=-1,z=hvel.z})
			end
		end
        
		if kiri > 3 or kanan > 3 then
			mobkit.clear_queue_high(self)
			if chose_turn(self,kiri,kanan) then
				water_life.big_hq_aqua_turn(self,30,yaw+(pi/24),-0.5)
			else
				water_life.big_hq_aqua_turn(self,30,yaw-(pi/24),-0.5)
			end
		end
        
	end
        
    
	if mobkit.is_queue_empty_high(self) then water_life.big_aqua_roam(self,20,-1) end
    
end


        
minetest.register_entity("water_life:whale",{
											-- common props
	physical = true,
	stepheight = 0.1,				--EVIL!
    	weight = 250,
	collide_with_objects = true,
	collisionbox = {-2, -2, -2, 2, 2, 2},
	visual = "mesh",
	mesh = "water_life_whale.b3d",
	textures = {"water_life_whale.png"},
	visual_size = {x = 3.5, y = 3.5},
    drops = {
		{name = "default:diamond", chance = 5, min = 10, max = 50,},		
		{name = "water_life:meat_raw", chance = 1, min = 15, max = 65,},
	},
	static_save = false,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 0.98,					-- portion of hitbox submerged
	max_speed = -1,                        
	jump_height = 1.26,
	view_range = 32,
--	lung_capacity = 0, 		-- seconds
	max_hp = 500,
	timeout=300,
	attack={range=4.5,damage_groups={fleshy=15}},
	sounds = {
      random = "water_life_whale.ogg",
      death = "water_life_whale.ogg",
      distance = 10,
	},
    
	animation = {
		def={range={x=1,y=59},speed=5,loop=true},	
		fast={range={x=1,y=59},speed=20,loop=true},
		back={range={x=15,y=1},speed=7,loop=false},
		},
	
	brainfunc = whale_brain,
    
    on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
			local pos = mobkit.get_stand_pos(self)
			local yaw =  self.object:get_yaw() + pi
			local obj = self.object
			local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
			local left, right, up, down, under, above = water_life.radar(pos, yaw)
			local attach = puncher:get_attach()
                                             
			if attach and random(100) > (self.hp/5) then
				puncher:set_detach()
			end

			if under > 6 then
				self.object:set_velocity({x=hvel.x,y=-2,z=hvel.z})
				self.object:add_velocity({x=0,y=-3, z=0})
			end
			
			if time_from_last_punch > 2 then
				mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)
			else
				if puncher:is_player() then
					minetest.chat_send_player(puncher:get_player_name(),">>> You missed <<<")
				end
			end
			
			
			obj:set_nametag_attributes({
				color = '#ff7373',
				text = ">>> "..tostring(math.floor(self.hp/5)).."% <<<",
				})
		end
	end,
	
})


