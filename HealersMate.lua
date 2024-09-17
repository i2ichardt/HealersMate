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


--This is Just to respond to events "EventHandlerFrame" never appears on the screen
local EventHandlerFrame = CreateFrame("Frame", "EventHandlerFrame", UIParent)
EventHandlerFrame:RegisterEvent("ADDON_LOADED"); -- This triggers once for every addon that was loaded after this addon
EventHandlerFrame:RegisterEvent("PLAYER_LOGOUT"); -- Fired when about to log out
EventHandlerFrame:RegisterEvent("PLAYER_QUITING"); -- Fired when a player has the quit option on screen
EventHandlerFrame:RegisterEvent("UNIT_HEALTH") --“UNIT_HEALTH” fires when a unit’s health changes
EventHandlerFrame:RegisterEvent("UNIT_AURA")-- Register for the "UNIT_AURA" event to update buffs and debuffs
EventHandlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- This event is fired when the player enters the world, reloads the UI, or zones between map instances. Basically, it triggers whenever a loading screen appears2. This includes logging in, respawning at a graveyard, entering/leaving an instance, and other situations where a loading screen is presented.
EventHandlerFrame:RegisterEvent("PARTY_MEMBERS_CHANGED") -- This event is generated when someone joins or leaves the group
EventHandlerFrame:RegisterEvent("PLAYER_TARGET_CHANGED") --track when player changes what they are targeting

EventHandlerFrame:RegisterEvent("UNIT_MANA")
EventHandlerFrame:RegisterEvent("UNIT_RAGE")
EventHandlerFrame:RegisterEvent("UNIT_ENERGY")

--EventHandlerFrame:RegisterEvent("PLAYER_LOGIN") -- Fires when you login only once.

--#########################################################################################################

function Debug(msg)
	--Used to send text to the chatbox of the player but not to any other player
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

--Used too set custom tooltip information when you mouse over things; like in the settings checkboxes
local MyTooltip = CreateFrame("GameTooltip", "MyTooltip", UIParent, "GameTooltipTemplate")

--Fucntion that is called to set the text of a custom tooltip and where to display it.
local function ShowTooltip(AttachTo, TooltipText1, TooltipText2)
	MyTooltip:SetOwner(AttachTo, "ANCHOR_RIGHT")
	MyTooltip:SetPoint("RIGHT", AttachTo, "LEFT", 0, 0)
		
	MyTooltip:AddLine(TooltipText1, 1, 1, 1) -- White text color
	
	if TooltipText2 ~= "" then
		MyTooltip:AddLine(TooltipText2, 1, 1, 1) -- White text color
	end
		
	MyTooltipTextLeft1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	MyTooltipTextLeft2:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	
	MyTooltip:Show()
end

--Used to hide custom tooltips
local function HideTooltip()
	MyTooltip:Hide()
end


--#########################################################################################################
-- START - Create Settings UI
--#########################################################################################################

--START -- Checkbox Logic
local function CheckboxShowScrollingTextOnClick()

	local isChecked = CheckboxShowScrollingText:GetChecked()
    
	if isChecked then
		ShowScrollingText = "true"
		
		CheckboxShowDamage:Enable()
		CheckboxShowHeal:Enable()

		CheckboxShowDamageLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold color
		CheckboxShowHealLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold color
    else
        ShowScrollingText = "false"
		
		CheckboxShowDamage:Disable()
		CheckboxShowHeal:Disable()
		
		CheckboxShowDamageLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
		CheckboxShowHealLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
		
    end
	
end

local function CheckboxShowDamageOnClick()
    local isChecked = CheckboxShowDamage:GetChecked()
     
	if isChecked then
    	ShowDamage = "true"
	else
    	ShowDamage = "false"
	end
	
end

local function CheckboxShowHealOnClick()
    local isChecked = CheckboxShowHeal:GetChecked()
    
	if isChecked then
    	ShowHeal = "true"
	else
    	ShowHeal = "false"
	end
	
end

local function CheckboxShowTargetOnClick()
    local isChecked = CheckboxShowTarget:GetChecked()
    
	if isChecked then
        ShowTargetUI = "true"
		
		CheckboxFriendly:Enable()
		CheckboxEnemy:Enable()
		
		CheckboxFriendlyLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold color
		CheckboxEnemyLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold color
       
    else
        ShowTargetUI = "false"
		
		CheckboxFriendly:Disable()
		CheckboxEnemy:Disable()
		
		CheckboxFriendlyLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
		CheckboxEnemyLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
		
		--Hide Target UI incase its currently visible
		TargetContainer:Hide()
    end
end

local function CheckboxShowFriendlyOnClick()
    local isChecked = CheckboxFriendly:GetChecked()
    
	if isChecked then
    	ShowTargetFriendly = "true"
	else
    	ShowTargetFriendly = "false"
	end
end

local function CheckboxShowEnemyOnClick()
    local isChecked = CheckboxEnemy:GetChecked()
    
	if isChecked then
    	ShowTargetEnemy = "true"
	else
    	ShowTargetEnemy = "false"
	end
end


local function CheckboxShowHealthMinusValueOnClick()
    local isChecked = CheckboxShowHealthMinusValue:GetChecked()
    
	if isChecked then
    
		ShowMinusValue = "true"
		ShowPercentageHealth = "false"
		CheckboxShowHealthMinusValueLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold color
		
		--Other Checkbox
		CheckboxShowHealthPercentageValue:SetChecked(false)
		CheckboxShowHealthPercentageValueLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
	else
    	
		ShowMinusValue = "false"
		ShowPercentageHealth = "true"
		CheckboxShowHealthMinusValueLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
		
		--Other Checkbox
		CheckboxShowHealthPercentageValue:SetChecked(true)
		CheckboxShowHealthPercentageValueLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold color
	end

end

local function CheckboxShowHealthPercentageValueOnClick()
    local isChecked = CheckboxShowHealthPercentageValue:GetChecked()
    
    if isChecked then
    
		ShowPercentageHealth = "true"
		ShowMinusValue = "false"
		CheckboxShowHealthPercentageValueLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold color
		--Other Checkbox
		CheckboxShowHealthMinusValue:SetChecked(false)
		CheckboxShowHealthMinusValueLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
	else
    	
		ShowPercentageHealth = "false"
		ShowMinusValue = "true"
		CheckboxShowHealthPercentageValueLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
		--Other Checkbox
		CheckboxShowHealthMinusValue:SetChecked(true)
		CheckboxShowHealthMinusValueLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold color
	end

end

--END -- Checkbox Logic


-- Create the main SETTINGS frame
local HM_SettingsContainer = CreateFrame("Frame", "HM_SettingsContainer", UIParent)
HM_SettingsContainer:SetFrameLevel(10)
HM_SettingsContainer:SetWidth(425) -- width
HM_SettingsContainer:SetHeight(365) -- height
HM_SettingsContainer:SetPoint("CENTER", UIParent, "CENTER")
HM_SettingsContainer:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
HM_SettingsContainer:EnableMouse(true)
HM_SettingsContainer:SetMovable(true)

HM_SettingsContainer:SetScript("OnMouseDown", function()
  local button = arg1
  
  if button == "LeftButton" and not HM_SettingsContainer.isMoving then
	  HM_SettingsContainer:StartMoving();
	  HM_SettingsContainer.isMoving = true;
  end
  
end)

HM_SettingsContainer:SetScript("OnMouseUp", function()
  local button = arg1
  
  if button == "LeftButton" and HM_SettingsContainer.isMoving then
	  HM_SettingsContainer:StopMovingOrSizing();
	  HM_SettingsContainer.isMoving = false;
  end
  
end)

-- Main Settings Page - Title Text
local title = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetText("HealersMate Settings")
title:SetPoint("TOP", HM_SettingsContainer, "TOP", 0, -10)

-- Main Settings Page - Close Button
local closeButton = CreateFrame("Button", nil, HM_SettingsContainer, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", HM_SettingsContainer, "TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function() HM_SettingsContainer:Hide() checkboxFrame:Hide() spellsFrame:Hide() scalingFrame:Hide() AboutFrame:Show() end)

--START--Combobox

	--What to do when an option is selected in the settings combobox
	local function ShowFrame(frameName)
		if frameName == "checkboxFrame" then
			checkboxFrame:Show()
			spellsFrame:Hide()
			scalingFrame:Hide()
			AboutFrame:Hide()
		elseif frameName =="spellsFrame" then
			checkboxFrame:Hide()
			spellsFrame:Show()
			scalingFrame:Hide()
			AboutFrame:Hide()
		elseif frameName =="scalingFrame" then
			checkboxFrame:Hide()
			spellsFrame:Hide()
			scalingFrame:Show()
			AboutFrame:Hide()
		end
	end

	local dropdownOptions = {
		{ text = "Checkboxes", func = function() ShowFrame("checkboxFrame") end },
		{ text = "Spells", func = function() ShowFrame("spellsFrame") end },
		--{ text = "Scaling", func = function() ShowFrame("scalingFrame") end },
	}

	-- Dropdown list frame
	local dropdownList = CreateFrame("Frame", "HM_SettingsDropdownList", HM_SettingsContainer, "UIDropDownMenuTemplate")
	dropdownList:SetPoint("TOPLEFT", HM_SettingsContainer, "TOPLEFT", 0, -30)
	dropdownList:SetWidth(120)
	dropdownList:SetHeight(150)
	dropdownList:Show()

	-- Initialize the dropdown menu
	UIDropDownMenu_Initialize(dropdownList, function(self, level)
		local info = {}
		for _, dropdownOption in pairs(dropdownOptions) do
			info.text = dropdownOption.text
			info.func = dropdownOption.func
			UIDropDownMenu_AddButton(info)
		end
	end)
	
	-- Set the default text for the combobox; this is the text that is visible if you haven't selected an option in the combobox yet
	UIDropDownMenu_SetText("Select option", dropdownList)

--END--Combobox

-- Settings Content Frames: About, Checkboxes, Spells, Scaling
local AboutFrame = CreateFrame("Frame", "AboutFrame", HM_SettingsContainer)
AboutFrame:SetWidth(250) -- width
AboutFrame:SetHeight(380) -- height
AboutFrame:SetPoint("CENTER", HM_SettingsContainer, "CENTER")
AboutFrame:Show()

local checkboxFrame = CreateFrame("Frame", "checkboxFrame", HM_SettingsContainer)
checkboxFrame:SetWidth(250) -- width
checkboxFrame:SetHeight(380) -- height
checkboxFrame:SetPoint("CENTER", HM_SettingsContainer, "CENTER")
checkboxFrame:Hide() -- Initially hidden

local spellsFrame = CreateFrame("Frame", "spellsFrame", HM_SettingsContainer)
spellsFrame:SetWidth(250)
spellsFrame:SetHeight(380)
spellsFrame:SetPoint("CENTER", HM_SettingsContainer, "CENTER")
spellsFrame:Hide() -- Initially hidden

local scalingFrame = CreateFrame("Frame", "scalingFrame", HM_SettingsContainer)
scalingFrame:SetWidth(250)
scalingFrame:SetHeight(380)
scalingFrame:SetPoint("CENTER", HM_SettingsContainer, "CENTER")
scalingFrame:Hide() -- Initially hidden

-- START -- AboutFrame Contents

local TxtAboutLabel = AboutFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtAboutLabel:SetPoint("CENTER", AboutFrame, "CENTER")
TxtAboutLabel:SetText("HealersMate Version 1.3.0\ni2ichardt, Chatgpt\nrj299@yahoo.com\n\nCheck for Updates @:\n https://github.com/i2ichardt/HealersMate")

-- END -- AboutFrame Contents

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------

-- START -- SpellsFrame Contents

	--Used as a reference point; to be able to move all the controls that reference it without having to go through and adjust each item
	local TopX = 20
	local TopY = -50


	--Textbox
	local TxtLeftClick = CreateFrame("EditBox", "TxtLeftClick", spellsFrame, "InputBoxTemplate")
	TxtLeftClick:SetPoint("TOP", TopX + 35, TopY + -25)
	TxtLeftClick:SetWidth(200) -- width
	TxtLeftClick:SetHeight(30) -- height
	--Label
	local TxtLeftClickLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TxtLeftClickLabel:SetPoint("RIGHT", TxtLeftClick, "LEFT", -10, 0)
	TxtLeftClickLabel:SetText("Left Click:")


	--Textbox
	local TxtShiftLeftClick = CreateFrame("EditBox", "TxtShiftLeftClick", spellsFrame, "InputBoxTemplate")
	TxtShiftLeftClick:SetPoint("TOP", TopX + 35, TopY + -50)
	TxtShiftLeftClick:SetWidth(200) -- width
	TxtShiftLeftClick:SetHeight(30) -- height
	--Label
	local TxtShiftLeftClickLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TxtShiftLeftClickLabel:SetPoint("RIGHT", TxtShiftLeftClick, "LEFT", -10, 0)
	TxtShiftLeftClickLabel:SetText("Shift + Left Click:")


	--Textbox
	local TxtCtrlLeftClick = CreateFrame("EditBox", "TxtCtrlLeftClick", spellsFrame, "InputBoxTemplate")
	TxtCtrlLeftClick:SetPoint("TOP", TopX + 35,TopY + -75)
	TxtCtrlLeftClick:SetWidth(200) -- width
	TxtCtrlLeftClick:SetHeight(30) -- height
	--Label
	local TxtCtrlLeftLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TxtCtrlLeftLabel:SetPoint("RIGHT", TxtCtrlLeftClick, "LEFT", -10, 0)
	TxtCtrlLeftLabel:SetText("Ctrl + Left Click:")


	--Middle Click
	--Textbox
	local TxtMiddleClick = CreateFrame("EditBox", "TxtMiddleClick", spellsFrame, "InputBoxTemplate")
	TxtMiddleClick:SetPoint("TOP", TopX + 35, TopY + -125)
	TxtMiddleClick:SetWidth(200) -- width
	TxtMiddleClick:SetHeight(30) -- height
	--Label
	local TxtMiddleClickLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TxtMiddleClickLabel:SetPoint("RIGHT", TxtMiddleClick, "LEFT", -10, 0)
	TxtMiddleClickLabel:SetText("Middle Click:")

	--Shift + Middle Click
	--Textbox
	local TxtShiftMiddleClick = CreateFrame("EditBox", "TxtShiftMiddleClick", spellsFrame, "InputBoxTemplate")
	TxtShiftMiddleClick:SetPoint("TOP", TopX + 35, TopY + -150)
	TxtShiftMiddleClick:SetWidth(200) -- width
	TxtShiftMiddleClick:SetHeight(30) -- height
	--Label
	local TxtShiftMiddleClickLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TxtShiftMiddleClickLabel:SetPoint("RIGHT", TxtShiftMiddleClick, "LEFT", -10, 0)
	TxtShiftMiddleClickLabel:SetText("Shift + Middle Click:")


	--Shift + Middle Click
	--Textbox
	local TxtCtrlMiddleClick = CreateFrame("EditBox", "TxtCtrlMiddleClick", spellsFrame, "InputBoxTemplate")
	TxtCtrlMiddleClick:SetPoint("TOP", TopX + 35, TopY + -175)
	TxtCtrlMiddleClick:SetWidth(200) -- width
	TxtCtrlMiddleClick:SetHeight(30) -- height
	--Label
	local TxtCtrlMiddleClickLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TxtCtrlMiddleClickLabel:SetPoint("RIGHT", TxtCtrlMiddleClick, "LEFT", -10, 0)
	TxtCtrlMiddleClickLabel:SetText("Ctrl + Middle Click:")

	--Textbox
	local TxtRightClick = CreateFrame("EditBox", "TxtRightClick", spellsFrame, "InputBoxTemplate")
	TxtRightClick:SetPoint("TOP", TopX + 35, TopY + -225)
	TxtRightClick:SetWidth(200) -- width
	TxtRightClick:SetHeight(30) -- height
	--Label
	local TxtRightClickLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TxtRightClickLabel:SetPoint("RIGHT", TxtRightClick, "LEFT", -10, 0)
	TxtRightClickLabel:SetText("Right Click:")


	--Textbox
	local TxtShiftRightClick = CreateFrame("EditBox", "TxtShiftRightClick", spellsFrame, "InputBoxTemplate")
	TxtShiftRightClick:SetPoint("TOP", TopX + 35, TopY + -250)
	TxtShiftRightClick:SetWidth(200) -- width
	TxtShiftRightClick:SetHeight(30) -- height
	--Label
	local TxtShiftRightClickLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TxtShiftRightClickLabel:SetPoint("RIGHT", TxtShiftRightClick, "LEFT", -10, 0)
	TxtShiftRightClickLabel:SetText("Shift + Right Click:")


	--Textbox
	local TxtCtrlRightClick = CreateFrame("EditBox", "TxtCtrlRightClick", spellsFrame, "InputBoxTemplate")
	TxtCtrlRightClick:SetPoint("TOP", TopX + 35, TopY + -275)
	TxtCtrlRightClick:SetWidth(200) -- width
	TxtCtrlRightClick:SetHeight(30) -- height
	--Label
	local TxtCtrlRightClickLabel = spellsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TxtCtrlRightClickLabel:SetPoint("RIGHT", TxtCtrlRightClick, "LEFT", -10, 0)
	TxtCtrlRightClickLabel:SetText("Ctrl + Right Click:")

-- END -- SpellsFrame Contents--

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------

--START-- checkboxFrame Contents

	--Used as a reference point; to be able to move all the controls that reference it without having to go through and adjust each item
	local CheckboxTopX = 20
	local CheckboxTopY = -50

	--START-- OPTION: Show Target

		-- Create the checkbox
		local CheckboxShowTarget = CreateFrame("CheckButton", "CheckboxShowTarget", checkboxFrame, "UICheckButtonTemplate")
		CheckboxShowTarget:SetPoint("TOP", CheckboxTopX + -62, CheckboxTopY + -25)
		CheckboxShowTarget:SetWidth(20) -- width
		CheckboxShowTarget:SetHeight(20) -- height
		CheckboxShowTarget:SetScript("OnEnter", function() ShowTooltip(CheckboxShowScrollingText, "Check to show a UI Frame for the players target.", "Note: You also need to check Friendly and/or Enemy to determine which too display.") end)
		CheckboxShowTarget:SetScript("OnLeave", HideTooltip)
		
		-- Label for the checkbox
		local CheckboxShowTargetLabel = checkboxFrame:CreateFontString("CheckboxShowTargetLabel", "OVERLAY", "GameFontNormal")
		CheckboxShowTargetLabel:SetPoint("RIGHT", CheckboxShowTarget, "LEFT", -3, 0)
		CheckboxShowTargetLabel:SetText("Show Target:")

		-- Create the "Friendly" checkbox
		local CheckboxFriendly = CreateFrame("CheckButton", "CheckboxFriendly", checkboxFrame, "UICheckButtonTemplate")
		CheckboxFriendly:SetPoint("TOP", CheckboxTopX + 45, CheckboxTopY + -25)
		CheckboxFriendly:SetWidth(20) -- width
		CheckboxFriendly:SetHeight(20) -- height

		-- Label for the "Friendly" checkbox
		local CheckboxFriendlyLabel = checkboxFrame:CreateFontString("CheckboxFriendlyLabel", "OVERLAY", "GameFontNormal")
		CheckboxFriendlyLabel:SetPoint("RIGHT", CheckboxFriendly, "LEFT", -5, 0)
		CheckboxFriendlyLabel:SetText("Friendly")

		-- Create the "Enemy" checkbox
		local CheckboxEnemy = CreateFrame("CheckButton", "CheckboxEnemy", checkboxFrame, "UICheckButtonTemplate")
		CheckboxEnemy:SetPoint("TOP", CheckboxTopX + 125, CheckboxTopY + -25)
		CheckboxEnemy:SetWidth(20) -- width
		CheckboxEnemy:SetHeight(20) -- height

		-- Label for the "Enemy" checkbox
		local CheckboxEnemyLabel = checkboxFrame:CreateFontString("CheckboxEnemyLabel", "OVERLAY", "GameFontNormal")
		CheckboxEnemyLabel:SetPoint("RIGHT", CheckboxEnemy, "LEFT", -5, 0)
		CheckboxEnemyLabel:SetText("Enemy")
		
	--END-- OPTION: Show Target

	----------------------------------------------------------------------------------------------------------------------------------------------

	--START-- OPTION: Show Health As
	
		-- Label
		local HealthStyleLabel = checkboxFrame:CreateFontString("HealthStyleLabel", "OVERLAY", "GameFontNormal")
		HealthStyleLabel:SetPoint("TOP", CheckboxTopX + -122, CheckboxTopY + -60)
		HealthStyleLabel:SetText("Show Health As:")

		-- Create the checkbox for Health -
		local CheckboxShowHealthMinusValue = CreateFrame("CheckButton", "CheckboxShowHealthMinusValue", checkboxFrame, "UICheckButtonTemplate")
		CheckboxShowHealthMinusValue:SetPoint("TOP", CheckboxTopX + 45, CheckboxTopY + -60)
		CheckboxShowHealthMinusValue:SetWidth(20) -- width
		CheckboxShowHealthMinusValue:SetHeight(20) -- height

		-- Label for the checkbox  for Health -
		local CheckboxShowHealthMinusValueLabel = checkboxFrame:CreateFontString("CheckboxShowHealthMinusValueLabel", "OVERLAY", "GameFontNormal")
		CheckboxShowHealthMinusValueLabel:SetPoint("RIGHT", CheckboxShowHealthMinusValue, "LEFT", -5, 0)
		CheckboxShowHealthMinusValueLabel:SetText("- Value")

		-- Create the checkbox for Health %
		local CheckboxShowHealthPercentageValue = CreateFrame("CheckButton", "CheckboxShowHealthPercentageValue", checkboxFrame, "UICheckButtonTemplate")
		CheckboxShowHealthPercentageValue:SetPoint("TOP", CheckboxTopX + 125, CheckboxTopY + -60)
		CheckboxShowHealthPercentageValue:SetWidth(20) -- width
		CheckboxShowHealthPercentageValue:SetHeight(20) -- height

		-- Label for the checkbox  for Health %
		local CheckboxShowHealthPercentageValueLabel = checkboxFrame:CreateFontString("CheckboxShowHealthPercentageValueLabel", "OVERLAY", "GameFontNormal")
		CheckboxShowHealthPercentageValueLabel:SetPoint("RIGHT", CheckboxShowHealthPercentageValue, "LEFT", -5, 0)
		CheckboxShowHealthPercentageValueLabel:SetText("% Value")
		
	--END-- OPTION: Show Health As
	
	----------------------------------------------------------------------------------------------------------------------------------------------
	
	--START-- OPTION: Show Scrolling Combat Text
		
		-- Create the checkbox
		local CheckboxShowScrollingText = CreateFrame("CheckButton", "CheckboxShowScrollingText", checkboxFrame, "UICheckButtonTemplate")
		CheckboxShowScrollingText:SetPoint("TOP", CheckboxTopX + -62, CheckboxTopY + -95)
		CheckboxShowScrollingText:SetWidth(20) -- width
		CheckboxShowScrollingText:SetHeight(20) -- height
		CheckboxShowScrollingText:SetScript("OnEnter", function() ShowTooltip(CheckboxShowScrollingText, "Check to show Damage and/or Healing taken on UI Frames.","Note: You also need to check Damage and/or Healing to determine which too display.") end)
		CheckboxShowScrollingText:SetScript("OnLeave", HideTooltip)
		CheckboxShowScrollingText:SetScript("OnClick", CheckboxShowScrollingTextOnClick)

		-- Label for the checkbox
		local CheckboxShowScrollingTextLabel = checkboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		CheckboxShowScrollingTextLabel:SetPoint("RIGHT", CheckboxShowScrollingText, "LEFT", -3, 0)
		CheckboxShowScrollingTextLabel:SetText("Show ScrollingText:")

		-- Create the "Damage:" checkbox
		local CheckboxShowDamage = CreateFrame("CheckButton", "CheckboxShowDamage", checkboxFrame, "UICheckButtonTemplate")
		CheckboxShowDamage:SetPoint("TOP", CheckboxTopX + 45, CheckboxTopY + -95)
		CheckboxShowDamage:SetWidth(20) -- width
		CheckboxShowDamage:SetHeight(20) -- height
		CheckboxShowDamage:SetScript("OnClick", CheckboxShowDamageOnClick)
	
		-- Label for the "Damage" checkbox
		local CheckboxShowDamageLabel = checkboxFrame:CreateFontString("CheckboxShowDamageLabel", "OVERLAY", "GameFontNormal")
		CheckboxShowDamageLabel:SetPoint("RIGHT", CheckboxShowDamage, "LEFT", -5, 0)
		CheckboxShowDamageLabel:SetText("Damage")
	
		-- Create the "Heal" checkbox
		local CheckboxShowHeal = CreateFrame("CheckButton", "CheckboxShowHeal", checkboxFrame, "UICheckButtonTemplate")
		CheckboxShowHeal:SetPoint("TOP", CheckboxTopX + 125, CheckboxTopY + -95)
		CheckboxShowHeal:SetWidth(20) -- width
		CheckboxShowHeal:SetHeight(20) -- height
		CheckboxShowHeal:SetScript("OnClick", CheckboxShowHealOnClick)
		
		-- Label for the "Heal" checkbox
		local CheckboxShowHealLabel = checkboxFrame:CreateFontString("CheckboxShowHealLabel", "OVERLAY", "GameFontNormal")
		CheckboxShowHealLabel:SetPoint("RIGHT", CheckboxShowHeal, "LEFT", -5, 0)
		CheckboxShowHealLabel:SetText("Healing")
	
	--END-- OPTION: Show Scrolling Combat Text

--END-- checkboxFrame Contents


--#########################################################################################################
-- END - Create Settings UI
--#########################################################################################################






--#########################################################################################################
--#########################################################################################################

--##START## Create Main Healing Interfaces UI

--## START ## Create the frame container for the Player elements, this contains the area that is used to heal the player, and there buffs.
PlayerContainer = CreateFrame("Frame", "PlayerContainer", UIParent)
PlayerContainer:SetWidth(200) -- width
PlayerContainer:SetHeight(150) -- height; this will get re adjusted after the UI elements that go inside it are built.
PlayerContainer:SetPoint("CENTER", 0, 0) -- position it at the center of the screen
PlayerContainer:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
-- Enable mouse interaction and register for dragging
PlayerContainer:EnableMouse(true)
PlayerContainer:SetMovable(true)
--PlayerContainer:SetFrameLevel(15)

--Note: The position of the Element is automatically saved by default by the WOW Client
-- Set scripts for drag start, drag stop
PlayerContainer:SetScript("OnMouseDown", function()
  local button = arg1
  if button == "LeftButton" and not PlayerContainer.isMoving then
   PlayerContainer:StartMoving();
   PlayerContainer.isMoving = true;
  end
end)

PlayerContainer:SetScript("OnMouseUp", function()
  local button = arg1
  if button == "LeftButton" and PlayerContainer.isMoving then
   PlayerContainer:StopMovingOrSizing();
   PlayerContainer.isMoving = false;
  end
end)

--## END ## Create the frame container for the Player elements, this contains the area that is used to heal the player, and there buffs.


--## START ## Create a header for the player container
-- Create a label for the player's name, class
-- Note: the label isn't given text here; it is done in the addon logic later
playerName = PlayerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
playerNamepaddingLeft = 2.5 -- adjust this value for left padding so the label doesn't appear against the edge of the container
playerNamepaddingTop = 5 -- adjust this value for top padding so the label doesn't appear against the edge of the container
playerName:SetPoint("TOPLEFT", PlayerContainer, "TOPLEFT", playerNamepaddingLeft, -playerNamepaddingTop) -- position it at the top left of the frame with padding
--## END ## Create a header for the player container

--## START ## Create a 'button' to show the settings frame
-- Create a frame
local playerSettingsFrame = CreateFrame("Frame", nil, PlayerContainer)

-- Set its size

playerSettingsFrame:SetWidth(53) -- width
playerSettingsFrame:SetHeight(20) -- height
-- Position it at the top right of the PlayerContainer
playerSettingspaddingLeft = 2.5 -- adjust this value for left padding so the label doesn't appear against the edge of the container
playerSettingspaddingTop = 5 -- adjust this value for top padding so the label doesn't appear against the edge of the container
playerSettingsFrame:SetPoint("TOPRIGHT", PlayerContainer, "TOPRIGHT", 0, -5)

-- Create the font string
local playerSettings = playerSettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

-- Position it at the top left of the frame with padding
playerSettings:SetPoint("TOPLEFT", playerSettingsFrame, "TOPLEFT")

-- Set the text
playerSettings:SetText("SETTINGS")

-- Change the font size
playerSettings:SetFont("Fonts\\FRIZQT__.TTF", 10)

-- Change the color to red and alpha to 0.5
playerSettings:SetTextColor(1, 1, 1, 0.2)
playerSettingsFrame:EnableMouse(true)
-- Add an OnClick event
playerSettingsFrame:SetScript("OnMouseUp", function()
	local ClickType = arg1
	
	if ClickType == "LeftButton" then
        -- Do something when the left mouse button is released
        
		 -- Check if the sForm frame exists
        if HM_SettingsContainer then
            -- Check if the frame is visible
            if HM_SettingsContainer:IsVisible() then
                -- If the frame is visible, hide it
                HM_SettingsContainer:Hide()
            else
                -- If the frame is not visible, show it
                HM_SettingsContainer:Show()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("HM_SettingsContainer frame not found.")
        end
		
	end
	
end)


--## END ## Create a 'button' to show the settings frame

--## START ## Create a status bar; this is the green progress bar that shows how full the players health is.
PlayerStatusBar = CreateFrame("StatusBar", "PlayerStatusBar", PlayerContainer)
PlayerStatusBar:SetWidth(200) -- width
PlayerStatusBar:SetHeight(25) -- height
PlayerStatusBarpaddingLeft = 2.5 -- adjust this value for left padding
PlayerStatusBarpaddingTop = 5 -- adjust this value for top padding
PlayerStatusBar:SetPoint("TOPLEFT", playerName, "BOTTOMLEFT", -PlayerStatusBarpaddingLeft, -PlayerStatusBarpaddingTop) -- position it at the bottom left of the player name
PlayerStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
PlayerStatusBar:SetMinMaxValues(0, 1)
PlayerStatusBar:SetValue(1)
PlayerStatusBar:SetStatusBarColor(0, 0.7529412, 0)

-- Create a background texture for the status bar
bg = PlayerStatusBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetTexture(0.5, 0.5, 0.5, 0.5) -- set color to light gray with high transparency
--## END ## Create a status bar; this is the green progress bar that shows how full the players health is.

--## START ## Create a status bar; Energy/mana/rage
PlayerPowerStatusBar = CreateFrame("StatusBar", "PlayerPowerStatusBar", PlayerContainer)
PlayerPowerStatusBar:SetWidth(200) -- width
PlayerPowerStatusBar:SetHeight(5) -- height
PlayerPowerStatusBarpaddingLeft = 2.5 -- adjust this value for left padding
PlayerPowerStatusBarpaddingTop = 30 -- adjust this value for top padding
PlayerPowerStatusBar:SetPoint("TOPLEFT", playerName, "BOTTOMLEFT", -PlayerPowerStatusBarpaddingLeft, -PlayerPowerStatusBarpaddingTop) -- position it at the bottom left of the player name
PlayerPowerStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
PlayerPowerStatusBar:SetMinMaxValues(0, 1)
PlayerPowerStatusBar:SetValue(1)
PlayerPowerStatusBar:SetStatusBarColor(0, 0, 1)
PlayerPowerStatusBar:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
--## END ## Create a status bar; Energy/mana/rage



--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a button; you can't see this button in the game only the text that is on the button.
--Note: It sits on top of the status bar so that you can appear to click the status bar to cast a healing spell. The status bar control doesn't let you us the OnClick event which you need to cast a spell that is why the button is needed.
PlayerButton = CreateFrame("Button", "PlayerButton", PlayerStatusBar, "UIPanelButtonTemplate")
PlayerButton:RegisterForClicks("LeftButtonUp", "RightButtonUp","MiddleButtonUp")
PlayerButton:EnableMouse(true)
-- Set its properties
PlayerButton:SetWidth(PlayerStatusBar:GetWidth()) -- width
PlayerButton:SetHeight(PlayerStatusBar:GetHeight()) -- height
PlayerButton:SetText("0/0") -- change text to "0/0"
PlayerButton:SetPoint("CENTER", 0, 0) -- position it at the center of the screen

-- Remove the button textures for normal, hover and click states
PlayerButton:SetNormalTexture(nil)
PlayerButton:SetHighlightTexture(nil)
PlayerButton:SetPushedTexture(nil)
--## END ## Create a button; you can't see this button in the game only the text that is on the button.

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a panel for player buff/debuff icons
PlayerBuffPanel = CreateFrame("Frame", "PlayerBuffPanel", PlayerContainer)
PlayerBuffPanel:SetWidth(200) -- width
PlayerBuffPanel:SetHeight(25) -- height
--PlayerBuffPanelpaddingLeft = 0 -- adjust this value for left padding
PlayerBuffPanelpaddingTop = 0 -- adjust this value for top padding
PlayerBuffPanel:SetPoint("TOPLEFT", PlayerPowerStatusBar, "BOTTOMLEFT", 0, -PlayerBuffPanelpaddingTop) -- position it at the bottom left of the player name
PlayerBuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of PlayerContainer
local totalHeight = playerName:GetHeight() + playerNamepaddingTop + PlayerStatusBar:GetHeight() + PlayerStatusBarpaddingTop + PlayerBuffPanel:GetHeight() + PlayerBuffPanelpaddingTop
PlayerContainer:SetHeight(totalHeight+17) --10
--## END ## Create a panel for player buff/debuff icons

--##END## Create Player UI


--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--##START## Create Party1 UI

--## START ## Create the frame container for the Player elements, this contains the area that is used to heal the player, and there buffs.
Party1Container = CreateFrame("Frame", "Party1Container", UIParent) --type, name, parent
Party1Container:SetWidth(200) -- width
Party1Container:SetHeight(150) -- height; this will get re adjusted after the UI elements that go inside it are built.
Party1Container:SetPoint("TOPLEFT", PlayerContainer, "BOTTOMLEFT", 0, 0) -- position it at the top left of the frame with padding
Party1Container:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
-- Enable mouse interaction and register for dragging
Party1Container:EnableMouse(true)
Party1Container:SetMovable(true)


--Note: The position of the Element is automatically saved by default by the WOW Client
-- Set scripts for drag start, drag stop
Party1Container:SetScript("OnMouseDown", function()
  local button = arg1
  if button == "LeftButton" and not Party1Container.isMoving then
   Party1Container:StartMoving();
   Party1Container.isMoving = true;
  end
end)

Party1Container:SetScript("OnMouseUp", function()
  local button = arg1
  if button == "LeftButton" and Party1Container.isMoving then
   Party1Container:StopMovingOrSizing();
   Party1Container.isMoving = false;
  end
end)

--## END ## Create the frame container for the Party1 elements, this contains the area that is used to heal the Party1, and there buffs.


--## START ## Create a header for the Party1 container
-- Create a label for the Party1's name, class
-- Note: the label isn't given text here; it is done in the addon logic later
Party1Name = Party1Container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Party1NamepaddingLeft = 2.5 -- adjust this value for left padding so the label doesn't appear against the edge of the container
Party1NamepaddingTop = 5 -- adjust this value for top padding so the label doesn't appear against the edge of the container
Party1Name:SetPoint("TOPLEFT", Party1Container, "TOPLEFT", Party1NamepaddingLeft, -Party1NamepaddingTop) -- position it at the top left of the frame with padding
--## END ## Create a header for the Party1 container



--## START ## Create a status bar; this is the green progress bar that shows how full the Party1s health is.
Party1StatusBar = CreateFrame("StatusBar", "Party1StatusBar", Party1Container)
Party1StatusBar:SetWidth(200) -- width
Party1StatusBar:SetHeight(25) -- height
Party1StatusBarpaddingLeft = 2.5 -- adjust this value for left padding
Party1StatusBarpaddingTop = 5 -- adjust this value for top padding
Party1StatusBar:SetPoint("TOPLEFT", Party1Name, "BOTTOMLEFT", -Party1StatusBarpaddingLeft, -Party1StatusBarpaddingTop) -- position it at the bottom left of the Party1 name
Party1StatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Party1StatusBar:SetMinMaxValues(0, 1)
Party1StatusBar:SetValue(1)
Party1StatusBar:SetStatusBarColor(0, 0.7529412, 0)

-- Create a background texture for the status bar
bg = Party1StatusBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetTexture(0.5, 0.5, 0.5, 0.5) -- set color to light gray with high transparency
--## END ## Create a status bar; this is the green progress bar that shows how full the Party1s health is.

--## START ## Create a status bar; Energy/mana/rage
Party1PowerStatusBar = CreateFrame("StatusBar", "Party1PowerStatusBar", Party1Container)
Party1PowerStatusBar:SetWidth(200) -- width
Party1PowerStatusBar:SetHeight(5) -- height
Party1PowerStatusBarpaddingLeft = 2.5 -- adjust this value for left padding
Party1PowerStatusBarpaddingTop = 30 -- adjust this value for top padding
Party1PowerStatusBar:SetPoint("TOPLEFT", Party1Name, "BOTTOMLEFT", -Party1PowerStatusBarpaddingLeft, -Party1PowerStatusBarpaddingTop) -- position it at the bottom left of the player name
Party1PowerStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Party1PowerStatusBar:SetMinMaxValues(0, 1)
Party1PowerStatusBar:SetValue(1)
Party1PowerStatusBar:SetStatusBarColor(0, 0, 1)
Party1PowerStatusBar:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--## END ## Create a status bar; Energy/mana/rage

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a button; you can't see this button in the game only the text that is on the button.
--Note: It sits on top of the status bar so that you can appear to click the status bar to cast a healing spell. The status bar control doesn't let you us the OnClick event which you need to cast a spell that is why the button is needed.
Party1Button = CreateFrame("Button", "Party1Button", Party1StatusBar, "UIPanelButtonTemplate")
Party1Button:RegisterForClicks("LeftButtonUp", "RightButtonUp","MiddleButtonUp")
Party1Button:EnableMouse(true)
-- Set its properties
Party1Button:SetWidth(Party1StatusBar:GetWidth()) -- width
Party1Button:SetHeight(Party1StatusBar:GetHeight()) -- height
Party1Button:SetText("0/0") -- change text to "0/0"
Party1Button:SetPoint("CENTER", 0, 0) -- position it at the center of the screen

-- Remove the button textures for normal, hover and click states
Party1Button:SetNormalTexture(nil)
Party1Button:SetHighlightTexture(nil)
Party1Button:SetPushedTexture(nil)
--## END ## Create a button; you can't see this button in the game only the text that is on the button.

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a panel for Party1 buff/debuff icons
Party1BuffPanel = CreateFrame("Frame", "Party1BuffPanel", Party1Container)
Party1BuffPanel:SetWidth(200) -- width
Party1BuffPanel:SetHeight(25) -- height
--Party1BuffPanelpaddingLeft = 0 -- adjust this value for left padding
Party1BuffPanelpaddingTop = 0 -- adjust this value for top padding
Party1BuffPanel:SetPoint("TOPLEFT", Party1PowerStatusBar, "BOTTOMLEFT", 0, -Party1BuffPanelpaddingTop) -- position it at the bottom left of the Party1 name
Party1BuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of Party1Container
local Party1TotalHeight = Party1Name:GetHeight() + Party1NamepaddingTop + Party1StatusBar:GetHeight() + Party1StatusBarpaddingTop + Party1BuffPanel:GetHeight() + Party1BuffPanelpaddingTop
Party1Container:SetHeight(Party1TotalHeight+17) --10
--## END ## Create a panel for Party1 buff/debuff icons

--##END## Create Party1 UI


--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--##START## Create Party2 UI

--## START ## Create the frame container for the Player elements, this contains the area that is used to heal the player, and there buffs.
Party2Container = CreateFrame("Frame", "Party2Container", UIParent) --type, name, parent
Party2Container:SetWidth(200) -- width
Party2Container:SetHeight(150) -- height; this will get re adjusted after the UI elements that go inside it are built.
Party2Container:SetPoint("TOPLEFT", Party1Container, "BOTTOMLEFT", 0, 0) -- position it at the top left of the frame with padding
Party2Container:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
-- Enable mouse interaction and register for dragging
Party2Container:EnableMouse(true)
Party2Container:SetMovable(true)


--Note: The position of the Element is automatically saved by default by the WOW Client
-- Set scripts for drag start, drag stop
Party2Container:SetScript("OnMouseDown", function()
  local button = arg1
  if button == "LeftButton" and not Party2Container.isMoving then
   Party2Container:StartMoving();
   Party2Container.isMoving = true;
  end
end)

Party2Container:SetScript("OnMouseUp", function()
  local button = arg1
  if button == "LeftButton" and Party2Container.isMoving then
   Party2Container:StopMovingOrSizing();
   Party2Container.isMoving = false;
  end
end)

--## END ## Create the frame container for the Party2 elements, this contains the area that is used to heal the Party2, and there buffs.


--## START ## Create a header for the Party2 container
-- Create a label for the Party2's name, class
-- Note: the label isn't given text here; it is done in the addon logic later
Party2Name = Party2Container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Party2NamepaddingLeft = 2.5 -- adjust this value for left padding so the label doesn't appear against the edge of the container
Party2NamepaddingTop = 5 -- adjust this value for top padding so the label doesn't appear against the edge of the container
Party2Name:SetPoint("TOPLEFT", Party2Container, "TOPLEFT", Party2NamepaddingLeft, -Party2NamepaddingTop) -- position it at the top left of the frame with padding
--## END ## Create a header for the Party2 container



--## START ## Create a status bar; this is the green progress bar that shows how full the Party2s health is.
Party2StatusBar = CreateFrame("StatusBar", "Party2StatusBar", Party2Container)
Party2StatusBar:SetWidth(200) -- width
Party2StatusBar:SetHeight(25) -- height
Party2StatusBarpaddingLeft = 2.5 -- adjust this value for left padding
Party2StatusBarpaddingTop = 5 -- adjust this value for top padding
Party2StatusBar:SetPoint("TOPLEFT", Party2Name, "BOTTOMLEFT", -Party2StatusBarpaddingLeft, -Party2StatusBarpaddingTop) -- position it at the bottom left of the Party2 name
Party2StatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Party2StatusBar:SetMinMaxValues(0, 1)
Party2StatusBar:SetValue(1)
Party2StatusBar:SetStatusBarColor(0, 0.7529412, 0)

-- Create a background texture for the status bar
bg = Party2StatusBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetTexture(0.5, 0.5, 0.5, 0.5) -- set color to light gray with high transparency
--## END ## Create a status bar; this is the green progress bar that shows how full the Party2s health is.

--## START ## Create a status bar; Energy/mana/rage
Party2PowerStatusBar = CreateFrame("StatusBar", "Party2PowerStatusBar", Party2Container)
Party2PowerStatusBar:SetWidth(200) -- width
Party2PowerStatusBar:SetHeight(5) -- height
Party2PowerStatusBarpaddingLeft = 2.5 -- adjust this value for left padding
Party2PowerStatusBarpaddingTop = 30 -- adjust this value for top padding
Party2PowerStatusBar:SetPoint("TOPLEFT", Party2Name, "BOTTOMLEFT", -Party2PowerStatusBarpaddingLeft, -Party2PowerStatusBarpaddingTop) -- position it at the bottom left of the player name
Party2PowerStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Party2PowerStatusBar:SetMinMaxValues(0, 1)
Party2PowerStatusBar:SetValue(1)
Party2PowerStatusBar:SetStatusBarColor(0, 0, 1)
Party2PowerStatusBar:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--## END ## Create a status bar; Energy/mana/rage

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a button; you can't see this button in the game only the text that is on the button.
--Note: It sits on top of the status bar so that you can appear to click the status bar to cast a healing spell. The status bar control doesn't let you us the OnClick event which you need to cast a spell that is why the button is needed.
Party2Button = CreateFrame("Button", "Party2Button", Party2StatusBar, "UIPanelButtonTemplate")
Party2Button:RegisterForClicks("LeftButtonUp", "RightButtonUp","MiddleButtonUp")
Party2Button:EnableMouse(true)
-- Set its properties
Party2Button:SetWidth(Party2StatusBar:GetWidth()) -- width
Party2Button:SetHeight(Party2StatusBar:GetHeight()) -- height
Party2Button:SetText("0/0") -- change text to "0/0"
Party2Button:SetPoint("CENTER", 0, 0) -- position it at the center of the screen

-- Remove the button textures for normal, hover and click states
Party2Button:SetNormalTexture(nil)
Party2Button:SetHighlightTexture(nil)
Party2Button:SetPushedTexture(nil)
--## END ## Create a button; you can't see this button in the game only the text that is on the button.

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a panel for Party2 buff/debuff icons
Party2BuffPanel = CreateFrame("Frame", "Party2BuffPanel", Party2Container)
Party2BuffPanel:SetWidth(200) -- width
Party2BuffPanel:SetHeight(25) -- height
--Party2BuffPanelpaddingLeft = 0 -- adjust this value for left padding
Party2BuffPanelpaddingTop = 0 -- adjust this value for top padding
Party2BuffPanel:SetPoint("TOPLEFT", Party2PowerStatusBar, "BOTTOMLEFT", 0, -Party2BuffPanelpaddingTop) -- position it at the bottom left of the Party2 name
Party2BuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of Party2Container
local Party2TotalHeight = Party2Name:GetHeight() + Party2NamepaddingTop + Party2StatusBar:GetHeight() + Party2StatusBarpaddingTop + Party2BuffPanel:GetHeight() + Party2BuffPanelpaddingTop
Party2Container:SetHeight(Party2TotalHeight+17) --10
--## END ## Create a panel for Party2 buff/debuff icons

--##END## Create Party2 UI


--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--##START## Create Party1 UI

--## START ## Create the frame container for the Player elements, this contains the area that is used to heal the player, and there buffs.
Party3Container = CreateFrame("Frame", "Party3Container", UIParent) --type, name, parent
Party3Container:SetWidth(200) -- width
Party3Container:SetHeight(150) -- height; this will get re adjusted after the UI elements that go inside it are built.
Party3Container:SetPoint("TOPLEFT", PlayerContainer, "BOTTOMLEFT", 0, 0) -- position it at the top left of the frame with padding
Party3Container:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
-- Enable mouse interaction and register for dragging
Party3Container:EnableMouse(true)
Party3Container:SetMovable(true)


--Note: The position of the Element is automatically saved by default by the WOW Client
-- Set scripts for drag start, drag stop
Party3Container:SetScript("OnMouseDown", function()
  local button = arg1
  if button == "LeftButton" and not Party3Container.isMoving then
   Party3Container:StartMoving();
   Party3Container.isMoving = true;
  end
end)

Party3Container:SetScript("OnMouseUp", function()
  local button = arg1
  if button == "LeftButton" and Party3Container.isMoving then
   Party3Container:StopMovingOrSizing();
   Party3Container.isMoving = false;
  end
end)

--## END ## Create the frame container for the Party3 elements, this contains the area that is used to heal the Party3, and there buffs.


--## START ## Create a header for the Party3 container
-- Create a label for the Party3's name, class
-- Note: the label isn't given text here; it is done in the addon logic later
Party3Name = Party3Container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Party3NamepaddingLeft = 2.5 -- adjust this value for left padding so the label doesn't appear against the edge of the container
Party3NamepaddingTop = 5 -- adjust this value for top padding so the label doesn't appear against the edge of the container
Party3Name:SetPoint("TOPLEFT", Party3Container, "TOPLEFT", Party3NamepaddingLeft, -Party3NamepaddingTop) -- position it at the top left of the frame with padding
--## END ## Create a header for the Party3 container



--## START ## Create a status bar; this is the green progress bar that shows how full the Party3s health is.
Party3StatusBar = CreateFrame("StatusBar", "Party3StatusBar", Party3Container)
Party3StatusBar:SetWidth(200) -- width
Party3StatusBar:SetHeight(25) -- height
Party3StatusBarpaddingLeft = 2.5 -- adjust this value for left padding
Party3StatusBarpaddingTop = 5 -- adjust this value for top padding
Party3StatusBar:SetPoint("TOPLEFT", Party3Name, "BOTTOMLEFT", -Party3StatusBarpaddingLeft, -Party3StatusBarpaddingTop) -- position it at the bottom left of the Party3 name
Party3StatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Party3StatusBar:SetMinMaxValues(0, 1)
Party3StatusBar:SetValue(1)
Party3StatusBar:SetStatusBarColor(0, 0.7529412, 0)

-- Create a background texture for the status bar
bg = Party3StatusBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetTexture(0.5, 0.5, 0.5, 0.5) -- set color to light gray with high transparency
--## END ## Create a status bar; this is the green progress bar that shows how full the Party3s health is.

--## START ## Create a status bar; Energy/mana/rage
Party3PowerStatusBar = CreateFrame("StatusBar", "Party3PowerStatusBar", Party3Container)
Party3PowerStatusBar:SetWidth(200) -- width
Party3PowerStatusBar:SetHeight(5) -- height
Party3PowerStatusBarpaddingLeft = 2.5 -- adjust this value for left padding
Party3PowerStatusBarpaddingTop = 30 -- adjust this value for top padding
Party3PowerStatusBar:SetPoint("TOPLEFT", Party3Name, "BOTTOMLEFT", -Party3PowerStatusBarpaddingLeft, -Party3PowerStatusBarpaddingTop) -- position it at the bottom left of the player name
Party3PowerStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Party3PowerStatusBar:SetMinMaxValues(0, 1)
Party3PowerStatusBar:SetValue(1)
Party3PowerStatusBar:SetStatusBarColor(0, 0, 1)
Party3PowerStatusBar:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--## END ## Create a status bar; Energy/mana/rage

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a button; you can't see this button in the game only the text that is on the button.
--Note: It sits on top of the status bar so that you can appear to click the status bar to cast a healing spell. The status bar control doesn't let you us the OnClick event which you need to cast a spell that is why the button is needed.
Party3Button = CreateFrame("Button", "Party3Button", Party3StatusBar, "UIPanelButtonTemplate")
Party3Button:RegisterForClicks("LeftButtonUp", "RightButtonUp","MiddleButtonUp")
Party3Button:EnableMouse(true)
-- Set its properties
Party3Button:SetWidth(Party3StatusBar:GetWidth()) -- width
Party3Button:SetHeight(Party3StatusBar:GetHeight()) -- height
Party3Button:SetText("0/0") -- change text to "0/0"
Party3Button:SetPoint("CENTER", 0, 0) -- position it at the center of the screen

-- Remove the button textures for normal, hover and click states
Party3Button:SetNormalTexture(nil)
Party3Button:SetHighlightTexture(nil)
Party3Button:SetPushedTexture(nil)
--## END ## Create a button; you can't see this button in the game only the text that is on the button.

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a panel for Party3 buff/debuff icons
Party3BuffPanel = CreateFrame("Frame", "Party3BuffPanel", Party3Container)
Party3BuffPanel:SetWidth(200) -- width
Party3BuffPanel:SetHeight(25) -- height
--Party3BuffPanelpaddingLeft = 0 -- adjust this value for left padding
Party3BuffPanelpaddingTop = 0 -- adjust this value for top padding
Party3BuffPanel:SetPoint("TOPLEFT", Party3PowerStatusBar, "BOTTOMLEFT", 0, -Party3BuffPanelpaddingTop) -- position it at the bottom left of the Party3 name
Party3BuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of Party3Container
local Party3TotalHeight = Party3Name:GetHeight() + Party3NamepaddingTop + Party3StatusBar:GetHeight() + Party3StatusBarpaddingTop + Party3BuffPanel:GetHeight() + Party3BuffPanelpaddingTop
Party3Container:SetHeight(Party3TotalHeight+17) --10
--## END ## Create a panel for Party3 buff/debuff icons

--##END## Create Party3 UI


--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--##START## Create Party4 UI

--## START ## Create the frame container for the Player elements, this contains the area that is used to heal the player, and there buffs.
Party4Container = CreateFrame("Frame", "Party4Container", UIParent) --type, name, parent
Party4Container:SetWidth(200) -- width
Party4Container:SetHeight(150) -- height; this will get re adjusted after the UI elements that go inside it are built.
Party4Container:SetPoint("TOPLEFT", PlayerContainer, "BOTTOMLEFT", 0, 0) -- position it at the top left of the frame with padding
Party4Container:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
-- Enable mouse interaction and register for dragging
Party4Container:EnableMouse(true)
Party4Container:SetMovable(true)


--Note: The position of the Element is automatically saved by default by the WOW Client
-- Set scripts for drag start, drag stop
Party4Container:SetScript("OnMouseDown", function()
  local button = arg1
  if button == "LeftButton" and not Party4Container.isMoving then
   Party4Container:StartMoving();
   Party4Container.isMoving = true;
  end
end)

Party4Container:SetScript("OnMouseUp", function()
  local button = arg1
  if button == "LeftButton" and Party4Container.isMoving then
   Party4Container:StopMovingOrSizing();
   Party4Container.isMoving = false;
  end
end)

--## END ## Create the frame container for the Party4 elements, this contains the area that is used to heal the Party4, and there buffs.


--## START ## Create a header for the Party4 container
-- Create a label for the Party4's name, class
-- Note: the label isn't given text here; it is done in the addon logic later
Party4Name = Party4Container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Party4NamepaddingLeft = 2.5 -- adjust this value for left padding so the label doesn't appear against the edge of the container
Party4NamepaddingTop = 5 -- adjust this value for top padding so the label doesn't appear against the edge of the container
Party4Name:SetPoint("TOPLEFT", Party4Container, "TOPLEFT", Party4NamepaddingLeft, -Party4NamepaddingTop) -- position it at the top left of the frame with padding
--## END ## Create a header for the Party4 container



--## START ## Create a status bar; this is the green progress bar that shows how full the Party4s health is.
Party4StatusBar = CreateFrame("StatusBar", "Party4StatusBar", Party4Container)
Party4StatusBar:SetWidth(200) -- width
Party4StatusBar:SetHeight(25) -- height
Party4StatusBarpaddingLeft = 2.5 -- adjust this value for left padding
Party4StatusBarpaddingTop = 5 -- adjust this value for top padding
Party4StatusBar:SetPoint("TOPLEFT", Party4Name, "BOTTOMLEFT", -Party4StatusBarpaddingLeft, -Party4StatusBarpaddingTop) -- position it at the bottom left of the Party4 name
Party4StatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Party4StatusBar:SetMinMaxValues(0, 1)
Party4StatusBar:SetValue(1)
Party4StatusBar:SetStatusBarColor(0, 0.7529412, 0)

-- Create a background texture for the status bar
bg = Party4StatusBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetTexture(0.5, 0.5, 0.5, 0.5) -- set color to light gray with high transparency
--## END ## Create a status bar; this is the green progress bar that shows how full the Party4s health is.

--## START ## Create a status bar; Energy/mana/rage
Party4PowerStatusBar = CreateFrame("StatusBar", "Party4PowerStatusBar", Party4Container)
Party4PowerStatusBar:SetWidth(200) -- width
Party4PowerStatusBar:SetHeight(5) -- height
Party4PowerStatusBarpaddingLeft = 2.5 -- adjust this value for left padding
Party4PowerStatusBarpaddingTop = 30 -- adjust this value for top padding
Party4PowerStatusBar:SetPoint("TOPLEFT", Party4Name, "BOTTOMLEFT", -Party4PowerStatusBarpaddingLeft, -Party4PowerStatusBarpaddingTop) -- position it at the bottom left of the player name
Party4PowerStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Party4PowerStatusBar:SetMinMaxValues(0, 1)
Party4PowerStatusBar:SetValue(1)
Party4PowerStatusBar:SetStatusBarColor(0, 0, 1)
Party4PowerStatusBar:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--## END ## Create a status bar; Energy/mana/rage

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a button; you can't see this button in the game only the text that is on the button.
--Note: It sits on top of the status bar so that you can appear to click the status bar to cast a healing spell. The status bar control doesn't let you us the OnClick event which you need to cast a spell that is why the button is needed.
Party4Button = CreateFrame("Button", "Party4Button", Party4StatusBar, "UIPanelButtonTemplate")
Party4Button:RegisterForClicks("LeftButtonUp", "RightButtonUp","MiddleButtonUp")
Party4Button:EnableMouse(true)
-- Set its properties
Party4Button:SetWidth(Party4StatusBar:GetWidth()) -- width
Party4Button:SetHeight(Party4StatusBar:GetHeight()) -- height
Party4Button:SetText("0/0") -- change text to "0/0"
Party4Button:SetPoint("CENTER", 0, 0) -- position it at the center of the screen

-- Remove the button textures for normal, hover and click states
Party4Button:SetNormalTexture(nil)
Party4Button:SetHighlightTexture(nil)
Party4Button:SetPushedTexture(nil)
--## END ## Create a button; you can't see this button in the game only the text that is on the button.

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a panel for Party4 buff/debuff icons
Party4BuffPanel = CreateFrame("Frame", "Party4BuffPanel", Party4Container)
Party4BuffPanel:SetWidth(200) -- width
Party4BuffPanel:SetHeight(25) -- height
--Party4BuffPanelpaddingLeft = 0 -- adjust this value for left padding
Party4BuffPanelpaddingTop = 0 -- adjust this value for top padding
Party4BuffPanel:SetPoint("TOPLEFT", Party4PowerStatusBar, "BOTTOMLEFT", 0, -Party4BuffPanelpaddingTop) -- position it at the bottom left of the Party4 name
Party4BuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of Party4Container
local Party4TotalHeight = Party4Name:GetHeight() + Party4NamepaddingTop + Party4StatusBar:GetHeight() + Party4StatusBarpaddingTop + Party4BuffPanel:GetHeight() + Party4BuffPanelpaddingTop
Party4Container:SetHeight(Party4TotalHeight+17) --10
--## END ## Create a panel for Party4 buff/debuff icons

--##END## Create Party4 UI


--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################







--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--##START## Create Target UI

--## START ## Create the frame container for the Player elements, this contains the area that is used to heal the player, and there buffs.
TargetContainer = CreateFrame("Frame", "TargetContainer", UIParent) --type, name, parent
TargetContainer:SetWidth(200) -- width
TargetContainer:SetHeight(150) -- height; this will get re adjusted after the UI elements that go inside it are built.
TargetContainer:SetPoint("TOPLEFT", PlayerContainer, "BOTTOMLEFT", 0, 0) -- position it at the top left of the frame with padding
TargetContainer:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
-- Enable mouse interaction and register for dragging
TargetContainer:EnableMouse(true)
TargetContainer:SetMovable(true)


--Note: The position of the Element is automatically saved by default by the WOW Client
-- Set scripts for drag start, drag stop
TargetContainer:SetScript("OnMouseDown", function()
  local button = arg1
  if button == "LeftButton" and not TargetContainer.isMoving then
   TargetContainer:StartMoving();
   TargetContainer.isMoving = true;
  end
end)

TargetContainer:SetScript("OnMouseUp", function()
  local button = arg1
  if button == "LeftButton" and TargetContainer.isMoving then
   TargetContainer:StopMovingOrSizing();
   TargetContainer.isMoving = false;
  end
end)

--## END ## Create the frame container for the Target elements, this contains the area that is used to heal the Target, and there buffs.


--## START ## Create a header for the Target container
-- Create a label for the Target's name, class
-- Note: the label isn't given text here; it is done in the addon logic later
TargetName = TargetContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TargetNamepaddingLeft = 2.5 -- adjust this value for left padding so the label doesn't appear against the edge of the container
TargetNamepaddingTop = 5 -- adjust this value for top padding so the label doesn't appear against the edge of the container
TargetName:SetPoint("TOPLEFT", TargetContainer, "TOPLEFT", TargetNamepaddingLeft, -TargetNamepaddingTop) -- position it at the top left of the frame with padding
--## END ## Create a header for the Target container



--## START ## Create a status bar; this is the green progress bar that shows how full the Targets health is.
TargetStatusBar = CreateFrame("StatusBar", "TargetStatusBar", TargetContainer)
TargetStatusBar:SetWidth(200) -- width
TargetStatusBar:SetHeight(25) -- height
TargetStatusBarpaddingLeft = 2.5 -- adjust this value for left padding
TargetStatusBarpaddingTop = 5 -- adjust this value for top padding
TargetStatusBar:SetPoint("TOPLEFT", TargetName, "BOTTOMLEFT", -TargetStatusBarpaddingLeft, -TargetStatusBarpaddingTop) -- position it at the bottom left of the Target name
TargetStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
TargetStatusBar:SetMinMaxValues(0, 1)
TargetStatusBar:SetValue(1)
TargetStatusBar:SetStatusBarColor(0, 0.7529412, 0)

-- Create a background texture for the status bar
bg = TargetStatusBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetTexture(0.5, 0.5, 0.5, 0.5) -- set color to light gray with high transparency
--## END ## Create a status bar; this is the green progress bar that shows how full the Targets health is.

--## START ## Create a status bar; Energy/mana/rage
TargetPowerStatusBar = CreateFrame("StatusBar", "TargetPowerStatusBar", TargetContainer)
TargetPowerStatusBar:SetWidth(200) -- width
TargetPowerStatusBar:SetHeight(5) -- height
TargetPowerStatusBarpaddingLeft = 2.5 -- adjust this value for left padding
TargetPowerStatusBarpaddingTop = 30 -- adjust this value for top padding
TargetPowerStatusBar:SetPoint("TOPLEFT", TargetName, "BOTTOMLEFT", -TargetPowerStatusBarpaddingLeft, -TargetPowerStatusBarpaddingTop) -- position it at the bottom left of the player name
TargetPowerStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
TargetPowerStatusBar:SetMinMaxValues(0, 1)
TargetPowerStatusBar:SetValue(1)
TargetPowerStatusBar:SetStatusBarColor(0, 0, 1)
TargetPowerStatusBar:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--## END ## Create a status bar; Energy/mana/rage

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a button; you can't see this button in the game only the text that is on the button.
--Note: It sits on top of the status bar so that you can appear to click the status bar to cast a healing spell. The status bar control doesn't let you us the OnClick event which you need to cast a spell that is why the button is needed.
TargetButton = CreateFrame("Button", "TargetButton", TargetStatusBar, "UIPanelButtonTemplate")
TargetButton:RegisterForClicks("LeftButtonUp", "RightButtonUp","MiddleButtonUp")
TargetButton:EnableMouse(true)
-- Set its properties
TargetButton:SetWidth(TargetStatusBar:GetWidth()) -- width
TargetButton:SetHeight(TargetStatusBar:GetHeight()) -- height
TargetButton:SetText("0/0") -- change text to "0/0"
TargetButton:SetPoint("CENTER", 0, 0) -- position it at the center of the screen

-- Remove the button textures for normal, hover and click states
TargetButton:SetNormalTexture(nil)
TargetButton:SetHighlightTexture(nil)
TargetButton:SetPushedTexture(nil)
--## END ## Create a button; you can't see this button in the game only the text that is on the button.

--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

--## START ## Create a panel for Target buff/debuff icons
TargetBuffPanel = CreateFrame("Frame", "TargetBuffPanel", TargetContainer)
TargetBuffPanel:SetWidth(200) -- width
TargetBuffPanel:SetHeight(25) -- height
--TargetBuffPanelpaddingLeft = 0 -- adjust this value for left padding
TargetBuffPanelpaddingTop = 0 -- adjust this value for top padding
TargetBuffPanel:SetPoint("TOPLEFT", TargetPowerStatusBar, "BOTTOMLEFT", 0, -TargetBuffPanelpaddingTop) -- position it at the bottom left of the Target name
TargetBuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of TargetContainer
local TargetTotalHeight = TargetName:GetHeight() + TargetNamepaddingTop + TargetStatusBar:GetHeight() + TargetStatusBarpaddingTop + TargetBuffPanel:GetHeight() + TargetBuffPanelpaddingTop
TargetContainer:SetHeight(TargetTotalHeight+17) --10
--## END ## Create a panel for Target buff/debuff icons

--##END## Create Target UI


--START -- Scrolling Text Frames

-- Create a frame for the text

	--PLAYER
	local PlayerScrollingDamageFrame = CreateFrame("Frame", "PlayerScrollingDamageFrame", UIParent)
	PlayerScrollingDamageFrame:SetWidth(100) -- width
	PlayerScrollingDamageFrame:SetHeight(20) -- height
	PlayerScrollingDamageFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	PlayerScrollingDamageFrame.text = PlayerScrollingDamageFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	PlayerScrollingDamageFrame.text:SetPoint("CENTER", 0, 0)
	PlayerScrollingDamageFrame:Hide() -- Hide the frame initially
	PlayerScrollingDamageFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top

	local PlayerScrollingHealFrame = CreateFrame("Frame", "PlayerScrollingHealFrame", UIParent)
	PlayerScrollingHealFrame:SetWidth(100) -- width
	PlayerScrollingHealFrame:SetHeight(20) -- height
	PlayerScrollingHealFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	PlayerScrollingHealFrame.text = PlayerScrollingHealFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	PlayerScrollingHealFrame.text:SetPoint("CENTER", 0, 0)
	PlayerScrollingHealFrame:Hide() -- Hide the frame initially
	PlayerScrollingHealFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top

	--Party1
	local Party1ScrollingDamageFrame = CreateFrame("Frame", "Party1ScrollingDamageFrame", UIParent)
	Party1ScrollingDamageFrame:SetWidth(100) -- width
	Party1ScrollingDamageFrame:SetHeight(20) -- height
	Party1ScrollingDamageFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	Party1ScrollingDamageFrame.text = Party1ScrollingDamageFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Party1ScrollingDamageFrame.text:SetPoint("CENTER", 0, 0)
	Party1ScrollingDamageFrame:Hide() -- Hide the frame initially
	Party1ScrollingDamageFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top

	local Party1ScrollingHealFrame = CreateFrame("Frame", "Party1ScrollingHealFrame", UIParent)
	Party1ScrollingHealFrame:SetWidth(100) -- width
	Party1ScrollingHealFrame:SetHeight(20) -- height
	Party1ScrollingHealFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	Party1ScrollingHealFrame.text = Party1ScrollingHealFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Party1ScrollingHealFrame.text:SetPoint("CENTER", 0, 0)
	Party1ScrollingHealFrame:Hide() -- Hide the frame initially
	Party1ScrollingHealFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top
	
	--Party2
	local Party2ScrollingDamageFrame = CreateFrame("Frame", "Party2ScrollingDamageFrame", UIParent)
	Party2ScrollingDamageFrame:SetWidth(100) -- width
	Party2ScrollingDamageFrame:SetHeight(20) -- height
	Party2ScrollingDamageFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	Party2ScrollingDamageFrame.text = Party2ScrollingDamageFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Party2ScrollingDamageFrame.text:SetPoint("CENTER", 0, 0)
	Party2ScrollingDamageFrame:Hide() -- Hide the frame initially
	Party2ScrollingDamageFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top

	local Party2ScrollingHealFrame = CreateFrame("Frame", "Party2ScrollingHealFrame", UIParent)
	Party2ScrollingHealFrame:SetWidth(100) -- width
	Party2ScrollingHealFrame:SetHeight(20) -- height
	Party2ScrollingHealFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	Party2ScrollingHealFrame.text = Party2ScrollingHealFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Party2ScrollingHealFrame.text:SetPoint("CENTER", 0, 0)
	Party2ScrollingHealFrame:Hide() -- Hide the frame initially
	Party2ScrollingHealFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top
	
	--Party3
	local Party3ScrollingDamageFrame = CreateFrame("Frame", "Party3ScrollingDamageFrame", UIParent)
	Party3ScrollingDamageFrame:SetWidth(100) -- width
	Party3ScrollingDamageFrame:SetHeight(20) -- height
	Party3ScrollingDamageFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	Party3ScrollingDamageFrame.text = Party3ScrollingDamageFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Party3ScrollingDamageFrame.text:SetPoint("CENTER", 0, 0)
	Party3ScrollingDamageFrame:Hide() -- Hide the frame initially
	Party3ScrollingDamageFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top

	local Party3ScrollingHealFrame = CreateFrame("Frame", "Party3ScrollingHealFrame", UIParent)
	Party3ScrollingHealFrame:SetWidth(100) -- width
	Party3ScrollingHealFrame:SetHeight(20) -- height
	Party3ScrollingHealFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	Party3ScrollingHealFrame.text = Party3ScrollingHealFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Party3ScrollingHealFrame.text:SetPoint("CENTER", 0, 0)
	Party3ScrollingHealFrame:Hide() -- Hide the frame initially
	Party3ScrollingHealFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top

	--Party4
	local Party4ScrollingDamageFrame = CreateFrame("Frame", "Party4ScrollingDamageFrame", UIParent)
	Party4ScrollingDamageFrame:SetWidth(100) -- width
	Party4ScrollingDamageFrame:SetHeight(20) -- height
	Party4ScrollingDamageFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	Party4ScrollingDamageFrame.text = Party4ScrollingDamageFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Party4ScrollingDamageFrame.text:SetPoint("CENTER", 0, 0)
	Party4ScrollingDamageFrame:Hide() -- Hide the frame initially
	Party4ScrollingDamageFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top

	local Party4ScrollingHealFrame = CreateFrame("Frame", "Party4ScrollingHealFrame", UIParent)
	Party4ScrollingHealFrame:SetWidth(100) -- width
	Party4ScrollingHealFrame:SetHeight(20) -- height
	Party4ScrollingHealFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	Party4ScrollingHealFrame.text = Party4ScrollingHealFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Party4ScrollingHealFrame.text:SetPoint("CENTER", 0, 0)
	Party4ScrollingHealFrame:Hide() -- Hide the frame initially
	Party4ScrollingHealFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top
	
	--Target
	local TargetScrollingDamageFrame = CreateFrame("Frame", "TargetScrollingDamageFrame", UIParent)
	TargetScrollingDamageFrame:SetWidth(100) -- width
	TargetScrollingDamageFrame:SetHeight(20) -- height
	TargetScrollingDamageFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	TargetScrollingDamageFrame.text = TargetScrollingDamageFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	TargetScrollingDamageFrame.text:SetPoint("CENTER", 0, 0)
	TargetScrollingDamageFrame:Hide() -- Hide the frame initially
	TargetScrollingDamageFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top

	local TargetScrollingHealFrame = CreateFrame("Frame", "TargetScrollingHealFrame", UIParent)
	TargetScrollingHealFrame:SetWidth(100) -- width
	TargetScrollingHealFrame:SetHeight(20) -- height
	TargetScrollingHealFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
	TargetScrollingHealFrame.text = TargetScrollingHealFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	TargetScrollingHealFrame.text:SetPoint("CENTER", 0, 0)
	TargetScrollingHealFrame:Hide() -- Hide the frame initially
	TargetScrollingHealFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top
	--END -- Scrolling Text Frames

	-- ##END## Create Main Healing Interfaces UI
	
	
	
	
	--This was done so that i could consolidate the function that creates the UI frames
	--instead of having a different function for each player, party1, party2, party3, party4, target
	--I could still consolidate the buff ui parts of the code but i haven't done that yet.
	--TODO: Consolidate BuffUI creation. 
	local UI_Components = {}
	
	
	--Player UI Elements:
	UI_Components["player_PlayerName"] 		= playerName
	UI_Components["player_CastSpellButton"] = PlayerButton
	UI_Components["player_HealthBar"] 		= PlayerStatusBar
	UI_Components["player_PowerBar"] 		= PlayerPowerStatusBar	
	UI_Components["player_ScrollingDamageFrame"] 	= PlayerScrollingDamageFrame
	UI_Components["player_ScrollingHealFrame"] 		= PlayerScrollingHealFrame
	
	--Party1 UI Elements:
	UI_Components["party1_PlayerName"] 		= Party1Name
	UI_Components["party1_CastSpellButton"] = Party1Button
	UI_Components["party1_HealthBar"] 		= Party1StatusBar
	UI_Components["party1_PowerBar"] 		= Party1PowerStatusBar
	UI_Components["party1_ScrollingDamageFrame"] 	= Party1ScrollingDamageFrame
	UI_Components["party1_ScrollingHealFrame"] 		= Party1ScrollingHealFrame
	
	--Party2 UI Elements:
	UI_Components["party2_PlayerName"] 		= Party2Name
	UI_Components["party2_CastSpellButton"] = Party2Button
	UI_Components["party2_HealthBar"] 		= Party2StatusBar
	UI_Components["party2_PowerBar"] 		= Party2PowerStatusBar
	UI_Components["party2_ScrollingDamageFrame"] 	= Party2ScrollingDamageFrame
	UI_Components["party2_ScrollingHealFrame"] 		= Party2ScrollingHealFrame
	
	--Party3 UI Elements:
	UI_Components["party3_PlayerName"] 		= Party3Name
	UI_Components["party3_CastSpellButton"] = Party3Button
	UI_Components["party3_HealthBar"] 		= Party3StatusBar
	UI_Components["party3_PowerBar"] 		= Party3PowerStatusBar
	UI_Components["party3_ScrollingDamageFrame"] 	= Party3ScrollingDamageFrame
	UI_Components["party3_ScrollingHealFrame"] 		= Party3ScrollingHealFrame
	
	--Party4 UI Elements:
	UI_Components["party4_PlayerName"] 		= Party4Name
	UI_Components["party4_CastSpellButton"] = Party4Button
	UI_Components["party4_HealthBar"] 		= Party4StatusBar
	UI_Components["party4_PowerBar"] 		= Party4PowerStatusBar
	UI_Components["party4_ScrollingDamageFrame"] 	= Party4ScrollingDamageFrame
	UI_Components["party4_ScrollingHealFrame"] 		= Party4ScrollingHealFrame
	
	--Party5 UI Elements:
	UI_Components["target_PlayerName"] 		= TargetName
	UI_Components["target_CastSpellButton"] = TargetButton
	UI_Components["target_HealthBar"] 		= TargetStatusBar
	UI_Components["target_PowerBar"] 		= TargetPowerStatusBar
	UI_Components["target_ScrollingDamageFrame"] 	= TargetScrollingDamageFrame
	UI_Components["target_ScrollingHealFrame"] 		= TargetScrollingHealFrame
	
	-- END -- Add elements to the array using strings as indices



	
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################


function eventAddonLoaded()
	--## Initilize Addon here. ##
	
	--##START## Create Default Values for Settings if Addon has never ran before.
	--TODO: Only Druid, Priest currently have some spells set by default on first time use. Haven't gotten to others.
	if FreshInstall == nil then
		--**TO DO:** Will need to do detect class stuff here to set the values based on class 
		local playerClass, englishClass = UnitClass("player") --Example: Priest, PRIEST
		
		if playerClass == "priest" then
			--Create Default Spells for the buttons
			LeftClickSpell = "Lesser Heal";
			MiddleClickSpell = "Renew";
			
			--Set the text in the options textbox with the intial starter value
			TxtLeftClick:SetText("Lesser Heal")
			TxtMiddleClick:SetText("Renew")
			
		elseif playerClass == "druid" then
			--Create Default Spells for the buttons
			LeftClickSpell = "Healing Touch";
			--Set the text in the options textbox with the intial starter value
			TxtLeftClick:SetText("Healing Touch")
		
		end
	
		--Sets the default values for the checkbox states on the first time the addon has ever been ran.
	    ShowMinusValue = "true"
		ShowPercentageHealth = "false"
		ShowScrollingText = "false"
		ShowTargetUI = "false"
	
		FreshInstall = false
		
	end
	--######

	if ShowMinusValue == "" and ShowPercentageHealth == "" then 
		--This is needed incase the addon has been used before this feature was added
		ShowMinusValue = "true"
	end 
	
	--##END## Create Default Values for Settings if Addon has never ran before.
	
	--##########################################################################
	--##########################################################################
	
	--##START## Fill in Setting textboxs with appropriate data.
	
	--Fill Normal Click textboxs with the text from save file values
	--Doing: If there is text save in the variable then put the text into the textbox in the settings panel that the variable goes too
	if LeftClickSpell ~= nil then TxtLeftClick:SetText(LeftClickSpell) end
	if MiddleClickSpell ~= nil then TxtMiddleClick:SetText(MiddleClickSpell) end
	if RightClickSpell ~= nil then TxtRightClick:SetText(RightClickSpell) end
	
	--Fill Shift + Click textboxs with the text from save file values
	if ShiftLeftClickSpell ~= nil then TxtShiftLeftClick:SetText(ShiftLeftClickSpell) end
	if ShiftMiddleClickSpell ~= nil then TxtShiftMiddleClick:SetText(ShiftMiddleClickSpell) end
	if ShiftRightClickSpell ~= nil then TxtShiftRightClick:SetText(ShiftRightClickSpell) end
	
	--Fill Control(Ctrl) + Click textboxs with the text from save file values
	if ControlLeftClickSpell ~= nil then TxtCtrlLeftClick:SetText(ControlLeftClickSpell) end
	if ControlMiddleClickSpell ~= nil then TxtCtrlMiddleClick:SetText(ControlMiddleClickSpell) end
	if ControlRightClickSpell ~= nil then TxtCtrlRightClick:SetText(ControlRightClickSpell) end

	--##END## Fill in Setting textboxs with appropriate data.

	--## START ## - ScrollingText Checkboxes
	if ShowScrollingText == "true" then
		 
		CheckboxShowScrollingText:SetChecked(true)
		CheckboxShowDamage:Enable()
		CheckboxShowHeal:Enable()
		
	elseif ShowScrollingText == "false" or "" then
		 
		CheckboxShowScrollingText:SetChecked(false)
		CheckboxShowDamage:Disable()
		CheckboxShowHeal:Disable()
		CheckboxShowDamageLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
		CheckboxShowHealLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
		
	end
	
	if ShowDamage == "true" then
		CheckboxShowDamage:SetChecked(true)
	
	elseif ShowDamage == "false" or "" then
		CheckboxShowDamage:SetChecked(false)
	
	end
	
	if ShowHeal == "true" then
	
		CheckboxShowHeal:SetChecked(true)
		
	elseif ShowHeal == "false" or "" then
		
		CheckboxShowHeal:SetChecked(false)
		
	end
	--## END ## - ScrollingText Checkboxes


	--## START ## - Target Checkboxes
	if ShowTargetUI == "true" then
		 
		CheckboxShowTarget:SetChecked(true)
		CheckboxFriendly:Enable()
		CheckboxEnemy:Enable()
		
	elseif ShowTargetUI == "false" or "" then
		 
		CheckboxShowTarget:SetChecked(false)
		CheckboxFriendly:Disable()
		CheckboxEnemy:Disable()
		CheckboxFriendlyLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
		CheckboxEnemyLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
		
	end
	
	if ShowTargetFriendly == "true" then
		CheckboxFriendly:SetChecked(true)
	
	elseif ShowTargetFriendly == "false" or "" then
		CheckboxFriendly:SetChecked(false)
	
	end
	
	if ShowTargetEnemy == "true" then
	
		CheckboxEnemy:SetChecked(true)
		
	elseif ShowTargetEnemy == "false" or "" then
		
		CheckboxEnemy:SetChecked(false)
		
	end
	--## END ## - Target Checkboxes
	

	--## START ## - Set Health Text Checkboxes

	
	
	if ShowMinusValue == "true" then
		CheckboxShowHealthMinusValue:SetChecked(true)
		CheckboxShowHealthPercentageValue:SetChecked(false)
	
		CheckboxShowHealthMinusValueLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold color
		CheckboxShowHealthPercentageValueLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
	
	elseif ShowMinusValue == "false" or "" then
	
	end
	
	if ShowPercentageHealth == "true" then
		CheckboxShowHealthPercentageValue:SetChecked(true)
		CheckboxShowHealthMinusValue:SetChecked(false)
		
		CheckboxShowHealthPercentageValueLabel:SetTextColor(1, 0.82, 0)  -- Yellow/gold color
		CheckboxShowHealthMinusValueLabel:SetTextColor(0.5, 0.5, 0.5)  -- Gray color
	elseif ShowPercentageHealth == "false" or "" then
	end

	--## END ## - Set Health Text Checkboxes
	
	
	
	--##########################################################################
	--##########################################################################




end

local function eventPlayerLogout()
	
    --Save Settings:
	LeftClickSpell = tostring(TxtLeftClick:GetText())
	MiddleClickSpell = tostring(TxtMiddleClick:GetText())
	RightClickSpell = tostring(TxtRightClick:GetText())
	
	ShiftLeftClickSpell = tostring(TxtShiftLeftClick:GetText())
	ShiftMiddleClickSpell = tostring(TxtShiftMiddleClick:GetText())
	ShiftRightClickSpell = tostring(TxtShiftRightClick:GetText())
	
	ControlLeftClickSpell = tostring(TxtCtrlLeftClick:GetText())
	ControlMiddleClickSpell = tostring(TxtCtrlMiddleClick:GetText())
	ControlRightClickSpell = tostring(TxtCtrlRightClick:GetText())
	
end

function GetClassColor(unit)
  local ClassColorR,ClassColorG,ClassColorB = 0,0,0;
  local class=unit
  if class=="DRUID" then
    ClassColorR,ClassColorG,ClassColorB = 1.0,0.49,0.04;
  elseif class=="HUNTER" then
    ClassColorR,ClassColorG,ClassColorB = 0.67,0.83,0.45;
  elseif class=="MAGE" then
    ClassColorR,ClassColorG,ClassColorB = 0.41,0.8,0.94;
  elseif class=="PALADIN" then
    ClassColorR,ClassColorG,ClassColorB = 0.96,0.55,0.73;
  elseif class=="PRIEST" then
    ClassColorR,ClassColorG,ClassColorB = 1.0,1.0,1.0;
  elseif class=="ROGUE" then
    ClassColorR,ClassColorG,ClassColorB = 1.0,0.96,0.41;
  elseif class=="SHAMAN" then
    ClassColorR,ClassColorG,ClassColorB = 0.96,0.55,0.73;
  elseif class=="WARLOCK" then
    ClassColorR,ClassColorG,ClassColorB = 0.58,0.51,0.79;
  elseif class=="WARRIOR" then
    ClassColorR,ClassColorG,ClassColorB = 0.78,0.61,0.43;
  end
  return ClassColorR,ClassColorG,ClassColorB;
end


--wwww




local function ShowAnimatedTextDownward(ParentTarget, text, xOffset, yOffset, color)
	-- Function to show animated text moving downward
	-- Not currently Used for anything, decided to go with the bigtosmall animation
	
	local totalDistance = 15 -- total distance to move the text
	local duration = 1
	local speed = totalDistance / duration -- calculate speed based on total distance and duration


    frame.text:SetText(text)
    frame:SetPoint("TOP", playerName, "BOTTOM", xOffset, yOffset)
    frame:Show()

    local startTime = GetTime()

    local function OnUpdate()
        local elapsed = GetTime() - startTime
        local distance = speed * elapsed

        frame:SetPoint("TOP", ParentTarget, "BOTTOM", xOffset, yOffset - distance)
		
		if color == "red" then
			frame.text:SetTextColor(1, 0, 0)  -- Red color
		elseif color == "green" then
			frame.text:SetTextColor(0, 1, 0)  -- green color
		end
		
        if elapsed >= duration then
            frame:Hide()
            frame:SetScript("OnUpdate", nil)
        end
    end

    frame:SetScript("OnUpdate", OnUpdate)
end
-- END


-- START -- ANIMATE BIG TO SMALL

local function quadraticEaseInOut(t, b, c, d) --chatgpt black magic, supposed to make the animation smoother; i have no clue wth is going on here.
    t = t / (d / 2)
    if t < 1 then
        return c / 2 * t * t + b
    else
        t = t - 1
        return -c / 2 * (t * (t - 2) - 1) + b
    end
end

local function ShowAnimatedTextBigtoSmall(Person, ParentTarget, text, xOffset, yOffset, color)
	--Variables:
	--Person: player, party1, party2, party3, party4, target
	--ParentTarget: UI frame to attach the scrolling text frame too i.e. playerName, party1Name, ...
	--text: text to display i.e. "-100"
	--xOffset, yOffset: Where to spawn the text away from the ParentTarget
	--color: Color of the text to display i.e. "red" for damage, "green" for heals
	
	local startFontSize = 20 -- initial font size
	local endFontSize = 8 -- final font size
	local duration = .6
	local startTime

    local TargetUIFrame = nil
	
	--Determine whether it was damage or a heal based on the color that was sent to the function; route the text to the correct UI frame
	if color == "red" then --Whether they gained on lost heal, use different UI element
		TargetUIFrame = UI_Components[Person.."_ScrollingDamageFrame"]
	else
		TargetUIFrame = UI_Components[Person.."_ScrollingHealFrame"]
	end

	--Set UI frame variables for the text
    TargetUIFrame.text:SetText(text)
    TargetUIFrame:SetPoint("CENTER", ParentTarget, "CENTER", xOffset, yOffset)
    TargetUIFrame.text:SetTextColor(1, 1, 1)  -- White color
	TargetUIFrame.text:SetFont("Fonts\\ARIALN.TTF", startFontSize) -- Set the initial font size
	TargetUIFrame:Show()

    startTime = GetTime()

    local function OnUpdate()
        local elapsed = GetTime() - startTime
        local t = math.min(1, elapsed / duration) -- Ensure t is capped at 1

        local fontSize = startFontSize - quadraticEaseInOut(t, 0, startFontSize - endFontSize, 1)

        TargetUIFrame.text:SetFont("Fonts\\ARIALN.TTF", fontSize)

        if color == "red" then
            TargetUIFrame.text:SetTextColor(1, 0, 0)  -- Red color
        elseif color == "green" then
            TargetUIFrame.text:SetTextColor(0, 1, 0)  -- Green color
        end

        if elapsed >= duration then
            TargetUIFrame:Hide()
            TargetUIFrame:SetScript("OnUpdate", nil)
        end
    end

    TargetUIFrame:SetScript("OnUpdate", OnUpdate)
end
-- END -- ANIMATE BIG TO SMALL


local function ScrollingText(SpecifiedPerson)
	-- Determines if you gained or lost health and sends the amount to the animation function.
	
	local DamageAmount = 0
	local HealedAmount = 0
		
	if SpecifiedPerson == "player" or SpecifiedPerson == "party1" or SpecifiedPerson == "party2" or SpecifiedPerson == "party3" or SpecifiedPerson == "party4" or SpecifiedPerson == "target" then
			
		if PreviouseHealth[SpecifiedPerson] == -1 then
				--Gets triggered When player logs in; don't show scrolling text
		else 
				
			if PreviouseHealth[SpecifiedPerson] > UnitHealth(SpecifiedPerson) then
				--Took Damage
				if ShowDamage =="true" and ShowScrollingText=="true" then
					DamageAmount = (PreviouseHealth[SpecifiedPerson] - UnitHealth(SpecifiedPerson))
					ShowAnimatedTextBigtoSmall(SpecifiedPerson, UI_Components[SpecifiedPerson.."_CastSpellButton"], tostring(DamageAmount), -65, 0, "red")
				end	
			elseif PreviouseHealth[SpecifiedPerson] < UnitHealth(SpecifiedPerson) then
				--Healed
				if ShowHeal =="true"  and ShowScrollingText=="true" then
					HealedAmount = (UnitHealth(SpecifiedPerson) - PreviouseHealth[SpecifiedPerson])
					ShowAnimatedTextBigtoSmall(SpecifiedPerson, UI_Components[SpecifiedPerson.."_CastSpellButton"], tostring(HealedAmount), 65, 0, "green")
				end
			end
				
		end
			
		PreviouseHealth[SpecifiedPerson] = UnitHealth(SpecifiedPerson)
		
	end

end


local function UpdateHealthValues(person, TriggerScrollingText)
		--Variable: TriggerScrollingText : is needed so that the scrolling text doesn't trigger when you switch targets or players, and use the previous person data for the first tick
		--Variable: person : player, party1, party2, party3, party4, target
		
		local SpecifiedPerson = tostring(person)  --player, party1, party2, etc..
		
		local SpecifiedPersonCurrentHealth = UnitHealth(SpecifiedPerson)
        local SpecifiedPersonMaxHealth = UnitHealthMax(SpecifiedPerson)
		
		local PersonName = UnitName(tostring(person))
		local PersonClass, UpperCaseClass = UnitClass(tostring(person))
        local cr,cg,cb = GetClassColor(UpperCaseClass)
		
		--Store PlayersName for use in the target UI functions to prevent showing a target that is already in the party in a target ui frame.
		PlayerNames[SpecifiedPerson] = PersonName
		
		--Call Scrolling Text Function
		if TriggerScrollingText == true then
			ScrollingText(SpecifiedPerson)
		else
			PreviouseHealth[SpecifiedPerson] = UnitHealth(SpecifiedPerson)
		end
		
		if SpecifiedPerson == "player" or SpecifiedPerson == "party1" or SpecifiedPerson == "party2" or SpecifiedPerson == "party3" or SpecifiedPerson == "party4" or SpecifiedPerson == "target" then
			
			if UnitIsConnected(SpecifiedPerson) then				
				--Online
				
				--Set Player Name Text
				if cr then
					--playerName is the UI controls name, PlayerName is the variable containing the players name; the difference is the lower/uppercase "p"
					UI_Components[SpecifiedPerson.."_PlayerName"]:SetText(PersonName .. "  ( |cFF" .. string.format("%02x%02x%02x", cr * 255, cg * 255, cb * 255) .. PersonClass .. "|r )")
				
				else
					UI_Components[SpecifiedPerson.."_PlayerName"]:SetText(PersonName .. "  ( " .. PersonClass .. " )")
				end

				
				if SpecifiedPersonCurrentHealth <= 0 then
					--Dead
					UI_Components[SpecifiedPerson.."_CastSpellButton"]:SetText("<< DEAD >>")
					UI_Components[SpecifiedPerson.."_HealthBar"]:SetValue(0)
					UI_Components[SpecifiedPerson.."_PowerBar"]:SetValue(0)
					
				else
					--Alive
					--Set Players Health Values TEXT UI
					if ShowMinusValue == "true" then
					
						if math.floor(SpecifiedPersonMaxHealth - SpecifiedPersonCurrentHealth) == 0 then
							--If the person is at FULL health ex: 100/100
							UI_Components[SpecifiedPerson.."_CastSpellButton"]:SetText(SpecifiedPersonCurrentHealth .. "/" .. SpecifiedPersonMaxHealth)
						else
							--Not at full health ex: 90/100 (-10)
							UI_Components[SpecifiedPerson.."_CastSpellButton"]:SetText(SpecifiedPersonCurrentHealth .. "/" .. SpecifiedPersonMaxHealth .. "(-" .. math.floor(SpecifiedPersonMaxHealth - SpecifiedPersonCurrentHealth) .. ")")
						end
						
					elseif ShowPercentageHealth == "true" then
						
						if math.floor(SpecifiedPersonMaxHealth - SpecifiedPersonCurrentHealth) == 0 then
							--If the person is at FULL health ex: 100/100
							UI_Components[SpecifiedPerson.."_CastSpellButton"]:SetText(SpecifiedPersonCurrentHealth .. "/" .. SpecifiedPersonMaxHealth)
						else
							--Not at full health ex: 90/100 (90%)
							UI_Components[SpecifiedPerson.."_CastSpellButton"]:SetText(SpecifiedPersonCurrentHealth .. "/" .. SpecifiedPersonMaxHealth .. "(" .. math.floor((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth)*100) .. "%" .. ")")
						end
					end
					--This shouldn't trigger; here just in case something weird happens
					UI_Components[SpecifiedPerson.."_HealthBar"]:SetValue((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth))
				end
				
				
			else
				--Offline; this happens when someone is in your party already but goes offline
				UI_Components[SpecifiedPerson.."_PlayerName"]:SetText(PersonName.." is Offline")
				UI_Components[SpecifiedPerson.."_CastSpellButton"]:SetText("<< Offline >>")
				UI_Components[SpecifiedPerson.."_HealthBar"]:SetValue(0)
				UI_Components[SpecifiedPerson.."_PowerBar"]:SetValue(0)
			end
			
		end
		
end


-- Function to create and set a texture for a buff or debuff icon
local function CreatePlayerBuffDebuffIcon(buffindex, texturePath, StackSize, xOffset,Btype)
    -- Create a frame; must be a frame so i can create the mouseover tooltip for the buff
    local PlayerBuffIconFrame = CreateFrame("Frame", nil, PlayerBuffPanel)
    PlayerBuffIconFrame:SetWidth(15)
    PlayerBuffIconFrame:SetHeight(15)
    --if xOffset == 0 then xOffset = 2.5 end -- Pad the first icon in the list
	PlayerBuffIconFrame:SetPoint("TOPLEFT", xOffset, -1.5)
	
	
    -- Create a texture for the frame
    local icon = PlayerBuffIconFrame:CreateTexture(nil, "OVERLAY") --Call the function that created the icon UI
    icon:SetAllPoints(PlayerBuffIconFrame)
    icon:SetTexture(texturePath)
	
	--#START# TOOLTIP STUFF
	-- Set the GameTooltip to the player buff
	PlayerBuffIconFrame:EnableMouse(true)
	
	PlayerBuffIconFrame:SetScript("OnEnter", function()
        local buffbuttonid = nil
        local debuffbuttonid = nil
        local texture = icon:GetTexture()

        for i = 1, 16 do
            if UnitBuff("player", i) == texture then
                buffbuttonid = i
                break
            end
        end

        if buffbuttonid == nil then
            for i_2 = 1, 8 do
                if UnitDebuff("player", i_2) == texture then
                    debuffbuttonid = i_2
                    break
                end
            end
        end

        GameTooltip:SetOwner(PlayerBuffIconFrame, "ANCHOR_BOTTOMLEFT")
        if buffbuttonid then
            GameTooltip:SetUnitBuff("player", buffbuttonid)
        elseif debuffbuttonid then
            GameTooltip:SetUnitDebuff("player", debuffbuttonid)
        end
        GameTooltip:Show()
    end)

    PlayerBuffIconFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
	
	table.insert(PlayerBuffIconFrames, PlayerBuffIconFrame)
	--#END# TOOLTIP STUFF
	
	-- Create a FontString for the stack size
    -- Don't create text for the stacksize if there isn't a more than one stack
	if StackSize > 1 then
		local stackText = PlayerBuffIconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		stackText:SetPoint("BOTTOM", PlayerBuffIconFrame, "BOTTOM", 0, -9)  -- Adjusted position to bottom center
		stackText:SetTextColor(1, 1, 1)  -- Set text color to white
		stackText:SetText(StackSize)
		stackText:SetFont("Fonts\\FRIZQT__.TTF", 10) -- Change the font size
		table.insert(PlayerBuffStackText, stackText)
		
	end
	
	-- Add the icon to the table
    table.insert(PlayerBuffIcons, icon)
	
end

-- Function to create and set a texture for a buff or debuff icon
local function CreateParty1BuffDebuffIcon(buffindex, texturePath, StackSize, xOffset,Btype)
    -- Create a frame; must be a frame so i can create the mouseover tooltip for the buff
    local Party1BuffIconFrame = CreateFrame("Frame", nil, Party1BuffPanel)
    Party1BuffIconFrame:SetWidth(15)
    Party1BuffIconFrame:SetHeight(15)
    --if xOffset == 0 then xOffset = 2.5 end -- Pad the first icon in the list
	Party1BuffIconFrame:SetPoint("TOPLEFT", xOffset, -1.5)

    -- Create a texture for the frame
    local icon = Party1BuffIconFrame:CreateTexture(nil, "OVERLAY") --Call the function that created the icon UI
    icon:SetAllPoints(Party1BuffIconFrame)
    icon:SetTexture(texturePath)
	
	--#START# TOOLTIP STUFF
	-- Set the GameTooltip to the player buff
	Party1BuffIconFrame:EnableMouse(true)
	
		Party1BuffIconFrame:SetScript("OnEnter", function()
        local buffbuttonid = nil
        local debuffbuttonid = nil
        local texture = icon:GetTexture()

        for i = 1, 16 do
            if UnitBuff("party1", i) == texture then
                buffbuttonid = i
                break
            end
        end

        if buffbuttonid == nil then
            for i_2 = 1, 8 do
                if UnitDebuff("party1", i_2) == texture then
                    debuffbuttonid = i_2
                    break
                end
            end
        end

        GameTooltip:SetOwner(Party1BuffIconFrame, "ANCHOR_BOTTOMLEFT")
        if buffbuttonid then
            GameTooltip:SetUnitBuff("party1", buffbuttonid)
        elseif debuffbuttonid then
            GameTooltip:SetUnitDebuff("party1", debuffbuttonid)
        end
        GameTooltip:Show()
    end)
	
	-- Set a script to hide the tooltip when the mouse leaves the icon
	Party1BuffIconFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	table.insert(Party1BuffIconFrames, Party1BuffIconFrame)
	--#END# TOOLTIP STUFF
	
	
	
	-- Create a FontString for the stack size
    -- Don't create text for the stacksize if there isn't a more than one stack
	if StackSize > 1 then
		local stackText = Party1BuffIconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		stackText:SetPoint("BOTTOM", Party1BuffIconFrame, "BOTTOM", 0, -9)  -- Adjusted position to bottom center
		stackText:SetTextColor(1, 1, 1)  -- Set text color to white
		stackText:SetText(StackSize)
		stackText:SetFont("Fonts\\FRIZQT__.TTF", 10) -- Change the font size
		table.insert(Party1BuffStackText, stackText)
		
	end
	
	 -- Add the icon to the table
    table.insert(Party1BuffIcons, icon)
	 
end

-- Function to create and set a texture for a buff or debuff icon
local function CreateParty2BuffDebuffIcon(buffindex, texturePath, StackSize, xOffset,Btype)
    -- Create a frame; must be a frame so i can create the mouseover tooltip for the buff
    local Party2BuffIconFrame = CreateFrame("Frame", nil, Party2BuffPanel)
    Party2BuffIconFrame:SetWidth(15)
    Party2BuffIconFrame:SetHeight(15)
    --if xOffset == 0 then xOffset = 2.5 end -- Pad the first icon in the list
	Party2BuffIconFrame:SetPoint("TOPLEFT", xOffset, -1.5)

    -- Create a texture for the frame
    local icon = Party2BuffIconFrame:CreateTexture(nil, "OVERLAY") --Call the function that created the icon UI
    icon:SetAllPoints(Party2BuffIconFrame)
    icon:SetTexture(texturePath)
	
	--#START# TOOLTIP STUFF
	-- Set the GameTooltip to the player buff
	Party2BuffIconFrame:EnableMouse(true)
	
	Party2BuffIconFrame:SetScript("OnEnter", function()
        local buffbuttonid = nil
        local debuffbuttonid = nil
        local texture = icon:GetTexture()

        for i = 1, 16 do
            if UnitBuff("party2", i) == texture then
                buffbuttonid = i
                break
            end
        end

        if buffbuttonid == nil then
            for i_2 = 1, 8 do
                if UnitDebuff("party2", i_2) == texture then
                    debuffbuttonid = i_2
                    break
                end
            end
        end

        GameTooltip:SetOwner(Party2BuffIconFrame, "ANCHOR_BOTTOMLEFT")
        if buffbuttonid then
            GameTooltip:SetUnitBuff("party2", buffbuttonid)
        elseif debuffbuttonid then
            GameTooltip:SetUnitDebuff("party2", debuffbuttonid)
        end
        GameTooltip:Show()
    end)
	
	-- Set a script to hide the tooltip when the mouse leaves the icon
	Party2BuffIconFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	table.insert(Party2BuffIconFrames, Party2BuffIconFrame)
	--#END# TOOLTIP STUFF
	
	-- Create a FontString for the stack size
    -- Don't create text for the stacksize if there isn't a more than one stack
	if StackSize > 1 then
		local stackText = Party2BuffIconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		stackText:SetPoint("BOTTOM", Party2BuffIconFrame, "BOTTOM", 0, -9)  -- Adjusted position to bottom center
		stackText:SetTextColor(1, 1, 1)  -- Set text color to white
		stackText:SetText(StackSize)
		stackText:SetFont("Fonts\\FRIZQT__.TTF", 10) -- Change the font size
		table.insert(Party2BuffStackText, stackText)
		
	end
	
	 -- Add the icon to the table
    table.insert(Party2BuffIcons, icon)
	 
end

-- Function to create and set a texture for a buff or debuff icon
local function CreateParty3BuffDebuffIcon(buffindex, texturePath, StackSize, xOffset,Btype)
    -- Create a frame; must be a frame so i can create the mouseover tooltip for the buff
    local Party3BuffIconFrame = CreateFrame("Frame", nil, Party3BuffPanel)
    Party3BuffIconFrame:SetWidth(15)
    Party3BuffIconFrame:SetHeight(15)
    --if xOffset == 0 then xOffset = 2.5 end -- Pad the first icon in the list
	Party3BuffIconFrame:SetPoint("TOPLEFT", xOffset, -1.5)

    -- Create a texture for the frame
    local icon = Party3BuffIconFrame:CreateTexture(nil, "OVERLAY") --Call the function that created the icon UI
    icon:SetAllPoints(Party3BuffIconFrame)
    icon:SetTexture(texturePath)
	
	--#START# TOOLTIP STUFF
	-- Set the GameTooltip to the player buff
	Party3BuffIconFrame:EnableMouse(true)
	
	Party3BuffIconFrame:SetScript("OnEnter", function()
        local buffbuttonid = nil
        local debuffbuttonid = nil
        local texture = icon:GetTexture()

        for i = 1, 16 do
            if UnitBuff("party3", i) == texture then
                buffbuttonid = i
                break
            end
        end

        if buffbuttonid == nil then
            for i_2 = 1, 8 do
                if UnitDebuff("party3", i_2) == texture then
                    debuffbuttonid = i_2
                    break
                end
            end
        end

        GameTooltip:SetOwner(Party3BuffIconFrame, "ANCHOR_BOTTOMLEFT")
        if buffbuttonid then
            GameTooltip:SetUnitBuff("party3", buffbuttonid)
        elseif debuffbuttonid then
            GameTooltip:SetUnitDebuff("party3", debuffbuttonid)
        end
        GameTooltip:Show()
    end)
	
	-- Set a script to hide the tooltip when the mouse leaves the icon
	Party3BuffIconFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	table.insert(Party3BuffIconFrames, Party3BuffIconFrame)
	--#END# TOOLTIP STUFF
	
	-- Create a FontString for the stack size
    -- Don't create text for the stacksize if there isn't a more than one stack
	if StackSize > 1 then
		local stackText = Party3BuffIconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		stackText:SetPoint("BOTTOM", Party3BuffIconFrame, "BOTTOM", 0, -9)  -- Adjusted position to bottom center
		stackText:SetTextColor(1, 1, 1)  -- Set text color to white
		stackText:SetText(StackSize)
		stackText:SetFont("Fonts\\FRIZQT__.TTF", 10) -- Change the font size
		table.insert(Party3BuffStackText, stackText)
		
	end
	
	 -- Add the icon to the table
    table.insert(Party3BuffIcons, icon)
	 
end

-- Function to create and set a texture for a buff or debuff icon
local function CreateParty4BuffDebuffIcon(buffindex, texturePath, StackSize, xOffset,Btype)
    -- Create a frame; must be a frame so i can create the mouseover tooltip for the buff
    local Party4BuffIconFrame = CreateFrame("Frame", nil, Party4BuffPanel)
    Party4BuffIconFrame:SetWidth(15)
    Party4BuffIconFrame:SetHeight(15)
    --if xOffset == 0 then xOffset = 2.5 end -- Pad the first icon in the list
	Party4BuffIconFrame:SetPoint("TOPLEFT", xOffset, -1.5)

    -- Create a texture for the frame
    local icon = Party4BuffIconFrame:CreateTexture(nil, "OVERLAY") --Call the function that created the icon UI
    icon:SetAllPoints(Party4BuffIconFrame)
    icon:SetTexture(texturePath)
	
	--#START# TOOLTIP STUFF
	-- Set the GameTooltip to the player buff
	Party4BuffIconFrame:EnableMouse(true)
	
		Party4BuffIconFrame:SetScript("OnEnter", function()
        local buffbuttonid = nil
        local debuffbuttonid = nil
        local texture = icon:GetTexture()

        for i = 1, 16 do
            if UnitBuff("party4", i) == texture then
                buffbuttonid = i
                break
            end
        end

        if buffbuttonid == nil then
            for i_2 = 1, 8 do
                if UnitDebuff("party4", i_2) == texture then
                    debuffbuttonid = i_2
                    break
                end
            end
        end

        GameTooltip:SetOwner(Party4BuffIconFrame, "ANCHOR_BOTTOMLEFT")
        if buffbuttonid then
            GameTooltip:SetUnitBuff("party4", buffbuttonid)
        elseif debuffbuttonid then
            GameTooltip:SetUnitDebuff("party4", debuffbuttonid)
        end
        GameTooltip:Show()
    end)
	

	
	-- Set a script to hide the tooltip when the mouse leaves the icon
	Party4BuffIconFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	table.insert(Party4BuffIconFrames, Party4BuffIconFrame)
	--#END# TOOLTIP STUFF
	
	-- Create a FontString for the stack size
    -- Don't create text for the stacksize if there isn't a more than one stack
	if StackSize > 1 then
		local stackText = Party4BuffIconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		stackText:SetPoint("BOTTOM", Party4BuffIconFrame, "BOTTOM", 0, -9)  -- Adjusted position to bottom center
		stackText:SetTextColor(1, 1, 1)  -- Set text color to white
		stackText:SetText(StackSize)
		stackText:SetFont("Fonts\\FRIZQT__.TTF", 10) -- Change the font size
		table.insert(Party4BuffStackText, stackText)
		
	end
	
	 -- Add the icon to the table
    table.insert(Party4BuffIcons, icon)
	 
end


local function GetDruidForm(person)
--person == player, party1, party2, party3, party4, target

--Druid Forms:
--       "Interface\\Icons\\Ability_Druid_CatForm" = "energy",	-- Cat
--       "Interface\\Icons\\Ability_Racial_BearForm" = "rage",	-- Bear
--       "Interface\\Icons\\Spell_Nature_ForceOfNature" = "mana",  -- Moonkin
--       "Interface\\Icons\\Ability_Druid_TravelForm" = "mana",    -- Travel
--       "Interface\\Icons\\Ability_Druid_AquaticForm" = "mana",   -- Aquatic
--       "Interface\\Icons\\Spell_Nature_HealingTouch" = "mana"    -- Tree of Life
	local FoundForm = false
	
	for i = 1, 16 do
		if UnitBuff(person, i) ~= nil then
	
			--Debug("Buff:"..UnitBuff(person, i))
			if UnitBuff(person, i) == "Interface\\Icons\\Ability_Druid_CatForm" then
				FoundForm = true
				return "energy"
				--break
			elseif UnitBuff(person, i) == "Interface\\Icons\\Ability_Racial_BearForm" then	
				FoundForm = true
				return "rage"
				--break
			elseif UnitBuff(person, i) == "Interface\\Icons\\Spell_Nature_ForceOfNature" or UnitBuff(person, i) == "Interface\\Icons\\Ability_Druid_TravelForm" or UnitBuff(person, i) == "Interface\\Icons\\Ability_Druid_AquaticForm" or UnitBuff(person, i) == "Interface\\Icons\\Spell_Nature_HealingTouch" then	
				--All other forms use MANA
				FoundForm = true
				return "mana"
				
			end
	
		end
	end
	
	if FoundForm == false then
		return "mana"
	end
	
end


local function CreateTargetBuffDebuffIcon(buffindex, texturePath, StackSize, xOffset,Btype)
    -- Create a frame; must be a frame so i can create the mouseover tooltip for the buff
    local TargetBuffIconFrame = CreateFrame("Frame", nil, TargetBuffPanel)
    TargetBuffIconFrame:SetWidth(15)
    TargetBuffIconFrame:SetHeight(15)
    --if xOffset == 0 then xOffset = 2.5 end -- Pad the first icon in the list
	TargetBuffIconFrame:SetPoint("TOPLEFT", xOffset, -1.5)

    -- Create a texture for the frame
    local icon = TargetBuffIconFrame:CreateTexture(nil, "OVERLAY") --Call the function that created the icon UI
    icon:SetAllPoints(TargetBuffIconFrame)
    icon:SetTexture(texturePath)
	
	--#START# TOOLTIP STUFF
	-- Set the GameTooltip to the player buff
	TargetBuffIconFrame:EnableMouse(true)
	
		TargetBuffIconFrame:SetScript("OnEnter", function()
        local buffbuttonid = nil
        local debuffbuttonid = nil
        local texture = icon:GetTexture()

        for i = 1, 16 do
            if UnitBuff("target", i) == texture then
                buffbuttonid = i
                break
            end
        end

        if buffbuttonid == nil then
            for i_2 = 1, 8 do
                if UnitDebuff("target", i_2) == texture then
                    debuffbuttonid = i_2
                    break
                end
            end
        end

        GameTooltip:SetOwner(TargetBuffIconFrame, "ANCHOR_BOTTOMLEFT")
        if buffbuttonid then
            GameTooltip:SetUnitBuff("target", buffbuttonid)
        elseif debuffbuttonid then
            GameTooltip:SetUnitDebuff("target", debuffbuttonid)
        end
        GameTooltip:Show()
    end)
	

	
	-- Set a script to hide the tooltip when the mouse leaves the icon
	TargetBuffIconFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	table.insert(TargetBuffIconFrames, TargetBuffIconFrame)
	--#END# TOOLTIP STUFF
	
	-- Create a FontString for the stack size
    -- Don't create text for the stacksize if there isn't a more than one stack
	if StackSize > 1 then
		local stackText = TargetBuffIconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		stackText:SetPoint("BOTTOM", TargetBuffIconFrame, "BOTTOM", 0, -9)  -- Adjusted position to bottom center
		stackText:SetTextColor(1, 1, 1)  -- Set text color to white
		stackText:SetText(StackSize)
		stackText:SetFont("Fonts\\FRIZQT__.TTF", 10) -- Change the font size
		table.insert(TargetBuffStackText, stackText)
		
	end
	
	 -- Add the icon to the table
    table.insert(TargetBuffIcons, icon)
	 
end


local function UpdatePlayerBuffDebuffIcons()
    -- Destroy and recreate the BuffDebuffIconFrame
	
	-- Hide("delete") all PlayerBuffIconFrame the currently exist
	for _, PlayerBuffIconFrame in ipairs(PlayerBuffIconFrames) do
		PlayerBuffIconFrame:SetScript("OnEnter", nil) -- Remove OnEnter script
		PlayerBuffIconFrame:SetScript("OnLeave", nil) -- Remove OnLeave script
		PlayerBuffIconFrame:Hide()
		PlayerBuffIconFrame:ClearAllPoints()
		PlayerBuffIconFrame = nil
	end
	
	-- Hide("delete") all icons the currently exist
	for _, icon in ipairs(PlayerBuffIcons) do
		
		icon:Hide()
		icon:ClearAllPoints()
		icon = nil
		
	end
	
		-- Hide("delete") all icons the currently exist
	for _, stackText in ipairs(PlayerBuffStackText) do
		stackText:Hide()
		stackText:SetText("")
		stackText:ClearAllPoints()
		stackText = nil
	end
	
    local xOffset = 0 --Reset this variable so that the new icons start at the left side of the bufficon frame

    -- Track player buffs
    for i = 1, 40 do
        local IconTexturePath, StackSize = UnitBuff("player", i)
		local BuffIndex = i
		--If it returns a value for texture path than their is a buff there
		if not IconTexturePath then break end
	
			CreatePlayerBuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Buff")
			xOffset = xOffset + 20
			
	end

    -- Track player debuffs
	
    i = 1
    while true do
        local IconTexturePath, StackSize = UnitDebuff("player", i)
        local BuffIndex = i
		if not IconTexturePath then break end
        CreatePlayerBuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Debuff")
        xOffset = xOffset + 20
		i = i + 1
    end
	
	
	
	end
	

local function UpdateParty1BuffDebuffIcons()
    -- Destroy and recreate the BuffDebuffIconFrame

	-- Hide("delete") all Party1BuffIconFrame the currently exist
	for _, Party1BuffIconFrame in ipairs(Party1BuffIconFrames) do
		Party1BuffIconFrame:SetScript("OnEnter", nil) -- Remove OnEnter script
		Party1BuffIconFrame:SetScript("OnLeave", nil) -- Remove OnLeave script
		Party1BuffIconFrame:Hide()
		Party1BuffIconFrame:ClearAllPoints()
		Party1BuffIconFrame = nil
	end
	
	-- Hide("delete") all icons the currently exist
	for _, icon in ipairs(Party1BuffIcons) do
		icon:Hide()
		icon:ClearAllPoints()
		icon = nil
	end
	
		-- Hide("delete") all icons the currently exist
	for _, stackText in ipairs(Party1BuffStackText) do
		stackText:Hide()
		stackText:SetText("")
		stackText:ClearAllPoints()
		stackText = nil
	end
	
    local xOffset = 0 --Reset this variable so that the new icons start at the left side of the bufficon frame

    -- Track player buffs
    for i = 1, 40 do
        local IconTexturePath, StackSize = UnitBuff("party1", i)
		local BuffIndex = i
		--If it returns a value for texture path than their is a buff there
		if not IconTexturePath then break end
	
			CreateParty1BuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Buff")
			xOffset = xOffset + 20
			
	end

    -- Track player debuffs
	
    i = 1
    while true do
        local IconTexturePath, StackSize = UnitDebuff("party1", i)
        local BuffIndex = i
		
		if not IconTexturePath then break end
        CreateParty1BuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Debuff")
        xOffset = xOffset + 20
		i = i + 1
    end
	
end

local function UpdateParty2BuffDebuffIcons()
    -- Destroy and recreate the BuffDebuffIconFrame
	
	-- Hide("delete") all Party1BuffIconFrame the currently exist
	for _, Party2BuffIconFrame in ipairs(Party2BuffIconFrames) do
		Party2BuffIconFrame:SetScript("OnEnter", nil) -- Remove OnEnter script
		Party2BuffIconFrame:SetScript("OnLeave", nil) -- Remove OnLeave script
		Party2BuffIconFrame:Hide()
		Party2BuffIconFrame:ClearAllPoints()
		Party2BuffIconFrame = nil
	end
	
	-- Hide("delete") all icons the currently exist
	for _, icon in ipairs(Party2BuffIcons) do
		icon:Hide()
		icon:ClearAllPoints()
		icon = nil
	end
	
		-- Hide("delete") all icons the currently exist
	for _, stackText in ipairs(Party2BuffStackText) do
		stackText:Hide()
		stackText:SetText("")
		stackText:ClearAllPoints()
		stackText = nil
	end
	
    local xOffset = 0 --Reset this variable so that the new icons start at the left side of the bufficon frame

    -- Track player buffs
    for i = 1, 40 do
        local IconTexturePath, StackSize = UnitBuff("party2", i)
local BuffIndex = i
		
		--If it returns a value for texture path than their is a buff there
		if not IconTexturePath then break end
	
			CreateParty2BuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Buff")
			xOffset = xOffset + 20
			
	end

    -- Track player debuffs
	
    i = 1
    while true do
        local IconTexturePath, StackSize = UnitDebuff("party2", i)
      local BuffIndex = i
		  
		if not IconTexturePath then break end
        CreateParty2BuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Debuff")
        xOffset = xOffset + 20
		i = i + 1
    end
	
end

local function UpdateParty3BuffDebuffIcons()
    -- Destroy and recreate the BuffDebuffIconFrame

	-- Hide("delete") all Party1BuffIconFrame the currently exist
	for _, Party3BuffIconFrame in ipairs(Party3BuffIconFrames) do
		Party3BuffIconFrame:SetScript("OnEnter", nil) -- Remove OnEnter script
		Party3BuffIconFrame:SetScript("OnLeave", nil) -- Remove OnLeave script
		Party3BuffIconFrame:Hide()
		Party3BuffIconFrame:ClearAllPoints()
		Party3BuffIconFrame = nil
	end
	
	-- Hide("delete") all icons the currently exist
	for _, icon in ipairs(Party3BuffIcons) do
		icon:Hide()
		icon:ClearAllPoints()
		icon = nil
	end
	
		-- Hide("delete") all icons the currently exist
	for _, stackText in ipairs(Party3BuffStackText) do
		stackText:Hide()
		stackText:SetText("")
		stackText:ClearAllPoints()
		stackText = nil
	end
	
    local xOffset = 0 --Reset this variable so that the new icons start at the left side of the bufficon frame

    -- Track player buffs
    for i = 1, 40 do
        local IconTexturePath, StackSize = UnitBuff("party3", i)
local BuffIndex = i
		
		--If it returns a value for texture path than their is a buff there
		if not IconTexturePath then break end
	
			CreateParty3BuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Buff")
			xOffset = xOffset + 20
			
	end

    -- Track player debuffs
	
    i = 1
    while true do
        local IconTexturePath, StackSize = UnitDebuff("party3", i)
        local BuffIndex = i
		
		if not IconTexturePath then break end
        CreateParty3BuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Debuff")
        xOffset = xOffset + 20
		i = i + 1
    end
	
end

local function UpdateParty4BuffDebuffIcons()
    -- Destroy and recreate the BuffDebuffIconFrame

	-- Hide("delete") all Party1BuffIconFrame the currently exist
	for _, Party4BuffIconFrame in ipairs(Party4BuffIconFrames) do
		Party4BuffIconFrame:SetScript("OnEnter", nil) -- Remove OnEnter script
		Party4BuffIconFrame:SetScript("OnLeave", nil) -- Remove OnLeave script
		Party4BuffIconFrame:Hide()
		Party4BuffIconFrame:ClearAllPoints()
		Party4BuffIconFrame = nil
	end
	
	-- Hide("delete") all icons the currently exist
	for _, icon in ipairs(Party4BuffIcons) do
		icon:Hide()
		icon:ClearAllPoints()
		icon = nil
	end
	
		-- Hide("delete") all icons the currently exist
	for _, stackText in ipairs(Party4BuffStackText) do
		stackText:Hide()
		stackText:SetText("")
		stackText:ClearAllPoints()
		stackText = nil
	end
	
    local xOffset = 0 --Reset this variable so that the new icons start at the left side of the bufficon frame

    -- Track player buffs
    for i = 1, 40 do
        local IconTexturePath, StackSize = UnitBuff("party4", i)
local BuffIndex = i
		
		--If it returns a value for texture path than their is a buff there
		if not IconTexturePath then break end
	
			CreateParty4BuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Buff")
			xOffset = xOffset + 20
			
	end

    -- Track player debuffs
	
    i = 1
    while true do
        local IconTexturePath, StackSize = UnitDebuff("party4", i)
       local BuffIndex = i
		 
		if not IconTexturePath then break end
        CreateParty4BuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Debuff")
        xOffset = xOffset + 20
		i = i + 1
    end
	
end

local function UpdateTargetBuffDebuffIcons()
    -- Destroy and recreate the BuffDebuffIconFrame

	-- Hide("delete") all Party1BuffIconFrame the currently exist
	for _, TargetBuffIconFrame in ipairs(TargetBuffIconFrames) do
		TargetBuffIconFrame:SetScript("OnEnter", nil) -- Remove OnEnter script
		TargetBuffIconFrame:SetScript("OnLeave", nil) -- Remove OnLeave script
		TargetBuffIconFrame:Hide()
		TargetBuffIconFrame:ClearAllPoints()
		TargetBuffIconFrame = nil
	end
	
	-- Hide("delete") all icons the currently exist
	for _, icon in ipairs(TargetBuffIcons) do
		icon:Hide()
		icon:ClearAllPoints()
		icon = nil
	end
	
		-- Hide("delete") all icons the currently exist
	for _, stackText in ipairs(TargetBuffStackText) do
		stackText:Hide()
		stackText:SetText("")
		stackText:ClearAllPoints()
		stackText = nil
	end
	
    local xOffset = 0 --Reset this variable so that the new icons start at the left side of the bufficon frame

    -- Track player buffs
    for i = 1, 40 do
        local IconTexturePath, StackSize = UnitBuff("target", i)
		local BuffIndex = i
		
		--If it returns a value for texture path than their is a buff there
		if not IconTexturePath then break end
	
			CreateTargetBuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Buff")
			xOffset = xOffset + 20
			
	end

    -- Track player debuffs
	
    i = 1
    while true do
        local IconTexturePath, StackSize = UnitDebuff("target", i)
       local BuffIndex = i
		 
		if not IconTexturePath then break end
        CreateTargetBuffDebuffIcon(BuffIndex, IconTexturePath, StackSize, xOffset, "Debuff")
        xOffset = xOffset + 20
		i = i + 1
    end
	
end

-- Set the script to be run when the "player" "Statusbar" is clicked
PlayerButton:SetScript("OnClick", function()
    -- Triggers when someone clicks on the "player" heal area/button.
	local ClickType = arg1
	ClickHandler(ClickType,"player")

end) --End of onclick event

-- Set the script to be run when the "party1" "Statusbar" is clicked
Party1Button:SetScript("OnClick", function()
    -- Triggers when someone clicks on the "party1" heal area/button.
	local ClickType = arg1
	ClickHandler(ClickType,"party1")

end) --End of onclick event

-- Set the script to be run when the "party1" "Statusbar" is clicked
Party2Button:SetScript("OnClick", function()
    -- Triggers when someone clicks on the "party1" heal area/button.
	local ClickType = arg1
	ClickHandler(ClickType,"party2")

end) --End of onclick event

-- Set the script to be run when the "party1" "Statusbar" is clicked
Party3Button:SetScript("OnClick", function()
    -- Triggers when someone clicks on the "party1" heal area/button.
	local ClickType = arg1
	ClickHandler(ClickType,"party3")

end) --End of onclick event

-- Set the script to be run when the "party1" "Statusbar" is clicked
Party4Button:SetScript("OnClick", function()
    -- Triggers when someone clicks on the "party1" heal area/button.
	local ClickType = arg1
	ClickHandler(ClickType,"party4")

end) --End of onclick event

-- Set the script to be run when the "target" "Statusbar" is clicked
TargetButton:SetScript("OnClick", function()
    -- Triggers when someone clicks on the "target" heal area/button.
	local ClickType = arg1
	ClickHandler(ClickType, "target")

end) --End of onclick event
--##########################
--##########################

function ClickHandler(arg1, arg2)
	local ClickType = arg1 -- LeftButton
	local ClickedPerson = tostring(arg2) -- player, party1, party2, etc..
	
	local CurrentTarget = UnitName("target")
	local CurrentTargetEnemy = false
	local SpecialSituation = false
	
	if (UnitCanAttack(ClickedPerson,"target")) then
		CurrentTargetEnemy = true
	end
	
	

	-- Determine the kind of click that took place on the PLAYER button and do what needs done
	
    if ClickType == "LeftButton" then
     	--## Left Click ##
		
		if IsShiftKeyDown() then
			local Spell = tostring(TxtShiftLeftClick:GetText())
			
			if Spell == "target" then
				TargetUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "assist" then
				AssistUnit(ClickedPerson)
				SpecialSituation = true
				
			elseif Spell == "follow" then
				FollowUnit(ClickedPerson)
				SpecialSituation = true
				
			else
				-- Check if target is not already targeted
				if not UnitIsUnit("target", ClickedPerson) then --returns 1 if true
					-- Set target as target
					TargetUnit(ClickedPerson)
				end
				
				-- Cast the spell on yourself
				CastSpellByName(Spell)
			
			end
			
			
		elseif IsControlKeyDown() then
			local Spell = tostring(TxtCtrlLeftClick:GetText())
			
			if Spell == "target" then
				TargetUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "assist" then
				AssistUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "follow" then
				FollowUnit(ClickedPerson)
				SpecialSituation = true
			
			else
				-- Check if target is not already targeted
				if not UnitIsUnit("target", ClickedPerson) then --returns 1 if true
					-- Set target as target
					TargetUnit(ClickedPerson)
				end
				
				-- Cast the spell on yourself
				CastSpellByName(Spell)
			
			end
		
		else
          --Normal Left Click
		  local Spell = tostring(TxtLeftClick:GetText())
			
			if Spell == "target" then
				TargetUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "assist" then
				AssistUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "follow" then
				FollowUnit(ClickedPerson)
				SpecialSituation = true
			
			else
				-- Check if target is not already targeted
				if not UnitIsUnit("target", ClickedPerson) then --returns 1 if true
					-- Set target as target
					TargetUnit(ClickedPerson)
				end
				
				-- Cast the spell on yourself
				CastSpellByName(Spell)
			
			end
			
		end
		
    elseif ClickType == "MiddleButton" then
		--## Middle Click ##
        
		if IsShiftKeyDown() then
			local Spell = tostring(TxtShiftMiddleClick:GetText())
			
			if Spell == "target" then
				TargetUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "assist" then
				AssistUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "follow" then
				FollowUnit(ClickedPerson)
				SpecialSituation = true
			
			else
				-- Check if target is not already targeted
				if not UnitIsUnit("target", ClickedPerson) then --returns 1 if true
					-- Set target as target
					TargetUnit(ClickedPerson)
				end
				
				-- Cast the spell on yourself
				CastSpellByName(Spell)
			
			end
			
		elseif IsControlKeyDown() then
			local Spell = tostring(TxtCtrlMiddleClick:GetText())
			
			if Spell == "target" then
				TargetUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "assist" then
				AssistUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "follow" then
				FollowUnit(ClickedPerson)
				SpecialSituation = true
			
			else
				-- Check if target is not already targeted
				if not UnitIsUnit("target", ClickedPerson) then --returns 1 if true
					-- Set target as target
					TargetUnit(ClickedPerson)
				end
				
				-- Cast the spell on yourself
				CastSpellByName(Spell)
			
			end
		else
			--Normal MIDDLE Click
			local Spell = tostring(TxtMiddleClick:GetText())
			
			if Spell == "target" then
				TargetUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "assist" then
				AssistUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "follow" then
				FollowUnit(ClickedPerson)
				SpecialSituation = true
			
			else
				-- Check if target is not already targeted
				if not UnitIsUnit("target", ClickedPerson) then --returns 1 if true
					-- Set target as target
					TargetUnit(ClickedPerson)
				end
				
				-- Cast the spell on yourself
				CastSpellByName(Spell)
			
			end

		end
		
		
    elseif ClickType == "RightButton" then
        if IsShiftKeyDown() then
            local Spell = tostring(TxtShiftRightClick:GetText())
			
			if Spell == "target" then
				TargetUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "assist" then
				AssistUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "follow" then
				FollowUnit(ClickedPerson)
				SpecialSituation = true
			
			else
				-- Check if target is not already targeted
				if not UnitIsUnit("target", ClickedPerson) then --returns 1 if true
					-- Set target as target
					TargetUnit(ClickedPerson)
				end
				
				-- Cast the spell on yourself
				CastSpellByName(Spell)
			
			end
			
         elseif IsControlKeyDown() then
			local Spell = tostring(TxtCtrlRightClick:GetText())
			
			if Spell == "target" then
				TargetUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "assist" then
				AssistUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "follow" then
				FollowUnit(ClickedPerson)
				SpecialSituation = true
			
			else
				-- Check if target is not already targeted
				if not UnitIsUnit("target", ClickedPerson) then --returns 1 if true
					-- Set target as target
					TargetUnit(ClickedPerson)
				end
				
				-- Cast the spell on yourself
				CastSpellByName(Spell)
			
			end
			
		else
            --Normal RIGHT Click
			local Spell = tostring(TxtRightClick:GetText())
			
			if Spell == "target" then
				TargetUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "assist" then
				AssistUnit(ClickedPerson)
				SpecialSituation = true
			
			elseif Spell == "follow" then
				FollowUnit(ClickedPerson)
				SpecialSituation = true
			
			else
				-- Check if target is not already targeted
				if not UnitIsUnit("target", ClickedPerson) then --returns 1 if true
					-- Set target as target
					TargetUnit(ClickedPerson)
				end
				
				-- Cast the spell on yourself
				CastSpellByName(Spell)
			
			end
        end
    end
	
		--Put Target of player back to whatever it was before casting spell
	    if CurrentTarget == nil and SpecialSituation == false then
			--Player wasn't targeting anything before casting spell
			ClearTarget();
		
		else
			--Set Target back to whatever it was before casting the spell
			if CurrentTargetEnemy == true and SpecialSituation == false then
				TargetLastEnemy(); -- to make sure if there was more than one mob with that name near you the same one get retargeted
			elseif SpecialSituation == true then
				--do nothing, already taken care of
			else
				TargetByName(CurrentTarget)
			end
			
		end

end

--##########################
--##########################
local function UpdatePowerValues(person)
    local CurrentPower = UnitMana(person)
    local PowerMax = UnitManaMax(person)
	local Class, UClass = UnitClass(person) --Use to determine color of mana/energy/rage UI bar
	
	local PowerColor = {}

    if UClass == "WARRIOR" then
		PowerColor = {r = 698, g = 0, b = 0} -- Rage
    elseif UClass == "PALADIN" then
		PowerColor = {r = 0, g = 0, b = 0.882} -- Mana
    elseif UClass == "HUNTER" then
		PowerColor = {r = 0, g = 0, b = 0.882} -- Mana
    elseif UClass == "ROGUE" then
		PowerColor = {r = 882, g = 871, b = 0} -- Energy
    elseif UClass == "PRIEST" then
		PowerColor = {r = 0, g = 0, b = 0.882} -- Mana
    elseif UClass == "SHAMAN" then
		PowerColor = {r = 0, g = 0, b = 0.882} -- Mana
    elseif UClass == "MAGE" then
		PowerColor = {r = 0, g = 0, b = 0.882} -- Mana
    elseif UClass == "WARLOCK" then
		PowerColor = {r = 0, g = 0, b = 0.882} -- Mana
    elseif UClass == "DRUID" then
		local ManaType = GetDruidForm(person)
		
		if ManaType == "mana" then
			PowerColor = {r = 0, g = 0, b = 0.882} -- Mana
		elseif ManaType == "rage" then
			PowerColor = {r = 698, g = 0, b = 0} -- Rage
		elseif ManaType == "energy" then
			PowerColor = {r = 882, g = 871, b = 0} -- Energy
		end
	end

	if person == "player" or person=="party1" or person=="party2" or person=="party3" or person=="party4" or person=="target" then

		--Set How full the bar appears
		UI_Components[person.."_PowerBar"]:SetValue((CurrentPower / PowerMax))
		--Set Color of bar
		UI_Components[person.."_PowerBar"]:SetStatusBarColor(PowerColor.r, PowerColor.g, PowerColor.b)
		
    end
	
end

function Check4Group()
		
		local NumPartyMembers = GetNumPartyMembers()
		
		
		if NumPartyMembers == 0 then
			--No Party; Update Players Names, Health
			UpdateHealthValues("player", false)
			UpdatePlayerBuffDebuffIcons()
			UpdatePowerValues("player")
			
			--Show/Hide Party Frames that are needed
			Party1Container:Hide() --Make the Party1 persons UI invisible
			Party2Container:Hide() --Make the Party1 persons UI invisible
			Party3Container:Hide() --Make the Party1 persons UI invisible
			Party4Container:Hide() --Make the Party1 persons UI invisible
			
		elseif NumPartyMembers == 1 then
			--Party with two people including the player
			
			--Update Party Members Names, Health
			UpdateHealthValues("player", false)
			UpdatePowerValues("player")
			
			UpdateHealthValues("party1", false)
			UpdatePowerValues("party1")
			
			--Update Party Members Buffs
			UpdatePlayerBuffDebuffIcons()
			UpdateParty1BuffDebuffIcons()
			
			--Show/Hide Party Members Frames that are needed
			Party1Container:Show() --Make the Party1 persons UI invisible
			Party2Container:Hide() --Make the Party1 persons UI invisible
			Party3Container:Hide() --Make the Party1 persons UI invisible
			Party4Container:Hide() --Make the Party1 persons UI invisible
			
		elseif NumPartyMembers == 2 then
			--Party with two people including the player
			
			--Update Party Members Names, Health
			UpdateHealthValues("player", false)
			UpdatePowerValues("player")
			
			UpdateHealthValues("party1", false)
			UpdatePowerValues("party1")
			
			UpdateHealthValues("party2", false)
			UpdatePowerValues("party2")
			
			--Update Party Members Buffs
			UpdatePlayerBuffDebuffIcons()
			UpdateParty1BuffDebuffIcons()
			UpdateParty2BuffDebuffIcons()
			
			--Show/Hide Party Members Frames that are needed
			Party1Container:Show() --Make the Party1 persons UI invisible
			Party2Container:Show() --Make the Party1 persons UI invisible
			Party3Container:Hide() --Make the Party1 persons UI invisible
			Party4Container:Hide() --Make the Party1 persons UI invisible
			
		elseif NumPartyMembers == 3 then
			--Party with two people including the player
			
			--Update Party Members Names, Health
			UpdateHealthValues("player", false)
			UpdatePowerValues("player")
			
			UpdateHealthValues("party1", false)
			UpdatePowerValues("party1")
			
			UpdateHealthValues("party2", false)
			UpdatePowerValues("party2")
			
			UpdateHealthValues("party3", false)
			UpdatePowerValues("party3")
			
			--Update Party Members Buffs
			UpdatePlayerBuffDebuffIcons()
			UpdateParty1BuffDebuffIcons()
			UpdateParty3BuffDebuffIcons()
			
			--Show/Hide Party Members Frames that are needed
			Party1Container:Show() --Make the Party1 persons UI invisible
			Party2Container:Show() --Make the Party1 persons UI invisible
			Party3Container:Show() --Make the Party1 persons UI invisible	
			Party4Container:Hide() --Make the Party1 persons UI invisible
		
		elseif NumPartyMembers == 4 then
			--Party with two people including the player
			
			--Update Party Members Names, Health
			UpdateHealthValues("player", false)
			UpdatePowerValues("player")
			
			UpdateHealthValues("party1", false)
			UpdatePowerValues("party1")
			
			UpdateHealthValues("party2", false)
			UpdatePowerValues("party2")
			
			UpdateHealthValues("party3", false)
			UpdatePowerValues("party3")
			
			UpdateHealthValues("party4", false)
			UpdatePowerValues("party4")
			
			--Update Party Members Buffs
			UpdatePlayerBuffDebuffIcons()
			UpdateParty1BuffDebuffIcons()
			UpdateParty3BuffDebuffIcons()
			UpdateParty4BuffDebuffIcons()
			
			--Show/Hide Party Members Frames that are needed
			Party1Container:Show() --Make the Party1 persons UI invisible
			Party2Container:Show() --Make the Party1 persons UI invisible
			Party3Container:Show() --Make the Party1 persons UI invisible	
			Party4Container:Show() --Make the Party1 persons UI invisible
				
		end
		
end





local function eventHandler()
    
	if event == "ADDON_LOADED" then
		
		eventAddonLoaded()
		PlayerContainer:UnregisterEvent("ADDON_LOADED") -- Keeps this from trigger more than once.
	
	elseif event == "PLAYER_ENTERING_WORLD"   then
		
		Check4Group()
		
	elseif event == "PLAYER_LOGOUT" or event == "PLAYER_QUITING" then
		eventPlayerLogout()
		
	elseif event == "UNIT_HEALTH" then
		--arg1 == player, party1,party2,target etc..
		--Used to update Health values as people take damage or heal
		--Debug("Unit_Health : " .. arg1)
		UpdateHealthValues(arg1, true)
	elseif event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" then
		--Only Handles Mana 
		--arg1 == player, party1,party2,target etc..
		local Person = arg1
		UpdatePowerValues(Person)
		
	elseif event =="UNIT_AURA" then
		
		local WhoTriggered = arg1 --arg1 == player, party1,party2, etc..
		
		if WhoTriggered == "player" then
		    UpdateHealthValues("player", false) --Do this incase the player gets a health buff like Power Word: Fortitude that raises MAX Health
			UpdatePlayerBuffDebuffIcons()

		elseif WhoTriggered == "party1" then
			UpdateHealthValues("party1", false)
			
			UpdateParty1BuffDebuffIcons()
		
		elseif WhoTriggered == "party2" then
			UpdateHealthValues("party2", false)
			
			UpdateParty2BuffDebuffIcons()
		
		elseif WhoTriggered == "party3" then
			UpdateHealthValues("party3", false)
			
			UpdateParty3BuffDebuffIcons()
		
		elseif WhoTriggered == "party4" then
			UpdateHealthValues("party4", false)
			
			UpdateParty4BuffDebuffIcons()
			
		elseif WhoTriggered == "target" then
			UpdateHealthValues("target", false)
			
			UpdateTargetBuffDebuffIcons()
			
		end
		
		
	elseif event =="PARTY_MEMBERS_CHANGED" then
	    
		Check4Group()
	
	elseif event == "PLAYER_TARGET_CHANGED" then
		
		if ShowTargetUI == "true" then
		
			local target = UnitName("target")
			
			
				if UnitExists("target") then
					--Debug("You have selected a new target: " .. target)
					
					if (UnitIsFriend("player", "target") and ShowTargetFriendly == "true") or (not UnitIsFriend("player", "target") and ShowTargetEnemy == "true") then
					
					
						if PlayerNames["player"] == target or PlayerNames["party1"] == target or PlayerNames["party2"] == target  or PlayerNames["party3"] == target or PlayerNames["party4"] == target then
						--Do nothing because the target is a player that is already in the party.
						TargetContainer:Hide() 
						else
						--Create UI
						TargetContainer:Show() --Make the Party1 persons UI invisible
						UpdateHealthValues("target", false)
						UpdatePowerValues("target")
						UpdateTargetBuffDebuffIcons()
						
						CurrentTargetName = target
						end
					
					else
					TargetContainer:Hide() 
						--Target is an enemy
						--Debug("Target is an enemy")
					end
					
				else
					TargetContainer:Hide() 
				end
		else
			TargetContainer:Hide() 
		end
	
	end

end

	
-- Needs to appear after the eventHandler function in the code
EventHandlerFrame:SetScript("OnEvent", eventHandler)
-- Set the callback for the checkbox click event
CheckboxShowTarget:SetScript("OnClick", CheckboxShowTargetOnClick)
CheckboxFriendly:SetScript("OnClick", CheckboxShowFriendlyOnClick)
CheckboxEnemy:SetScript("OnClick", CheckboxShowEnemyOnClick)

CheckboxShowHealthMinusValue:SetScript("OnClick", CheckboxShowHealthMinusValueOnClick)
CheckboxShowHealthPercentageValue:SetScript("OnClick", CheckboxShowHealthPercentageValueOnClick)

-- Show the button and status bar
PlayerButton:Show()
PlayerStatusBar:Show()
PlayerBuffPanel:Show()
HM_SettingsContainer:Hide()
TargetContainer:Hide()
