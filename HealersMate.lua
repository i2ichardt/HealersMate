--Notes:
--1) use tostring(arg1), arg2, arg3, arg4 etc to see what data a function uses/returns
		--DEFAULT_CHAT_FRAME:AddMessage("arg1: " .. tostring(arg1))
		--DEFAULT_CHAT_FRAME:AddMessage("arg2: " .. tostring(arg2))
		--DEFAULT_CHAT_FRAME:AddMessage("arg3: " .. tostring(arg3))
		--DEFAULT_CHAT_FRAME:AddMessage("arg4: " .. tostring(arg4))
		--DEFAULT_CHAT_FRAME:AddMessage("arg5: " .. tostring(arg5))
		--DEFAULT_CHAT_FRAME:AddMessage("arg6: " .. tostring(arg6))
		--DEFAULT_CHAT_FRAME:AddMessage("arg7: " .. tostring(arg7))
		--DEFAULT_CHAT_FRAME:AddMessage("arg8: " .. tostring(arg8))
		--DEFAULT_CHAT_FRAME:AddMessage("arg9: " .. tostring(arg9))
		--DEFAULT_CHAT_FRAME:AddMessage("arg10: " .. tostring(arg10))
		--Debug( "[arg1 = " .. tostring(arg1).. "]" .. "[arg2 = " .. tostring(arg2).. "]" .. "[arg3 = " .. tostring(arg3).. "]")
		
--2) The order in which things appear in the .lua file is very important if you try to reference something
-- that doesn't appear until later in the code you will get errors.

--3) Access elements using strings as indices
--Debug(myArray["player"])  -- Output: Some data for player
--Debug(myArray["party1"])  -- Output: Some data for party1
--Debug(myArray["party2"])  -- Output: Some data for party2



--4)##Saved Variables:##
--Note: Saves variables are specified in the .toc file

--[the following variables are saved PER character, not account]
--FreshInstall --Tracks if the addon has been started before for the active character

--LeftClickSpell : Stores a spellname as text "lesser heal"
--MiddleClickSpell : Stores a spellname as text "lesser heal"
--RightClickSpell : Stores a spellname as text "lesser heal"

--ShiftLeftClickSpell : Stores a spellname as text "lesser heal"
--ShiftMiddleClickSpell : Stores a spellname as text "lesser heal"
--ShiftRightClickSpell : Stores a spellname as text "lesser heal"

--ControlLeftClickSpell : Stores a spellname as text "lesser heal"
--ControlMiddleClickSpell : Stores a spellname as text "lesser heal"
--ControlRightClickSpell : Stores a spellname as text "lesser heal"

--ShowTargetUI : Used to determine if any target should be visible
--ShowTargetFriendly : Used to determine if the Target UI should be visible when the target is an friendly
--ShowTargetEnemy : Used to determine if the Target UI should be visible when the target is an enemy
--ShowMinusValue : Used to determine if the health deficit should be shown as "-50"
--ShowPercentageHealth: Used to determine if the health deficit should be shown as "%98"
--ShowScrollingText : Used to determine if any scrolling combat text should be visible
--ShowDamage : Used to determine if the scrolling combat text for losing health should be visible
--ShowHeal : Used to determine if the scrolling combat text for gaining health should be visible

local PlayerBuffIconFrames = {}
local PlayerBuffIcons = {} --Used too deleted the current ones too make new ones --wth does this mean? i wrote it and it looks like gibberish to me
local PlayerBuffStackText = {} --Used too deleted the current ones too make new ones

local Party1BuffIconFrames = {}
local Party1BuffIcons = {} --Used too deleted the current ones too make new ones
local Party1BuffStackText = {} --Used too deleted the current ones too make new ones

local Party2BuffIconFrames = {}
local Party2BuffIcons = {} --Used too deleted the current ones too make new ones
local Party2BuffStackText = {} --Used too deleted the current ones too make new ones

local Party3BuffIconFrames = {}
local Party3BuffIcons = {} --Used too deleted the current ones too make new ones
local Party3BuffStackText = {} --Used too deleted the current ones too make new ones

local Party4BuffIconFrames = {}
local Party4BuffIcons = {} --Used too deleted the current ones too make new ones
local Party4BuffStackText = {} --Used too deleted the current ones too make new ones

local TargetBuffIconFrames = {}
local TargetBuffIcons = {} --Used too deleted the current ones too make new ones
local TargetBuffStackText = {} --Used too deleted the current ones too make new ones

-- Define a variable to store the target container globally
TargetContainer = nil


local PlayerNames = {} --This is used to keep from showing the target UI when the target is in your party.
	PlayerNames["player"] = nil
	PlayerNames["party1"] = nil
	PlayerNames["party2"] = nil
	PlayerNames["party3"] = nil
	PlayerNames["party4"] = nil
	PlayerNames["target"] = nil

local PreviouseHealth = {} --This is used to determine if the player gained or lost health, used in the scrolling combat text functions
	PreviouseHealth["player"] = -1
	PreviouseHealth["party1"] = -1
	PreviouseHealth["party2"] = -1
	PreviouseHealth["party3"] = -1
	PreviouseHealth["party4"] = -1
	PreviouseHealth["target"] = -1


-- This is just to respond to events; "EventHandlerFrame" never appears on the screen
local EventHandlerFrame = CreateFrame("Frame", "EventHandlerFrame", UIParent)

-- ========================================================================
-- DEFERRED EXECUTION (taint workaround)
-- ========================================================================
-- HealersMate's secure click-bind system supports a "target" keyword (see
-- SPECIAL_CLICK_ACTIONS) that performs a real Blizzard secure targeting
-- action. When that fires, PLAYER_TARGET_CHANGED goes out as a direct
-- consequence of a protected action -- which means our own response to that
-- event (updating/resizing the Target frame) can inherit taint from that
-- protected call chain, and Blizzard blocks otherwise-harmless calls like
-- SetHeight() with "AddOn prevented the call of the secure function". 3.3.5
-- has no C_Timer, so the standard workaround is to defer the actual UI work
-- to the *next* frame update via OnUpdate -- taint doesn't survive across a
-- frame boundary, so by the time this runs, it's no longer tainted.
local HM_DeferredFrame = CreateFrame("Frame")
local HM_DeferredQueue = {}
local HM_DeferredElapsed = 0
local HM_DEFER_DELAY = 0.3 -- seconds of quiet before running -- gives Blizzard's
                           -- own protected code (e.g. secure group headers
                           -- processing a roster change) time to fully finish,
                           -- since a single frame isn't always enough
HM_DeferredFrame:Hide()
HM_DeferredFrame:SetScript("OnUpdate", function(self, elapsed)
    HM_DeferredElapsed = HM_DeferredElapsed + elapsed
    if HM_DeferredElapsed < HM_DEFER_DELAY then return end

    self:Hide() -- stop ticking again until something new is queued
    HM_DeferredElapsed = 0
    local queue = HM_DeferredQueue
    HM_DeferredQueue = {}
    for _, fn in ipairs(queue) do
        local ok, err = pcall(fn)
        if not ok then
            Debug("HealersMate: deferred call error (recovered): " .. tostring(err))
        end
    end
end)

function HM_Defer(fn)
    if not fn then return end
    table.insert(HM_DeferredQueue, fn)
    -- Reset the quiet-period timer so several rapid events (e.g. multiple
    -- players joining within the same second) all get batched into one
    -- delayed pass instead of firing separately.
    HM_DeferredElapsed = 0
    HM_DeferredFrame:Show()
end

EventHandlerFrame:RegisterEvent("ADDON_LOADED")          -- Triggers once for every addon loaded after this one
EventHandlerFrame:RegisterEvent("PLAYER_LOGOUT")          -- Fired when about to log out
EventHandlerFrame:RegisterEvent("PLAYER_QUITTING")        -- FIXED TYPO: Fired when a player has the quit option on screen
EventHandlerFrame:RegisterEvent("UNIT_HEALTH")            -- Fires when a unit’s health changes
EventHandlerFrame:RegisterEvent("UNIT_AURA")              -- Update buffs and debuffs
EventHandlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")  -- Fired when entering world, reloading UI, or zoning
EventHandlerFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")  -- Correct for 3.3.5 (changed to GROUP_ROSTER_UPDATE in later expansions)
EventHandlerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")  -- Track when player changes target
EventHandlerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Fires the instant combat ends -- used to catch up on anything skipped during combat (spell-binding changes, and now pending frame-height recalculations; see HM_ApplyClickBindings and HM_RecalculateFrameLayout)

-- 3.3.5 Power Events (Cataclysm merged these into UNIT_POWER_UPDATE)
EventHandlerFrame:RegisterEvent("UNIT_MANA")
EventHandlerFrame:RegisterEvent("UNIT_RAGE")
EventHandlerFrame:RegisterEvent("UNIT_ENERGY")
EventHandlerFrame:RegisterEvent("UNIT_FOCUS")             -- Added: For Hunters and Pets in 3.3.5
EventHandlerFrame:RegisterEvent("UNIT_RUNIC_POWER")       -- Added: For Death Knights in 3.3.5

--EventHandlerFrame:RegisterEvent("PLAYER_LOGIN")         -- Fires when you login only once.

--#########################################################################################################

function Debug(msg)
    -- Used to send text to the chatbox of the player but not to any other player
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Used to set custom tooltip information when you mouse over things
local MyTooltip = CreateFrame("GameTooltip", "MyTooltip", UIParent, "GameTooltipTemplate")

-- Function that is called to set the text of a custom tooltip and where to display it.
local function ShowTooltip(AttachTo, TooltipText1, TooltipText2)
    MyTooltip:SetOwner(AttachTo, "ANCHOR_RIGHT")
    MyTooltip:SetPoint("RIGHT", AttachTo, "LEFT", 0, 0)
        
    MyTooltip:AddLine(TooltipText1, 1, 1, 1) -- White text color
    
    if TooltipText2 and TooltipText2 ~= "" then
        MyTooltip:AddLine(TooltipText2, 1, 1, 1) -- White text color
    end
        
    -- In 3.3.5, these global font strings are automatically generated by the "GameTooltipTemplate"
    MyTooltipTextLeft1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    MyTooltipTextLeft2:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    
    MyTooltip:Show()
end

-- Used to hide custom tooltips
local function HideTooltip()
    MyTooltip:Hide()
end


--#########################################################################################################
-- START - Create Settings UI
--#########################################################################################################

--START -- Checkbox Logic
local function CheckboxShowScrollingTextOnClick()
--Debug("[CheckboxShowScrollingTextOnClick] Ran")
    -- NOTE: every place that reads this setting compares against the STRING
    -- "true" (e.g. `if ShowScrollingText == "true" then`), so we must store
    -- a string here, not a real boolean -- `true == "true"` is always false
    -- in Lua, which is why these settings previously had no effect at all.
    local isChecked = (HM_CheckboxShowScrollingText:GetChecked() == 1)
    --Debug("[CheckboxShowScrollingTextOnClick](isChecked) == "..tostring(isChecked))
    if isChecked then
	
        ShowScrollingText = "true"
        
        HM_CheckboxShowDamage:Enable()
        HM_CheckboxShowHeal:Enable()

        HM_CheckboxShowDamageLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold
        HM_CheckboxHealLabel:SetTextColor(1, 0.82, 0)    -- Yellow/gold
    else
        ShowScrollingText = "false"
        
        HM_CheckboxShowDamage:Disable()
        HM_CheckboxShowHeal:Disable()
        
        HM_CheckboxShowDamageLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray
        HM_CheckboxHealLabel:SetTextColor(0.5, 0.5, 0.5)    -- Gray
    end
end

local function CheckboxShowDamageOnClick()
    ShowDamage = (HM_CheckboxShowDamage:GetChecked() == 1) and "true" or "false"
end

local function CheckboxShowHealOnClick()
    ShowHeal = (HM_CheckboxShowHeal:GetChecked() == 1) and "true" or "false"
end

local function CheckboxShowClassOnClick()
    ShowClass = (HM_CheckboxShowClass:GetChecked() == 1) and "true" or "false"
    -- Force an immediate name-text refresh instead of waiting for the next
    -- unrelated health/target event.
    if Check4Group then Check4Group() end
end

local function CheckboxColorNameByClassOnClick()
    ColorNameByClass = (HM_CheckboxColorNameByClass:GetChecked() == 1) and "true" or "false"
    if Check4Group then Check4Group() end
end

local function CheckboxShowPowerBarOnClick()
    ShowPowerBar = (HM_CheckboxShowPowerBar:GetChecked() == 1) and "true" or "false"
    -- Re-layout every frame now (shows/hides the power bar and re-flows the
    -- buff panel and container height to match) instead of waiting for the
    -- next aura update.
    if HM_RefreshAllAuraLayout then HM_RefreshAllAuraLayout() end
end

local function CheckboxShowBuffsOnClick()
    ShowBuffs = (HM_CheckboxShowBuffs:GetChecked() == 1) and "true" or "false"
    if HM_RefreshAllAuraLayout then HM_RefreshAllAuraLayout() end
end

local function CheckboxShowClickTooltipOnClick()
    ShowClickTooltip = (HM_CheckboxShowClickTooltip:GetChecked() == 1) and "true" or "false"
    -- Nothing else to refresh -- the tooltip checks this setting live each
    -- time you mouse over a health bar.
end

-- NEW: Checkbox for hiding background
local function CheckboxHideBackgroundOnClick()
    HideBackground = (HM_CheckboxHideBackground:GetChecked() == 1) and "true" or "false"
    if HM_ApplyFrameAppearance then HM_ApplyFrameAppearance() end
end

-- NEW: Checkbox for player-only buffs
local function CheckboxPlayerOnlyBuffsOnClick()
    PlayerOnlyBuffs = (HM_CheckboxPlayerOnlyBuffs:GetChecked() == 1) and "true" or "false"
    if HM_RefreshAllAuraLayout then HM_RefreshAllAuraLayout() end
end




-- "Show Health Value" is a master on/off for any numeric health text at all.
-- When on, HealthDisplayMode ("value" / "percent" / "both") picks the format
-- of the extra bit shown alongside "current/max".
local function CheckboxShowHealthValueOnClick()
    local isChecked = (HM_CheckboxShowHealthValue:GetChecked() == 1)
    ShowHealthValue = isChecked and "true" or "false"

    local radios = { HM_RadioHealthValue, HM_RadioHealthPercent, HM_RadioHealthBoth }
    for _, radio in ipairs(radios) do
        if radio then
            if isChecked then radio:Enable() else radio:Disable() end
        end
    end

    if Check4Group then Check4Group() end
end

-- Shared handler for the three mutually-exclusive health display radios.
-- WoW's UIRadioButtonTemplate doesn't enforce mutual exclusion on its own --
-- each click here explicitly re-checks itself and unchecks its siblings.
local function SetHealthDisplayMode(mode)
    HealthDisplayMode = mode
    if HM_RadioHealthValue   then HM_RadioHealthValue:SetChecked(mode == "value") end
    if HM_RadioHealthPercent then HM_RadioHealthPercent:SetChecked(mode == "percent") end
    if HM_RadioHealthBoth    then HM_RadioHealthBoth:SetChecked(mode == "both") end
    if Check4Group then Check4Group() end
end

--END -- Checkbox Logic

-- Create the main SETTINGS frame
local HM_SettingsContainer = CreateFrame("Frame", "HM_SettingsContainer", UIParent)
HM_SettingsContainer:SetFrameLevel(10)
HM_SettingsContainer:SetWidth(425) 
HM_SettingsContainer:SetHeight(430) 
HM_SettingsContainer:SetPoint("CENTER", UIParent, "CENTER")
HM_SettingsContainer:EnableMouse(true)
HM_SettingsContainer:SetMovable(true)

-- In 3.3.5, SetBackdrop is natively supported on frames out-of-the-box
HM_SettingsContainer:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", -- Added standard border for clean 3.3.5 look
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})

-- 3.3.5 Mouse Dragging Scripts using explicit parameters
HM_SettingsContainer:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
        self:StartMoving()
        self.isMoving = true
    end
end)

HM_SettingsContainer:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
    end
end)

-- Main Settings Page - Title Text
local title = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetText("HealersMate Settings")
title:SetPoint("TOP", HM_SettingsContainer, "TOP", 0, -10)

-- Main Settings Page - Close Button
local closeButton = CreateFrame("Button", nil, HM_SettingsContainer, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", HM_SettingsContainer, "TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function(self) 
    HM_SettingsContainer:Hide() 
    if checkboxFrame then checkboxFrame:Hide() end
    if spellsFrame then spellsFrame:Hide() end
    if scalingFrame then scalingFrame:Hide() end
    if AboutFrame then AboutFrame:Show() end 
end)

--START--Combobox

-- What to do when an option is selected in the settings combobox

local function ShowFrame(frameName)
    if frameName == "checkboxFrame" then
        if HM_CheckboxFrame then HM_CheckboxFrame:Show() end
        if HM_SpellsFrame then HM_SpellsFrame:Hide() end
        if HM_ScalingFrame then HM_ScalingFrame:Hide() end
        if HM_AboutFrame then HM_AboutFrame:Hide() end
    elseif frameName == "spellsFrame" then
        if HM_CheckboxFrame then HM_CheckboxFrame:Hide() end
        if HM_SpellsFrame then HM_SpellsFrame:Show() end
        if HM_ScalingFrame then HM_ScalingFrame:Hide() end
        if HM_AboutFrame then HM_AboutFrame:Hide() end
    elseif frameName == "scalingFrame" then
        if HM_CheckboxFrame then HM_CheckboxFrame:Hide() end
        if HM_SpellsFrame then HM_SpellsFrame:Hide() end
        if HM_ScalingFrame then HM_ScalingFrame:Show() end
        if HM_AboutFrame then HM_AboutFrame:Hide() end
    end
end

local dropdownOptions = {
    { text = "Checkboxes", func = function() ShowFrame("checkboxFrame") end },
    { text = "Spells", func = function() ShowFrame("spellsFrame") end },
    { text = "Appearance", func = function() ShowFrame("scalingFrame") end },
}

-- Dropdown list frame
local dropdownList = CreateFrame("Frame", "HM_SettingsDropdownList", HM_SettingsContainer, "UIDropDownMenuTemplate")
dropdownList:SetPoint("TOPLEFT", HM_SettingsContainer, "TOPLEFT", 0, -30)

-- 3.3.5 FIXED: Standard :SetWidth() breaks the background texture of a UIDropDownMenu.
-- You must use the built-in global function instead.
UIDropDownMenu_SetWidth(dropdownList, 120) 
dropdownList:SetHeight(150)
dropdownList:Show()

-- Initialize the dropdown menu
UIDropDownMenu_Initialize(dropdownList, function(self, level)
    for _, dropdownOption in pairs(dropdownOptions) do
        -- 3.3.5 FIXED: Using a blank table `local info = {}` causes UI taint and 
        -- layout leaks. You must use the engine's built-in initialization helper.
        local info = UIDropDownMenu_CreateInfo()
        info.text = dropdownOption.text
        info.func = dropdownOption.func
        info.notCheckable = true -- Optional optimization: removes empty checkmark spacing
        UIDropDownMenu_AddButton(info)
    end
end)

-- Set the default text for the combobox
-- 3.3.5 FIXED: Argument order was backwards. The syntax is (frame, text).
UIDropDownMenu_SetText(dropdownList, "Select option")

--END--Combobox

-- Settings Content Frames: About, Checkboxes, Spells, Scaling
-- Adjusted heights to 300 so they sit perfectly inside the 365-height parent container
local AboutFrame = CreateFrame("Frame", "HM_AboutFrame", HM_SettingsContainer)
AboutFrame:SetWidth(425)
AboutFrame:SetHeight(430)
AboutFrame:SetPoint("TOPLEFT", HM_SettingsContainer, "TOPLEFT", 0, 0)
AboutFrame:Show()

-- Pointing these to the remaining space on the right side of the menu
local checkboxFrame = CreateFrame("Frame", "HM_CheckboxFrame", HM_SettingsContainer)
checkboxFrame:SetWidth(250)
checkboxFrame:SetHeight(365)
checkboxFrame:SetPoint("TOPLEFT", HM_SettingsContainer, "TOPLEFT", 20, -55)
checkboxFrame:Hide() -- Initially hidden

local spellsFrame = CreateFrame("Frame", "HM_SpellsFrame", HM_SettingsContainer)
spellsFrame:SetWidth(250)
spellsFrame:SetHeight(365)
spellsFrame:SetPoint("BOTTOMRIGHT", HM_SettingsContainer, "BOTTOMRIGHT", -20, 20)
spellsFrame:Hide() -- Initially hidden

local scalingFrame = CreateFrame("Frame", "HM_ScalingFrame", HM_SettingsContainer)
scalingFrame:SetWidth(250)
scalingFrame:SetHeight(365)
scalingFrame:SetPoint("TOPLEFT", HM_SettingsContainer, "TOPLEFT", 130, -75) -- x,y
scalingFrame:Hide() -- Initially hidden

-- Make sure your global references match the new unique names
-- (Updates the variables used by your previous dropdown logic)
checkboxFrame = HM_CheckboxFrame
spellsFrame = HM_SpellsFrame
scalingFrame = HM_ScalingFrame
AboutFrame = HM_AboutFrame

-- START -- AboutFrame Contents

local TxtAboutLabel = AboutFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtAboutLabel:SetPoint("CENTER", AboutFrame, "CENTER", 0, 0)
TxtAboutLabel:SetJustifyH("CENTER") -- Ensures clean multi-line text alignment in 3.3.5
TxtAboutLabel:SetText("HealersMate Version 1.3.0\ni2ichardt, Claude/ChatGPT/Gemini\nrj299@yahoo.com\n\nCheck for Updates @:\nhttps://github.com/i2ichardt/HealersMate")
-- END -- AboutFrame Contents

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------

-- START -- SpellsFrame Contents

-- Reference point for child control positions
local TopX = -90  -- Right-side padding offset
local TopY = -15  -- Top padding offset

-- Helper function to apply required 3.3.5 EditBox behavior 
-- (Prevents repeating focus-clearing code 9 times)
-- "varName" (optional) is the saved-variable name this box maps to (e.g.
-- "LeftClickSpell"); when supplied, any edit (typing, pasting, deleting, or
-- pressing Enter) saves the typed text into that global immediately and
-- pushes it out to the secure buttons, so the player doesn't have to /reload,
-- relog, or even remember to press Enter to see a spell-name change apply.

local function UpdateValidation(editBox, icon)
    local text = editBox:GetText()
    if text == "" then 
        --icon:SetText("") 
        return 
    end
    
    -- Check if spell exists
    local name = GetSpellInfo(text)
    if name then
        editBox:SetTextColor(0.4, 0.7, 1.0) -- Blue text for valid
        --icon:SetText("|TInterface\\Buttons\\UI-CheckBox-Check:16:16|t") -- Checkmark
    else
        editBox:SetTextColor(1.0, 0.4, 0.4) -- Red text for invalid
        --icon:SetText("|TInterface\\AddOns\\YourAddonName\\Media\\Warning:16:16|t") -- Requires a warning icon
    end
end

local function Configure335EditBox(editBox, varName)
    editBox:SetAutoFocus(false) -- CRITICAL FOR 3.3.5: Prevents keyboard hijacking
    editBox:SetFontObject("ChatFontNormal") -- Standard clean input text font

    local function SaveAndRefresh(self)
        if varName then
            _G[varName] = tostring(self:GetText() or "")

            -- No-ops harmlessly if the player is in combat; the old bindings
            -- just stay in effect until combat ends (see HM_ApplyClickBindings).
            if HM_RefreshAllSpellBindings then
                HM_RefreshAllSpellBindings()
            end
        end
    end
    
    -- Clear keyboard focus when interacting natively
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        SaveAndRefresh(self)
    end)
    -- Fires on every keystroke/paste/delete, including clearing the box to
    -- empty -- so a change takes effect even if the player never presses
    -- Enter or clicks away.
    editBox:SetScript("OnTextChanged", function(self)
        SaveAndRefresh(self)
		UpdateValidation(self, status)
    end)
	
end

-- ==========================================
-- LEFT CLICK GROUP
-- ==========================================

-- Textbox
local TxtLeftClick = CreateFrame("EditBox", "HM_TxtLeftClick", HM_SpellsFrame, "InputBoxTemplate")
TxtLeftClick:SetPoint("TOPRIGHT", HM_SpellsFrame, "TOPRIGHT", TopX, TopY - 10)
TxtLeftClick:SetWidth(140) 
TxtLeftClick:SetHeight(22) -- 3.3.5 InputBoxTemplate textures look best at 20-22 height
Configure335EditBox(TxtLeftClick, "LeftClickSpell")

-- Label
local TxtLeftClickLabel = HM_SpellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtLeftClickLabel:SetPoint("RIGHT", TxtLeftClick, "LEFT", -10, 0)
TxtLeftClickLabel:SetText("Left Click:")

-- Textbox
local TxtShiftLeftClick = CreateFrame("EditBox", "HM_TxtShiftLeftClick", HM_SpellsFrame, "InputBoxTemplate")
TxtShiftLeftClick:SetPoint("TOPRIGHT", HM_SpellsFrame, "TOPRIGHT", TopX, TopY - 40)
TxtShiftLeftClick:SetWidth(140)
TxtShiftLeftClick:SetHeight(22)
Configure335EditBox(TxtShiftLeftClick, "ShiftLeftClickSpell")

-- Label
local TxtShiftLeftClickLabel = HM_SpellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtShiftLeftClickLabel:SetPoint("RIGHT", TxtShiftLeftClick, "LEFT", -10, 0)
TxtShiftLeftClickLabel:SetText("Shift + Left:")

-- Textbox
local TxtCtrlLeftClick = CreateFrame("EditBox", "HM_TxtCtrlLeftClick", HM_SpellsFrame, "InputBoxTemplate")
TxtCtrlLeftClick:SetPoint("TOPRIGHT", HM_SpellsFrame, "TOPRIGHT", TopX, TopY - 70)
TxtCtrlLeftClick:SetWidth(140)
TxtCtrlLeftClick:SetHeight(22)
Configure335EditBox(TxtCtrlLeftClick, "ControlLeftClickSpell")

-- Label
local TxtCtrlLeftLabel = HM_SpellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtCtrlLeftLabel:SetPoint("RIGHT", TxtCtrlLeftClick, "LEFT", -10, 0)
TxtCtrlLeftLabel:SetText("Ctrl + Left:")


-- ==========================================
-- MIDDLE CLICK GROUP
-- ==========================================

-- Textbox
local TxtMiddleClick = CreateFrame("EditBox", "HM_TxtMiddleClick", HM_SpellsFrame, "InputBoxTemplate")
TxtMiddleClick:SetPoint("TOPRIGHT", HM_SpellsFrame, "TOPRIGHT", TopX, TopY - 110)
TxtMiddleClick:SetWidth(140)
TxtMiddleClick:SetHeight(22)
Configure335EditBox(TxtMiddleClick, "MiddleClickSpell")

-- Label
local TxtMiddleClickLabel = HM_SpellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtMiddleClickLabel:SetPoint("RIGHT", TxtMiddleClick, "LEFT", -10, 0)
TxtMiddleClickLabel:SetText("Middle Click:")

-- Textbox
local TxtShiftMiddleClick = CreateFrame("EditBox", "HM_TxtShiftMiddleClick", HM_SpellsFrame, "InputBoxTemplate")
TxtShiftMiddleClick:SetPoint("TOPRIGHT", HM_SpellsFrame, "TOPRIGHT", TopX, TopY - 140)
TxtShiftMiddleClick:SetWidth(140)
TxtShiftMiddleClick:SetHeight(22)
Configure335EditBox(TxtShiftMiddleClick, "ShiftMiddleClickSpell")

-- Label
local TxtShiftMiddleClickLabel = HM_SpellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtShiftMiddleClickLabel:SetPoint("RIGHT", TxtShiftMiddleClick, "LEFT", -10, 0)
TxtShiftMiddleClickLabel:SetText("Shift + Mid:")

-- Textbox
local TxtCtrlMiddleClick = CreateFrame("EditBox", "HM_TxtCtrlMiddleClick", HM_SpellsFrame, "InputBoxTemplate")
TxtCtrlMiddleClick:SetPoint("TOPRIGHT", HM_SpellsFrame, "TOPRIGHT", TopX, TopY - 170)
TxtCtrlMiddleClick:SetWidth(140)
TxtCtrlMiddleClick:SetHeight(22)
Configure335EditBox(TxtCtrlMiddleClick, "ControlMiddleClickSpell")

-- Label
local TxtCtrlMiddleClickLabel = HM_SpellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtCtrlMiddleClickLabel:SetPoint("RIGHT", TxtCtrlMiddleClick, "LEFT", -10, 0)
TxtCtrlMiddleClickLabel:SetText("Ctrl + Mid:")


-- ==========================================
-- RIGHT CLICK GROUP
-- ==========================================

-- Textbox
local TxtRightClick = CreateFrame("EditBox", "HM_TxtRightClick", HM_SpellsFrame, "InputBoxTemplate")
TxtRightClick:SetPoint("TOPRIGHT", HM_SpellsFrame, "TOPRIGHT", TopX, TopY - 210)
TxtRightClick:SetWidth(140)
TxtRightClick:SetHeight(22)
Configure335EditBox(TxtRightClick, "RightClickSpell")

-- Label
local TxtRightClickLabel = HM_SpellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtRightClickLabel:SetPoint("RIGHT", TxtRightClick, "LEFT", -10, 0)
TxtRightClickLabel:SetText("Right Click:")

-- Textbox
local TxtShiftRightClick = CreateFrame("EditBox", "HM_TxtShiftRightClick", HM_SpellsFrame, "InputBoxTemplate")
TxtShiftRightClick:SetPoint("TOPRIGHT", HM_SpellsFrame, "TOPRIGHT", TopX, TopY - 240)
TxtShiftRightClick:SetWidth(140)
TxtShiftRightClick:SetHeight(22)
Configure335EditBox(TxtShiftRightClick, "ShiftRightClickSpell")

-- Label
local TxtShiftRightClickLabel = HM_SpellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtShiftRightClickLabel:SetPoint("RIGHT", TxtShiftRightClick, "LEFT", -10, 0)
TxtShiftRightClickLabel:SetText("Shift + Right:")

-- Textbox
local TxtCtrlRightClick = CreateFrame("EditBox", "HM_TxtCtrlRightClick", HM_SpellsFrame, "InputBoxTemplate")
TxtCtrlRightClick:SetPoint("TOPRIGHT", HM_SpellsFrame, "TOPRIGHT", TopX, TopY - 270)
TxtCtrlRightClick:SetWidth(140)
TxtCtrlRightClick:SetHeight(22)
Configure335EditBox(TxtCtrlRightClick, "ControlRightClickSpell")

-- Label
local TxtCtrlRightClickLabel = HM_SpellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtCtrlRightClickLabel:SetPoint("RIGHT", TxtCtrlRightClick, "LEFT", -10, 0)
TxtCtrlRightClickLabel:SetText("Ctrl + Right:")

-- END -- SpellsFrame Contents--

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------

-- START -- ScalingFrame (Frame Appearance) Contents
-- Lets the player customize width/height/background color/transparency of
-- the Player, Party1-4, and Target unit frames. Applies live as controls
-- are adjusted (see HM_ApplyFrameAppearance, defined near HM_CreateUnitFrame).

-- NOTE: this section used to (incorrectly) reuse the Spells section's TopX/
-- TopY (-90/-15), which are offsets meant for TOPRIGHT-anchored elements.
-- Applied to this section's TOPLEFT-anchored elements instead, that shoved
-- everything ~90px too far left, off-center from the other settings tabs.
-- These are dedicated TOPLEFT-appropriate offsets instead, matching the
-- positive-offset convention used for TOPLEFT content elsewhere (e.g. the
-- Checkboxes tab's CheckboxTopX/CheckboxTopY).
local AppearanceX = 0
local AppearanceY = 0

local AppearanceTitle = HM_ScalingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
AppearanceTitle:SetPoint("TOPLEFT", HM_ScalingFrame, "TOPLEFT", AppearanceX, AppearanceY + 5)
AppearanceTitle:SetText("Frame Appearance")

-- Width slider
local WidthSlider = CreateFrame("Slider", "HM_FrameWidthSlider", HM_ScalingFrame, "OptionsSliderTemplate")
WidthSlider:SetWidth(190)
WidthSlider:SetHeight(16)
WidthSlider:SetPoint("TOPLEFT", HM_ScalingFrame, "TOPLEFT", AppearanceX, AppearanceY - 30)
WidthSlider:SetMinMaxValues(100, 400)
WidthSlider:SetValueStep(1)
HM_FrameWidthSliderText:SetText("Frame Width")
HM_FrameWidthSliderLow:SetText("100")
HM_FrameWidthSliderHigh:SetText("400")

local WidthValueText = HM_ScalingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
WidthValueText:SetPoint("TOP", WidthSlider, "BOTTOM", 0, -2)

WidthSlider:SetScript("OnValueChanged", function(self, value)
    FrameWidth = math.floor(value + 0.5)
    WidthValueText:SetText(tostring(FrameWidth) .. " px")
    if HM_ApplyFrameAppearance then HM_ApplyFrameAppearance() end
end)

-- Custom height checkbox
local CheckboxCustomHeight = CreateFrame("CheckButton", "HM_CheckboxCustomHeight", HM_ScalingFrame, "UICheckButtonTemplate")
CheckboxCustomHeight:SetWidth(24)
CheckboxCustomHeight:SetHeight(24)
CheckboxCustomHeight:SetPoint("TOPLEFT", HM_ScalingFrame, "TOPLEFT", AppearanceX - 5, AppearanceY - 75)

local CheckboxCustomHeightLabel = HM_ScalingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
CheckboxCustomHeightLabel:SetPoint("LEFT", CheckboxCustomHeight, "RIGHT", 5, 0)
CheckboxCustomHeightLabel:SetText("Use Custom Height")

-- Height slider (only takes effect while the checkbox above is checked --
-- otherwise height is auto-calculated from frame contents, same as before)
local HeightSlider = CreateFrame("Slider", "HM_FrameHeightSlider", HM_ScalingFrame, "OptionsSliderTemplate")
HeightSlider:SetWidth(190)
HeightSlider:SetHeight(16)
HeightSlider:SetPoint("TOPLEFT", HM_ScalingFrame, "TOPLEFT", AppearanceX, AppearanceY - 110)
HeightSlider:SetMinMaxValues(80, 400)
HeightSlider:SetValueStep(1)
HM_FrameHeightSliderText:SetText("Frame Height")
HM_FrameHeightSliderLow:SetText("80")
HM_FrameHeightSliderHigh:SetText("400")

local HeightValueText = HM_ScalingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeightValueText:SetPoint("TOP", HeightSlider, "BOTTOM", 0, -2)

HeightSlider:SetScript("OnValueChanged", function(self, value)
    FrameHeightValue = math.floor(value + 0.5)
    HeightValueText:SetText(tostring(FrameHeightValue) .. " px")
    if HM_ApplyFrameAppearance then HM_ApplyFrameAppearance() end
	if HM_ReapplyAllDocking then HM_ReapplyAllDocking() end
end)

CheckboxCustomHeight:SetScript("OnClick", function(self)
    local checked = (self:GetChecked() == 1)
    FrameCustomHeight = checked and "true" or "false"
    if checked then HeightSlider:Enable() else HeightSlider:Disable() end
    if HM_ApplyFrameAppearance then HM_ApplyFrameAppearance() end
	if HM_ReapplyAllDocking then HM_ReapplyAllDocking() end
end)

-- Background transparency slider (0 = fully see-through, 100 = fully opaque)
local AlphaSlider = CreateFrame("Slider", "HM_FrameAlphaSlider", HM_ScalingFrame, "OptionsSliderTemplate")
AlphaSlider:SetWidth(190)
AlphaSlider:SetHeight(16)
AlphaSlider:SetPoint("TOPLEFT", HM_ScalingFrame, "TOPLEFT", AppearanceX, AppearanceY - 155)
AlphaSlider:SetMinMaxValues(0, 100)
AlphaSlider:SetValueStep(1)
HM_FrameAlphaSliderText:SetText("Background Opacity")
HM_FrameAlphaSliderLow:SetText("0%")
HM_FrameAlphaSliderHigh:SetText("100%")

local AlphaValueText = HM_ScalingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
AlphaValueText:SetPoint("TOP", AlphaSlider, "BOTTOM", 0, -2)

AlphaSlider:SetScript("OnValueChanged", function(self, value)
    local pct = math.floor(value + 0.5)
    FrameBGAlpha = pct / 100
    AlphaValueText:SetText(tostring(pct) .. "%")
    if HM_ApplyFrameAppearance then HM_ApplyFrameAppearance() end
end)

-- Background color swatch (opens the standard Blizzard color picker)
local ColorSwatchLabel = HM_ScalingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ColorSwatchLabel:SetPoint("TOPLEFT", HM_ScalingFrame, "TOPLEFT", AppearanceX - 5, AppearanceY - 200)
ColorSwatchLabel:SetText("Background Color:")

local ColorSwatchButton = CreateFrame("Button", "HM_FrameColorButton", HM_ScalingFrame)
ColorSwatchButton:SetWidth(24)
ColorSwatchButton:SetHeight(24)
ColorSwatchButton:SetPoint("LEFT", ColorSwatchLabel, "RIGHT", 10, 0)

local swatchBorder = ColorSwatchButton:CreateTexture(nil, "BACKGROUND")
swatchBorder:SetAllPoints(true)
swatchBorder:SetTexture(0, 0, 0, 1)

local swatchTex = ColorSwatchButton:CreateTexture(nil, "ARTWORK")
swatchTex:SetPoint("TOPLEFT", 1, -1)
swatchTex:SetPoint("BOTTOMRIGHT", -1, 1)
swatchTex:SetTexture(1, 1, 1)
ColorSwatchButton.swatchTex = swatchTex

ColorSwatchButton:SetScript("OnClick", function(self)
    local r = tonumber(FrameBGColorR) or 1
    local g = tonumber(FrameBGColorG) or 1
    local b = tonumber(FrameBGColorB) or 1
    local a = tonumber(FrameBGAlpha) or 1

    ColorPickerFrame.func = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        FrameBGColorR, FrameBGColorG, FrameBGColorB = nr, ng, nb
        self.swatchTex:SetTexture(nr, ng, nb)
        if HM_ApplyFrameAppearance then HM_ApplyFrameAppearance() end
    end
    ColorPickerFrame.cancelFunc = function(previousValues)
        if previousValues then
            FrameBGColorR = previousValues.r
            FrameBGColorG = previousValues.g
            FrameBGColorB = previousValues.b
            self.swatchTex:SetTexture(FrameBGColorR, FrameBGColorG, FrameBGColorB)
            if HM_ApplyFrameAppearance then HM_ApplyFrameAppearance() end
        end
    end
	
	ColorPickerFrame.hasOpacity = false -- opacity has its own slider above already
    ColorPickerFrame.previousValues = { r = r, g = g, b = b }
    ColorPickerFrame:SetColorRGB(r, g, b)
    ShowUIPanel(ColorPickerFrame)
end)

-- Hide Border checkbox (border is separate from the background -- Hide
-- Background already exists in the Checkboxes tab, but there was no way to
-- hide just the border while keeping the background)
local CheckboxHideBorder = CreateFrame("CheckButton", "HM_CheckboxHideBorder", HM_ScalingFrame, "UICheckButtonTemplate")
CheckboxHideBorder:SetWidth(24)
CheckboxHideBorder:SetHeight(24)
CheckboxHideBorder:SetPoint("TOPLEFT", HM_ScalingFrame, "TOPLEFT", AppearanceX - 5, AppearanceY - 235)
CheckboxHideBorder:SetScript("OnClick", function(self)
    HideBorder = (self:GetChecked() == 1) and "true" or "false"
    if HM_ApplyFrameAppearance then HM_ApplyFrameAppearance() end
end)

local CheckboxHideBorderLabel = HM_ScalingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
CheckboxHideBorderLabel:SetPoint("LEFT", CheckboxHideBorder, "RIGHT", 5, 0)
CheckboxHideBorderLabel:SetText("Hide Frame Border")

-- Reset to defaults button
local ResetAppearanceButton = CreateFrame("Button", "HM_ResetAppearanceButton", HM_ScalingFrame, "UIPanelButtonTemplate")
ResetAppearanceButton:SetWidth(150)
ResetAppearanceButton:SetHeight(22)
ResetAppearanceButton:SetPoint("TOPLEFT", HM_ScalingFrame, "TOPLEFT", AppearanceX - 5, AppearanceY - 270)
ResetAppearanceButton:SetText("Reset to Default")
ResetAppearanceButton:SetScript("OnClick", function()
    FrameWidth = 200
    FrameCustomHeight = "false"
    FrameHeightValue = 150
    FrameBGColorR, FrameBGColorG, FrameBGColorB = 1, 1, 1
    FrameBGAlpha = 1
    HideBorder = "false"

    WidthSlider:SetValue(FrameWidth)
    CheckboxCustomHeight:SetChecked(false)
    HeightSlider:SetValue(FrameHeightValue)
    HeightSlider:Disable()
    AlphaSlider:SetValue(100)
    swatchTex:SetTexture(1, 1, 1)
    CheckboxHideBorder:SetChecked(false)

    if HM_ApplyFrameAppearance then HM_ApplyFrameAppearance() end
end)
-- END -- ScalingFrame (Frame Appearance) Contents

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------

-- START -- checkboxFrame Contents

-- Layout: two columns of grouped sections with headers, matching the
-- requested settings-page mockup:
--   GENERAL         APPEARANCE
--   HEALTH          TARGETS
--   SCROLLING TEXT

local CheckboxTopX = 0
local CheckboxTopY = -20
local CB_SIZE = 24
local CB_SIZE_SMALL = 20 -- radio buttons read fine slightly smaller than checkboxes

local Col1X = CheckboxTopX + 20   -- left column checkbox X
local Col2X = CheckboxTopX + 180  -- right column checkbox X
local IndentX = CheckboxTopX + 35 -- indented sub-item X (radios, SCT sub-checks)

-- Small helper so every section header looks consistent (gold, same font).
local function CreateSectionHeader(name, xOffset, yOffset)
    local header = HM_CheckboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", xOffset, yOffset)
    header:SetText(name)
    header:SetTextColor(1, 0.82, 0) -- gold, to stand out from regular checkbox labels
    return header
end

-- ========================================================================
-- ROW 0: Section headers -- GENERAL / APPEARANCE
-- ========================================================================
CreateSectionHeader("GENERAL", CheckboxTopX, CheckboxTopY + 0)
CreateSectionHeader("APPEARANCE", Col2X - 5, CheckboxTopY + 0)

-- ---- GENERAL: Show Target ----
local CheckboxShowTarget = CreateFrame("CheckButton", "HM_CheckboxShowTarget", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxShowTarget:SetWidth(CB_SIZE)
CheckboxShowTarget:SetHeight(CB_SIZE)
CheckboxShowTarget:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col1X, CheckboxTopY - 22)
CheckboxShowTarget:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Check to show a UI Frame for the player's target.", "Note: You also need to check Friendly and/or Enemy under Targets.")
end)
CheckboxShowTarget:SetScript("OnLeave", HideTooltip)
CheckboxShowTarget:SetScript("OnClick", CheckboxShowTargetOnClick)

local CheckboxShowTargetLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxShowTargetLabel", "OVERLAY", "GameFontNormal")
CheckboxShowTargetLabel:SetPoint("LEFT", CheckboxShowTarget, "RIGHT", 5, 0)
CheckboxShowTargetLabel:SetText("Show Target")

-- ---- GENERAL: Show Class ----
local CheckboxShowClass = CreateFrame("CheckButton", "HM_CheckboxShowClass", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxShowClass:SetWidth(CB_SIZE)
CheckboxShowClass:SetHeight(CB_SIZE)
CheckboxShowClass:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col1X, CheckboxTopY - 46)
CheckboxShowClass:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Check to show the unit's class next to their name.", "Uncheck to show just the name.")
end)
CheckboxShowClass:SetScript("OnLeave", HideTooltip)
CheckboxShowClass:SetScript("OnClick", CheckboxShowClassOnClick)

local CheckboxShowClassLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxShowClassLabel", "OVERLAY", "GameFontNormal")
CheckboxShowClassLabel:SetPoint("LEFT", CheckboxShowClass, "RIGHT", 5, 0)
CheckboxShowClassLabel:SetText("Show Class")

-- ---- GENERAL: Show Energy ----
local CheckboxShowPowerBar = CreateFrame("CheckButton", "HM_CheckboxShowPowerBar", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxShowPowerBar:SetWidth(CB_SIZE)
CheckboxShowPowerBar:SetHeight(CB_SIZE)
CheckboxShowPowerBar:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col1X, CheckboxTopY - 70)
CheckboxShowPowerBar:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Check to show the mana/energy/rage bar under the health bar.")
end)
CheckboxShowPowerBar:SetScript("OnLeave", HideTooltip)
CheckboxShowPowerBar:SetScript("OnClick", CheckboxShowPowerBarOnClick)

local CheckboxShowPowerBarLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxShowPowerBarLabel", "OVERLAY", "GameFontNormal")
CheckboxShowPowerBarLabel:SetPoint("LEFT", CheckboxShowPowerBar, "RIGHT", 5, 0)
CheckboxShowPowerBarLabel:SetText("Show Energy")

-- ---- GENERAL: Show Click Tooltip ----
local CheckboxShowClickTooltip = CreateFrame("CheckButton", "HM_CheckboxShowClickTooltip", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxShowClickTooltip:SetWidth(CB_SIZE)
CheckboxShowClickTooltip:SetHeight(CB_SIZE)
CheckboxShowClickTooltip:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col1X, CheckboxTopY - 94)
CheckboxShowClickTooltip:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Check to show a tooltip when hovering a health bar", "listing which click types have spells bound, and what they are.")
end)
CheckboxShowClickTooltip:SetScript("OnLeave", HideTooltip)
CheckboxShowClickTooltip:SetScript("OnClick", CheckboxShowClickTooltipOnClick)

local CheckboxShowClickTooltipLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxShowClickTooltipLabel", "OVERLAY", "GameFontNormal")
CheckboxShowClickTooltipLabel:SetPoint("LEFT", CheckboxShowClickTooltip, "RIGHT", 5, 0)
CheckboxShowClickTooltipLabel:SetText("Show Click Tooltip")

-- ---- APPEARANCE: Hide Background ----
local CheckboxHideBackground = CreateFrame("CheckButton", "HM_CheckboxHideBackground", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxHideBackground:SetWidth(CB_SIZE)
CheckboxHideBackground:SetHeight(CB_SIZE)
CheckboxHideBackground:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col2X, CheckboxTopY - 22)
CheckboxHideBackground:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Hide the background of all unit frames.")
end)
CheckboxHideBackground:SetScript("OnLeave", HideTooltip)
CheckboxHideBackground:SetScript("OnClick", CheckboxHideBackgroundOnClick)

local CheckboxHideBackgroundLabel = HM_CheckboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
CheckboxHideBackgroundLabel:SetPoint("LEFT", CheckboxHideBackground, "RIGHT", 5, 0)
CheckboxHideBackgroundLabel:SetText("Hide Background")

-- ---- APPEARANCE: Color by Class ----
local CheckboxColorNameByClass = CreateFrame("CheckButton", "HM_CheckboxColorNameByClass", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxColorNameByClass:SetWidth(CB_SIZE)
CheckboxColorNameByClass:SetHeight(CB_SIZE)
CheckboxColorNameByClass:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col2X, CheckboxTopY - 46)
CheckboxColorNameByClass:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Check to color the unit's name using their class color.")
end)
CheckboxColorNameByClass:SetScript("OnLeave", HideTooltip)
CheckboxColorNameByClass:SetScript("OnClick", CheckboxColorNameByClassOnClick)

local CheckboxColorNameByClassLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxColorNameByClassLabel", "OVERLAY", "GameFontNormal")
CheckboxColorNameByClassLabel:SetPoint("LEFT", CheckboxColorNameByClass, "RIGHT", 5, 0)
CheckboxColorNameByClassLabel:SetText("Color by Class")

-- ---- APPEARANCE: Show Buffs ----
local CheckboxShowBuffs = CreateFrame("CheckButton", "HM_CheckboxShowBuffs", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxShowBuffs:SetWidth(CB_SIZE)
CheckboxShowBuffs:SetHeight(CB_SIZE)
CheckboxShowBuffs:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col2X, CheckboxTopY - 70)
CheckboxShowBuffs:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Check to show buff/debuff icons on unit frames.")
end)
CheckboxShowBuffs:SetScript("OnLeave", HideTooltip)
CheckboxShowBuffs:SetScript("OnClick", CheckboxShowBuffsOnClick)

local CheckboxShowBuffsLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxShowBuffsLabel", "OVERLAY", "GameFontNormal")
CheckboxShowBuffsLabel:SetPoint("LEFT", CheckboxShowBuffs, "RIGHT", 5, 0)
CheckboxShowBuffsLabel:SetText("Show Buffs")

-- ---- APPEARANCE: Player Cast Buffs Only ----
local CheckboxPlayerOnlyBuffs = CreateFrame("CheckButton", "HM_CheckboxPlayerOnlyBuffs", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxPlayerOnlyBuffs:SetWidth(CB_SIZE)
CheckboxPlayerOnlyBuffs:SetHeight(CB_SIZE)
CheckboxPlayerOnlyBuffs:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col2X, CheckboxTopY - 94)
CheckboxPlayerOnlyBuffs:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Only show buffs/debuffs that you (the player) cast.")
end)
CheckboxPlayerOnlyBuffs:SetScript("OnLeave", HideTooltip)
CheckboxPlayerOnlyBuffs:SetScript("OnClick", CheckboxPlayerOnlyBuffsOnClick)

local CheckboxPlayerOnlyBuffsLabel = HM_CheckboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
CheckboxPlayerOnlyBuffsLabel:SetPoint("LEFT", CheckboxPlayerOnlyBuffs, "RIGHT", 5, 0)
CheckboxPlayerOnlyBuffsLabel:SetText("Player Cast Buffs Only")

-- ========================================================================
-- ROW: Section headers -- HEALTH / TARGETS
-- ========================================================================
CreateSectionHeader("HEALTH", CheckboxTopX, CheckboxTopY - 128)
CreateSectionHeader("TARGETS", Col2X - 5, CheckboxTopY - 128)

-- ---- HEALTH: Show Health Value (master toggle) ----
local CheckboxShowHealthValue = CreateFrame("CheckButton", "HM_CheckboxShowHealthValue", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxShowHealthValue:SetWidth(CB_SIZE)
CheckboxShowHealthValue:SetHeight(CB_SIZE)
CheckboxShowHealthValue:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col1X, CheckboxTopY - 150)
CheckboxShowHealthValue:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Check to show a numeric health value on the health bar.", "Uncheck to show just the bar, with no text.")
end)
CheckboxShowHealthValue:SetScript("OnLeave", HideTooltip)
CheckboxShowHealthValue:SetScript("OnClick", CheckboxShowHealthValueOnClick)

local CheckboxShowHealthValueLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxShowHealthValueLabel", "OVERLAY", "GameFontNormal")
CheckboxShowHealthValueLabel:SetPoint("LEFT", CheckboxShowHealthValue, "RIGHT", 5, 0)
CheckboxShowHealthValueLabel:SetText("Show Health Value")

-- ---- HEALTH: Value / Percent / Both (mutually exclusive radios) ----
local RadioHealthValue = CreateFrame("CheckButton", "HM_RadioHealthValue", HM_CheckboxFrame, "UIRadioButtonTemplate")
RadioHealthValue:SetWidth(CB_SIZE_SMALL)
RadioHealthValue:SetHeight(CB_SIZE_SMALL)
RadioHealthValue:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", IndentX, CheckboxTopY - 172)
RadioHealthValue:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Show the missing health amount, e.g. \"850/1000 (-150)\".")
end)
RadioHealthValue:SetScript("OnLeave", HideTooltip)
RadioHealthValue:SetScript("OnClick", function() SetHealthDisplayMode("value") end)

local RadioHealthValueLabel = HM_CheckboxFrame:CreateFontString("HM_RadioHealthValueLabel", "OVERLAY", "GameFontNormal")
RadioHealthValueLabel:SetPoint("LEFT", RadioHealthValue, "RIGHT", 5, 0)
RadioHealthValueLabel:SetText("Value")

local RadioHealthPercent = CreateFrame("CheckButton", "HM_RadioHealthPercent", HM_CheckboxFrame, "UIRadioButtonTemplate")
RadioHealthPercent:SetWidth(CB_SIZE_SMALL)
RadioHealthPercent:SetHeight(CB_SIZE_SMALL)
RadioHealthPercent:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", IndentX, CheckboxTopY - 194)
RadioHealthPercent:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Show the current health percentage, e.g. \"850/1000 (85%)\".")
end)
RadioHealthPercent:SetScript("OnLeave", HideTooltip)
RadioHealthPercent:SetScript("OnClick", function() SetHealthDisplayMode("percent") end)

local RadioHealthPercentLabel = HM_CheckboxFrame:CreateFontString("HM_RadioHealthPercentLabel", "OVERLAY", "GameFontNormal")
RadioHealthPercentLabel:SetPoint("LEFT", RadioHealthPercent, "RIGHT", 5, 0)
RadioHealthPercentLabel:SetText("Percent")

local RadioHealthBoth = CreateFrame("CheckButton", "HM_RadioHealthBoth", HM_CheckboxFrame, "UIRadioButtonTemplate")
RadioHealthBoth:SetWidth(CB_SIZE_SMALL)
RadioHealthBoth:SetHeight(CB_SIZE_SMALL)
RadioHealthBoth:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", IndentX, CheckboxTopY - 216)
RadioHealthBoth:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Show both the missing amount and the percentage, e.g. \"850/1000 (-150, 85%)\".")
end)
RadioHealthBoth:SetScript("OnLeave", HideTooltip)
RadioHealthBoth:SetScript("OnClick", function() SetHealthDisplayMode("both") end)

local RadioHealthBothLabel = HM_CheckboxFrame:CreateFontString("HM_RadioHealthBothLabel", "OVERLAY", "GameFontNormal")
RadioHealthBothLabel:SetPoint("LEFT", RadioHealthBoth, "RIGHT", 5, 0)
RadioHealthBothLabel:SetText("Both")

-- ---- TARGETS: Friendly ----
local CheckboxFriendly = CreateFrame("CheckButton", "HM_CheckboxFriendly", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxFriendly:SetWidth(CB_SIZE)
CheckboxFriendly:SetHeight(CB_SIZE)
CheckboxFriendly:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col2X, CheckboxTopY - 150)
CheckboxFriendly:SetScript("OnClick", CheckboxShowFriendlyOnClick)

local CheckboxFriendlyLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxFriendlyLabel", "OVERLAY", "GameFontNormal")
CheckboxFriendlyLabel:SetPoint("LEFT", CheckboxFriendly, "RIGHT", 5, 0)
CheckboxFriendlyLabel:SetText("Friendly")

-- ---- TARGETS: Enemy ----
local CheckboxEnemy = CreateFrame("CheckButton", "HM_CheckboxEnemy", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxEnemy:SetWidth(CB_SIZE)
CheckboxEnemy:SetHeight(CB_SIZE)
CheckboxEnemy:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col2X, CheckboxTopY - 174)
CheckboxEnemy:SetScript("OnClick", CheckboxShowEnemyOnClick)

local CheckboxEnemyLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxEnemyLabel", "OVERLAY", "GameFontNormal")
CheckboxEnemyLabel:SetPoint("LEFT", CheckboxEnemy, "RIGHT", 5, 0)
CheckboxEnemyLabel:SetText("Enemy")

-- ========================================================================
-- ROW: Section header -- SCROLLING TEXT
-- ========================================================================
CreateSectionHeader("SCROLLING TEXT", CheckboxTopX, CheckboxTopY - 246)

-- ---- SCROLLING TEXT: Enable SCT (master toggle) ----
local CheckboxShowScrollingText = CreateFrame("CheckButton", "HM_CheckboxShowScrollingText", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxShowScrollingText:SetWidth(CB_SIZE)
CheckboxShowScrollingText:SetHeight(CB_SIZE)
CheckboxShowScrollingText:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", Col1X, CheckboxTopY - 268)
CheckboxShowScrollingText:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Check to show Damage and/or Healing taken on UI Frames.", "Note: You also need to check Damage and/or Healing to determine which to display.")
end)
CheckboxShowScrollingText:SetScript("OnLeave", HideTooltip)
CheckboxShowScrollingText:SetScript("OnClick", CheckboxShowScrollingTextOnClick)

local CheckboxShowScrollingTextLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxShowScrollingTextLabel", "OVERLAY", "GameFontNormal")
CheckboxShowScrollingTextLabel:SetPoint("LEFT", CheckboxShowScrollingText, "RIGHT", 5, 0)
CheckboxShowScrollingTextLabel:SetText("Enable SCT")

-- ---- SCROLLING TEXT: Damage (indented sub-option) ----
local CheckboxShowDamage = CreateFrame("CheckButton", "HM_CheckboxShowDamage", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxShowDamage:SetWidth(CB_SIZE)
CheckboxShowDamage:SetHeight(CB_SIZE)
CheckboxShowDamage:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", IndentX, CheckboxTopY - 291)
CheckboxShowDamage:SetScript("OnClick", CheckboxShowDamageOnClick)

local CheckboxShowDamageLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxShowDamageLabel", "OVERLAY", "GameFontNormal")
CheckboxShowDamageLabel:SetPoint("LEFT", CheckboxShowDamage, "RIGHT", 5, 0)
CheckboxShowDamageLabel:SetText("Damage")

-- ---- SCROLLING TEXT: Healing (indented sub-option) ----
local CheckboxShowHeal = CreateFrame("CheckButton", "HM_CheckboxShowHeal", HM_CheckboxFrame, "UICheckButtonTemplate")
CheckboxShowHeal:SetWidth(CB_SIZE)
CheckboxShowHeal:SetHeight(CB_SIZE)
CheckboxShowHeal:SetPoint("TOPLEFT", HM_CheckboxFrame, "TOPLEFT", IndentX, CheckboxTopY - 314)
CheckboxShowHeal:SetScript("OnClick", CheckboxShowHealOnClick)

local CheckboxShowHealLabel = HM_CheckboxFrame:CreateFontString("HM_CheckboxHealLabel", "OVERLAY", "GameFontNormal")
CheckboxShowHealLabel:SetPoint("LEFT", CheckboxShowHeal, "RIGHT", 5, 0)
CheckboxShowHealLabel:SetText("Healing")

--END-- checkboxFrame Contents


--#########################################################################################################
-- END - Create Settings UI
--#########################################################################################################





--#########################################################################################################
--#########################################################################################################

--## START ## Create Main Healing Interfaces UI

-- NOTE: This used to contain a manually-built "PlayerContainer" frame (plus a
-- "playerName" fontstring and a "SETTINGS" button on it) created here at
-- load time, anchored to screen CENTER. It was already obsolete by the time
-- it rendered: InitializeFrames() (run later, on ADDON_LOADED) overwrites
-- the global PlayerContainer with the real one built by HM_CreateUnitFrame.
-- The frame built here never got hidden, though, so it just sat at screen
-- center forever with nothing meaningful attached to it -- including that
-- floating "SETTINGS" button, which is why it looked like an orphaned,
-- unparented panel. Removed entirely; see the slash command below for how
-- to open the settings now.

-- Open/close the settings window with a slash command instead of a button
-- floating on the player frame.
SLASH_HEALERSMATE1 = "/hm"
SLASH_HEALERSMATE2 = "/healersmate"
SLASH_HMDRAGRESET1 = "/hmdrag"

SlashCmdList["HEALERSMATE"] = function()
    if HM_SettingsContainer then
        if HM_SettingsContainer:IsVisible() then
            HM_SettingsContainer:Hide()
        else
            HM_SettingsContainer:Show()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000HealersMate Error:|r HM_SettingsContainer frame could not be found.")
    end
end

SlashCmdList["HMDRAGRESET"] = function()
    for _, frame in ipairs({
        PlayerContainer,
        Party1Container,
        Party2Container,
        Party3Container,
        Party4Container,
        TargetContainer
    }) do
        if frame then
            frame.isMoving = false
            frame:StopMovingOrSizing()
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage("HealersMate drag state reset.")
end

-- ========================================================================
-- SECURE CLICK-CAST SPELL BINDING SYSTEM
-- ========================================================================
-- IMPORTANT: We never call CastSpellByName() from a plain Lua OnClick handler.
-- That's a protected function and gets silently blocked (this is the bug that
-- started this whole investigation). Instead, each unit's button is created
-- from "SecureActionButtonTemplate" and we hand Blizzard's secure header code
-- a set of attributes (type#/spell#) describing what to cast. Blizzard's own
-- C code performs the cast the instant a real mouse click happens, which is
-- allowed because it isn't Lua calling the protected function directly.
--
-- Attribute button numbers: 1 = Left-Click, 2 = Right-Click, 3 = Middle-Click
-- Modifier prefixes: "shift-" / "ctrl-" go in front of the attribute name,
-- e.g. "shift-type1" / "shift-spell1" for Shift+Left-Click.

local CLICK_BINDINGS = {
    -- { attribute button number, modifier prefix, saved variable name }
    { 1, "",      "LeftClickSpell" },
    { 2, "",      "RightClickSpell" },
    { 3, "",      "MiddleClickSpell" },
    { 1, "shift", "ShiftLeftClickSpell" },
    { 2, "shift", "ShiftRightClickSpell" },
    { 3, "shift", "ShiftMiddleClickSpell" },
    { 1, "ctrl",  "ControlLeftClickSpell" },
    { 2, "ctrl",  "ControlRightClickSpell" },
    { 3, "ctrl",  "ControlMiddleClickSpell" },
}

-- If a bound "spell name" is actually one of these keywords (case-insensitive,
-- whitespace-trimmed), it's treated as a secure action instead of a spell
-- cast. All of these are legal secure "type" attribute values that Blizzard's
-- secure header code performs directly -- no CastSpellByName() or macro
-- needed. Add more keywords here any time you want to support another
-- special case.
local SPECIAL_ACTIONS = {
    -- Direct Actions (Type: ActionName)
    ["target"]      = { type = "target" },
    ["follow"]      = { type = "macro",   macro = "/target %u\n/follow" },
    ["assist"]      = { type = "assist" },
    ["focus"]       = { type = "focus" },
    ["clearfocus"]  = { type = "clearfocus" },
    ["menu"]        = { type = "menu" },
    ["stopcasting"] = { type = "stopcasting" },
    ["stopattack"]  = { type = "stopattack" },
    ["pettarget"]   = { type = "pettarget" },
	["joke"]      = { type = "macro",   macro = "/silly" }, --example, run macro
    
    -- Macro-based Actions
    ["selfcast"]    = { type = "macro",   macro = "/cast [@player] %s" },
    ["token"]       = { type = "macro",   macro = "/use %s" } 
}

function HM_ApplyClickBindings(secureBtn, unitId)
    if not secureBtn then return end
    secureBtn:SetAttribute("unit", unitId)

    for _, bind in ipairs(CLICK_BINDINGS) do
        local buttonNum, modPrefix, varName = bind[1], bind[2], bind[3]
        local prefix = (modPrefix ~= "") and (modPrefix .. "-") or ""
        local spellName = _G[varName] or ""
        local trimmed = strtrim(tostring(spellName)):lower()
        local action = SPECIAL_ACTIONS[trimmed]

        if action then
            -- Handle Special Actions (Target, Follow, Macro, etc)
            secureBtn:SetAttribute(prefix .. "type" .. buttonNum, action.type)
            secureBtn:SetAttribute(prefix .. "unit" .. buttonNum, unitId)
            
            if action.type == "macro" then
                -- Replace placeholder %u with unitId, %s with spellName
                local m = string.gsub(action.macro, "%%u", unitId)
                m = string.gsub(m, "%%s", spellName)
                secureBtn:SetAttribute(prefix .. "macrotext" .. buttonNum, m)
            else
                secureBtn:SetAttribute(prefix .. "macrotext" .. buttonNum, nil)
            end
            secureBtn:SetAttribute(prefix .. "spell" .. buttonNum, nil)
            
        elseif spellName ~= "" then
            -- Handle standard spells
            secureBtn:SetAttribute(prefix .. "type" .. buttonNum, "spell")
            secureBtn:SetAttribute(prefix .. "spell" .. buttonNum, spellName)
            secureBtn:SetAttribute(prefix .. "unit" .. buttonNum, unitId)
        else
            -- Clear empty bindings
            secureBtn:SetAttribute(prefix .. "type" .. buttonNum, nil)
        end
    end
end

-- Re-applies bindings to every unit frame's button. Call this after the
-- player changes a spell name in the settings UI, or after login.
function HM_RefreshAllSpellBindings()
    local units = { "player", "party1", "party2", "party3", "party4", "target" }
    for _, unitId in ipairs(units) do
        local btn = UI_Components and UI_Components[unitId .. "_CastSpellButton"]
        if btn then
            HM_ApplyClickBindings(btn, unitId)
        end
    end
end

-- ========================================================================
-- CLICK-BINDING TOOLTIP
-- ========================================================================
-- Shows a tooltip (Settings > Checkboxes > "Show Click Bindings Tooltip")
-- listing which click types have a spell bound, and to what. Click bindings
-- are the same global set applied to every unit frame (see CLICK_BINDINGS
-- above), so this doesn't need to know which unit's health bar it's on.
local CLICK_LABELS = { [1] = "Left-Click", [2] = "Right-Click", [3] = "Middle-Click" }
local CLICK_MOD_LABELS = { [""] = "", ["shift"] = "Shift + ", ["ctrl"] = "Ctrl + " }

function HM_ShowClickBindingTooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText("Click Bindings", 1, 0.82, 0)

    local anyBound = false
    for _, bind in ipairs(CLICK_BINDINGS) do
        local buttonNum, modPrefix, varName = bind[1], bind[2], bind[3]
        local spellName = _G[varName]
        if spellName and spellName ~= "" then
            anyBound = true
            local label = (CLICK_MOD_LABELS[modPrefix] or "") .. (CLICK_LABELS[buttonNum] or ("Button" .. buttonNum))
            GameTooltip:AddLine(label .. ":  " .. tostring(spellName), 1, 1, 1)
        end
    end

    if not anyBound then
        GameTooltip:AddLine("No spells bound", 0.7, 0.7, 0.7)
    end

    GameTooltip:Show()
end

-- ========================================================================
-- FRAME LAYOUT (Show Energy Bar / Show Buffs + height recalculation)
-- ========================================================================
-- Applies the Show Energy Bar / Show Buffs settings to one unit frame
-- (hides/shows the relevant panel, re-anchors the buff panel under whichever
-- element is now the last visible one, and recalculates the container's
-- overall height) -- the single source of truth for frame height, used both
-- at frame creation and every time auras update or these settings change.
-- Show()/Hide() on these containers face the identical restriction as
-- SetHeight() (see HM_RecalculateFrameLayout below) -- they have a secure
-- click-to-cast child, so Blizzard blocks visibility changes on them for the
-- whole time you're in combat. This wraps that check once: skip and
-- remember the desired state if in combat, apply immediately otherwise.
-- Pending states get caught up on PLAYER_REGEN_ENABLED (combat end).
HM_PendingVisibility = HM_PendingVisibility or {}

function HM_SafeSetShown(frame, shouldShow, key)
    if not frame then return end
    if InCombatLockdown() then
        HM_PendingVisibility[key or frame] = { frame = frame, shouldShow = shouldShow }
        return
    end
    if shouldShow then frame:Show() else frame:Hide() end
end

function HM_RecalculateFrameLayout(unitId)
    local camelKey = unitId:sub(1,1):upper() .. unitId:sub(2)
    local container  = _G[camelKey .. "Container"]
    local nameString = _G[camelKey .. "Name"]
    local healthBar  = _G[camelKey .. "StatusBar"]
    local powerBar   = _G[camelKey .. "PowerStatusBar"]
    local buffPanel  = _G[camelKey .. "BuffPanel"]

    if not (container and nameString and healthBar) then return end

    local showPower = (ShowPowerBar ~= "false") -- default true
    local showBuffs = (ShowBuffs ~= "false")    -- default true

    if powerBar then
        if showPower then powerBar:Show() else powerBar:Hide() end
    end
    if buffPanel then
        if showBuffs then buffPanel:Show() else buffPanel:Hide() end
    end

    -- Re-anchor the buff panel to whichever element above it is currently
    -- visible (power bar if shown, otherwise straight under the health bar).
    if buffPanel then
        buffPanel:ClearAllPoints()
        if powerBar and showPower then
            buffPanel:SetPoint("TOPLEFT", powerBar, "BOTTOMLEFT", 0, -4)
        else
            buffPanel:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -2)
        end
    end

    local naturalHeight = 6                             -- Name padding top
                 + nameString:GetHeight()
                 + (24 - nameString:GetHeight())         -- Gap offset to health bar
                 + healthBar:GetHeight()

    if showPower and powerBar then
        naturalHeight = naturalHeight + 2 + powerBar:GetHeight()
    end

    if showBuffs and buffPanel then
        naturalHeight = naturalHeight + 4 + buffPanel:GetHeight()
    end

    naturalHeight = naturalHeight + 8 -- Bottom buffer boundary margin

    -- IMPORTANT: this container has a SecureActionButtonTemplate child (the
    -- click-to-cast button), so Blizzard treats SetHeight() on the container
    -- itself as restricted for the entire time you're in combat -- not just
    -- for a brief moment after whatever triggered this update. There's no
    -- "wait a little and try again" that helps here as long as combat is
    -- still ongoing, which is almost always true exactly when buffs are
    -- actively changing size. So: skip the resize while in combat (buff
    -- icons themselves still update fine, they just may visually extend a
    -- little past the frame's border/background until this catches up) and
    -- remember to redo it the instant combat ends -- see the
    -- PLAYER_REGEN_ENABLED handler, which calls HM_RefreshAllAuraLayout().
    if InCombatLockdown() then
        HM_PendingLayoutUnits = HM_PendingLayoutUnits or {}
        HM_PendingLayoutUnits[unitId] = true
        return
    end

    -- If "Use Custom Height" is on, respect it -- but never let it shrink
    -- below naturalHeight, or the buff panel (and everything else) would
    -- render outside the container's visible background/border. This is the
    -- single place custom height gets applied now (HM_ApplyFrameAppearance
    -- used to also apply it separately afterward with no such floor, which
    -- is what let a too-small custom height cause the overflow).
    if FrameCustomHeight == "true" then
        local customHeight = tonumber(FrameHeightValue) or 150
        container:SetHeight(math.max(customHeight, naturalHeight))
    else
        container:SetHeight(naturalHeight)
    end
end

-- ========================================================================
-- SNAP-DOCKING FOR UNIT FRAMES
-- ========================================================================
-- When the player drops a frame near another unit frame's edge (on either
-- axis, independently), it snaps flush against it instead of being left a
-- few pixels off. Distance is checked separately for the horizontal (left/
-- right edges) and vertical (top/bottom edges) axes, so you can dock two
-- frames side-by-side, stacked, or both at once against different frames.
local SNAP_DISTANCE = 14 -- pixels

local function HM_GetDockableFrames(exclude)
    local frames = {}
    for _, f in ipairs({ PlayerContainer, Party1Container, Party2Container, Party3Container, Party4Container, TargetContainer }) do
        if f and f ~= exclude and f:IsShown() then
            table.insert(frames, f)
        end
    end
    return frames
end

-- Checks whether `frame` is currently anchored, directly or indirectly, to
-- `potentialAncestor` -- by walking its REAL anchor chain via GetPoint(),
-- not just our own .dockedTo bookkeeping. This matters because every unit
-- frame's original anchor (set once at creation in HM_CreateUnitFrame, e.g.
-- Party1Container -> PlayerContainer, Party2Container -> Party1Container,
-- etc.) is a genuine WoW anchor dependency even though it was never "docked"
-- through our own drag system, so .dockedTo alone can't see it. Anchoring a
-- frame to something that's (directly or indirectly) anchored to it is what
-- WoW's UI engine hard-errors on with "X is dependent on this".
local function HM_IsAnchoredTo(frame, potentialAncestor, depth)
    if not frame or not potentialAncestor then return false end
    depth = depth or 0
    if depth > 15 then return false end -- safety guard against runaway loops

    local numPoints = frame.GetNumPoints and frame:GetNumPoints() or 0
    for i = 1, numPoints do
        local _, relativeTo = frame:GetPoint(i)
        if relativeTo then
            if relativeTo == potentialAncestor then
                return true
            end
            if HM_IsAnchoredTo(relativeTo, potentialAncestor, depth + 1) then
                return true
            end
        end
    end
    return false
end

function HM_TrySnapContainer(movedFrame)
    if not movedFrame then return end

    local mLeft, mBottom = movedFrame:GetLeft(), movedFrame:GetBottom()
    if not mLeft or not mBottom then return end
    local mWidth, mHeight = movedFrame:GetWidth(), movedFrame:GetHeight()
    local mRight, mTop = mLeft + mWidth, mBottom + mHeight

    local newLeft, newBottom = mLeft, mBottom
    local bestXDist, bestYDist = SNAP_DISTANCE, SNAP_DISTANCE
    local xPartner, yPartner = nil, nil

    for _, other in ipairs(HM_GetDockableFrames(movedFrame)) do
        local oLeft, oBottom = other:GetLeft(), other:GetBottom()
        if oLeft and oBottom then
            local oWidth, oHeight = other:GetWidth(), other:GetHeight()
            local oRight, oTop = oLeft + oWidth, oBottom + oHeight

            -- Horizontal (X): align our left/right edge to their left/right edge
            local xTests = {
                { dist = math.abs(mLeft  - oLeft),  left = oLeft },
                { dist = math.abs(mLeft  - oRight), left = oRight },
                { dist = math.abs(mRight - oLeft),  left = oLeft - mWidth },
                { dist = math.abs(mRight - oRight), left = oRight - mWidth },
            }
            for _, t in ipairs(xTests) do
                if t.dist < bestXDist and not HM_IsAnchoredTo(other, movedFrame) then
                    bestXDist = t.dist
                    newLeft = t.left
                    xPartner = other
                end
            end

            -- Vertical (Y): align our top/bottom edge to their top/bottom edge
            local yTests = {
                { dist = math.abs(mBottom - oBottom), bottom = oBottom },
                { dist = math.abs(mBottom - oTop),    bottom = oTop },
                { dist = math.abs(mTop    - oBottom), bottom = oBottom - mHeight },
                { dist = math.abs(mTop    - oTop),    bottom = oTop - mHeight },
            }
            for _, t in ipairs(yTests) do
                if t.dist < bestYDist and not HM_IsAnchoredTo(other, movedFrame) then
                    bestYDist = t.dist
                    newBottom = t.bottom
                    yPartner = other
                end
            end
        end
    end

    -- Pick a single "dock partner" to parent to, so the docked frame follows
    -- that one frame around if it's moved later. If both axes snapped to the
    -- same frame, that's the obvious choice; if they snapped to different
    -- frames, prefer whichever produced the tighter (smaller-distance) snap.
    local dockPartner = nil
    if xPartner and yPartner then
        dockPartner = (xPartner == yPartner) and xPartner or ((bestXDist <= bestYDist) and xPartner or yPartner)
    else
        dockPartner = xPartner or yPartner
    end

    -- Final safety check
    if dockPartner and HM_IsAnchoredTo(dockPartner, movedFrame) then
        dockPartner = nil
    end

    movedFrame:ClearAllPoints()
    if dockPartner then
        -- Anchor relative to the dock partner (not UIParent) using the same
        -- snapped absolute position. This alone is what makes it "follow"
        -- the partner when the partner moves later -- WoW recalculates a
        -- frame's screen position from whatever it's anchored to every
        -- frame, regardless of the frame's actual Lua Parent. (We used to
        -- also call SetParent() here to literally reparent it, but that
        -- turned out to break being able to drop the frame on a later drag --
        -- removed, since it wasn't actually needed for the "follows the
        -- partner" behavior anyway.)
        local pLeft, pBottom = dockPartner:GetLeft(), dockPartner:GetBottom()
        movedFrame:SetPoint("BOTTOMLEFT", dockPartner, "BOTTOMLEFT", newLeft - pLeft, newBottom - pBottom)
        movedFrame.dockedTo = dockPartner
    else
        -- Nothing close enough to dock to: make sure it's tracked as a free,
        -- independent frame again (in case it was docked before this drag).
        movedFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", newLeft, newBottom)
        movedFrame.dockedTo = nil
    end
end

function HM_ReapplyAllDocking()
    local allFrames = {
        PlayerContainer, Party1Container, Party2Container,
        Party3Container, Party4Container, TargetContainer
    }
    
    -- First pass: clear any stale absolute positioning for docked frames
    for _, frame in ipairs(allFrames) do
        if frame and frame.dockedTo and frame:IsShown() then
            -- Temporarily detach to absolute coords so we can re-snap cleanly
            local curLeft, curBottom = frame:GetLeft(), frame:GetBottom()
            if curLeft and curBottom then
                frame:ClearAllPoints()
                frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", curLeft, curBottom)
            end
        end
    end
    
    -- Second pass: re-snap everything (order doesn't matter much because
    -- HM_TrySnapContainer already handles cycles and multiple docks)
    for _, frame in ipairs(allFrames) do
        if frame and frame.dockedTo then
            HM_TrySnapContainer(frame)
        end
    end
end

-- ========================================================================
-- TEXT-TO-WIDTH FITTING
-- ========================================================================
-- Shrinks a fontstring's font size just enough that its current text fits
-- within maxWidth, always starting from the fontstring's original/base font
-- size (cached as .baseFontPath/.baseFontSize/.baseFontFlags at creation
-- time) so repeated calls don't compound shrinkage. Used for the player
-- name+class label, which can otherwise run off narrow custom frame widths.
function HM_FitTextToWidth(fontString, maxWidth)
    if not fontString or not maxWidth or maxWidth <= 0 then return end

    local basePath, baseSize, baseFlags = fontString.baseFontPath, fontString.baseFontSize, fontString.baseFontFlags
    if not basePath or not baseSize then return end -- no cached baseline; nothing safe to do

    -- Always reset to the original size first so we're measuring/shrinking
    -- from a consistent baseline rather than an already-shrunk size.
    fontString:SetFont(basePath, baseSize, baseFlags)

    local textWidth = fontString:GetStringWidth()
    if not textWidth or textWidth <= maxWidth then return end -- fits already

    local MIN_FONT_SIZE = 7
    local scale = maxWidth / textWidth
    local newSize = math.max(MIN_FONT_SIZE, math.floor(baseSize * scale))
    fontString:SetFont(basePath, newSize, baseFlags)

    -- One corrective pass in case font metrics don't scale perfectly linearly
    if fontString:GetStringWidth() > maxWidth and newSize > MIN_FONT_SIZE then
        fontString:SetFont(basePath, newSize - 1, baseFlags)
    end
end

-- ========================================================================
-- FRAME APPEARANCE CUSTOMIZATION
-- ========================================================================
-- Applies the saved FrameWidth / FrameCustomHeight / FrameHeightValue /
-- FrameBGColorR-B / FrameBGAlpha settings to every unit frame container
-- (Player, Party1-4, Target). Safe to call any time -- e.g. live while a
-- settings slider is being dragged, or once at login.
function HM_ApplyFrameAppearance()
    -- Same restriction as HM_RecalculateFrameLayout: these containers have a
    -- secure click-to-cast child, so SetWidth() on them is treated the same
    -- way SetHeight() is -- restricted for the whole time you're in combat.
    -- Skip entirely and re-apply the instant combat ends instead of getting
    -- partially applied (colors updated but not size, etc.).
    if InCombatLockdown() then
        HM_AppearancePendingApply = true
        return
    end

    local width = tonumber(FrameWidth) or 200
    local r = tonumber(FrameBGColorR) or 1
    local g = tonumber(FrameBGColorG) or 1
    local b = tonumber(FrameBGColorB) or 1
    local a = tonumber(FrameBGAlpha) or 1
    local hideBG = (HideBackground == "true")
    local hideBorder = (HideBorder == "true")

    local units = { "player", "party1", "party2", "party3", "party4", "target" }
    for _, unitId in ipairs(units) do
	    local camelKey = unitId:sub(1,1):upper() .. unitId:sub(2)
        local container = _G[camelKey .. "Container"]
        local healthBar  = _G[camelKey .. "StatusBar"]
        local powerBar   = _G[camelKey .. "PowerStatusBar"]
        local buffPanel  = _G[camelKey .. "BuffPanel"]

        if container then
            container:SetWidth(width)
            if hideBG then
                container:SetBackdropColor(0, 0, 0, 0)
            else
                container:SetBackdropColor(r, g, b, a)
            end
            container:SetBackdropBorderColor(1, 1, 1, hideBorder and 0 or 1)

            -- Keep the health/power bars and buff panel matching the new
            -- width (minus the same 6px-per-side padding used elsewhere).
            local innerWidth = math.max(40, width - 12)
            if healthBar then healthBar:SetWidth(innerWidth) end
            if powerBar  then powerBar:SetWidth(innerWidth) end
            if buffPanel then buffPanel:SetWidth(innerWidth) end

            -- Re-fit the name+class label to the new width too.
            local nameString = _G[camelKey .. "Name"]
            if nameString and HM_FitTextToWidth and healthBar then
                HM_FitTextToWidth(nameString, healthBar:GetWidth())
            end
        end
    end

    -- Width changes affect how many buff/debuff icons fit per row, and thus
    -- the auto-calculated frame height -- recompute both for every frame
    -- (including hidden ones, so they're correct whenever they do appear).
    if HM_RefreshAllAuraLayout then HM_RefreshAllAuraLayout() end

    -- NEW: Re-dock any frames that were previously snapped together
    -- so they stay flush after width/height changes.
    if HM_ReapplyAllDocking then HM_ReapplyAllDocking() end
end


-- ========================================================================
-- STRUCTURAL UNIT FRAME FACTORY ENGINE
-- ========================================================================
function HM_CreateUnitFrame(unitId, displayName, relativeToFrame, defaultYOffset)
    -- 1. Format Naming Keys cleanly (e.g., "HM_Party1Container", "Party1Container")
    local camelKey = unitId:sub(1,1):upper() .. unitId:sub(2) -- "player" -> "Player", "party1" -> "Party1"
    local globalContainerName = "HM_" .. camelKey .. "Container"
    --Debug("globalContainerName: "..tostring(globalContainerName))
    -- 2. Build Core Frame Container
    local container = CreateFrame("Frame", globalContainerName, UIParent)
    container:SetWidth(200)
    container:SetHeight(150) -- Adjusted dynamically via calculation downstream
    container:EnableMouse(true)
    container:SetMovable(true)
    
    -- Setup Layout Position Constraints
    if unitId == "player" then
        container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -100) -- Clean screen entry point
    else
        container:SetPoint("TOPLEFT", relativeToFrame, "BOTTOMLEFT", 0, defaultYOffset or -10)
    end
    
    container:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    
    -- 3. Attach 3.3.5 Drag Scripts safely without global arg1 leaks
    container:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not self.isMoving then
            -- If this frame is currently docked to another frame, detach it
            -- the moment you pick it up again so it moves independently
            -- during this drag -- it'll only re-dock if you drop it near
            -- another frame's edge again (see HM_TrySnapContainer).
            if self.dockedTo then
                local curLeft, curBottom = self:GetLeft(), self:GetBottom()
                if curLeft and curBottom then
                    self:ClearAllPoints()
                    self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", curLeft, curBottom)
                end
                self.dockedTo = nil
            end

            self:StartMoving()
            self.isMoving = true
        end
    end)
	
	container:SetScript("OnHide", function(self)
		if self.isMoving then
			self:StopMovingOrSizing()
			self.isMoving = false
		end
	end)
	
	container:SetScript("OnShow", function(self)
		self.isMoving = false
	end)
	
    container:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self:StopMovingOrSizing()
            self.isMoving = false
            HM_TrySnapContainer(self)
        end
    end)
    
    -- 4. Append Unit Title Text Label
    local nameString = container:CreateFontString("HM_" .. camelKey .. "Name", "OVERLAY", "GameFontNormal")
    nameString:SetPoint("TOPLEFT", container, "TOPLEFT", 6, -6)
    nameString:SetText(displayName)
    -- Cache the original font so HM_FitTextToWidth always shrinks from this
    -- known baseline rather than compounding shrinkage update after update.
    local baseFontPath, baseFontSize, baseFontFlags = nameString:GetFont()
    nameString.baseFontPath  = baseFontPath
    nameString.baseFontSize  = baseFontSize
    nameString.baseFontFlags = baseFontFlags
    _G[camelKey .. "Name"] = nameString -- Backend tracking hook bridge
    
    -- 5. Construct Main Health Status Bar Layer
    local healthBar = CreateFrame("StatusBar", "HM_" .. camelKey .. "StatusBar", container)
    healthBar:SetWidth(188)
    healthBar:SetHeight(25)
    healthBar:SetPoint("TOPLEFT", container, "TOPLEFT", 6, -24)
    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    healthBar:SetMinMaxValues(0, 1)
    healthBar:SetValue(1)
    healthBar:SetStatusBarColor(0, 0.7529412, 0)
    
    local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
    healthBg:SetAllPoints(true)
    healthBg:SetTexture(0.1, 0.1, 0.1, 0.6)
    
    -- 6. Construct Power Status Bar Layer (Mana/Energy/Rage)
    local powerBar = CreateFrame("StatusBar", "HM_" .. camelKey .. "PowerStatusBar", container)
    powerBar:SetWidth(188)
    powerBar:SetHeight(8)
    powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -2)
    powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    powerBar:SetMinMaxValues(0, 1)
    powerBar:SetValue(1)
    powerBar:SetStatusBarColor(0, 0, 1)
    
    local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
    powerBg:SetAllPoints(true)
    powerBg:SetTexture(0, 0, 0, 0.6)
    
    -- 7. Overlay the Combat-Safe SecureActionButton Target Layer
    local secureBtn = CreateFrame("Button", "HM_" .. camelKey .. "Button", healthBar, "SecureActionButtonTemplate")
  
    -- Register clicks: 1 is Left, 2 is Right, 3 is Middle
    secureBtn:RegisterForClicks("AnyUp")

    -- Spell bindings come from the saved LeftClickSpell / RightClickSpell /
    -- MiddleClickSpell (and Shift-/Ctrl- variant) variables, applied via
    -- HM_ApplyClickBindings below (see the SECURE CLICK-CAST SPELL BINDING
    -- SYSTEM section above HM_CreateUnitFrame). This call also sets the
    -- "unit" attribute. Note: at this point in the load process the saved
    -- variables may not exist yet, so bindings are re-applied for real once
    -- settings are loaded in eventAddonLoaded() -> HM_RefreshAllSpellBindings().
    HM_ApplyClickBindings(secureBtn, unitId)

    -- Set the look and feel
    secureBtn:SetAllPoints(healthBar)
    secureBtn:SetNormalFontObject("GameFontHighlight")
    secureBtn:SetText("0/0")

    -- Optional tooltip (Settings > Checkboxes > "Show Click Bindings
    -- Tooltip") listing which click types have spells bound, and to what.
    -- Click bindings are the same global set for every unit frame, so this
    -- doesn't need any unit-specific data.
    secureBtn:SetScript("OnEnter", function(self)
        if ShowClickTooltip == "true" and HM_ShowClickBindingTooltip then
            HM_ShowClickBindingTooltip(self)
        end
    end)
    secureBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- 8. Append Aura Buff Panel Display Base
    local buffPanel = CreateFrame("Frame", "HM_" .. camelKey .. "BuffPanel", container)
    buffPanel:SetWidth(188)
    buffPanel:SetHeight(25)
    buffPanel:SetPoint("TOPLEFT", powerBar, "BOTTOMLEFT", 0, -4)
    buffPanel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        --edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- Show a Border around buffs
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    buffPanel:SetBackdropColor(0, 0, 0, 0)
    
    -- 9. Complete Core Structural Height Grid Calculations
    -- (also applies the Show Energy Bar / Show Buffs settings -- see
    -- HM_RecalculateFrameLayout near HM_ApplyClickBindings)
    _G[camelKey .. "Container"]      = container
    _G[camelKey .. "StatusBar"]      = healthBar
    _G[camelKey .. "PowerStatusBar"] = powerBar
    _G[camelKey .. "Button"]         = secureBtn
    _G[camelKey .. "BuffPanel"]      = buffPanel
    if HM_RecalculateFrameLayout then
        HM_RecalculateFrameLayout(unitId)
    else
        -- Fallback in case this ever runs before HM_RecalculateFrameLayout
        -- is defined (shouldn't happen at actual runtime, only if this
        -- function were somehow called from top-level load code).
        local exactCalculatedHeight = 6
                                    + nameString:GetHeight()
                                    + (24 - nameString:GetHeight())
                                    + healthBar:GetHeight()
                                    + 2
                                    + powerBar:GetHeight()
                                    + 4
                                    + buffPanel:GetHeight()
                                    + 8
        container:SetHeight(exactCalculatedHeight)
    end
    
    -- 10. Expose to Global Variables to map into your addon's backend tracking engine smoothly
	-- Ensure the table exists globally
    if not UI_Components then UI_Components = {} end

    -- Populate the table so UpdateHealthValues can find the frames
    UI_Components[unitId .. "_PlayerName"] = nameString
    UI_Components[unitId .. "_CastSpellButton"] = secureBtn
    UI_Components[unitId .. "_HealthBar"] = healthBar
    UI_Components[unitId .. "_PowerBar"] = powerBar
	
    return container
end


--## START ## Scrolling Text Frames & Component Registry Automation

local UI_Components = {}
local units = {"player", "party1", "party2", "party3", "party4", "target"}

for _, unit in ipairs(units) do
    -- 1. Format names for namespace safety strings (e.g., "party1" -> "Party1")
    local camelUnit = unit:gsub("^%l", string.upper)
    
    -- 2. Safely locate parent containers using global string matching
    local parentContainer = _G["HM_"..camelUnit.."Container"] or _G[camelUnit.."Container"] or UIParent

    -- ========================================================================
    -- DAMAGE SCROLLING FRAME GENERATION
    -- ========================================================================
    local dmgFrame = CreateFrame("Frame", "HM_"..camelUnit.."ScrollingDamageFrame", parentContainer)
    dmgFrame:SetWidth(100)
    dmgFrame:SetHeight(20)
    -- Anchored to the left side of its respective unit container
    dmgFrame:SetPoint("CENTER", parentContainer, "CENTER", -35, 10)
    dmgFrame:SetFrameLevel(100)
    dmgFrame:Hide()
    
    dmgFrame.text = dmgFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dmgFrame.text:SetPoint("CENTER", 0, 0)
    dmgFrame.text:SetTextColor(1, 0.1, 0.1) -- Optional visual aid: Default red text for damage
    
    -- ========================================================================
    -- HEAL SCROLLING FRAME GENERATION
    -- ========================================================================
    local healFrame = CreateFrame("Frame", "HM_"..camelUnit.."ScrollingHealFrame", parentContainer)
    healFrame:SetWidth(100)
    healFrame:SetHeight(20)
    -- Anchored to the right side of its respective unit container to avoid overlapping numbers
    healFrame:SetPoint("CENTER", parentContainer, "CENTER", 35, 10)
    healFrame:SetFrameLevel(100)
    healFrame:Hide()
    
    healFrame.text = healFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    healFrame.text:SetPoint("CENTER", 0, 0)
    healFrame.text:SetTextColor(0.1, 1, 0.1) -- Optional visual aid: Default green text for healing

    -- ========================================================================
    -- SYSTEM AUTOMATED REGISTRY ARRAY MAPPING
    -- ========================================================================
    -- Maps scrolling assets instantly inside the tracking table indices
    UI_Components[unit.."_ScrollingDamageFrame"] = dmgFrame
    UI_Components[unit.."_ScrollingHealFrame"]   = healFrame
    
    -- Dynamically looks up and registers the core frame assets created earlier
    UI_Components[unit.."_PlayerName"]       = _G["HM_"..camelUnit.."Name"] or _G[camelUnit.."Name"] or _G[unit.."Name"]
    UI_Components[unit.."_CastSpellButton"]  = _G["HM_"..camelUnit.."Button"] or _G[camelUnit.."Button"]
    UI_Components[unit.."_HealthBar"]        = _G["HM_"..camelUnit.."StatusBar"] or _G[camelUnit.."StatusBar"]
    UI_Components[unit.."_PowerBar"]         = _G["HM_"..camelUnit.."PowerStatusBar"] or _G[camelUnit.."PowerStatusBar"]
end

-- Safely expose your component array globally for addon event logic parsing
_G["UI_Components"] = UI_Components

--## END ## Scrolling Text Frames & Component Registry Automation


	
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

local framesInitialized = false

function InitializeFrames()
    if framesInitialized then return end -- Stop if we already did this
    
   -- Create Player Base
    PlayerContainer = HM_CreateUnitFrame("player", "Player")
	TargetContainer = HM_CreateUnitFrame("target", "Target", PlayerContainer, -20)
    -- Hide it initially if you don't want it shown unless a target exists
    TargetContainer:Hide()
    
	-- Cascade Party Frames down cleanly
    Party1Container = HM_CreateUnitFrame("party1", "Party 1", PlayerContainer, -10)
    Party2Container = HM_CreateUnitFrame("party2", "Party 2", Party1Container, -10)
    Party3Container = HM_CreateUnitFrame("party3", "Party 3", Party2Container, -10)
    Party4Container = HM_CreateUnitFrame("party4", "Party 4", Party3Container, -10)
 
    framesInitialized = true
end

function eventAddonLoaded()
    --## Initialize Addon here. ##
--## Initialize Addon here. ##
    

    --## START ## Create Default Values for Settings if Addon has never ran before.
    if FreshInstall == nil then
        -- CRITICAL FIX: UnitClass() returns the capitalized Localized name first ("Priest"), 
        -- and the uppercase English token second ("PRIEST"). Checked against englishClass here.
        local _, englishClass = UnitClass("player") 
        
        if englishClass == "Chronomancer" then
            LeftClickSpell = "Reverse Wound"
            MiddleClickSpell = "Accelerated Recovery"
            
        elseif englishClass == "DRUID" then
            LeftClickSpell = "Healing Touch"
            MiddleClickSpell = ""
        else
            LeftClickSpell = ""
            MiddleClickSpell = ""
        end
        
        -- Default assignments for baseline settings profile tracking
        RightClickSpell = RightClickSpell or ""
        ShiftLeftClickSpell = ShiftLeftClickSpell or ""
        ShiftMiddleClickSpell = ShiftMiddleClickSpell or ""
        ShiftRightClickSpell = ShiftRightClickSpell or ""
        ControlLeftClickSpell = ControlLeftClickSpell or ""
        ControlMiddleClickSpell = ControlMiddleClickSpell or ""
        ControlRightClickSpell = ControlRightClickSpell or ""

        ShowMinusValue = "true"
        ShowPercentageHealth = "false"
        ShowHealthValue = "true"
        HealthDisplayMode = "value"
        ShowScrollingText = "false"
        ShowTargetUI = "false"
        ShowDamage = "false"
        ShowHeal = "false"
        ShowTargetFriendly = "false"
        ShowTargetEnemy = "false"

        ShowClass = "true"
        ColorNameByClass = "false"
        ShowPowerBar = "true"
        ShowBuffs = "true"
        ShowClickTooltip = "false"

        -- NEW defaults
        HideBackground = "false"
        PlayerOnlyBuffs = "false"
        HideBorder = "false"

        FrameWidth = 200
        FrameCustomHeight = "false"
        FrameHeightValue = 150
        FrameBGColorR = 1
        FrameBGColorG = 1
        FrameBGColorB = 1
        FrameBGAlpha = 1
    
        FreshInstall = false
    end
    
    -- Backward compatibility safeguard layer for legacy upgrades
    if (ShowMinusValue == nil or ShowMinusValue == "") and (ShowPercentageHealth == nil or ShowPercentageHealth == "") then 
        ShowMinusValue = "true"
        ShowPercentageHealth = "false"
    end 

    -- Backward compatibility: characters that installed the addon before the
    -- Frame Appearance section existed won't have these set (FreshInstall was
    -- already false for them, so the block above never ran for these vars).
    if FrameWidth == nil then FrameWidth = 200 end
    if FrameCustomHeight == nil then FrameCustomHeight = "false" end
    if FrameHeightValue == nil then FrameHeightValue = 150 end
    if FrameBGColorR == nil then FrameBGColorR = 1 end
    if FrameBGColorG == nil then FrameBGColorG = 1 end
    if FrameBGColorB == nil then FrameBGColorB = 1 end
    if FrameBGAlpha == nil then FrameBGAlpha = 1 end

    -- Backward compatibility: same idea, for characters that installed before
    -- these display-toggle settings existed.
    if ShowClass == nil then ShowClass = "true" end
    if ColorNameByClass == nil then ColorNameByClass = "false" end
    if ShowPowerBar == nil then ShowPowerBar = "true" end
    if ShowBuffs == nil then ShowBuffs = "true" end
    if ShowClickTooltip == nil then ShowClickTooltip = "false" end
    
    -- NEW backward compatibility
    if HideBackground == nil then HideBackground = "false" end
    if PlayerOnlyBuffs == nil then PlayerOnlyBuffs = "false" end
    if HideBorder == nil then HideBorder = "false" end
    --## END ## Create Default Values for Settings
    
    
	
	
    --## START ## Fill in Setting textboxes with appropriate data.
    local textboxes = {
        { control = TxtLeftClick,         value = LeftClickSpell },
        { control = TxtMiddleClick,       value = MiddleClickSpell },
        { control = TxtRightClick,        value = RightClickSpell },
        { control = TxtShiftLeftClick,    value = ShiftLeftClickSpell },
        { control = TxtShiftMiddleClick,  value = ShiftMiddleClickSpell },
        { control = TxtShiftRightClick,   value = ShiftRightClickSpell },
        { control = TxtCtrlLeftClick,     value = ControlLeftClickSpell },
        { control = TxtCtrlMiddleClick,   value = ControlMiddleClickSpell },
        { control = TxtCtrlRightClick,    value = ControlRightClickSpell },
    }
    
    for _, item in ipairs(textboxes) do
        if item.value then item.control:SetText(item.value) end
    end
    --## END ## Fill in Setting textboxes with appropriate data.


    --## START ## - ScrollingText Checkboxes
    -- CRITICAL BUG FIX: Replaced evaluation "false" or "" syntax error blocks with explicit matching checks
    if ShowScrollingText == "true" then
        HM_CheckboxShowScrollingText:SetChecked(true)
        HM_CheckboxShowDamage:Enable()
        HM_CheckboxShowHeal:Enable()
        HM_CheckboxShowDamageLabel:SetTextColor(1, 0.82, 0)
        HM_CheckboxHealLabel:SetTextColor(1, 0.82, 0)
    else
        HM_CheckboxShowScrollingText:SetChecked(false)
        HM_CheckboxShowDamage:Disable()
        HM_CheckboxShowHeal:Disable()
        HM_CheckboxShowDamageLabel:SetTextColor(0.5, 0.5, 0.5)  -- Disabled Gray
        HM_CheckboxHealLabel:SetTextColor(0.5, 0.5, 0.5)   -- Disabled Gray
    end
    
    HM_CheckboxShowDamage:SetChecked(ShowDamage == "true")
    HM_CheckboxShowHeal:SetChecked(ShowHeal == "true")
    --## END ## - ScrollingText Checkboxes


    --## START ## - Target Checkboxes
    if ShowTargetUI == "true" then
        HM_CheckboxShowTarget:SetChecked(true)
        HM_CheckboxFriendly:Enable()
        HM_CheckboxEnemy:Enable()
        HM_CheckboxFriendlyLabel:SetTextColor(1, 0.82, 0)
        HM_CheckboxEnemyLabel:SetTextColor(1, 0.82, 0)
    else
        HM_CheckboxShowTarget:SetChecked(false)
        HM_CheckboxFriendly:Disable()
        HM_CheckboxEnemy:Disable()
        HM_CheckboxFriendlyLabel:SetTextColor(0.5, 0.5, 0.5)   -- Disabled Gray
        HM_CheckboxEnemyLabel:SetTextColor(0.5, 0.5, 0.5)      -- Disabled Gray
    end
    --Debug("[eventAddonLoaded()](ShowTargetFriendly) : "..tostring(ShowTargetFriendly) )
	--Debug("[eventAddonLoaded()](ShowTargetEnemy) : "..tostring(ShowTargetEnemy) )
    HM_CheckboxFriendly:SetChecked(ShowTargetFriendly == "true")
    HM_CheckboxEnemy:SetChecked(ShowTargetEnemy == "true")
    --## END ## - Target Checkboxes
    
    
    --## START ## - Set Health Text Checkboxes
    -- One-time migration: if this character has old ShowMinusValue/
    -- ShowPercentageHealth values from before this settings redesign, but no
    -- HealthDisplayMode yet, translate them across instead of silently
    -- resetting to the default.
    if HealthDisplayMode == nil then
        if ShowPercentageHealth == "true" then
            HealthDisplayMode = "percent"
        else
            HealthDisplayMode = "value"
        end
    end
    if ShowHealthValue == nil then ShowHealthValue = "true" end

    if HM_CheckboxShowHealthValue then HM_CheckboxShowHealthValue:SetChecked(ShowHealthValue == "true") end

    local healthRadios = { HM_RadioHealthValue, HM_RadioHealthPercent, HM_RadioHealthBoth }
    for _, radio in ipairs(healthRadios) do
        if radio then
            if ShowHealthValue == "true" then radio:Enable() else radio:Disable() end
        end
    end
    if HM_RadioHealthValue   then HM_RadioHealthValue:SetChecked(HealthDisplayMode == "value") end
    if HM_RadioHealthPercent then HM_RadioHealthPercent:SetChecked(HealthDisplayMode == "percent") end
    if HM_RadioHealthBoth    then HM_RadioHealthBoth:SetChecked(HealthDisplayMode == "both") end
    --## END ## - Set Health Text Checkboxes

    --## START ## - New Display Toggle Checkboxes
    if HM_CheckboxShowClass then HM_CheckboxShowClass:SetChecked(ShowClass == "true") end
    if HM_CheckboxColorNameByClass then HM_CheckboxColorNameByClass:SetChecked(ColorNameByClass == "true") end
    if HM_CheckboxShowPowerBar then HM_CheckboxShowPowerBar:SetChecked(ShowPowerBar == "true") end
    if HM_CheckboxShowBuffs then HM_CheckboxShowBuffs:SetChecked(ShowBuffs == "true") end
    if HM_CheckboxShowClickTooltip then HM_CheckboxShowClickTooltip:SetChecked(ShowClickTooltip == "true") end
    
    -- NEW checkboxes
    if HM_CheckboxHideBackground then HM_CheckboxHideBackground:SetChecked(HideBackground == "true") end
    if HM_CheckboxPlayerOnlyBuffs then HM_CheckboxPlayerOnlyBuffs:SetChecked(PlayerOnlyBuffs == "true") end
    if HM_CheckboxHideBorder then HM_CheckboxHideBorder:SetChecked(HideBorder == "true") end
    
    if HM_RefreshAllAuraLayout then HM_RefreshAllAuraLayout() end
    if Check4Group then Check4Group() end
    --## END ## - New Display Toggle Checkboxes

    -- Bind click spells to secure buttons
    -- (frames already exist by now: InitializeFrames() runs on ADDON_LOADED
    -- before this function is called)
    HM_RefreshAllSpellBindings()

    --## START ## - Frame Appearance controls
    if HM_FrameWidthSlider then HM_FrameWidthSlider:SetValue(tonumber(FrameWidth) or 200) end
    if HM_FrameHeightSlider then HM_FrameHeightSlider:SetValue(tonumber(FrameHeightValue) or 150) end
    if HM_FrameAlphaSlider then HM_FrameAlphaSlider:SetValue(math.floor(((tonumber(FrameBGAlpha) or 1) * 100) + 0.5)) end
    if HM_CheckboxCustomHeight then
        local customHeightOn = (FrameCustomHeight == "true")
        HM_CheckboxCustomHeight:SetChecked(customHeightOn)
        if HM_FrameHeightSlider then
            if customHeightOn then HM_FrameHeightSlider:Enable() else HM_FrameHeightSlider:Disable() end
        end
    end
    if HM_FrameColorButton and HM_FrameColorButton.swatchTex then
        HM_FrameColorButton.swatchTex:SetTexture(tonumber(FrameBGColorR) or 1, tonumber(FrameBGColorG) or 1, tonumber(FrameBGColorB) or 1)
    end
    if HM_ApplyFrameAppearance then HM_ApplyFrameAppearance() end
    --## END ## - Frame Appearance controls
DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[HealersMate]|r |cff00ff00Loaded Successfully!|r Configure with |cffffff00/hm|r or |cffffff00/healersmate|r")
end

local function eventPlayerLogout()
    --## START ## Save Settings
    -- Consolidated into an array loop to keep code structure uniform with eventAddonLoaded
    local saveMappings = {
        { control = TxtLeftClick,         varName = "LeftClickSpell" },
        { control = TxtMiddleClick,       varName = "MiddleClickSpell" },
        { control = TxtRightClick,        varName = "RightClickSpell" },
        { control = TxtShiftLeftClick,    varName = "ShiftLeftClickSpell" },
        { control = TxtShiftMiddleClick,  varName = "ShiftMiddleClickSpell" },
        { control = TxtShiftRightClick,   varName = "ShiftRightClickSpell" },
        { control = TxtCtrlLeftClick,     varName = "ControlLeftClickSpell" },
        { control = TxtCtrlMiddleClick,   varName = "ControlMiddleClickSpell" },
        { control = TxtCtrlRightClick,    varName = "ControlRightClickSpell" },
    }
    
    for _, item in ipairs(saveMappings) do
        if item.control then
            _G[item.varName] = tostring(item.control:GetText() or "")
        end
    end
    --## END ## Save Settings
end


--##########################################################################
--##########################################################################

function GetClassColor(unitOrClass)
    -- This now accepts an English class string ("PRIEST") OR a unit ID ("party1").
    local classToken = unitOrClass
    if UnitExists(unitOrClass) then
        _, classToken = UnitClass(unitOrClass)
    end
    
    -- Fallback to default white if class token is missing/invalid
    local color = RAID_CLASS_COLORS[classToken]
    if color then
        return color.r, color.g, color.b
    else
        return 1.0, 1.0, 1.0
    end
end


--##########################################################################
--##########################################################################

local function ShowAnimatedTextDownward(ParentTarget, text, xOffset, yOffset, color)
    -- ParentTarget must contain the custom text frame object passed to it.
    if not ParentTarget or not ParentTarget.text then return end
    
    local totalDistance = 15 
    local duration = 1
    local speed = totalDistance / duration 

    ParentTarget.text:SetText(text)
    ParentTarget:SetPoint("TOP", ParentTarget:GetParent(), "BOTTOM", xOffset, yOffset)
    ParentTarget:Show()

    -- PERFORMANCE OPTIMIZATION: Set text color once here instead of recalculating 
    -- inside the OnUpdate loop 60+ times per second.
    if color == "red" then
        ParentTarget.text:SetTextColor(1, 0.1, 0.1)
    elseif color == "green" then
        ParentTarget.text:SetTextColor(0.1, 1, 0.1)
    else
        ParentTarget.text:SetTextColor(1, 1, 1) -- default white fallback
    end

    local startTime = GetTime()

    ParentTarget:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - startTime
        local distance = speed * elapsed

        self:SetPoint("TOP", self:GetParent(), "BOTTOM", xOffset, yOffset - distance)
        
        if elapsed >= duration then
            self:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end)
end


--##########################################################################
--##########################################################################

-- START -- ANIMATE BIG TO SMALL
-- This is a standard Robert Penner easing equation.
-- It smooths out animations so changes don't look robotic and rigid.
-- Variables represent:
-- t = elapsed time (how long the animation has been running)
-- b = beginning value (starting scale size/position coordinate)
-- c = change in value (the target difference to move/scale by)
-- d = duration (the total length of time the animation should take)
local function quadraticEaseInOut(t, b, c, d)
    t = t / (d / 2)
    if t < 1 then
        return c / 2 * t * t + b
    else
        t = t - 1
        return -c / 2 * (t * (t - 2) - 1) + b
    end
end

local function ShowAnimatedTextBigtoSmall(Person, ParentTarget, text, xOffset, yOffset, color)
    -- Variables:
    -- Person: player, party1, party2, party3, party4, target
    -- ParentTarget: UI frame to attach the scrolling text frame to
    -- text: text to display i.e. "-100"
    -- xOffset, yOffset: Where to spawn the text away from the ParentTarget
    -- color: "red" for damage, "green" for heals
    
    local startFontSize = 24 -- Slightly bumped up initial size for a punchier "pop" effect
    local endFontSize = 10   -- Standard readable baseline size
    local duration = 0.6

    -- Route the text tracking to the correct UI frame based on data signature type
    local TargetUIFrame = UI_Components[Person .. (color == "red" and "_ScrollingDamageFrame" or "_ScrollingHealFrame")]
    if not TargetUIFrame or not TargetUIFrame.text then return end

    -- PERFORMANCE OPTIMIZATION: Setup structural properties ONCE before entering the update loop
    TargetUIFrame.text:SetText(text)
    TargetUIFrame:ClearAllPoints() -- CRITICAL FIX: Clears anchor stacks to prevent memory allocation drops
    TargetUIFrame:SetPoint("CENTER", ParentTarget, "CENTER", xOffset, yOffset)
    
    -- Set color once out here instead of evaluating it every single frame step
    if color == "red" then
        TargetUIFrame.text:SetTextColor(1, 0.1, 0.1)  -- Pure red
    else
        TargetUIFrame.text:SetTextColor(0.1, 1, 0.1)  -- Pure green
    end

    TargetUIFrame.text:SetFont("Fonts\\ARIALN.TTF", startFontSize, "OUTLINE") 
    TargetUIFrame:Show()

    local startTime = GetTime()

    -- Refactored OnUpdate loop handles nothing but pure math execution
    TargetUIFrame:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - startTime
        local t = math.min(1, elapsed / duration) -- Clamps time cleanly at 1.0 boundary

        -- Utilizing your quadraticEaseInOut formula for smooth scale compression
        local fontSize = startFontSize - quadraticEaseInOut(t, 0, startFontSize - endFontSize, 1)
        self.text:SetFont("Fonts\\ARIALN.TTF", fontSize, "OUTLINE")

        if elapsed >= duration then
            self:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end)
end


--#########################################################################################################
--#########################################################################################################

local validUnits = { player = true, party1 = true, party2 = true, party3 = true, party4 = true, target = true }

local function ScrollingText(SpecifiedPerson)
    -- Determines if you gained or lost health and sends the amount to the animation engine.
    if not validUnits[SpecifiedPerson] then return end
    
    -- Initialize unit safety checks table if missing from global scope environment
    if not PreviouseHealth then PreviouseHealth = {} end
    
    local currentHealth = UnitHealth(SpecifiedPerson)
    local previousHealth = PreviouseHealth[SpecifiedPerson]

    -- Safeguard: If tracking data hasn't initialized yet, record baseline state and exit quietly
    if not previousHealth or previousHealth == -1 then
        PreviouseHealth[SpecifiedPerson] = currentHealth
        return
    end

    -- Evaluate active configuration flag limits before crunching numbers
    if ShowScrollingText == "true" then
        if previousHealth > currentHealth then
            -- ========================================================================
            -- UNIT TOOK DAMAGE
            -- ========================================================================
            if ShowDamage == "true" then
                local DamageAmount = previousHealth - currentHealth
                ShowAnimatedTextBigtoSmall(
                    SpecifiedPerson, 
                    UI_Components[SpecifiedPerson.."_CastSpellButton"], 
                    "-" .. tostring(DamageAmount), -- Appended negative prefix sign for visual clarity
                    -65, 0, 
                    "red"
                )
            end   
        elseif previousHealth < currentHealth then
            -- ========================================================================
            -- UNIT RECEIVED HEALING
            -- ========================================================================
            if ShowHeal == "true" then
                local HealedAmount = currentHealth - previousHealth
                ShowAnimatedTextBigtoSmall(
                    SpecifiedPerson, 
                    UI_Components[SpecifiedPerson.."_CastSpellButton"], 
                    "+" .. tostring(HealedAmount), -- Appended plus prefix sign for visual clarity
                    65, 0, 
                    "green"
                )
            end
        end
    end
    
    -- Cache current values to maintain tracking integrity across tick updates
    PreviouseHealth[SpecifiedPerson] = currentHealth
end

local validUnits = { player = true, party1 = true, party2 = true, party3 = true, party4 = true, target = true }

local function UpdateHealthValues(person, TriggerScrollingText)
    -- Guard Clause: Halt execution if the unit token passed is invalid
    if not validUnits[person] then return end
    
    local SpecifiedPerson = person
    local currentHealth   = UnitHealth(SpecifiedPerson)
    local maxHealth       = UnitHealthMax(SpecifiedPerson)
    local personName      = UnitName(SpecifiedPerson) or "Unknown"
    local personClass, classToken = UnitClass(SpecifiedPerson)
    
    -- Cache PlayerNames globally for external tracking matrix verification
    if not PlayerNames then PlayerNames = {} end
    PlayerNames[SpecifiedPerson] = personName
    
    -- Route Scrolling Combat Text updates
    if TriggerScrollingText then
        ScrollingText(SpecifiedPerson)
    else
        if not PreviouseHealth then PreviouseHealth = {} end
        PreviouseHealth[SpecifiedPerson] = currentHealth
    end
    
    -- Fetch localized components safely via tracking index strings
    local nameFrame   = UI_Components[SpecifiedPerson .. "_PlayerName"]
    local buttonFrame = UI_Components[SpecifiedPerson .. "_CastSpellButton"]
    local healthBar   = UI_Components[SpecifiedPerson .. "_HealthBar"]
    local powerBar    = UI_Components[SpecifiedPerson .. "_PowerBar"]
    
    if not nameFrame or not buttonFrame or not healthBar then return end

    -- ========================================================================
    -- CONNECTION STATES (ONLINE VS OFFLINE)
    -- ========================================================================
    if not UnitIsConnected(SpecifiedPerson) then
        nameFrame:SetText(personName .. " is Offline")
        if HM_FitTextToWidth then HM_FitTextToWidth(nameFrame, healthBar:GetWidth()) end
        buttonFrame:SetText("<< Offline >>")
        healthBar:SetValue(0)
        if powerBar then powerBar:SetValue(0) end
        return
    end
    
    -- Format Name Text string, respecting the Show Class / Color Name by
    -- Class settings (default: show class, don't color the name itself --
    -- matches the original always-on behavior).
    local cr, cg, cb = GetClassColor(classToken or personClass)
    -- FIXED: Wrapped RGB multipliers in math.floor to prevent floating point crashes in string.format
    local classColorHex = string.format("%02x%02x%02x", math.floor(cr * 255), math.floor(cg * 255), math.floor(cb * 255))

    local showClassText = (ShowClass ~= "false")     -- default true
    local colorName      = (ColorNameByClass == "true") -- default false

    local displayName = personName
    if colorName then
        displayName = string.format("|cFF%s%s|r", classColorHex, personName)
    end

    local nameText
    if showClassText then
        nameText = string.format("%s  ( |cFF%s%s|r )", displayName, classColorHex, personClass or "")
    else
        nameText = displayName
    end
    nameFrame:SetText(nameText)
    -- Shrink the font just enough to fit the current frame width (matters a
    -- lot for long name+class combos, and for narrower custom Frame Widths).
    if HM_FitTextToWidth then HM_FitTextToWidth(nameFrame, healthBar:GetWidth()) end

    -- ========================================================================
    -- HEALTH STATES (DEAD VS ALIVE)
    -- ========================================================================
    if currentHealth <= 0 then
        buttonFrame:SetText("<< DEAD >>")
        healthBar:SetValue(0)
        if powerBar then powerBar:SetValue(0) end
    else
        -- ALIVE: Standardized Consolidated Health String Builder
        local healthString = ""

        if ShowHealthValue ~= "false" then
            healthString = currentHealth .. "/" .. maxHealth
            local missingHealth = maxHealth - currentHealth

            if missingHealth > 0 then
                local mode = HealthDisplayMode or "value"
                local pct = math.floor((currentHealth / maxHealth) * 100)
                if mode == "value" then
                    healthString = string.format("%s (-%d)", healthString, missingHealth)
                elseif mode == "percent" then
                    healthString = string.format("%s (%d%%)", healthString, pct)
                elseif mode == "both" then
                    healthString = string.format("%s (-%d, %d%%)", healthString, missingHealth, pct)
                end
            end
        end
        
        buttonFrame:SetText(healthString)
        -- Safe calculation guard against division-by-zero crashes
        healthBar:SetValue(maxHealth > 0 and (currentHealth / maxHealth) or 0)
    end
end


--################################################################################================#########
--################################################################################=========================



-- ========================================================================
-- UNIVERSAL AURA ICON RENDERER (Player, Party1-4, Target, etc.)
-- ========================================================================
-- Icons are laid out in a grid that wraps to a new row once it runs out of
-- panel width (see UpdateUnitBuffDebuffIcons, which computes icons-per-row
-- from the panel's current width so it scales with custom Frame Width
-- settings). Cell size is ICON_CELL_BASE px square (scaled with frame width);
-- the icon texture itself is
-- slightly smaller than the cell so wrapped rows have a little breathing room.
local ICONS_PER_ROW_DEFAULT = 9 -- only used as a fallback if the panel isn't found yet
-- Base sizes at the default 200px Frame Width. UpdateUnitBuffDebuffIcons
-- scales these proportionally to the frame's *current* width and passes the
-- scaled values in, so buffs stay proportionate on custom widths instead of
-- overflowing (too wide) or wrapping too early (too narrow) at a fixed size.
local ICON_CELL_BASE         = 20
local ICON_SIZE_BASE         = 15
local PLAYER_ICON_SIZE_BASE  = 18 -- slightly larger for auras the player themself cast

local function CreateUnitBuffDebuffIcon(unit, buffindex, texturePath, StackSize, xOffset, Btype, caster, yOffset, iconCell, iconSizeBase, playerIconSizeBase)
										--name,rank,icon,count,dtype,duration,expires,caster,stealable,consolidate,spellId
    -- Formatting helper: converts lower case "party1" into upper- CamelCase "Party1" 
    -- so it automatically matches your global frame names (e.g., Party1BuffPanel)
    local titleUnit = unit:gsub("^%l", string.upper)
    
    -- Dynamically locate the parent UI panel frame from the global environment
    local parentPanel = _G[titleUnit .. "BuffPanel"]
    if not parentPanel then return end -- Safety guard: Exit if the unit panel doesn't exist
    
    -- Dynamically resolve or initialize tracking data tables using global string lookups
    if not _G[titleUnit .. "BuffIconFrames"] then _G[titleUnit .. "BuffIconFrames"] = {} end
    if not _G[titleUnit .. "BuffStackText"]  then _G[titleUnit .. "BuffStackText"] = {} end
    if not _G[titleUnit .. "BuffIcons"]      then _G[titleUnit .. "BuffIcons"] = {} end
    
    local iconFramesTable = _G[titleUnit .. "BuffIconFrames"]
    local stackTextTable  = _G[titleUnit .. "BuffStackText"]
    local iconsTable      = _G[titleUnit .. "BuffIcons"]

    -- Fall back to the base (unscaled) sizes if a caller doesn't supply them.
    iconCell            = iconCell or ICON_CELL_BASE
    iconSizeBase        = iconSizeBase or ICON_SIZE_BASE
    playerIconSizeBase  = playerIconSizeBase or PLAYER_ICON_SIZE_BASE

    -- Player-cast auras get drawn slightly larger (and with a gold border)
    -- so they stand out at a glance from auras other people cast.
    local isPlayerCast = (caster == "player")

    local iconSize = isPlayerCast and playerIconSizeBase or iconSizeBase
    -- Center the (possibly larger) icon within its fixed-size grid cell so
    -- rows still line up neatly even when some icons are bigger than others.
    local cellPad = (iconCell - iconSize) / 2

    -- Framework structural composition allocation
    local BuffIconFrame = CreateFrame("Frame", nil, parentPanel)
    BuffIconFrame:SetWidth(iconSize)
    BuffIconFrame:SetHeight(iconSize)
    BuffIconFrame:SetPoint("TOPLEFT", xOffset + cellPad, -1.5 - (yOffset or 0) - cellPad)
    
    -- Store precise identification properties right on the frame object for O(1) Tooltips
    BuffIconFrame.unit      = unit
    BuffIconFrame.auraIndex = buffindex
    BuffIconFrame.auraType  = Btype -- Expects "HELPFUL" (buff) or "HARMFUL" (debuff)

    local icon = BuffIconFrame:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints(BuffIconFrame)
    icon:SetTexture(texturePath)

    -- Gold border highlight to call out player-cast auras even more clearly.
    -- Uses a multiplicative ratio (not a fixed pixel offset) so the border
    -- stays proportionate as iconSize itself scales with Frame Width --
    -- a fixed "+15px" only looked right at the original unscaled size, and
    -- became proportionally too thin (nearly invisible) at larger scales or
    -- oversized at smaller ones.
if isPlayerCast then
    local border = BuffIconFrame:CreateTexture(nil, "ARTWORK")

    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")

    border:SetPoint("CENTER", BuffIconFrame, "CENTER", 0, 0)
    -- Ratio derived from the original design (18px icon + 15px border = 33px
    -- total, i.e. ~1.833x), applied to the current (possibly scaled) size.
    local borderRatio = (PLAYER_ICON_SIZE_BASE + 15) / PLAYER_ICON_SIZE_BASE
    local borderSize = iconSize * borderRatio
    border:SetWidth(borderSize)
    border:SetHeight(borderSize)

    BuffIconFrame.PlayerBorder = border
end
    
    -- High-Performance Tooltip Event Binding
    BuffIconFrame:EnableMouse(true)
    BuffIconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        
        -- Zero processing loops: Directly query the engine via pre-cached parameters
        if self.auraType == "HARMFUL" then
            GameTooltip:SetUnitDebuff(self.unit, self.auraIndex)
        else
            GameTooltip:SetUnitBuff(self.unit, self.auraIndex)
        end
        
        GameTooltip:Show()
    end)

    BuffIconFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Stack count numeric indicators layout processing
   -- To this:
	local actualStacks = tonumber(StackSize) or 0
	if actualStacks > 1 then
        local stackText = BuffIconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        stackText:SetPoint("BOTTOM", BuffIconFrame, "BOTTOM", 0, -9)
        stackText:SetTextColor(1, 1, 1)
        stackText:SetText(StackSize)
        stackText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        table.insert(stackTextTable, stackText)
    end
    
    -- Maintain data table state registrations
    table.insert(iconFramesTable, BuffIconFrame)
    table.insert(iconsTable, icon)
end

--################################################################################=========================
--################################################################################################=========

local function ClearAuraPanel(titleUnit)
    -- MEMORY FIX: Replaced broken "iterator = nil" references with WoW's native wipe() table command.
    local framesTable = _G[titleUnit .. "BuffIconFrames"]
    local iconsTable  = _G[titleUnit .. "BuffIcons"]
    local textsTable  = _G[titleUnit .. "BuffStackText"]

    if framesTable then
        for _, frame in ipairs(framesTable) do
            frame:SetScript("OnEnter", nil)
            frame:SetScript("OnLeave", nil)
            frame:Hide()
            frame:ClearAllPoints()
        end
        wipe(framesTable) -- Empties the array table completely while preserving memory allocations
    end

    if iconsTable then
        for _, icon in ipairs(iconsTable) do
            icon:Hide()
            icon:ClearAllPoints()
        end
        wipe(iconsTable)
    end

    if textsTable then
        for _, text in ipairs(textsTable) do
            text:Hide()
            text:SetText("")
            text:ClearAllPoints()
        end
        wipe(textsTable)
    end
end


-- ========================================================================
-- MASTER REFRESH SYSTEM (Replaces both UpdatePlayer and UpdateParty1)
-- ========================================================================
local function UpdateUnitBuffDebuffIcons(unit)
    -- Normalize naming conventions to match your global frameworks (e.g. "player" -> "Player")
    local titleUnit = unit:gsub("^%l", string.upper)
    
    -- Clear out out-of-date assets from memory arrays before drawing the new set
    ClearAuraPanel(titleUnit)

    local buffPanel = _G[titleUnit .. "BuffPanel"]

    -- If Show Buffs is off, just clear everything, collapse the panel back
    -- to a minimal height, and skip drawing entirely.
    if ShowBuffs == "false" then
        if buffPanel then buffPanel:SetHeight(ICON_CELL_BASE) end
        if HM_RecalculateFrameLayout then HM_RecalculateFrameLayout(unit) end
        return
    end

    local container = _G[titleUnit .. "Container"]

    -- ---- PASS 1: gather every aura we're actually going to draw ----
    -- Filtering (e.g. "Only Show My Buffs") happens here, BEFORE anything is
    -- laid out or created, so filtered-out auras never take up grid space --
    -- previously a similar filter (if present) only hid the icon visually
    -- after the fact, leaving its grid slot empty.
    local onlyPlayerBuffs = (PlayerOnlyBuffs == "true")
    local auras = {}

    for i = 1, 40 do
        -- UnitBuff in 3.3.5 returns (name, rank, icon, count, debuffType, duration, expirationTime, caster, ...)
        -- so the icon texture is the 3rd value, stack count the 4th, and caster the 8th.
        local _, _, iconTexturePath, stackSize, _, _, _, caster = UnitBuff(unit, i)
        if not iconTexturePath then break end -- Stop structural scanning if index is empty
        if not onlyPlayerBuffs or caster == "player" then
            table.insert(auras, { index = i, icon = iconTexturePath, stack = stackSize, btype = "HELPFUL", caster = caster })
        end
    end

    for i = 1, 40 do
        local _, _, iconTexturePath, stackSize, _, _, _, caster = UnitDebuff(unit, i)
        if not iconTexturePath then break end
        if not onlyPlayerBuffs or caster == "player" then
            table.insert(auras, { index = i, icon = iconTexturePath, stack = stackSize, btype = "HARMFUL", caster = caster })
        end
    end

    local auraTotal = #auras

    -- ---- PASS 2: figure out the biggest icon scale that fits both the
    -- available width AND the available height ----
    -- Width-only baseline (relative to the default 200px width where the
    -- original fixed 20px cell / 15px icon size was designed to look right).
    local frameWidth = (container and container:GetWidth()) or 200
    local widthScale = math.max(0.6, math.min(frameWidth / 200, 2.0))

    local panelWidth = (buffPanel and buffPanel:GetWidth()) or (ICONS_PER_ROW_DEFAULT * ICON_CELL_BASE * widthScale)

    local function gridAt(scale)
        local cell = ICON_CELL_BASE * scale
        local cols = math.max(1, math.floor(panelWidth / cell))
        local rows = (auraTotal > 0) and math.ceil(auraTotal / cols) or 1
        return cell, cols, rows
    end

    local finalScale = widthScale

    -- If "Use Custom Height" is on and leaves extra vertical room beyond what
    -- the buff panel actually needs at widthScale, use that extra room to
    -- scale icons up further (never below widthScale) so buffs fill the
    -- frame vertically too, not just horizontally.
    if FrameCustomHeight == "true" and auraTotal > 0 then
        local nameString = _G[titleUnit .. "Name"]
        local healthBar  = _G[titleUnit .. "StatusBar"]
        local powerBar   = _G[titleUnit .. "PowerStatusBar"]
        local showPower  = (ShowPowerBar ~= "false")

        if nameString and healthBar then
            -- Same fixed-overhead formula as HM_RecalculateFrameLayout, minus
            -- the buff panel's own contribution (that's what we're solving for).
            local overhead = 6 + nameString:GetHeight() + (24 - nameString:GetHeight()) + healthBar:GetHeight()
            if showPower and powerBar then overhead = overhead + 2 + powerBar:GetHeight() end
            overhead = overhead + 4 -- gap before the buff panel
            overhead = overhead + 8 -- bottom buffer margin

            local customHeight = tonumber(FrameHeightValue) or 150
            local availableForBuffs = customHeight - overhead

            local _, _, baseRows = gridAt(widthScale)
            local baseNeeded = math.max(ICON_CELL_BASE * widthScale, baseRows * ICON_CELL_BASE * widthScale) + 5

            if availableForBuffs > baseNeeded then
                -- Binary-search upward for the largest scale whose resulting
                -- grid (recomputed at each candidate scale, since a bigger
                -- icon means fewer columns and therefore possibly more rows)
                -- still fits within availableForBuffs.
                local lo, hi = widthScale, 3.0
                for _ = 1, 14 do
                    local mid = (lo + hi) / 2
                    local cell, _, rows = gridAt(mid)
                    local neededHeight = math.max(cell, rows * cell) + 5
                    if neededHeight <= availableForBuffs then
                        lo = mid
                    else
                        hi = mid
                    end
                end
                finalScale = lo
            end
        end
    end

    finalScale = math.max(0.6, math.min(finalScale, 3.0))

    local iconCell, iconsPerRow, _ = gridAt(finalScale)
    local iconSize       = ICON_SIZE_BASE * finalScale
    local playerIconSize = PLAYER_ICON_SIZE_BASE * finalScale

    -- ---- PASS 3: actually create the icons at the final scale ----
    for i, aura in ipairs(auras) do
        local col = (i - 1) % iconsPerRow
        local row = math.floor((i - 1) / iconsPerRow)
        local xOffset, yOffset = col * iconCell, row * iconCell
        CreateUnitBuffDebuffIcon(unit, aura.index, aura.icon, aura.stack, xOffset, aura.btype, aura.caster, yOffset, iconCell, iconSize, playerIconSize)
    end

    -- Resize the buff panel backdrop to fit however many rows got used, so
    -- wrapped rows aren't drawn below/outside the panel's visible background.
    if buffPanel then
        local rowsUsed = (auraTotal > 0) and (math.ceil(auraTotal / iconsPerRow)) or 1
        local newPanelHeight = math.max(iconCell, rowsUsed * iconCell) + 5
        buffPanel:SetHeight(newPanelHeight)
    end

    -- Re-derive the container's overall height (and re-apply Show Energy Bar
    -- / Show Buffs visibility) using the single shared layout function.
    if HM_RecalculateFrameLayout then HM_RecalculateFrameLayout(unit) end
end

-- Backward compatibility aliases to prevent broken references in your event wrappers
local function UpdatePlayerBuffDebuffIcons() UpdateUnitBuffDebuffIcons("player") end
local function UpdateParty1BuffDebuffIcons() UpdateUnitBuffDebuffIcons("party1") end

local function UpdateParty2BuffDebuffIcons() 
    UpdateUnitBuffDebuffIcons("party2") 
end

local function UpdateParty3BuffDebuffIcons() 
    UpdateUnitBuffDebuffIcons("party3") 
end

local function UpdateParty4BuffDebuffIcons() 
    UpdateUnitBuffDebuffIcons("party4") 
end

local function UpdateTargetBuffDebuffIcons()
    -- Directly routes into the high-performance universal refresh engine
    UpdateUnitBuffDebuffIcons("target")
end

-- Re-runs the aura grid layout (and the auto-height calculation that comes
-- with it) for every unit frame, including ones currently hidden. Used by
-- HM_ApplyFrameAppearance whenever Frame Width changes (icons-per-row and
-- the auto-calculated height both depend on the current width) and when the
-- "Use Custom Height" checkbox is turned back off (restores the normal
-- auto-calculated height instead of leaving whatever custom height was set).
function HM_RefreshAllAuraLayout()
    local units = { "player", "party1", "party2", "party3", "party4", "target" }
    for _, unitId in ipairs(units) do
        UpdateUnitBuffDebuffIcons(unitId)
    end
end

-- ========================================================================
-- HIGH-PERFORMANCE POWER BAR SYSTEM
-- ========================================================================

-- Normalized color dictionary (Decimals match WoW's standard 0.0 - 1.0 API scaling)
-- Modernized Power Constants using Enum-like indexing
local POWER_COLORS = {
    [0] = { r = 0.0,   g = 0.0,   b = 0.882 }, -- Mana
    [1] = { r = 0.698, g = 0.0,   b = 0.0 },   -- Rage
	[2] = { r = 0.694, g = 0.345, b = 0.172 }, -- Focus
	[3] = { r = 0.882, g = 0.871, b = 0.0 },   -- Energy
    [6] = { r = 0.70,  g = 0.40,  b = 1.0 },   -- Runic Power (example)
	[12] = { r = 0.0,  g = 0.8,   b = 0.0 },   -- Example: Venomancer Toxic Pool
}

local VALID_POWER_UNITS = { player = true, party1 = true, party2 = true, party3 = true, party4 = true, target = true }

local function UpdatePowerValues(person)
    if not VALID_POWER_UNITS[person] then return end

    -- Use UnitPowerType to get the current resource ID dynamically
    -- This handles Druid forms and custom classes automatically
    local powerType = UnitPowerType(person)
    
    local currentPower = UnitPower(person, powerType)
    local powerMax = UnitPowerMax(person, powerType)
    
    -- Route color based on the numeric Power ID rather than Class string
    local color = POWER_COLORS[powerType] or POWER_COLORS[0]

    -- Safeguard division
    local progress = (powerMax > 0) and (currentPower / powerMax) or 0

    local powerBar = UI_Components[person .. "_PowerBar"]
    if powerBar then
        powerBar:SetValue(progress)
        powerBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end


-- ========================================================================
-- CLEAN GROUP LAYOUT MANAGEMENT ENGINE
-- ========================================================================

function Check4Group()
    -- 1. Always update player frame values regardless of group configuration state
    UpdateHealthValues("player", false)
    UpdateUnitBuffDebuffIcons("player") -- Calls the master engine from prior steps
    UpdatePowerValues("player")

    local numPartyMembers = GetNumPartyMembers() or 0
	--Debug( "[numPartyMembers] = " .. tostring(numPartyMembers))
    -- 2. Cleanly loop over party slots to toggle containers and synchronize properties
    for i = 1, 4 do
        local unitName = "party" .. i
        local container = _G["Party" .. i .. "Container"]

        if container then
            if i <= numPartyMembers then
                -- Target is active: update vital data matrices and show the frame
                UpdateHealthValues(unitName, false)
                UpdatePowerValues(unitName)
                UpdateUnitBuffDebuffIcons(unitName) -- Eliminates structural omission bugs
                
                HM_SafeSetShown(container, true, unitName)
            else
                -- Target is empty: dismiss the component from the screen canvas
                HM_SafeSetShown(container, false, unitName)
            end
        end
    end
end


local function ManageTargetFrame()
	
local isTargetVisible = false
        -- Guard Clause: Only evaluate tracking if the user configuration allows it and a target exists
        if ShowTargetUI == "true" and UnitExists("target") then
            local targetName = UnitName("target")
			local isFriend   = UnitIsFriend("player", "target")
            -- Match visibility criteria against user context string settings
            local passFilter = (isFriend and ShowTargetFriendly == "true") or (not isFriend and ShowTargetEnemy == "true")
            
            -- Structural array sweep: Ensure we aren't showing the target frame if they are already visible in party frames
            local alreadyTracked = (PlayerNames["player"] == targetName) or
                                   (PlayerNames["party1"] == targetName) or
                                   (PlayerNames["party2"] == targetName) or
                                   (PlayerNames["party3"] == targetName) or
                                   (PlayerNames["party4"] == targetName)

            if passFilter and not alreadyTracked then
                isTargetVisible = true
                
                HM_SafeSetShown(TargetContainer, true, "target")
                UpdateHealthValues("target", false)
                UpdatePowerValues("target")
                UpdateUnitBuffDebuffIcons("target")
                
                CurrentTargetName = targetName
            end
        end
        
        -- Single Fallback Point: Safely secures frame closure without duplicating code 5 times
        if not isTargetVisible then
            HM_SafeSetShown(TargetContainer, false, "target")
        end
end

local function CheckboxShowTargetOnClick()

    local isChecked = (HM_CheckboxShowTarget:GetChecked() == 1)
    
    if isChecked then
        ShowTargetUI = "true"
        
        HM_CheckboxFriendly:Enable()
        HM_CheckboxEnemy:Enable()
        
        HM_CheckboxFriendlyLabel:SetTextColor(1, 0.82, 0)
        HM_CheckboxEnemyLabel:SetTextColor(1, 0.82, 0)
		ManageTargetFrame()
		
    else
        ShowTargetUI = "false"
        
        HM_CheckboxFriendly:Disable()
        HM_CheckboxEnemy:Disable()
        
        HM_CheckboxFriendlyLabel:SetTextColor(0.5, 0.5, 0.5)
        HM_CheckboxEnemyLabel:SetTextColor(0.5, 0.5, 0.5)
        
        if TargetContainer then HM_SafeSetShown(TargetContainer, false, "target") end
    end
end

local function CheckboxShowFriendlyOnClick()
	ShowTargetFriendly = (HM_CheckboxFriendly:GetChecked() == 1) and "true" or "false"
	ManageTargetFrame()
end

local function CheckboxShowEnemyOnClick()
    ShowTargetEnemy = (HM_CheckboxEnemy:GetChecked() == 1) and "true" or "false"
	ManageTargetFrame()
end
-- ========================================================================
-- MASTER EVENT ROUTER ENGINE
-- ========================================================================

-- Valid target map for fast O(1) tracking lookups
local VALID_AURA_UNITS = { player = true, party1 = true, party2 = true, party3 = true, party4 = true, target = true }

local function eventHandler(self, eventParam, arg1Param)
    -- Multi-client engine fallback: supports explicit parameters or historical global injections
    local currentEvent = eventParam or event
    local currentArg1  = arg1Param or arg1

    if currentEvent == "ADDON_LOADED" then
        -- ADDON_LOADED fires once per addon loaded; only react to our own.
        if currentArg1 == "HealersMate" then
            InitializeFrames()
            eventAddonLoaded()
            self:RegisterEvent("UNIT_HEALTH")
            self:RegisterEvent("UNIT_MAXHEALTH")
            self:RegisterEvent("UNIT_POWER")
        end
    
    elseif currentEvent == "PLAYER_ENTERING_WORLD" or currentEvent == "PARTY_MEMBERS_CHANGED" then
        -- Deferred (see HM_Defer above). Party roster changes are a classic
        -- taint source in WoW: Blizzard's own compact party frame system
        -- runs through secure/protected code when the roster updates, and
        -- that taint can leak into ANY addon's handler for the same event --
        -- even one that never touches anything protected itself -- which is
        -- exactly what was blocking SetHeight() on the Target frame here.
        HM_Defer(Check4Group)
        
    elseif currentEvent == "PLAYER_LOGOUT" or currentEvent == "PLAYER_QUITING" then
        eventPlayerLogout()
        
    elseif currentEvent == "UNIT_HEALTH" then
        UpdateHealthValues(currentArg1, true)
		
    elseif currentEvent == "UNIT_MANA" or currentEvent == "UNIT_RAGE" or currentEvent == "UNIT_ENERGY" then
        UpdatePowerValues(currentArg1)
        
    elseif currentEvent == "UNIT_AURA" then
        -- Replaces 25 lines of duplicate frame switches with a clean lookup matrix
        if VALID_AURA_UNITS[currentArg1] then
            -- Deferred (see HM_Defer above): UpdateUnitBuffDebuffIcons calls
            -- HM_RecalculateFrameLayout, which can call SetHeight() -- the
            -- same call Blizzard blocks when this fires in a tainted tick
            -- (e.g. from a party roster change happening at the same time).
            UpdateHealthValues(currentArg1, false)     -- Catch Max Health changes (e.g., Fortitude/Power Word)
            HM_Defer(function() UpdateUnitBuffDebuffIcons(currentArg1) end)
        end
        
    elseif currentEvent == "PLAYER_TARGET_CHANGED" then
        -- Deferred (see HM_Defer above) -- this event can fire as a direct
        -- result of our own secure "target" click-bind action, which would
        -- otherwise taint this whole call chain (including the SetHeight()
        -- calls inside ManageTargetFrame -> HM_RecalculateFrameLayout) and
        -- get blocked by Blizzard's protected-function guard.
        HM_Defer(ManageTargetFrame)

    elseif currentEvent == "PLAYER_REGEN_ENABLED" then
        -- Combat just ended.
        -- 1) Any click-bind spell name changed while InCombatLockdown() was
        --    true got silently skipped (secure attributes can't be touched
        --    in combat) -- re-apply now.
        if HM_RefreshAllSpellBindings then
            HM_RefreshAllSpellBindings()
        end
        -- 2) Any width/height/color settings change made mid-combat got
        --    skipped entirely (see HM_ApplyFrameAppearance) -- apply it now.
        if HM_AppearancePendingApply and HM_ApplyFrameAppearance then
            HM_AppearancePendingApply = false
            HM_ApplyFrameAppearance()
        end
        -- 3) Any container whose SetHeight() got skipped during combat
        --    (because it has a secure click-to-cast child, which makes
        --    Blizzard treat resizing it as restricted for the whole fight)
        --    needs its layout recalculated now that we're safely out of
        --    combat -- otherwise buffs added mid-fight could keep slightly
        --    overflowing the frame's border until the next full refresh.
        if HM_PendingLayoutUnits then
            for unitId in pairs(HM_PendingLayoutUnits) do
                if HM_RecalculateFrameLayout then
                    HM_RecalculateFrameLayout(unitId)
                end
            end
            HM_PendingLayoutUnits = {}
        end
        -- 4) Any Show()/Hide() on these containers that got skipped during
        --    combat (same secure-child restriction as SetHeight/SetWidth) --
        --    apply whatever visibility state was actually wanted now.
        if HM_PendingVisibility then
            for key, entry in pairs(HM_PendingVisibility) do
                if entry.frame then
                    if entry.shouldShow then entry.frame:Show() else entry.frame:Hide() end
                end
            end
            HM_PendingVisibility = {}
        end
    end
end

-- ========================================================================
-- FRAME CALLBACK REGISTERS & INITIALIZATION
-- ========================================================================

-- Event Handlers
EventHandlerFrame:SetScript("OnEvent", eventHandler)

-- Configuration Checkbox Injections
HM_CheckboxShowTarget:SetScript("OnClick", CheckboxShowTargetOnClick)
HM_CheckboxFriendly:SetScript("OnClick", CheckboxShowFriendlyOnClick)
HM_CheckboxEnemy:SetScript("OnClick", CheckboxShowEnemyOnClick)

-- NEW checkbox injections
HM_CheckboxHideBackground:SetScript("OnClick", CheckboxHideBackgroundOnClick)
HM_CheckboxPlayerOnlyBuffs:SetScript("OnClick", CheckboxPlayerOnlyBuffsOnClick)

-- Keep these hidden on raw file-load; eventAddonLoaded/PLAYER_TARGET_CHANGED will manage them.
HM_SettingsContainer:Hide()
if TargetContainer then TargetContainer:Hide() end