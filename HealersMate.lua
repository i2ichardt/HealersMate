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


--3)##Saved Variables:##
--Note: Saves variables are specified in the .toc file

--FreshInstall --Tracks if the addon has been started before

--LeftClickSpell
--MiddleClickSpell
--RightClickSpell

--ShiftLeftClickSpell
--ShiftMiddleClickSpell
--ShiftRightClickSpell

--ControlLeftClickSpell
--ControlMiddleClickSpell
--ControlRightClickSpell

local PlayerBuffIconFrames = {}
local PlayerBuffIcons = {} --Used too deleted the current ones too make new ones
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

--#####################


--This is Just to respond to events "EventHandlerFrame" never appears on the screen
local EventHandlerFrame = CreateFrame("Frame", "EventHandlerFrame", UIParent)
EventHandlerFrame:RegisterEvent("ADDON_LOADED"); -- This triggers once for every addon that was loaded after this addon
EventHandlerFrame:RegisterEvent("PLAYER_LOGOUT"); -- Fired when about to log out
EventHandlerFrame:RegisterEvent("PLAYER_QUITING"); -- Fired when a player has the quit option on screen
EventHandlerFrame:RegisterEvent("UNIT_HEALTH") --“UNIT_HEALTH” fires when a unit’s health changes
EventHandlerFrame:RegisterEvent("UNIT_AURA")-- Register for the "UNIT_AURA" event to update buffs and debuffs
EventHandlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- This event is fired when the player enters the world, reloads the UI, or zones between map instances. Basically, it triggers whenever a loading screen appears2. This includes logging in, respawning at a graveyard, entering/leaving an instance, and other situations where a loading screen is presented.
EventHandlerFrame:RegisterEvent("PARTY_MEMBERS_CHANGED") -- This event is generated when someone joins or leaves the group

--EventHandlerFrame:RegisterEvent("PLAYER_LOGIN") -- Fires when you login only once.

--#########################################################################################################

function Debug(msg)
 DEFAULT_CHAT_FRAME:AddMessage(msg)
end



--#########################################################################################################
-- START - Create Settings UI
--#########################################################################################################

local HM_SettingsContainer = CreateFrame("Frame", "HM_SettingsContainer", UIParent)
HM_SettingsContainer:SetFrameLevel(10)
HM_SettingsContainer:SetPoint("CENTER", 0, 0)
HM_SettingsContainer:SetWidth(425) -- width
HM_SettingsContainer:SetHeight(325) -- height
HM_SettingsContainer:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
-- Enable mouse interaction and register for dragging
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

-- Create the close button
local closeButton = CreateFrame("Button", nil, HM_SettingsContainer, "UIPanelButtonTemplate")
closeButton:SetPoint("TOPRIGHT", 0, 0)
closeButton:SetWidth(70) -- width
closeButton:SetHeight(22) -- height
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
    HM_SettingsContainer:Hide()
end)

--Textbox
local TxtLeftClick = CreateFrame("EditBox", "TxtLeftClick", HM_SettingsContainer, "InputBoxTemplate")
TxtLeftClick:SetPoint("TOP", 35, -25)
TxtLeftClick:SetWidth(200) -- width
TxtLeftClick:SetHeight(30) -- height
--Label
local TxtLeftClickLabel = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtLeftClickLabel:SetPoint("RIGHT", TxtLeftClick, "LEFT", -10, 0)
TxtLeftClickLabel:SetText("Left Click:")


--Textbox
local TxtShiftLeftClick = CreateFrame("EditBox", "TxtShiftLeftClick", HM_SettingsContainer, "InputBoxTemplate")
TxtShiftLeftClick:SetPoint("TOP", 35, -50)
TxtShiftLeftClick:SetWidth(200) -- width
TxtShiftLeftClick:SetHeight(30) -- height
--Label
local TxtShiftLeftClickLabel = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtShiftLeftClickLabel:SetPoint("RIGHT", TxtShiftLeftClick, "LEFT", -10, 0)
TxtShiftLeftClickLabel:SetText("Shift + Left Click:")


--Textbox
local TxtCtrlLeftClick = CreateFrame("EditBox", "TxtCtrlLeftClick", HM_SettingsContainer, "InputBoxTemplate")
TxtCtrlLeftClick:SetPoint("TOP", 35, -75)
TxtCtrlLeftClick:SetWidth(200) -- width
TxtCtrlLeftClick:SetHeight(30) -- height
--Label
local TxtCtrlLeftLabel = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtCtrlLeftLabel:SetPoint("RIGHT", TxtCtrlLeftClick, "LEFT", -10, 0)
TxtCtrlLeftLabel:SetText("Ctrl + Left Click:")


--Middle Click
--Textbox
local TxtMiddleClick = CreateFrame("EditBox", "TxtMiddleClick", HM_SettingsContainer, "InputBoxTemplate")
TxtMiddleClick:SetPoint("TOP", 35, -125)
TxtMiddleClick:SetWidth(200) -- width
TxtMiddleClick:SetHeight(30) -- height
--Label
local TxtMiddleClickLabel = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtMiddleClickLabel:SetPoint("RIGHT", TxtMiddleClick, "LEFT", -10, 0)
TxtMiddleClickLabel:SetText("Middle Click:")

--Shift + Middle Click
--Textbox
local TxtShiftMiddleClick = CreateFrame("EditBox", "TxtShiftMiddleClick", HM_SettingsContainer, "InputBoxTemplate")
TxtShiftMiddleClick:SetPoint("TOP", 35, -150)
TxtShiftMiddleClick:SetWidth(200) -- width
TxtShiftMiddleClick:SetHeight(30) -- height
--Label
local TxtShiftMiddleClickLabel = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtShiftMiddleClickLabel:SetPoint("RIGHT", TxtShiftMiddleClick, "LEFT", -10, 0)
TxtShiftMiddleClickLabel:SetText("Shift + Middle Click:")


--Shift + Middle Click
--Textbox
local TxtCtrlMiddleClick = CreateFrame("EditBox", "TxtCtrlMiddleClick", HM_SettingsContainer, "InputBoxTemplate")
TxtCtrlMiddleClick:SetPoint("TOP", 35, -175)
TxtCtrlMiddleClick:SetWidth(200) -- width
TxtCtrlMiddleClick:SetHeight(30) -- height
--Label
local TxtCtrlMiddleClickLabel = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtCtrlMiddleClickLabel:SetPoint("RIGHT", TxtCtrlMiddleClick, "LEFT", -10, 0)
TxtCtrlMiddleClickLabel:SetText("Ctrl + Middle Click:")

--Textbox
local TxtRightClick = CreateFrame("EditBox", "TxtRightClick", HM_SettingsContainer, "InputBoxTemplate")
TxtRightClick:SetPoint("TOP", 35, -225)
TxtRightClick:SetWidth(200) -- width
TxtRightClick:SetHeight(30) -- height
--Label
local TxtRightClickLabel = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtRightClickLabel:SetPoint("RIGHT", TxtRightClick, "LEFT", -10, 0)
TxtRightClickLabel:SetText("Right Click:")


--Textbox
local TxtShiftRightClick = CreateFrame("EditBox", "TxtShiftRightClick", HM_SettingsContainer, "InputBoxTemplate")
TxtShiftRightClick:SetPoint("TOP", 35, -250)
TxtShiftRightClick:SetWidth(200) -- width
TxtShiftRightClick:SetHeight(30) -- height
--Label
local TxtShiftRightClickLabel = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtShiftRightClickLabel:SetPoint("RIGHT", TxtShiftRightClick, "LEFT", -10, 0)
TxtShiftRightClickLabel:SetText("Shift + Right Click:")


--Textbox
local TxtCtrlRightClick = CreateFrame("EditBox", "TxtCtrlRightClick", HM_SettingsContainer, "InputBoxTemplate")
TxtCtrlRightClick:SetPoint("TOP", 35, -275)
TxtCtrlRightClick:SetWidth(200) -- width
TxtCtrlRightClick:SetHeight(30) -- height
--Label
local TxtCtrlRightClickLabel = HM_SettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TxtCtrlRightClickLabel:SetPoint("RIGHT", TxtCtrlRightClick, "LEFT", -10, 0)
TxtCtrlRightClickLabel:SetText("Ctrl + Right Click:")


HM_SettingsContainer:Show()

--#########################################################################################################
-- END - Create Settings UI
--#########################################################################################################












--#########################################################################################################
--#########################################################################################################

--##START## Create UI

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
PlayerBuffPanel:SetPoint("TOPLEFT", PlayerStatusBar, "BOTTOMLEFT", 0, -PlayerBuffPanelpaddingTop) -- position it at the bottom left of the player name
PlayerBuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of PlayerContainer
local totalHeight = playerName:GetHeight() + playerNamepaddingTop + PlayerStatusBar:GetHeight() + PlayerStatusBarpaddingTop + PlayerBuffPanel:GetHeight() + PlayerBuffPanelpaddingTop
PlayerContainer:SetHeight(totalHeight+12) --10
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
Party1BuffPanel:SetPoint("TOPLEFT", Party1StatusBar, "BOTTOMLEFT", 0, -Party1BuffPanelpaddingTop) -- position it at the bottom left of the Party1 name
Party1BuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of Party1Container
local Party1TotalHeight = Party1Name:GetHeight() + Party1NamepaddingTop + Party1StatusBar:GetHeight() + Party1StatusBarpaddingTop + Party1BuffPanel:GetHeight() + Party1BuffPanelpaddingTop
Party1Container:SetHeight(Party1TotalHeight+12) --10
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
Party2BuffPanel:SetPoint("TOPLEFT", Party2StatusBar, "BOTTOMLEFT", 0, -Party2BuffPanelpaddingTop) -- position it at the bottom left of the Party2 name
Party2BuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of Party2Container
local Party2TotalHeight = Party2Name:GetHeight() + Party2NamepaddingTop + Party2StatusBar:GetHeight() + Party2StatusBarpaddingTop + Party2BuffPanel:GetHeight() + Party2BuffPanelpaddingTop
Party2Container:SetHeight(Party2TotalHeight+12) --10
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
Party3BuffPanel:SetPoint("TOPLEFT", Party3StatusBar, "BOTTOMLEFT", 0, -Party3BuffPanelpaddingTop) -- position it at the bottom left of the Party3 name
Party3BuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of Party3Container
local Party3TotalHeight = Party3Name:GetHeight() + Party3NamepaddingTop + Party3StatusBar:GetHeight() + Party3StatusBarpaddingTop + Party3BuffPanel:GetHeight() + Party3BuffPanelpaddingTop
Party3Container:SetHeight(Party3TotalHeight+12) --10
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
function Settings_DragStart()
Debug("start")
end

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
Party4BuffPanel:SetPoint("TOPLEFT", Party4StatusBar, "BOTTOMLEFT", 0, -Party4BuffPanelpaddingTop) -- position it at the bottom left of the Party4 name
Party4BuffPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background

--Resize Container to match its contents
-- Calculate total height of all elements and their padding and set it as the height of Party4Container
local Party4TotalHeight = Party4Name:GetHeight() + Party4NamepaddingTop + Party4StatusBar:GetHeight() + Party4StatusBarpaddingTop + Party4BuffPanel:GetHeight() + Party4BuffPanelpaddingTop
Party4Container:SetHeight(Party4TotalHeight+12) --10
--## END ## Create a panel for Party4 buff/debuff icons

--##END## Create Party4 UI


--#########################################################################################################
--#########################################################################################################
--#########################################################################################################
--#########################################################################################################

function eventAddonLoaded()
	--## Initilize Addon here. ##
	
	--##START## Create Default Values for Settings if Addon has never ran before.
	
	
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
		
		end
	
		FreshInstall = false
	end
	--######

	
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

local function UpdatePlayerHealthValues()

		--Update Players Health Values, Name
		local PlayerName = UnitName("player")
		local PlayerClass, UpperCaseClass = UnitClass("player")
        local PlayerCurrentHealth = UnitHealth("player")
        local PlayerMaxHealth = UnitHealthMax("player")
		
		local cr,cg,cb = GetClassColor(UpperCaseClass)
			if cr then
				playerName:SetText(PlayerName .. "  ( |cFF" .. string.format("%02x%02x%02x", cr * 255, cg * 255, cb * 255) .. PlayerClass .. "|r )")
			else
				playerName:SetText(PlayerName .. "  ( " .. PlayerClass .. " )")
			end
		
		PlayerButton:SetText(PlayerCurrentHealth .. "/" .. PlayerMaxHealth .. "(" .. math.floor((PlayerCurrentHealth / PlayerMaxHealth)*100) .. "%" .. ")")
		PlayerStatusBar:SetValue((PlayerCurrentHealth / PlayerMaxHealth))


end

local function UpdateParty1HealthValues()

		if UnitIsConnected("party1") then
			--Player("party1") is Online
			--Update Players Health Values, Name
			local CurrentParty1Name = UnitName("party1")
			local Party1Class, UpperCaseClass = UnitClass("party1")
			local Party1CurrentHealth = UnitHealth("party1")
			local Party1MaxHealth = UnitHealthMax("party1")
			local cr,cg,cb = GetClassColor(UpperCaseClass)
			
			if cr then
				Party1Name:SetText(CurrentParty1Name .. "  ( |cFF" .. string.format("%02x%02x%02x", cr * 255, cg * 255, cb * 255) .. tostring(Party1Class) .. "|r )")
			else
				Party1Name:SetText(CurrentParty1Name .. "  ( " .. Party1Class .. " )")
			end
		
			Party1Button:SetText(Party1CurrentHealth .. "/" .. Party1MaxHealth .. "(" .. math.floor((Party1CurrentHealth / Party1MaxHealth)*100) .. "%" .. ")")
			Party1StatusBar:SetValue((Party1CurrentHealth / Party1MaxHealth))
		
		else
			--Player("party1") is Offfline
			Party1Name:SetText("User Offline")
			Party1Button:SetText("<< Offline >>")
			Party1StatusBar:SetValue(0)
		
		end

end

local function UpdateParty2HealthValues()
	
		if UnitIsConnected("party2") then
			--Player("party2") is Online
			--Update Players Health Values, Name
			local CurrentParty2Name = UnitName("party2")
			local Party2Class, UpperCaseClass = UnitClass("party2")
			local Party2CurrentHealth = UnitHealth("party2")
			local Party2MaxHealth = UnitHealthMax("party2")
		
			local cr,cg,cb = GetClassColor(UpperCaseClass)
				if cr then
					Party2Name:SetText(CurrentParty2Name .. "  ( |cFF" .. string.format("%02x%02x%02x", cr * 255, cg * 255, cb * 255) .. Party2Class .. "|r )")
				else
					Party2Name:SetText(CurrentParty2Name .. "  ( " .. Party2Class .. " )")
				end
		
			Party2Button:SetText(Party2CurrentHealth .. "/" .. Party2MaxHealth .. "(" .. math.floor((Party2CurrentHealth / Party2MaxHealth)*100) .. "%" .. ")")
			Party2StatusBar:SetValue((Party2CurrentHealth / Party2MaxHealth))
		else
			--Player("party2") is Offfline
			Party2Name:SetText("User Offline")
			Party2Button:SetText("<< Offline >>")
			Party2StatusBar:SetValue(0)
		
		end

end

local function UpdateParty3HealthValues()

		if UnitIsConnected("party3") then
			--Player("Party3") is Online
			--Update Players Health Values, Name
			local CurrentParty3Name = UnitName("party3")
			local Party3Class, UpperCaseClass = UnitClass("party3")
			local Party3CurrentHealth = UnitHealth("party3")
			local Party3MaxHealth = UnitHealthMax("party3")
			local cr,cg,cb = GetClassColor(UpperCaseClass)
			
			if cr then
				Party3Name:SetText(CurrentParty3Name .. "  ( |cFF" .. string.format("%02x%02x%02x", cr * 255, cg * 255, cb * 255) .. tostring(Party3Class) .. "|r )")
			else
				Party3Name:SetText(CurrentParty3Name .. "  ( " .. Party3Class .. " )")
			end
		
			Party3Button:SetText(Party3CurrentHealth .. "/" .. Party3MaxHealth .. "(" .. math.floor((Party3CurrentHealth / Party3MaxHealth)*100) .. "%" .. ")")
			Party3StatusBar:SetValue((Party3CurrentHealth / Party3MaxHealth))
		
		else
			--Player("party3") is Offfline
			Party3Name:SetText("User Offline")
			Party3Button:SetText("<< Offline >>")
			Party3StatusBar:SetValue(0)
		
		end

end

local function UpdateParty4HealthValues()

		if UnitIsConnected("party4") then
			--Player("party4") is Online
			--Update Players Health Values, Name
			local CurrentParty4Name = UnitName("party4")
			local Party4Class, UpperCaseClass = UnitClass("party4")
			local Party4CurrentHealth = UnitHealth("party4")
			local Party4MaxHealth = UnitHealthMax("party4")
			local cr,cg,cb = GetClassColor(UpperCaseClass)
			
			if cr then
				Party4Name:SetText(CurrentParty4Name .. "  ( |cFF" .. string.format("%02x%02x%02x", cr * 255, cg * 255, cb * 255) .. tostring(Party4Class) .. "|r )")
			else
				Party4Name:SetText(CurrentParty4Name .. "  ( " .. Party4Class .. " )")
			end
		
			Party4Button:SetText(Party4CurrentHealth .. "/" .. Party4MaxHealth .. "(" .. math.floor((Party4CurrentHealth / Party4MaxHealth)*100) .. "%" .. ")")
			Party4StatusBar:SetValue((Party4CurrentHealth / Party4MaxHealth))
		
		else
			--Player("party4") is Offfline
			Party4Name:SetText("User Offline")
			Party4Button:SetText("<< Offline >>")
			Party4StatusBar:SetValue(0)
		
		end

end

local function UpdateHealthValues(person)
		--Update Players Health Values
		local SpecifiedPerson = tostring(person)  --player, party1, party2, etc..
		
		local SpecifiedPersonCurrentHealth = UnitHealth(SpecifiedPerson)
        local SpecifiedPersonMaxHealth = UnitHealthMax(SpecifiedPerson)
		
		if SpecifiedPerson == "player" then
			
			if UnitIsConnected("player") then				
				--Online
				--This is the person playing this should always be true
				PlayerButton:SetText(SpecifiedPersonCurrentHealth .. "/" .. SpecifiedPersonMaxHealth .. "(" .. math.floor((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth)*100) .. "%" .. ")")
				PlayerStatusBar:SetValue((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth))
			else
				--Offline; this happens when someone is in your party already but goes offline
				--This should never trigger.
				PlayerButton:SetText("<< Offline >>")
				PlayerStatusBar:SetValue(0)
			end
			
		elseif SpecifiedPerson == "party1" then
			
			if UnitIsConnected("party1") then
				--Online			
				Party1Button:SetText(SpecifiedPersonCurrentHealth .. "/" .. SpecifiedPersonMaxHealth .. "(" .. math.floor((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth)*100) .. "%" .. ")")
				Party1StatusBar:SetValue((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth))
			else
				--Offline; this happens when someone is in your party already but goes offline
				Party1Button:SetText("<< Offline >>")
				Party1StatusBar:SetValue(0)
			end
			
		elseif SpecifiedPerson == "party2" then
			
			if UnitIsConnected("party2") then
				--Online
				Party2Button:SetText(SpecifiedPersonCurrentHealth .. "/" .. SpecifiedPersonMaxHealth .. "(" .. math.floor((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth)*100) .. "%" .. ")")
				Party2StatusBar:SetValue((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth))
			else
				--Offline; this happens when someone is in your party already but goes offline
				Party2Button:SetText("<< Offline >>")
				Party2StatusBar:SetValue(0)
			end
		
		elseif SpecifiedPerson == "party3" then
			
			if UnitIsConnected("party3") then
				--Online
				Party3Button:SetText(SpecifiedPersonCurrentHealth .. "/" .. SpecifiedPersonMaxHealth .. "(" .. math.floor((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth)*100) .. "%" .. ")")
				Party3StatusBar:SetValue((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth))
			else
				--Offline; this happens when someone is in your party already but goes offline
				Party3Button:SetText("<< Offline >>")
				Party3StatusBar:SetValue(0)
			end
		
		elseif SpecifiedPerson == "party4" then
			
			if UnitIsConnected("party4") then
				--Online
				Party4Button:SetText(SpecifiedPersonCurrentHealth .. "/" .. SpecifiedPersonMaxHealth .. "(" .. math.floor((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth)*100) .. "%" .. ")")
				Party4StatusBar:SetValue((SpecifiedPersonCurrentHealth / SpecifiedPersonMaxHealth))
			else
				--Offline; this happens when someone is in your party already but goes offline
				Party4Button:SetText("<< Offline >>")
				Party4StatusBar:SetValue(0)
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
	
	GameTooltip:SetUnitBuff("player", buffindex)
	
	-- Get the number of lines in the tooltip
	local numLines = GameTooltip:NumLines()
	local Line1Text = tostring(GameTooltipTextLeft1:GetText())
	local Line2Text = tostring(GameTooltipTextLeft2:GetText())
	local Line3Text = tostring(GameTooltipTextLeft3:GetText())
	local Line4Text = tostring(GameTooltipTextLeft4:GetText())
	local Line5Text = tostring(GameTooltipTextLeft5:GetText())
	local Line6Text = tostring(GameTooltipTextLeft6:GetText())
	local Line7Text = tostring(GameTooltipTextLeft7:GetText())
	local Line8Text = tostring(GameTooltipTextLeft8:GetText())
	local Line9Text = tostring(GameTooltipTextLeft9:GetText())
	
	
	-- Set a script to show the tooltip when the mouse is over the icon
	
	if Line1Text ~= "nil" then --Tooltip information isn't always returned when i try to retrieve it.
	
		PlayerBuffIconFrame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(PlayerBuffIconFrame, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:ClearLines() -- Clear current lines
	
			if Btype == "Buff" then
				--Green for Buff
				GameTooltip:AddLine(Line1Text, 0, 1, 0)
			else
				--Red for Debuff
				GameTooltip:AddLine(Line1Text, 1, 0, 0)
			end
			
			--Description
			if Line2Text ~= "nil" then GameTooltip:AddLine(Line2Text, 1, 1, 1) end
			if Line3Text ~= "nil" then GameTooltip:AddLine(Line3Text, 1, 1, 1) end
			if Line4Text ~= "nil" then GameTooltip:AddLine(Line4Text, 1, 1, 1) end
			if Line5Text ~= "nil" then GameTooltip:AddLine(Line5Text, 1, 1, 1) end
			if Line6Text ~= "nil" then GameTooltip:AddLine(Line6Text, 1, 1, 1) end
			if Line7Text ~= "nil" then GameTooltip:AddLine(Line7Text, 1, 1, 1) end
			if Line8Text ~= "nil" then GameTooltip:AddLine(Line8Text, 1, 1, 1) end
			if Line9Text ~= "nil" then GameTooltip:AddLine(Line9Text, 1, 1, 1) end
			
			GameTooltip:Show()
		end)
	
	end
	
	-- Set a script to hide the tooltip when the mouse leaves the icon
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
	
	GameTooltip:SetUnitBuff("party1", buffindex)
	
	-- Get the number of lines in the tooltip
	local numLines = GameTooltip:NumLines()
	local Line1Text = tostring(GameTooltipTextLeft1:GetText())
	local Line2Text = tostring(GameTooltipTextLeft2:GetText())
	local Line3Text = tostring(GameTooltipTextLeft3:GetText())
	local Line4Text = tostring(GameTooltipTextLeft4:GetText())
	local Line5Text = tostring(GameTooltipTextLeft5:GetText())
	local Line6Text = tostring(GameTooltipTextLeft6:GetText())
	local Line7Text = tostring(GameTooltipTextLeft7:GetText())
	local Line8Text = tostring(GameTooltipTextLeft8:GetText())
	local Line9Text = tostring(GameTooltipTextLeft9:GetText())
	
	
	-- Set a script to show the tooltip when the mouse is over the icon
	
	if Line1Text ~= "nil" then --Tooltip information isn't always returned when i try to retrieve it.
	
		Party1BuffIconFrame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(Party1BuffIconFrame, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:ClearLines() -- Clear current lines
	
			if Btype == "Buff" then
				--Green for Buff
				GameTooltip:AddLine(Line1Text, 0, 1, 0)
			else
				--Red for Debuff
				GameTooltip:AddLine(Line1Text, 1, 0, 0)
			end
			
			--Description
			if Line2Text ~= "nil" then GameTooltip:AddLine(Line2Text, 1, 1, 1) end
			if Line3Text ~= "nil" then GameTooltip:AddLine(Line3Text, 1, 1, 1) end
			if Line4Text ~= "nil" then GameTooltip:AddLine(Line4Text, 1, 1, 1) end
			if Line5Text ~= "nil" then GameTooltip:AddLine(Line5Text, 1, 1, 1) end
			if Line6Text ~= "nil" then GameTooltip:AddLine(Line6Text, 1, 1, 1) end
			if Line7Text ~= "nil" then GameTooltip:AddLine(Line7Text, 1, 1, 1) end
			if Line8Text ~= "nil" then GameTooltip:AddLine(Line8Text, 1, 1, 1) end
			if Line9Text ~= "nil" then GameTooltip:AddLine(Line9Text, 1, 1, 1) end
			
			GameTooltip:Show()
		end)
	
	end
	
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
	
	GameTooltip:SetUnitBuff("party2", buffindex)
	
	-- Get the number of lines in the tooltip
	local numLines = GameTooltip:NumLines()
	local Line1Text = tostring(GameTooltipTextLeft1:GetText())
	local Line2Text = tostring(GameTooltipTextLeft2:GetText())
	local Line3Text = tostring(GameTooltipTextLeft3:GetText())
	local Line4Text = tostring(GameTooltipTextLeft4:GetText())
	local Line5Text = tostring(GameTooltipTextLeft5:GetText())
	local Line6Text = tostring(GameTooltipTextLeft6:GetText())
	local Line7Text = tostring(GameTooltipTextLeft7:GetText())
	local Line8Text = tostring(GameTooltipTextLeft8:GetText())
	local Line9Text = tostring(GameTooltipTextLeft9:GetText())
	
	-- Set a script to show the tooltip when the mouse is over the icon
	
	if Line1Text ~= "nil" then --Tooltip information isn't always returned when i try to retrieve it.
	
		Party2BuffIconFrame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(Party2BuffIconFrame, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:ClearLines() -- Clear current lines
	
			if Btype == "Buff" then
				--Green for Buff
				GameTooltip:AddLine(Line1Text, 0, 1, 0)
			else
				--Red for Debuff
				GameTooltip:AddLine(Line1Text, 1, 0, 0)
			end
			
			--Description
			if Line2Text ~= "nil" then GameTooltip:AddLine(Line2Text, 1, 1, 1) end
			if Line3Text ~= "nil" then GameTooltip:AddLine(Line3Text, 1, 1, 1) end
			if Line4Text ~= "nil" then GameTooltip:AddLine(Line4Text, 1, 1, 1) end
			if Line5Text ~= "nil" then GameTooltip:AddLine(Line5Text, 1, 1, 1) end
			if Line6Text ~= "nil" then GameTooltip:AddLine(Line6Text, 1, 1, 1) end
			if Line7Text ~= "nil" then GameTooltip:AddLine(Line7Text, 1, 1, 1) end
			if Line8Text ~= "nil" then GameTooltip:AddLine(Line8Text, 1, 1, 1) end
			if Line9Text ~= "nil" then GameTooltip:AddLine(Line9Text, 1, 1, 1) end
			
			GameTooltip:Show()
		end)
	
	end
	
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
	
	GameTooltip:SetUnitBuff("party3", buffindex)
	
	-- Get the number of lines in the tooltip
	local numLines = GameTooltip:NumLines()
	local Line1Text = tostring(GameTooltipTextLeft1:GetText())
	local Line2Text = tostring(GameTooltipTextLeft2:GetText())
	local Line3Text = tostring(GameTooltipTextLeft3:GetText())
	local Line4Text = tostring(GameTooltipTextLeft4:GetText())
	local Line5Text = tostring(GameTooltipTextLeft5:GetText())
	local Line6Text = tostring(GameTooltipTextLeft6:GetText())
	local Line7Text = tostring(GameTooltipTextLeft7:GetText())
	local Line8Text = tostring(GameTooltipTextLeft8:GetText())
	local Line9Text = tostring(GameTooltipTextLeft9:GetText())
	
	-- Set a script to show the tooltip when the mouse is over the icon
	
	if Line1Text ~= "nil" then --Tooltip information isn't always returned when i try to retrieve it.
	
		Party3BuffIconFrame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(Party3BuffIconFrame, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:ClearLines() -- Clear current lines
	
			if Btype == "Buff" then
				--Green for Buff
				GameTooltip:AddLine(Line1Text, 0, 1, 0)
			else
				--Red for Debuff
				GameTooltip:AddLine(Line1Text, 1, 0, 0)
			end
			
			--Description
			if Line2Text ~= "nil" then GameTooltip:AddLine(Line2Text, 1, 1, 1) end
			if Line3Text ~= "nil" then GameTooltip:AddLine(Line3Text, 1, 1, 1) end
			if Line4Text ~= "nil" then GameTooltip:AddLine(Line4Text, 1, 1, 1) end
			if Line5Text ~= "nil" then GameTooltip:AddLine(Line5Text, 1, 1, 1) end
			if Line6Text ~= "nil" then GameTooltip:AddLine(Line6Text, 1, 1, 1) end
			if Line7Text ~= "nil" then GameTooltip:AddLine(Line7Text, 1, 1, 1) end
			if Line8Text ~= "nil" then GameTooltip:AddLine(Line8Text, 1, 1, 1) end
			if Line9Text ~= "nil" then GameTooltip:AddLine(Line9Text, 1, 1, 1) end
			
			GameTooltip:Show()
		end)
	
	end
	
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
	
	GameTooltip:SetUnitBuff("party4", buffindex)
	
	-- Get the number of lines in the tooltip
	local numLines = GameTooltip:NumLines()
	local Line1Text = tostring(GameTooltipTextLeft1:GetText())
	local Line2Text = tostring(GameTooltipTextLeft2:GetText())
	local Line3Text = tostring(GameTooltipTextLeft3:GetText())
	local Line4Text = tostring(GameTooltipTextLeft4:GetText())
	local Line5Text = tostring(GameTooltipTextLeft5:GetText())
	local Line6Text = tostring(GameTooltipTextLeft6:GetText())
	local Line7Text = tostring(GameTooltipTextLeft7:GetText())
	local Line8Text = tostring(GameTooltipTextLeft8:GetText())
	local Line9Text = tostring(GameTooltipTextLeft9:GetText())
	
	-- Set a script to show the tooltip when the mouse is over the icon
	
	if Line1Text ~= "nil" then --Tooltip information isn't always returned when i try to retrieve it.
	
		Party4BuffIconFrame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(Party4BuffIconFrame, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:ClearLines() -- Clear current lines
	
			if Btype == "Buff" then
				--Green for Buff
				GameTooltip:AddLine(Line1Text, 0, 1, 0)
			else
				--Red for Debuff
				GameTooltip:AddLine(Line1Text, 1, 0, 0)
			end
			
			--Description
			if Line2Text ~= "nil" then GameTooltip:AddLine(Line2Text, 1, 1, 1) end
			if Line3Text ~= "nil" then GameTooltip:AddLine(Line3Text, 1, 1, 1) end
			if Line4Text ~= "nil" then GameTooltip:AddLine(Line4Text, 1, 1, 1) end
			if Line5Text ~= "nil" then GameTooltip:AddLine(Line5Text, 1, 1, 1) end
			if Line6Text ~= "nil" then GameTooltip:AddLine(Line6Text, 1, 1, 1) end
			if Line7Text ~= "nil" then GameTooltip:AddLine(Line7Text, 1, 1, 1) end
			if Line8Text ~= "nil" then GameTooltip:AddLine(Line8Text, 1, 1, 1) end
			if Line9Text ~= "nil" then GameTooltip:AddLine(Line9Text, 1, 1, 1) end
			
			GameTooltip:Show()
		end)
	
	end
	
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
				CastSpellByName(Spell, ClickedPerson)
			
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
				CastSpellByName(Spell, ClickedPerson)
			
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
				CastSpellByName(Spell, ClickedPerson)
			
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
				CastSpellByName(Spell, ClickedPerson)
			
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
				CastSpellByName(Spell, ClickedPerson)
			
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
				CastSpellByName(Spell, ClickedPerson)
			
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
				CastSpellByName(Spell, ClickedPerson)
			
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
				CastSpellByName(Spell, ClickedPerson)
			
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
				CastSpellByName(Spell, ClickedPerson)
			
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

function Check4Group()
		
		local NumPartyMembers = GetNumPartyMembers()
		
		
		if NumPartyMembers == 0 then
			--No Party; Update Players Names, Health
			UpdatePlayerHealthValues()
			UpdatePlayerBuffDebuffIcons()
			
			--Show/Hide Party Frames that are needed
			Party1Container:Hide() --Make the Party1 persons UI invisible
			Party2Container:Hide() --Make the Party1 persons UI invisible
			Party3Container:Hide() --Make the Party1 persons UI invisible
			Party4Container:Hide() --Make the Party1 persons UI invisible
			
		elseif NumPartyMembers == 1 then
			--Party with two people including the player
			
			--Update Party Members Names, Health
			UpdatePlayerHealthValues()
			UpdateParty1HealthValues()
			
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
			UpdatePlayerHealthValues()
			UpdateParty1HealthValues()
			UpdateParty2HealthValues()
			
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
			UpdatePlayerHealthValues()
			UpdateParty1HealthValues()
			UpdateParty2HealthValues()
			UpdateParty3HealthValues()
			
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
			UpdatePlayerHealthValues()
			UpdateParty1HealthValues()
			UpdateParty2HealthValues()
			UpdateParty3HealthValues()
			UpdateParty4HealthValues()
			
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
		--arg1 == player, party1,party2, etc..
		--Used to update Health values as people take damage
		
		UpdateHealthValues(arg1)
	
	elseif event =="UNIT_AURA" then
		
		local WhoTriggered = arg1 --arg1 == player, party1,party2, etc..
		
		if WhoTriggered == "player" then
		
			UpdatePlayerBuffDebuffIcons()

		elseif WhoTriggered == "party1" then
			
			UpdateParty1BuffDebuffIcons()
		
		elseif WhoTriggered == "party2" then
			
			UpdateParty2BuffDebuffIcons()
		
		elseif WhoTriggered == "party3" then
			
			UpdateParty3BuffDebuffIcons()
		
		elseif WhoTriggered == "party4" then
			
			UpdateParty4BuffDebuffIcons()
		end
		
		
	elseif event =="PARTY_MEMBERS_CHANGED" then
	    Check4Group()
	
	end

end

	
-- Needs to appear after the eventHandler function in the code
EventHandlerFrame:SetScript("OnEvent", eventHandler)
-- Show the button and status bar
PlayerButton:Show()
PlayerStatusBar:Show()
PlayerBuffPanel:Show()
