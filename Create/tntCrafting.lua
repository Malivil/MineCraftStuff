local sandPlace = 1
local sandCount = 4
local gunpowderPlace = 2
local gunpowderCount = 5
local currentCount = 0
 
local function getSupply(count, name, fn)
    -- don't bother getting more if we have enough
    if turtle.getItemCount() >= count then return true end
 
    if not (fn or turtle.suck)(count) then
        print("Failed to pick up " .. name .. ", please check pathing and shelf access.")
        return false
    end
 
    if turtle.getItemCount() < count then
        print("Not enough " .. name .. " to continue crafting. Please resupply shelves.")
        return false
    end
    return true
end
 
while (true) do
-- sand
    turtle.select(sandPlace)
    while not getSupply(sandCount, "Sand", turtle.suckUp) do
        sleep(30)
    end
    currentCount = turtle.getItemCount()
    if currentCount > sandCount then
        turtle.dropUp(currentCount - sandCount)
    end
-- gunpowder
    turtle.select(gunpowderPlace)
    while not getSupply(gunpowderCount, "Gunpowder", turtle.suckDown) do
        sleep(30)
    end
    currentCount = turtle.getItemCount()
    if currentCount > gunpowderCount then
        turtle.dropDown(currentCount - gunpowderCount)
    end
-- place sand
    turtle.select(sandPlace)
    turtle.transferTo(7, 1)
    turtle.transferTo(10, 1)
    turtle.transferTo(12, 1)
    turtle.transferTo(15, 1)
-- place gunpowder
    turtle.select(gunpowderPlace)
    turtle.transferTo(6, 1)
    turtle.transferTo(8, 1)
    turtle.transferTo(11, 1)
    turtle.transferTo(14, 1)
    turtle.transferTo(16, 1)
-- craft
    turtle.craft()
    turtle.drop()
end
 
print("Crafting terminated")