-- Imports
computer = require("computer")
component = require("component")
sides = require("sides")
robot = require("robot")
event = require("event")
term = require("term")
filesize = require("filesize") -- github /utils/filesize.lua put in /lib folder
dtutil = require("datetimeutil") -- github /utils/datetimeutil.lua put in /lib folder
putils = require("power") -- github /utils/power.lua put in /lib folder
rs = component.redstone
c = component.crafting
inv = component.inventory_controller

-- Variables
local lowPowerVal = 50 -- Value for Low Power
local chargerSlot = 16 -- Slot to put OpenComputers Charger into
local chestSlot = 15 -- Slot to put chest into
local debug = false -- Set to true for debug info on the screen

function guiHeader()
    term.setCursor(1,1)
    term.write("========================================================================================", false)
    term.setCursor(1,3)
    term.write("CheesecakeNet OpenComputers Bow Crafting Robot", false)
    term.setCursor(1,5)
    term.write("========================================================================================", false)
end

function guiFooter(power)
    local width,height = term.getViewport()
    local free = computer.freeMemory()
    local uptime = computer.uptime()
    term.setCursor(1, height - 2)
    term.write("RAM Usage: "..filesize(computer.totalMemory() - free, {round = 1}).."/"..filesize(computer.totalMemory(), {round = 1}))
    term.setCursor(1, height - 1)
    term.write("Battery Percentage: "..power.."% | Uptime: "..dtutil.secToClock(computer.uptime()))
    term.setCursor(1, height)
    term.write("Exit with Ctrl+C or Ctrl+Alt+C")
end

function updateGUI(...)
    local arg = {...}
    local task = arg[1]
    local message = arg[2]
    local int = 0
    local ext = 0
    local power = putils.getPowerPercent()
    if task == "craft" or task == "sleep" then
        int = arg[3] -- Sleep: Time Elapsed
        ext = arg[4] -- Sleep: Total Time
    elseif task == "clear" then
        int = arg[3]
    end
    term.clear()
    term.setCursorBlink(false)
    guiHeader()
    if debug == true then
        term.setCursor(1,7)
        term.write("Task (debug): "..task)
    end
    term.setCursor(1,8)
    term.write("Current Action: "..message)
    if task == "craft" or task == "clear" then
        term.setCursor(1,9)
        term.write("Robot Selected Slot: "..math.floor(int))
    end
    if task == "craft" then
        term.setCursor(1,10)
        term.write("Selected Chest Slot: "..ext)
    end
    if task == "sleep" then
        term.setCursor(1,9)
        term.write("Sleep Timer: "..int.."/"..ext.." sec elapsed")
    end
    guiFooter(power)
end

function checkInterruptAndQuit()
    local id = event.pull(1, "interrupted")
    if id == nil then
    end
    if id == "interrupted" then
        updateGUI("general", "Stopping Program")
        os.exit()
    end
end

function recharge(chargerSlot)
    updateGUI("general", "Recharging robot...")
    robot.select(chargerSlot)
    while robot.compare(true) == false do
        robot.turnLeft()
        checkInterruptAndQuit()
    end
    rs.setOutput(sides.front, 15)
    while putils.detectPowerFull() == false do
        os.sleep(5)
        checkInterruptAndQuit()
    end
    rs.setOutput(sides.front, 0)
    robot.select(1)
    updateGUI("general", "Recharge complete")
end

function crafting(i)
    c.craft(1)
    updateGUI("craft", "Crafting bows together", robot.select(), i)
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
        updateGUI("clear", "Clearing crafting slots of items", i)
        robot.select(i)
        robot.drop()
    end
    updateGUI("general", "Cleared crafting slots")
end

function getBrokenBowsToCraft()
    local size = inv.getInventorySize(sides.front)
    ensureCrafterClean()
    local first = false
    robot.select(1)
    for i = 1, size do
        checkInterruptAndQuit()
        updateGUI("craft", "Getting broken bows", robot.select(), i)
        if isBrokenBow(i) == true then
            inv.suckFromSlot(sides.front, i) -- Get Bow
            if first == false then
                first = true
                robot.select(2)
            else
                robot.select(1)
                crafting(i) -- Craft together
                if isBrokenBowInt(1) == false then
                    updateGUI("craft", "Bow Repaired. Returning to chest", robot.select(), i)
                    robot.drop()
                    first = false
                end
            end
        end
    end
end

while true do
    if putils.detectPowerLow(lowPowerVal) == true then
        recharge(chargerSlot)
    end
    robot.select(chestSlot)
    while robot.compare(true) == false do
        robot.turnLeft()
        checkInterruptAndQuit()
    end
    updateGUI("general", "Preparing to repair broken bows by merging them together")
    getBrokenBowsToCraft()
    updateGUI("sleep", "Completed broken bow check. Resting for 5 minutes", 0, 300)
    checkInterruptAndQuit()
    for i=1,60 do
        updateGUI("sleep", "Completed broken bow check. Resting for 5 minutes", i*5, 300)
        os.sleep(5)
        checkInterruptAndQuit()
    end
    checkInterruptAndQuit()
end

