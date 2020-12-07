
local abs = math.abs
local pi = math.pi
local floor = math.floor
local ceil = math.ceil
local sqrt = math.sqrt
local max = math.max
local min = math.min
local pow = math.pow
local sign = math.sign
local time = os.clock()
local rad = math.rad
local random = water_life.random
local deg=math.deg
local tan = math.tan
local cos = math.cos
local atan=math.atan


function water_life.init_bio(self)
	local dna =  water_life.make_dna()
	mobkit.remember(self,"wl_hunger",100)
	mobkit.remember(self,"wl_thirst",100)
	mobkit.remember(self,"wl_life",self.timeout)
	mobkit.remember(self,"wl_exhaust",100)
	mobkit.remember(self,"wl_horny",100)
	mobkit.remember(self,"wl_pregnant",-1)
	mobkit.remember(self,"wl_head",random(65535))
	mobkit.remember(self,"wl_headpos", nil)
	mobkit.remember(self,"wl_boss", 0)
	mobkit.remember(self,"wl_parent", 0)
	mobkit.remember(self,"wl_dna", dna)
end


function water_life.is_alive(self,change,set)
	if not self then return 0 end
	if not change then return mobkit.recall(self,"wl_life") or 1440 end
	if set then
		mobkit.remember(self,"wl_life", change)
		return 
	end
	change = (mobkit.recall(self,"wl_life") or 1440) + change
	mobkit.remember(self,"wl_life", change)
end


function water_life.is_parent(self,change)
	if not self then return 0 end
	if not change then return mobkit.recall(self,"wl_parent") or 0 end
	mobkit.remember(self,"wl_parent", change)
end


function water_life.is_boss(self,change)
	if not self then return 0 end
	if not change then return mobkit.recall(self,"wl_boss") or 0 end
	mobkit.remember(self,"wl_boss", change)
end


function water_life.dna(self,change)
	if not self then return nil end
	if not change then 
		local dna = mobkit.recall(self,"wl_dna")
		if dna then return dna end
		dna = water_life.make_dna()
		mobkit.remember(self,"wl_dna", dna)
		return dna
	end
	
	mobkit.remember(self,"wl_dna", change)
end
	

function water_life.headpos(self,change)
	if not self then return nil end
	if not change then
		local strg = mobkit.recall(self,"wl_headpos")
		if strg then
			return minetest.deserialize(strg)
		else
			return nil
		end
	end
	
	mobkit.remember(self,"wl_headpos", minetest.serialize(change))
end

	
function water_life.head(self)
	if not self then return 0 end
	local boss = mobkit.recall(self,"wl_head")
	if boss then
		return boss 
	else
		boss = random(65535)
		mobkit.remember(self,"wl_head",boss)
		return boss
	end
end


function water_life.hunger(self,change)
	if not self then return 0 end
	if not change then change = 0 end
	local hunger = mobkit.recall(self,"wl_hunger") or 100
	hunger = hunger + change
	if hunger < 0 then hunger = 0 end
	if hunger > 100 then hunger = 100 end
	mobkit.remember(self,"wl_hunger", hunger)
	return hunger
end


function water_life.exhaust(self,change)
	if not self then return 0 end
	if not change then change = 0 end
	local exhaust = mobkit.recall(self,"wl_exhaust") or 100
	exhaust = exhaust + change
	if exhaust < 0 then exhaust = 0 end
	if exhaust > 100 then exhaust = 100 end
	mobkit.remember(self,"wl_exhaust", exhaust)
	return exhaust
end

function water_life.thirst(self,change)
	if not self then return 0 end
	if not change then change = 0 end
	local thirst = mobkit.recall(self,"wl_thirst") or 100
	thirst = thirst + change
	if thirst < 0 then thirst = 0 end
	if thirst > 100 then thirst = 100 end
	mobkit.remember(self,"wl_thirst", thirst)
	return thirst
end


function water_life.horny(self,change)
	if not self then return 0 end
	if not change then change = 0 end
	local horny = mobkit.recall(self,"wl_horny") or 100
	horny = horny + change
	if horny < 0 then horny = 0 end
	if horny > 100 then horny = 100 end
	mobkit.remember(self,"wl_horny", horny)
	return horny
end


function water_life.pregnant(self,change)
	if not self then return -1 end
	if not change then return mobkit.recall(self,"wl_pregnant") or -1 end
	
	mobkit.remember(self,"wl_pregnant", change)
end


function water_life.make_dna(length)
	if not length then length=32 end
	local component = {"A","T","G","C"}
	local dna = ""
	
	for i = 1,length,1 do
		dna = dna..component[random(#component)]
	end
	
	return dna
end
		
	
	
