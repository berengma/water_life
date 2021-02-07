
-- check for islands mod
if minetest.get_modpath("islands") then
	
	local bnames = water_life.get_biomes()
	water_life.spawn_on_islands = true
	
	if bnames then
		
		for i=1,#bnames,1 do
			local keep = string.match(bnames[i],"savanna") or string.match(bnames[i],"rainforest")
			if not keep then minetest.unregister_biome(bnames[i]) end
		end
	end
end




