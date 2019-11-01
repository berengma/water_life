

-- raw meat
minetest.register_craftitem("water_life:meat_raw", {
	description = ("Raw Meat"),
	inventory_image = "water_life_meat_raw.png",
	on_use = minetest.item_eat(3),
	groups = {food_meat_raw = 1, flammable = 2}
})

-- cooked meat
minetest.register_craftitem("water_life:meat", {
	description = ("Meat"),
	inventory_image = "water_life_meat.png",
	on_use = minetest.item_eat(8),
	groups = {food_meat = 1, flammable = 2}
})

minetest.register_craft({
	type = "cooking",
	output = "water_life:meat",
	recipe = "water_life:meat_raw",
	cooktime = 5
})
