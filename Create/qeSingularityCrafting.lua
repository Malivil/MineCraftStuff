local enderDustPlace = 1
local enderDustCount = 0
local singularityPlace = 2
local singularityCount = 0
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

while (true) do
-- singularity
    turtle.select(singularityPlace)
    if singularityCount > 0 then
        turtle.drop()
    end
    while not getSupply(nil, "Singularity", turtle.suckDown) do
        sleep(30)
    end
    singularityCount = turtle.getItemCount()
    turtle.turnRight()
-- ender dust
	turtle.select(enderDustPlace)
    if enderDustCount > 0 then
        turtle.drop()
    end
    while not getSupply(nil, "Ender Dust", turtle.suckUp) do
        sleep(30)
    end
    enderDustCount = turtle.getItemCount()
    turtle.turnRight()
-- tnt
    turtle.select(tntPlace)
    while not getSupply(tntCount, "TNT", turtle.suckDown) do
        sleep(30)
    end
    turtle.turnRight()
-- determine drop count
    commonCount = math.min(enderDustCount, singularityCount)
-- subtract from the amount picked so we don't overfill next loop
    enderDustCount = enderDustCount - commonCount
    singularityCount = singularityCount - commonCount
-- drop
	turtle.select(enderDustPlace)
    turtle.placeDown(commonCount)
	turtle.select(singularityPlace)
    turtle.placeDown(commonCount)
	--turtle.select(tntPlace)
    --turtle.placeDown(tntCount)
    turtle.turnRight()
-- qe singularity
    turtle.select(qeSingularityPlace)
    while not turtle.suckDown() do
        print("No QE Singularities found. Waiting 5 seconds and trying again...")
        sleep(5)
    end
    turtle.dropUp()
end

print("Crafting terminated")