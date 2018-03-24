computer = require("computer")
component = require("component")
sides = require("sides")
robot = require("robot")
rs = component.redstone
c = component.crafting
inv = component.inventory_controller

-- Variables
local lowPowerVal = 50 -- Value for Low Power
local chargerSlot = 16 -- Slot to put OpenComputers Charger into
local chestSlot = 15 -- Slot to put chest into

function getPowerPercent()
    local maxPower = computer.maxEnergy()
    local curPower = computer.energy()
    return math.floor(((curPower / maxPower) * 100) + 0.5)
end

function checkInterruptAndQuit()
    local id = event.pull("interrupted")
    if id == nil then
    end
    if id == "interrupted" then
        print("Stopping Program")
        os.exit()
    end
end

function detectPowerLow(lowPowerVal)
    local percent = getPowerPercent()
    if (percent < lowPowerVal) then
        return true
    else
        return false
    end
end

function detectPowerFull()
    local percent = getPowerPercent()
    if (percent > 95) then
        return true
    else
        return false
    end
end

function recharge(chargerSlot)
    print("Recharging robot...")
    robot.select(chargerSlot)
    while robot.compare(true) == false do
        robot.turnLeft()
        checkInterruptAndQuit()
    end
    rs.setOutput(sides.front, 15)
    while detectPowerFull() == false do
        os.sleep(5)
        checkInterruptAndQuit()
    end
    rs.setOutput(sides.front, 0)
    robot.select(1)
    print("Recharge complete")
end

function crafting()
    c.craft(1)
    print("Crafting Complete")
end

function isBrokenBow(slot)
    item = inv.getStackInSlot(sides.front, slot)
    if item == nil then
        return false
    end
    if item.name == "minecraft:bow" then -- Check if Bow
        if item.damage == 0 then -- Check durability
            return false
        end
        return true
    end
    return false
end

function isBrokenBowInt(slot)
    item = inv.getStackInInternalSlot(slot)
    if item == nil then
        return false
    end
    if item.name == "minecraft:bow" then -- Check if Bow
        if item.damage == 0 then -- Check durability full
            return false
        end
        return true
    end
    return false
end

function ensureCrafterClean()
    for i=1,12 do
        robot.select(i)
        robot.drop()
    end
    print("Cleaned crafting slots")
end

function getBrokenBowsToCraft()
    local size = inv.getInventorySize(sides.front)
    ensureCrafterClean()
    local first = false
    robot.select(1)
    for i = 1, size do
        checkInterruptAndQuit()
        if isBrokenBow(i) == true then
            inv.suckFromSlot(sides.front, i) -- Get Bow
            if first == false then
                first = true
                robot.select(2)
            else
                robot.select(1)
                crafting() -- Craft together
                if isBrokenBowInt(1) == false then
                    print("Repaired item dropped back into chest")
                    robot.drop()
                    first = false
                end
            end
        end
    end
end

while true do
    if detectPowerLow(lowPowerVal) == true then
        recharge(chargerSlot)
    end
    robot.select(chestSlot)
    while robot.compare(true) == false do
        robot.turnLeft()
        checkInterruptAndQuit()
    end
    print("Preparing to repair broken bows by merging them together")
    getBrokenBowsToCraft()
    print("Completed checking inventory for broken bows. Resting for 5 minutes")
    checkInterruptAndQuit()
    os.sleep(300)
    checkInterruptAndQuit()
end

