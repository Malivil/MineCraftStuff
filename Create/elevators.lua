os.unloadAPI("buttons")
os.loadAPI("disk/buttons.lua")
 
-------------------
-- Configuration --
-------------------

local myFloor = 1

-- Direction control
local redstoneSide = "right"

-- Piston control
local pistonSide = "bottom"

------------
-- Fields --
------------

local guiButtons = {}
local mon = peripheral.find("monitor")
local mod = peripheral.find("modem")

-- State tracking
local currentFloor = 1
local running = true
local moving = false

-- Channels
local movingChan = 100
local redstoneChan = 101

-------------------
-- Modem Control --
-------------------

-- Floor channels
mod.open(1)
mod.open(2)
mod.open(3)
-- Movement reporting channel
mod.open(movingChan)
-- Redstone direction channel
mod.open(redstoneChan)

-- Redstone control
local handleRedstone = function(isEnabled)
    print("[ELEVATOR] Setting redstone state to: " .. (isEnabled and "ON" or "OFF"))
    if myFloor == 1 then
        rs.setOutput(redstoneSide, isEnabled)
    else
        mod.transmit(redstoneChan, redstoneChan, isEnabled and "1" or "0")
    end
end
local handlePiston = function(isOpen)
    if myFloor == 1 then return end

    print("[ELEVATOR] Setting piston state to: " .. (isEnabled and "OPEN" or "CLOSED"))
    rs.setOutput(pistonSide, isOpen)
end

-- Messaging
local sendFloorMessage = function()
    mod.transmit(currentFloor, currentFloor, "1")
end
local sendMovingMessage = function(isMoving)
    mod.transmit(movingChan, movingChan, isMoving and "1" or "0")
end

-----------
-- Logic --
-----------

local handleFloorSwitch = function(pressed)
    if currentFloor == pressed then return end
    print("[ELEVATOR] Switching floors from " .. currentFloor .. " to " .. pressed)
    local oldFloor = currentFloor
    currentFloor = pressed
    
    -- Get the piston out of the way first
    -- This won't make the elevator move because once it's stopped, it stops until the direction changes
    if oldFloor == myFloor then
        handlePiston(false)
    end
    
    local up = oldFloor > pressed
    -- Send "up" redstone message
    if up then
        handleRedstone(true)
    -- Send "down" redstone message
    else
        -- If we're on the 2nd floor and we want to go down, we first have to go up and then go back down so the elevator realizes it can move again
        if oldFloor == 2 and oldFloor == myFloor then
            handleRedstone(true)
            sleep(0.25)
        end

        handleRedstone(false)
    end
    
    -- Everything below is about controlling local pistons and only applies to the computer handling the destination floor
    if pressed ~= myFloor then return end
    
    -- Open piston logic
    if up then
        -- Special logic for the 2nd floor
        if myFloor == 2 then
            -- Wait for the elevator to pass the floor
            sleep(10)
            -- Open the piston
            handlePiston(true)
            -- Send the elevator back down so it rolls into the piston to stop
            handleRedstone(false)
        end
    -- If the elevator is coming down to us then open our piston
    else
        handlePiston(true)
    end
end

--------
-- UI --
--------

local updateButtons = function()
    buttons.setColor(guiButtons.buttonFirst, colors.white, currentFloor == 1 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonSecond, colors.white, currentFloor == 2 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonThird, colors.white, currentFloor == 3 and colors.green or colors.lightGray)
    buttons.draw()
end
 
local goFirst = function()
    handleFloorSwitch(1)
end
local firstPressed = function()
    if moving then return end
    if currentFloor == 1 then return end
    print("[ELEVATOR] Player pressed \"First\" button")
    goFirst()
    updateButtons()
    sendFloorMessage()
end

local goSecond = function()
    handleFloorSwitch(2)
end
local secondPressed = function()
    if moving then return end
    if currentFloor == 2 then return end
    print("[ELEVATOR] Player pressed \"Second\" button")
    goSecond()
    updateButtons()
    sendFloorMessage()
end

local goThird = function()
    handleFloorSwitch(3)
end
local thirdPressed = function()
    if moving then return end
    if currentFloor == 3 then return end
    print("[ELEVATOR] Player pressed \"Third\" button")
    goThird()
    updateButtons()
    sendFloorMessage()
end
 
-- Create the buttons
guiButtons.buttonFirst = buttons.register(1, 1, 7, 1, colors.white, colors.green, " First", firstPressed)
guiButtons.buttonSecond = buttons.register(1, 3, 7, 1, colors.white, colors.lightGray, "Second", secondPressed)
guiButtons.buttonThird = buttons.register(1, 5, 7, 1, colors.white, colors.lightGray, " Third", thirdPressed)

-- Make sure we draw on the monitor
buttons.setTarget(mon)
buttons.draw()

----------
-- Main --
----------

local tick = function()
    -- Handle all events and redraw the buttons as needed
    while running do
        local eventArray = {os.pullEventRaw()}
        if eventArray[1] == "modem_message" then
            local channel = eventArray[3]
            local message = eventArray[5]
            -- Handle floor call messages
            if channel >= 1 and channel <= 3 then
                print("[ELEVATOR] Received message from channel " .. channel .. ": " .. message)
                handleFloorSwitch(channel)
                updateButtons()
            -- Handle moving message
            elseif channel == movingChan then
                moving = message == "1"
                local state = moving and "now" or "no longer"
                print("[ELEVATOR] Elevator is " .. state .. " moving")
            -- Handle redstone control message
            elseif myFloor == 1 and channel == redstoneChan then
                local isEnabled = message == "1"
                local state = isEnabled and "enabled" or "disabled"
                print("[ELEVATOR] Redstone is now " .. state)
                handleRedstone(isEnabled)
            end
        elseif eventArray[i] == "terminate" then
        else
            buttons.event(eventArray)
            buttons.draw()
        end
    end
end

local termHandler = function()
    os.pullEventRaw("terminate")
    print("[ELEVATOR] Shutting down cleanly")
    handleRedstone(false)
    handlePiston(false)
    mon.clear()
    running = false
end

print("[ELEVATOR] Starting...")
parallel.waitForAny(tick, termHandler)

os.unloadAPI("buttons")