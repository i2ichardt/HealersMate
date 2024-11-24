SLASH_HEALERSMATE1 = "/healersmate"
SLASH_HEALERSMATE2 = "/hm"
SlashCmdList["HEALERSMATE"] = function(args)
    if args == "reset" then
        for _, group in pairs(HealersMate.HealUIGroups) do
            local gc = group:GetContainer()
            gc:ClearAllPoints()
            gc:SetPoint(HMUtil.GetCenterScreenPoint(gc:GetWidth(), gc:GetHeight()))
        end
        HealersMateSettings.HM_SettingsContainer:ClearAllPoints()
        HealersMateSettings.HM_SettingsContainer:SetPoint("CENTER", 0, 0)
        DEFAULT_CHAT_FRAME:AddMessage("Reset all frame positions.")
    elseif args == "check" then
        HealersMate.CheckGroup()
    elseif args == "update" then
        for _, ui in pairs(HealersMate.HealUIs) do
            ui:SizeElements()
            ui:UpdateAll()
        end
        for _, group in pairs(HealersMate.HealUIGroups) do
            group:ApplyProfile()
            group:UpdateUIPositions()
        end
    elseif args == "testui" then
        HMOptions.TestUI = not HMOptions.TestUI
        HealersMate.TestUI = HMOptions.TestUI
        if HMOptions.TestUI then
            for _, ui in pairs(HealersMate.HealUIs) do
                ui.fakeStats = ui.GenerateFakeStats()
                ui:Show()
            end
        end
        HealersMate.CheckGroup()
        DEFAULT_CHAT_FRAME:AddMessage("UI Testing is now "..(not HMOptions.TestUI and 
            HMUtil.Colorize("off", 1, 0.6, 0.6) or HMUtil.Colorize("on", 0.6, 1, 0.6))..".")
    elseif args == "toggle" then
        HMOptions.Hidden = not HMOptions.Hidden
        HealersMate.CheckGroup()
        DEFAULT_CHAT_FRAME:AddMessage("The HealersMate UI is now "..(HMOptions.Hidden and 
            HMUtil.Colorize("hidden", 1, 0.6, 0.6) or HMUtil.Colorize("shown", 0.6, 1, 0.6))..".")
    elseif args == "show" then
        HMOptions.Hidden = false
        HealersMate.CheckGroup()
        DEFAULT_CHAT_FRAME:AddMessage("The HealersMate UI is now "..(HMOptions.Hidden and 
            HMUtil.Colorize("hidden", 1, 0.6, 0.6) or HMUtil.Colorize("shown", 0.6, 1, 0.6))..".")
    elseif args == "hide" then
        HMOptions.Hidden = true
        HealersMate.CheckGroup()
        DEFAULT_CHAT_FRAME:AddMessage("The HealersMate UI is now "..(HMOptions.Hidden and 
            HMUtil.Colorize("hidden", 1, 0.6, 0.6) or HMUtil.Colorize("shown", 0.6, 1, 0.6))..".")
    elseif args == "silent" then
        HMOnLoadInfoDisabled = not HMOnLoadInfoDisabled
        DEFAULT_CHAT_FRAME:AddMessage("Load message is now "..(HMOnLoadInfoDisabled and 
            HMUtil.Colorize("off", 1, 0.6, 0.6) or HMUtil.Colorize("on", 0.6, 1, 0.6))..".")
    elseif args == "help" or args == "?" then
        DEFAULT_CHAT_FRAME:AddMessage(HMUtil.Colorize("/hm", 0, 0.8, 0).." -- Opens the addon configuration")
        DEFAULT_CHAT_FRAME:AddMessage(HMUtil.Colorize("/hm reset", 0, 0.8, 0).." -- Resets all heal frame positions")
        DEFAULT_CHAT_FRAME:AddMessage(HMUtil.Colorize("/hm testui", 0, 0.8, 0)..
            " -- Toggles fake players to see how the UI would look")
        DEFAULT_CHAT_FRAME:AddMessage(HMUtil.Colorize("/hm toggle", 0, 0.8, 0).." -- Shows/hides the UI")
        DEFAULT_CHAT_FRAME:AddMessage(HMUtil.Colorize("/hm show", 0, 0.8, 0).." -- Shows the UI")
        DEFAULT_CHAT_FRAME:AddMessage(HMUtil.Colorize("/hm hide", 0, 0.8, 0).." -- Hides the UI")
        DEFAULT_CHAT_FRAME:AddMessage(HMUtil.Colorize("/hm silent", 0, 0.8, 0).." -- Turns off/on message when addon loads")
    elseif args == "" then
        local container = HealersMateSettings.HM_SettingsContainer
        if container then
            if container:IsVisible() then
                container:Hide()
            else
                container:Show()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("HM_SettingsContainer frame not found.")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("Unknown subcommand. See usage with /hm help")
    end
end

HealersMate = {}
local _G = getfenv(0)
setmetatable(HealersMate, {__index = getfenv(1)})
setfenv(1, HealersMate)

VERSION = "2.0.0-alpha4"

TestUI = false

local util = HMUtil
local colorize = util.Colorize
local GetKeyModifier = util.GetKeyModifier
local GetClass = util.GetClass
local GetPowerType = util.GetPowerType
local GetColoredRoleText = util.GetColoredRoleText

PartyUnits = util.PartyUnits
PetUnits = util.PetUnits
TargetUnits = util.TargetUnits
RaidUnits = util.RaidUnits
RaidPetUnits = util.RaidPetUnits
AllUnits = util.AllUnits

-- TODO: Actually use this
UIGroupInfo = {}
UIGroupInfo["Party"] = {
    units = PartyUnits,
    environment = "party",
    enableCondition = function()
        return true
end}
UIGroupInfo["Pets"] = {
    units = PetUnits,
    environment = "party",
    enableCondition = function()
        return true
    end
}
UIGroupInfo["Raid"] = {
    units = RaidUnits,
    environment = "raid",
    enableCondition = function()
        return true
    end
}
UIGroupInfo["Raid Pets"] = {
    units = RaidPetUnits,
    environment = "raid",
    enableCondition = function()
        return true
    end
}
UIGroupInfo["Target"] = {
    units = TargetUnits,
    environment = "all",
    enableCondition = function()
        return true
    end
}

-- Relic of previous versions, may be removed
PreviousHealth = {} --This is used to determine if the player gained or lost health, used in the scrolling combat text functions
for _, unit in ipairs(AllUnits) do
    PreviousHealth[unit] = -1
end

ReadableButtonMap = {
    ["LeftButton"] = "Left",
    ["MiddleButton"] = "Middle",
    ["RightButton"] = "Right",
    ["Button4"] = "Button 4",
    ["Button5"] = "Button 5"
}

ResurrectionSpells = {
    ["PRIEST"] = "Resurrection",
    ["PALADIN"] = "Redemption",
    ["SHAMAN"] = "Ancestral Spirit",
    ["DRUID"] = "Rebirth"
}

GameTooltip = CreateFrame("GameTooltip", "HMGameTooltip", UIParent, "GameTooltipTemplate")

CurrentlyHeldButton = nil
SpellsTooltip = CreateFrame("GameTooltip", "HMSpellsTooltip", UIParent, "GameTooltipTemplate")
SpellsTooltipOwner = nil

local hmBarsPath = util.GetAssetsPath().."textures\\bars\\"
BarStyles = {
    ["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
    ["Blizzard Raid"] = hmBarsPath.."Blizzard-Raid",
    ["HealersMate"] = hmBarsPath.."HealersMate",
    ["HealersMate Borderless"] = hmBarsPath.."HealersMate-Borderless",
    ["HealersMate Shineless"] = hmBarsPath.."HealersMate-Shineless",
    ["HealersMate Shineless Borderless"] = hmBarsPath.."HealersMate-Shineless-Borderless"
}

-- Contains all individual player healing UIs
HealUIs = {}
-- Contains all the healing UI groups
HealUIGroups = {}

CurrentlyInRaid = false

AssignedRoles = nil


--This is just to respond to events "EventHandlerFrame" never appears on the screen
local EventHandlerFrame = CreateFrame("Frame", "HMEventHandlerFrame", UIParent)
EventHandlerFrame:RegisterEvent("ADDON_LOADED"); -- This triggers once for every addon that was loaded after this addon
EventHandlerFrame:RegisterEvent("PLAYER_LOGOUT"); -- Fired when about to log out
EventHandlerFrame:RegisterEvent("PLAYER_QUITING"); -- Fired when a player has the quit option on screen
EventHandlerFrame:RegisterEvent("UNIT_HEALTH") --“UNIT_HEALTH” fires when a unit’s health changes
EventHandlerFrame:RegisterEvent("UNIT_MAXHEALTH")
EventHandlerFrame:RegisterEvent("UNIT_AURA") -- Register for the "UNIT_AURA" event to update buffs and debuffs
EventHandlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Fired when the player enters the world, reloads the UI, or zones between map instances. Basically, it triggers whenever a loading screen appears2. This includes logging in, respawning at a graveyard, entering/leaving an instance, and other situations where a loading screen is presented.
EventHandlerFrame:RegisterEvent("PARTY_MEMBERS_CHANGED") -- Fired when someone joins or leaves the group
EventHandlerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
EventHandlerFrame:RegisterEvent("RAID_ROSTER_UPDATE")
EventHandlerFrame:RegisterEvent("UNIT_PET")
EventHandlerFrame:RegisterEvent("PLAYER_PET_CHANGED")
EventHandlerFrame:RegisterEvent("SPELLS_CHANGED")

EventHandlerFrame:RegisterEvent("UNIT_MANA")
EventHandlerFrame:RegisterEvent("UNIT_RAGE")
EventHandlerFrame:RegisterEvent("UNIT_ENERGY")
EventHandlerFrame:RegisterEvent("UNIT_FOCUS")
EventHandlerFrame:RegisterEvent("UNIT_MAXMANA")

local lastModifier = "None"
EventHandlerFrame:SetScript("OnUpdate", function()
    local modifier = GetKeyModifier()
    if lastModifier ~= modifier then
        lastModifier = modifier
        if SpellsTooltip:IsVisible() then
            ReapplySpellsTooltip()
        end
    end
end)

do
    local almostAllUnits = util.CloneTable(AllUnits) -- Everything except the player
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
    local distanceCheckerFrame = CreateFrame("Frame", "HMDistanceCheckerFrame", UIParent)
    distanceCheckerFrame:SetScript("OnUpdate", function()
        local time = GetTime()
        if time > nextTrackingUpdate then
            nextTrackingUpdate = time + math.random(0.5, 2)
    
            distanceTrackedUnits = {}
            local prevSightTrackedUnits = sightTrackedUnits
            sightTrackedUnits = {}
            for _, unit in ipairs(almostAllUnits) do
                local dist = util.GetDistanceTo(unit)
                HealUIs[unit]:CheckRange(dist)
                if dist < 60 and dist > 20 then -- Only closely track units that are close to the range threshold
                    table.insert(distanceTrackedUnits, unit)
                end
                if dist < 80 and sightTrackingEnabled then
                    table.insert(sightTrackedUnits, unit)
                end
            end

            -- Check sight on previously tracked units in case they got removed
            for _, unit in ipairs(prevSightTrackedUnits) do
                HealUIs[unit]:CheckSight()
            end
        end
    
        if time > nextUpdate then
            nextUpdate = time + 0.1
            for _, unit in ipairs(distanceTrackedUnits) do
                HealUIs[unit]:CheckRange()
            end
            for _, unit in ipairs(sightTrackedUnits) do
                HealUIs[unit]:CheckSight()
            end
        end
    end)
end

-- If SuperWoW is present, then a GUID map will be populated
if util.IsSuperWowPresent() then
    GUIDUnitMap = {} -- Key: GUID, Value: Array of units associated with GUID
end

function Debug(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function GetSpells()
    return HMSpells["Friendly"]
end

function GetHostileSpells()
    return HMSpells["Hostile"]
end

function UpdateHealUIGroups()
    for _, group in pairs(HealUIGroups) do
        group:UpdateUIPositions()
    end
end

local ScanningTooltip = CreateFrame("GameTooltip", "HMScanningTooltip", nil, "GameTooltipTemplate");
ScanningTooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
-- Allow tooltip SetX() methods to dynamically add new lines based on these
ScanningTooltip:AddFontStrings(
    ScanningTooltip:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
    ScanningTooltip:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ) );

-- Thanks ChatGPT
function ExtractSpellRank(spellname)
    -- Find the starting position of "Rank "
    local start_pos = string.find(spellname, "Rank ")

    -- Check if "Rank " was found
    if start_pos then
        -- Adjust start_pos to point to the first digit
        --start_pos = start_pos + 5  -- Move past "Rank "

        -- Find the ending parenthesis
        local end_pos = string.find(spellname, ")", start_pos)

        -- Extract the number substring
        if end_pos then
            local number_str = string.sub(spellname, start_pos, end_pos - 1)
            --local number = tonumber(number_str)  -- Convert to a number

            return number_str
        end
    end
    return nil
end

-- Thanks again ChatGPT
local tooltipResources = {"Mana", "Rage", "Energy"}
function ExtractResourceCost(costText)

    -- First extract resource type
    local resource
    for _, r in ipairs(tooltipResources) do
        if string.find(costText, r) then
            resource = string.lower(r)
            break
        end
    end

    -- No resource found, this spell is probably free
    if not resource then
        return 0
    end

    -- Find the position where non-digit characters start
    local num_end = string.find(costText, "%D")

    -- If a non-digit character is found, extract the number
    if num_end then
        -- Extract the number substring from the start to the position before the non-digit character
        local number_str = string.sub(costText, 1, num_end - 1)
        -- Convert the substring to a number
        local number = tonumber(number_str)
        -- Print the result
        return number, resource
    else
        -- If no non-digit character is found, the entire string is a number
        local number = tonumber(costText)
        return number, resource
    end
end


function GetSpellID(spellname)
    local id = 1;
    local matchingSpells = {}
    local spellRank = ExtractSpellRank(spellname)

    if spellRank ~= nil then
        spellname = string.gsub(spellname, "%b()", "")
    end

    for i = 1, GetNumSpellTabs() do
        local _, _, _, numSpells = GetSpellTabInfo(i);
        for j = 1, numSpells do
            local spellName, rank, realID = GetSpellName(id, "spell");
            if spellName == spellname then
                if rank == spellRank then -- If the rank is specified, then we can check if this is the right spell
                    return id
                else
                    table.insert(matchingSpells, id)
                end
            end
            id = id + 1;
        end
    end
    return matchingSpells[table.getn(matchingSpells)]
end

-- Returns the numerical cost and the resource name; "unknown" if the spell is unknown; 0 if the spell is free
function GetResourceCost(spellName)
    ScanningTooltip:SetOwner(UIParent, "ANCHOR_NONE");

    local spellID = GetSpellID(spellName)
    if not spellID then
        return "unknown"
    end

    ScanningTooltip:SetSpell(spellID, "spell")

    local leftText = getglobal("HMScanningTooltipTextLeft"..2)

    if leftText:GetText() then
        return ExtractResourceCost(leftText:GetText())
    end
    return 0
end

-- Returns the aura's name and its school type
function GetAuraInfo(unit, type, index)
    -- Make these texts blank since they don't clear otherwise
    local leftText = getglobal("HMScanningTooltipTextLeft1")
    leftText:SetText("")
    local rightText = getglobal("HMScanningTooltipTextRight1")
    rightText:SetText("")
    if type == "Buff" then
        ScanningTooltip:SetUnitBuff(unit, index)
    else
        ScanningTooltip:SetUnitDebuff(unit, index)
    end
    return leftText:GetText() or "", rightText:GetText() or ""
end

function ApplySpellsTooltip(attachTo, unit)
    if not HMOptions.ShowSpellsTooltip then
        return
    end

    local spellList = {}
    local modifier = GetKeyModifier()
    local settings = HealersMateSettings
    local spells = UnitCanAttack("player", unit) and GetHostileSpells() or GetSpells()

    local deadFriend = util.IsDeadFriend(unit)
    local selfClass = GetClass("player")
    local canResurrect = deadFriend and ResurrectionSpells[selfClass]
    -- Holy Champion Texture: Interface\\Icons\\Spell_Holy_ProclaimChampion_02
    local canReviveChampion = canResurrect and GetSpellID("Revive Champion") and 
        HMUnit.Get(unit):HasBuffIDOrName(45568, "Holy Champion") and UnitAffectingCombat("player")

    for _, btn in ipairs(settings.CustomButtonOrder) do
        if canResurrect then -- Show all spells as the resurrection spell
            local kv = {}
            local readableButton = settings.CustomButtonNames[btn] or ReadableButtonMap[btn]
            kv[readableButton] = canReviveChampion and "Revive Champion" or ResurrectionSpells[selfClass]
            table.insert(spellList, kv)
        else
            if spells[modifier][btn] or (settings.ShowEmptySpells and not settings.IgnoredEmptySpells[btn]) then
                local kv = {}
                local readableButton = settings.CustomButtonNames[btn] or ReadableButtonMap[btn]
                kv[readableButton] = spells[modifier][btn] or "Unbound"
                table.insert(spellList, kv)
            end
        end
    end
    ShowSpellsTooltip(attachTo, spellList, attachTo)
end

local tooltipPowerColors = {
    ["mana"] = {0.4, 0.4, 1}, -- Not the accurate color, but more readable
    ["rage"] = {1, 0, 0},
    ["energy"] = {1, 1, 0}
}
function ShowSpellsTooltip(attachTo, spells, owner)
    SpellsTooltipOwner = owner
    SpellsTooltip:SetOwner(attachTo, "ANCHOR_RIGHT")
    SpellsTooltip:SetPoint("RIGHT", attachTo, "LEFT", 0, 0)
    local modifier = GetKeyModifier()
    local currentPower = UnitMana("player")
    local maxPower = UnitManaMax("player")
    local powerType = GetPowerType("player")
    local powerColor = tooltipPowerColors[powerType]
    SpellsTooltip:AddDoubleLine("Key: "..modifier, colorize(currentPower.."/"..maxPower, powerColor), 1, 1, 1)

    for _, kv in ipairs(spells) do
        for button, spell in pairs(kv) do
            local leftText = colorize(button, 1, 1, 0.5)
            local rightText
            if spell == "Unbound" then
                leftText = colorize(button, 0.6, 0.6, 0.6)
                rightText = colorize("Unbound", 0.6, 0.6, 0.6)
            elseif SpecialBinds[string.upper(spell)] then
                rightText = spell
            else -- There is a bound spell
                local cost, resource = GetResourceCost(spell)
                if cost == "unknown" then
                    leftText = colorize(button, 1, 0.4, 0.4)
                    rightText = colorize(spell.." (Unknown)", 1, 0.4, 0.4)
                elseif cost == 0 then -- The spell is free, so no fancy text
                    rightText = spell
                else
                    local resourceColor = tooltipPowerColors[resource]
                    local casts = math.floor(currentPower / cost)
                    if resource ~= powerType then -- A druid can't cast a spell that requires a different power type
                        casts = 0
                    end
                    local castsColor = {0.6, 1, 0.6}
                    if casts == 0 then
                        castsColor = {1, 0.5, 0.5}
                    elseif casts == 1 then
                        castsColor = {1, 1, 0}
                    end
                    rightText = spell.." "..colorize(cost, resourceColor)
                        ..colorize(" ("..casts..")", castsColor)
                end
            end
            -- Gray out spells that are not held down
            if CurrentlyHeldButton and button ~= CurrentlyHeldButton then
                leftText = colorize(util.StripColors(leftText), 0.3, 0.3, 0.3)
                rightText = colorize(util.StripColors(rightText), 0.3, 0.3, 0.3)
            end
            SpellsTooltip:AddDoubleLine(leftText, rightText)
        end
        
    end

    --local leftTexts = {spellsTooltipTextLeft1, spellsTooltipTextLeft2, spellsTooltipTextLeft3, 
    --	spellsTooltipTextLeft4, spellsTooltipTextLeft5, spellsTooltipTextLeft6}

    

    --spellsTooltipTextLeft1:SetFont("Fonts\\FRIZQT__.TTF", 12, "GameFontNormal")
    --spellsTooltipTextRight1:SetFont("Fonts\\FRIZQT__.TTF", 12, "GameFontNormal")
    SpellsTooltip:Show()
end

function HideSpellsTooltip()
    SpellsTooltip:Hide()
    SpellsTooltipOwner = nil
end

function ReapplySpellsTooltip()
    if SpellsTooltipOwner ~= nil then
        local prevOwner = SpellsTooltipOwner
        HideSpellsTooltip()
        prevOwner:GetScript("OnEnter")()
    end
end

function UpdateAllIncomingHealing()
    if not HMHealPredict then
        return
    end
    for _, ui in pairs(HealUIs) do
        if HMOptions.UseHealPredictions then
            local _, guid = UnitExists(ui:GetUnit())
            ui.incomingHealing = HMHealPredict.GetIncomingHealing(guid)
        else
            ui.incomingHealing = 0
        end
        ui:UpdateHealth()
    end
end

local function createUIGroup(groupName, environment, units, petGroup, profile)
    local uiGroup = HealUIGroup:New(groupName, environment, units, petGroup, profile)
    for _, unit in ipairs(units) do
        local ui = HealUI:New(unit)
        HealUIs[unit] = ui
        uiGroup:AddUI(ui)
        if unit ~= "target" then
            ui:Hide()
        end
    end
    return uiGroup
end

local function initUIs()
    local getSelectedProfile = HealersMateSettings.GetSelectedProfile
    HealUIGroups["Party"] = createUIGroup("Party", "party", PartyUnits, false, getSelectedProfile("Party"))
    HealUIGroups["Pets"] = createUIGroup("Pets", "party", PetUnits, true, getSelectedProfile("Pets"))
    HealUIGroups["Raid"] = createUIGroup("Raid", "raid", RaidUnits, false, getSelectedProfile("Raid"))
    HealUIGroups["Raid Pets"] = createUIGroup("Raid Pets", "raid", RaidPetUnits, true, getSelectedProfile("Raid Pets"))
    HealUIGroups["Target"] = createUIGroup("Target", "all", TargetUnits, false, getSelectedProfile("Target"))

    HealUIGroups["Target"].ShowCondition = function(self)
        return UnitExists("target") and not HMOptions.Hidden
    end
    HealUIGroups["Target"]:Hide()
end

function EventAddonLoaded()
    local freshInstall = false
    if HMSpells == nil then
        freshInstall = true
        local HMSpells = {}
        HMSpells["Friendly"] = {}
        HMSpells["Hostile"] = {}
        setglobal("HMSpells", HMSpells)
    end

    for _, spells in pairs(HMSpells) do
        for _, modifier in ipairs(util.GetKeyModifiers()) do
            if not spells[modifier] then
                spells[modifier] = {}
            end
        end
    end

    if not _G.HMRoleCache then
        _G.HMRoleCache = {}
    end
    if not _G.HMRoleCache[GetRealmName()] then
        _G.HMRoleCache[GetRealmName()] = {}
    end
    AssignedRoles = _G.HMRoleCache[GetRealmName()]
    PruneAssignedRoles()

    HMUnit.CreateCaches(AllUnits)
    HealersMateSettings.UpdateTrackedDebuffTypes()
    HMProfileManager.InitializeDefaultProfiles()
    HealersMateSettings.SetDefaults()
    HealersMateSettings.InitSettings()
    if HMHealPredict then
        HMHealPredict.OnLoad()

        HMHealPredict.HookUpdates(function(guid, incomingHealing)
            if not HMOptions.UseHealPredictions then
                return
            end
            if not GUIDUnitMap[guid] then
                return
            end
            for _, unit in ipairs(GUIDUnitMap[guid]) do
                HealUIs[unit].incomingHealing = incomingHealing
                HealUIs[unit]:UpdateHealth()
            end
        end)
    end

    TestUI = HMOptions.TestUI

    if TestUI then
        DEFAULT_CHAT_FRAME:AddMessage(colorize("[HealersMate] UI Testing is enabled. Use /hm testui to disable.", 1, 0.6, 0.6))
    end

    initUIs()

    if HMOnLoadInfoDisabled == nil then
        HMOnLoadInfoDisabled = false
    end

    if not HMOnLoadInfoDisabled then
        DEFAULT_CHAT_FRAME:AddMessage(colorize("[HealersMate] Use ", 0.5, 1, 0.5)..colorize("/hm help", 0, 1, 0)
            ..colorize(" to see commands.", 0.5, 1, 0.5))
    end

    --##START## Create Default Values for Settings if Addon has never ran before.
    --TODO: Only Druid, Priest, Paladin currently have some spells set by default on first time use. Haven't gotten to others.
    if freshInstall then
        local class = GetClass("player")
        local spells = GetSpells()
        if class == "PRIEST" then
            spells["None"]["LeftButton"] = "Power Word: Shield"
            spells["None"]["MiddleButton"] = "Renew"
            spells["None"]["RightButton"] = "Lesser Heal"
        elseif class == "DRUID" then
            spells["None"]["LeftButton"] = "Rejuvenation"
            spells["None"]["RightButton"] = "Healing Touch"
        elseif class == "PALADIN" then
            spells["None"]["LeftButton"] = "Flash of Light"
            spells["None"]["RightButton"] = "Holy Light"
        end
    end
end

function SetPartyFramesEnabled(enabled)
    if enabled then
        for i = 1, MAX_PARTY_MEMBERS do
            local frame = getglobal("PartyMemberFrame"..i)
            if frame and frame.HMRealShow then
                frame.Show = frame.HMRealShow
                frame.HMRealShow = nil

                if UnitExists("party"..i) then
                    frame:Show()
                end
                local prevThis = _G.this
                _G.this = frame
                PartyMemberFrame_OnLoad()
                _G.this = prevThis
            end
        end
    else
        for i = 1, MAX_PARTY_MEMBERS do
            local frame = getglobal("PartyMemberFrame"..i)
            if frame then
                frame:UnregisterAllEvents()
                frame.HMRealShow = frame.Show
                frame.Show = function() end
                frame:Hide()
            end
        end
    end
end

function GetAssignedRole(name)
    if not AssignedRoles or not AssignedRoles[name] then
        return
    end
    AssignedRoles[name]["lastSeen"] = time()
    return AssignedRoles[name]["role"]
end

function GetUnitAssignedRole(unit)
    if not UnitIsPlayer(unit) then
        return
    end
    return GetAssignedRole(UnitName(unit))
end

function SetAssignedRole(name, role)
    if role == nil or role == "No Role" then
        AssignedRoles[name] = nil
        return
    end
    AssignedRoles[name] = {
        ["role"] = role,
        ["lastSeen"] = time()
    }
end

-- Returns true if role assignment failed
function SetUnitAssignedRole(unit, role)
    if not UnitIsPlayer(unit) then
        return true
    end
    SetAssignedRole(UnitName(unit), role)
end

function PruneAssignedRoles()
    local currentTime = time()
    for name, data in pairs(AssignedRoles) do
        if not data["lastSeen"] or data["lastSeen"] < currentTime - (24 * 60 * 60) then
            AssignedRoles[name] = nil
            --hmprint("Pruned "..name.."'s role")
        end
    end
end

local roleTarget
local roleTargetClassColor
local roleTargetGroup

local function setUnassignedRoles(role)
    if not roleTargetGroup then
        return
    end
    for _, ui in pairs(roleTargetGroup.uis) do
        if not ui:GetRole() and UnitIsPlayer(ui:GetUnit()) then
            SetAssignedRole(UnitName(ui:GetUnit()), role)
        end
    end
    UpdateHealUIGroups()
    ToggleDropDownMenu(1, nil, _G["HMRoleDropdown"])
end

local function applyTargetRole(role)
    SetAssignedRole(roleTarget, role)
    UpdateHealUIGroups()
end

do
    local roleDropdown = CreateFrame("Frame", "HMRoleDropdown", UIParent, "UIDropDownMenuTemplate")

    local options = {
        {
            ["text"] = "",
            ["arg1"] = "Assign Role",
            ["notCheckable"] = true,
            ["disabled"] = true
        }, {
            ["text"] = GetColoredRoleText("Tank"),
            ["arg1"] = "Tank",
            ["func"] = applyTargetRole
        }, {
            ["text"] = GetColoredRoleText("Healer"),
            ["arg1"] = "Healer",
            ["func"] = applyTargetRole
        }, {
            ["text"] = GetColoredRoleText("Damage"),
            ["arg1"] = "Damage",
            ["func"] = applyTargetRole
        }, {
            ["text"] = GetColoredRoleText("No Role"),
            ["arg1"] = "No Role",
            ["func"] = applyTargetRole
        }, {
            ["text"] = "",
            ["notCheckable"] = true,
            ["disabled"] = true
        }, {
            ["text"] = "Set Unassigned As",
            ["tooltipTitle"] = "Set Unassigned As",
            ["tooltipText"] = "Mass-set the roles of unassigned players. Only applies to players contained in this UI group.",
            ["notCheckable"] = true,
            ["hasArrow"] = true,
            ["suboptions"] = {
                {
                    ["text"] = GetColoredRoleText("Tank"),
                    ["arg1"] = "Tank",
                    ["notCheckable"] = true,
                    ["func"] = setUnassignedRoles
                }, {
                    ["text"] = GetColoredRoleText("Healer"),
                    ["arg1"] = "Healer",
                    ["notCheckable"] = true,
                    ["func"] = setUnassignedRoles
                }, {
                    ["text"] = GetColoredRoleText("Damage"),
                    ["arg1"] = "Damage",
                    ["notCheckable"] = true,
                    ["func"] = setUnassignedRoles
                }
            }
        }, {
            ["text"] = "Clear Roles",
            ["arg1"] = "Clear Roles",
            ["tooltipTitle"] = "Clear Roles",
            ["tooltipText"] = "Clear all players' roles. Only applies to players contained in this UI group.",
            ["notCheckable"] = true,
            ["func"] = function()
                if not roleTargetGroup then
                    return
                end
                for _, ui in pairs(roleTargetGroup.uis) do
                    if ui:GetRole() and UnitIsPlayer(ui:GetUnit()) then
                        SetAssignedRole(UnitName(ui:GetUnit()), nil)
                    end
                end
                UpdateHealUIGroups()
                ToggleDropDownMenu(1, nil, _G["HMRoleDropdown"])
            end
        }
    }

    UIDropDownMenu_Initialize(roleDropdown, function(level)
        level = level or 1
        if level == 1 then
            for _, option in ipairs(options) do
                option.checked = (GetAssignedRole(roleTarget) or "No Role") == option.arg1

                if option.arg1 == "Assign Role" and roleTarget then
                    option.text = colorize("Assign Role: ", 1, 0.5, 1)..colorize(roleTarget, roleTargetClassColor)
                end
                UIDropDownMenu_AddButton(option)
            end
        elseif level == 2 then
            local suboptions
            for _, option in ipairs(options) do
                if option.text == UIDROPDOWNMENU_MENU_VALUE then
                    suboptions = option.suboptions
                end
            end
            for _, option in ipairs(suboptions) do
                UIDropDownMenu_AddButton(option, level)
            end
        end
    end, "MENU")
end

local function setUnitRoleAndUpdate(unit, role)
    if not SetUnitAssignedRole(unit, role) then
        UpdateHealUIGroups()
    end
end

SpecialBinds = {
    ["target"] = function(unit)
        TargetUnit(unit)
    end,
    ["assist"] = function(unit)
        AssistUnit(unit)
    end,
    ["follow"] = function(unit)
        FollowUnit(unit)
    end,
    ["context"] = function(unit, ui)
        -- Trying to figure out how to get raid context menus still
        local map = {
            ["party1"] = 1,
            ["party2"] = 2,
            ["party3"] = 3,
            ["party4"] = 4
        }
        if map[unit] then
            local frame = ui:GetRootContainer()
            ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..map[unit].."DropDown"], frame:GetName(), frame:GetWidth(), 0)
        end
    end,
    ["Role: Tank"] = function(unit)
        setUnitRoleAndUpdate(unit, "Tank")
    end,
    ["Role: Healer"] = function(unit)
        setUnitRoleAndUpdate(unit, "Healer")
    end,
    ["Role: Damage"] = function(unit)
        setUnitRoleAndUpdate(unit, "Damage")
    end,
    ["Role: None"] = function(unit)
        setUnitRoleAndUpdate(unit, nil)
    end,
    ["Role"] = function(unit, ui)
        if not UnitIsPlayer(unit) then
            return
        end
        roleTarget = UnitName(unit)
        roleTargetClassColor = util.GetClassColor(util.GetClass(unit), true)
        roleTargetGroup = ui.owningGroup
        local frame = ui:GetRootContainer()
        local dropdown = _G["HMRoleDropdown"]
        if dropdown:IsShown() then
            ToggleDropDownMenu(1, nil, dropdown)
        end
        ToggleDropDownMenu(1, nil, dropdown, frame:GetName(), frame:GetWidth(), frame:GetHeight())
        PlaySound("igMainMenuOpen")
    end
}

-- Create aliases for special binds
SpecialBinds["Set Role"] = SpecialBinds["Role"]

-- Make all the special binds upper case
do
    local upperSpecialBinds = {}
    for name, func in pairs(SpecialBinds) do
        upperSpecialBinds[string.upper(name)] = func
    end
    SpecialBinds = upperSpecialBinds
end

function ClickHandler(buttonType, unit, ui)
    local currentTargetEnemy = UnitCanAttack("player", "target")
    
    local spells = UnitCanAttack("player", unit) and GetHostileSpells() or GetSpells()
    local spell = spells[GetKeyModifier()][buttonType]

    if not UnitIsConnected(unit) or not UnitIsVisible(unit) then
        if SpecialBinds[string.upper(spell)] then
            SpecialBinds[string.upper(spell)](unit, ui)
        end
        return
    end
    if util.IsDeadFriend(unit) then
        if HMUnit.Get(unit):HasBuffIDOrName(45568, "Holy Champion") and GetSpellID("Revive Champion") 
            and UnitAffectingCombat("player") then
                spell = "Revive Champion"
        else
            spell = ResurrectionSpells[GetClass("player")]
        end
    end
    
    if spell == nil then
        return
    end

    if SpecialBinds[string.upper(spell)] then
        SpecialBinds[string.upper(spell)](unit, ui)
        return
    end

    -- Auto targeting requires no special logic to cast spells
    if HMOptions.AutoTarget then
        if not UnitIsUnit("target", unit) then
            TargetUnit(unit)
        end
        CastSpellByName(spell)
        return
    end

    -- Not a special bind
    if util.IsSuperWowPresent() then -- No target changing shenanigans required with SuperWoW
        CastSpellByName(spell, unit)
    else
        local currentTarget = UnitName("target")
        local targetChanged = false
        -- Check if target is not already targeted
        if not UnitIsUnit("target", unit) then
            -- Set target as target
            TargetUnit(unit)
            targetChanged = true
        end
        
        CastSpellByName(spell)

        --Put Target of player back to whatever it was before casting spell
        if targetChanged then
            if currentTarget == nil then
                --Player wasn't targeting anything before casting spell
                ClearTarget()
            else
                --Set Target back to whatever it was before casting the spell
                if currentTargetEnemy then
                    TargetLastEnemy() -- to make sure if there was more than one mob with that name near you the same one get retargeted
                else
                    TargetLastTarget()
                    --TargetByName(currentTarget)
                end
            end
        end
    end
end

-- Reevaluates what UI frames should be shown
function CheckGroup()
    local environment = "party"
    if GetNumRaidMembers() > 0 then
        environment = "raid"
        if not CurrentlyInRaid then
            CurrentlyInRaid = true
            SetPartyFramesEnabled(not HMOptions.DisablePartyFrames.InRaid)
        end
    else
        if CurrentlyInRaid then
            CurrentlyInRaid = false
            SetPartyFramesEnabled(not HMOptions.DisablePartyFrames.InParty)
        end
    end
    local superwow = util.IsSuperWowPresent()
    if superwow then
        GUIDUnitMap = {}
    end
    for unit, ui in pairs(HealUIs) do
        local exists, guid = UnitExists(unit)
        if unit ~= "target" then
            if exists then
                ui:Show()
                ui:UpdateAuras()
            else
                ui:Hide()
            end
        end
        if guid then -- If the guid isn't nil, then SuperWoW is present
            if not GUIDUnitMap[guid] then
                GUIDUnitMap[guid] = {}
            end
            table.insert(GUIDUnitMap[guid], unit)
        end
    end
    for _, group in pairs(HealUIGroups) do
        if group:CanShowInEnvironment(environment) and group:ShowCondition() then
            group:Show()
            group:UpdateUIPositions()
        else
            group:Hide()
        end
    end
    HMUnit.UpdateAllUnits()
    for _, ui in pairs(HealUIs) do
        ui:UpdateAuras()
    end
    if superwow then
        HMHealPredict.SetRelevantGUIDs(util.ToArray(GUIDUnitMap))
    end
end


function IsRelevantUnit(unit)
    --return not string.find(unit, "0x")
    return HealUIs[unit] ~= nil
end

function EventHandler()
    if event == "ADDON_LOADED" then
        
        if arg1 ~= "HealersMate" then
            return
        end

        EventAddonLoaded()
        EventHandlerFrame:UnregisterEvent("ADDON_LOADED")
    
    elseif event == "PLAYER_ENTERING_WORLD" then
        
        CheckGroup()

        if HMOptions.DisablePartyFrames.InParty then
            SetPartyFramesEnabled(false)
        end
        
    elseif event == "PLAYER_LOGOUT" or event == "PLAYER_QUITING" then
        
        
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = arg1
        if not IsRelevantUnit(unit) then
            return
        end
        HealUIs[unit]:UpdateHealth()
    elseif event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" or 
            event == "UNIT_FOCUS" or event == "UNIT_MAXMANA" then
        local unit = arg1
        if not IsRelevantUnit(unit) then
            return
        end
        
        HealUIs[unit]:UpdatePower()
        
        if unit == "player" then
            ReapplySpellsTooltip()
        end
        
    elseif event == "UNIT_AURA" then
        local unit = arg1
        if not IsRelevantUnit(unit) then
            return
        end
        HMUnit.Get(unit):UpdateAuras()
        HealUIs[unit]:UpdateAuras()
        HealUIs[unit]:UpdateHealth() -- Update health because there may be an aura that changes health bar color

    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        CheckGroup()
    elseif event == "UNIT_PET" or event == "PLAYER_PET_CHANGED" then
        local unit = arg1
        if IsRelevantUnit(unit) then
            CheckGroup()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if HMOptions.Hidden then
            return
        end
        HMUnit.Get("target"):UpdateAll()
        local exists, guid = UnitExists("target")
        if exists then
            HealUIGroups["Target"]:Hide()
            local friendly = not UnitCanAttack("player", "target")
            if (friendly and HMOptions.ShowTargets.Friendly) or (not friendly and HMOptions.ShowTargets.Hostile) then
                HealUIGroups["Target"]:Show()
                HealUIs["target"]:CheckRange()
                HealUIs["target"]:CheckSight()

                if guid then -- If the guid isn't nil, then SuperWoW is present
                    for guidInMap, units in pairs(GUIDUnitMap) do
                        if util.ArrayContains(units, "target") then
                            util.RemoveElement(units, "target")
                            if table.getn(units) == 0 then
                                GUIDUnitMap[guidInMap] = nil
                            end
                            break
                        end
                    end
                
                    if not GUIDUnitMap[guid] then
                        GUIDUnitMap[guid] = {}
                    end
                    table.insert(GUIDUnitMap[guid], "target")
                    HMHealPredict.SetRelevantGUIDs(util.ToArray(GUIDUnitMap))
                    HealUIs["target"].incomingHealing = HMHealPredict.GetIncomingHealing(guid)
                    HealUIs["target"]:UpdateHealth()
                    HealUIs["target"]:UpdateRole()
                end
            end
        else
            HealUIGroups["Target"]:Hide()
        end
    elseif event == "SPELLS_CHANGED" then
        HealersMateSettings.UpdateTrackedDebuffTypes()
    end
end

EventHandlerFrame:SetScript("OnEvent", EventHandler)


function hmprint(msg)
    if not HMOptions or not HMOptions["Debug"] then
        return
    end
    local window
    local i = 1
    while not window do
        local name = GetChatWindowInfo(i)
        if not name then
            break
        end
        if name == "Debug" then
            window = getglobal("ChatFrame"..i)
            break
        end
        i = i + 1
    end
    if window then
        window:AddMessage(tostring(msg))
    end
end