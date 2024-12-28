-- A utility to map guids to units

if not HMUtil.IsSuperWowPresent() then
    return
end

HMGuidRoster = {}

local _G = getfenv(0)
setmetatable(HMGuidRoster, {__index = getfenv(1)})
setfenv(1, HMGuidRoster)

local util = HMUtil

GuidUnitMap = {}

function ResetRoster()
    GuidUnitMap = {}
end

-- HealersMate does not currently use this because the roster is populated when updating UIs
function PopulateRoster()
    for _, unit in ipairs(util.AllUnits) do
        local _, guid = UnitExists(unit)
        AddUnit(guid, unit)
    end
end

function AddUnit(guid, unit)
    if not GuidUnitMap[guid] then
        GuidUnitMap[guid] = {}
    end
    table.insert(GuidUnitMap[guid], unit)
end

function SetTargetGuid(guid)
    for guidInMap, units in pairs(GuidUnitMap) do
        if util.ArrayContains(units, "target") then
            util.RemoveElement(units, "target")
            if table.getn(units) == 0 then
                GuidUnitMap[guidInMap] = nil
            end
            break
        end
    end

    if not GuidUnitMap[guid] then
        GuidUnitMap[guid] = {}
    end
    table.insert(GuidUnitMap[guid], "target")
end

function GetUnitGuid(unit)
    local _, guid = UnitExists(unit)
    return guid
end

-- Returns an array of all the units the guid is, or nil if none
function GetUnits(guid)
    return GuidUnitMap[guid]
end

function HasUnits(guid)
    return GuidUnitMap[guid] ~= nil
end

-- Returns an array of units this unit is
function GetAllUnits(unit)
    return GetUnits(GetUnitGuid(unit))
end

-- Returns an array of all guids that have units
function GetTrackedGuids()
    return util.ToArray(GuidUnitMap)
end