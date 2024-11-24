-- Predicts healing based on previously seen healing.
-- This library currently is not independent and relies on some HealersMate code.

if not HMUtil.IsSuperWowPresent() then
    return
end

HMHealPredict = {}

local _G = getfenv(0)
setmetatable(HMHealPredict, {__index = getfenv(1)})
setfenv(1, HMHealPredict)

RelevantGUIDs = {} -- A set of GUIDs to listen to

IncomingHeals = {} -- Key: Receiver | Value: List of incoming casts
Casts = {} -- Key: Caster | Value: {"targets", "spellID"}
LastCastedSpells = {}

-- A cache of expected heal values for spells. These values are saved.
-- Key: Spell ID | Value: Typical heal value for the spell ID
HealCache = {}

-- Since every healer heals for different values based on talents and gear,
-- everyone's heal values are cached
-- Key: Name | Value: Array: {Spell ID: Heal value}
PlayerHealCache = {}

-- An array of functions that listen to changes to incoming healing
Listeners = {}

local hmprint
local colorize = HMUtil.Colorize

function OnLoad()
    hmprint = HealersMate.hmprint
    if not HMHealCache then
        setglobal("HMHealCache", {})
    end
    HealCache = HMHealCache

    if not HMPlayerHealCache then
        setglobal("HMPlayerHealCache", {})
    end
    if not HMPlayerHealCache[GetRealmName()] then
        HMPlayerHealCache[GetRealmName()] = {}
    end
    PlayerHealCache = HMPlayerHealCache[GetRealmName()]
end

-- Get the expected heal of a player's spell
function GetExpectedHeal(playerName, spellID)
    local playerCache = PlayerHealCache[playerName]
    if not playerCache or not playerCache[spellID] then
        return GetGenericExpectedHeal(spellID)
    end
    return playerCache[spellID]
end

function GetGenericExpectedHeal(spellID)
    return HealCache[spellID] or 0
end

function GetIncomingHealing(guid)
    local casts = IncomingHeals[guid]
    if not casts then
        return 0
    end
    local healing = 0
    for _, cast in pairs(casts) do
        healing = healing + cast["heal"]
    end
    return healing
end

-- To mimick HealComm, but this currently only accepts GUIDs
function getHeal(guid)
    return GetIncomingHealing(guid)
end

-- Used for Prayer of Healing to add incoming healing to multiple players
function AddIncomingMultiCast(targets, caster, spellID, healAmount, castTime)
    Casts[caster] = {
        ["targets"] = targets,
        ["spellID"] = spellID
    }
    for _, target in ipairs(targets) do
        AddIncomingCast(target, caster, spellID, healAmount, castTime, true)
    end
end

function AddIncomingCast(target, caster, spellID, healAmount, castTime, multi)
    if not multi then
        Casts[caster] = {
            ["targets"] = {target},
            ["spellID"] = spellID
        }
    end
    local targetTable = IncomingHeals[target]
    if not targetTable then
        targetTable = {}
        IncomingHeals[target] = targetTable
    end
    targetTable[caster] = {
        ["spellID"] = spellID,
        ["heal"] = healAmount,
        ["castTime"] = castTime,
        ["startTime"] = GetTime()
    }

    UpdateTarget(target)
end

function RemoveIncomingCast(caster)
    local cast = Casts[caster]
    if cast then
        for _, target in ipairs(cast["targets"]) do
            local incomingHeals = IncomingHeals[target]
            incomingHeals[caster] = nil
            UpdateTarget(target)
        end
        Casts[caster] = nil
    end
end

function GetCurrentCast(caster)
    local cast = Casts[caster]
    if cast then
        return IncomingHeals[cast["targets"][1]][caster]
    end
end

function UpdateTarget(target)
    for _, listener in ipairs(Listeners) do
        listener(target, GetIncomingHealing(target))
    end
end

local function trimDecimal(number, places)
    local factor = 10 ^ places
    return math.floor(number * factor) / factor
end

local GENERIC_CHANGE_FACTOR = 0.05
local PLAYER_CHANGE_FACTOR = 0.25
function UpdateCache(heal, name)
    name = name or UnitName("player")
    local lastCastedSpell = LastCastedSpells[name]
    LastCastedSpells[name] = nil

    if not lastCastedSpell then
        return
    end

    local spellID = lastCastedSpell["spellID"]

    -- A rather messy dependency on HealersMate
    local units = HealersMate.GUIDUnitMap[lastCastedSpell["unit"]]
    if not units then
        --hmprint(colorize("Could not find "..name.."'s unit while updating cache!", 1, 0, 0))
        return
    end
    local normalUnit = units[1]
    if HMUnit.Get(normalUnit).HasHealingModifier then
        --hmprint(colorize("Not updating cache for "..name.."'s "..spellID.." because of healing modifier", 0.5, 0.5, 0.5))
        return
    end

    -- Update the generic cache
    if not HealCache[spellID] then
        HealCache[spellID] = heal
    else
        local prevHeal = HealCache[spellID]
        local adjustedHeal = trimDecimal(prevHeal + ((heal - prevHeal) * GENERIC_CHANGE_FACTOR), 2)
        HealCache[spellID] = adjustedHeal
        --hmprint(colorize("Generic "..spellID..": "..prevHeal.." -> "..adjustedHeal, 0, 0.8, 0.8))
    end

    if not PlayerHealCache[name] then
        PlayerHealCache[name] = {}
    end
    -- Update the player-specific cache
    local playerCache = PlayerHealCache[name]
    if not playerCache[spellID] then
        playerCache[spellID] = heal
        --hmprint(colorize("Created cache for "..name.."'s "..spellID, 1, 0.5, 1))
    end
    local prevHeal = playerCache[spellID]
    local adjustedHeal = trimDecimal(prevHeal + ((heal - prevHeal) * PLAYER_CHANGE_FACTOR), 2)
    playerCache[spellID] = adjustedHeal
    playerCache["lastSeen"] = time()

    --hmprint(colorize(name.."'s "..spellID..": "..prevHeal.." -> "..adjustedHeal, 0, 0.8, 0.2))
end

local PRAYER_OF_HEALING_IDS = HMUtil.ToSet({596, 996, 10960, 10961, 25316})

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_CASTEVENT")
eventFrame:SetScript("OnEvent", function()
    local caster, target, event, spellID, duration = arg1, arg2, arg3, arg4, arg5

    if not RelevantGUIDs[caster] then
        return
    end

    if not UnitIsPlayer(caster) then
        return
    end

    -- Check started cast spell ID to prevent instant mid-cast spells from removing incoming healing
    local currentCast = GetCurrentCast(caster)
    if event == "CAST" and currentCast and currentCast["spellID"] == spellID then
        RemoveIncomingCast(caster)
        LastCastedSpells[UnitName(caster)] = {unit = caster, spellID = spellID}
        return
    end

    if event == "START" or event == "FAIL" then
        RemoveIncomingCast(caster)
    end

    if event == "START" then
        if target and target ~= "" and UnitCanAssist(caster, target) and duration > 0 then
            local casterName = UnitName(caster)
            local expectedHeal = GetExpectedHeal(casterName, spellID)
            AddIncomingCast(target, caster, spellID, expectedHeal, duration)
        elseif PRAYER_OF_HEALING_IDS[spellID] then
            local inRange = HMUtil.GetSurroundingPartyMembers(caster)
            local casterName = UnitName(caster)
            local expectedHeal = GetExpectedHeal(casterName, spellID)
            AddIncomingMultiCast(inRange, caster, spellID, expectedHeal, duration)
        end
    end
end)
-- Because the prediction code is not currently bullet-proof to infinite incoming heals, we're checking once a while for old casts
local GARBAGE_CHECK_INTERVAL = 10
local nextGarbageCheck = GetTime() + GARBAGE_CHECK_INTERVAL
eventFrame:SetScript("OnUpdate", function()
    if GetTime() > nextGarbageCheck then
        local time = GetTime()
        nextGarbageCheck = time + GARBAGE_CHECK_INTERVAL

        for receiver, casts in pairs(IncomingHeals) do
            for caster, cast in pairs(casts) do
                if cast["startTime"] + 15 < time then
                    --hmprint(colorize("Removed "..caster.."'s heal on "..receiver.." for taking too long", 1, 0, 0))
                    casts[caster] = nil
                    UpdateTarget(receiver)
                end
            end
        end
    end
end)

local combatLogFrame = CreateFrame("Frame")
combatLogFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
combatLogFrame:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
combatLogFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF") -- Needed to see casts coming from other players to yourself
combatLogFrame:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
combatLogFrame:SetScript("OnEvent", function()
    if string.find(arg1, "critically") then
        return
    end

    local cmatch = HMUtil.cmatch

    local spell, targetName, heal = cmatch(arg1, HEALEDSELFOTHER) -- "Your %s heals %s for %d."
    if spell and targetName and heal then
        UpdateCache(tonumber(heal))
        return
    end

    local spell, heal = cmatch(arg1, HEALEDSELFSELF) -- "Your %s heals you for %d."
    if spell and heal then
        UpdateCache(tonumber(heal))
        return
    end

    local name, spell, heal = cmatch(arg1, HEALEDOTHERSELF) -- "%s's %s heals you for %d."
    if name and spell and heal then
        UpdateCache(tonumber(heal), name)
        return
    end

    local name, spell, targetName, heal = cmatch(arg1, HEALEDOTHEROTHER) -- "%s's %s heals %s for %d."
    if name and spell and targetName and heal then
        UpdateCache(tonumber(heal), name)
        return
    end
end)

-- Set the GUIDs to listen to
function SetRelevantGUIDs(guidArray)
    RelevantGUIDs = HMUtil.ToSet(guidArray)
end

-- Provided listener function will receive the arguments: Updated GUID, Updated Incoming Healing
function HookUpdates(listener)
    table.insert(Listeners, listener)
end
