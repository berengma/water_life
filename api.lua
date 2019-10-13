 



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
