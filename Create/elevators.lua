os.unloadAPI("buttons")
os.loadAPI("disk/buttons.lua")
 
local guiButtons = {}
local mon = peripheral.find("monitor")
local mod = peripheral.find("modem")

local myFloor = 1
local currentFloor = 1

local running = true
local moving = false

-- Direction control
local redstone = false
local redstoneSide = "right"

-- Piston control
local piston = false
local pistonSide = "left"

-- Channels
local movingChan = 100
local redstoneChan = 101

-- Floor channels
mod.open(1)
mod.open(2)
mod.open(3)
-- Movement reporting channel
mod.open(movingChan)
-- Redstone direction channel
mod.open(redstoneChan)

-- Redstone control
local handleRedstone = function()
    rs.setOutput(redstoneSide, redstone)
end
local handlePiston = function(isOpen)
    piston = isOpen
    rs.setOutput(pistonSide, piston)
end

-- Messaging
local sendFloorMessage = function()
    mod.transmit(currentFloor, currentFloor, "1")
end
local sendMovingMessage = function(isMoving)
    mod.transmit(movingChan, movingChan, isMoving and "1" or "0")
end
local sendRedstoneMessage = function(isEnabled)
    -- Don't actually send anything if we're the computer controlling the redstone direction
    if myFloor == 1 then
        redstone = isEnabled
        handleRedstone()
    else
        mod.transmit(redstoneChan, redstoneChan, isEnabled and "1" or "0")
    end
end

-- Logic
local handleFloorSwitch = function(oldFloor, pressed)
    if oldFloor == pressed then return end
    
    -- Get the piston out of the way first
    -- This won't make the elevator move because once it's stopped, it stops until the direction changes
    if oldFloor == myFloor then
        handlePiston(false)
    end
    
    local up = pressed > oldFloor
    -- Send "up" redstone message
    if up then
        sendRedstoneMessage(true)
    -- Send "down" redstone message
    else
        -- If we're on the 2nd floor and we want to go down, we first have to go up and then go back down so the elevator realizes it can move again
        if oldFloor == 2 and oldFloor == myFloor then
            sendRedstoneMessage(true)
            sleep(0.25)
        end

        sendRedstoneMessage(false)
    end
    
    -- Open piston logic
    if up then
        if pressed == myFloor and myFloor == 2 then
            -- TODO: Special logic for the second floor to wait for the elevator to pass, then make the piston come out, then reverse the direction of the elevator so it rolls back into the piston to stop
        end
    -- If the elevator is coming down to us then open our piston
    elseif pressed == myFloor then
        handlePiston(true)
    end
end

-- UI
local updateButtons = function()
    buttons.setColor(guiButtons.buttonFirst, colors.white, currentFloor == 1 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonSecond, colors.white, currentFloor == 2 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonThird, colors.white, currentFloor == 3 and colors.green or colors.lightGray)
    buttons.draw()
end
 
local firstPressed = function()
    if moving then return end
    if currentFloor == 1 then return end
    print("[ELEVATOR] Player pressed \"First\" button")
    currentFloor = 1
    updateButtons()
    sendFloorMessage()
end
local goFirst = function(oldFloor)
    handleFloorSwitch(oldFloor, 1)
end

local secondPressed = function()
    if moving then return end
    if currentFloor == 2 then return end
    print("[ELEVATOR] Player pressed \"Second\" button")
    currentFloor = 2
    updateButtons()
    sendFloorMessage()
end
local goSecond = function(oldFloor)
    handleFloorSwitch(oldFloor, 2)
end

local thirdPressed = function()
    if moving then return end
    if currentFloor == 3 then return end
    print("[ELEVATOR] Player pressed \"Third\" button")
    currentFloor = 3
    updateButtons()
    sendFloorMessage()
end
local goThird = function(oldFloor)
    handleFloorSwitch(oldFloor, 3)
end
 
-- Create the buttons
guiButtons.buttonFirst = buttons.register(1, 1, 7, 1, colors.white, colors.green, " First", firstPressed)
guiButtons.buttonSecond = buttons.register(1, 3, 7, 1, colors.white, colors.lightGray, "Second", secondPressed)
guiButtons.buttonThird = buttons.register(1, 5, 7, 1, colors.white, colors.lightGray, " Third", thirdPressed)

-- Make sure we draw on the monitor
buttons.setTarget(mon)
buttons.draw()

-- Handle all events and redraw the buttons as needed
while running do
    local eventArray = {os.pullEvent()}
    if eventArray[1] == "modem_message" then
        local channel = eventArray[3]
        local message = eventArray[5]
        -- Handle floor call messages
        if channel >= 1 and channel <= 3 then
            local oldFloor = currentFloor
            currentFloor = channel
            print("[ELEVATOR] Received message from channel " .. channel .. ": " .. message)
            if channel == 1 then
                goFirst(oldFloor)
            elseif channel == 2 then
                goSecond(oldFloor)
            elseif channel == 3 then
                goThird(oldFloor)
            end
            updateButtons()
        -- Handle moving message
        else if channel == movingChan then
            moving = message == "1"
            local state = moving and "now" or "no longer"
            print("[ELEVATOR] Elevator is " .. state .. " moving")
        -- Handle redstone control message
        else if myFloor == 1 and channel == redstoneChan then
            redstone = message == "1"
            local state = redstone and "enabled" or "disabled"
            print("[ELEVATOR] Redstone is now " .. state)
            handleRedstone()
        end
    else
        buttons.event(eventArray)
        buttons.draw()
    end
end
 
os.unloadAPI("buttons")