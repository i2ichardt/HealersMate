HealersMate.DistanceScannerFrame = CreateFrame("Frame", "HMDistanceScannerFrame", UIParent)

local util = HMUtil
local TRACKING_MIN_DIST = 20
local TRACKING_MAX_DIST = 60
local SIGHT_MAX_DIST = 80

local almostAllUnits = util.CloneTable(util.AllUnits) -- Everything except the player
table.remove(almostAllUnits, util.IndexOf(almostAllUnits, "player"))
HMUnitProxy.RegisterUpdateListener(function()
    almostAllUnits = util.CloneTable(util.AllUnits) -- Everything except the player
    table.remove(almostAllUnits, util.IndexOf(almostAllUnits, "player"))
end)

local distanceTrackedUnits = util.CloneTable(almostAllUnits) -- Initially scan all units
local sightTrackedUnits = util.CloneTable(almostAllUnits)
local preciseDistance = util.CanClientGetPreciseDistance()
local sightTrackingEnabled = util.CanClientSightCheck()
local nextTrackingUpdate = GetTime() + 0.5
local nextUpdate = GetTime() + 0.6
if not preciseDistance and not sightTrackingEnabled then
    nextUpdate = nextUpdate + 99999999 -- Effectively disable updates
end

local TRACKING_UPDATE_INTERVAL = 1.25

local _G = getfenv(0)
if HMUtil.IsSuperWowPresent() then
    setmetatable(HMUnitProxy, {__index = getfenv(1)})
    setfenv(1, HMUnitProxy)
end

function HealersMate.RunTrackingScan()
    local UnitFrames = HealersMate.UnitFrames
    local time = GetTime()
    if time > nextTrackingUpdate then
        nextTrackingUpdate = time + TRACKING_UPDATE_INTERVAL

        distanceTrackedUnits = {}
        local prevSightTrackedUnits = sightTrackedUnits
        sightTrackedUnits = {}
        if HMGuidRoster then
            for guid, cache in pairs(HMUnit.GetAllUnits()) do
                HealersMate.EvaluateTracking(guid)
            end
        else
            for _, unit in ipairs(almostAllUnits) do
                HealersMate.EvaluateTracking(unit)
            end
        end

        for _, unit in ipairs(prevSightTrackedUnits) do
            for ui in UnitFrames(unit) do
                ui:UpdateSight()
            end
        end
        --HealersMate.hmprint("Tracking dist "..table.getn(distanceTrackedUnits))
        --HealersMate.hmprint("Tracking sight "..table.getn(sightTrackedUnits))
    end

    if time > nextUpdate then
        nextUpdate = time + 0.1
        for _, unit in ipairs(distanceTrackedUnits) do
            local cache = HMUnit.Get(unit)
            if cache and cache:UpdateDistance() then
                for ui in UnitFrames(unit) do
                    ui:UpdateRange()
                end
            end
        end
        for _, unit in ipairs(sightTrackedUnits) do
            local cache = HMUnit.Get(unit)
            if cache and cache:UpdateSight() then
                for ui in UnitFrames(unit) do
                    ui:UpdateSight()
                end
            end
        end
    end
end

function HealersMate.EvaluateTracking(unit, update)
    local UnitFrames = HealersMate.UnitFrames
    local cache = HMUnit.Get(unit)
    local distanceChanged = cache:UpdateDistance()
    local sightChanged = cache:UpdateSight()
    local new = cache:CheckNew()
    local dist = cache:GetDistance()
    if distanceChanged or sightChanged or new then
        for ui in UnitFrames(unit) do
            if distanceChanged or new then
                ui:UpdateRange()
            end
            if sightChanged or new then
                ui:UpdateSight()
            end
        end
    end
    local isTarget = UnitIsUnit(unit, "target")
    if HMGuidRoster then
        unit = HMGuidRoster.ResolveUnitGuid(unit)
    end
    if isTarget or (dist < TRACKING_MAX_DIST and dist > TRACKING_MIN_DIST) then -- Only closely track units that are close to the range threshold
        if not update or not util.ArrayContains(distanceTrackedUnits, unit) then
            table.insert(distanceTrackedUnits, unit)
        end
    end
    if sightTrackingEnabled and (isTarget or (dist > 0 and dist < SIGHT_MAX_DIST)) then
        if not update or not util.ArrayContains(sightTrackedUnits, unit) then
            table.insert(sightTrackedUnits, unit)
        end
    end
end

function HealersMate.StartDistanceScanner()
    HealersMate.DistanceScannerFrame:SetScript("OnUpdate", HealersMate.RunTrackingScan)
end