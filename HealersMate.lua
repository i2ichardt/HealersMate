SLASH_HEALERSMATE1 = "/healersmate"
SLASH_HEALERSMATE2 = "/hm"
SlashCmdList["HEALERSMATE"] = function(args)
	if args == "reset" then
		for _, group in pairs(HealersMate.HealUIGroups) do
			group:GetContainer():ClearAllPoints()
			group:GetContainer():SetPoint("CENTER", 0, 0)
		end
		DEFAULT_CHAT_FRAME:AddMessage("Reset all frame positions.")
		return
	elseif args == "check" then
		HealersMate.Check4Group()
		return
	elseif args == "update" then
		for _, ui in pairs(HealersMate.HealUIs) do
			ui:SizeElements()
			ui:UpdateAll()
		end
		for _, group in pairs(HealersMate.HealUIGroups) do
			group:ApplyProfile()
			group:UpdateUIPositions()
		end
		return
	end

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
end

HealersMate = {}
local _G = getfenv(0)
setmetatable(HealersMate, {__index = getfenv(1)})
setfenv(1, HealersMate)

TestUI = false

local util = HMUtil
local colorize = util.Colorize
local GetKeyModifier = util.GetKeyModifier
local GetClass = util.GetClass
local GetPowerType = util.GetPowerType

PartyUnits = {"player", "party1", "party2", "party3", "party4"}
PetUnits = {"pet", "partypet1", "partypet2", "partypet3", "partypet4"}
TargetUnits = {"target"}
RaidUnits = {}
for i = 1, 40 do
	RaidUnits[i] = "raid"..i
end
RaidPetUnits = {}
for i = 1, 40 do
	RaidPetUnits[i] = "raidpet"..i
end

local unitArrays = {PartyUnits, PetUnits, RaidUnits, RaidPetUnits, TargetUnits}
AllUnits = {}
for _, unitArray in ipairs(unitArrays) do
	for _, unit in ipairs(unitArray) do
		table.insert(AllUnits, unit)
	end
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

SpellsTooltip = CreateFrame("GameTooltip", "HMSpellsTooltip", UIParent, "GameTooltipTemplate")
SpellsTooltipOwner = nil

-- Contains all individual player healing UIs
HealUIs = {}
-- Contains all the healing UI groups
HealUIGroups = {}


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

EventHandlerFrame:RegisterEvent("UNIT_MANA")
EventHandlerFrame:RegisterEvent("UNIT_RAGE")
EventHandlerFrame:RegisterEvent("UNIT_ENERGY")
EventHandlerFrame:RegisterEvent("UNIT_MAXMANA")

-- Not sure if there's a better way to detect key presses. At least this is a relatively lightweight function.
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

function IsSuperWowEnabled()
	return SpellInfo ~= nil
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


local ScanningTooltip = CreateFrame("GameTooltip", "HMScanningTooltip", nil, "GameTooltipTemplate");
ScanningTooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
-- Allow tooltip SetX() methods to dynamically add new lines based on these
ScanningTooltip:AddFontStrings(
    ScanningTooltip:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
    ScanningTooltip:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ) );

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
	local spellList = {}
	local modifier = GetKeyModifier()
	local settings = HealersMateSettings
	local spells = UnitCanAttack("player", unit) and GetHostileSpells() or GetSpells()

	local deadFriend = util.IsDeadFriend(unit)
	local selfClass = GetClass("player")
	local canResurrect = deadFriend and ResurrectionSpells[selfClass]

	for _, btn in ipairs(settings.CustomButtonOrder) do
		if canResurrect then -- Show all spells as the resurrection spell
			local kv = {}
			local readableButton = settings.CustomButtonNames[btn] or ReadableButtonMap[btn]
			kv[readableButton] = ResurrectionSpells[selfClass]
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
			elseif SpecialBinds[spell] then
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

local keyModifiers = {"None", "Shift", "Control", "Alt"}
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
		for _, modifier in ipairs(keyModifiers) do
			if not spells[modifier] then
				spells[modifier] = {}
			end
		end
	end

	HealersMateSettings.SetDefaults()
	HealersMateSettings.InitSettings()

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

		DEFAULT_CHAT_FRAME:AddMessage(colorize("Welcome to HealersMate! Use /hm to configure spell bindings.", 0.4, 1, 0.4))
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
	end
}

function ClickHandler(buttonType, unit)
	if not UnitIsConnected(unit) or not UnitIsVisible(unit) then
		return
	end
	
	local currentTargetEnemy = UnitCanAttack("player", "target")
	
	local spells = UnitCanAttack("player", unit) and GetHostileSpells() or GetSpells()
	local spell = spells[GetKeyModifier()][buttonType]
	if util.IsDeadFriend(unit) then
		spell = ResurrectionSpells[GetClass("player")]
	end
	
	if spell == nil then
		return
	end

	if SpecialBinds[spell] then
		SpecialBinds[spell](unit)
		return
	end

	-- Not a special bind
	if IsSuperWowEnabled() then -- No target changing shenanigans required with SuperWoW
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

local function createUIGroup(groupName, environment, units, petGroup)
	local uiGroup = HealUIGroup:New(groupName, environment, units, petGroup)
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

HealUIGroups["Party"] = createUIGroup("Party", "party", PartyUnits, false)
HealUIGroups["Pets"] = createUIGroup("Pets", "party", PetUnits, true)
HealUIGroups["Raid"] = createUIGroup("Raid", "raid", RaidUnits, false)
HealUIGroups["RaidPets"] = createUIGroup("Raid Pets", "raid", RaidPetUnits, true)
HealUIGroups["Target"] = createUIGroup("Target", "all", TargetUnits, false)

HealUIGroups["Target"].ShowCondition = function(self)
	return UnitExists("target")
end
HealUIGroups["Target"]:Hide()

-- Reevaluates what UI frames should be shown
function CheckGroup()
	local environment = "party"
	if GetNumRaidMembers() > 0 then
		environment = "raid"
	end
	for unit, ui in pairs(HealUIs) do
		if unit ~= "target" then
			if UnitExists(unit) then
				ui:Show()
			else
				ui:Hide()
			end
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
end


function IsRelevantUnit(unit)
	--return not string.find(unit, "0x")
	return HealUIs[unit] ~= nil
end

function EventHandler()
	if event == "ADDON_LOADED" then
		
		EventAddonLoaded()
		EventHandlerFrame:UnregisterEvent("ADDON_LOADED")
	
	elseif event == "PLAYER_ENTERING_WORLD" then
		
		CheckGroup()
		
	elseif event == "PLAYER_LOGOUT" or event == "PLAYER_QUITING" then
		
		
	elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
		local unit = arg1
		if not IsRelevantUnit(unit) then
			return
		end
		HealUIs[unit]:UpdateHealth()
	elseif event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" or event == "UNIT_MAXMANA" then
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

		if UnitExists("target") then
			HealUIGroups["Target"]:Hide()
			local friendly = not UnitCanAttack("player", "target")
			if (friendly and HMOptions["ShowTargets"]["Friendly"]) or (not friendly and HMOptions["ShowTargets"]["Hostile"]) then
				HealUIGroups["Target"]:Show()
			end
		else
			HealUIGroups["Target"]:Hide()
		end
	end
end

EventHandlerFrame:SetScript("OnEvent", EventHandler)