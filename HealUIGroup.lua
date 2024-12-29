HMUnitFrameGroup = {}

HMUnitFrameGroup.name = "???"

HMUnitFrameGroup.profile = nil

HMUnitFrameGroup.container = nil
HMUnitFrameGroup.borderFrame = nil
HMUnitFrameGroup.header = nil
HMUnitFrameGroup.label = nil
HMUnitFrameGroup.uis = nil
HMUnitFrameGroup.units = nil

HMUnitFrameGroup.petGroup = false
HMUnitFrameGroup.environment = "all" -- party, raid, or all

HMUnitFrameGroup.moveContainer = CreateFrame("Frame", "HMUnitFrameGroupBulkMoveContainer", UIParent)
HMUnitFrameGroup.moveContainer:EnableMouse(true)
HMUnitFrameGroup.moveContainer:SetMovable(true)

-- Singleton references, assigned in constructor
local HM
local util

function HMUnitFrameGroup:New(name, environment, units, petGroup, profile)
    HM = HealersMate -- Need to do this in the constructor or else it doesn't exist yet
    util = HMUtil
    local obj = {name = name, environment = environment, uis = {}, units = units, petGroup = petGroup, profile = profile}
    setmetatable(obj, self)
    self.__index = self
    obj:Initialize()
    return obj
end

function HMUnitFrameGroup:ShowCondition()
    if HMOptions.Hidden then
        return false
    end

    for _, ui in pairs(self.uis) do
        if ui:IsShown() then
            return true
        end
    end
    return false
 end

function HMUnitFrameGroup:AddUI(ui, noUpdate)
    self.uis[ui:GetUnit()] = ui
    ui:SetOwningGroup(self)
    if not noUpdate then
        self:UpdateUIPositions()
    end
end

function HMUnitFrameGroup:GetContainer()
    return self.container
end

function HMUnitFrameGroup:ResetFrameLevel()
    self.container:SetFrameLevel(0)
    self.borderFrame:SetFrameLevel(1)
end

function HMUnitFrameGroup:GetEnvironment()
    return self.environment
end

function HMUnitFrameGroup:CanShowInEnvironment(environment)
    return self.environment == "all" or self.environment == environment
end

function HMUnitFrameGroup:Show()
    self.container:Show()
    for _, ui in pairs(self.uis) do
        ui:UpdateAll()
    end
end

function HMUnitFrameGroup:Hide()
    self.container:Hide()
end

function HMUnitFrameGroup:Initialize()
    local container = CreateFrame("Frame", self.name.."HMUnitFrameGroupContainer", UIParent) --type, name, parent
    self.container = container
    container:SetToplevel(true)
    if container:GetNumPoints() == 0 then
        container:SetPoint(util.GetCenterScreenPoint(0, 0))
    end
    container:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}) -- set a light gray background
    container:SetBackdropColor(0, 0, 0, 0.5)
    container:EnableMouse(true)
    container:SetMovable(true)

    container:SetScript("OnMouseDown", function()
        local button = arg1

        if button ~= "LeftButton" or container.isMoving then
            return
        end

        container.isMoving = true

        if (util.GetKeyModifier() == HMOptions.FrameDrag.AltMoveKey) == HMOptions.FrameDrag.MoveAll then
            container:StartMoving()
            return
        end

        container.bulkMovement = true

        local moveContainer = HMUnitFrameGroup.moveContainer
        moveContainer:ClearAllPoints()
        moveContainer:SetPoint("TOPLEFT", 0, 0)
        -- If the container doesn't have a size, it doesn't move
        moveContainer:SetWidth(1)
        moveContainer:SetHeight(1)
        for _, group in pairs(HealersMate.UnitFrameGroups) do
            local gc = group:GetContainer()
            local point, relativeTo, relativePoint, xofs, yofs = gc:GetPoint(1)
            gc:ClearAllPoints()
            gc:SetPoint("TOPLEFT", moveContainer, relativePoint, xofs, yofs)
        end
        moveContainer:StartMoving()
    end)

    container:SetScript("OnMouseUp", function()
        local button = arg1

        if (button ~= "LeftButton" or not container.isMoving) then
            return
        end

        container.isMoving = false

        if not container.bulkMovement then
            container:StopMovingOrSizing()
            return
        end

        container.bulkMovement = false

        local moveContainer = HMUnitFrameGroup.moveContainer
        moveContainer:StopMovingOrSizing()
        for _, group in pairs(HealersMate.UnitFrameGroups) do
            local gc = group:GetContainer()
            local mcpoint, mcrelativeTo, mcrelativePoint, mcxofs, mcyofs = moveContainer:GetPoint(1)
            local point, relativeTo, relativePoint, xofs, yofs = gc:GetPoint(1)
            gc:ClearAllPoints()
            gc:SetPoint("TOPLEFT", UIParent, mcrelativePoint, mcxofs + xofs, mcyofs + yofs)
        end
        -- Prevent container from potentially blocking mouse by setting it back to 0 size
        moveContainer:SetWidth(0)
        moveContainer:SetHeight(0)
    end)

    container:SetScript("OnHide", function()
        if not container.isMoving then
            return
        end
        local prevArg = arg1
        arg1 = "LeftButton"
        container:GetScript("OnMouseUp")()
        arg1 = prevArg
    end)

    local header = CreateFrame("Frame", self.name.."HMUnitFrameGroupContainerHeader", container) --type, name, parent
    self.header = header
    header:SetPoint("TOPLEFT", container, 0, 0)
    header:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
    header:SetBackdropColor(0, 0, 0, 0.5)

    local borderFrame = CreateFrame("Frame", self.name.."HMUnitFrameGroupContainerBorder", container)
    self.borderFrame = borderFrame
    borderFrame:SetPoint("CENTER", container, 0, 0)

    local label = header:CreateFontString(header, "OVERLAY", "GameFontNormal")
    self.label = label
    label:SetPoint("CENTER", header, "CENTER", 0, 0)
    label:SetText(self.name)

    self:ApplyProfile()

    self:UpdateUIPositions()
end

function HMUnitFrameGroup:ApplyProfile()
    local profile = self:GetProfile()
    
    local borderFrame = self.borderFrame
    if profile.BorderStyle == "Tooltip" then
        borderFrame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 17, 
            tile = true, tileSize = 17})
    elseif profile.BorderStyle == "Dialog Box" then
        borderFrame:SetBackdrop({edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24, 
            tile = true, tileSize = 24})
    else
        borderFrame:SetBackdrop({})
    end
end

function HMUnitFrameGroup:UpdateUIPositions()
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

    local xSpacing = profile.HorizontalSpacing
    local ySpacing = profile.VerticalSpacing
    for columnIndex, column in ipairs(splitSortedUIs) do
        for i, ui in ipairs(column) do -- Column is guaranteed to be less than max units
            local container = ui:GetRootContainer()
            local x = orientation == "Vertical" and ((profileWidth + xSpacing) * (columnIndex - 1)) or ((profileWidth + xSpacing) * (i - 1))
            local y = orientation == "Vertical" and ((profileHeight + ySpacing) * (i - 1)) or ((profileHeight + ySpacing) * (columnIndex - 1))
            container:SetPoint("TOPLEFT", self.container, "TOPLEFT", x, -y - 20)
        end
    end

    local largestRow = table.getn(splitSortedUIs)

    local width = orientation == "Vertical" and (profileWidth * largestRow + (xSpacing * (largestRow - 1))) or (profileWidth * largestColumn + (xSpacing * (largestColumn - 1)))
    local height = orientation == "Vertical" and (profileHeight * largestColumn + (ySpacing * (largestColumn - 1))) or (profileHeight * largestRow + (ySpacing * (largestRow - 1)))
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
function HMUnitFrameGroup:GetSortedUIs()
    local profile = self:GetProfile()
    local uis = self.uis
    local groups = {}
    
    if self.environment == "raid" and profile.SplitRaidIntoGroups and not self.petGroup then
        local foundRaidNumbers = {} -- Used for testing UI
        for i = 1, 8 do
            groups[i] = {}
            local group = groups[i]
            if RAID_SUBGROUP_LISTS and RAID_SUBGROUP_LISTS[i] then
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
                    if not RAID_SUBGROUP_LISTS[i] or not RAID_SUBGROUP_LISTS[i][frameNumber] then
                        table.insert(group, uis["raid"..table.remove(unoccupied, table.getn(unoccupied))])
                    end
                end
            end
        end
    else
        groups[1] = {}
        local group = groups[1]
        for _, ui in pairs(uis) do
            if ui:IsShown() then
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
                    local aName = UnitName(a:GetUnit()) or a.fakeStats.name or a:GetUnit()
                    local bName = UnitName(b:GetUnit()) or b.fakeStats.name or b:GetUnit()
                    return aName < bName
                end)
                table.insert(sortedGroups, group)
            end
        end
    elseif profile.SortUnitsBy == "Class Name" then
        for groupNumber, group in ipairs(groups) do
            if table.getn(group) > 0 then
                table.sort(group, function(a, b)
                    local aName = util.GetClass(a:GetUnit()) or a.fakeStats.class
                    local bName = util.GetClass(b:GetUnit()) or b.fakeStats.class
                    return aName < bName
                end)
                table.insert(sortedGroups, group)
            end
        end
    end
    for _, group in ipairs(sortedGroups) do
        local rolePriority = {
            ["Tank"] = 1,
            ["Healer"] = 2,
            ["Damage"] = 3
        }
        local groupCopy = util.CloneTable(group)
        local roleSorter = function(a, b)
            if not a or not b then
                return false
            end
            local aRank = ((rolePriority[a:GetRole()] or 4) * 100) + util.IndexOf(groupCopy, a)
            local bRank = ((rolePriority[b:GetRole()] or 4) * 100) + util.IndexOf(groupCopy, b)
            return aRank < bRank
        end
        table.sort(group, roleSorter)
        for _, ui in ipairs(group) do
            ui:UpdateRole()
        end
    end
    return sortedGroups
end

function HMUnitFrameGroup:GetProfile()
    return self.profile
end