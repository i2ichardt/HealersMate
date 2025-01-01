HealersMate.DistanceScannerFrame = CreateFrame("Frame", "HMDistanceScannerFrame", UIParent)

local util = HMUtil
local TRACKING_MIN_DIST = 20
local TRACKING_MAX_DIST = 60
local SIGHT_MAX_DIST = 80

function HealersMate.StartDistanceScanner()
    local almostAllUnits = util.CloneTable(util.AllUnits) -- Everything except the player
    table.remove(almostAllUnits, util.IndexOf(almostAllUnits, "player"))

    local distanceTrackedUnits = util.CloneTable(almostAllUnits) -- Initially scan all units
    local sightTrackedUnits = util.CloneTable(almostAllUnits)
    local preciseDistance = util.CanClientGetPreciseDistance()
    local sightTrackingEnabled = util.CanClientSightCheck()
    local nextTrackingUpdate = GetTime() + 0.5
    local nextUpdate = GetTime() + 0.6
    if not preciseDistance and not sightTrackingEnabled then
        nextUpdate = nextUpdate + 99999999 -- Effectively disable updates
    end
    local UnitFrames = HealersMate.UnitFrames
    HealersMate.DistanceScannerFrame:SetScript("OnUpdate", function()
        local time = GetTime()
        if time > nextTrackingUpdate then
            nextTrackingUpdate = time + math.random(0.5, 2)
    
            distanceTrackedUnits = {}
            local prevSightTrackedUnits = sightTrackedUnits
            sightTrackedUnits = {}
            for _, unit in ipairs(almostAllUnits) do
                local dist = util.GetDistanceTo(unit)
                for ui in UnitFrames(unit) do
                    ui:CheckRange(dist)
                end
                if dist < TRACKING_MAX_DIST and dist > TRACKING_MIN_DIST then -- Only closely track units that are close to the range threshold
                    table.insert(distanceTrackedUnits, unit)
                end
                if dist > 0 and dist < SIGHT_MAX_DIST and sightTrackingEnabled then
                    table.insert(sightTrackedUnits, unit)
                end
            end

            -- Check sight on previously tracked units in case they got removed
            for _, unit in ipairs(prevSightTrackedUnits) do
                for ui in UnitFrames(unit) do
                    ui:CheckSight()
                end
            end
        end
    
        if time > nextUpdate then
            nextUpdate = time + 0.1
            for _, unit in ipairs(distanceTrackedUnits) do
                for ui in UnitFrames(unit) do
                    ui:CheckRange()
                end
            end
            for _, unit in ipairs(sightTrackedUnits) do
                for ui in UnitFrames(unit) do
                    ui:CheckSight()
                end
            end
        end
    end)
end