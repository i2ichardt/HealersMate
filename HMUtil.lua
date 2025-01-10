-- Contains standalone utility functions that cause no side effects and don't require data from other files, other than the unit proxy

HMUtil = {}

local _G = getfenv(0)
setmetatable(HMUtil, {__index = getfenv(1)})
setfenv(1, HMUtil)

Classes = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}
HealerClasses = {"PRIEST", "DRUID", "SHAMAN", "PALADIN"}

UnitXPSP3 = pcall(UnitXP, "inSight", "player", "player") -- WTB better way to check for UnitXP SP3
UnitXPSP3_Version = -1
if UnitXPSP3 and pcall(UnitXP, "version", "coffTimeDateStamp") then
    UnitXPSP3_Version = UnitXP("version", "coffTimeDateStamp") or -1
end
SuperWoW = SpellInfo ~= nil
Nampower = QueueSpellByName ~= nil

TurtleWow = true

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
CustomUnits = HMUnitProxy and HMUnitProxy.AllCustomUnits or {}
CustomUnitsSet = HMUnitProxy and HMUnitProxy.AllCustomUnitsSet or {}
FocusUnits = HMUnitProxy and HMUnitProxy.CustomUnitsMap["focus"] or {}
if HMUnitProxy then
    HMUnitProxy.ImportFunctions(HMUtil)
end

local unitArrays = {PartyUnits, PetUnits, RaidUnits, RaidPetUnits, TargetUnits}
AllUnits = {}
for _, unitArray in ipairs(unitArrays) do
    for _, unit in ipairs(unitArray) do
        table.insert(AllUnits, unit)
    end
end
AllRealUnits = {}
for i, unit in ipairs(AllUnits) do
    AllRealUnits[i] = unit
end
if HMUnitProxy then
    for _, unit in ipairs(CustomUnits) do
        table.insert(AllUnits, unit)
    end
    HMUnitProxy.RegisterUpdateListener(function()
        local i = 1
        for _, unit in ipairs(AllRealUnits) do
            AllUnits[i] = unit
            i = i + 1
        end
        for _, unit in ipairs(CustomUnits) do
            AllUnits[i] = unit
            i = i + 1
        end
        ClearTable(AllUnitsSet)
        for k, v in pairs(ToSet(AllUnits)) do
            AllUnitsSet[k] = v
        end
    end)
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

local compost = AceLibrary("Compost-2.0")
function CloneTableCompost(table, deep)
    local clone = compost:GetTable()
    for k, v in pairs(table) do
        if deep and type(v) == "table" then
            clone[k] = CloneTable(v, true)
        else
            clone[k] = v
        end
    end
    return clone
end

function ClearTable(table)
    for k, v in pairs(table) do
        table[k] = nil
    end
end

-- Courtesy of ChatGPT
function SplitString(str, delimiter)
    local result = {}
    local pattern = "([^" .. delimiter .. "]+)"  -- The pattern to match substrings excluding the delimiter
    for part in string.gmatch(str, pattern) do
        table.insert(result, part)
    end
    return result
end

function StartsWith(str, starts)
    return string.sub(str, 1, string.len(starts)) == starts
end

function RoundNumber(number, decimalPlaces)
    decimalPlaces = decimalPlaces or 0
    return math.floor(number * 10^decimalPlaces + 0.5) / 10^decimalPlaces
end

-- Courtesy of ChatGPT
function InterpolateColors(colors, t)
    local r, g, b = InterpolateColorsNoTable(colors, t)
    return {r, g, b}
end

function InterpolateColorsNoTable(colors, t)
    local numColors = table.getn(colors)
    
    -- Ensure t is between 0 and 1
    t = math.max(0, math.min(1, t))

    -- If there are fewer than 2 colors, just return the single color
    if numColors < 2 then
        local c = colors[1]
        return c[1], c[2], c[3]
    end

    -- Determine the segment in which t falls
    local scaledT = t * (numColors - 1)  -- Scale t to cover the range of indices
    local index = math.floor(scaledT)
    local fraction = scaledT - index

    -- Handle edge cases where index is out of bounds
    if index >= numColors - 1 then
        local c = colors[numColors]
        return c[1], c[2], c[3]
    end

    local color1 = colors[index + 1]
    local color2 = colors[index + 2]

    -- Linear interpolation between color1 and color2
    local r = color1[1] + (color2[1] - color1[1]) * fraction
    local g = color1[2] + (color2[2] - color1[2]) * fraction
    local b = color1[3] + (color2[3] - color1[3]) * fraction

    return r, g, b
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

-- Deprecated
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

function GetBagSlotInfo(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if not link then
        return
    end
    local _, _, name = string.find(link, "%[(.*)%]")
    local _, count = GetContainerItemInfo(bag, slot)
    return name, count
end

-- Returns: Bag index, Slot index
function FindBagSlot(itemName)
    local bestBag, bestSlot, lowestStackSize
    for bag = 0, NUM_BAG_FRAMES do
        for slot = 1, GetContainerNumSlots(bag) do
            local name, count = GetBagSlotInfo(bag, slot)
            if itemName == name then
                if not lowestStackSize or lowestStackSize > count then
                    bestBag = bag
                    bestSlot = slot
                    lowestStackSize = count
                end
            end
        end
    end
    return bestBag, bestSlot
end

-- Returns true if an item was found and attempted to be used
function UseItem(itemName)
    local bag, slot = FindBagSlot(itemName)
    if not bag then
        return
    end
    UseContainerItem(bag, slot)
    return true
end

function GetItemCount(itemName)
    local total = 0
    for bag = 0, NUM_BAG_FRAMES do
        for slot = 1, GetContainerNumSlots(bag) do
            local name, count = GetBagSlotInfo(bag, slot)
            if itemName == name then
                total = total + count
            end
        end
    end
    return total
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
    if RAID_SUBGROUP_LISTS[partyNumberOrUnit] then
        for frameNumber, raidNumber in pairs(RAID_SUBGROUP_LISTS[partyNumberOrUnit]) do
            table.insert(members, RaidUnits[raidNumber])
        end
    end
    return members
end

-- Returns the raid unit that this unit is, or nil if the unit is not in the raid
function FindRaidUnit(unit)
    if not RAID_SUBGROUP_LISTS then
        return {}
    end
    for party = 1, 8 do
        if RAID_SUBGROUP_LISTS[party] then
            for frameNumber, raidNumber in pairs(RAID_SUBGROUP_LISTS[party]) do
                local raidUnit = RaidUnits[raidNumber]
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
                local raidUnit = RaidUnits[raidNumber]
                if UnitIsUnit(unit, raidUnit) then
                    return party
                end
            end
        end
    end
end

-- Requires SuperWoW
function GetSurroundingPartyMembers(player, range)
    local units
    if UnitInRaid("player") then
        units = GetRaidPartyMembers(player)
    else
        units = CloneTable(PartyUnits)
        AppendArrayElements(units, PetUnits)
    end

    return GetUnitsInRange(player, units, range or 30)
end

function GetSurroundingRaidMembers(player, range, checkPets)
    local units
    if UnitInRaid("player") then
        units = CloneTable(RaidUnits)
        if checkPets then
            AppendArrayElements(units, RaidPetUnits)
        end
    else
        units = CloneTable(PartyUnits)
        if checkPets then
            AppendArrayElements(units, PetUnits)
        end
    end

    return GetUnitsInRange(player, units, range or 30)
end

function GetUnitsInRange(center, units, range)
    local inRange = {}
    for _, unit in ipairs(units) do
        local exists, guid = UnitExists(unit)
        if exists and not UnitIsDeadOrGhost(unit) and GetDistanceBetween(center, unit) <= (range or 30) then
            table.insert(inRange, guid)
        end
    end
    return inRange
end

-- Blizzard's UI functions seem to get called referring to a global called "this" referring to the UI object.
-- This function calls a function on the object, emulating the "this" variable.
function CallWithThis(object, func)
    local prevThis = _G.this
    _G.this = object
    func()
    _G.this = prevThis
end

-- Returns the class without the first return variable fluff
function GetClass(unit)
    local _, class = UnitClass(unit)
    return class
end

function GetClasses()
    return Classes
end

function GetRandomClass()
    return Classes[math.random(1, 9)]
end

local healerClassesSet = ToSet(HealerClasses)
function IsHealerClass(unit)
    return healerClassesSet[GetClass(unit)] == 1
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

-- L1: Shift
-- L2: Control
-- L3: Alt
local keyModifierMap = {
    [true] = {
        [true] = {
            [true] = "Shift+Control+Alt",
            [false] = "Shift+Control"
        },
        [false] = {
            [true] = "Shift+Alt",
            [false] = "Shift"
        }
    },
    [false] = {
        [true] = {
            [true] = "Control+Alt",
            [false] = "Control"
        },
        [false] = {
            [true] = "Alt",
            [false] = "None"
        }
    }
}
function GetKeyModifier()
    return keyModifierMap[IsShiftKeyDown() == 1][IsControlKeyDown() == 1][IsAltKeyDown() == 1]
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
-- 0 if unit is offline, or unit is enemy and SuperWoW is the distance provider;
-- 9999 if unit is not visible or UnitXP SP3 is not present.
-- Might try to do hacky stuff for people without mods later on.
function GetDistanceTo(unit)
    return GetDistanceBetween("player", unit)
end

function GetDistanceBetween_SuperWow(unit1, unit2)
    if not UnitIsConnected(unit1) or not UnitIsConnected(unit2) then
        return 0
    end

    if not UnitIsVisible(unit1) or not UnitIsVisible(unit2) then
        return 9999
    end

    local x1, z1, y1 = UnitPosition(unit1)
    local x2, z2, y2 = UnitPosition(unit2)
    
    if not x1 or not x2 then
        return 0
    end
    local dx = x2 - x1
    local dz = z2 - z1
    local dy = y2 - y1
    return math.sqrt(dx*dx + dz*dz + dy*dy)
end

function GetDistanceBetween_UnitXPSP3_Legacy(unit1, unit2)
    if not UnitIsConnected(unit1) or not UnitIsConnected(unit2) then
        return 0
    end

    if not UnitIsVisible(unit1) or not UnitIsVisible(unit2) then
        return 9999
    end

    return math.max((UnitXP("distanceBetween", unit1, unit2) or (9999 + 3)) - 3, 0) -- UnitXP SP3 modded function
end

function GetDistanceBetween_UnitXPSP3(unit1, unit2)
    if not UnitIsConnected(unit1) or not UnitIsConnected(unit2) then
        return 0
    end

    if not UnitIsVisible(unit1) or not UnitIsVisible(unit2) then
        return 9999
    end

    return math.max(UnitXP("distanceBetween", unit1, unit2) or 9999, 0) -- UnitXP SP3 modded function
end

function GetDistanceBetween_Vanilla(unit1, unit2)
    if not UnitIsConnected(unit1) or not UnitIsConnected(unit2) then
        return 0
    end

    if not UnitIsVisible(unit1) or not UnitIsVisible(unit2) then
        return 9999
    end

    if unit1 == "player" then
        if CheckInteractDistance(unit2, 3) then
            return 9
        end
        if CheckInteractDistance(unit2, 4) then
            return 27
        end
    end

    return 28
end

if UnitXPSP3 then
    if UnitXPSP3_Version > -1 then -- Newer versions have more accurate distances
        GetDistanceBetween = GetDistanceBetween_UnitXPSP3
    else -- Fall back to old distance calculation
        GetDistanceBetween = GetDistanceBetween_UnitXPSP3_Legacy
    end
elseif SuperWoW then
    GetDistanceBetween = GetDistanceBetween_SuperWow
else -- sad
    GetDistanceBetween = GetDistanceBetween_Vanilla
end

-- SuperWoW cannot provide precise distance for enemies
function CanClientGetPreciseDistance(alsoEnemies)
    return UnitXPSP3 or (SuperWoW and not alsoEnemies)
end

-- Returns whether unit is in sight if UnitXP SP3 is present, otherwise always true.
IsInSight = function()
    return true
end

do -- This is done to prevent crashes from checking sight too early
    local sightEnableFrame = CreateFrame("Frame")
    sightEnableFrame:RegisterEvent("ADDON_LOADED")
    sightEnableFrame:SetScript("OnEvent", function()
        if arg1 == "HealersMate" and UnitXPSP3 then
            IsInSight = function(unit)
                return UnitXP("inSight", "player", unit) -- UnitXP SP3 modded function
            end
            sightEnableFrame:SetScript("OnEvent", nil)
        end
    end)
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

-- Only detects Pepopo's Nampower
function IsNampowerPresent()
    return Nampower
end

function IsTurtleWow()
    return TurtleWow
end

AllUnitsSet = ToSet(AllUnits)
FocusUnitsSet = ToSet(FocusUnits)