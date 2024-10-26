HMProfileManager = {}

HMDefaultProfiles = {}

HMUserProfiles = {}

local _G = getfenv(0)
setmetatable(HMProfileManager, {__index = getfenv(1)})
setfenv(1, HMProfileManager)

local util = getglobal("HMUtil")

function GetProfile(name)
    return HMDefaultProfiles[name]
end

function InitializeDefaultProfiles()
    HMUIProfile.SetDefaults()

    -- Master default profile
    HMDefaultProfiles["Default"] = HMUIProfile:New()

    -- Small profile
    do
        local profile = HMUIProfile:New(GetProfile("Default"))
        HMDefaultProfiles["Small Default"] = profile

        profile.Width = 120
        profile.HealthBarHeight = 16
        profile.PowerBarHeight = 8
        profile.TrackedAurasHeight = 16
        profile.NameText.FontSize = 10
        local healthTexts = profile.HealthTexts
        healthTexts.Normal.FontSize = 10
        healthTexts.WithMissing.FontSize = 8
        healthTexts.Missing.FontSize = 9
        profile.PowerText.FontSize = 8
    end

    -- Compact profile
    do
        local profile = HMUIProfile:New(GetProfile("Default"))
        HMDefaultProfiles["Compact Default"] = profile

        profile.Width = 67
        profile.HealthBarHeight = 28
        profile.HealthBarColor = "Class"
        profile.NameText.FontSize = 12
        profile.NameText.AlignmentH = "CENTER"
        profile.NameText.AlignmentV = "TOP"
        profile.NameText.PaddingV = 1
        profile.NameText.Color = {0.95, 0.95, 0.95}
        profile.PowerBarHeight = 6
        profile.TrackedAurasHeight = 8
        local healthTexts = profile.HealthTexts
        healthTexts.Normal.FontSize = 9
        healthTexts.Normal.AlignmentH = "CENTER"
        healthTexts.Normal.AlignmentV = "BOTTOM"
        healthTexts.Normal.PaddingV = 1
        healthTexts.WithMissing.FontSize = 9
        healthTexts.WithMissing.AlignmentH = "LEFT"
        healthTexts.WithMissing.AlignmentV = "BOTTOM"
        healthTexts.WithMissing.PaddingV = 1
        healthTexts.Missing.FontSize = 9
        healthTexts.Missing.AlignmentH = "RIGHT"
        healthTexts.Missing.AlignmentV = "BOTTOM"
        healthTexts.Missing.PaddingV = 1


        profile.RangeText.AlignmentV = "CENTER"
        profile.RangeText.FontSize = 7
        profile.LineOfSightIcon.Width = 20
        profile.LineOfSightIcon.Height = 20
        profile.LineOfSightIcon.Opacity = 70
        profile.HealthDisplay = "Health"
        profile.MissingHealthDisplay = "-Health"
        profile.PowerDisplay = "Hidden"
        profile.PowerText.FontSize = 8
        profile.Orientation = "Vertical"
        profile.SplitRaidIntoGroups = true
        profile.SortUnitsBy = "ID"
        profile.AlertPercent = 100
        profile.MaxUnitsInAxis = 5
    end

    -- Legacy profile - Meant to look as close as possible to HealersMate 1.3.0
    do
        local profile = HMUIProfile:New(GetProfile("Party Default"))
        HMDefaultProfiles["Legacy"] = profile

        profile.Width = 200

        profile.BarsOffsetY = 20

        profile.MissingHealthInline = true
        profile.HealthBarHeight = 25
        profile.HealthBarStyle = "Blizzard"
        profile.PowerBarHeight = 5

        profile.NameText.AlignmentH = "LEFT"
        profile.NameText.AlignmentV = "TOP"
        profile.NameText.Anchor = "Container"
        local healthTexts = profile.HealthTexts
        healthTexts.Normal.AlignmentH = "CENTER"
        profile.HealthDisplay = "Health/Max Health"
        profile.PowerDisplay = "Hidden"

        profile.BorderStyle = "Hidden"
    end

    HMDefaultProfiles["Party"] = HMUIProfile:New(GetProfile("Default"))
    HMDefaultProfiles["Pets"] = HMUIProfile:New(GetProfile("Small Default"))
    HMDefaultProfiles["Raid"] = HMUIProfile:New(GetProfile("Compact Default"))
    HMDefaultProfiles["Raid Pets"] = HMUIProfile:New(GetProfile("Compact Default"))
    HMDefaultProfiles["Target"] = HMUIProfile:New(GetProfile("Default"))
end