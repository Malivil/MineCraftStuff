os.unloadAPI("buttons")
os.loadAPI("disk/buttons.lua")
 
-------------------
-- Configuration --
-------------------

local myFloor = 1
local maxFloors = 3

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
local movingTimer = nil
local transitionTimes = {
    [1] = {
        [2] = 3,
        [3] = 5
    },
    [2] = {
        [1] = 3,
        [3] = 5
    },
    [3] = {
        [1] = 5,
        [2] = 3
    }
}

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
local function handleRedstone(isEnabled)
    print("[ELEVATOR] Setting redstone state to: " .. (isEnabled and "ON" or "OFF"))
    if myFloor == 1 then
        rs.setOutput(redstoneSide, isEnabled)
    else
        mod.transmit(redstoneChan, redstoneChan, isEnabled and "1" or "0")
    end
end
local function handlePiston(isOpen)
    if myFloor == 1 then return end

    print("[ELEVATOR] Setting piston state to: " .. (isEnabled and "OPEN" or "CLOSED"))
    rs.setOutput(pistonSide, isOpen)
end

-- Messaging
local function sendFloorMessage(pressed)
    mod.transmit(pressed, pressed, "1")
end
local function sendMovingMessage(isMoving)
    mod.transmit(movingChan, movingChan, isMoving and "1" or "0")
end

-----------
-- Logic --
-----------

local function updateButtons()
    buttons.setColor(guiButtons.buttonFirst, colors.white, currentFloor == 1 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonSecond, colors.white, currentFloor == 2 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonThird, colors.white, currentFloor == 3 and colors.green or colors.lightGray)
    buttons.draw()
end

local function handleFloorSwitch(pressed)
    if currentFloor == pressed then return end
    print("[ELEVATOR] Switching floors from " .. currentFloor .. " to " .. pressed)
    local oldFloor = currentFloor
    currentFloor = pressed
    updateButtons()
    
    print("[ELEVATOR] Elevator has started moving")
    moving = true
    movingTimer = os.startTimer(transitionTimes[oldFloor][currentFloor])
    
    -- Get the piston out of the way first
    -- This won't make the elevator move because once it's stopped, it stops until the direction changes
    if oldFloor == myFloor then
        handlePiston(false)
    end
    
    -- TODO: Re-do redstone logic
    -- Redstone needs to "pin" direction based on current floor. e.g. first should stay in "up" direction, 2nd and 3rd should stay in "down" to pin it against whatever retaining floor/ceiling there is
    
    local up = oldFloor > pressed
    -- Send "up" redstone message
    if up then
        handleRedstone(false)
    -- Send "down" redstone message
    else
        -- If we're on one of the middle floors and we want to go down, we first have to go up and then go back down so the elevator realizes it can move again
        if oldFloor > 1 and oldFloor < maxFloors and oldFloor == myFloor then
            handleRedstone(false)
            sleep(0.25)
        end

        handleRedstone(true)
    end
    
    -- Everything below is about controlling local pistons and only applies to the computer handling the destination floor
    if pressed ~= myFloor then return end
    
    -- Open piston logic
    if up then
        -- Special logic for the middle floors
        if myFloor > 1 and myFloor < maxFloors then
            -- Wait for the elevator to pass the floor
            sleep(transitionTimes[3][2])
            -- Open the piston
            handlePiston(true)
            -- Send the elevator back down so it rolls into the piston to stop
            handleRedstone(true)
        end
    -- If the elevator is coming down to us then open our piston
    else
        handlePiston(true)
    end
end
 
local function buttonPressed(pressed)
    if moving then return end
    if currentFloor == pressed then return end
    print("[ELEVATOR] Player pressed button: " .. pressed)
    sendFloorMessage(pressed)
    handleFloorSwitch(pressed)
end
 
----------
-- Main --
----------

local function renderButtons()
    -- Create the buttons
    guiButtons.buttonFirst = buttons.register(1, 1, 7, 1, colors.white, colors.green, " First", function() buttonPressed(1) end)
    guiButtons.buttonSecond = buttons.register(1, 3, 7, 1, colors.white, colors.lightGray, "Second", function() buttonPressed(2) end)
    guiButtons.buttonThird = buttons.register(1, 5, 7, 1, colors.white, colors.lightGray, " Third", function() buttonPressed(3) end)

    -- Make sure we draw on the monitor
    buttons.setTarget(mon)
    buttons.draw()
end

local function tick()
    -- Handle all events and redraw the buttons as needed
    while running do
        local eventArray = {os.pullEventRaw()}
        if eventArray[1] == "modem_message" then
            local channel = eventArray[3]
            local message = eventArray[5]
            -- Handle floor call messages
            if channel >= 1 and channel <= maxFloors then
                print("[ELEVATOR] Received message from channel " .. channel .. ": " .. message)
                handleFloorSwitch(channel)
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
        elseif eventArray[1] == "timer" and eventArray[2] == movingTimer then
            print("[ELEVATOR] Elevator has stopped moving")
            moving = false
            movingTimer = nil
        else
            buttons.event(eventArray)
            buttons.draw()
        end
    end
end

local function termHandler()
    os.pullEventRaw("terminate")
    print("[ELEVATOR] Shutting down cleanly")
    handleRedstone(false)
    handlePiston(false)
    running = false
end

print("[ELEVATOR] Starting...")
parallel.waitForAll(renderButtons, tick, termHandler)

-- Clear the screen
mon.clear()

os.unloadAPI("buttons")