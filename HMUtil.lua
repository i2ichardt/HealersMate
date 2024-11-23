-- Contains standalone utility functions that cause no side effects and don't require data from other files

HMUtil = {}

local _G = getfenv(0)
setmetatable(HMUtil, {__index = getfenv(1)})
setfenv(1, HMUtil)

Classes = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}

UnitXPSP3 = pcall(UnitXP, "inSight", "player", "player") -- WTB better way to check for UnitXP SP3
SuperWoW = SpellInfo ~= nil

PowerColors = {
    ["mana"] = {0.1, 0.25, 1}, --{r = 0, g = 0, b = 0.882}, Not accurate, changed color to make brighter
    ["rage"] = {1, 0, 0},
    ["focus"] = {1, 0.5, 0.25},
    ["energy"] = {1, 1, 0}
}

ClassPowerTypes = {
    ["WARRIOR"] = "rage",
    ["PALADIN"] = "mana",
    ["HUNTER"] = "mana",
    ["ROGUE"] = "energy",
    ["PRIEST"] = "mana",
    ["SHAMAN"] = "mana",
    ["MAGE"] = "mana",
    ["WARLOCK"] = "mana",
    ["DRUID"] = "mana"
}

-- The power types IDs mapped in accordance to UnitPowerType
PowerTypeMap = {
    [0] = "mana", 
    [1] = "rage", 
    [2] = "focus", 
    [3] = "energy"
}

-- The default color Blizzard uses for text
DefaultTextColor = {1, 0.82, 0}

PartyUnits = {"player", "party1", "party2", "party3", "party4"}
PetUnits = {"pet", "partypet1", "partypet2", "partypet3", "partypet4"}
TargetUnits = {"target"}
RaidUnits = {}
for i = 1, MAX_RAID_MEMBERS do
    RaidUnits[i] = "raid"..i
end
RaidPetUnits = {}
for i = 1, MAX_RAID_MEMBERS do
    RaidPetUnits[i] = "raidpet"..i
end

local unitArrays = {PartyUnits, PetUnits, RaidUnits, RaidPetUnits, TargetUnits}
AllUnits = {}
for _, unitArray in ipairs(unitArrays) do
    for _, unit in ipairs(unitArray) do
        table.insert(AllUnits, unit)
    end
end

local assetsPath = "Interface\\AddOns\\HealersMate\\assets\\"
function GetAssetsPath()
    return assetsPath
end

-- Returns a new table with the elements of the given array being the keys with 1 being the value of all keys, 
-- or the index if indexValue is true
function ToSet(array, indexValue)
    local set = {}
    for index, value in ipairs(array) do
        set[value] = indexValue and index or 1
    end
    return set
end

-- Returns a new table with the keys of the given set being the values of the array
function ToArray(set)
    local array = {}
    for value, _ in pairs(set) do
        table.insert(array, value)
    end
    return array
end

-- Adds the elements of otherArray to the array
function AppendArrayElements(array, otherArray)
    for _, v in ipairs(otherArray) do
        table.insert(array, v)
    end
end

function IndexOf(table, value)
    for i, v in ipairs(table) do
        if v == value then
            return i
        end
    end
    return -1
end

function ArrayContains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function RemoveElement(t, value)
    table.remove(t, IndexOf(t, value))
end

function CloneTable(table, deep)
    local clone = {}
    for k, v in pairs(table) do
        if deep and type(v) == "table" then
            clone[k] = CloneTable(v, true)
        else
            clone[k] = v
        end
    end
    return clone
end

-- Courtesy of ChatGPT
function InterpolateColors(colors, t)
    local numColors = table.getn(colors)
    
    -- Ensure t is between 0 and 1
    t = math.max(0, math.min(1, t))

    -- If there are fewer than 2 colors, just return the single color
    if numColors < 2 then
        return colors[1]
    end

    -- Determine the segment in which t falls
    local scaledT = t * (numColors - 1)  -- Scale t to cover the range of indices
    local index = math.floor(scaledT)
    local fraction = scaledT - index

    -- Handle edge cases where index is out of bounds
    if index >= numColors - 1 then
        return colors[numColors]
    end

    local color1 = colors[index + 1]
    local color2 = colors[index + 2]

    -- Linear interpolation between color1 and color2
    local r = color1[1] + (color2[1] - color1[1]) * fraction
    local g = color1[2] + (color2[2] - color1[2]) * fraction
    local b = color1[3] + (color2[3] - color1[3]) * fraction

    return {r, g, b}
end

function Colorize(text, r, g, b)
    if type(r) == "table" then
        local rgb = r
        r = rgb[1]
        g = rgb[2]
        b = rgb[3]
    end
    return "|cFF" .. string.format("%02x%02x%02x", r * 255, g * 255, b * 255) .. text .. "|r"
end

function StripColors(text)
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    return text
end

local coloredRoles = {
    ["Tank"] = Colorize("Tank", 0.3, 0.6, 1),
    ["Healer"] = Colorize("Healer", 0.2, 1, 0.2),
    ["Damage"] = Colorize("Damage", 1, 0.4, 0.4),
    ["No Role"] = "No Role"
}
function GetColoredRoleText(role)
    if not role then
        return coloredRoles["No Role"]
    end
    return coloredRoles[role]
end

function IsFeigning(unit)
    local unitClass = GetClass(unit)
    if unitClass == "HUNTER" then
        local superwow = IsSuperWowPresent()
        for i = 1, 32 do
            local texture, _, id = UnitBuff(unit, i)
            if superwow then -- Use the ID if SuperWoW is present
                if id == 5384 then -- 5384 is Feign Death
                    return true
                end
            else -- Use the texture otherwise
                if texture == "Interface\\Icons\\Ability_Rogue_FeignDeath" then
                    return true
                end
            end
        end
    end
    return false
end

function HasAura(unit, auraType, auraTexture, auraID)
    local auraFunc = auraType == "Buff" and UnitBuff or UnitDebuff
    local checkCount = auraType == "Buff" and 32 or 16

    local superwow = IsSuperWowPresent()
    for i = 1, checkCount do
        local texture, _, id = auraFunc(unit, i)
        if superwow and auraID then
            if auraID == id then
                return true
            end
        else
            if texture == auraTexture then
                return true
            end
        end
    end
    return false
end

-- Returns an array of the units in the party number or the unit's raid group
function GetRaidPartyMembers(partyNumberOrUnit)
    if not RAID_SUBGROUP_LISTS then
        return {}
    end
    if type(partyNumberOrUnit) == "string" then
        partyNumberOrUnit = FindUnitRaidGroup(partyNumberOrUnit)
    end
    local members = {}
    for frameNumber, raidNumber in pairs(RAID_SUBGROUP_LISTS[partyNumberOrUnit]) do
        table.insert(members, "raid"..raidNumber)
    end
    return members
end

-- Returns the raid unit that this unit is, or nil if the unit is not in the raid
function FindRaidUnit(unit)
    for party = 1, 8 do
        if RAID_SUBGROUP_LISTS[party] then
            for frameNumber, raidNumber in pairs(RAID_SUBGROUP_LISTS[party]) do
                local raidUnit = "raid"..raidNumber
                if UnitIsUnit(unit, raidUnit) then
                    return raidUnit
                end
            end
        end
    end
end

-- Returns the raid group number the unit is part of, or nil if the unit is not in the raid
function FindUnitRaidGroup(unit)
    for party = 1, 8 do
        if RAID_SUBGROUP_LISTS[party] then
            for frameNumber, raidNumber in pairs(RAID_SUBGROUP_LISTS[party]) do
                local raidUnit = "raid"..raidNumber
                if UnitIsUnit(unit, raidUnit) then
                    return party
                end
            end
        end
    end
end

-- Requires SuperWoW
function GetSurroundingPartyMembers(player)
    local units
    if UnitInRaid("player") then
        units = GetRaidPartyMembers(player)
    else
        units = CloneTable(PartyUnits)
        AppendArrayElements(units, PetUnits)
    end

    local inRange = {}
    for _, unit in ipairs(units) do
        local exists, guid = UnitExists(unit)
        if exists and not UnitIsDeadOrGhost(unit) and GetDistanceBetween(player, unit) <= 30 then
            table.insert(inRange, guid)
        end
    end
    return inRange
end

-- Returns the class without the first return variable fluff
function GetClass(unit)
    local _, class = UnitClass(unit)
    return class
end

local classes = {"HUNTER", "ROGUE", "PRIEST", "PALADIN", "DRUID", "SHAMAN", "WARRIOR", "MAGE", "WARLOCK"}
function GetClasses()
    return classes
end

function GetRandomClass()
    return classes[math.random(1, 9)]
end

local classColors = {
    ["DRUID"] = {1.0, 0.49, 0.04},
    ["HUNTER"] = {0.67, 0.83, 0.45},
    ["MAGE"] = {0.41, 0.8, 0.94},
    ["PALADIN"] = {0.96, 0.55, 0.73},
    ["PRIEST"] = {1.0, 1.0, 1.0},
    ["ROGUE"] = {1.0, 0.96, 0.41},
    ["SHAMAN"] = {0.14, 0.35, 1.0},
    ["WARLOCK"] = {0.58, 0.51, 0.79},
    ["WARRIOR"] = {0.78, 0.61, 0.43}
}
function GetClassColor(class, asArray)
    local color = classColors[class]
    if not color then -- Unknown class
        color = {0.7, 0.7, 0.7}
    end
    if asArray then
        return color
    end
    return color[1], color[2], color[3]
end

-- Checks for feign death as well
function IsDeadFriend(unit)
    return (UnitIsDead(unit) or UnitIsCorpse(unit)) and UnitIsFriend("player", unit) and not IsFeigning(unit)
end

local keyModifiers = {"None", "Shift", "Control", "Alt", "Shift+Control", "Shift+Alt", "Control+Alt", "Shift+Control+Alt"}
function GetKeyModifiers()
    return keyModifiers
end

function GetKeyModifier()
    local modifier = IsShiftKeyDown() and "Shift" or ""
    if IsControlKeyDown() then
        if modifier ~= "" then
            modifier = modifier.."+"
        end
        modifier = modifier.."Control"
    end
    if IsAltKeyDown() then
        if modifier ~= "" then
            modifier = modifier.."+"
        end
        modifier = modifier.."Alt"
    end

    if modifier == "" then
        return "None"
    end
    return modifier
end

local buttons = {"LeftButton", "MiddleButton", "RightButton", "Button4", "Button5"}
function GetAllButtons()
    return buttons
end

local upButtons = {}
for _, button in ipairs(buttons) do
    table.insert(upButtons, button.."Up")
end
function GetUpButtons()
    return upButtons
end

local downButtons = {}
for _, button in ipairs(buttons) do
    table.insert(downButtons, button.."Down")
end
function GetDownButtons()
    return downButtons
end

function GetCenterScreenPoint(componentWidth, componentHeight)
    return "TOPLEFT", (GetScreenWidth() / 2) - (componentWidth / 2), -((GetScreenHeight() / 2) - (componentHeight / 2))
end

function GetPowerType(unit)
    return PowerTypeMap[UnitPowerType(unit)]
end

function GetPowerColor(unit)
    return PowerColors[GetPowerType(unit)]
end

-- Returns distance if UnitXP SP3 or SuperWoW is present;
-- 0 if unit is offline, not visible, or unit is enemy and SuperWoW is the distance provider;
-- 9999 if unit is not visible or UnitXP SP3 is not present.
-- Might try to do hacky stuff for people without mods later on.
function GetDistanceTo(unit)
    if not UnitIsConnected(unit) then
        return 0
    end

    if UnitXPSP3 then
        return math.max((UnitXP("distanceBetween", "player", unit) or (9999 + 3)) - 3, 0) -- UnitXP SP3 modded function
    elseif SuperWoW then -- Try to fallback to SuperWoW distance
        return math.max((GetDistanceBetween_SuperWow("player", unit) or (9999 + 3)) - 3, 0)
    end
    return UnitIsVisible(unit) and 0 or 9999
end

local function getDistance(x1, z1, x2, z2)
    local dx = x2 - x1
    local dz = z2 - z1
    return math.sqrt(dx*dx + dz*dz)
end

function GetDistanceBetween_SuperWow(unit1, unit2)
    local x1, z1 = UnitPosition(unit1)
    local x2, z2 = UnitPosition(unit2)
    if not x1 or not x2 then
        return 0
    end
    return getDistance(x1, z1, x2, z2)
end

function GetDistanceBetween(unit1, unit2)
    if not UnitIsConnected(unit1) or not UnitIsConnected(unit2) then
        return 9999
    end
    if UnitXPSP3 then
        return math.max((UnitXP("distanceBetween", unit1, unit2) or (9999 + 3)) - 3, 0) -- UnitXP SP3 modded function
    elseif SuperWoW then
        return math.max((GetDistanceBetween_SuperWow(unit1, unit2) or (9999 + 3)) - 3, 0)
    end
    return (UnitIsVisible(unit1) and UnitIsVisible(unit2)) and 0 or 9999
end

-- SuperWoW cannot provide precise distance for enemies
function CanClientGetPreciseDistance(alsoEnemies)
    return UnitXPSP3 or (SuperWoW and not alsoEnemies)
end

-- Returns whether unit is in sight if UnitXP SP3 is present, otherwise always true.
function IsInSight(unit)
    if not UnitXPSP3 then
        return true
    end
    return UnitXP("inSight", "player", unit) -- UnitXP SP3 modded function
end

function CanClientSightCheck()
    return UnitXPSP3
end

function IsSuperWowPresent()
    return SuperWoW
end

function IsUnitXPSP3Present()
    return UnitXPSP3
end