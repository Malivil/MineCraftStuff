while true do
    redstone.setOutput("back", false)    
    os.queueEvent("randomEvent")
    os.pullEvent()
    if redstone.getInput("right") == true then
        --laser
        sleep(1)
        redstone.setOutput("top", true)
        sleep(2)
        redstone.setOutput("top", false)
        -- move to unloader
        redstone.setOutput("left", true)
        sleep(1)   
        redstone.setOutput("left", false)
        sleep(1)
        -- switch tracks
        redstone.setOutput("back", true)
        sleep(1)
        -- send cart back
        redstone.setOutput("bottom", true)
        sleep(3)
        --move tracks back
        redstone.setOutput("back", false)
        redstone.setOutput("bottom", false)
    end
end