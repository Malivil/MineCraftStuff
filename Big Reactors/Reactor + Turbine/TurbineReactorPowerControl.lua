---------------
-- Constants --
---------------

local ENERGY_CAPACITY = 1000000
local ENERGY_MIN = ENERGY_CAPACITY * 0.1 -- 10%
local ENERGY_MAX = ENERGY_CAPACITY * 0.9 -- 90%
local SPEED_MAX = 1800

local MODEM_CHANNEL = 3
local MODEM_REPLYCHANNEL = 4 -- Not used

--------------------
-- Helper Methods --
--------------------

-- Checks if the modem exists and can connect to the correct channel
function checkModem(modem)
    if (modem == nil) then
        error("Failed to connect to modem")
    end
end

function checkReactor(reactor)
    if (reactor == nil) then
        error("Failed to connect to reactor")
    end
end

function checkTurbine(turbine)
    if (turbine == nil) then
        error("Failed to connect to turbine")
    end
end

-- Pulls all useful information from the reactor and turbine
-- uses it to control whether the reactor and turbine should keep running.
-- It then broadcasts this information over the modem so it can be displayed elsewhere.
function pollReactor(reactor, turbine, modem)
    -- Make sure the reactor and turnbine are both still there
    checkReactor(reactor)
    checkTurbine(turbine)
    
    -- Pull all relevant information
    local stats = {}
    
    stats.steam = {}
    stats.steam.lastTick = reactor.getHotFluidProducedLastTick()
    
    stats.energy = {}
    stats.energy.current = turbine.getEnergyStored()
    stats.energy.lastTick = turbine.getEnergyProducedLastTick()
    stats.energy.max = ENERGY_MAX
    stats.energy.min = ENERGY_MIN
    stats.energy.capacity = ENERGY_CAPACITY

    stats.temp = {}
    stats.temp.fuel = reactor.getFuelTemperature()
    stats.temp.case = reactor.getCasingTemperature()

    stats.fuel = {}
    stats.fuel.current = reactor.getFuelAmount()
    stats.fuel.waste = reactor.getWasteAmount()
    stats.fuel.max = reactor.getFuelAmountMax()
    
    stats.rotor = {}
    stats.rotor.current = turbine.getRotorSpeed()
    stats.rotor.max = SPEED_MAX

    stats.isActive = reactor.getActive()    

    -- TODO: Figure out if we even want to control the energy output
    if --(stats.energy.current > ENERGY_MAX) or
         (stats.rotor.current > SPEED_MAX) then
        if (stats.isActive) then
            reactor.setActive(false)
        end
    elseif --(stats.energy.current < ENERGY_MIN) and
             (stats.rotor.current < SPEED_MAX) and
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
    local modem = peripheral.wrap("right")
    checkModem(modem)

    -- Reactor
    local reactor = peripheral.wrap("bottom")
    checkReactor(reactor)
    
    -- Turbine
    local turbine = peripheral.wrap("BigReactors-Turbine_0")
    checkTurbine(reactor)

    while true do
        pollReactor(reactor, turbine, modem)
        sleep(5)
    end
end

-- Run the actual program
run()