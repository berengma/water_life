


local abr = minetest.get_mapgen_setting('active_block_range')
local abo = minetest.get_mapgen_setting('active_object_send_range_blocks')
local nodename_water = minetest.registered_aliases.mapgen_water_source
local maxwhales = 1 -- (2 ^ (abo -1)) + 2

local abs = math.abs
local pi = math.pi
local floor = math.floor
local random = math.random
local sqrt = math.sqrt
local max = math.max
local min = math.min
local pow = math.pow
local sign = math.sign

local time = os.time

local spawn_rate = 1 - max(min(minetest.settings:get('whale_spawn_chance') or 0.6,1),0)
local spawn_reduction = minetest.settings:get('whale_spawn_reduction') or 0.4



-- count whales at position
local function count_whales(pos)

local all_objects = minetest.get_objects_inside_radius(pos, abo * 16)
local whales = 0
local _,obj
for _,obj in ipairs(all_objects) do
    local entity = obj:get_luaentity()
	if entity and entity.name == "water_life:whale" then
		whales = whales +1
	end
end
return whales
end



local function whale_brain(self)
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
		mobkit.hq_die(self)
		return
	end
	
	if mobkit.is_queue_empty_high(self) then mobkit.hq_aqua_roam(self,20,-1) end
end
-- spawning is too specific to be included in the api, this is an example.
-- a modder will want to refer to specific names according to games/mods they're using 
-- in order for mobs not to spawn on treetops, certain biomes etc.

local function spawnstep(dtime)

	for _,plyr in ipairs(minetest.get_connected_players()) do
		if random()<dtime*0.2 then	-- each player gets a spawn chance every 5s on average
			local vel = plyr:get_player_velocity()
			local spd = vector.length(vel)
			local chance = spawn_rate * 1/(spd*0.75+1)  -- chance is quadrupled for speed=4
			local yaw
			if spd > 1 then
				-- spawn in the front arc
				yaw = minetest.dir_to_yaw(vel) + random()*0.35 - 0.75
			else
				-- random yaw
				yaw = random()*pi*2 - pi
			end
			local pos = plyr:get_pos()
			local dir = vector.multiply(minetest.yaw_to_dir(yaw),abr*16)
			local pos2 = vector.add(pos,dir)
			pos2.y=pos2.y-5
			local height, liquidflag = mobkit.get_terrain_height(pos2,32)
            
            if not liquidflag then return end
	
			if height and mobkit.nodeatpos({x=pos2.x,y=height-0.01,z=pos2.z}).is_ground_content then

				local objs = minetest.get_objects_inside_radius(pos,abr*16+5)
				local wcnt=0
				local dcnt=0
				local mobname = 'water_life:whale'
				if liquidflag then		-- whales
					local spnode = mobkit.nodeatpos({x=pos2.x,y=height+0.01,z=pos2.z})
					local spnode2 = mobkit.nodeatpos({x=pos2.x,y=height+1.01,z=pos2.z}) -- node above to make sure won't spawn in shallows
					nodename_water = nodename_water or minetest.registered_aliases.mapgen_water_source
					if spnode and spnode2 and spnode.name == nodename_water and spnode2.name == nodename_water then
						
					mobname = 'water_life:whale'
					else
						return
					end
					
				
				end
				if chance < random() then
					pos2.y = height+1.01
					objs = minetest.get_objects_inside_radius(pos2,abr*16-2)
					for _,obj in ipairs(objs) do				-- do not spawn if another player around
						if obj:is_player() then return end
					end
                    local a=pos2.x
                    local b=pos2.y
                    local c=pos2.z
                    
                    local water = minetest.find_nodes_in_area({x=a-5, y=b-5, z=c-5}, {x=a+5, y=b+5, z=c+5}, {"default:water_source"})
                    
                    if #water < 800 then return end    -- whales need water, much water
                    local ms = count_whales(pos)
                    local mw = count_whales(pos2)
                    --minetest.chat_send_all("Maxwhales = "..maxwhales.."  counted: "..ms.." - "..mw.." abo="..abo.." abr="..abr)
                    if ms > (maxwhales-1) then return end  -- whales are no sardines

                    local obj=minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
				end
			end
		end
	end
end




minetest.register_entity("water_life:whale",{
											-- common props
	physical = true,
	stepheight = 0.1,				--EVIL!
	collide_with_objects = true,
	collisionbox = {-3, -2, -3, 3, 2, 3},
	visual = "mesh",
	mesh = "whale.b3d",
	textures = {"water_life_whale.png"},
	visual_size = {x = 3.5, y = 3.5},
	static_save = true,
	makes_footstep_sound = true,
	on_step = mobkit.stepfunc,	-- required
	on_activate = mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 0.98,					-- portion of hitbox submerged
	max_speed = -1,                        -- no matter which number is here, whales always at same speed
	jump_height = 1.26,
	view_range = 32,
--	lung_capacity = 0, 		-- seconds
	max_hp = 500,
	timeout=300,
	attack={range=1.5,damage_groups={fleshy=15}},
	sounds = {
      random = "whale_1",
      death = "whale_1",
      distance = 128,
	},
    
	animation = {
		def={range={x=1,y=59},speed=5,loop=true},	
		fast={range={x=1,y=59},speed=20,loop=true},
		back={range={x=15,y=1},speed=7,loop=false},
		},
	
	brainfunc = whale_brain,
    
    on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
			local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
			self.object:set_velocity({x=hvel.x,y=2,z=hvel.z})
			
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

			if type(puncher)=='userdata' and puncher:is_player() then	-- if hit by a player
				mobkit.clear_queue_high(self)							-- abandon whatever they've been doing
				mobkit.hq_aqua_attack(self,20,puncher,-3)				-- get revenge
			end
		end
	end,
	
})

minetest.register_globalstep(spawnstep)


--[[

mobs:register_mob("dmobs:whale", {
	type = "animal",
	passive = false,
	reach = 1,
	damage = 2,
	attack_type = "dogfight",
	hp_min = 52,
	hp_max = 82,
	armor = 230,
	collisionbox = {-0.9, -1.2, -0.9, 0.9, 0.9, 0.9},
	visual = "mesh",
	mesh = "whale.b3d",
	textures = {
		{"dmobs_whale.png"},
	},
	blood_texture = "mobs_blood.png",
	visual_size = {x=2.5, y=2.5},
	makes_footstep_sound = true,
	walk_velocity = 0.5,
	run_velocity = 1,
	jump = false,	
	stepheight = 1.5,
	fall_damage = 0,
	fall_speed = -6,
	fly = true,
	fly_in = "default:water_source",
	water_damage = 0,
	lava_damage = 2,
	light_damage = 0,
	follow = {"fishing:fish_cooked"},
	view_range = 14,
	drops = {
		{name = "mobs:meat_raw", chance = 1, min = 10, max = 25},
	},
	sounds = {
      random = "whale_1",
      death = "whale_1",
      distance = 128,
	},
	animation = {
		speed_normal = 5,
		speed_run = 10,
		walk_start = 2,
		walk_end = 39,
		stand_start = 2,
		stand_end = 39,
		run_start = 2,
		run_end = 39,

	},
	on_rightclick = function(self, clicker)

		if mobs:feed_tame(self, clicker, 8, true, true) then
			return
		end

		mobs:capture_mob(self, clicker, 0, 5, 50, false, nil)
	end,
})

mobs:register_spawn("dmobs:whale", {"default:water_source"}, 20, 0, 25000, 5, -2)

mobs:register_egg("dmobs:whale", "Whale", "default_water_source.png", 1)
]]
