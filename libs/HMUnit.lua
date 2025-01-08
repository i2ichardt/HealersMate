-- Caches important information about units and makes the data easily readable at any time.
-- If using SuperWoW, the cache map will have GUIDs as the key instead of unit IDs.

local USE_GUIDS = HMUtil.IsSuperWowPresent()
local AllUnits = HMUtil.AllUnits
local AllUnitsSet = HMUtil.AllUnitsSet
local util = HMUtil

local compost = AceLibrary("Compost-2.0")

HMUnit = {}

-- Non-instance variable
-- Key: Unit ID(Unmodded) or GUID(SuperWoW) | Value: HMUnit Instance
HMUnit.Cached = {}

HMUnit.Unit = nil

HMUnit.AurasPopulated = false
-- Buff/debuff entry contents: {"name", "stacks", "texture", "index", "type", "id"(SuperWoW only)}
HMUnit.Buffs = {} -- Array of all buffs
HMUnit.BuffsMap = {} -- Key: Name | Value: Array of buffs with key's name
HMUnit.Debuffs = {} -- Array of all debuffs
HMUnit.DebuffsMap = {} -- Key: Name | Value: Array of debuffs with key's name
HMUnit.TypedDebuffs = {} -- Key: Type | Value: Array of debuffs that are the type
HMUnit.AfflictedDebuffTypes = {} -- Set of the afflicted debuff types

HMUnit.HasHealingModifier = false

-- Only used with SuperWoW, managed in AuraTracker.lua
HMUnit.AuraTimes = {} -- Key: Aura Name | Value: {"startTime", "duration"}

HMUnit.Distance = 0
HMUnit.InSight = true
HMUnit.IsNew = false

local _G = getfenv(0)
if HMUtil.IsSuperWowPresent() then
    setmetatable(HMUnitProxy, {__index = getfenv(1)})
    setfenv(1, HMUnitProxy)
end

-- Non-GUID function
function HMUnit.CreateCaches()
    if USE_GUIDS then
        HealersMate.hmprint("Tried to create non-SuperWoW caches while using SuperWoW!")
        return
    end
    for _, unit in ipairs(AllUnits) do
        HMUnit:New(unit)
    end
end

function HMUnit.UpdateGuidCaches()
    local cached = HMUnit.Cached
    local prevCached = HMUtil.CloneTableCompost(cached)
    for _, unit in ipairs(AllUnits) do
        local exists, guid = UnitExists(unit)
        if exists then
            if not cached[guid] then
                HMUnit:New(guid)
                HealersMate.EvaluateTracking(unit, true)
            end
            prevCached[guid] = nil
        end
    end
    for guid, units in pairs(HMUnitProxy.GUIDCustomUnitMap) do
        if not cached[guid] then
            HMUnit:New(guid)
            for _, unit in ipairs(units) do
                HealersMate.EvaluateTracking(unit, true)
            end
        end
        prevCached[guid] = nil
    end
    for garbageGuid, cache in pairs(prevCached) do
        cache:Dispose()
        compost:Reclaim(cache)
        cached[garbageGuid] = nil
    end
    compost:Reclaim(prevCached)
end

-- Likely never needed to be called when using GUIDs
function HMUnit.UpdateAllUnits()
    for _, cache in pairs(HMUnit.Cached) do
        cache:UpdateAll()
    end
end

-- Get the HMUnit by unit ID. If using SuperWoW, GUID or unit ID is accepted.
function HMUnit.Get(unit)
    if USE_GUIDS and AllUnitsSet[unit] then
        return HMUnit.Cached[HMGuidRoster.GetUnitGuid(unit)] or HMUnit
    end
    return HMUnit.Cached[unit]
end

function HMUnit.GetAllUnits()
    return HMUnit.Cached
end

function HMUnit:New(unit)
    local obj = compost:AcquireHash("Unit", unit)
    setmetatable(obj, self)
    self.__index = self
    HMUnit.Cached[unit] = obj
    obj:AllocateAuras()
    obj.AurasPopulated = true -- To force aura fields to generate
    obj.IsNew = true
    if USE_GUIDS then
        obj.AuraTimes = compost:GetTable()
    end
    obj:UpdateAll()
    return obj
end

function HMUnit:Dispose()
    compost:Reclaim(self.Buffs, 1)
    compost:Reclaim(self.BuffsMap, 1)
    compost:Reclaim(self.Debuffs, 1)
    compost:Reclaim(self.DebuffsMap, 1)
    compost:Reclaim(self.TypedDebuffs)
    compost:Reclaim(self.AfflictedDebuffTypes)
    compost:Reclaim(self.AuraTimes)
end

function HMUnit:UpdateAll()
    self:UpdateAuras()
    self:UpdateDistance()
    self:UpdateSight()
end

-- Returns true if this unit is new, clearing its new status.
function HMUnit:CheckNew()
    if self.IsNew then
        self.IsNew = false
        return true
    end
end

-- Returns true if the distance changed
function HMUnit:UpdateDistance()
    local prevDist = self.Distance
    self.Distance = util.GetDistanceTo(self.Unit)

    return self.Distance ~= prevDist
end

function HMUnit:GetDistance()
    return self.Distance
end

-- Returns true if the sight state has changed
function HMUnit:UpdateSight()
    if not self.Unit then
        return
    end
    local wasInSight = self.InSight
    self.InSight = util.IsInSight(self.Unit)

    return self.InSight ~= wasInSight
end

function HMUnit:IsInSight()
    return self.InSight
end

function HMUnit:AllocateAuras()
    self.Buffs = compost:GetTable()
    self.BuffsMap = compost:GetTable()
    self.Debuffs = compost:GetTable()
    self.DebuffsMap = compost:GetTable()
    self.TypedDebuffs = compost:GetTable()
    self.AfflictedDebuffTypes = compost:GetTable()
end

function HMUnit:ClearAuras()
    if not self.AurasPopulated or self.Buffs == HMUnit.Buffs then
        return
    end
    compost:Reclaim(self.Buffs, 1)
    compost:Reclaim(self.BuffsMap, 1)
    compost:Reclaim(self.Debuffs, 1)
    compost:Reclaim(self.DebuffsMap, 1)
    compost:Reclaim(self.TypedDebuffs)
    compost:Reclaim(self.AfflictedDebuffTypes)
    self.Buffs = compost:GetTable()
    self.BuffsMap = compost:GetTable()
    self.Debuffs = compost:GetTable()
    self.DebuffsMap = compost:GetTable()
    self.TypedDebuffs = compost:GetTable()
    self.AfflictedDebuffTypes = compost:GetTable()
    self.HasHealingModifier = false
    self.AurasPopulated = false
end

function HMUnit:UpdateAuras()
    local unit = self.Unit

    self:ClearAuras()

    if not UnitExists(unit) then
        return
    end

    local HM = HealersMate

    -- Track player buffs
    local buffs = self.Buffs
    local buffsMap = self.BuffsMap
    for index = 1, 32 do
        local texture, stacks, id = UnitBuff(unit, index)
        if not texture then
            break
        end
        local name, type = HM.GetAuraInfo(unit, "Buff", index)
        if HealersMateSettings.TrackedHealingBuffs[name] then
            self.HasHealingModifier = true
        end
        local buff = compost:AcquireHash("name", name, "index", index, "texture", texture, "stacks", stacks, "type", type, "id", id)
        if not buffsMap[name] then
            buffsMap[name] = compost:GetTable()
        end
        table.insert(buffsMap[name], buff)
        table.insert(buffs, buff)
    end

    local afflictedDebuffTypes = self.AfflictedDebuffTypes
    -- Track player debuffs
    local debuffs = self.Debuffs
    local debuffsMap = self.DebuffsMap
    local typedDebuffs = self.TypedDebuffs -- Dispellable debuffs
    for index = 1, 16 do
        local texture, stacks, type, id = UnitDebuff(unit, index)
        if not texture then
            break
        end
        type = type or ""
        local name = HM.GetAuraInfo(unit, "Debuff", index)
        if HealersMateSettings.TrackedHealingDebuffs[name] then
            self.HasHealingModifier = true
        end
        local debuff = compost:AcquireHash("name", name, "index", index, "texture", texture, "stacks", stacks, "type", type, "id", id)
        if not debuffsMap[name] then
            debuffsMap[name] = compost:GetTable()
        end
        table.insert(debuffsMap[name], debuff)
        if type ~= "" then
            afflictedDebuffTypes[type] = 1
            if not typedDebuffs[type] then
                typedDebuffs[type] = compost:GetTable()
            end
            table.insert(typedDebuffs[type], debuff)
        end
        table.insert(debuffs, debuff)
    end
    self.AurasPopulated = true
end

function HMUnit:HasBuff(name)
    return self.BuffsMap[name] ~= nil
end

-- SuperWoW only
function HMUnit:HasBuffID(id)
    for _, buff in ipairs(self.Buffs) do
        if buff.id == id then
            return true
        end
    end
    return false
end

-- Looks for ID if SuperWoW is present, otherwise searches by name
function HMUnit:HasBuffIDOrName(id, name)
    if HMUtil.IsSuperWowPresent() then
        return self:HasBuffID(id)
    end
    return self:HasBuff(name)
end

function HMUnit:HasDebuff(name)
    return self.DebuffsMap[name] ~= nil
end

-- SuperWoW only
function HMUnit:HasDebuffID(id)
    for _, debuff in ipairs(self.Debuffs) do
        if debuff.id == id then
            return true
        end
    end
    return false
end

-- Looks for ID if SuperWoW is present, otherwise searches by name
function HMUnit:HasDebuffIDOrName(id, name)
    if HMUtil.IsSuperWowPresent() then
        return self:HasDebuffID(id)
    end
    return self:HasDebuff(name)
end

function HMUnit:HasDebuffType(type)
    return self.AfflictedDebuffTypes[type]
end

-- Returns the first buff with the provided name
function HMUnit:GetBuff(name)
    if not self:HasBuff(name) then
        return
    end
    return self.BuffsMap[name][1]
end

-- Returns the table of all buffs with the provided name
function HMUnit:GetBuffs(name)
    return self.BuffsMap[name]
end

function HMUnit:GetDebuff(name)
    if not self:HasDebuff(name) then
        return
    end
    return self.DebuffsMap[name][1]
end

function HMUnit:GetDebuffs(name)
    return self.DebuffsMap[name]
end