computer = require("computer")
component = require("component")
sides = require("sides")
rs = component.redstone
c = component.crafting
inv = component.inventory_controller

-- Variables
lowPowerVal = 50 -- Value for Low Power
chargerSlot = 16 -- Slot to put OpenComputers Charger into
chestSlot = 15 -- Slot to put chest into

local function getPowerPercent()
    local maxPower = computer.maxEnergy()
    local curPower = computer.energy()
    return math.floor(((curPower / maxPower) * 100) + 0.5)
end

local function detectPowerLow()
    local percent = getPowerPercent()
    if (percent < lowPowerVal) then
        return true
    else
        return false
    end
end

local function detectPowerFull()
    local percent = getPowerPercent()
    if (percent > 95) then
        return true
    else
        return false
    end
end

local function recharge()
    robot.select(chargerSlot)
    while robot.compare() == false do
        robot.turnLeft()
    end
    rs.setOutput(sides.front, 15)
    while detectPowerFull == false do
        os.sleep(5)
    end
    rs.setOutput(sides.front, 0)
    robot.select(1)
end

local function crafting()
    c.craft(1)
end

local function isBrokenBow(slot)
    item = inv.getStackInSlot(sides.front, slot)
    if item.name == "minecraft:bow" then -- Check if Bow
        if item.damage == item.maxDamage then -- Check durability
            return false
        end
        return true
    end
    return false
end

local function isBrokenBowInt(slot)
    item = inv.getStackInInternalSlot(slot)
    if item.name == "minecraft:bow" then -- Check if Bow
        if item.damage == item.maxDamage then -- Check durability
            return false
        end
        return true
    end
    return false
end

local function ensureCrafterClean()
    for i=1,12 do
        robot.drop()
    end
end

local function getBrokenBowsToCraft()
    local size = inv.getInventorySize(sides.front)
    ensureCrafterClean()
    local first = false
    for i = 1, size do
        if isBrokenBow(i) == true then
            inv.suckFromSlot(i) -- Get Bow
            if first == false then
                first = true
            else
                robot.select(1)
                crafting() -- Craft together
                if isBrokenBowInt(1) == false then
                    robot.drop()
                    first = false
                end
            end
        end
    end
end

while true do
    if detectPowerLow() == true then
        recharge()
    end
    robot.select(chestSlot)
    while robot.compare() == false do
        robot.turnLeft()
    end
    getBrokenBowsToCraft()
    os.sleep(300)
end
