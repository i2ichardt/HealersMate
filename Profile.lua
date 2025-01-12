HMUIProfile = {}

-- The base template for profile creation
local DEFAULT_PROFILE_VALUES = {}

local HM
local util

function HMUIProfile:New(base)
    HM = HealersMate -- Need to do this in the constructor or else it doesn't exist yet
    util = HMUtil
    local obj = util.CloneTable(base or DEFAULT_PROFILE_VALUES, true)
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function HMUIProfile.CreatePositionedObject()
    local obj = {}
    obj.AlignmentH = "CENTER" -- LEFT, CENTER, RIGHT
    obj.AlignmentV = "CENTER" -- TOP, CENTER, BOTTOM
    obj.PaddingH = 4
    obj.PaddingV = 4
    obj.OffsetX = 0
    obj.OffsetY = 0
    obj.Anchor = "Health Bar" -- Health Bar, Power Bar, Button, Container
    obj.Opacity = 100
    obj.GetWidth = function(self, ui)
        return (self.Width ~= "Anchor" and self.Width or self:GetAnchorComponent(ui):GetWidth()) + (self.Width2 or 0)
    end
    obj.GetHeight = function(self, ui)
        return (self.Height ~= "Anchor" and self.Height or self:GetAnchorComponent(ui):GetHeight()) + (self.Height2 or 0)
    end
    obj.GetOffsetX = function(self)
        if self.AlignmentH == "LEFT" then
            return self.PaddingH + self.OffsetX
        elseif self.AlignmentH == "RIGHT" then
            return -self.PaddingH + self.OffsetX
        end
        return self.OffsetX
    end
    obj.GetOffsetY = function(self)
        if self.AlignmentV == "TOP" then
            return -self.PaddingV + self.OffsetY
        elseif self.AlignmentV == "BOTTOM" then
            return self.PaddingV + self.OffsetY
        end
        return self.OffsetY
    end
    obj.GetAlpha = function(self)
        return self.Opacity / 100
    end
    obj.GetAnchorComponent = function(self, ui)
        local anchorName = self.Anchor
        if anchorName == "Health Bar" then
            return ui.healthBar
        elseif anchorName == "Power Bar" then
            return ui.powerBar
        elseif anchorName == "Button" then
            return ui.button
        elseif anchorName == "Container" then
            return ui.container
        end
    end
    obj.ApplyPredefined = function(self, predefined)
        if predefined then
            for key, value in pairs(predefined) do
                self[key] = value
            end
        end
    end
    return obj
end

function HMUIProfile.CreateSizedObject(predefined)
    local obj = HMUIProfile.CreatePositionedObject()
    obj.Width = 24
    obj.Height = 24
    obj:ApplyPredefined(predefined)
    return obj
end

function HMUIProfile.CreateTextObject(predefined)
    local obj = HMUIProfile.CreatePositionedObject()
    obj.FontSize = 12
    obj.MaxWidth = 1000
    obj:ApplyPredefined(predefined)
    return obj
end

function HMUIProfile:GetHeight()
    local totalHeight = self.HealthBarHeight + self.PowerBarHeight + self.PaddingTop + self.PaddingBottom
    return totalHeight
end

function HMUIProfile.SetDefaults()
    local createTextObject = HMUIProfile.CreateTextObject
    local createSizedObject = HMUIProfile.CreateSizedObject

    local profile = DEFAULT_PROFILE_VALUES

    profile.Width = 150

    profile.BarsOffsetY = 0

    profile.PaddingTop = 0
    profile.PaddingBottom = 20

    profile.HealthBarHeight = 24
    profile.HealthBarColor = "Green To Red" -- "Class", "Green", "Green To Red"
    profile.EnemyHealthBarColor = "Green"
    profile.HealthBarStyle = "HealersMate" -- "Blizzard", "Blizzard Raid", "HealersMate"

    profile.HealthDisplay = "Health" -- "Health", "Health/Max Health", "% Health", "Hidden"
    profile.MissingHealthDisplay = "-Health" -- "Hidden", "-Health", "-% Health"
    profile.AlwaysShowMissingHealth = false
    profile.ShowEnemyMissingHealth = false
    profile.MissingHealthInline = false
    profile.HealthTexts = {}
    profile.HealthTexts.Normal = createTextObject({
        ["FontSize"] = 12,
        ["AlignmentV"] = "CENTER",
        ["AlignmentH"] = "RIGHT"
    })
    -- Only used when MissingHealthInline is false
    profile.HealthTexts.WithMissing = createTextObject({
        ["FontSize"] = 11,
        ["AlignmentV"] = "TOP",
        ["AlignmentH"] = "RIGHT",
        ["PaddingV"] = 0
    })
    -- Only used when MissingHealthInline is false
    profile.HealthTexts.Missing = createTextObject({
        ["FontSize"] = 13,
        ["AlignmentV"] = "BOTTOM",
        ["AlignmentH"] = "RIGHT",
        ["PaddingV"] = 0,
        ["Color"] = {1, 0.4, 0.4}
    })

    profile.IncomingHealDisplay = "Hidden" -- "Overheal", "Heal", "Hidden"
    profile.IncomingHealText = createTextObject({
        ["FontSize"] = 9,
        ["AlignmentV"] = "BOTTOM",
        ["AlignmentH"] = "RIGHT",
        ["Anchor"] = "Health Bar",
        ["Color"] = {0.5, 1, 0.5},
        ["IndirectColor"] = {0.3, 0.8, 0.3},
        ["Outline"] = true
    })

    profile.AlertPercent = 100
    profile.NotAlertedOpacity = 60

    profile.PowerBarHeight = 10
    profile.PowerBarStyle = "HealersMate Borderless" -- "Blizzard", "Blizzard Raid"
    profile.PowerText = createTextObject({
        ["FontSize"] = 10,
        ["AlignmentH"] = "RIGHT",
        ["Anchor"] = "Power Bar"
    })
    profile.PowerDisplay = "Power" -- "Power", "Power/Max Power", "% Power", "Hidden"

    profile.NameText = createTextObject({
        ["FontSize"] = 12,
        ["AlignmentH"] = "LEFT",
        ["Color"] = "Class",
        ["MaxWidth"] = 105
    })
    profile.NameDisplay = "Name" -- Unimplemented
    -- "Name", "Name (Class)"

    profile.OutOfRangeOpacity = 50
    profile.RangeText = createTextObject({
        ["FontSize"] = 9,
        ["AlignmentV"] = "TOP",
        ["PaddingV"] = 0
    })
    profile.LineOfSightIcon = createSizedObject({
        ["Width"] = 24,
        ["Height"] = 24,
        ["AlignmentH"] = "CENTER",
        ["AlignmentV"] = "CENTER",
        ["Anchor"] = "Button",
        ["Opacity"] = 80
    })

    profile.RoleIcon = createSizedObject({
        ["Width"] = 14,
        ["Height"] = 14,
        ["AlignmentH"] = "LEFT",
        ["AlignmentV"] = "TOP",
        ["PaddingH"] = 1,
        ["PaddingV"] = 1,
        ["Anchor"] = "Container",
        ["Opacity"] = 100
    })

    profile.RaidMarkIcon = createSizedObject({
        ["Width"] = 12,
        ["Height"] = 12,
        ["AlignmentH"] = "RIGHT",
        ["AlignmentV"] = "TOP",
        ["PaddingH"] = 1,
        ["PaddingV"] = 1,
        ["Anchor"] = "Container",
        ["Opacity"] = 100
    })

    profile.TrackAuras = true
    profile.AuraTracker = createSizedObject({
        ["Height"] = 20,
        ["Width"] = "Anchor",
        ["AlignmentH"] = "CENTER",
        ["AlignmentV"] = "BOTTOM",
        ["PaddingH"] = 0,
        ["PaddingV"] = 0,
        ["Anchor"] = "Container"
    })
    profile.TrackedAurasSpacing = 2
    profile.TrackedAurasAlignment = "TOP"

    profile.TargetOutline = createSizedObject({
        ["Height"] = "Anchor",
        ["Width"] = "Anchor",
        ["Height2"] = 2,
        ["Width2"] = 2,
        ["Anchor"] = "Button",
        ["Thickness"] = 2
    })

    profile.Flash = createSizedObject({
        ["Height"] = "Anchor",
        ["Width"] = "Anchor",
        ["Anchor"] = "Health Bar"
    })
    profile.FlashThreshold = 25
    profile.FlashOpacity = 70

    profile.MaxUnitsInAxis = 5
    profile.Orientation = "Vertical" --"Vertical", "Horizontal"
    profile.HorizontalSpacing = 1
    profile.VerticalSpacing = 0

    profile.SortUnitsBy = "ID" -- "ID", "Name", "Class Name"
    profile.SplitRaidIntoGroups = true

    profile.BorderStyle = "Tooltip" -- "Tooltip", "Dialog Box", "Borderless"
end