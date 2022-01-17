--[[ * Buttons API by LBPHacker, 2013
     * You can use it whenever and whereever you want,
       but give credit! (at least something like 'LBP')
]]

--[[ Modified by Malivil in 2022 to add easier Monitor support ]]
 
local container = {}
local defaultColorT = colors.white
local defaultColorB = colors.black
local target = term
local termw, termh = target.getSize()
 
local forcedEvent
local getClickEvent = function()
    local clickEvent
    if forcedEvent then
        clickEvent = forcedEvent
    else
        --[[ * Below is a pretty way to determine wheter
               the terminal is redirected to a monitor or not.
             * As you might know, .setTextScale can be found
               in monitors only.
        ]]
        if target.setTextScale then
            clickEvent = "monitor_touch"
        else
            clickEvent = "mouse_click"
        end
    end
    return clickEvent
end
 
register = function(xorg, yorg, width, height, textColor, backgroundColor, text, func)
    local newButtonID = false
    for i = 1, #container do if not container[i].alive and not newButtonID then newButtonID = i end end
    if not newButtonID then
        newButtonID = #container + 1
        container[newButtonID] = {}
    end
    container[newButtonID].alive = true
    container[newButtonID].xorg = xorg
    container[newButtonID].yorg = yorg
    container[newButtonID].width = width
    container[newButtonID].height = height
    container[newButtonID].textColor = textColor
    container[newButtonID].backgroundColor = backgroundColor
    container[newButtonID].text = text
    container[newButtonID].func = func
    container[newButtonID].enabled = true
    container[newButtonID].visible = true
    return newButtonID
end
 
exists = function(buttonID)
    if container[buttonID] then
        return container[buttonID].alive
    else
        return false
    end
end
 
unregister = function(buttonID)
    if not exists(buttonID) then error("Invalid identifier: " .. tostring(buttonID)) end
    container[buttonID].alive = false
end
 
event = function(eventArray)
    if eventArray[1] == getClickEvent() then
        local button, mousex, mousey = eventArray[2], eventArray[3], eventArray[4]
        for i = 1, #container do
            if container[i].alive then
                if container[i].enabled and mousex > container[i].xorg - 1 and mousey > container[i].yorg - 1 and mousex < container[i].xorg + container[i].width and mousey < container[i].yorg + container[i].height then container[i].func() end
            end
        end
    end
end
 
draw = function()
    target.setBackgroundColor(defaultColorB)
    target.clear()
    for i = 1, #container do
        if container[i].alive and container[i].visible then
            for j = container[i].yorg, container[i].yorg + container[i].height - 1 do
                target.setCursorPos(container[i].xorg, j)
                target.setTextColor(container[i].textColor)
                target.setBackgroundColor(container[i].backgroundColor)
                target.write(string.rep(" ", container[i].width))
            end
            target.setCursorPos(container[i].xorg + math.floor((container[i].width - #container[i].text) / 2), container[i].yorg + math.floor((container[i].height - 1) / 2))
            target.write(container[i].text)
        end
    end
    target.setTextColor(defaultColorT)
    target.setBackgroundColor(defaultColorB)
end
 
enable = function(buttonID, bEnabled)
    if not exists(buttonID) then error("Invalid identifier: " .. tostring(buttonID)) end
    container[buttonID].enabled = bEnabled
end
 
show = function(buttonID, bVisible)
    if not exists(buttonID) then error("Invalid identifier: " .. tostring(buttonID)) end
    container[buttonID].visible = bVisible
end
 
setPosition = function(buttonID, xorg, yorg, width, height)
    if not exists(buttonID) then error("Invalid identifier: " .. tostring(buttonID)) end
    container[buttonID].xorg = xorg
    container[buttonID].yorg = yorg
    container[buttonID].width = width
    container[buttonID].height = height
end
 
setText = function(buttonID, sText)
    if not exists(buttonID) then error("Invalid identifier: " .. tostring(buttonID)) end
    container[buttonID].text = sText
end
 
setForcedEvent = function(fEvent)
    forcedEvent = fEvent
end
 
setColor = function(buttonID, colorT, colorB)
    if not exists(buttonID) then error("Invalid identifier: " .. tostring(buttonID)) end
    container[buttonID].textColor = colorT
    container[buttonID].backgroundColor = colorB
end
 
setDefaultColor = function(buttonID, colorT, colorB)
    defaultColorT = colorT
    defaultColorB = colorB
end

setTarget = function(targ)
    target = targ
    termw, termh = target.getSize()
end