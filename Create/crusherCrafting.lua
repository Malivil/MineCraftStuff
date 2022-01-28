local stonePlace = 16
local stoneCount = 16
local stickPlace = 15
local stickCount = 5
local fuelPlace = 14
local fuelCount = 10
local minFuel = 35

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

local function checkFuel()
    if turtle.getFuelLevel() < minFuel then
        print("Not enough fuel to continue crafting. Please add fuel to shelf and turtle and call turtle.refuel() on correct inventory slot.")
        return false
    end
    return true
end

while (checkFuel()) do
-- cobble
	turtle.select(stonePlace)
    if not getSupply(stoneCount, "Cobblestone") then
        break
    end
-- go get sticks
    turtle.turnLeft()
    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
-- sticks
    turtle.select(stickPlace)
    -- if we don't have enough sticks, return to the beginning
    if not getSupply(stickCount, "Sticks") then
        turtle.turnRight()
        turtle.forward()
        turtle.forward()
        turtle.forward()
        turtle.forward()
        turtle.turnLeft()
        break
    end
-- start placing
    turtle.select(stonePlace)
    turtle.up()
    turtle.drop(1)
    turtle.up()
    turtle.drop(1)
    turtle.up()
    turtle.drop(1)
    turtle.up()
-- move to next column
    turtle.turnRight()
    turtle.forward()
    turtle.turnLeft()
-- place row 2
    turtle.drop(1)
    turtle.down()
    turtle.drop(1)
    turtle.down()
    turtle.select(stickPlace)
    turtle.drop(1)
    turtle.down()
    turtle.select(stonePlace)
    turtle.drop(1)
    turtle.down()
    turtle.drop(1)
-- move to next column
    turtle.turnRight()
    turtle.forward()
    turtle.turnLeft()
-- place row 3
    turtle.drop(1)
    turtle.up()
    turtle.select(stickPlace)
    turtle.drop(1)
    turtle.up()
    turtle.drop(1)
    turtle.up()
    turtle.drop(1)
    turtle.up()
    turtle.select(stonePlace)
    turtle.drop(1)
-- move to next row
    turtle.turnRight()
    turtle.forward()
    turtle.turnLeft()
-- place row 4
    turtle.drop(1)
    turtle.down()
    turtle.drop(1)
    turtle.down()
    turtle.select(stickPlace)
    turtle.drop(1)
    turtle.down()
    turtle.select(stonePlace)
    turtle.drop(1)
    turtle.down()
    turtle.drop(1)
-- move to next column
    turtle.turnRight()
    turtle.forward()
    turtle.turnLeft()
-- place column 5
    turtle.up()
    turtle.drop(1)
    turtle.up()
    turtle.drop(1)
    turtle.up()
    turtle.drop(1)
-- pickup fuel
    turtle.up()
    turtle.select(fuelPlace)
    turtle.select(fuelCount)
    turtle.refuel()
-- return to beginning
    turtle.down()
    turtle.down()
    turtle.down()
    turtle.down()
-- wait for the craft to finish
    sleep(5)
end

print("Crafting terminated")