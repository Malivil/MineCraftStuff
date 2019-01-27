---------------
-- Constants --
---------------

local MODEM_SIDE = "top"
local SCREEN_SIDE = "right"

local MODEM_CHANNELS = {1,2,3,4}

local REACTOR_LIST = {}

--------------------
-- Helper Methods --
--------------------

-- Checks if the modem exists and can connect to the correct channel
function checkModem(modem)
    if (modem == nil) then
        error("Failed to connect to modem")
        return
    end

    -- Try to open the channel
    for i, channel in ipairs(MODEM_CHANNELS) do
        if (not modem.isOpen(channel)) then
            modem.open(channel)
        end

        -- If it still isn't connected, something is broken
        if (not modem.isOpen(channel)) then
            error("Failed to open modem connection on channel " .. channel)
        end
    end
end

function checkMonitor(monitor)
    if (monitor == nil) then
        error("Failed to connect to monitor")
    end
end

-------------------
-- Write Methods --
-------------------

function writeCentered(monitor, text, color, line)
    checkMonitor(monitor)
    local monitorXMax, _ = monitor.getSize()
    local x = math.ceil((monitorXMax / 2) - (text:len() / 2))
    monitor.setCursorPos(x, line)
    monitor.setTextColor(color)
    monitor.write(text)
end

function writeLabel(monitor, label, line)
    checkMonitor(monitor)
    monitor.setTextColor(colors.white)
    monitor.setCursorPos(1, line)
    monitor.write(label)
end

function writeValue(monitor, value, color)
    checkMonitor(monitor)
    monitor.setTextColor(color)
    monitor.write(tostring(value))
end

function percent(num, denom)
    if (denom < 0 or denom == 0) then
        return 0
    end
    return math.floor((num / denom) * 100)
end

function writeBoolean(monitor, value)
    local color = colors.green
    if (value == false) then
        color = colors.red
    end
    writeValue(monitor, value, color)
end

---------------------------
-- Reactor Count Methods --
---------------------------

function getReactorCount()
    local count = 0
    for _ in pairs(REACTOR_LIST) do
        count = count + 1
    end
    return count
end

function getActiveReactorCount()
    local count = 0
    for _, reactor in pairs(REACTOR_LIST) do
        if (reactor.isActive) then
            count = count + 1
        end
    end
    return count
end

function getInactiveReactorCount()
    local count = 0
    for _, reactor in pairs(REACTOR_LIST) do
        if (not reactor.isActive) then
            count = count + 1
        end
    end
    return count
end

-------------------
-- Stats Methods --
-------------------

function getCurrentEnergy()
    local total = 0
    for _, reactor in pairs(REACTOR_LIST) do
        total = total + reactor.energy.current
    end
    return total
end

function getTotalEnergy()
    local total = 0
    for _, reactor in pairs(REACTOR_LIST) do
        total = total + reactor.energy.capacity
    end
    return total
end

function getEnergyLastTick()
    local total = 0
    for _, reactor in pairs(REACTOR_LIST) do
        total = total + reactor.energy.lastTick
    end
    return total
end

function getFuelTemperature()
    local total = 0
    for _, reactor in pairs(REACTOR_LIST) do
        if (reactor.isActive) then
            total = total + reactor.temp.fuel
        end
    end
    return math.ceil(total)
end

function getCaseTemperature()
    local total = 0
    for _, reactor in pairs(REACTOR_LIST) do
        if (reactor.isActive) then
            total = total + reactor.temp.case
        end
    end
    return math.ceil(total)
end

function getCurrentFuel()
    local total = 0
    for _, reactor in pairs(REACTOR_LIST) do
        if (reactor.isActive) then
            total = total + reactor.fuel.current
        end
    end
    return total
end

function getMaxFuel()
    local total = 0
    for _, reactor in pairs(REACTOR_LIST) do
        if (reactor.isActive) then
            total = total + reactor.fuel.max
        end
    end
    return total
end

function getCurrentWaste()
    local total = 0
    for _, reactor in pairs(REACTOR_LIST) do
        if (reactor.isActive) then
            total = total + reactor.fuel.waste
        end
    end
    return total
end

--------------------
-- Event Handlers --
--------------------

function checkReactor(monitor, modem)
    -- Make sure we're still connected
    checkModem(modem)
    checkMonitor(monitor)

    local isMultiple = false
    local line = 1
    local _, _, _,  _, stats, _ = os.pullEvent("modem_message")
    monitor.clear()

    if (tonumber(stats.reactorId)) then
        REACTOR_LIST[stats.reactorId] = stats
        isMultiple = getReactorCount() > 1
    end
    
    writeCentered(monitor, "Reactor Status", colors.white, line)
    line = line + 1

    if (isMultiple == true) then
        writeLabel(monitor, "Active #: ", line)
        writeValue(monitor, getActiveReactorCount(), colors.green)
        writeValue(monitor, " Inctive #: ", line, colors.white)
        writeValue(monitor, getInactiveReactorCount(), colors.red)
    else
        writeLabel(monitor, "Is Active: ", line)
        writeBoolean(monitor, stats.isActive)
    end
    line = line + 2
    
    writeLabel(monitor, "Energy: ", line)
    writeValue(monitor, getCurrentEnergy() .. "/" .. getTotalEnergy() .. " (" .. percent(getCurrentEnergy(), getTotalEnergy()) .. "%)", colors.lightGray)
    line = line + 1
    
    writeLabel(monitor, "RF/t: ", line)
    writeValue(monitor, getEnergyLastTick(), colors.lightGray)
    line = line + 2
    
    writeLabel(monitor, "Fuel Temp: ", line)
    writeValue(monitor, getFuelTemperature() .. "C", colors.lightGray)
    line = line + 1
    
    writeLabel(monitor, "Casing Temp: ", line)
    writeValue(monitor, getCaseTemperature() .. "C", colors.lightGray)
    line = line + 2
    
    local currentFuel = getCurrentFuel()
    writeLabel(monitor, "Fuel Remaining: ", line)
    writeValue(monitor, currentFuel .. "mB", colors.lightGray)
    line = line + 1
    
    local currentWaste = getCurrentWaste()
    writeLabel(monitor, "Waste: ", line)
    writeValue(monitor, currentWaste .. "mB", colors.lightGray)
    line = line + 1
    
    local totalFuel = currentFuel + currentWaste
    local maxFuel = getMaxFuel()
    writeLabel(monitor, "Storage: ", line)
    writeValue(monitor, totalFuel .. "/" .. maxFuel .. " (" .. percent(totalFuel, maxFuel) .. "%)", colors.lightGray)
    line = line + 2
end

function run()
    -- Modem
    local modem = peripheral.wrap(MODEM_SIDE)
    checkModem(modem)

    -- Monitor
    local monitor = peripheral.wrap(SCREEN_SIDE)
    checkMonitor(monitor)
    monitor.clear()

    while true do
        checkReactor(monitor, modem)
    end
end

-- Run the actual program
run()