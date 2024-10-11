HealUI = {}

HealUI.owningGroup = nil

HealUI.unit = nil

HealUI.container = nil
HealUI.name = nil
HealUI.healthBar = nil
HealUI.powerBar = nil
HealUI.button = nil
HealUI.auraPanel = nil
HealUI.scrollingDamageFrame = nil -- Unimplemented
HealUI.scrollingHealFrame = nil -- Unimplemented
HealUI.auraIconPool = {} -- array: {"frame", "icon", "stackText"}
HealUI.auraIcons = {} -- array: {"frame", "icon", "stackText"}
HealUI.afflictedDebuffTypes = {} -- A set cache of debuff types currently on the player

HealUI.fakeClass = nil -- Used for displaying a fake party/raid

-- Singleton references, assigned in constructor
local HM
local util

function HealUI:New(unit)
    local obj = {unit = unit, auraIconPool = {}, auraIcons = {}, afflictedDebuffTypes = {}, fakeClass = HMUtil.GetRandomClass()}
    setmetatable(obj, self)
    self.__index = self
    HM = HealersMate -- Need to do this in the constructor or else it doesn't exist yet
    util = HMUtil
    return obj
end

function HealUI:GetUnit()
    return self.unit
end

function HealUI:GetContainer()
    return self.container
end

function HealUI:Show()
    self.container:Show()
    self:UpdateAll()
end

function HealUI:Hide()
    if not self:IsFake() then
        self.container:Hide()
    end
end

function HealUI:SetOwningGroup(group)
    self.owningGroup = group
    self:Initialize()
    self:GetContainer():SetParent(group:GetContainer())
end

function HealUI:UpdateAll()
    self:UpdateAuras()
    self:UpdateHealth()
    self:UpdatePower()
end

function HealUI.GetColorizedText(color, class, theText)
    local text = ""
    if color == "Class" then
        local r, g, b = util.GetClassColor(class)
        if r then
            text = text..util.Colorize(theText, r, g, b)
        else
            text = text..theText
        end
    elseif color == "Default" then
        text = text..theText
    elseif type(color) == "table" then
        text = text..util.Colorize(theText, color)
    end
    return text
end

function HealUI:UpdateHealth()
    if not UnitExists(self.unit) and not self:IsFake() then
        return
    end
    local profile = self:GetProfile()
    local unit = self.unit

    local fake = self:IsFake()
    local fakeOnline = true
    if fake then
        if math.random(10) == 1 then
            fakeOnline = false
        end
    end
    
    local currentHealth
    local maxHealth
    if fake then
        maxHealth = math.random(100, 5000)
        if math.random(10) > 3 then
            currentHealth = math.random(1, maxHealth)
        elseif math.random(10) == 1 then
            currentHealth = 0
        else
            currentHealth = maxHealth
        end
    else
        currentHealth = UnitHealth(unit)
        maxHealth = UnitHealthMax(unit)
    end
    
    local unitName = fake and unit or UnitName(unit)
    local class = fake and self.fakeClass or util.GetClass(unit)

    self.container:SetAlpha(1) -- Reset to opaque, may be changed further down

    if not UnitIsConnected(unit) and (not fake or not fakeOnline) then
        self.name:SetText(self.GetColorizedText(profile.NameText.Color, class, unitName))
        self.button:SetText(util.Colorize("Offline", 0.7, 0.7, 0.7))
        self.healthBar:SetValue(0)
        self.powerBar:SetValue(0)
        return
    end

    -- Set Name and its colors
    local nameText
    if UnitIsPlayer(unit) or fake then
        nameText = self.GetColorizedText(profile.NameText.Color, class, unitName)
    else -- Unit is not a player
        if UnitIsEnemy("player", unit) then
            nameText = util.Colorize(unitName, 1, 0.3, 0.3)
        else -- Unit is not an enemy
            nameText = unitName
        end
    end
    self.name:SetText(nameText)

    -- Set Health Status
    if currentHealth <= 0 then -- Unit Dead

        local healthText = util.Colorize("DEAD", 1, 0.3, 0.3)

        -- Check for Feign Death so the healer doesn't get alarmed
        if HMUtil.IsFeigning(unit) then
            healthText = "Feign"
        end

        self.button:SetText(healthText)
        self.healthBar:SetValue(0)
        self.powerBar:SetValue(0)
    elseif UnitIsGhost(unit) then
        self.button:SetText(util.Colorize("Ghost", 1, 0.3, 0.3))
        self.healthBar:SetValue(0)
        self.powerBar:SetValue(0)
    else -- Unit Not Dead
        local text = ""
        if profile.HealthDisplay == "Health/Max Health" then
            text = currentHealth.."/"..maxHealth
        elseif profile.HealthDisplay == "Health" then
            text = currentHealth
        elseif profile.HealthDisplay == "% Health" then
            text = math.floor((currentHealth / maxHealth) * 100).."%"
        end

        local missingHealth = math.floor(maxHealth - currentHealth)
        
        if (missingHealth > 0 or profile.AlwaysShowMissingHealth) and profile.MissingHealthDisplay ~= "Hidden" 
                and (profile.ShowEnemyMissingHealth or not self:IsEnemy()) then
            local hadHealthText = text ~= ""
            if hadHealthText then
                text = text.." ("
            end
            if profile.MissingHealthDisplay == "-Health" then
                text = text.."-"..missingHealth
            elseif profile.MissingHealthDisplay == "-% Health" then
                text = text.."-"..math.ceil((missingHealth / maxHealth) * 100).."%"
            end
            if hadHealthText then
                text = text..")"
            end
        end

        self.button:SetText(text)
        self.healthBar:SetValue(currentHealth / maxHealth)

        if profile.AlertPercent < math.ceil((currentHealth / maxHealth) * 100) and table.getn(self.afflictedDebuffTypes) == 0 then
            self.container:SetAlpha(0.4)
        end
    end
end

function HealUI:UpdatePower()
    local profile = self:GetProfile()
    local unit = self.unit
    local powerBar = self.powerBar
    local fake = self:IsFake()
    local class = fake and self.fakeClass or util.GetClass(unit)
    local currentPower
    local maxPower
    if fake then
        maxPower = math.random(100, 5000)
        if util.ClassPowerTypes[class] ~= "mana" then
            maxPower = 100
        end
        currentPower = math.random(1, maxPower)
    else
        currentPower = UnitMana(unit)
        maxPower = UnitManaMax(unit)
    end

    if class == nil then
        return
    end
    
    local powerColor = fake and util.PowerColors[util.ClassPowerTypes[class]] or util.GetPowerColor(unit)

    powerBar:SetValue(currentPower / maxPower)
    powerBar:SetStatusBarColor(powerColor[1], powerColor[2], powerColor[3])
    local text = ""
    if profile.PowerDisplay == "Power" then
        text = currentPower
    elseif profile.PowerDisplay == "Power/Max Power" then
        text = currentPower.."/"..maxPower
    elseif profile.PowerDisplay == "% Power" then
        if maxPower == 0 then
            maxPower = 1
        end
        text = math.floor((currentPower / maxPower) * 100).."%"
    end
    powerBar.text:SetText(text)
end

function HealUI:AllocateAura()
    local frame = CreateFrame("Frame", nil, self.auraPanel)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    local stackText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stackText:SetTextColor(1, 1, 1)
    return {["frame"] = frame, ["icon"] = icon, ["stackText"] = stackText}
end

-- Get an icon from the available pool. Automatically inserts into the used pool.
function HealUI:GetUnusedAura()
    local aura
    if table.getn(self.auraIconPool) > 0 then
        aura = table.remove(self.auraIconPool, table.getn(self.auraIconPool))
    else
        aura = self:AllocateAura()
    end
    table.insert(self.auraIcons, aura)
    return aura
end

function HealUI:ReleaseAuras()
    -- Release all icons back to the icon pool
    for _, aura in ipairs(self.auraIcons) do
        local frame = aura.frame
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
        frame:Hide()
        frame:ClearAllPoints()

        local icon = aura.icon
        icon:ClearAllPoints()

        local stackText = aura.stackText
        stackText:ClearAllPoints()
        stackText:SetText("")

        table.insert(self.auraIconPool, aura)
    end
    self.auraIcons = {} -- Allocating new table instead of clearing, might be a mistake?
end

function HealUI:UpdateAuras()
    local profile = self:GetProfile()
    local unit = self.unit

    self:ReleaseAuras()

    if not UnitExists(unit) then
        return
    end
    
    local xOffset = 0
    -- Track player buffs
    local buffs = {}
    local trackedBuffs = profile.TrackedBuffs
    for index = 1, 32 do
        local texturePath, stacks = UnitBuff(unit, index)
        if not texturePath then
            break
          end
        local name, type = HM.GetAuraInfo(unit, "Buff", index)
        if trackedBuffs[name] then
            table.insert(buffs, {name = name, index = index, texturePath = texturePath, stacks = stacks})
        end
    end

    table.sort(buffs, function(a, b)
        return trackedBuffs[a.name] < trackedBuffs[b.name]
    end)
    for _, buff in ipairs(buffs) do
        local aura = self:GetUnusedAura()
        self:CreateAura(aura, buff.index, buff.texturePath, buff.stacks, xOffset, "Buff")
        xOffset = xOffset + profile.TrackedAurasHeight + profile.TrackedAurasSpacing
    end

    self.afflictedDebuffTypes = {}
    xOffset = 0
    -- Track player debuffs
    local debuffs = {}
    local typedDebuffs = {} -- Dispellable debuffs
    local trackedDebuffs = profile.TrackedDebuffs
    for index = 1, 16 do
        local texturePath, stacks = UnitDebuff(unit, index)
        if not texturePath then
            break
        end
        local name, type = HM.GetAuraInfo(unit, "Debuff", index)
        if type ~= "" then
            self.afflictedDebuffTypes[type] = 1
        end
        local alreadyTracked = false
        for _, trackedType in ipairs(profile.TrackedDebuffTypes) do
            if type == trackedType then
                table.insert(typedDebuffs, {name = name, index = index, texturePath = texturePath, stacks = stacks})
                alreadyTracked = true
                break
            end
        end
        if trackedDebuffs[name] and not alreadyTracked then
            table.insert(debuffs, {name = name, index = index, texturePath = texturePath, stacks = stacks})
        end
    end

    table.sort(debuffs, function(a, b)
        return trackedDebuffs[a.name] < trackedDebuffs[b.name]
    end)
    util.AppendArrayElements(debuffs, typedDebuffs)
    for _, debuff in ipairs(debuffs) do
        local aura = self:GetUnusedAura()
        self:CreateAura(aura, debuff.index, debuff.texturePath, debuff.stacks, xOffset, "Debuff")
        xOffset = xOffset - profile.TrackedAurasHeight - profile.TrackedAurasSpacing
    end
end

function HealUI:CreateAura(aura, index, texturePath, stacks, xOffset, type)
    local profile = self:GetProfile()
    local size = profile.TrackedAurasHeight
    local unit = self.unit

    local frame = aura.frame
    frame:SetWidth(size)
    frame:SetHeight(size)
    frame:SetPoint(type == "Buff" and "TOPLEFT" or "TOPRIGHT", xOffset, 0)
    frame:Show()

    local icon = aura.icon
    icon:SetAllPoints(frame)
    icon:SetTexture(texturePath)
    --icon:SetVertexColor(1, 0, 0)
    
    frame:EnableMouse(true)
    
    -- TODO: Use SuperWoW to use buff IDs instead of textures
    frame:SetScript("OnEnter", function()
        local texture = icon:GetTexture()

        local auraFunc = type == "Buff" and UnitBuff or UnitDebuff
        local tooltipSetAuraFunc = type == "Buff" and HM.GameTooltip.SetUnitBuff or HM.GameTooltip.SetUnitDebuff
        local count = type == "Buff" and 32 or 16

        for i = 1, count do
            if texture == nil then
                break
            end
            if auraFunc(unit, i) == texture then
                HM.GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMLEFT")
                tooltipSetAuraFunc(HM.GameTooltip, unit, i)
                HM.GameTooltip:Show()
                break
            end
        end
    end)
    
    frame:SetScript("OnLeave", function()
        HM.GameTooltip:Hide()
    end)
    
    if stacks > 1 then
        local stackText = aura.stackText
        stackText:SetPoint("CENTER", frame, "CENTER", 0, 0)
        stackText:SetFont("Fonts\\FRIZQT__.TTF", math.ceil(size * (stacks < 10 and 0.75 or 0.6)))
        stackText:SetText(stacks)
    end
end

function HealUI:SetHealth(health)
    self.healthBar:SetValue(health)
end

function HealUI:Initialize()
    local unit = self.unit

    -- Container Element

    local container = CreateFrame("Frame", unit.."HealContainer", UIParent) --type, name, parent
    self.container = container
    container:SetPoint("CENTER", 0, 0)
    container:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
    container:SetBackdropColor(0, 0, 0, 0)

    -- Name Element

    local name = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.name = name
    name:SetFont("Fonts\\FRIZQT__.TTF", 12, "GameFontNormal")
    name:SetText(unit)

    -- Health Bar Element

    local healthBar = CreateFrame("StatusBar", unit.."StatusBar", container)
    self.healthBar = healthBar
    healthBar:SetFrameLevel(1)
    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    healthBar:SetMinMaxValues(0, 1)
    local origSetValue = healthBar.SetValue
    local greenToRedColors = {{1, 0, 0}, {1, 1, 0}, {0, 0.7529412, 0}}
    healthBar.SetValue = function(healthBarSelf, value)
        origSetValue(healthBarSelf, value)
        local rgb

        local profile = self:GetProfile()

        if not self:IsEnemy() then -- Do not display debuff colors for enemies
            for _, trackedDebuffType in ipairs(profile.TrackedDebuffTypes) do
                if self.afflictedDebuffTypes[trackedDebuffType] then
                    rgb = HealersMateSettings.DebuffTypeColors[trackedDebuffType]
                    break
                end
            end
        end

        local fake = self:IsFake()
        if fake then
            local trackedDebuffCount = table.getn(profile.TrackedDebuffTypes)
            if trackedDebuffCount > 0 then
                if math.random(1, 10) == 1 then
                    local fakeDebuffType = profile.TrackedDebuffTypes[math.random(trackedDebuffCount)]
                    rgb = HealersMateSettings.DebuffTypeColors[fakeDebuffType]
                end
            end
        end
        
        if rgb == nil then -- If there's no debuff color, proceed to normal colors
            if profile.HealthBarColor == "Class" then
                local _, class = UnitClass(unit)
                if class == nil then
                    class = self.fakeClass
                end
                local r, g, b = util.GetClassColor(class)
                rgb = {r, g, b}
            elseif profile.HealthBarColor == "Green" then
                rgb = {0, 0.7529412, 0}
            elseif profile.HealthBarColor == "Green To Red" then
                rgb = HMUtil.InterpolateColors(greenToRedColors, value)
            end
        end
        healthBar:SetStatusBarColor(rgb[1], rgb[2], rgb[3])
    end
    healthBar:SetValue(math.random())

    -- Create a background texture for the status bar
    local bg = healthBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetTexture(0.5, 0.5, 0.5, 0.5) -- set color to light gray with high transparency

    -- Power Bar Element

    local powerBar = CreateFrame("StatusBar", unit.."PowerStatusBar", container)
    self.powerBar = powerBar
    powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    powerBar:SetMinMaxValues(0, 1)
    powerBar:SetValue(1)
    powerBar:SetStatusBarColor(0, 0, 1)
    powerBar:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
    local powerText = powerBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    powerBar.text = powerText
    powerText:SetText("Power")
    powerText:SetFont("Fonts\\FRIZQT__.TTF", 10, "GameFontNormal")

    -- Button Element

    local button = CreateFrame("Button", unit.."Button", healthBar, "UIPanelButtonTemplate")
    self.button = button
    button:SetText("0/0")
    button:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 12, "GameFontNormal")
    button:GetFontString():ClearAllPoints()
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
    button:SetScript("OnClick", function()
        local buttonType = arg1
        HM.ClickHandler(buttonType, unit)
    end)
    button:SetScript("OnEnter", function()
        HM.ApplySpellsTooltip(button, unit)
    end)
    button:SetScript("OnLeave", HM.HideSpellsTooltip)
    button:EnableMouse(true)

    button:SetNormalTexture(nil)
    button:SetHighlightTexture(nil)
    button:SetPushedTexture(nil)

    -- Buff Panel Element

    local buffPanel = CreateFrame("Frame", unit.."BuffPanel", container)
    self.auraPanel = buffPanel

    local scrollingDamageFrame = CreateFrame("Frame", unit.."ScrollingDamageFrame", container)
    self.scrollingDamageFrame = scrollingDamageFrame
    scrollingDamageFrame:SetWidth(100) -- width
    scrollingDamageFrame:SetHeight(20) -- height
    scrollingDamageFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
    scrollingDamageFrame.text = scrollingDamageFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    scrollingDamageFrame.text:SetPoint("CENTER", 0, 0)
    scrollingDamageFrame:Hide() -- Hide the frame initially
    scrollingDamageFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top

    local scrollingHealFrame = CreateFrame("Frame", unit.."ScrollingHealFrame", container)
    self.scrollingHealFrame = scrollingHealFrame
    scrollingHealFrame:SetWidth(100) -- width
    scrollingHealFrame:SetHeight(20) -- height
    scrollingHealFrame:SetPoint("CENTER", 0, 0) -- Adjust the initial position as needed
    scrollingHealFrame.text = scrollingHealFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    scrollingHealFrame.text:SetPoint("CENTER", 0, 0)
    scrollingHealFrame:Hide() -- Hide the frame initially
    scrollingHealFrame:SetFrameLevel(100) -- Set the frame level to a high value to ensure it's on top

    self:SizeElements()
end

function HealUI:SizeElements()

    local profile = self:GetProfile()
    local width = profile.Width
    local healthBarHeight = profile.HealthBarHeight
    local powerBarHeight = profile.PowerBarHeight

    local nameTextProps = profile.NameText
    local healthTextProps = profile.HealthText
    local powerTextProps = profile.PowerText

    local container = self.container
    container:SetWidth(width)

    local healthBar = self.healthBar
    healthBar:SetWidth(width)
    healthBar:SetHeight(healthBarHeight)

    local healthBarPaddingTop = 0
    if not profile.NameInHealthBar then
        healthBarPaddingTop = nameTextProps.FontSize * 1.25
    end
    healthBar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -healthBarPaddingTop)

    local name = self.name
    local nameOffsetY = nameTextProps:GetPaddingV() + nameTextProps.OffsetY
    name:SetWidth(width)
    name:SetHeight(healthBar:GetHeight())
    if not profile.NameInHealthBar then
        local height = nameTextProps.FontSize * 1.25
        nameOffsetY = nameOffsetY + height
        name:SetHeight(height)
    end
    name:SetFont("Fonts\\FRIZQT__.TTF", nameTextProps.FontSize, "GameFontNormal")
    name:SetJustifyH(nameTextProps.AlignmentH)
    name:SetJustifyV(nameTextProps.AlignmentV)
    -- TODO: Change anchoring based on whether the name is in the health bar or not
    name:SetPoint("TOP", healthBar, "TOP", nameTextProps:GetPaddingH() + nameTextProps.OffsetX, nameOffsetY)

    local powerBar = self.powerBar
    powerBar:SetWidth(width)
    powerBar:SetHeight(powerBarHeight)
    powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, 0)

    local powerText = powerBar.text
    powerText:SetWidth(width)
    powerText:SetHeight(powerBar:GetHeight())
    powerText:SetFont("Fonts\\FRIZQT__.TTF", powerTextProps.FontSize, "GameFontNormal")
    powerText:SetJustifyH(powerTextProps.AlignmentH)
    powerText:SetJustifyV(powerTextProps.AlignmentV)
    powerText:SetPoint("TOP", powerBar, "TOP", powerTextProps:GetPaddingH() + powerTextProps.OffsetX, 
        powerTextProps:GetPaddingV() + powerTextProps.OffsetY)

    local button = self.button
    button:SetWidth(healthBar:GetWidth())
    button:SetHeight(healthBar:GetHeight() + powerBar:GetHeight())
    local buttonText = button:GetFontString()
    buttonText:SetWidth(width)
    buttonText:SetHeight(healthBar:GetHeight())
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", healthTextProps.FontSize, "GameFontNormal")
    buttonText:SetJustifyH(healthTextProps.AlignmentH)
    buttonText:SetJustifyV(healthTextProps.AlignmentV)
    buttonText:SetPoint("TOP", healthBar, "TOP", healthTextProps:GetPaddingH() + healthTextProps.OffsetX, 
        healthTextProps:GetPaddingV() + healthTextProps.OffsetY)
    --buttonText:SetPoint("TOP", healthTextXOffsets[healthTextAlignment], (buttonText:GetHeight() / 2) - (healthBar:GetHeight() / 2))
    button:SetPoint("TOP", 0, 0)

    local auraPanel = self.auraPanel
    auraPanel:SetWidth(width)
    auraPanel:SetHeight(profile.TrackedAurasHeight)
    auraPanel:SetPoint("TOPLEFT", powerBar, "BOTTOMLEFT", 0, 0)

    container:SetHeight(self:GetHeight())
end

function HealUI:GetWidth()
    return self:GetProfile().Width
end

function HealUI:GetHeight()
    return self:GetProfile():GetHeight()
end

function HealUI:IsEnemy()
    return UnitCanAttack("player", self.unit)
end

function HealUI:IsFake()
    return HealersMate.TestUI and not UnitExists(self.unit)
end

function HealUI:GetProfile()
    return self.owningGroup:GetProfile()
end