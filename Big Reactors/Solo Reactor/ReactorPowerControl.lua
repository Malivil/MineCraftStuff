---------------
-- Constants --
---------------

local MODEM_SIDE = "right"
local REACTOR_SIDE = "back"

local REFRESH_RATE = 5

local ENERGY_CAPACITY = 10000000
local ENERGY_MIN = ENERGY_CAPACITY * 0.1 -- 10%
local ENERGY_MAX = ENERGY_CAPACITY * 0.9 -- 90%
local TEMP_MAX = 1500

local MODEM_CHANNEL = 1
local MODEM_REPLYCHANNEL = 65535 -- Not used

--------------------
-- Helper Methods --
--------------------

-- Checks if the modem exists and can connect to the correct channel
function checkModem(modem)
    if (modem == nil) then
        error("Failed to connect to modem")
        return
    end
end

function checkReactor(reactor)
    if (reactor == nil) then
        error("Failed to connect to reactor")
    end
end

-- Pulls all useful information from the reactor and
-- uses it to control whether the reactor should keep running.
-- It then broadcasts this information over the modem so it can be displayed elsewhere.
function pollReactor(reactor, modem)
    -- Make sure the reactor is still there
    checkReactor(reactor)
    
    -- Pull all relevant information
    local stats = {}
    
    stats.reactorId = MODEM_CHANNEL
    
    stats.energy = {}
    stats.energy.current = reactor.getEnergyStored()
    stats.energy.lastTick = reactor.getEnergyProducedLastTick()
    stats.energy.max = ENERGY_MAX
    stats.energy.min = ENERGY_MIN
    stats.energy.capacity = ENERGY_CAPACITY

    stats.temp = {}
    stats.temp.fuel = reactor.getFuelTemperature()
    stats.temp.case = reactor.getCasingTemperature()
    stats.temp.max = TEMP_MAX

    stats.fuel = {}
    stats.fuel.current = reactor.getFuelAmount()
    stats.fuel.waste = reactor.getWasteAmount()
    stats.fuel.max = reactor.getFuelAmountMax()
    
    stats.isActive = reactor.getActive()

    -- Turn off the reactor when it's almost full
    -- or when its getting close to dangerous temp
    if (stats.energy.current > ENERGY_MAX) or
         (stats.temp.fuel > TEMP_MAX) or
         (stats.temp.case > TEMP_MAX) then
        if (stats.isActive) then
            reactor.setActive(false)
        end
    -- If we need more energy and it is safe, turn it back on
    elseif (stats.energy.current < ENERGY_MIN) and
             (stats.temp.fuel < TEMP_MAX) and
             (stats.temp.case < TEMP_MAX) and
             (not stats.isActive) then
        reactor.setActive(true)
    end

    write("Current Energy: " .. stats.energy.current .. "\n")

    -- Re-read this after the other checks to make sure it has the latest value
    stats.isActive = reactor.getActive()
    
    -- Make sure we're still connected to the modem and send the data
    checkModem(modem)
    modem.transmit(MODEM_CHANNEL, MODEM_REPLYCHANNEL, stats)
end

function run()
    -- Modem
    local modem = peripheral.wrap(MODEM_SIDE)
    checkModem(modem)

    -- Reactor
    local reactor = peripheral.wrap(REACTOR_SIDE)
    checkReactor(reactor)

    while true do
        pollReactor(reactor, modem)
        sleep(REFRESH_RATE)
    end
end

-- Run the actual program
run()