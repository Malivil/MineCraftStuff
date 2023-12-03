local router = peripheral.wrap("front")

local cog_chest = peripheral.wrap("left")
local cog_limit = 64

local large_cog_chest = peripheral.wrap("back")
local large_cog_limit = 64

local bronze_chest = peripheral.wrap("right")
local bronze_limit = 64

local function getItemCount(chest)
    local item = chest.getItemDetail(2)
    if item then
        return item.count
    end
    return 0
end

while (true) do
    local cog_count = getItemCount(cog_chest)
    local cog_enabled = cog_count < cog_limit

    local large_cog_count = getItemCount(large_cog_chest)
    local large_cog_enabled = large_cog_count < large_cog_limit

    local bronze_count = getItemCount(bronze_chest)
    local bronze_enabled = bronze_count < bronze_limit

    -- If any item needs to be created
    if cog_enabled or large_cog_enabled or bronze_enabled then
        -- Turn on the corresponding side
        if cog_enabled then
            router.setOutput("left", true)
        end
        if bronze_enabled then
            router.setOutput("right", true)
        end
        if large_cog_enabled then
            router.setOutput("front", true)
        end

        -- Turn on the bottom to enable ingot ingest from ME
        rs.setOutput("bottom", true)

        -- Wait for the molten metal to pour
        sleep(2)

        -- Turn all the pours off
        router.setOutput("left", false)
        router.setOutput("right", false)
        router.setOutput("front", false)
    -- If nothing is running, stop pulling from the ME
    else
        rs.setOutput("bottom", false)
    end
end