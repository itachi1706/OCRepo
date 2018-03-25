local computer = require("computer")

local power = {}

function power.getPowerPercent()
    local maxPower = computer.maxEnergy()
    local curPower = computer.energy()
    return math.floor(((curPower / maxPower) * 100) + 0.5)
end

function power.detectPowerLow(lowPowerVal)
    local percent = power.getPowerPercent()
    if (percent < lowPowerVal) then
        return true
    end
    return false
end

function power.detectPowerFull()
    local percent = power.getPowerPercent()
    if (percent > 95) then
        return true
    end
    return false
end

return power