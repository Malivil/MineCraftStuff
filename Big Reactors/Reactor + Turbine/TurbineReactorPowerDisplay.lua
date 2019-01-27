---------------
-- Constants --
---------------

local MODEM_CHANNEL = 3

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
    if (not modem.isOpen(MODEM_CHANNEL)) then
        modem.open(MODEM_CHANNEL)
    end

    -- If it still isn't connected, something is broken
    if (not modem.isOpen(MODEM_CHANNEL)) then
        error("Failed to open modem connection on channel " .. MODEM_CHANNEL)
    end
end

function checkMonitor(monitor)
    if (monitor == nil) then
        error("Failed to connect to monitor")
    end
end

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

function checkReactor(monitor, modem)
    -- Make sure we're still connected
    checkModem(modem)
    checkMonitor(monitor)

    local line = 1
    local _, _, _,  _, stats, _ = os.pullEvent("modem_message")
    monitor.clear()

    writeCentered(monitor, "Turbine / Reactor Status", colors.white, line)
    line = line + 1

    writeLabel(monitor, "Is Active: ", line)
    writeBoolean(monitor, stats.isActive)
    line = line + 2
    
    writeLabel(monitor, "Energy: ", line)
    writeValue(monitor, math.floor(stats.energy.current) .. "/" .. stats.energy.capacity .. " (" .. percent(stats.energy.current, stats.energy.capacity) .. "%)", colors.lightGray)
    line = line + 1
    
    writeLabel(monitor, "RF/t: ", line)
    writeValue(monitor, stats.energy.lastTick, colors.lightGray)
    line = line + 2
    
    writeLabel(monitor, "Rotor Speed: ", line)
    writeValue(monitor, math.floor(stats.rotor.current) .. "RPM", colors.lightGray)
    line = line + 1
    
    writeLabel(monitor, "Steam mB/t: ", line)
    writeValue(monitor, stats.steam.lastTick, colors.lightGray)
    line = line + 2
    
    writeLabel(monitor, "Fuel Remaining: ", line)
    writeValue(monitor, stats.fuel.current .. "mB", colors.lightGray)
    line = line + 1
    
    writeLabel(monitor, "Waste: ", line)
    writeValue(monitor, stats.fuel.waste .. "mB", colors.lightGray)
    line = line + 1
    
    local totalFuel = stats.fuel.current + stats.fuel.waste
    writeLabel(monitor, "Storage: ", line)
    writeValue(monitor, totalFuel .. "/" .. stats.fuel.max .. " (" .. percent(totalFuel, stats.fuel.max) .. "%)", colors.lightGray)
    line = line + 2
end

function run()
    -- Modem
    local modem = peripheral.wrap("back")
    checkModem(modem)

    -- Monitor
    local monitor = peripheral.wrap("right")
    checkMonitor(monitor)

    while true do
        checkReactor(monitor, modem)
        sleep(5)
    end
end

-- Run the actual program
run()