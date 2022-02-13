local enderDustPlace = 1
local enderDustCount = 0
local singularityPlace = 2
local singularityCount = 25
local tntPlace = 3
local tntCount = 1
local qeSingularityPlace = 4
local commonCount = 0

local function getSupply(count, name, fn)
    -- don't bother getting more if we have enough
    if count and turtle.getItemCount() >= count then return true end

    if not (fn or turtle.suck)(count) then
        print("Failed to pick up " .. name .. ", please check pathing and shelf access.")
        return false
    end

    if count and turtle.getItemCount() < count then
        print("Not enough " .. name .. " to continue crafting. Please resupply shelves.")
        return false
    end
    return true
end

local function waitDrop(name, fn)
    while not (fn or turtle.drop)() do
        print("Cannot drop " .. name .. ". Waiting 1 second and trying again.")
        sleep(1)
    end
end

while (true) do
-- singularity
    turtle.select(singularityPlace)
    if turtle.getItemCount() > 0 then
        turtle.drop()
    end
    while not getSupply(singularityCount, "Singularity") do
        sleep(30)
    end
    singularityCount = turtle.getItemCount()
    turtle.turnRight()
-- ender dust
	turtle.select(enderDustPlace)
    if turtle.getItemCount() > 0 then
        turtle.drop()
    end
    while not getSupply(nil, "Ender Dust") do
        sleep(30)
    end
    enderDustCount = turtle.getItemCount()
    turtle.turnRight()
-- tnt
    turtle.select(tntPlace)
    while not getSupply(tntCount, "TNT") do
        sleep(30)
    end
    turtle.turnRight()
-- determine drop count
    commonCount = math.min(enderDustCount, singularityCount)
-- drop
    turtle.select(enderDustPlace)
    turtle.dropDown(commonCount)
    turtle.select(singularityPlace)
    turtle.dropDown(commonCount)
    turtle.select(tntPlace)
    turtle.placeDown(tntCount)
    turtle.turnRight()
-- qe singularity
    turtle.select(qeSingularityPlace)
    sleep(5)
    while not turtle.suckDown() do
        print("No QE Singularities found. Waiting 5 seconds and trying again...")
        sleep(5)
    end
    waitDrop("QE Singularities", turtle.dropUp)
-- pick up all of them
    while turtle.suckDown() do
        waitDrop("QE Singularities", turtle.dropUp)
    end
-- wait a bit so the next step has time to run
   sleep(60)
end

print("Crafting terminated")