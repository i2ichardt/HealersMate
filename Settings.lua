HealersMateSettings = {}

local util = getglobal("HMUtil")

local _, playerClass = UnitClass("player")

function HealersMateSettings.UpdateTrackedDebuffTypes()
    local debuffTypeCureSpells = {
        ["PALADIN"] = {
            ["Purify"] = {"Poison", "Disease"},
            ["Cleanse"] = {"Poison", "Disease", "Magic"}
        },
        ["PRIEST"] = {
            ["Cure Disease"] = {"Disease"},
            ["Abolish Disease"] = {"Disease"},
            ["Dispel Magic"] = {"Magic"}
        },
        ["DRUID"] = {
            ["Cure Poison"] = {"Poison"},
            ["Abolish Poison"] = {"Poison"},
            ["Remove Curse"] = {"Curse"}
        },
        ["SHAMAN"] = {
            ["Cure Poison"] = {"Poison"},
            ["Cure Disease"] = {"Disease"}
        },
        ["MAGE"] = {
            ["Remove Lesser Curse"] = {"Curse"}
        }
    }

    for _, class in ipairs(util.GetClasses()) do
        if not debuffTypeCureSpells[class] then
            debuffTypeCureSpells[class] = {}
        end
    end

    local trackedDebuffTypes = {}
    do
        local id = 1;
        for i = 1, GetNumSpellTabs() do
            local _, _, _, numSpells = GetSpellTabInfo(i);
            for j = 1, numSpells do
                local spellName = GetSpellName(id, "spell");
                local types = debuffTypeCureSpells[playerClass][spellName]
                if types then
                    for _, type in ipairs(types) do
                        trackedDebuffTypes[type] = 1
                    end
                end
                id = id + 1
            end
        end
    end
    HealersMateSettings.TrackedDebuffTypesSet = trackedDebuffTypes
    trackedDebuffTypes = util.ToArray(trackedDebuffTypes)

    HealersMateSettings.TrackedDebuffTypes = trackedDebuffTypes
end

function HealersMateSettings.SetDefaults()
    if not HMOptions then
        HMOptions = {}
    end
    
    local isHealer = util.IsHealerClass("player")
    local isManaUser = util.ClassPowerTypes[util.GetClass("player")]
    do
        local defaults = {
            ["ShowTargets"] = {
                ["Friendly"] = isHealer,
                ["Hostile"] = false
            },
            ["AlwaysShowTargetFrame"] = false,
            ["AutoTarget"] = false,
            ["FrameDrag"] = {
                ["MoveAll"] = false,
                ["AltMoveKey"] = "Shift"
            },
            ["DisablePartyFrames"] = {
                ["InParty"] = false,
                ["InRaid"] = false
            },
            ["SpellsTooltip"] = {
                ["ShowManaCost"] = false,
                ["ShowManaPercentCost"] = true,
                ["HideCastsAbove"] = 3,
                ["CriticalCastsLevel"] = 3,
                ["AbbreviatedKeys"] = false,
                ["ColoredKeys"] = true,
                ["ShowPowerBar"] = true,
                ["ShowPowerAs"] = isManaUser and "Power %" or "Power" -- "Power", "Power/Max Power", "Power %"
            },
            ["ShowAuraTimesAt"] = {
                ["Short"] = 5, -- <1 min
                ["Medium"] = 10, -- <=2 min
                ["Long"] = 60 * 2 -- >2 min
            },
            ["CastWhen"] = "Mouse Up", -- Mouse Up, Mouse Down
            ["ShowSpellsTooltip"] = isHealer,
            ["UseHealPredictions"] = true,
            ["SetMouseover"] = true,
            ["TestUI"] = false,
            ["Hidden"] = false,
            ["ChosenProfiles"] = {
                ["Party"] = "Compact",
                ["Pets"] = "Compact",
                ["Raid"] = "Compact (Small)",
                ["Raid Pets"] = "Compact (Small)",
                ["Target"] = "Long",
                ["Focus"] = "Compact"
            },
            ["Scripts"] = {
                ["OnLoad"] = "",
                ["OnPostLoad"] = ""
            },
            ["OptionsVersion"] = 1
        }
    
        for field, value in pairs(defaults) do
            if HMOptions[field] == nil then
                if type(value) == "table" then
                    HMOptions[field] = HMUtil.CloneTable(value, true)
                else
                    HMOptions[field] = value
                end
            elseif type(value) == "table" then
                for field2, value2 in pairs(value) do
                    if HMOptions[field][field2] == nil then
                        if type(value2) == "table" then
                            HMOptions[field][field2] = HMUtil.CloneTable(value2, true)
                        else
                            HMOptions[field][field2] = value2
                        end
                    end
                end
            end
        end
    end
end

-- This file needs serious cleaning and refactoring

setmetatable(HealersMateSettings, {__index = getfenv(1)})
setfenv(1, HealersMateSettings)

TrackedBuffs = nil -- Default tracked is variable based on class
TrackedDebuffs = nil -- Default tracked is variable based on class
TrackedDebuffTypes = {} -- Default tracked is variable based on class

-- Buffs/debuffs that significantly modify healing
TrackedHealingBuffs = {"Amplify Magic", "Dampen Magic"}
TrackedHealingDebuffs = {"Mortal Strike", "Wound Poison", "Curse of the Deadwood", "Veil of Shadow", "Gehennas' Curse", 
    "Necrotic Poison", "Blood Fury", "Necrotic Aura", 
    "Shadowbane Curse" -- Turtle WoW
}

do
    -- Tracked buffs for all classes
    local defaultTrackedBuffs = {
        "Blessing of Protection", "Hand of Protection", "Divine Protection", "Divine Shield", "Divine Intervention", -- Paladin
            "Bulwark of the Righteous", "Blessing of Sacrifice", "Hand of Sacrifice",
        "Power Infusion", "Spirit of Redemption", "Inner Focus", "Abolish Disease", "Power Word: Shield", -- Priest
        "Shield Wall", "Recklessness", "Last Stand", -- Warrior
        "Evasion", "Vanish", -- Rogue
        "Deterrence", "Feign Death", "Mend Pet", -- Hunter
        "Frenzied Regeneration", "Innervate", "Abolish Poison", -- Druid
        "Soulstone Resurrection", "Hellfire", -- Warlock
        "Ice Block", "Evocation", "Ice Barrier", "Mana Shield", -- Mage
        "Quel'dorei Meditation", "Grace of the Sunwell", -- Racial
        "First Aid", "Food", "Drink" -- Generic
    }
    -- Tracked buffs for specific classes
    local defaultClassTrackedBuffs = {
        ["PALADIN"] = {"Blessing of Wisdom", "Blessing of Might", "Blessing of Salvation", "Blessing of Sanctuary", 
            "Blessing of Kings", "Greater Blessing of Wisdom", "Greater Blessing of Might", 
            "Greater Blssing of Salvation", "Greater Blessing of Sanctuary", "Greater Blessing of Kings", "Daybreak", 
            "Blessing of Freedom", "Hand of Freedom", "Redoubt", "Holy Shield"},
        ["PRIEST"] = {"Prayer of Fortitude", "Power Word: Fortitude", "Prayer of Spirit", "Divine Spirit", 
            "Prayer of Shadow Protection", "Shadow Protection", "Holy Champion", "Champion's Grace", "Empower Champion", 
            "Fear Ward", "Inner Fire", "Renew", "Lightwell Renew", "Inspiration", 
            "Fade", "Spirit Tap"},
        ["WARRIOR"] = {"Battle Shout"},
        ["DRUID"] = {"Gift of the Wild", "Mark of the Wild", "Thorns", "Rejuvenation", "Regrowth"},
        ["SHAMAN"] = {"Water Walking", "Healing Way", "Ancestral Fortitude"},
        ["MAGE"] = {"Arcane Brilliance", "Arcane Intellect", "Frost Armor", "Ice Armor", "Mage Armor"},
        ["WARLOCK"] = {"Demon Armor", "Demon Skin", "Unending Breath", "Shadow Ward", "Fire Shield"},
        ["HUNTER"] = {"Rapid Fire", "Quick Shots", "Quick Strikes", "Aspect of the Pack", 
            "Aspect of the Wild", "Bestial Wrath", "Feed Pet Effect"}
    }
    local trackedBuffs = defaultClassTrackedBuffs[playerClass] or {}
    util.AppendArrayElements(trackedBuffs, TrackedHealingBuffs)
    util.AppendArrayElements(trackedBuffs, defaultTrackedBuffs)
    trackedBuffs = util.ToSet(trackedBuffs, true)

    -- Tracked debuffs for all classes
    local defaultTrackedDebuffs = {
        "Forbearance", -- Paladin
        "Death Wish", -- Warrior
        "Enrage", -- Druid
        "Recently Bandaged", "Resurrection Sickness", "Ghost", -- Generic
        "Deafening Screech" -- Applied by mobs
    }
    -- Tracked debuffs for specific classes
    local defaultClassTrackedDebuffs = {
        ["PRIEST"] = {"Weakened Soul"}
    }
    local trackedDebuffs = defaultClassTrackedDebuffs[playerClass] or {}
    util.AppendArrayElements(trackedDebuffs, TrackedHealingDebuffs)
    util.AppendArrayElements(trackedDebuffs, defaultTrackedDebuffs)
    trackedDebuffs = util.ToSet(trackedDebuffs, true)

    TrackedBuffs = trackedBuffs
    TrackedDebuffs = trackedDebuffs

    TrackedHealingBuffs = util.ToSet(TrackedHealingBuffs)
    TrackedHealingDebuffs = util.ToSet(TrackedHealingDebuffs)
end

ShowEmptySpells = true
IgnoredEmptySpells = {--[["MiddleButton"]]}
IgnoredEmptySpells = util.ToSet(IgnoredEmptySpells)
CustomButtonOrder = {
    "LeftButton",
    "MiddleButton",
    "RightButton",
    "Button5",
    "Button4"
}
CustomButtonNames = {
    ["Button4"] = "Back", 
    ["Button5"] = "Forward"
}

DebuffTypeColors = {
    ["Magic"] = {0.35, 0.35, 1},
    ["Curse"] = {0.5, 0, 1},
    ["Disease"] = {0.45, 0.35, 0.16},
    ["Poison"] = {0.6, 0.7, 0}
}


EditedSpells = {}
SpellsContext = {}

function GetSelectedProfileName(frame)
    local selected = HMOptions.ChosenProfiles[frame]
    if not HMDefaultProfiles[selected] then
        selected = "Compact"
    end
    return selected
end

function GetSelectedProfile(frame)
    return HMDefaultProfiles[GetSelectedProfileName(frame)]
end


function InitSettings()
    --Used too set custom tooltip information when you mouse over things; like in the settings checkboxes
    local MyTooltip = CreateFrame("GameTooltip", "HMSettingsInfoTooltip", UIParent, "GameTooltipTemplate")

    --Fucntion that is called to set the text of a custom tooltip and where to display it.
    local function ShowTooltip(AttachTo, TooltipText1, TooltipText2)
        MyTooltip:SetOwner(AttachTo, "ANCHOR_RIGHT")
        MyTooltip:SetPoint("RIGHT", AttachTo, "LEFT", 0, 0)
            
        MyTooltip:AddLine(TooltipText1, 0.3, 1, 0.3)
        
        if TooltipText2 ~= "" then
            MyTooltip:AddLine(TooltipText2, 0.5, 1, 0.5)
        end
            
        HMSettingsInfoTooltipTextLeft1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        HMSettingsInfoTooltipTextLeft2:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        
        MyTooltip:Show()
    end

    --Used to hide custom tooltips
    local function HideTooltip()
        MyTooltip:Hide()
    end

    local function ApplyTooltip(component, header, footer)
        component:SetScript("OnEnter", function()
            ShowTooltip(component, header, footer)
        end)
        component:SetScript("OnLeave", HideTooltip)
    end


    -- Create the main SETTINGS frame
    local container = CreateFrame("Frame", "HM_SettingsContainer", UIParent)
    container:SetToplevel(true)
    container:SetFrameLevel(15)
    container:SetWidth(425) -- width
    container:SetHeight(475) -- height
    container:SetPoint("CENTER", UIParent, "CENTER")
    --container:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
    container:EnableMouse(true)
    container:SetMovable(true)
    container:Hide()

    if Aero then
        Aero:RegisterAddon("HealersMate", "HM_SettingsContainer")
    end

    container:SetScript("OnMouseDown", function()
        local button = arg1

        if button == "LeftButton" and not container.isMoving then
            container:StartMoving();
            container.isMoving = true;
        end
    end)
    
    container:SetScript("OnMouseUp", function()
        local button = arg1

        if button == "LeftButton" and container.isMoving then
            container:StopMovingOrSizing();
            container.isMoving = false;
        end
    end)

    table.insert(UISpecialFrames, container:GetName()) -- Allows frame to the closed with escape



    local containerBorder = CreateFrame("Frame", "$parentBorder", container)
    containerBorder:SetWidth(450) -- width
    containerBorder:SetHeight(500) -- height
    containerBorder:SetPoint("CENTER", container, "CENTER")
    containerBorder:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32, 
        insets = { left = 8, right = 8, top = 8, bottom = 8 }, tile = true, tileSize = 32})

    containerBorder.title = CreateFrame("Frame", container:GetName().."Title", containerBorder)
    containerBorder.title:SetPoint("TOP", containerBorder, "TOP", 0, 12)
    containerBorder.title:SetWidth(350)
    containerBorder.title:SetHeight(64)

    containerBorder.title.header = containerBorder.title:CreateTexture(nil, "MEDIUM")
    containerBorder.title.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    containerBorder.title.header:SetAllPoints()

    containerBorder.title.text = containerBorder.title:CreateFontString(nil, "HIGH", "GameFontNormal")
    containerBorder.title.text:SetText("HealersMate Settings")
    containerBorder.title.text:SetPoint("TOP", 0, -14)



    function resetSpells()
        EditedSpells = {}
        for context, spells in pairs(HMSpells) do
            EditedSpells[context] = {}
            local copy = EditedSpells[context]
            for modifier, buttons in pairs(spells) do
                copy[modifier] = {}
                for button, spell in pairs(buttons) do
                    copy[modifier][button] = spell
                end
            end
        end
        SpellsContext = EditedSpells[UIDropDownMenu_GetSelectedName(targetDropdown)]
    end



    -- Main Settings Page - Close Button
    local closeButton = CreateFrame("Button", nil, container, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", container, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() container:Hide() end)


    local frameNames = {}
    local frames = {}

    local function addFrame(name, frame)
        table.insert(frameNames, name)
        frames[name] = frame
    end

    local spellsFrame = CreateFrame("Frame", "spellsFrame", container)
    addFrame("Spells", spellsFrame)
    spellsFrame:SetWidth(400)
    spellsFrame:SetHeight(440)
    spellsFrame:SetPoint("CENTER", container, "CENTER", 0, -20)
    local spellsFrameOldShow = spellsFrame.Show
    spellsFrame.Show = function(self)
        spellsFrameOldShow(self)
        resetSpells()
    end
    spellsFrame:Hide()

    local optionsScrollFrame = CreateFrame("ScrollFrame", "$parentOptionsScrollFrame", container, "UIPanelScrollFrameTemplate")
    optionsScrollFrame:SetWidth(400) -- width
    optionsScrollFrame:SetHeight(440) -- height
    optionsScrollFrame:SetPoint("CENTER", container, "CENTER", -10, -20)
    optionsScrollFrame:Hide() -- Initially hidden

    local optionsFrame = CreateFrame("Frame", "$parentOptionsFrame", optionsScrollFrame)
    optionsFrame:SetWidth(400) -- width
    optionsFrame:SetHeight(440) -- height
    --optionsFrame:SetPoint("CENTER", container, "CENTER", -200, 0)

    optionsScrollFrame:SetScrollChild(optionsFrame)
    optionsScrollFrame:Hide()
    addFrame("Options", optionsScrollFrame)

    local xOffset = 140
    local xDropdownOffset = 30
    local yOffset = -20
    local yCheckboxOffset = -2
    local yDropdownOffset = -5
    local yInterval = -30

    do
        local TargetSettingsLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        TargetSettingsLabel:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 0, yOffset)
        TargetSettingsLabel:SetFont("Fonts\\FRIZQT__.TTF", 14)
        TargetSettingsLabel:SetWidth(optionsFrame:GetWidth())
        TargetSettingsLabel:SetJustifyH("CENTER")
        TargetSettingsLabel:SetText("Target Settings")
    end

    yOffset = yOffset + yInterval

    do
        local ShowTargetLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ShowTargetLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        ShowTargetLabel:SetText("Always Show Target")

        local ShowTargetCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        ShowTargetCheckbox:SetPoint("LEFT", ShowTargetLabel, "RIGHT", 5, yCheckboxOffset)
        ShowTargetCheckbox:SetWidth(20) -- width
        ShowTargetCheckbox:SetHeight(20) -- height
        ShowTargetCheckbox:SetChecked(HMOptions.AlwaysShowTargetFrame)
        ShowTargetCheckbox:SetScript("OnClick", function()
            HMOptions.AlwaysShowTargetFrame = ShowTargetCheckbox:GetChecked() == 1
            HealersMate.CheckTarget()
        end)
        ApplyTooltip(ShowTargetCheckbox, "Always show the target frame, regardless of whether you have a target or not")
    end

    yOffset = yOffset - 20

    do
        -- Label for the checkbox
        local CheckboxShowTargetLabel = optionsFrame:CreateFontString("CheckboxShowTargetLabel", "OVERLAY", "GameFontNormal")
        CheckboxShowTargetLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        CheckboxShowTargetLabel:SetText("Show Targets:")

        -- Label for the "Friendly" checkbox
        local CheckboxFriendlyLabel = optionsFrame:CreateFontString("CheckboxFriendlyLabel", "OVERLAY", "GameFontNormal")
        CheckboxFriendlyLabel:SetPoint("LEFT", CheckboxShowTargetLabel, "RIGHT", 20, 0)
        CheckboxFriendlyLabel:SetText("Friendly")

        -- Create the "Friendly" checkbox
        local CheckboxFriendly = CreateFrame("CheckButton", "$parentTargetFriendly", optionsFrame, "UICheckButtonTemplate")
        CheckboxFriendly:SetPoint("LEFT", CheckboxFriendlyLabel, "RIGHT", 5, yCheckboxOffset)
        CheckboxFriendly:SetWidth(20) -- width
        CheckboxFriendly:SetHeight(20) -- height
        CheckboxFriendly:SetChecked(HMOptions.ShowTargets.Friendly)
        CheckboxFriendly:SetScript("OnClick", function()
            HMOptions.ShowTargets.Friendly = CheckboxFriendly:GetChecked() == 1
            HealersMate.CheckTarget()
        end)
        ApplyTooltip(CheckboxFriendly, "Show the Target frame when targeting friendlies", 
            "No effect if Always Show Target is checked")

        -- Label for the "Enemy" checkbox
        local CheckboxEnemyLabel = optionsFrame:CreateFontString("CheckboxEnemyLabel", "OVERLAY", "GameFontNormal")
        CheckboxEnemyLabel:SetPoint("LEFT", CheckboxFriendly, "RIGHT", 10, -yCheckboxOffset)
        CheckboxEnemyLabel:SetText("Hostile")

        -- Create the "Enemy" checkbox
        local CheckboxHostile = CreateFrame("CheckButton", "$parentTargetHostile", optionsFrame, "UICheckButtonTemplate")
        CheckboxHostile:SetPoint("LEFT", CheckboxEnemyLabel, "RIGHT", 5, yCheckboxOffset)
        CheckboxHostile:SetWidth(20) -- width
        CheckboxHostile:SetHeight(20) -- height
        CheckboxHostile:SetChecked(HMOptions.ShowTargets.Hostile)
        CheckboxHostile:SetScript("OnClick", function()
            HMOptions.ShowTargets.Hostile = CheckboxHostile:GetChecked() == 1
            HealersMate.CheckTarget()
        end)
        ApplyTooltip(CheckboxHostile, "Show the Target frame when targeting hostiles", 
            "No effect if Always Show Target is checked")
    end

    yOffset = yOffset - 30

    local CheckboxAutoTargetLabel = optionsFrame:CreateFontString("CheckboxAutoTargetLabel", "OVERLAY", "GameFontNormal")
    CheckboxAutoTargetLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
    CheckboxAutoTargetLabel:SetText("Target On Cast")

    local CheckboxAutoTarget = CreateFrame("CheckButton", "$parentAutoTarget", optionsFrame, "UICheckButtonTemplate")
    CheckboxAutoTarget:SetPoint("LEFT", CheckboxAutoTargetLabel, "RIGHT", 5, yCheckboxOffset)
    CheckboxAutoTarget:SetWidth(20) -- width
    CheckboxAutoTarget:SetHeight(20) -- height
    CheckboxAutoTarget:SetChecked(HMOptions.AutoTarget)
    CheckboxAutoTarget:SetScript("OnClick", function()
        HMOptions.AutoTarget = CheckboxAutoTarget:GetChecked() == 1
    end)
    ApplyTooltip(CheckboxAutoTarget, "If enabled, casting a spell on a player will also cause you to target them")

    yOffset = yOffset - 30

    do
        local SpellsTooltipSettingsLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SpellsTooltipSettingsLabel:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 0, yOffset)
        SpellsTooltipSettingsLabel:SetFont("Fonts\\FRIZQT__.TTF", 14)
        SpellsTooltipSettingsLabel:SetWidth(optionsFrame:GetWidth())
        SpellsTooltipSettingsLabel:SetJustifyH("CENTER")
        SpellsTooltipSettingsLabel:SetText("Spells Tooltip Settings")
    end

    yOffset = yOffset - 30

    do
        local CheckboxShowSpellsTooltipLabel = optionsFrame:CreateFontString("CheckboxShowSpellsTooltipLabel", "OVERLAY", "GameFontNormal")
        CheckboxShowSpellsTooltipLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        CheckboxShowSpellsTooltipLabel:SetText("Show Spells Tooltip")

        local CheckboxShowSpellsTooltip = CreateFrame("CheckButton", "$parentShowSpellsTooltip", optionsFrame, "UICheckButtonTemplate")
        CheckboxShowSpellsTooltip:SetPoint("LEFT", CheckboxShowSpellsTooltipLabel, "RIGHT", 5, yCheckboxOffset)
        CheckboxShowSpellsTooltip:SetWidth(20) -- width
        CheckboxShowSpellsTooltip:SetHeight(20) -- height
        CheckboxShowSpellsTooltip:SetChecked(HMOptions.ShowSpellsTooltip)
        CheckboxShowSpellsTooltip:SetScript("OnClick", function()
            HMOptions.ShowSpellsTooltip = CheckboxShowSpellsTooltip:GetChecked() == 1
        end)
        ApplyTooltip(CheckboxShowSpellsTooltip, "Show the spells tooltip when hovering over frames")
    end

    yOffset = yOffset - 30

    do
        local ShowPercManaCostLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ShowPercManaCostLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        ShowPercManaCostLabel:SetText("Show % Mana Cost")

        local ShowPercManaCostCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        ShowPercManaCostCheckbox:SetPoint("LEFT", ShowPercManaCostLabel, "RIGHT", 5, yCheckboxOffset)
        ShowPercManaCostCheckbox:SetWidth(20) -- width
        ShowPercManaCostCheckbox:SetHeight(20) -- height
        ShowPercManaCostCheckbox:SetChecked(HMOptions.SpellsTooltip.ShowManaPercentCost)
        ShowPercManaCostCheckbox:SetScript("OnClick", function()
            HMOptions.SpellsTooltip.ShowManaPercentCost = ShowPercManaCostCheckbox:GetChecked() == 1
        end)
        ApplyTooltip(ShowPercManaCostCheckbox, "Show the percent mana cost in the spells tooltip", "Does nothing for non-mana users")

        local ShowManaCostLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ShowManaCostLabel:SetPoint("LEFT", ShowPercManaCostCheckbox, "RIGHT", 20, -yCheckboxOffset)
        ShowManaCostLabel:SetText("Show # Mana Cost")

        local ShowManaCostCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        ShowManaCostCheckbox:SetPoint("LEFT", ShowManaCostLabel, "RIGHT", 5, yCheckboxOffset)
        ShowManaCostCheckbox:SetWidth(20) -- width
        ShowManaCostCheckbox:SetHeight(20) -- height
        ShowManaCostCheckbox:SetChecked(HMOptions.SpellsTooltip.ShowManaCost)
        ShowManaCostCheckbox:SetScript("OnClick", function()
            HMOptions.SpellsTooltip.ShowManaCost = ShowManaCostCheckbox:GetChecked() == 1
        end)
        ApplyTooltip(ShowManaCostCheckbox, "Show the number mana cost in the spells tooltip", "Does nothing for non-mana users")
    end

    yOffset = yOffset - 30

    do
        local HideCastsAboveLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        HideCastsAboveLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        HideCastsAboveLabel:SetText("Hide Casts Above")

        local HideCastsAboveEditBox = CreateFrame("Editbox", "$parentHideCastsAboveEditBox", optionsFrame, "InputBoxTemplate")
        HideCastsAboveEditBox:SetPoint("LEFT", HideCastsAboveLabel, "RIGHT", 10, yCheckboxOffset)
        HideCastsAboveEditBox:SetWidth(30)
        HideCastsAboveEditBox:SetHeight(20)
        HideCastsAboveEditBox:SetText(tostring(HMOptions.SpellsTooltip.HideCastsAbove))
        HideCastsAboveEditBox:SetAutoFocus(false)
        HideCastsAboveEditBox:SetScript("OnTextChanged" , function()
            local num = tonumber(this:GetText())
            if not num then
                return
            end
            num = math.floor(num)
            HMOptions.SpellsTooltip.HideCastsAbove = num
        end)
        HideCastsAboveEditBox:SetScript("OnEnterPressed", function()
            this:ClearFocus()
        end)
        HideCastsAboveEditBox:SetScript("OnEditFocusLost", function()
            this:SetText(tostring(HMOptions.SpellsTooltip.HideCastsAbove))
        end)
        ApplyTooltip(HideCastsAboveEditBox, "Hides the cast count for a spell if above this threshold")

        local CriticalCastsLevelLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        CriticalCastsLevelLabel:SetPoint("LEFT", HideCastsAboveEditBox, "RIGHT", 20, 0)
        CriticalCastsLevelLabel:SetText("Critical Casts Level")

        local CriticalCastsLevelEditBox = CreateFrame("Editbox", "$parentCriticalCastsLevelEditBox", optionsFrame, "InputBoxTemplate")
        CriticalCastsLevelEditBox:SetPoint("LEFT", CriticalCastsLevelLabel, "RIGHT", 10, 0)
        CriticalCastsLevelEditBox:SetWidth(30)
        CriticalCastsLevelEditBox:SetHeight(20)
        CriticalCastsLevelEditBox:SetText(tostring(HMOptions.SpellsTooltip.CriticalCastsLevel))
        CriticalCastsLevelEditBox:SetAutoFocus(false)
        CriticalCastsLevelEditBox:SetScript("OnTextChanged" , function()
            local num = tonumber(this:GetText())
            if not num then
                return
            end
            num = math.floor(num)
            HMOptions.SpellsTooltip.CriticalCastsLevel = num
        end)
        CriticalCastsLevelEditBox:SetScript("OnEnterPressed", function()
            this:ClearFocus()
        end)
        CriticalCastsLevelEditBox:SetScript("OnEditFocusLost", function()
            this:SetText(tostring(HMOptions.SpellsTooltip.CriticalCastsLevel))
        end)
        ApplyTooltip(CriticalCastsLevelEditBox, "At how many casts to show yellow casts text")
    end

    yOffset = yOffset - 30

    do
        local AbbreviateKeysLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        AbbreviateKeysLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        AbbreviateKeysLabel:SetText("Shortened Keys")

        local AbbreviateKeysCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        AbbreviateKeysCheckbox:SetPoint("LEFT", AbbreviateKeysLabel, "RIGHT", 5, yCheckboxOffset)
        AbbreviateKeysCheckbox:SetWidth(20) -- width
        AbbreviateKeysCheckbox:SetHeight(20) -- height
        AbbreviateKeysCheckbox:SetChecked(HMOptions.SpellsTooltip.AbbreviatedKeys)
        AbbreviateKeysCheckbox:SetScript("OnClick", function()
            HMOptions.SpellsTooltip.AbbreviatedKeys = AbbreviateKeysCheckbox:GetChecked() == 1
        end)
        ApplyTooltip(AbbreviateKeysCheckbox, "Shortens keys to 1 letter")

        local ColorKeysLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ColorKeysLabel:SetPoint("LEFT", AbbreviateKeysCheckbox, "RIGHT", 20, -yCheckboxOffset)
        ColorKeysLabel:SetText("Colored Keys")

        local ColorKeysCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        ColorKeysCheckbox:SetPoint("LEFT", ColorKeysLabel, "RIGHT", 5, yCheckboxOffset)
        ColorKeysCheckbox:SetWidth(20) -- width
        ColorKeysCheckbox:SetHeight(20) -- height
        ColorKeysCheckbox:SetChecked(HMOptions.SpellsTooltip.ColoredKeys)
        ColorKeysCheckbox:SetScript("OnClick", function()
            HMOptions.SpellsTooltip.ColoredKeys = ColorKeysCheckbox:GetChecked() == 1
        end)
        ApplyTooltip(ColorKeysCheckbox, "Color code the keys as opposed to all being white")
    end

    yOffset = yOffset - 30

    do
        local showPowerAsDropdown = CreateFrame("Frame", "$parentShowPowerAsDropdown", optionsFrame, "UIDropDownMenuTemplate")
        showPowerAsDropdown:Show()
        --castWhenDropdown:SetPoint("TOP", -65, -100)
        showPowerAsDropdown:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset + xDropdownOffset, yOffset + yDropdownOffset)

        local label = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("RIGHT", showPowerAsDropdown, "RIGHT", -30, 5)
        label:SetText("Show Power As")

        local states = {"Power", "Power/Max Power", "Power %"}
        local options = {}

        for _, key in ipairs(states) do
            table.insert(options, {
                text = key,
                arg1 = key,
                func = function(targetArg)
                    UIDropDownMenu_SetSelectedName(showPowerAsDropdown, targetArg, false)
                    HMOptions.SpellsTooltip.ShowPowerAs = targetArg
                end
            })
        end

        UIDropDownMenu_Initialize(showPowerAsDropdown, function(self, level)
            for _, targetOption in ipairs(options) do
                targetOption.checked = false
                UIDropDownMenu_AddButton(targetOption)
            end
            if UIDropDownMenu_GetSelectedName(showPowerAsDropdown) == nil then
                UIDropDownMenu_SetSelectedName(showPowerAsDropdown, HMOptions.SpellsTooltip.ShowPowerAs, false)
            end
        end)
    end

    yOffset = yOffset - 30

    do
        local ShowPowerBarLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ShowPowerBarLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        ShowPowerBarLabel:SetText("Show Power Bar")

        local ShowPowerBarCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        ShowPowerBarCheckbox:SetPoint("LEFT", ShowPowerBarLabel, "RIGHT", 5, yCheckboxOffset)
        ShowPowerBarCheckbox:SetWidth(20) -- width
        ShowPowerBarCheckbox:SetHeight(20) -- height
        ShowPowerBarCheckbox:SetChecked(HMOptions.SpellsTooltip.ShowPowerBar)
        ShowPowerBarCheckbox:SetScript("OnClick", function()
            HMOptions.SpellsTooltip.ShowPowerBar = ShowPowerBarCheckbox:GetChecked() == 1
            if HMOptions.SpellsTooltip.ShowPowerBar then
                HealersMate.SpellsTooltipPowerBar:Show()
            else
                HealersMate.SpellsTooltipPowerBar:Hide()
            end
        end)
        ApplyTooltip(ShowPowerBarCheckbox, "Show a power bar in the spells tooltip")

        -- Disable power bar now if it's disabled
        if not HMOptions.SpellsTooltip.ShowPowerBar then
            HealersMate.SpellsTooltipPowerBar:Hide()
        end
    end

    yOffset = yOffset - 30

    do
        local OtherSettingsLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        OtherSettingsLabel:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 0, yOffset)
        OtherSettingsLabel:SetFont("Fonts\\FRIZQT__.TTF", 14)
        OtherSettingsLabel:SetWidth(optionsFrame:GetWidth())
        OtherSettingsLabel:SetJustifyH("CENTER")
        OtherSettingsLabel:SetText("Other Settings")
    end

    yOffset = yOffset - 30

    do
        local castWhenDropdown = CreateFrame("Frame", "$parentCastWhenDropdown", optionsFrame, "UIDropDownMenuTemplate")
        castWhenDropdown:Show()
        --castWhenDropdown:SetPoint("TOP", -65, -100)
        castWhenDropdown:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset + xDropdownOffset, yOffset + yDropdownOffset)

        local label = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("RIGHT", castWhenDropdown, "RIGHT", -30, 5)
        label:SetText("Cast When")

        local states = {"Mouse Up", "Mouse Down"}
        local options = {}

        for _, key in ipairs(states) do
            table.insert(options, {
                text = key,
                arg1 = key,
                func = function(targetArg)
                    UIDropDownMenu_SetSelectedName(castWhenDropdown, targetArg, false)
                    HMOptions.CastWhen = targetArg
                    for _, ui in ipairs(HealersMate.AllUnitFrames) do
                        ui:RegisterClicks()
                    end
                end
            })
        end

        UIDropDownMenu_Initialize(castWhenDropdown, function(self, level)
            for _, targetOption in ipairs(options) do
                targetOption.checked = false
                UIDropDownMenu_AddButton(targetOption)
            end
            if UIDropDownMenu_GetSelectedName(castWhenDropdown) == nil then
                UIDropDownMenu_SetSelectedName(castWhenDropdown, HMOptions.CastWhen, false)
            end
        end)
    end

    yOffset = yOffset - 30

    do
        local CheckboxMoveAllLabel = optionsFrame:CreateFontString("$parentMoveAllLabel", "OVERLAY", "GameFontNormal")
        CheckboxMoveAllLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        CheckboxMoveAllLabel:SetText("Drag All Frames")

        local CheckboxMoveAll = CreateFrame("CheckButton", "$parentMoveAll", optionsFrame, "UICheckButtonTemplate")
        CheckboxMoveAll:SetPoint("LEFT", CheckboxMoveAllLabel, "RIGHT", 5, yCheckboxOffset)
        CheckboxMoveAll:SetWidth(20)
        CheckboxMoveAll:SetHeight(20)
        CheckboxMoveAll:SetChecked(HMOptions.FrameDrag.MoveAll)
        CheckboxMoveAll:SetScript("OnClick", function()
            HMOptions.FrameDrag.MoveAll = CheckboxMoveAll:GetChecked() == 1
        end)
        ApplyTooltip(CheckboxMoveAll, "If enabled, all frames will be moved when dragging", "Use the inverse key to move a single frame; Opposite effect if disabled")



        local inverseKeyDropdown = CreateFrame("Frame", "$parentMoveAllInverseKeyDropdown", optionsFrame, "UIDropDownMenuTemplate")
        inverseKeyDropdown:Show()
        inverseKeyDropdown:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset + xDropdownOffset + 110, yOffset + yDropdownOffset)

        local label = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("RIGHT", inverseKeyDropdown, "RIGHT", -30, 5)
        label:SetText("Inverse Key")

        local keys = {"Shift", "Control", "Alt"}
        local options = {}

        for _, key in ipairs(keys) do
            table.insert(options, {
                text = key,
                arg1 = key,
                func = function(targetArg)
                    UIDropDownMenu_SetSelectedName(inverseKeyDropdown, targetArg, false)
                    HMOptions.FrameDrag.AltMoveKey = targetArg
                end
            })
        end

        UIDropDownMenu_Initialize(inverseKeyDropdown, function(self, level)
            for _, targetOption in ipairs(options) do
                targetOption.checked = false
                UIDropDownMenu_AddButton(targetOption)
            end
            if UIDropDownMenu_GetSelectedName(inverseKeyDropdown) == nil then
                UIDropDownMenu_SetSelectedName(inverseKeyDropdown, HMOptions.FrameDrag.AltMoveKey, false)
            end
        end)
    end

    yOffset = yOffset - 30

    do
        local CheckboxHealPredictLabel = optionsFrame:CreateFontString("$parentHealPredictionsLabel", "OVERLAY", "GameFontNormal")
        CheckboxHealPredictLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        CheckboxHealPredictLabel:SetText("Use Heal Predictions")

        local CheckboxHealPredict = CreateFrame("CheckButton", "$parentHealPredictions", optionsFrame, "UICheckButtonTemplate")
        CheckboxHealPredict:SetPoint("LEFT", CheckboxHealPredictLabel, "RIGHT", 5, yCheckboxOffset)
        CheckboxHealPredict:SetWidth(20)
        CheckboxHealPredict:SetHeight(20)
        CheckboxHealPredict:SetChecked(HMOptions.UseHealPredictions)
        CheckboxHealPredict:SetScript("OnClick", function()
            HMOptions.UseHealPredictions = CheckboxHealPredict:GetChecked() == 1
            HealersMate.UpdateAllIncomingHealing()
        end)
        ApplyTooltip(CheckboxHealPredict, "See predictions on incoming healing", 
            "Improved predictions if using SuperWoW")
    end

    yOffset = yOffset - 30

    do
        -- Label for the checkbox
        local HidePartyFramesLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        HidePartyFramesLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        HidePartyFramesLabel:SetText("Hide Party Frames:")

        -- Label for the "Friendly" checkbox
        local InPartyLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        InPartyLabel:SetPoint("LEFT", HidePartyFramesLabel, "RIGHT", 20, 0)
        InPartyLabel:SetText("In Party")

        -- Create the "Friendly" checkbox
        local CheckboxInParty = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        CheckboxInParty:SetPoint("LEFT", InPartyLabel, "RIGHT", 5, yCheckboxOffset)
        CheckboxInParty:SetWidth(20) -- width
        CheckboxInParty:SetHeight(20) -- height
        CheckboxInParty:SetChecked(HMOptions.DisablePartyFrames.InParty)
        CheckboxInParty:SetScript("OnClick", function()
            HMOptions.DisablePartyFrames.InParty = CheckboxInParty:GetChecked() == 1
            HealersMate.CheckPartyFramesEnabled()
        end)
        ApplyTooltip(CheckboxInParty, "Hide default party frames while in party", "This may cause issues with other addons")

        -- Label for the "Enemy" checkbox
        local InRaidLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        InRaidLabel:SetPoint("LEFT", CheckboxInParty, "RIGHT", 10, -yCheckboxOffset)
        InRaidLabel:SetText("In Raid")

        -- Create the "Enemy" checkbox
        local CheckboxInRaid = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        CheckboxInRaid:SetPoint("LEFT", InRaidLabel, "RIGHT", 5, yCheckboxOffset)
        CheckboxInRaid:SetWidth(20) -- width
        CheckboxInRaid:SetHeight(20) -- height
        CheckboxInRaid:SetChecked(HMOptions.DisablePartyFrames.InRaid)
        CheckboxInRaid:SetScript("OnClick", function()
            HMOptions.DisablePartyFrames.InRaid = CheckboxInRaid:GetChecked() == 1
            HealersMate.CheckPartyFramesEnabled()
        end)
        ApplyTooltip(CheckboxInRaid, "Hide default party frames while in raid", "This may cause issues with other addons")
    end

    yOffset = yOffset - 40

    local superwow = util.IsSuperWowPresent()
    do
        local SuperWoWLabel = optionsFrame:CreateFontString("$parentSuperWoWLabel", "OVERLAY", "GameFontNormal")
        SuperWoWLabel:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 0, yOffset)
        SuperWoWLabel:SetFont("Fonts\\FRIZQT__.TTF", 14)
        SuperWoWLabel:SetWidth(optionsFrame:GetWidth())
        SuperWoWLabel:SetJustifyH("CENTER")
        SuperWoWLabel:SetText("SuperWoW Required Settings")

        yOffset = yOffset - 20

        local SuperWoWDetectedLabel = optionsFrame:CreateFontString("$parentSuperWoWDetectedLabel", "OVERLAY", "GameFontNormal")
        SuperWoWDetectedLabel:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 0, yOffset)
        SuperWoWDetectedLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        SuperWoWDetectedLabel:SetWidth(optionsFrame:GetWidth())
        SuperWoWDetectedLabel:SetJustifyH("CENTER")
        SuperWoWDetectedLabel:SetText(superwow and util.Colorize("SuperWoW Detected", 0.5, 1, 0.5) or 
            util.Colorize("SuperWoW Not Detected", 1, 0.6, 0.6))
    end

    yOffset = yOffset - 30

    do
        local CheckboxMouseoverLabel = optionsFrame:CreateFontString("$parentMouseoverLabel", "OVERLAY", "GameFontNormal")
        CheckboxMouseoverLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", xOffset, yOffset)
        CheckboxMouseoverLabel:SetText("Set Mouseover")

        local CheckboxMouseover = CreateFrame("CheckButton", "$parentMouseover", optionsFrame, "UICheckButtonTemplate")
        CheckboxMouseover:SetPoint("LEFT", CheckboxMouseoverLabel, "RIGHT", 5, yCheckboxOffset)
        CheckboxMouseover:SetWidth(20)
        CheckboxMouseover:SetHeight(20)
        CheckboxMouseover:SetChecked(HMOptions.SetMouseover)
        if not superwow then
            CheckboxMouseover:Disable()
        end
        CheckboxMouseover:SetScript("OnClick", function()
            HMOptions.SetMouseover = CheckboxMouseover:GetChecked() == 1
        end)
        ApplyTooltip(CheckboxMouseover, "Requires SuperWoW Mod To Work", 
            "If enabled, hovering over frames will set your mouseover target")
    end


    local customizeScrollFrame = CreateFrame("ScrollFrame", "$parentCustomizeScrollFrame", container, "UIPanelScrollFrameTemplate")
    customizeScrollFrame:SetWidth(400) -- width
    customizeScrollFrame:SetHeight(440) -- height
    customizeScrollFrame:SetPoint("CENTER", container, "CENTER", -10, -20)
    customizeScrollFrame:Hide() -- Initially hidden

    local customizeFrame = CreateFrame("Frame", "$parentContent", customizeScrollFrame)
    addFrame("Customize", customizeScrollFrame)
    customizeFrame:SetWidth(400) -- width
    customizeFrame:SetHeight(440) -- height
    customizeFrame:SetPoint("CENTER", container, "CENTER")

    customizeScrollFrame:SetScrollChild(customizeFrame)

    local soonTM = customizeFrame:CreateFontString("$parentSoonTM", "OVERLAY", "GameFontNormal")
    soonTM:SetPoint("TOP", 0, -190)
    soonTM:SetText("Fully customizable frames coming in future updates")

    do
        local frameStyle = customizeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frameStyle:SetPoint("TOP", 0, 0)
        frameStyle:SetFont("Fonts\\FRIZQT__.TTF", 14)
        frameStyle:SetWidth(customizeFrame:GetWidth())
        frameStyle:SetJustifyH("CENTER")
        frameStyle:SetText("Choose Frame Style")
    end


    do
        frameDropdown = CreateFrame("Frame", "$parentFrameDropdown", customizeFrame, "UIDropDownMenuTemplate")
        frameDropdown:Show()
        frameDropdown:SetPoint("TOP", -60, -40)

        local label = customizeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("RIGHT", frameDropdown, "RIGHT", -40, 5)
        label:SetText("Select Frame")

        local targets = {"Party", "Pets", "Raid", "Raid Pets", "Target", "Focus"}
        local targetOptions = {}

        for _, target in ipairs(targets) do
            table.insert(targetOptions, {
                text = target,
                arg1 = target,
                func = function(targetArg)
                    UIDropDownMenu_SetSelectedName(frameDropdown, targetArg, false)
                    if profileDropdown then
                        -- Set the profile option. Why do you gotta do it like this? I don't know.
                        profileDropdown.selectedName = GetSelectedProfileName(targetArg)
                        UIDropDownMenu_SetText(GetSelectedProfileName(targetArg), profileDropdown)
                    end
                end
            })
        end

        UIDropDownMenu_Initialize(frameDropdown, function(self, level)
            for _, targetOption in ipairs(targetOptions) do
                targetOption.checked = false
                UIDropDownMenu_AddButton(targetOption)
            end
            if UIDropDownMenu_GetSelectedName(frameDropdown) == nil then
                UIDropDownMenu_SetSelectedName(frameDropdown, targets[1], false)
            end
        end)
    end


    do
        profileDropdown = CreateFrame("Frame", "$parentProfileDropdown", customizeFrame, "UIDropDownMenuTemplate")
        profileDropdown:Show()
        profileDropdown:SetPoint("TOP", -60, -70)

        local label = customizeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("RIGHT", profileDropdown, "RIGHT", -40, 5)
        label:SetText("Choose Style")

        local targets = util.ToArray(HMDefaultProfiles)
        util.RemoveElement(targets, "Base")
        table.sort(targets, function(a, b)
            return (HMProfileManager.DefaultProfileOrder[a] or 1000) < (HMProfileManager.DefaultProfileOrder[b] or 1000)
        end)
        local profileOptions = {}

        for _, target in ipairs(targets) do
            table.insert(profileOptions, {
                text = target,
                arg1 = target,
                func = function(targetArg)
                    UIDropDownMenu_SetSelectedName(profileDropdown, targetArg, false)
                    local selectedFrame = UIDropDownMenu_GetSelectedName(frameDropdown)
                    HMOptions.ChosenProfiles[selectedFrame] = targetArg

                    if selectedFrame == "Focus" and not util.IsSuperWowPresent() then
                        return
                    end

                    -- Here's some probably buggy profile hotswapping
                    local group = HealersMate.UnitFrameGroups[selectedFrame]
                    group.profile = GetSelectedProfile(selectedFrame)
                    local oldUIs = group.uis
                    group.uis = {}
                    group:ResetFrameLevel() -- Need to lower frame or the added UIs are somehow under it
                    for unit, ui in pairs(oldUIs) do
                        HealersMate.hmprint(unit)
                        ui:GetRootContainer():SetParent(nil)
                        -- Forget about the old UI, and cause a fat memory leak why not
                        ui:GetRootContainer():Hide()
                        local newUI = HMUnitFrame:New(unit, ui.isCustomUnit)
                        util.RemoveElement(HealersMate.AllUnitFrames, ui)
                        table.insert(HealersMate.AllUnitFrames, newUI)
                        local unitUIs = HealersMate.GetUnitFrames(unit)
                        util.RemoveElement(unitUIs, ui)
                        table.insert(unitUIs, newUI)
                        group:AddUI(newUI, true)
                        if ui.guidUnit then
                            newUI.guidUnit = ui.guidUnit
                        elseif unit ~= "target" then
                            newUI:Hide()
                        end
                    end
                    HealersMate.CheckGroup()
                    group:UpdateUIPositions()
                    group:ApplyProfile()
                end
            })
        end

        UIDropDownMenu_Initialize(profileDropdown, function(self, level)
            for _, targetOption in ipairs(profileOptions) do
                targetOption.checked = false
                UIDropDownMenu_AddButton(targetOption)
            end
            if UIDropDownMenu_GetSelectedName(profileDropdown) == nil then
                UIDropDownMenu_SetSelectedName(profileDropdown, 
                    GetSelectedProfileName(UIDropDownMenu_GetSelectedName(frameDropdown)), false)
            end
        end)
    end

    do
        local reloadNotify = customizeFrame:CreateFontString("$parentSoonTM", "OVERLAY", "GameFontNormal")
        reloadNotify:SetPoint("TOP", 0, -120)
        reloadNotify:SetText("Reload is recommended after changing UI styles")


        local reloadUI = CreateFrame("Button", "$parentReloadUIButton", customizeFrame, "UIPanelButtonTemplate")
        reloadUI:SetPoint("TOP", 0, -140)
        reloadUI:SetWidth(125)
        reloadUI:SetHeight(20)
        reloadUI:SetText("Reload UI")
        reloadUI:RegisterForClicks("LeftButtonUp")
        reloadUI:SetScript("OnClick", function()
            ReloadUI()
        end)
    end

    do
        local advanced = customizeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        advanced:SetPoint("TOP", 0, -240)
        advanced:SetFont("Fonts\\FRIZQT__.TTF", 14)
        advanced:SetWidth(customizeFrame:GetWidth())
        advanced:SetJustifyH("CENTER")
        advanced:SetText("Advanced Options")
    end

    do
        local explainer = customizeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        explainer:SetPoint("TOP", 0, -260)
        explainer:SetFont("Fonts\\FRIZQT__.TTF", 12)
        explainer:SetWidth(customizeFrame:GetWidth() * 0.85)
        explainer:SetJustifyH("CENTER")
        explainer:SetText("The Load Script runs after profiles are initialized, but before UIs are created, "..
            "making it good for editing profile attributes. GetProfile and CreateProfile are defined locals. "..
            "The Postload Script runs after everything is initialized. Reload is required for changes to take effect.")
    end

    do
        local editFrame = CreateFrame("Frame", "HMPreLoadScriptFrame", container)
        editFrame:SetWidth(325)
        editFrame:SetHeight(230)
        editFrame:SetPoint("CENTER", 0, 0)
        editFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
        editFrame:SetBackdropColor(0, 0, 0, 0.75)
        editFrame:SetPoint("LEFT", container, "RIGHT", 20, 0)
        editFrame:Hide()

        editFrame:EnableMouse(true)

        local scrollFrame = CreateFrame("ScrollFrame", "$parentCodeScrollFrame", editFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetWidth(300)
        scrollFrame:SetHeight(200)
        scrollFrame:SetPoint("TOPLEFT", 0, 0)

        local editBox = CreateFrame("EditBox", "$parentContent", scrollFrame)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        
        editBox:SetWidth(300)
        -- Stolen from SuperMacro
        editBox:SetScript("OnTextChanged", function()
            local scrollBar = getglobal(editBox:GetParent():GetName().."ScrollBar")
            editBox:GetParent():UpdateScrollChildRect();

            local _, max = scrollBar:GetMinMaxValues();
            scrollBar.prevMaxValue = scrollBar.prevMaxValue or max

            if math.abs(scrollBar.prevMaxValue - scrollBar:GetValue()) <= 1 then
                -- if scroll is down and add new line then move scroll
                scrollBar:SetValue(max);
            end
            if max ~= scrollBar.prevMaxValue then
                -- save max value
                scrollBar.prevMaxValue = max
            end
        end)
        editBox:SetScript("OnEscapePressed", function()
            editFrame:Hide()
        end)
        editBox:SetScript("OnEditFocusGained", function()
            this:SetText(HMOptions.Scripts[this.editScript])
        end)
        editBox:SetScript("OnEditFocusLost", function()
            if not this.editScript then
                return
            end
            HMOptions.Scripts[this.editScript] = this:GetText()
            editFrame:Hide()
        end)
        
        local editTargetLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        editTargetLabel:SetPoint("TOP", 0, -207)
        editTargetLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
        editTargetLabel:SetWidth(editFrame:GetWidth())
        editTargetLabel:SetJustifyH("CENTER")

        editBox.SetEditScript = function(self, scriptName)
            self.editScript = scriptName
            editTargetLabel:SetText(scriptName)
        end
        scrollFrame:SetScrollChild(editBox)

        do
            local ok = CreateFrame("Button", nil, editFrame, "UIPanelButtonTemplate")
            ok:SetPoint("TOP", -90, -205)
            ok:SetWidth(100)
            ok:SetHeight(20)
            ok:SetText("Save")
            ok:RegisterForClicks("LeftButtonUp")
            ok:SetScript("OnClick", function()
                editFrame:Hide()
            end)

            local cancel = CreateFrame("Button", nil, editFrame, "UIPanelButtonTemplate")
            cancel:SetPoint("TOP", 90, -205)
            cancel:SetWidth(100)
            cancel:SetHeight(20)
            cancel:SetText("Discard")
            cancel:RegisterForClicks("LeftButtonUp")
            cancel:SetScript("OnClick", function()
                editBox:SetEditScript(nil)
                editFrame:Hide()
            end)
        end

        do
            local openPreLoadScript = CreateFrame("Button", nil, customizeFrame, "UIPanelButtonTemplate")
            openPreLoadScript:SetPoint("TOP", 0, -340)
            openPreLoadScript:SetWidth(150)
            openPreLoadScript:SetHeight(20)
            openPreLoadScript:SetText("Edit Load Script")
            openPreLoadScript:RegisterForClicks("LeftButtonUp")
            openPreLoadScript:SetScript("OnClick", function()
                editBox:ClearFocus()
                editBox:SetEditScript("OnLoad")
                editFrame:Show()
                editBox:SetFocus()
            end)


            local postLoadScriptButton = CreateFrame("Button", nil, customizeFrame, "UIPanelButtonTemplate")
            postLoadScriptButton:SetPoint("TOP", 0, -365)
            postLoadScriptButton:SetWidth(150)
            postLoadScriptButton:SetHeight(20)
            postLoadScriptButton:SetText("Edit Postload Script")
            postLoadScriptButton:RegisterForClicks("LeftButtonUp")
            postLoadScriptButton:SetScript("OnClick", function()
                editBox:ClearFocus()
                editBox:SetEditScript("OnPostLoad")
                editFrame:Show()
                editBox:SetFocus()
            end)
        end
    end



    -- Settings Content Frames: About, Checkboxes, Spells, Scaling
    local AboutFrame = CreateFrame("Frame", "$parentAboutFrame", container)
    addFrame("About", AboutFrame)
    AboutFrame:SetWidth(250) -- width
    AboutFrame:SetHeight(380) -- height
    AboutFrame:SetPoint("CENTER", container, "CENTER")
    AboutFrame:Hide()

    local TxtAboutLabel = AboutFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    TxtAboutLabel:SetPoint("CENTER", AboutFrame, "CENTER", 0, 100)
    TxtAboutLabel:SetText("HealersMate Version "..HealersMate.VERSION..
    "\n\n\nOriginal Author: i2ichardt\nEmail: rj299@yahoo.com"..
    "\n\nMaintainer: OldManAlpha\nDiscord: oldmana\nTurtle IGN: Oldmana, Lowall, Jmdruid"..
    "\n\nContributers: Turtle WoW Community, ChatGPT"..
    "\n\n\nCheck For Updates, Report Issues, Make Suggestions:\n https://github.com/i2ichardt/HealersMate")

    --START--Combobox

        --What to do when an option is selected in the settings combobox
        local function ShowFrame(frameName)

            for name, frame in pairs(frames) do
                if name == frameName then
                    frame:Show()
                    if frameName == "Spells" then
                        populateSpellEditBoxes()
                    end
                else
                    frame:Hide()
                end
            end
        end

    local modifierDropdown = CreateFrame("Frame", "HM_ModifierDropdownList", spellsFrame, "UIDropDownMenuTemplate")
    --modifierDropdown:SetPoint("CENTER", keyLabel, "RIGHT", 10, -5)
    modifierDropdown:SetPoint("TOP", -35, -50)
    --modifierDropdown:SetWidth(120)
    --modifierDropdown:SetHeight(150)
    modifierDropdown:Show()

    local keyLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keyLabel:SetPoint("RIGHT", modifierDropdown, "RIGHT", -65, 5)
    keyLabel:SetText("Key")

    local modifiers = util.GetKeyModifiers()
    local orderedButtons = {"LeftButton", "MiddleButton", "RightButton", "Button4", "Button5"}
    local readableButtonMap = {
        ["LeftButton"] = "Left",
        ["MiddleButton"] = "Middle",
        ["RightButton"] = "Right",
        ["Button4"] = "Button 4",
        ["Button5"] = "Button 5"
    }

    local modifierOptions = {}

    for _, modifier in ipairs(modifiers) do
        table.insert(modifierOptions, {
            text = modifier,
            arg1 = modifier,
            func = function(modifierArg)
                saveSpellEditBoxes()
                UIDropDownMenu_SetSelectedName(modifierDropdown, modifierArg, false)
                populateSpellEditBoxes()
            end
        })
    end

    UIDropDownMenu_Initialize(modifierDropdown, function(self, level)
        for _, dropdownOption in ipairs(modifierOptions) do
            dropdownOption.checked = false
            UIDropDownMenu_AddButton(dropdownOption)
        end
        if UIDropDownMenu_GetSelectedName(modifierDropdown) == nil then
            UIDropDownMenu_SetSelectedName(modifierDropdown, modifiers[1], false)
        end
    end)

    targetDropdown = CreateFrame("Frame", "$parentTargetDropdown", spellsFrame, "UIDropDownMenuTemplate")
    targetDropdown:Show()
    targetDropdown:SetPoint("TOP", -35, 5)

    local spellsForLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellsForLabel:SetPoint("RIGHT", targetDropdown, "RIGHT", -65, 5)
    spellsForLabel:SetText("Spells For")

    local targets = {"Friendly", "Hostile"}
    local targetOptions = {}

    for _, target in ipairs(targets) do
        table.insert(targetOptions, {
            text = target,
            arg1 = target,
            func = function(targetArg)
                saveSpellEditBoxes()
                UIDropDownMenu_SetSelectedName(targetDropdown, targetArg, false)
                SpellsContext = EditedSpells[targetArg]
                populateSpellEditBoxes()
            end
        })
    end

    UIDropDownMenu_Initialize(targetDropdown, function(self, level)
        for _, targetOption in ipairs(targetOptions) do
            targetOption.checked = false
            UIDropDownMenu_AddButton(targetOption)
        end
        if UIDropDownMenu_GetSelectedName(targetDropdown) == nil then
            UIDropDownMenu_SetSelectedName(targetDropdown, targets[1], false)
        end
    end)


    -- START -- SpellsFrame Contents

    --Used as a reference point; to be able to move all the controls that reference it without having to go through and adjust each item
    local TopX = -5
    local TopY = -60

    local spellTextInterval = 25

    local spellTextBoxes = {}

    local function getSpellTextPos(pos)
        return TopY - (spellTextInterval * pos)
    end

    local function createSpellEditBox(button, pos)
        local txt = CreateFrame("EditBox", "Txt"..button, spellsFrame, "InputBoxTemplate")
        spellTextBoxes[button] = txt
        txt:SetPoint("TOP", TopX + 35, getSpellTextPos(pos))
        txt:SetWidth(200) -- width
        txt:SetHeight(30) -- height
        txt:SetAutoFocus(false)

        local txtLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txtLabel:SetPoint("RIGHT", txt, "LEFT", -10, 0)
        txtLabel:SetText(CustomButtonNames[button] or HealersMate.ReadableButtonMap[button])
    end

    for i, button in ipairs(CustomButtonOrder) do
        createSpellEditBox(button, i)
    end

    function populateSpellEditBoxes()
        local modifier = UIDropDownMenu_GetSelectedName(modifierDropdown)
        for button, txt in pairs(spellTextBoxes) do
            local spell = SpellsContext[modifier][button] or ""
            txt:SetText(spell)
        end
    end

    function saveSpellEditBoxes()
        local modifier = UIDropDownMenu_GetSelectedName(modifierDropdown)
        for button, txt in pairs(spellTextBoxes) do
            if txt:GetText() ~= "" then
                SpellsContext[modifier][button] = txt:GetText()
            else
                SpellsContext[modifier][button] = nil
            end
        end
    end

    local spellApplyButton = CreateFrame("Button", "SpellApplyButton", spellsFrame, "UIPanelButtonTemplate")
    spellApplyButton:SetPoint("TOP", 0, -230)
    spellApplyButton:SetWidth(125)
    spellApplyButton:SetHeight(20)
    spellApplyButton:SetText("Save & Close")
    spellApplyButton:RegisterForClicks("LeftButtonUp")
    spellApplyButton:SetScript("OnClick", function()
        saveSpellEditBoxes()
        for context, spells in pairs(EditedSpells) do
            local Spells = HMSpells[context]
            for modifier, buttons in pairs(spells) do
                Spells[modifier] = {}
                for button, spell in pairs(buttons) do
                    Spells[modifier][button] = spell
                end
            end
        end
        PlaySound("GAMESPELLBUTTONMOUSEDOWN")
        closeButton:GetScript("OnClick")()
    end)

    local spellApplyButtonNoClose = CreateFrame("Button", "SpellApplyButton", spellsFrame, "UIPanelButtonTemplate")
    spellApplyButtonNoClose:SetPoint("TOP", 140, -230)
    spellApplyButtonNoClose:SetWidth(125)
    spellApplyButtonNoClose:SetHeight(20)
    spellApplyButtonNoClose:SetText("Save Changes")
    spellApplyButtonNoClose:RegisterForClicks("LeftButtonUp")
    spellApplyButtonNoClose:SetScript("OnClick", function()
        saveSpellEditBoxes()
        for context, spells in pairs(EditedSpells) do
            local Spells = HMSpells[context]
            for modifier, buttons in pairs(spells) do
                Spells[modifier] = {}
                for button, spell in pairs(buttons) do
                    Spells[modifier][button] = spell
                end
            end
        end
        PlaySound("GAMESPELLBUTTONMOUSEDOWN")
    end)

    do
        local spellDiscardButton = CreateFrame("Button", "SpellApplyButton", spellsFrame, "UIPanelButtonTemplate")
        spellDiscardButton:SetPoint("TOP", -140, -230)
        spellDiscardButton:SetWidth(125)
        spellDiscardButton:SetHeight(20)
        spellDiscardButton:SetText("Discard Changes")
        spellDiscardButton:RegisterForClicks("LeftButtonUp")
        spellDiscardButton:SetScript("OnClick", function()
            resetSpells()
            populateSpellEditBoxes()
            PlaySound("GAMESPELLBUTTONMOUSEDOWN")
        end)
    end

    do
        local helpScrollFrame = CreateFrame("ScrollFrame", "$parentHelpScrollFrame", spellsFrame, "UIPanelScrollFrameTemplate")
        helpScrollFrame:SetWidth(400) -- width
        helpScrollFrame:SetHeight(175) -- height
        helpScrollFrame:SetPoint("TOPRIGHT", spellsFrame, "TOPRIGHT", -10, -260)

        local helpFrame = CreateFrame("Frame", "$parentHelpFrame", helpScrollFrame)
        helpFrame:SetWidth(400) -- width
        helpFrame:SetHeight(175) -- height

        helpScrollFrame:SetScrollChild(helpFrame)


        do
            local explainerHeader = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            explainerHeader:SetPoint("TOP", 0, 0)
            explainerHeader:SetFont("Fonts\\FRIZQT__.TTF", 14)
            explainerHeader:SetWidth(helpFrame:GetWidth() * 1)
            explainerHeader:SetJustifyH("CENTER")
            explainerHeader:SetText("Spell Binding Help & Info")

            local explainer = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            explainer:SetPoint("TOP", 0, -20)
            explainer:SetFont("Fonts\\FRIZQT__.TTF", 12)
            explainer:SetWidth(helpFrame:GetWidth() * 0.9)
            explainer:SetJustifyH("LEFT")
            local colorize = util.Colorize
            explainer:SetText(colorize("How to downrank: ", 1, 0.6, 0.6).."Input the name of the spell, suffixed by \"(Rank #)\""..
                ". For example, "..colorize("Lesser Heal(Rank 2)", 0.6, 1, 0.6).."\n\n"..
            colorize("Special Bindings:", 1, 0.6, 0.6).."\n"..
            colorize("Target", 0.6, 0.6, 1).." - ".."Sets your target\n"..
            colorize("Assist", 0.6, 0.6, 1).." - ".."Sets your target as the unit's target\n"..
            colorize("Role", 0.6, 0.6, 1).." - ".."Choose the role of the player\n"..
            colorize("Context", 0.6, 0.6, 1).." - ".."Open the right-click context menu\n"..
            colorize("Follow", 0.6, 0.6, 1).." - ".."Follow a player\n"..
            colorize("Focus", 0.6, 0.6, 1)..colorize(" (SuperWoW Required)", 1, 0.8, 0.8).." - ".."Add/remove a unit to your focus\n"..
            colorize("Promote Focus", 0.6, 0.6, 1)..colorize(" (SuperWoW Required)", 1, 0.8, 0.8).." - "..
                "Moves the focus to the top\n\n"..
            colorize("Binding Items: ", 1, 0.6, 0.6).."Prefix \"Item: \" to indicate that you're binding an item in your bags."..
                " For example, "..colorize("Item: Silk Bandage", 0.6, 1, 0.6).."\n\n"..
            colorize("Binding Macros: ", 1, 0.6, 0.6).."Prefix \"Macro: \" to indicate that you're binding a macro. For example, "..
                colorize("Macro: Summon", 0.6, 1, 0.6).."\n\n"..
            colorize("Information on Macros: ", 1, 0.6, 0.6).."When clicking on a unit with macro binds, you will automatically"..
                " target them for a split second, allowing you to use the \"target\" unit in your macros. Additionally, the "..
                "global \"HM_MacroTarget\" is exposed, allowing you to see the actual unit that was clicked, such as "..
                "\"party1\". Beware that clicking on a focus will produce fake units, such as \"focus1\".")
        end
    end

    local lastTab
    for tabIndex, name in ipairs(frameNames) do
        local tab = CreateFrame("Button", "$parentTab"..tabIndex, container, "CharacterFrameTabButtonTemplate")
        if lastTab == nil then
            tab:SetPoint("BOTTOM", container, "BOTTOMLEFT", 30, -36)
        else
            tab:SetPoint("LEFT", lastTab, "RIGHT", -10, 0)
        end
        tab:SetText(name)
        tab:RegisterForClicks("LeftButtonUp")

        -- The locals declared in the for loop aren't good enough for the script apparently..
        local tabIndex = tabIndex
        local name = name
        tab:SetScript("OnClick", function()
            PanelTemplates_SetTab(container, tabIndex);
            ShowFrame(name)
            PlaySoundFile("Sound\\Interface\\uCharacterSheetTab.wav")
        end)
        lastTab = tab
    end

    PanelTemplates_SetNumTabs(container, table.getn(frameNames))  -- 2 because there are 2 frames total.
    PanelTemplates_SetTab(container, 1)      -- 1 because we want tab 1 selected.

    local oldContainerShow = container.Show
    container.Show = function(self)
        PanelTemplates_SetTab(container, 1)
        ShowFrame("Spells")
        oldContainerShow(self)
    end
end
