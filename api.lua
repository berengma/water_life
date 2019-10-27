 



function water_life.handle_drops(self)
    if not self.drops then return end
    
    for _,item in ipairs(self.drops) do
        
        local amount = math.random (item.min, item.max)
        local chance = math.random(1,100) 
        local pos = self.object:get_pos()
        pos.x = pos.x + math.random(-1,1)
        pos.z = pos.z + math.random(-1,1)
        
        if chance < (100/item.chance) then
            minetest.add_item(pos, item.name.." "..tostring(amount))
        end
        
    end
end


function water_life.register_shark_food(name)
    table.insert(water_life.shark_food,name)
end


function water_life.feed_shark()
    local index = math.random(1,#water_life.shark_food)
    return water_life.shark_food[index]
end
