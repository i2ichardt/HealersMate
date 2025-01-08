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
                ["ShowManaPercentCost"] = true
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
            ["Focus"] = {
                ["ClearNonPlayerOnDeath"] = true
            },
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
            ["OptionsVersion"] = 1
        }
    
        for field, value in pairs(defaults) do
            if HMOptions[field] == nil then
                if type(value) == "table" then
                    HMOptions[field] = HMUtil.CloneTable(value, true)
                else
                    HMOptions[field] = value
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
        "Shield Wall", "Recklessness", -- Warrior
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
    containerBorder:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",       edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 }, tile = true, tileSize = 32})

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
    spellsFrame:SetHeight(365)
    spellsFrame:SetPoint("CENTER", container, "CENTER")
    local spellsFrameOldShow = spellsFrame.Show
    spellsFrame.Show = function(self)
        spellsFrameOldShow(self)
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
    spellsFrame:Hide()

    local optionsFrame = CreateFrame("Frame", "$parentOptionsFrame", container)
    addFrame("Options", optionsFrame)
    optionsFrame:SetWidth(250) -- width
    optionsFrame:SetHeight(380) -- height
    optionsFrame:SetPoint("CENTER", container, "CENTER")
    optionsFrame:Hide() -- Initially hidden

    -- Label for the checkbox
    local CheckboxShowTargetLabel = optionsFrame:CreateFontString("CheckboxShowTargetLabel", "OVERLAY", "GameFontNormal")
    CheckboxShowTargetLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", 50, -20)
    CheckboxShowTargetLabel:SetText("Show Targets:")

    -- Label for the "Friendly" checkbox
    local CheckboxFriendlyLabel = optionsFrame:CreateFontString("CheckboxFriendlyLabel", "OVERLAY", "GameFontNormal")
    CheckboxFriendlyLabel:SetPoint("LEFT", CheckboxShowTargetLabel, "RIGHT", 20, 0)
    CheckboxFriendlyLabel:SetText("Friendly")

    -- Create the "Friendly" checkbox
    local CheckboxFriendly = CreateFrame("CheckButton", "$parentTargetFriendly", optionsFrame, "UICheckButtonTemplate")
    CheckboxFriendly:SetPoint("LEFT", CheckboxFriendlyLabel, "RIGHT", 5, -2)
    CheckboxFriendly:SetWidth(20) -- width
    CheckboxFriendly:SetHeight(20) -- height
    CheckboxFriendly:SetChecked(HMOptions.ShowTargets.Friendly)
    CheckboxFriendly:SetScript("OnClick", function()
        HMOptions.ShowTargets.Friendly = CheckboxFriendly:GetChecked() == 1
    end)
    ApplyTooltip(CheckboxFriendly, "Show friendly targets in the Target frame")

    -- Label for the "Enemy" checkbox
    local CheckboxEnemyLabel = optionsFrame:CreateFontString("CheckboxEnemyLabel", "OVERLAY", "GameFontNormal")
    CheckboxEnemyLabel:SetPoint("LEFT", CheckboxFriendly, "RIGHT", 10, 0)
    CheckboxEnemyLabel:SetText("Hostile")

    -- Create the "Enemy" checkbox
    local CheckboxHostile = CreateFrame("CheckButton", "$parentTargetHostile", optionsFrame, "UICheckButtonTemplate")
    CheckboxHostile:SetPoint("LEFT", CheckboxEnemyLabel, "RIGHT", 5, -2)
    CheckboxHostile:SetWidth(20) -- width
    CheckboxHostile:SetHeight(20) -- height
    CheckboxHostile:SetChecked(HMOptions.ShowTargets.Hostile)
    CheckboxHostile:SetScript("OnClick", function()
        HMOptions.ShowTargets.Hostile = CheckboxHostile:GetChecked() == 1
    end)
    ApplyTooltip(CheckboxHostile, "Show hostile targets in the Target frame")

    local CheckboxAutoTargetLabel = optionsFrame:CreateFontString("CheckboxAutoTargetLabel", "OVERLAY", "GameFontNormal")
    CheckboxAutoTargetLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", 50, -50)
    CheckboxAutoTargetLabel:SetText("Auto Target")

    local CheckboxAutoTarget = CreateFrame("CheckButton", "$parentAutoTarget", optionsFrame, "UICheckButtonTemplate")
    CheckboxAutoTarget:SetPoint("LEFT", CheckboxAutoTargetLabel, "RIGHT", 5, -2)
    CheckboxAutoTarget:SetWidth(20) -- width
    CheckboxAutoTarget:SetHeight(20) -- height
    CheckboxAutoTarget:SetChecked(HMOptions.AutoTarget)
    CheckboxAutoTarget:SetScript("OnClick", function()
        HMOptions.AutoTarget = CheckboxAutoTarget:GetChecked() == 1
    end)
    ApplyTooltip(CheckboxAutoTarget, "If enabled, casting a spell on a player will also cause you to target them")

    do
        local CheckboxShowSpellsTooltipLabel = optionsFrame:CreateFontString("CheckboxShowSpellsTooltipLabel", "OVERLAY", "GameFontNormal")
        CheckboxShowSpellsTooltipLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", 50, -80)
        CheckboxShowSpellsTooltipLabel:SetText("Show Spells Tooltip")

        local CheckboxShowSpellsTooltip = CreateFrame("CheckButton", "$parentShowSpellsTooltip", optionsFrame, "UICheckButtonTemplate")
        CheckboxShowSpellsTooltip:SetPoint("LEFT", CheckboxShowSpellsTooltipLabel, "RIGHT", 5, -2)
        CheckboxShowSpellsTooltip:SetWidth(20) -- width
        CheckboxShowSpellsTooltip:SetHeight(20) -- height
        CheckboxShowSpellsTooltip:SetChecked(HMOptions.ShowSpellsTooltip)
        CheckboxShowSpellsTooltip:SetScript("OnClick", function()
            HMOptions.ShowSpellsTooltip = CheckboxShowSpellsTooltip:GetChecked() == 1
        end)
        ApplyTooltip(CheckboxShowSpellsTooltip, "Show the spells tooltip when hovering over frames")
    end

    do
        local castWhenDropdown = CreateFrame("Frame", "$parentCastWhenDropdown", optionsFrame, "UIDropDownMenuTemplate")
        castWhenDropdown:Show()
        castWhenDropdown:SetPoint("TOP", -65, -100)

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

    do
        local CheckboxMoveAllLabel = optionsFrame:CreateFontString("$parentMoveAllLabel", "OVERLAY", "GameFontNormal")
        CheckboxMoveAllLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", 50, -140)
        CheckboxMoveAllLabel:SetText("Drag All Frames")

        local CheckboxMoveAll = CreateFrame("CheckButton", "$parentMoveAll", optionsFrame, "UICheckButtonTemplate")
        CheckboxMoveAll:SetPoint("LEFT", CheckboxMoveAllLabel, "RIGHT", 5, -2)
        CheckboxMoveAll:SetWidth(20)
        CheckboxMoveAll:SetHeight(20)
        CheckboxMoveAll:SetChecked(HMOptions.FrameDrag.MoveAll)
        CheckboxMoveAll:SetScript("OnClick", function()
            HMOptions.FrameDrag.MoveAll = CheckboxMoveAll:GetChecked() == 1
        end)
        ApplyTooltip(CheckboxMoveAll, "If enabled, all frames will be moved when dragging", "Use the inverse key to move a single frame; Opposite effect if disabled")



        local inverseKeyDropdown = CreateFrame("Frame", "$parentMoveAllInverseKeyDropdown", optionsFrame, "UIDropDownMenuTemplate")
        inverseKeyDropdown:Show()
        inverseKeyDropdown:SetPoint("TOP", 40, -130)

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

    local superwow = util.IsSuperWowPresent()
    do
        local SuperWoWLabel = optionsFrame:CreateFontString("$parentSuperWoWLabel", "OVERLAY", "GameFontNormal")
        SuperWoWLabel:SetPoint("CENTER", 0, -10)
        SuperWoWLabel:SetText("SuperWoW Required Settings")

        local SuperWoWDetectedLabel = optionsFrame:CreateFontString("$parentSuperWoWDetectedLabel", "OVERLAY", "GameFontNormal")
        SuperWoWDetectedLabel:SetPoint("CENTER", 0, -25)
        SuperWoWDetectedLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        SuperWoWDetectedLabel:SetText(superwow and util.Colorize("SuperWoW Detected", 0.5, 1, 0.5) or 
            util.Colorize("SuperWoW Not Detected", 1, 0.6, 0.6))
    end

    do
        local CheckboxHealPredictLabel = optionsFrame:CreateFontString("$parentHealPredictionsLabel", "OVERLAY", "GameFontNormal")
        CheckboxHealPredictLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", 50, -245)
        CheckboxHealPredictLabel:SetText("Use Heal Predictions")

        local CheckboxHealPredict = CreateFrame("CheckButton", "$parentHealPredictions", optionsFrame, "UICheckButtonTemplate")
        CheckboxHealPredict:SetPoint("LEFT", CheckboxHealPredictLabel, "RIGHT", 5, -2)
        CheckboxHealPredict:SetWidth(20)
        CheckboxHealPredict:SetHeight(20)
        CheckboxHealPredict:SetChecked(HMOptions.UseHealPredictions)
        if not superwow then
            CheckboxHealPredict:Disable()
        end
        CheckboxHealPredict:SetScript("OnClick", function()
            HMOptions.UseHealPredictions = CheckboxHealPredict:GetChecked() == 1
            HealersMate.UpdateAllIncomingHealing()
        end)
        ApplyTooltip(CheckboxHealPredict, "Requires SuperWoW Mod To Work", 
            "If enabled, you will see predictions on incoming healing")
    end

    do
        local CheckboxMouseoverLabel = optionsFrame:CreateFontString("$parentMouseoverLabel", "OVERLAY", "GameFontNormal")
        CheckboxMouseoverLabel:SetPoint("RIGHT", optionsFrame, "TOPLEFT", 50, -275)
        CheckboxMouseoverLabel:SetText("Set Mouseover")

        local CheckboxMouseover = CreateFrame("CheckButton", "$parentMouseover", optionsFrame, "UICheckButtonTemplate")
        CheckboxMouseover:SetPoint("LEFT", CheckboxMouseoverLabel, "RIGHT", 5, -2)
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
    customizeScrollFrame:SetWidth(370) -- width
    customizeScrollFrame:SetHeight(380) -- height
    customizeScrollFrame:SetPoint("CENTER", container, "CENTER")
    customizeScrollFrame:Hide() -- Initially hidden

    local customizeFrame = CreateFrame("Frame", "$parentContent", customizeScrollFrame)
    addFrame("Customize", customizeScrollFrame)
    customizeFrame:SetWidth(370 + 20) -- width
    customizeFrame:SetHeight(360) -- height
    customizeFrame:SetPoint("CENTER", container, "CENTER")

    customizeScrollFrame:SetScrollChild(customizeFrame)

    local soonTM = customizeFrame:CreateFontString("$parentSoonTM", "OVERLAY", "GameFontNormal")
    soonTM:SetPoint("CENTER", customizeFrame, "CENTER", 0, 0)
    soonTM:SetText("Fully customizable frames coming in future updates")



    do
        frameDropdown = CreateFrame("Frame", "$parentFrameDropdown", customizeFrame, "UIDropDownMenuTemplate")
        frameDropdown:Show()
        frameDropdown:SetPoint("TOP", -60, 0)

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
        profileDropdown:SetPoint("TOP", -60, -30)

        local label = customizeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("RIGHT", profileDropdown, "RIGHT", -40, 5)
        label:SetText("Choose Style")

        local targets = util.ToArray(HMDefaultProfiles)
        util.RemoveElement(targets, "Base")
        table.sort(targets, function(a, b)
            return (HMProfileManager.DefaultProfileOrder[a] or 1000) < (HMProfileManager.DefaultProfileOrder[b] or 1000)
        end)
        profileOptions = {}

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
        reloadNotify:SetPoint("TOP", 0, -80)
        reloadNotify:SetText("Reload is recommended after changing UI styles")


        local reloadUI = CreateFrame("Button", "$parentReloadUIButton", customizeFrame, "UIPanelButtonTemplate")
        reloadUI:SetPoint("TOP", 0, -100)
        reloadUI:SetWidth(125)
        reloadUI:SetHeight(20)
        reloadUI:SetText("Reload UI")
        reloadUI:RegisterForClicks("LeftButtonUp")
        reloadUI:SetScript("OnClick", function()
            ReloadUI()
        end)
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
    spellApplyButton:SetPoint("BOTTOM", 0, 10)
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
        closeButton:GetScript("OnClick")()
    end)

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
