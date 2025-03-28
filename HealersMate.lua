SLASH_HEALERSMATE1 = "/healersmate"
SLASH_HEALERSMATE2 = "/hm"
SlashCmdList["HEALERSMATE"] = function(args)
    if args == "reset" then
        for _, group in pairs(HealersMate.UnitFrameGroups) do
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
        for _, ui in pairs(HealersMate.AllUnitFrames) do
            ui:SizeElements()
            ui:UpdateAll()
        end
        for _, group in pairs(HealersMate.UnitFrameGroups) do
            group:ApplyProfile()
            group:UpdateUIPositions()
        end
    elseif args == "testui" then
        HMOptions.TestUI = not HMOptions.TestUI
        HealersMate.TestUI = HMOptions.TestUI
        if HMOptions.TestUI then
            for _, ui in pairs(HealersMate.AllUnitFrames) do
                ui.fakeStats = ui.GenerateFakeStats()
                ui:Show()
            end
        end
        HealersMate.CheckGroup()
        if not HMOptions.TestUI and HMUnitProxy then
            for _, type in ipairs(HMUnitProxy.CustomUnitTypes) do
                HMUnitProxy.UpdateUnitTypeFrames(type)
            end
        end
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

HealersMateLib = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0")
HealersMate = {}
local _G = getfenv(0)
setmetatable(HealersMate, {__index = getfenv(1)})
setfenv(1, HealersMate)

VERSION = "2.0.0-alpha5.1"

TestUI = false

Banzai = AceLibrary("Banzai-1.0")
HealComm = AceLibrary("HealComm-1.0")
GuidRoster = HMGuidRoster -- Will be nil if SuperWoW isn't present

local util = HMUtil
local colorize = util.Colorize
local GetKeyModifier = util.GetKeyModifier
local GetClass = util.GetClass
local GetPowerType = util.GetPowerType
local GetColoredRoleText = util.GetColoredRoleText
local UseItem = util.UseItem
local GetItemCount = util.GetItemCount

PartyUnits = util.PartyUnits
PetUnits = util.PetUnits
TargetUnits = util.TargetUnits
RaidUnits = util.RaidUnits
RaidPetUnits = util.RaidPetUnits
AllUnits = util.AllUnits
AllUnitsSet = util.AllUnitsSet
AllCustomUnits = util.CustomUnits
AllCustomUnitsSet = util.CustomUnitsSet

if HMUnitProxy then
    HMUnitProxy.ImportFunctions(HealersMate)
end

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

local hmBarsPath = util.GetAssetsPath().."textures\\bars\\"
BarStyles = {
    ["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
    ["Blizzard Smooth"] = hmBarsPath.."Blizzard-Smooth",
    ["Blizzard Raid"] = hmBarsPath.."Blizzard-Raid",
    ["Blizzard Raid Sideless"] = hmBarsPath.."Blizzard-Raid-Sideless",
    ["HealersMate"] = hmBarsPath.."HealersMate",
    ["HealersMate Borderless"] = hmBarsPath.."HealersMate-Borderless",
    ["HealersMate Shineless"] = hmBarsPath.."HealersMate-Shineless",
    ["HealersMate Shineless Borderless"] = hmBarsPath.."HealersMate-Shineless-Borderless"
}

GameTooltip = CreateFrame("GameTooltip", "HMGameTooltip", UIParent, "GameTooltipTemplate")

CurrentlyHeldButton = nil
SpellsTooltip = CreateFrame("GameTooltip", "HMSpellsTooltip", UIParent, "GameTooltipTemplate")
SpellsTooltipOwner = nil
SpellsTooltipPowerBar = nil
do
    local manaBar = CreateFrame("StatusBar", "HMSpellsTooltipManaBar", SpellsTooltip)
    SpellsTooltipPowerBar = manaBar
    manaBar:SetStatusBarTexture(BarStyles["HealersMate"])
    manaBar:SetMinMaxValues(0, 1)
    manaBar:SetWidth(100)
    manaBar:SetHeight(12)
    manaBar:SetPoint("TOPRIGHT", SpellsTooltip, "TOPRIGHT", -10, -12)

    local bg = manaBar:CreateTexture(nil, "BACKGROUND")
    manaBar.background = bg
    bg:SetAllPoints(true)
    bg:SetTexture(0.3, 0.3, 0.3, 0.8)

    local text = manaBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    manaBar.text = text
    text:SetWidth(manaBar:GetWidth())
    text:SetHeight(manaBar:GetHeight())
    text:SetPoint("CENTER", manaBar, "CENTER")
    text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    text:SetShadowOffset(0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("CENTER")
end

-- An unmapped array of all unit frames
AllUnitFrames = {}
-- A map of units to an array of unit frames associated with the unit
HMUnitFrames = {}

-- Key: Unit frame group name | Value: The group
UnitFrameGroups = {}

CustomUnitGUIDMap = HMUnitProxy and HMUnitProxy.CustomUnitGUIDMap or {}
GUIDCustomUnitMap = HMUnitProxy and HMUnitProxy.GUIDCustomUnitMap or {}


CurrentlyInRaid = false

AssignedRoles = nil

-- Returns the array of unit frames of the unit
function GetUnitFrames(unit)
    return HMUnitFrames[unit]
end

-- A temporary dummy function while the addon initializes. See below for the real iterator.
function UnitFrames(unit)
    return function() end
end

local function OpenUnitFramesIterator()
    -- UnitFrames function definition.
    -- Returns an iterator for the unit frames of the unit.
    -- These iterators have a serious problem in that they do not support concurrent iteration.
    if util.IsSuperWowPresent() then
        local EMPTY_UIS = {}
        local HMUnitFrames = HMUnitFrames
        local GuidUnitMap = HMGuidRoster.GuidUnitMap
        local iterTable = {} -- The table reused for iteration over GUID units
        local uis
        local i = 0
        local len = 0
        local iterFunc = function()
            i = i + 1
            if i <= len then
                return uis[i]
            end
        end
        function UnitFrames(unit)
            if i < len then
                hmprint("Collision: "..i.."/"..len)
            end
            if GuidUnitMap[unit] then -- If a GUID is provided, ALL UIs associated with that GUID will be iterated
                uis = iterTable
                for i = 1, table.getn(uis) do
                    uis[i] = nil
                end
                table.setn(uis, 0)
                for _, unit in pairs(GuidUnitMap[unit]) do
                    for _, frame in ipairs(HMUnitFrames[unit]) do
                        table.insert(uis, frame)
                    end
                end
            else
                uis = HMUnitFrames[unit] or EMPTY_UIS
            end
            len = table.getn(uis)
            i = 0
            return iterFunc
        end
    else -- Optimized version for vanilla
        local HMUnitFrames = HMUnitFrames
        local uis
        local i = 0
        local len = 0
        local iterFunc = function()
            i = i + 1
            if i <= len then
                return uis[i]
            end
        end
        function UnitFrames(unit)
            i = 0
            uis = HMUnitFrames[unit]
            len = table.getn(uis)
            return iterFunc
        end
    end
end


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
EventHandlerFrame:RegisterEvent("RAID_TARGET_UPDATE")

EventHandlerFrame:RegisterEvent("UNIT_MANA")
EventHandlerFrame:RegisterEvent("UNIT_DISPLAYPOWER")
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

function Debug(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function GetSpells()
    return HMSpells["Friendly"]
end

function GetHostileSpells()
    return HMSpells["Hostile"]
end

function UpdateUnitFrameGroups()
    for _, group in pairs(UnitFrameGroups) do
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

    local spellID, bookType
    if GetSpellSlotTypeIdForName then -- Nampower 2.6.0 function
        spellID, bookType = GetSpellSlotTypeIdForName(spellName)
        if bookType == "unknown" then
            return "unknown"
        end
        if bookType ~= "spell" then
            return 0
        end
    else
        spellID = GetSpellID(spellName)
    end
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
    if not HMOptions.SpellsTooltip.Enabled then
        return
    end

    local spellList = {}
    local modifier = GetKeyModifier()
    local settings = HealersMateSettings
    local spells = UnitCanAttack("player", unit) and GetHostileSpells() or GetSpells()

    local deadFriend = util.IsDeadFriend(unit)
    local selfClass = GetClass("player")
    local canResurrect = HMOptions.AutoResurrect and deadFriend and ResurrectionSpells[selfClass]
    -- Holy Champion Texture: Interface\\Icons\\Spell_Holy_ProclaimChampion_02
    local canReviveChampion = canResurrect and GetSpellID("Revive Champion") and 
        HMUnit.Get(unit):HasBuffIDOrName(45568, "Holy Champion") and UnitAffectingCombat("player")

    for _, btn in ipairs(settings.CustomButtonOrder) do
        if canResurrect then -- Show all spells (except special binds) as the resurrection spell
            local kv = {}
            local readableButton = settings.CustomButtonNames[btn] or ReadableButtonMap[btn]
            kv[readableButton] = canReviveChampion and "Revive Champion" or ResurrectionSpells[selfClass]
            if SpecialBinds[string.upper(spells[modifier][btn] or "")] then
                kv[readableButton] = spells[modifier][btn]
            end
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

function IsValidMacro(name)
    return GetMacroIndexByName(name) ~= 0
end

function RunMacro(name, target)
    if not IsValidMacro(name) then
        return
    end
    if target then
        _G.HM_MacroTarget = target
    end
    local _, _, body = GetMacroInfo(GetMacroIndexByName(name))
    local commands = util.SplitString(body, "\n")
    for i = 1, table.getn(commands) do
        ChatFrameEditBox:SetText(commands[i])
        ChatEdit_SendText(ChatFrameEditBox)
    end
    if target then
        _G.HM_MacroTarget = nil
    end
end

local ITEM_PREFIX = "Item: "
local MACRO_PREFIX = "Macro: "
local lowToHighColors = {
    {1, 0, 0}, 
    {1, 0.9, 0}, 
    {0.35, 1, 0.35}
}
local tooltipPowerColors = {
    ["mana"] = {0.5, 0.7, 1}, -- Not the accurate color, but more readable
    ["rage"] = {1, 0, 0},
    ["energy"] = {1, 1, 0}
}
function ShowSpellsTooltip(attachTo, spells, owner)
    SpellsTooltipOwner = owner
    SpellsTooltip:SetOwner(attachTo, "ANCHOR_RIGHT")
    SpellsTooltip:SetPoint("RIGHT", attachTo, "LEFT", 0, 0)
    local options = HMOptions.SpellsTooltip
    local currentPower = UnitMana("player")
    local maxPower = UnitManaMax("player")
    local powerType = GetPowerType("player")
    local powerColor = tooltipPowerColors[powerType]
    local powerText = ""
    local showPowerBar = options.ShowPowerBar
    if options.ShowPowerAs == "Power" then
        powerText = tostring(currentPower)
    elseif options.ShowPowerAs == "Power/Max Power" then
        powerText = currentPower.."/"..maxPower
    elseif options.ShowPowerAs == "Power %" then
        powerText = util.RoundNumber((currentPower / maxPower) * 100).."%"
    end

    if showPowerBar then
        local color = util.InterpolateColors(lowToHighColors, (currentPower / maxPower))
        powerText = colorize(powerText, color)
        SpellsTooltipPowerBar:SetStatusBarColor(powerColor[1], powerColor[2], powerColor[3])
        SpellsTooltipPowerBar:SetValue(currentPower / maxPower)
        SpellsTooltipPowerBar.text:SetText(powerText)
    else
        powerText = colorize(powerText, powerColor)
    end

    local modifier = util.GetKeyModifierTypeByID(1 + (options.AbbreviatedKeys and 2 or 0) + (options.ColoredKeys and 1 or 0))
    SpellsTooltip:AddDoubleLine(modifier, showPowerBar and "                 " or powerText, 1, 1, 1)

    for _, kv in ipairs(spells) do
        for button, spell in pairs(kv) do
            local leftText = colorize(button, 1, 1, 0.5)
            local rightText
            if spell == "Unbound" then
                leftText = colorize(button, 0.6, 0.6, 0.6)
                rightText = colorize("Unbound", 0.6, 0.6, 0.6)
            elseif util.StartsWith(spell, ITEM_PREFIX) then
                local item = string.sub(spell, string.len(ITEM_PREFIX) + 1)
                local itemCount = GetItemCount(item)
                local castsColor = {0.6, 1, 0.6}
                if itemCount == 0 then
                    castsColor = {1, 0.5, 0.5}
                elseif itemCount == 1 then
                    castsColor = {1, 1, 0}
                end
                rightText = colorize(item, 1, 1, 1)..colorize(" ("..itemCount..")", castsColor)
            elseif util.StartsWith(spell, MACRO_PREFIX) then
                local macro = string.sub(spell, string.len(MACRO_PREFIX) + 1)
                if IsValidMacro(macro) then
                    rightText = colorize(macro, 1, 0.6, 1)
                else
                    rightText = colorize(macro.." (Invalid Macro)", 1, 0.4, 0.4)
                end
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
                    local r, g, b = 0.6, 1, 0.6
                    if casts == 0 then
                        r, g, b = 1, 0.5, 0.5
                    elseif casts <= options.CriticalCastsLevel then
                        r, g, b = 1, 1, 0
                    end
                    local costText
                    if powerType == "mana" and resource == powerType then
                        if options.ShowManaCost then
                            costText = cost
                        end
                        if options.ShowManaPercentCost then
                            costText = (costText and (costText.." ") or "")..util.RoundNumber((cost / maxPower) * 100, 1).."%"
                        end
                    else
                        costText = cost
                    end
                    rightText = spell
                    if casts == 0 then
                        rightText = colorize(util.StripColors(rightText), 0.5, 0.5, 0.5)
                    end
                    if costText then
                        rightText = rightText.." "..colorize(costText, resourceColor)
                    end
                    if casts <= options.HideCastsAbove then
                        rightText = rightText..colorize(" ("..casts..")", r, g, b)
                    end
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
    if HMHealPredict then
        for _, ui in ipairs(AllUnitFrames) do
            if HMOptions.UseHealPredictions then
                local _, guid = UnitExists(ui:GetUnit())
                ui:SetIncomingHealing(HMHealPredict.GetIncomingHealing(guid))
            else
                ui:SetIncomingHealing(0)
            end
        end
    else
        for _, ui in ipairs(AllUnitFrames) do
            if HMOptions.UseHealPredictions then
                ui:UpdateIncomingHealing()
            else
                ui:SetIncomingHealing(0)
            end
        end
    end
end

function UpdateAllOutlines()
    for _, ui in ipairs(AllUnitFrames) do
        ui:UpdateOutline()
    end
end

function CreateUnitFrameGroup(groupName, environment, units, petGroup, profile, sortByRole)
    if UnitFrameGroups[groupName] then
        error("[HealersMate] Tried to create a unit frame group using existing name! \""..groupName.."\"")
        return
    end
    local uiGroup = HMUnitFrameGroup:New(groupName, environment, units, petGroup, profile, sortByRole)
    for _, unit in ipairs(units) do
        local ui = HMUnitFrame:New(unit, AllCustomUnitsSet[unit] ~= nil)
        if not HMUnitFrames[unit] then
            HMUnitFrames[unit] = {}
        end
        table.insert(HMUnitFrames[unit], ui)
        table.insert(AllUnitFrames, ui)
        uiGroup:AddUI(ui)
        if unit ~= "target" then
            ui:Hide()
        end
    end
    UnitFrameGroups[groupName] = uiGroup
    return uiGroup
end

local function initUnitFrames()
    local getSelectedProfile = HealersMateSettings.GetSelectedProfile
    CreateUnitFrameGroup("Party", "party", PartyUnits, false, getSelectedProfile("Party"))
    CreateUnitFrameGroup("Pets", "party", PetUnits, true, getSelectedProfile("Pets"))
    CreateUnitFrameGroup("Raid", "raid", RaidUnits, false, getSelectedProfile("Raid"))
    CreateUnitFrameGroup("Raid Pets", "raid", RaidPetUnits, true, getSelectedProfile("Raid Pets"))
    CreateUnitFrameGroup("Target", "all", TargetUnits, false, getSelectedProfile("Target"), false)
    if util.IsSuperWowPresent() then
        CreateUnitFrameGroup("Focus", "all", HMUnitProxy.CustomUnitsMap["focus"], false, getSelectedProfile("Focus"), false)
    end

    UnitFrameGroups["Target"].ShowCondition = function(self)
        local friendly = not UnitCanAttack("player", "target")
        return (HMOptions.AlwaysShowTargetFrame or (UnitExists("target") and 
            (friendly and HMOptions.ShowTargets.Friendly) or (not friendly and HMOptions.ShowTargets.Hostile))) 
            and not HMOptions.Hidden
    end

    OpenUnitFramesIterator()
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

    if util.IsSuperWowPresent() then
        -- In case other addons override unit functions, we want to make sure we're using their functions
        HMUnitProxy.CreateUnitProxies()

        -- Do it again after all addons have loaded
        local frame = CreateFrame("Frame")
        local reapply = GetTime() + 0.1
        frame:SetScript("OnUpdate", function()
            if GetTime() > reapply then
                HMUnitProxy.CreateUnitProxies()
                frame:SetScript("OnUpdate", nil)
            end
        end)
    end

    if not _G.HMRoleCache then
        _G.HMRoleCache = {}
    end
    if not _G.HMRoleCache[GetRealmName()] then
        _G.HMRoleCache[GetRealmName()] = {}
    end
    AssignedRoles = _G.HMRoleCache[GetRealmName()]
    PruneAssignedRoles()

    if util.IsSuperWowPresent() then
        HMUnit.UpdateGuidCaches()

        -- SuperWoW currently does not currently allow us to receive events for units that aren't part of normal units, so
        -- we're manually updating
        local customUnitUpdater = CreateFrame("Frame", "HMCustomUnitUpdater")
        local nextUpdate = GetTime() + 0.25
        customUnitUpdater:SetScript("OnUpdate", function()
            if GetTime() > nextUpdate then
                nextUpdate = GetTime() + 0.25

                for unit, guid in pairs(CustomUnitGUIDMap) do
                    HMUnit.Get(unit):UpdateAuras()
                    for ui in UnitFrames(unit) do
                        ui:UpdateHealth()
                        ui:UpdatePower()
                        ui:UpdateAuras()
                    end
                end
            end
        end)
    else
        HMUnit.CreateCaches()
    end
    HealersMateSettings.UpdateTrackedDebuffTypes()
    HMProfileManager.InitializeDefaultProfiles()
    HealersMateSettings.SetDefaults()

    do
        if HMOptions.Scripts.OnLoad then
            local scriptString = "local GetProfile = HMProfileManager.GetProfile "..
                "local CreateProfile = HMProfileManager.CreateProfile "..HMOptions.Scripts.OnLoad
            local script = loadstring(scriptString)
            local ok, result = pcall(script)
            if not ok then
                DEFAULT_CHAT_FRAME:AddMessage(colorize("[HealersMate] ", 1, 0.4, 0.4)..colorize("ERROR: ", 1, 0.2, 0.2)
                    ..colorize("The Load Script produced an error! If this causes HealersMate to fail to load, "..
                        "you will need to manually edit the script in your game files.", 1, 0.4, 0.4))
                DEFAULT_CHAT_FRAME:AddMessage(colorize("OnLoad Script Error: "..tostring(result), 1, 0, 0))
            end
        end
    end
    HealersMateSettings.InitSettings()
    if HMHealPredict then
        HMHealPredict.OnLoad()

        HMHealPredict.HookUpdates(function(guid, incomingHealing, incomingDirectHealing)
            if not HMOptions.UseHealPredictions then
                return
            end
            local units = GuidRoster.GetUnits(guid)
            if not units then
                return
            end
            for _, unit in ipairs(units) do
                for ui in UnitFrames(unit) do
                    ui:SetIncomingHealing(incomingHealing, incomingDirectHealing)
                end
            end
        end)
    else
        local roster = AceLibrary("RosterLib-2.0")
        HealersMateLib:RegisterEvent("HealComm_Healupdate", function(name)
            if not HMOptions.UseHealPredictions then
                return
            end
            local unit = roster:GetUnitIDFromName(name)
            if unit then
                for ui in UnitFrames(unit) do
                    ui:UpdateIncomingHealing()
                end
            end
            if UnitName("target") == name then
                for ui in UnitFrames("target") do
                    ui:UpdateIncomingHealing()
                end
            end
        end)
        HealersMateLib:RegisterEvent("HealComm_Ressupdate", function(name)
            local unit = roster:GetUnitIDFromName(name)
            if unit then
                for ui in UnitFrames(unit) do
                    ui:UpdateHealth()
                end
            end
            if UnitName("target") == name then
                for ui in UnitFrames("target") do
                    ui:UpdateHealth()
                end
            end
        end)
    end
    
    SetLFTAutoRoleEnabled(HMOptions.LFTAutoRole)

    TestUI = HMOptions.TestUI

    if TestUI then
        DEFAULT_CHAT_FRAME:AddMessage(colorize("[HealersMate] UI Testing is enabled. Use /hm testui to disable.", 1, 0.6, 0.6))
    end

    initUnitFrames()
    StartDistanceScanner()

    HealersMateLib:RegisterEvent("Banzai_UnitGainedAggro", function(unit)
        if HMGuidRoster then
            unit = HMGuidRoster.GetUnitGuid(unit)
        end
        for ui in UnitFrames(unit) do
            ui:UpdateOutline()
        end
    end)
	HealersMateLib:RegisterEvent("Banzai_UnitLostAggro", function(unit)
        if HMGuidRoster then
            unit = HMGuidRoster.GetUnitGuid(unit)
        end
        for ui in UnitFrames(unit) do
            ui:UpdateOutline()
        end
    end)

    if HMOnLoadInfoDisabled == nil then
        HMOnLoadInfoDisabled = false
    end

    do
        local INFO_SEND_TIME = GetTime() + 0.5
        local infoFrame = CreateFrame("Frame")
        infoFrame:SetScript("OnUpdate", function()
            if GetTime() < INFO_SEND_TIME then
                return
            end
            infoFrame:SetScript("OnUpdate", nil)
            if not HMOnLoadInfoDisabled then
                DEFAULT_CHAT_FRAME:AddMessage(colorize("[HealersMate] Use ", 0.5, 1, 0.5)..colorize("/hm help", 0, 1, 0)
                    ..colorize(" to see commands.", 0.5, 1, 0.5))
            end
    
            if not util.IsSuperWowPresent() and util.IsNampowerPresent() then
                DEFAULT_CHAT_FRAME:AddMessage(colorize("[HealersMate] ", 1, 0.4, 0.4)..colorize("WARNING: ", 1, 0.2, 0.2)
                    ..colorize("You are using Nampower without SuperWoW, which will cause heal predictions to be wildly inaccurate "..
                    "for you and your raid members! It is highly recommended to install SuperWoW.", 1, 0.4, 0.4))
            end

            if util.IsSuperWowPresent() and not HealComm:IsEventRegistered("UNIT_CASTEVENT") then
                DEFAULT_CHAT_FRAME:AddMessage(colorize("[HealersMate] ", 1, 0.4, 0.4)..colorize("WARNING: ", 1, 0.2, 0.2)
                    ..colorize("You have another addon that uses a HealComm version that is incompatible with SuperWoW! "..
                    "This will cause wildly inaccurate heal predictions to be shown to your raid members. It is "..
                    "recommended to either unload the offending addon or copy HealersMate's HealComm "..
                    "into the other addon.", 1, 0.4, 0.4))
            end
        end)
    end

    -- Create default bindings for new characters
    if freshInstall then
        local class = GetClass("player")
        local spells = GetSpells()
        local hostileSpells = GetHostileSpells()
        if class == "PRIEST" then
            spells["None"]["LeftButton"] = "Power Word: Shield"
            spells["None"]["MiddleButton"] = "Renew"
            spells["None"]["RightButton"] = "Lesser Heal"
            spells["Shift"]["LeftButton"] = "Target"
            spells["Shift"]["RightButton"] = "Context"
            spells["Control"]["RightButton"] = "Dispel Magic"

            hostileSpells["None"]["RightButton"] = "Dispel Magic"
        elseif class == "DRUID" then
            spells["None"]["LeftButton"] = "Rejuvenation"
            spells["None"]["RightButton"] = "Healing Touch"
            spells["Shift"]["LeftButton"] = "Target"
            spells["Shift"]["MiddleButton"] = "Role"
            spells["Shift"]["RightButton"] = "Context"
            spells["Control"]["RightButton"] = "Remove Curse"
        elseif class == "PALADIN" then
            spells["None"]["LeftButton"] = "Flash of Light"
            spells["None"]["RightButton"] = "Holy Light"
            spells["Shift"]["LeftButton"] = "Target"
            spells["Shift"]["MiddleButton"] = "Role"
            spells["Shift"]["RightButton"] = "Context"
            spells["Control"]["RightButton"] = "Cleanse"
        elseif class == "SHAMAN" then
            spells["None"]["LeftButton"] = "Healing Wave"
            spells["None"]["RightButton"] = "Lesser Healing Wave"
            spells["Shift"]["LeftButton"] = "Target"
            spells["Shift"]["MiddleButton"] = "Role"
            spells["Shift"]["RightButton"] = "Context"
            spells["Control"]["RightButton"] = "Cure Disease"
        else
            -- Non-healer classes can use this addon like traditional raid frames
            spells["None"]["LeftButton"] = "Target"
            spells["None"]["MiddleButton"] = "Role"
            spells["None"]["RightButton"] = "Context"
        end
        hostileSpells["None"]["LeftButton"] = "Target"
    end

    do
        if HMOptions.Scripts.OnPostLoad then
            local scriptString = HMOptions.Scripts.OnPostLoad
            local script = loadstring(scriptString)
            local ok, result = pcall(script)
            if not ok then
                DEFAULT_CHAT_FRAME:AddMessage(colorize("[HealersMate] ", 1, 0.4, 0.4)..colorize("ERROR: ", 1, 0.2, 0.2)
                    ..colorize("The Postload Script produced an error! If this causes HealersMate to fail to operate, "..
                        "you may need to manually edit the script in your game files.", 1, 0.4, 0.4))
                DEFAULT_CHAT_FRAME:AddMessage(colorize("OnPostLoad Script Error: "..tostring(result), 1, 0, 0))
            end
        end
    end
end

function CheckPartyFramesEnabled()
    local shouldBeDisabled = (CurrentlyInRaid and HMOptions.DisablePartyFrames.InRaid) or 
        (not CurrentlyInRaid and HMOptions.DisablePartyFrames.InParty)
    SetPartyFramesEnabled(not shouldBeDisabled)
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
            if frame and not frame.HMRealShow then
                frame:UnregisterAllEvents()
                frame.HMRealShow = frame.Show
                frame.Show = function() end
                frame:Hide()
            end
        end
    end
end

LFTAutoRoleFrame = CreateFrame("Frame", "HM_LFTAutoRoleFrame")
function SetLFTAutoRoleEnabled(enabled)
    if not LFT_ADDON_PREFIX then -- Must not be Turtle WoW, or LFT has changed
        return
    end

    if not enabled then
        LFTAutoRoleFrame:SetScript("OnEvent", nil)
        LFTAutoRoleFrame:SetScript("OnUpdate", nil)
        LFTAutoRoleFrame:UnregisterAllEvents()
        return
    end

    if LFTAutoRoleFrame:GetScript("OnEvent") ~= nil then -- Already enabled
        return
    end
    
    local roleMap = {
        ["t"] = "Tank",
        ["h"] = "Healer",
        ["d"] = "Damage"
    }
    local offerCompleteTime = -1 -- The time the offer is completed, used to verify rolecheck info is valid
    local alreadyAssigned = {} -- The Tank & Healer names
    local scanDPSTime = -1
    local AutoRoleFrame_OnUpdate = function()
        if scanDPSTime > GetTime() then
            return
        end

        for _, unit in ipairs(PartyUnits) do
            local name = UnitName(unit)
            if name ~= "Unknown" and not util.ArrayContains(alreadyAssigned, name) then
                hmprint("Assuming "..name.." is Damage")
                SetAssignedRole(name, "Damage")
            end
        end
        UpdateUnitFrameGroups()
        LFTAutoRoleFrame:SetScript("OnUpdate", nil)
    end
    LFTAutoRoleFrame:RegisterEvent("CHAT_MSG_ADDON")
    LFTAutoRoleFrame:SetScript("OnEvent", function()
        if arg1 == LFT_ADDON_PREFIX then
            -- After an offer is complete, it is immediately followed by rolecheck info for the tank and healer
            if strfind(arg2, "S2C_ROLECHECK_INFO") then
                if GetNumPartyMembers() == 4 then
                    local params = util.SplitString(arg2, LFT_ADDON_FIELD_DELIMITER)
                    local member = params[2]
                    params = util.SplitString(params[3], ":") -- get confirmed roles
                    if offerCompleteTime + 0.5 > GetTime() and table.getn(params) == 1 then
                        local role = roleMap[params[1]]
                        table.insert(alreadyAssigned, member)
                        SetAssignedRole(member, role) -- Tank & Healer is sent after the offer is complete
                        hmprint("Assigning "..member.." to "..role)
                        if table.getn(alreadyAssigned) == 2 then -- Set rest as Damage after Tank & Healer is sent
                            -- Delay scanning party members because their names might not be loaded yet
                            scanDPSTime = GetTime() + 1.5
                            LFTAutoRoleFrame:SetScript("OnUpdate", AutoRoleFrame_OnUpdate)
                        end
                        UpdateUnitFrameGroups()
                    end
                end
            elseif strfind(arg2, "S2C_OFFER_COMPLETE") then
                alreadyAssigned = {}
                offerCompleteTime = GetTime()
            end
        end
    end)
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
    UpdateUnitFrameGroups()
    ToggleDropDownMenu(1, nil, _G["HMRoleDropdown"])
end

local function applyTargetRole(role)
    SetAssignedRole(roleTarget, role)
    UpdateUnitFrameGroups()
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
                UpdateUnitFrameGroups()
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
        UpdateUnitFrameGroups()
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
        -- Resolve focus to a proper unit if possible
        if AllCustomUnitsSet[unit] then
            unit = HMUnitProxy.ResolveCustomUnit(unit)
            if not unit then
                return
            end
        end

        local dropdown

        local specialContexts = {
            ["player"] = _G["PlayerFrameDropDown"],
            ["target"] = _G["TargetFrameDropDown"],
            ["pet"] = _G["PetFrameDropDown"]
        }
        if specialContexts[unit] then
            dropdown = specialContexts[unit]
        elseif util.StartsWith(unit, "raid") and not util.StartsWith(unit, "raidpet") then
            FriendsDropDown.displayMode = "MENU"
            FriendsDropDown.initialize = function()
                UnitPopup_ShowMenu(_G[UIDROPDOWNMENU_OPEN_MENU], "PARTY", unit, nil, string.sub(unit, 5))
            end
            dropdown = FriendsDropDown
        elseif util.StartsWith(unit, "party") and not util.StartsWith(unit, "partypet") then
            dropdown = _G["PartyMemberFrame"..string.sub(unit, 6).."DropDown"]
        end


        if dropdown then
            local frame = ui:GetRootContainer()
            ToggleDropDownMenu(1, nil, dropdown, frame:GetName(), frame:GetWidth(), 0)
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
    end,
    ["Focus"] = function(unit)
        if not util.IsSuperWowPresent() then
            DEFAULT_CHAT_FRAME:AddMessage(colorize("You need SuperWoW to focus targets.", 1, 0.5, 0.5))
            return
        end

        HM_ToggleFocusUnit(unit)
    end,
    ["Promote Focus"] = function(unit)
        if not util.IsSuperWowPresent() then
            DEFAULT_CHAT_FRAME:AddMessage(colorize("You need SuperWoW to focus targets.", 1, 0.5, 0.5))
            return
        end

        HM_PromoteFocus(unit)
    end,
    ["Demote Focus"] = function(unit)
        if not util.IsSuperWowPresent() then
            DEFAULT_CHAT_FRAME:AddMessage(colorize("You need SuperWoW to focus targets.", 1, 0.5, 0.5))
            return
        end

        HM_UnfocusUnit(unit)
        HM_FocusUnit(unit)
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

function _G.HM_ToggleFocusUnit(unit)
    if HMUnitProxy.IsUnitUnitType(unit, "focus") then
        if not HMUnitProxy.CustomUnitsSetMap["focus"][unit] then
            return -- Do not toggle focus if user is clicking on a UI that isn't the focus UI
        end
        HM_UnfocusUnit(unit)
    else
        HM_FocusUnit(unit)
    end
end

function _G.HM_FocusUnit(unit)
    local guid = HMGuidRoster.ResolveUnitGuid(unit)
    if not guid or HMUnitProxy.IsGuidUnitType(guid, "focus") then
        return
    end

    HMUnitProxy.SetGuidUnitType(guid, "focus")
    PlaySound("GAMETARGETHOSTILEUNIT")
end

function _G.HM_UnfocusUnit(unit)
    local guid = HMGuidRoster.ResolveUnitGuid(unit)
    if not guid then
        return
    end
    local focusUnit = HMUnitProxy.GetCurrentUnitOfType(guid, "focus")
    if not focusUnit then
        return
    end
    HMUnitProxy.SetCustomUnitGuid(focusUnit, nil)
    PlaySound("INTERFACESOUND_LOSTTARGETUNIT")
end

function _G.HM_PromoteFocus(unit)
    local guid = HMGuidRoster.ResolveUnitGuid(unit)
    if not guid then
        return
    end
    HMUnitProxy.PromoteGuidUnitType(guid, "focus")
end

function CycleFocus(onlyAttackable)
    HMUnitProxy.CycleUnitType("focus", onlyAttackable)
end

local Sound_Disabled = function() end

function ClickHandler(buttonType, unit, ui)
    local currentTargetEnemy = UnitCanAttack("player", "target")
    local spells = UnitCanAttack("player", unit) and GetHostileSpells() or GetSpells()
    local spell = spells[GetKeyModifier()][buttonType]
    if not UnitIsConnected(unit) or not UnitIsVisible(unit) then
        if spell and SpecialBinds[string.upper(spell)] then
            SpecialBinds[string.upper(spell)](unit, ui)
        end
        return
    end
    if HMOptions.AutoResurrect and util.IsDeadFriend(unit) then
        if spell and SpecialBinds[string.upper(spell)] then
            SpecialBinds[string.upper(spell)](unit, ui)
            return
        end
        if HMUnit.Get(unit):HasBuffIDOrName(45568, "Holy Champion") and GetSpellID("Revive Champion") 
            and UnitAffectingCombat("player") then
                spell = "Revive Champion"
        else
            spell = ResurrectionSpells[GetClass("player")] or spell
        end
    end
    
    if spell == nil then
        return
    end

    if SpecialBinds[string.upper(spell)] then
        SpecialBinds[string.upper(spell)](unit, ui)
        return
    end

    local isItem = util.StartsWith(spell, ITEM_PREFIX)
    local isMacro = util.StartsWith(spell, MACRO_PREFIX)
    local isNonSpell = isItem or isMacro

    -- Not a special bind
    if util.IsSuperWowPresent() and not isNonSpell then -- No target changing shenanigans required with SuperWoW
        if HMOptions.AutoTarget and not UnitIsUnit("target", unit) then
            TargetUnit(unit)
        end
        CastSpellByName(spell, unit)
    else
        local currentTarget = UnitName("target")
        local targetChanged = false
        -- Check if target is not already targeted
        if not UnitIsUnit("target", unit) then
            -- Set target as target
            local Sound_Enabled = PlaySound
            _G.PlaySound = Sound_Disabled
            TargetUnit(unit)
            _G.PlaySound = Sound_Enabled
            targetChanged = true
        end

        if isItem then
            UseItem(string.sub(spell, string.len(ITEM_PREFIX) + 1))
        elseif isMacro then
            RunMacro(string.sub(spell, string.len(MACRO_PREFIX) + 1), unit)
        else
            CastSpellByName(spell)
        end

        --Put Target of player back to whatever it was before casting spell
        if targetChanged and not HMOptions.AutoTarget then
            if currentTarget == nil then
                --Player wasn't targeting anything before casting spell
                local Sound_Enabled = PlaySound
                _G.PlaySound = Sound_Disabled
                ClearTarget()
                _G.PlaySound = Sound_Enabled
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
    if GetNumRaidMembers() > 0 then
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
        GuidRoster.ResetRoster()
        GuidRoster.PopulateRoster()
        HMUnit.UpdateGuidCaches()
    end
    for _, unit in ipairs(util.AllRealUnits) do
        local exists, guid = UnitExists(unit)
        if unit ~= "target" then
            if exists then
                for ui in UnitFrames(unit) do
                    ui:Show()
                end
            else
                for ui in UnitFrames(unit) do
                    ui:Hide()
                end
            end
        end
    end
    for _, group in pairs(UnitFrameGroups) do
        group:EvaluateShown()
    end
    if not superwow then -- If SuperWoW isn't present, the units may have shifted and thus require a full scan
        HMUnit.UpdateAllUnits()
    end
    for _, ui in pairs(AllUnitFrames) do
        if ui:IsShown() then
            ui:UpdateRange()
            ui:UpdateAuras()
            ui:UpdateIncomingHealing()
            ui:UpdateOutline()
        end
    end
    if superwow then
        HMHealPredict.SetRelevantGUIDs(GuidRoster.GetTrackedGuids())
    end
    RunTrackingScan()
end

function CheckTarget()
    local exists, guid = UnitExists("target")
    if exists then
        local friendly = not UnitCanAttack("player", "target")
        if (friendly and HMOptions.ShowTargets.Friendly) or (not friendly and HMOptions.ShowTargets.Hostile) then
            for ui in UnitFrames("target") do
                ui.lastHealthPercent = (ui:GetCurrentHealth() / ui:GetMaxHealth()) * 100
                ui:UpdateRange()
                ui:UpdateSight()
                ui:UpdateRole()
                ui:UpdateIncomingHealing()
            end
        end
    else
        for ui in UnitFrames("target") do
            ui.lastHealthPercent = (ui:GetCurrentHealth() / ui:GetMaxHealth()) * 100
            ui:UpdateAll()
            ui:UpdateRole()
            ui:UpdateIncomingHealing()
        end
    end
    UnitFrameGroups["Target"]:EvaluateShown()
end


function IsRelevantUnit(unit)
    --return not string.find(unit, "0x")
    return AllUnitsSet[unit] ~= nil or GUIDCustomUnitMap[unit]
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
        for ui in UnitFrames(unit) do
            ui:UpdateHealth()
        end
    elseif event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" or 
            event == "UNIT_FOCUS" or event == "UNIT_MAXMANA" or event == "UNIT_DISPLAYPOWER" then
        local unit = arg1
        if not IsRelevantUnit(unit) then
            return
        end

        for ui in UnitFrames(unit) do
            ui:UpdatePower()
        end
        
        if unit == "player" then
            ReapplySpellsTooltip()
        end
        
    elseif event == "UNIT_AURA" then
        local unit = arg1
        if not IsRelevantUnit(unit) then
            return
        end
        HMUnit.Get(unit):UpdateAuras()
        for ui in UnitFrames(unit) do
            ui:UpdateAuras()
            ui:UpdateHealth() -- Update health because there may be an aura that changes health bar color
        end

    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        CheckGroup()
    elseif event == "UNIT_PET" or event == "PLAYER_PET_CHANGED" then
        local unit = arg1
        if IsRelevantUnit(unit) then
            CheckGroup()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        for _, ui in ipairs(AllUnitFrames) do
            ui:EvaluateTarget()
        end
        local exists, guid = UnitExists("target")
        if guid then
            HMUnit.UpdateGuidCaches()
        end
        
        HMUnit.Get("target"):UpdateAll()
        if util.IsSuperWowPresent() then
            GuidRoster.SetUnitGuid("target", guid)
            HMHealPredict.SetRelevantGUIDs(GuidRoster.GetTrackedGuids())
        end

        if exists then
            EvaluateTracking("target", true)
        end

        if HMOptions.Hidden then
            return
        end

        CheckTarget()
    elseif event == "SPELLS_CHANGED" then
        HealersMateSettings.UpdateTrackedDebuffTypes()
    elseif event == "RAID_TARGET_UPDATE" then
        for _, ui in ipairs(AllUnitFrames) do
            ui:UpdateRaidMark()
        end
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