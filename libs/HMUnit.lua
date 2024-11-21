-- Caches important information about units and makes the data easily readable at any time

HMUnit = {}

-- Non-instance variable
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

function HMUnit.CreateCaches(units)
    for _, unit in ipairs(units) do
        HMUnit:New(unit)
    end
end

function HMUnit.UpdateAllUnits()
    for _, cache in pairs(HMUnit.Cached) do
        cache:UpdateAuras()
    end
end

function HMUnit.Get(unit)
    return HMUnit.Cached[unit]
end

function HMUnit:New(unit)
    local obj = {Unit = unit}
    setmetatable(obj, self)
    self.__index = self
    HMUnit.Cached[unit] = obj
    obj.AurasPopulated = true -- To force aura fields to generate
    obj:UpdateAll()
    return obj
end

function HMUnit:UpdateAll()
    self:UpdateAuras()
end

function HMUnit:ClearAuras()
    if not self.AurasPopulated then
        return
    end
    self.Buffs = {}
    self.BuffsMap = {}
    self.Debuffs = {}
    self.DebuffsMap = {}
    self.TypedDebuffs = {}
    self.AfflictedDebuffTypes = {}
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
        local buff = {name = name, index = index, texture = texture, stacks = stacks, type = type, id = id}
        if not buffsMap[name] then
            buffsMap[name] = {}
        end
        table.insert(buffsMap[name], buff)
        table.insert(buffs, buff)
    end

    local afflictedDebuffTypes = self.AfflictedDebuffTypes
    -- Track player debuffs
    local debuffs = {}
    local debuffsMap = self.DebuffsMap
    local typedDebuffs = self.TypedDebuffs -- Dispellable debuffs
    for index = 1, 16 do
        local texture, stacks, id = UnitDebuff(unit, index)
        if not texture then
            break
        end
        local name, type = HM.GetAuraInfo(unit, "Debuff", index)
        if HealersMateSettings.TrackedHealingDebuffs[name] then
            self.HasHealingModifier = true
        end
        local debuff = {name = name, index = index, texture = texture, stacks = stacks, type = type, id = id}
        if not debuffsMap[name] then
            debuffsMap[name] = {}
        end
        table.insert(debuffsMap[name], debuff)
        if type ~= "" then
            afflictedDebuffTypes[type] = 1
            if not typedDebuffs[type] then
                typedDebuffs[type] = {}
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