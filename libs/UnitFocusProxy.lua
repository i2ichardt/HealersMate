-- Proxy unit functions that resolve focus units to their GUIDs before doing what they do.
-- One might say you'd be insane to do this just to have focus units, and you'd be correct.

-- SuperWoW check, can't rely on HMUtil because it depends on this file
if SpellInfo == nil then
    return
end

HMUnitProxy = {}
local _G = getfenv(0)
setmetatable(HMUnitProxy, {__index = getfenv(1)})
setfenv(1, HMUnitProxy)

MAX_FOCUS_UNITS = 10

local focusUnits = {}
for i = 1, MAX_FOCUS_UNITS do
    focusUnits["focus"..i] = 1
end

local FocusTable = {} -- Temporary empty table

AllProxies = {}

function SetFocusTable(table)
    FocusTable = table
end

function ImportFunctions(env)
    for name, func in pairs(AllProxies) do
        env[name] = func
    end
end

function UnitProxy(name, func, defaultValue)
    local proxy = function(unit)
        if focusUnits[unit] then
            unit = FocusTable[unit]
            if not unit then
                return defaultValue
            end
        end
        if not unit then
            return
        end
        return func(unit)
    end
    HMUnitProxy[name] = proxy
    AllProxies[name] = proxy
end

function DoubleUnitProxy(name, func, defaultValue)
    local proxy = function(unit1, unit2)
        if focusUnits[unit1] then
            unit1 = FocusTable[unit1]
            if not unit1 then
                return defaultValue
            end
        end
        if focusUnits[unit2] then
            unit2 = FocusTable[unit2]
            if not unit2 then
                return defaultValue
            end
        end
        return func(unit1, unit2)
    end
    HMUnitProxy[name] = proxy
    AllProxies[name] = proxy
end

function AuraProxy(name, func, defaultValue)
    local proxy = function(unit, index)
        if focusUnits[unit] then
            unit = FocusTable[unit]
            if not unit then
                return defaultValue
            end
        end
        return func(unit, index)
    end
    HMUnitProxy[name] = proxy
    AllProxies[name] = proxy
end

function CustomProxy(name, constructor)
    local proxy = constructor()
    HMUnitProxy[name] = proxy
    AllProxies[name] = proxy
end

AuraProxy("UnitBuff", _G.UnitBuff, nil)
AuraProxy("UnitDebuff", _G.UnitDebuff, nil)
UnitProxy("UnitExists", _G.UnitExists, false)
UnitProxy("UnitHealth", _G.UnitHealth, 0)
UnitProxy("UnitHealthMax", _G.UnitHealthMax, 0)
UnitProxy("UnitMana", _G.UnitMana, 0)
UnitProxy("UnitManaMax", _G.UnitManaMax, 0)
UnitProxy("UnitIsPlayer", _G.UnitIsPlayer, false)
UnitProxy("UnitIsConnected", _G.UnitIsConnected, false)
UnitProxy("UnitIsDead", _G.UnitIsDead, false)
UnitProxy("UnitIsGhost", _G.UnitIsGhost, false)
UnitProxy("UnitIsDeadOrGhost", _G.UnitIsDeadOrGhost, false)
UnitProxy("UnitIsCorpse", _G.UnitIsCorpse, false)
UnitProxy("UnitClass", _G.UnitClass, "")
UnitProxy("UnitName", _G.UnitName, "Unknown")
UnitProxy("UnitPowerType", _G.UnitPowerType, "mana")
UnitProxy("UnitIsVisible", _G.UnitIsVisible, false)
UnitProxy("TargetUnit", _G.TargetUnit, nil)
DoubleUnitProxy("UnitIsFriend", _G.UnitIsFriend, false)
DoubleUnitProxy("UnitIsEnemy", _G.UnitIsEnemy, false)
DoubleUnitProxy("UnitIsUnit", _G.UnitIsUnit, false)
DoubleUnitProxy("UnitCanAttack", _G.UnitCanAttack, false)
CustomProxy("CastSpellByName", function()
    local CastSpellByName = _G.CastSpellByName
    return function(spell, unit)
        if focusUnits[unit] then
            unit = FocusTable[unit]
            if not unit then
                return
            end
        end
        return CastSpellByName(spell, unit)
    end
end)
-- UnitXP SP3 compatibility
CustomProxy("UnitXP", function()
    local UnitXP = _G.UnitXP
    return function(...)
        local args = arg
        for i = 1, table.getn(args) do
            local arg = args[i]
            if focusUnits[arg] then
                args[i] = FocusTable[arg]
                if not args[i] then
                    return 0
                end
            end
        end
        return UnitXP(unpack(args))
    end
end)