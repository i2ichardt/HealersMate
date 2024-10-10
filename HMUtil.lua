-- Contains standalone utility functions that cause no side effects and don't require data from other files

HMUtil = {}

local _G = getfenv(0)
setmetatable(HMUtil, {__index = getfenv(1)})
setfenv(1, HMUtil)

Classes = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}

PowerColors = {
	["mana"] = {0.1, 0.1, 1}, --{r = 0, g = 0, b = 0.882}, Not accurate, changed color to make brighter
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

-- Returns a new table with the elements of the given array being the keys with 1 being the value of all keys
function ToSet(array)
    local set = {}
    for _, value in ipairs(array) do
        set[value] = 1
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

function IsFeigning(unit)
    local unitClass = GetClass(unit)
    if unitClass == "HUNTER" then
        local superwow = HealersMate.IsSuperWowEnabled()
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

    local superwow = HealersMate.IsSuperWowEnabled()
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

function GetKeyModifier()
	local modifier = "None"
	if IsShiftKeyDown() then
		modifier = "Shift"
	elseif IsControlKeyDown() then
		modifier = "Control"
	elseif IsAltKeyDown() then
		modifier = "Alt"
	end
	return modifier
end

function GetPowerType(unit)
	return PowerTypeMap[UnitPowerType(unit)]
end

function GetPowerColor(unit)
	return PowerColors[GetPowerType(unit)]
end