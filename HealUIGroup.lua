HealUIGroup = {}

HealUIGroup.name = "???"

HealUIGroup.container = nil
HealUIGroup.borderFrame = nil
HealUIGroup.header = nil
HealUIGroup.label = nil
HealUIGroup.uis = nil
HealUIGroup.units = nil

HealUIGroup.petGroup = false
HealUIGroup.environment = "all" -- party, raid, or all

-- Singleton references, assigned in constructor
local HM
local util

function HealUIGroup:New(name, environment, units, petGroup)
    local obj = {name = name, environment = environment, uis = {}, units = units, petGroup = petGroup}
    setmetatable(obj, self)
    self.__index = self
    HM = HealersMate -- Need to do this in the constructor or else it doesn't exist yet
    util = HMUtil
    obj:Initialize()
    return obj
end

function HealUIGroup:ShowCondition()
    for _, ui in pairs(self.uis) do
        if ui:GetContainer():IsShown() then
            return true
        end
    end
    return false
 end

function HealUIGroup:AddUI(ui)
    self.uis[ui:GetUnit()] = ui
    ui:SetOwningGroup(self)
    self:UpdateUIPositions()
end

function HealUIGroup:GetContainer()
    return self.container
end

function HealUIGroup:GetEnvironment()
    return self.environment
end

function HealUIGroup:CanShowInEnvironment(environment)
    return self.environment == "all" or self.environment == environment
end

function HealUIGroup:Show()
    self.container:Show()
    for _, ui in pairs(self.uis) do
        ui:UpdateAll()
    end
end

function HealUIGroup:Hide()
    self.container:Hide()
end

function HealUIGroup:Initialize()
    local container = CreateFrame("Frame", self.name.."HealUIGroupContainer", UIParent) --type, name, parent
    self.container = container
    container:SetToplevel(true)
    container:SetPoint("CENTER", 0, 0) -- position it at the center of the screen
    container:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
    container:SetBackdropColor(0, 0, 0, 0.5)
    container:EnableMouse(true)
    container:SetMovable(true)

    container:SetScript("OnMouseDown", function()
        local button = arg1
        if button == "LeftButton" and not container.isMoving then
            container:StartMoving()
            container.isMoving = true
        end
    end)

    container:SetScript("OnMouseUp", function()
        local button = arg1
        if button == "LeftButton" and container.isMoving then
            container:StopMovingOrSizing()
            container.isMoving = false
        end
    end)

    local header = CreateFrame("Frame", self.name.."HealUIGroupContainerHeader", container) --type, name, parent
    self.header = header
    header:SetPoint("TOPLEFT", container, 0, 0)
    header:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
    header:SetBackdropColor(0, 0, 0, 0.5)

    local borderFrame = CreateFrame("Frame", self.name.."HealUIGroupContainerBorder", container)
    self.borderFrame = borderFrame
    borderFrame:SetPoint("CENTER", container, 0, 0)

    local label = header:CreateFontString(header, "OVERLAY", "GameFontNormal")
    self.label = label
    label:SetPoint("CENTER", header, "CENTER", 0, 0)
    label:SetText(self.name)

    self:ApplyProfile()

    self:UpdateUIPositions()
end

function HealUIGroup:ApplyProfile()
    local profile = self:GetProfile()
    
    local borderFrame = self.borderFrame
    if profile.BorderStyle == "Tooltip" then
        borderFrame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, 
            insets = { left = 6, right = 6, top = 6, bottom = 6 }, tile = true, tileSize = 16})
    elseif profile.BorderStyle == "Dialog Box" then
        borderFrame:SetBackdrop({edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24, 
            insets = { left = 8, right = 8, top = 8, bottom = 8 }, tile = true, tileSize = 24})
    else
        borderFrame:SetBackdrop({})
    end
end

function HealUIGroup:UpdateUIPositions()
    local profile = self:GetProfile()
    local profileWidth = profile.Width
    local profileHeight = profile:GetHeight()
    local maxUnitsInAxis = profile.MaxUnitsInAxis
    local orientation = profile.Orientation

    local sortedUIs = self:GetSortedUIs()
    local splitSortedUIs = {}
    for _, group in ipairs(sortedUIs) do
        local currentTable = {}
        local unitsUntilShift = maxUnitsInAxis
        for _, ui in ipairs(group) do
            if unitsUntilShift == 0 then
                table.insert(splitSortedUIs, currentTable)
                currentTable = {}
                unitsUntilShift = maxUnitsInAxis
            end
            table.insert(currentTable, ui)
            unitsUntilShift = unitsUntilShift - 1
        end
        if table.getn(currentTable) > 0 then
            table.insert(splitSortedUIs, currentTable)
        end
    end

    -- IMPORTANT: "Column" does not necessarily mean vertical!
    local largestColumn = 0
    for _, column in ipairs(splitSortedUIs) do
        largestColumn = math.max(largestColumn, table.getn(column))
    end

    
    for columnIndex, column in ipairs(splitSortedUIs) do
        
        for i, ui in ipairs(column) do -- Column is guaranteed to be less than max units
            local container = ui:GetContainer()
            local x = orientation == "Vertical" and (profileWidth * (columnIndex - 1)) or (profileWidth * (i - 1))
            local y = orientation == "Vertical" and (profileHeight * (i - 1)) or (profileHeight * (columnIndex - 1))
            container:SetPoint("TOPLEFT", self.container, "TOPLEFT", x, -y - 20)
        end
    end

    local width = orientation == "Vertical" and (profileWidth * table.getn(splitSortedUIs)) or (profileWidth * largestColumn)
    local height = orientation == "Vertical" and (profileHeight * largestColumn) or (profileHeight * table.getn(splitSortedUIs))
    height = height + 20
    self.container:SetWidth(width)
    self.container:SetHeight(height)

    local header = self.header
    header:SetWidth(width)
    header:SetHeight(20)

    local borderPadding = 0
    if profile.BorderStyle == "Tooltip" then
        borderPadding = 10
    elseif profile.BorderStyle == "Dialog Box" then
        borderPadding = 18
    end
    self.borderFrame:SetWidth(width + borderPadding)
    self.borderFrame:SetHeight(height + borderPadding)

    local label = self.label
    label:SetPoint("CENTER", header, "CENTER", 0, 0)
end

-- Returns an array with the index being the group number, and the value being an array of units
function HealUIGroup:GetSortedUIs()
    local profile = self:GetProfile()
    local uis = self.uis
    local groups = {}
    
    if self.environment == "raid" and profile.SplitRaidIntoGroups and not self.petGroup then
        local foundRaidNumbers = {} -- Used for testing UI
        for i = 1, 8 do
            groups[i] = {}
            local group = groups[i]
            if RAID_SUBGROUP_LISTS then
                for frameNumber, raidNumber in pairs(RAID_SUBGROUP_LISTS[i]) do
                    table.insert(group, uis["raid"..raidNumber]) -- Effectively sorts raid members by ID at this point
                    foundRaidNumbers[raidNumber] = 1
                end
            end
        end
        -- If testing, fill empty slots with fake players
        if HealersMate.TestUI and RAID_SUBGROUP_LISTS then
            local unoccupied = {}
            for i = 1, 40 do
                if not foundRaidNumbers[i] then
                    table.insert(unoccupied, i)
                end
            end
            for i = 1, 8 do
                local group = groups[i]
                for frameNumber = 1, 5 do
                    if not RAID_SUBGROUP_LISTS[i][frameNumber] then
                        table.insert(group, uis["raid"..table.remove(unoccupied, table.getn(unoccupied))])
                    end
                end
            end
        end
    else
        groups[1] = {}
        local group = groups[1]
        for _, ui in pairs(uis) do
            if ui:GetContainer():IsShown() then
                table.insert(group, ui)
            end
        end
    end

    local sortedGroups = {}
    if profile.SortUnitsBy == "ID" then
        for groupNumber, group in ipairs(groups) do
            if table.getn(group) > 0 then
                local groupSet = {} -- Convert group UI array to a set with the key as the Unit ID
                for _, ui in ipairs(group) do
                    groupSet[ui:GetUnit()] = ui
                end
                if self.environment == "raid" then
                    if not self.petGroup then -- Should already be sorted if we're not dealing with the pets
                        table.insert(sortedGroups, group)
                    else -- Pets need to be sorted manually
                        local sortedGroup = {}
                        for _, unit in ipairs(self.units) do -- Iterate through all unit IDs this UI group can handle, in order
                            if groupSet[unit] then
                                table.insert(sortedGroup, groupSet[unit])
                            end
                        end
                        table.insert(sortedGroups, sortedGroup)
                    end
                else
                    local sortedGroup = {}
                    for _, unit in ipairs(self.units) do -- Iterate through all unit IDs this UI group can handle, in order
                        if groupSet[unit] then
                            table.insert(sortedGroup, groupSet[unit])
                        end
                    end
                    table.insert(sortedGroups, sortedGroup)
                end
            end
        end
    elseif profile.SortUnitsBy == "Name" then
        for groupNumber, group in ipairs(groups) do
            if table.getn(group) > 0 then
                table.sort(group, function(a, b)
                    local aName = UnitName(a:GetUnit()) or a:GetUnit()
                    local bName = UnitName(b:GetUnit()) or b:GetUnit()
                    return aName < bName
                end)
                table.insert(sortedGroups, group)
            end
        end
    elseif profile.SortUnitsBy == "Class Name" then
        for groupNumber, group in ipairs(groups) do
            if table.getn(group) > 0 then
                table.sort(group, function(a, b)
                    local aName = HM.GetClass(a:GetUnit()) or a.testClass
                    local bName = HM.GetClass(b:GetUnit()) or b.testClass
                    return aName < bName
                end)
                table.insert(sortedGroups, group)
            end
        end
    end
    return sortedGroups
end

function HealUIGroup:GetProfile()
    return HealersMateSettings.Profiles[self.name]
end