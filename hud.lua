
water_life.playerhud = {}


water_life.hud =   {
	{
		hud_elem_type = "text",

		position = {x=0.5, y=0.8},
		-- Left corner position of element

		name = "water_life_poison.png",

		scale = {x = 0.1, y = 0.1},

		text = "water_life_poison.png"},
	
	--[[{
		hud_elem_type = "image",

		position = {x=0.55, y=0.8},
		-- Left corner position of element

		name = "water_life_repellant",

		scale = {x = 0.1, y = 0.1},

		text = "water_life_repellanthud.png"},]]
}



function water_life.change_hud(player,selection)
end



minetest.register_on_joinplayer(function(player)

		if not player then return end
		local name = player:get_player_name()
		water_life.playerhud[name] = player:hud_add(water_life.hud)
end)
