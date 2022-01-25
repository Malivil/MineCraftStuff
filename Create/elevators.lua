os.unloadAPI("buttons")
os.loadAPI("disk/buttons.lua")
 
-------------------
-- Configuration --
-------------------

local myFloor = 1
local minFloor = 1
local maxFloors = 6

-- Direction control
local redstoneSide = "back"

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
        [2] = 10,
        [3] = 10,
        [4] = 10,
        [5] = 10,
        [6] = 10
    },
    [2] = {
        [1] = 10,
        [3] = 1.1,
        [4] = 10,
        [5] = 2.5,
        [6] = 6.5
    },
    [3] = {
        [1] = 10,
        [2] = 1.1,
        [4] = 10,
        [5] = 2,
        [6] = 5.5
    },
    [4] = {
        [1] = 10,
        [2] = 10,
        [3] = 10,
        [5] = 10,
        [6] = 10
    },
    [5] = {
        [1] = 10,
        [2] = 2.5,
        [3] = 1.5,
        [4] = 10,
        [6] = 4.25
    },
    [6] = {
        [1] = 10,
        [2] = 6.5,
        [3] = 5.5,
        [4] = 10,
        [5] = 4.5
    }
}

-- Channels
local movingChan = 100
local redstoneChan = 101

-------------------
-- Modem Control --
-------------------

-- Floor channels
for c = minFloor, maxFloors do
    mod.open(c)
end
-- Movement reporting channel
mod.open(movingChan)
-- Redstone direction channel
mod.open(redstoneChan)

-- Redstone control
local function handleRedstone(isEnabled)
    print("[ELEVATOR] Setting redstone state to: " .. (isEnabled and "ON" or "OFF"))
    if myFloor == minFloor then
        rs.setOutput(redstoneSide, isEnabled)
    else
        mod.transmit(redstoneChan, redstoneChan, isEnabled and "1" or "0")
    end
end
local function handlePiston(isOpen)
    if myFloor == minFloor then return end

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
    buttons.setColor(guiButtons.buttonGround, colors.white, currentFloor == 0 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonFirst, colors.white, currentFloor == 1 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonSecond, colors.white, currentFloor == 2 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonThird, colors.white, currentFloor == 3 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonFourth, colors.white, currentFloor == 4 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonFifth, colors.white, currentFloor == 5 and colors.green or colors.lightGray)
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
    sendMovingMessage(true)
    
    -- Get the piston out of the way first
    -- This won't make the elevator move because once it's stopped, it stops until the direction changes
    if oldFloor == myFloor then
        handlePiston(false)
    end
    
    local up = oldFloor > pressed
    -- Send "up" redstone message
    if up then
        handleRedstone(false)
    -- Send "down" redstone message
    else
        -- If we're on one of the middle floors and we want to go down, we first have to go up and then go back down so the elevator realizes it can move again
        if oldFloor > minFloor and oldFloor < maxFloors then
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
        if myFloor > minFloor and myFloor < maxFloors then
            -- Wait for the elevator to pass the floor
            sleep(transitionTimes[oldFloor][currentFloor])
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
    guiButtons.buttonGround = buttons.register(1, 1, 3, 2, colors.white, colors.green, "G", function() buttonPressed(1) end)
    guiButtons.buttonFirst = buttons.register(5, 1, 3, 2, colors.white, colors.lightGray, "1", function() buttonPressed(2) end)
    guiButtons.buttonSecond = buttons.register(1, 4, 3, 2, colors.white, colors.lightGray, "2", function() buttonPressed(3) end)
    guiButtons.buttonThird = buttons.register(5, 4, 3, 2, colors.white, colors.lightGray, "3", function() buttonPressed(4) end)
    guiButtons.buttonFourth = buttons.register(1, 7, 3, 2, colors.white, colors.lightGray, "4", function() buttonPressed(5) end)
    guiButtons.buttonFifth = buttons.register(5, 7, 3, 2, colors.white, colors.lightGray, "5", function() buttonPressed(6) end)

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
            if channel >= minFloor and channel <= maxFloors then
                print("[ELEVATOR] Received message from channel " .. channel .. ": " .. message)
                handleFloorSwitch(channel)
            -- Handle moving message
            elseif channel == movingChan then
                moving = message == "1"
                local state = moving and "now" or "no longer"
                print("[ELEVATOR] Elevator is " .. state .. " moving")
            -- Handle redstone control message
            elseif myFloor == minFloor and channel == redstoneChan then
                local isEnabled = message == "1"
                local state = isEnabled and "enabled" or "disabled"
                print("[ELEVATOR] Redstone is now " .. state)
                handleRedstone(isEnabled)
            end
        elseif eventArray[1] == "timer" and eventArray[2] == movingTimer then
            print("[ELEVATOR] Elevator has stopped moving")
            moving = false
            movingTimer = nil
            sendMovingMessage(false)
        else
            buttons.event(eventArray)
            buttons.draw()
        end
    end
end

local function termHandler()
    os.pullEventRaw("terminate")
    print("[ELEVATOR] Shutting down cleanly")
    if myFloor == minFloor then
        handleRedstone(false)
    end
    handlePiston(false)
    running = false
end

print("[ELEVATOR] Starting...")
parallel.waitForAll(renderButtons, tick, termHandler)

-- Clear the screen
mon.clear()

os.unloadAPI("buttons")