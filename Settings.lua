HealersMateSettings = {}

HealersMateSettings.Profiles = {}
HealersMateSettings.ProfileOptions = {}

local Util = getglobal("HMUtil")

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
    trackedDebuffTypes = Util.ToArray(trackedDebuffTypes)

    for _, profile in pairs(HealersMateSettings.Profiles) do
        profile.TrackedDebuffTypes = trackedDebuffTypes
    end
end

function HealersMateSettings.InitProfiles()
    local defaultTrackedBuffs = {"First Aid", "Blessing of Protection", "Divine Protection", "Divine Shield", 
    "Divine Intervention", "Power Infusion", "Spirit of Redemption", "Shield Wall", "Soulstone Resurrection", 
    "Feign Death", "Mend Pet", "Innervate", "Quel'dorei Meditation"}
    local defaultClassTrackedBuffs = {
        ["PALADIN"] = {"Blessing of Wisdom", "Blessing of Might", "Blessing of Salvation", "Blessing of Sanctuary", 
            "Blessing of Kings", "Blessing of Freedom", "Greater Blessing of Wisdom", "Greater Blessing of Might", 
            "Greater Blssing of Salvation", "Greater Blessing of Sanctuary", "Greater Blessing of Kings", 
            "Holy Shield", "Redoubt"},
        ["PRIEST"] = {"Power Word: Fortitude", "Divine Spirit", "Shadow Protection", "Power Word: Shield", "Renew", 
            "Inspiration", "Abolish Disease", "Fear Ward", "Fade", "Inner Fire", "Spirit Tap"},
        ["DRUID"] = {"Mark of the Wild", "Thorns", "Rejuvenation", "Regrowth"}
    }
    for _, class in ipairs(Util.Classes) do
        defaultClassTrackedBuffs[class] = Util.ToSet(defaultClassTrackedBuffs[class] or {})
        for _, buff in ipairs(defaultTrackedBuffs) do
            defaultClassTrackedBuffs[class][buff] = 1
        end
    end

    local defaultTrackedDebuffs = {"Recently Bandaged", "Forbearance", "Resurrection Sickness", "Ghost"}
    local defaultClassTrackedDebuffs = {
        ["PRIEST"] = {"Weakened Soul"}
    }
    for _, class in ipairs(Util.Classes) do
        defaultClassTrackedDebuffs[class] = Util.ToSet(defaultClassTrackedDebuffs[class] or {})
        for _, debuff in ipairs(defaultTrackedDebuffs) do
            defaultClassTrackedDebuffs[class][debuff] = 1
        end
    end

    local options = HealersMateSettings.ProfileOptions
    local profiles = HealersMateSettings.Profiles

    do
        local function createTextObject(predefined)
            local text = {}
            text.FontSize = 12
            text.AlignmentH = "CENTER" -- LEFT, CENTER, RIGHT
            text.AlignmentV = "CENTER" -- TOP, CENTER, BOTTOM
            text.PaddingH = 4
            text.PaddingV = 4
            text.OffsetX = 0
            text.OffsetY = 0
            text.Color = "Default" -- Default, Class, Array(Custom Color)
            text.GetPaddingH = function(self)
                if self.AlignmentH == "LEFT" then
                    return self.PaddingH
                elseif self.AlignmentH == "RIGHT" then
                    return -self.PaddingH
                end
                return 0
            end
            text.GetPaddingV = function(self)
                if self.AlignmentV == "TOP" then
                    return -self.PaddingV
                elseif self.AlignmentH == "BOTTOM" then
                    return self.PaddingV
                end
                return 0
            end
            if predefined then
                for key, value in pairs(predefined) do
                    text[key] = value
                end
            end
            return text
        end

        profiles["Party"] = {}
        local profile = profiles["Party"]
        profile.Width = 150 -- Default: 150
        profile.HealthBarHeight = 24 -- Default: 20
        profile.HealthBarColor = "Green To Red" -- Class, Green, Green To Red
        options.HealthBarColor = {"Class", "Green", "Green To Red"}
        profile.HealthText = createTextObject({
            ["FontSize"] = 12,
            ["AlignmentH"] = "RIGHT"
        })
        profile.HealthDisplay = "Health"
        options.HealthDisplay = {"Health", "Health/Max Health", "% Health", "Hidden"}
        profile.MissingHealthDisplay = "-Health"
        options.MissingHealthDisplay = {"Hidden", "-Health", "-% Health"}
        profile.AlwaysShowMissingHealth = false
        profile.ShowEnemyMissingHealth = false

        profile.AlertPercent = 100

        profile.PowerBarHeight = 12 -- Default: 10
        profile.PowerText = createTextObject({
            ["FontSize"] = 10,
            ["AlignmentH"] = "RIGHT"
        })
        profile.PowerDisplay = "Power"
        options.PowerDisplay = {"Power", "Power/Max Power", "% Power", "Hidden"}

        profile.NameInHealthBar = true -- Default: true
        profile.NameText = createTextObject({
            ["FontSize"] = 12,
            ["AlignmentH"] = "LEFT",
            ["Color"] = "Class"
        })
        profile.NameDisplay = "Name" -- Unimplemented
        options.NameDisplay = {"Name", "Name (Class)"}

        profile.TrackAuras = true -- Default: true
        profile.TrackedAurasHeight = 20
        profile.TrackedAurasSpacing = 2
        profile.TrackedBuffs = defaultClassTrackedBuffs[playerClass] -- Default tracked is variable based on class
        profile.TrackedDebuffs = defaultClassTrackedDebuffs[playerClass] -- Default tracked is variable based on class
        profile.TrackedDebuffTypes = {} -- Default tracked is variable based on class
        options.TrackedDebuffTypes = {"Poison", "Disease", "Magic", "Curse"}
        profile.TrackedDebuffTypesSet = Util.ToSet(profile.TrackedDebuffTypes)

        profile.MaxUnitsInAxis = 5
        profile.Orientation = "Vertical"
        options.Orientation = {"Vertical", "Horizontal"}
        profile.PaddingBetweenUnits = 2 -- Unimplemented

        profile.SortUnitsBy = "ID"
        options.SortUnitsBy = {"ID", "Name", "Class Name"}
        profile.SplitRaidIntoGroups = true

        profile.BorderStyle = "Tooltip"
        options.BorderStyle = {"Tooltip", "Dialog Box", "Borderless"}

        profile.GetHeight = function(self)
            local totalHeight = self.HealthBarHeight + self.PowerBarHeight + self.TrackedAurasHeight
            if not self.NameInHealthBar then
                totalHeight = totalHeight + (self.NameText.FontSize * 1.25)
            end
            return totalHeight
        end
    end

    profiles["Pets"] = HMUtil.CloneTable(profiles["Party"], true)
    profiles["Raid"] = HMUtil.CloneTable(profiles["Party"], true)
    profiles["Raid Pets"] = HMUtil.CloneTable(profiles["Party"], true)
    profiles["Target"] = HMUtil.CloneTable(profiles["Party"], true)

    do
        local profile = profiles["Pets"]
        profile.Width = 120
        profile.HealthBarHeight = 16
        profile.PowerBarHeight = 9
        profile.TrackedAurasHeight = 16
        profile.NameTextFontSize = 10
        profile.HealthTextFontSize = 10
        profile.PowerBarTextFontSize = 9
    end

    do
        local profile = profiles["Raid"]
        profile.Width = 80
        profile.NameInHealthBar = true
        profile.HealthBarHeight = 16
        profile.HealthBarColor = "Class"
        profile.NameText.FontSize = 8
        profile.NameText.AlignmentH = "LEFT"
        profile.NameText.Color = "Default"
        profile.PowerBarHeight = 6
        profile.TrackedAurasHeight = 10
        profile.HealthText.FontSize = 9
        profile.HealthText.AlignmentH = "RIGHT"
        profile.HealthDisplay = "% Health"
        profile.MissingHealthDisplay = "Hidden"
        profile.PowerDisplay = "Hidden"
        profile.PowerText.FontSize = 8
        profile.Orientation = "Vertical"
        profile.SplitRaidIntoGroups = true
        profile.SortUnitsBy = "ID"
        profile.AlertPercent = 99

        profiles["Raid Pets"] = HMUtil.CloneTable(profile, true)
    end

    do
        local profile = profiles["Raid Pets"]
    end

    --profiles["Target"].BorderStyle = "Dialog Box"
    profiles["Party"].MaxUnitsInAxis = 5

    do
        local profile = HMUtil.CloneTable(profiles["Party"], true)
        profiles["Legacy"] = profile

        profile.Width = 200
        profile.NameInHealthBar = false
        profile.HealthBarHeight = 25
        profile.PowerBarHeight = 5

        profile.NameText.AlignmentH = "LEFT"
        profile.HealthText.AlignmentH = "CENTER"
        profile.HealthDisplay = "Health/Max Health"
        profile.PowerDisplay = "Hidden"

        --profiles["Party"] = profile
    end

    do
        local profile = profiles["Target"]
    end

    HealersMateSettings.UpdateTrackedDebuffTypes()
end

-- Non-profile settings

function HealersMateSettings.SetDefaults()
    if not HMOptions then
        HMOptions = {}
    end
    
    do
        local defaults = {
            ["ShowTargets"] = {
                ["Friendly"] = true,
                ["Hostile"] = false
            },
            ["OptionsVersion"] = 1
        }
    
        for field, value in pairs(defaults) do
            if not HMOptions[field] then
                if type(value) == "table" then
                    HMOptions[field] = HMUtil.CloneTable(value, true)
                else
                    HMOptions[field] = value
                end
            end
        end
    end
end

ShowEmptySpells = true
IgnoredEmptySpells = {--[["MiddleButton"]]}
IgnoredEmptySpells = Util.ToSet(IgnoredEmptySpells)
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


-- This file needs serious cleaning and refactoring

setmetatable(HealersMateSettings, {__index = getfenv(1)})
setfenv(1, HealersMateSettings)


function HealersMateSettings.InitSettings()
    --Used too set custom tooltip information when you mouse over things; like in the settings checkboxes
    local MyTooltip = CreateFrame("GameTooltip", "HMSettingsInfoTooltip", UIParent, "GameTooltipTemplate")

    --Fucntion that is called to set the text of a custom tooltip and where to display it.
    local function ShowTooltip(AttachTo, TooltipText1, TooltipText2)
        MyTooltip:SetOwner(AttachTo, "ANCHOR_RIGHT")
        MyTooltip:SetPoint("RIGHT", AttachTo, "LEFT", 0, 0)
            
        MyTooltip:AddLine(TooltipText1, 1, 1, 1) -- White text color
        
        if TooltipText2 ~= "" then
            MyTooltip:AddLine(TooltipText2, 1, 1, 1) -- White text color
        end
            
        HMSettingsInfoTooltipTextLeft1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        HMSettingsInfoTooltipTextLeft2:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        
        MyTooltip:Show()
    end

    --Used to hide custom tooltips
    local function HideTooltip()
        MyTooltip:Hide()
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
        SpellsCopy = {}
        for modifier, buttons in pairs(HealersMate.GetSpells()) do
            SpellsCopy[modifier] = {}
            for button, spell in pairs(buttons) do
                SpellsCopy[modifier][button] = spell
            end
        end
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
    CheckboxShowTargetLabel:SetPoint("CENTER", optionsFrame, "TOPLEFT", 0, -25)
    CheckboxShowTargetLabel:SetText("Show Targets:")

    -- Label for the "Friendly" checkbox
    local CheckboxFriendlyLabel = optionsFrame:CreateFontString("CheckboxFriendlyLabel", "OVERLAY", "GameFontNormal")
    CheckboxFriendlyLabel:SetPoint("LEFT", CheckboxShowTargetLabel, "RIGHT", 50, 0)
    CheckboxFriendlyLabel:SetText("Friendly")

    -- Create the "Friendly" checkbox
    local CheckboxFriendly = CreateFrame("CheckButton", "$parentTargetFriendly", optionsFrame, "UICheckButtonTemplate")
    CheckboxFriendly:SetPoint("LEFT", CheckboxFriendlyLabel, "RIGHT", 0, 0)
    CheckboxFriendly:SetWidth(20) -- width
    CheckboxFriendly:SetHeight(20) -- height
    CheckboxFriendly:SetChecked(HMOptions.ShowTargets.Friendly)
    CheckboxFriendly:SetScript("OnClick", function()
        HMOptions.ShowTargets.Friendly = CheckboxFriendly:GetChecked() == 1
    end)

    -- Label for the "Enemy" checkbox
    local CheckboxEnemyLabel = optionsFrame:CreateFontString("CheckboxEnemyLabel", "OVERLAY", "GameFontNormal")
    CheckboxEnemyLabel:SetPoint("LEFT", CheckboxFriendly, "RIGHT", 10, 0)
    CheckboxEnemyLabel:SetText("Hostile")

    -- Create the "Enemy" checkbox
    local CheckboxHostile = CreateFrame("CheckButton", "$parentTargetHostile", optionsFrame, "UICheckButtonTemplate")
    CheckboxHostile:SetPoint("LEFT", CheckboxEnemyLabel, "RIGHT", 0, 0)
    CheckboxHostile:SetWidth(20) -- width
    CheckboxHostile:SetHeight(20) -- height
    CheckboxHostile:SetChecked(HMOptions.ShowTargets.Hostile)
    CheckboxHostile:SetScript("OnClick", function()
        HMOptions.ShowTargets.Hostile = CheckboxHostile:GetChecked() == 1
    end)


    local soonTM = optionsFrame:CreateFontString("$parentSoonTM", "OVERLAY", "GameFontNormal")
    soonTM:SetPoint("CENTER", optionsFrame, "CENTER", 0, 0)
    soonTM:SetText("More options coming in future updates")




    local customizeFrame = CreateFrame("Frame", "$parentOptionsFrame", container)
    addFrame("Customize", customizeFrame)
    customizeFrame:SetWidth(250) -- width
    customizeFrame:SetHeight(380) -- height
    customizeFrame:SetPoint("CENTER", container, "CENTER")
    customizeFrame:Hide() -- Initially hidden

    local soonTM = customizeFrame:CreateFontString("$parentSoonTM", "OVERLAY", "GameFontNormal")
    soonTM:SetPoint("CENTER", optionsFrame, "CENTER", 0, 0)
    soonTM:SetText("Customization coming in future updates")



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
    "\n\nMaintainer: OldManAlpha\nDiscord: oldmana\nTurtle IGN: Oldmana"..
    "\n\nContributer: ChatGPT"..
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

    local txtLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txtLabel:SetPoint("TOPLEFT", 85, -80)
    txtLabel:SetText("Key: ")

    local modifierDropdown = CreateFrame("Frame", "HM_ModifierDropdownList", spellsFrame, "UIDropDownMenuTemplate")
    modifierDropdown:SetPoint("CENTER", txtLabel, "RIGHT", 10, -5)
    --modifierDropdown:SetWidth(120)
    --modifierDropdown:SetHeight(150)
    modifierDropdown:Show()

    local modifiers = {"None", "Shift", "Control", "Alt"}
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


    -- START -- SpellsFrame Contents

    --Used as a reference point; to be able to move all the controls that reference it without having to go through and adjust each item
    local TopX = -5
    local TopY = -90

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
        txtLabel:SetText(readableButtonMap[button]..":")
    end

    for i, button in ipairs(orderedButtons) do
        createSpellEditBox(button, i)
    end

    function populateSpellEditBoxes()
        local modifier = UIDropDownMenu_GetSelectedName(modifierDropdown)
        for button, txt in pairs(spellTextBoxes) do
            local spell = SpellsCopy[modifier][button] or ""
            txt:SetText(spell)
        end
    end

    function saveSpellEditBoxes()
        local modifier = UIDropDownMenu_GetSelectedName(modifierDropdown)
        for button, txt in pairs(spellTextBoxes) do
            if txt:GetText() ~= "" then
                SpellsCopy[modifier][button] = txt:GetText()
            else
                SpellsCopy[modifier][button] = nil
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
        for modifier, buttons in pairs(SpellsCopy) do
            local Spells = HealersMate.GetSpells()
            Spells[modifier] = {}
            for button, spell in pairs(buttons) do
                Spells[modifier][button] = spell
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

    container:Hide()
end