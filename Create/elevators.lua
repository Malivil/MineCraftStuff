os.unloadAPI("buttons")
os.loadAPI("disk/buttons.lua")
 
local running = true
local guiButtons = {}
local mon = peripheral.find("monitor")
local mod = peripheral.find("modem")
local myFloor = 1
local currentFloor = 1
local moving = false

-- Floor channels
mod.open(1)
mod.open(2)
mod.open(3)
-- Movement channel
mod.open(100)

local sendFloorMessage = function()
    mod.transmit(currentFloor, currentFloor, "1")
end
local updateButtons = function()
    buttons.setColor(guiButtons.buttonFirst, colors.white, currentFloor == 1 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonSecond, colors.white, currentFloor == 2 and colors.green or colors.lightGray)
    buttons.setColor(guiButtons.buttonThird, colors.white, currentFloor == 3 and colors.green or colors.lightGray)
    buttons.draw()
end
 
local firstPressed = function()
    if currentFloor == 1 then return end
    print("[ELEVATOR] Player pressed \"First\" button")
    currentFloor = 1
    updateButtons()
    sendFloorMessage()
end
local goFirst = function()
    
end

local secondPressed = function()
    if currentFloor == 2 then return end
    print("[ELEVATOR] Player pressed \"Second\" button")
    currentFloor = 2
    updateButtons()
    sendFloorMessage()
end
local goSecond = function()
    
end

local thirdPressed = function()
    if currentFloor == 3 then return end
    print("[ELEVATOR] Player pressed \"Third\" button")
    currentFloor = 3
    updateButtons()
    sendFloorMessage()
end
local goThird = function()
    
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
        -- Handle floor call methods
        if channel >= 1 and channel <= 3 then
            currentFloor = channel
            print("[ELEVATOR] Received message from channel " .. channel .. ": " .. message)
            if channel == 1 then
                goFirst()
            elseif channel == 2 then
                goSecond()
            elseif channel == 3 then
                goThird()
            end
            updateButtons()
        end

        -- Handle moving message
        if channel == 100 then
            moving = message == "1"
            local state = moving and "now" or "no longer"
            print("[ELEVATOR] Elevator is " .. state .. " moving")
        end
    else
        buttons.event(eventArray)
        buttons.draw()
    end
end
 
os.unloadAPI("buttons")