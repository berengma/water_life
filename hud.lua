
water_life.playerhud = {}
water_life.playerhud.poison = {}
water_life.playerhud.repellant = {}



water_life.hud_poison =   {
        
		hud_elem_type = "image",

		position = {x=0.5, y=0.8},
		-- Left corner position of element

		name = "water_life_poison",

		scale = {x = 0.1, y = 0.1},

		text = "water_life_emptyhud.png",
	

}



water_life.hud_repellant =   {
        hud_elem_type = "image",

        position = {x=0.55, y=0.8},
        -- Left corner position of element

        name = "water_life_repellant",

        scale = {x = 0.1, y = 0.1},

        text = "water_life_emptyhud.png",
}


function water_life.change_hud(player,selection,switch)
	local value = ""
	if not player then return end
	if not selection then selection = "poison" end
	if not switch then switch = 1 end
	
	
	local name = player:get_player_name()
	
	if selection == "poison" then
		if switch == 1 then value = "water_life_poison.png" else value = "water_life_emptyhud.png" end
		player:hud_change(water_life.playerhud.poison[name], "text", value)
	end
	
	if selection == "repellant" then
		if switch == 1 then value = "water_life_repellanthud.png" else value = "water_life_emptyhud.png" end
		player:hud_change(water_life.playerhud.repellant[name], "text", value)
	end
	
end



minetest.register_on_joinplayer(function(player)
		if not player then return end
                               
          local meta=player:get_meta()
		meta:set_int("repellant",0)                     
		local name = player:get_player_name()
                               
		water_life.playerhud.poison[name] = player:hud_add(water_life.hud_poison)
		water_life.playerhud.repellant[name] = player:hud_add(water_life.hud_repellant)
                               
		if meta:get_int("snakepoison") > 0 then
			minetest.after(5, function(player)
				water_life.change_hud(player,"poison")
			end, player)
		end
                               
end)


