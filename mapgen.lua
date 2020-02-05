
if minetest.registered_biomes["rainforest"] then
	
	local rainforest = minetest.registered_biomes["rainforest"]
	rainforest.node_river_water = "water_life:muddy_river_water_source"
	rainforest.node_riverbed = "default:dirt"
	rainforest.depth_riverbed = 2
	rainforest.node_water_top = "water_life:muddy_river_water_source"
	rainforest.depth_water_top = 10
	minetest.unregister_biome("rainforest")
	minetest.register_biome(rainforest)
end



if minetest.registered_biomes["rainforest_ocean"] then
	
	local rainforest = minetest.registered_biomes["rainforest_ocean"]
	rainforest.node_river_water = "water_life:muddy_river_water_source"
	rainforest.node_riverbed = "default:dirt"
	rainforest.depth_riverbed = 2
	rainforest.node_water_top = "water_life:muddy_river_water_source"
	rainforest.depth_water_top = 10
	minetest.unregister_biome("rainforest_ocean")
	minetest.register_biome(rainforest)
end



if minetest.registered_biomes["rainforest_swamp"] then
	
	local rainforest = minetest.registered_biomes["rainforest_swamp"]
	rainforest.node_river_water = "water_life:muddy_river_water_source"
	rainforest.node_riverbed = "default:dirt"
	rainforest.depth_riverbed = 2
	rainforest.node_water_top = "water_life:muddy_river_water_source"
	rainforest.depth_water_top = 10
	minetest.unregister_biome("rainforest_swamp")
	minetest.register_biome(rainforest)
end



if minetest.registered_biomes["savanna"] then
	
	local savanna = minetest.registered_biomes["savanna"]
	savanna.node_river_water = "water_life:muddy_river_water_source"
	savanna.node_riverbed = "default:sand"
	savanna.depth_riverbed = 2
--	savanna.node_water_top = "water_life:muddy_river_water_source"
--	savanna.depth_water_top = 10
	minetest.unregister_biome("savanna")
	minetest.register_biome(savanna)
end


