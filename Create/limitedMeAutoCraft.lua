local chest = peripheral.wrap("left")
local item_limit = 50

while (true) do
    local item = chest.getItemDetail(2)
    local item_count = 0
    if item then
        item_count = item.count
    end

    if item_count <= item_limit then
        rs.setOutput("right", true)
        sleep(0.05)
        rs.setOutput("right", false)
        sleep(3)
    end
end