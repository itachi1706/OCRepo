function getPowerPercent()
    local maxPower = computer.maxEnergy()
    local curPower = computer.energy()
    return math.floor(((curPower / maxPower) * 100) + 0.5)
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