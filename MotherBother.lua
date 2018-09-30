MB = LibStub("AceAddon-3.0"):NewAddon("MB", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local Sticky = LibStub("LibSimpleSticky-1.0")

function MB:OnInitialize()
    MB:RegisterChatCommand("MB", "ToggleWindow")
    MB:RegisterChatCommand("mb", "ToggleWindow")
    MB:RegisterChatCommand("mbd", "Debug")
end
function MB:OnEnable()
end
function MB:OnDisable()
end

local GetNumGroupMembers = GetNumGroupMembers

function MB:ToggleWindow()
    if not MB.window then
        MB:CreateWindow()
    end
    if MB.window:IsShown() then
        MB.window:Hide()
    else
        MB.window:Show()
    end
end

local wstat = {width = 1200, height = 720, top = nil, left = nil}
function MB:CreateWindow()
    if MB.window then
        return
    end

    -- Create Window
    local window = AceGUI:Create("Window")
    window:SetTitle("Assign Subgroups")
    window:SetLayout("Fill")
    window:Hide()
    window:SetStatusTable(wstat)
    MB.window = window

    -- Create global scroll frame to hold all UI elements inside window
    local fillScroll = AceGUI:Create("ScrollFrame")
    fillScroll:SetRelativeWidth(1)
    fillScroll:SetLayout("List")
    fillScroll:SetHeight(window.status.height)
    MB.fs = fillScroll
    assert(MB.fs)
    window:AddChild(fillScroll)

    -- Create Roster Frame
    local rosterFrame = AceGUI:Create("InlineGroup")
    rosterFrame:SetTitle("Group Members")
    rosterFrame:SetLayout("Flow")
    rosterFrame:SetRelativeWidth(1)
    MB.window.r = rosterFrame
    fillScroll:AddChild(rosterFrame)

    -- Create heading divider
    local h = AceGUI:Create("Heading")
    h:SetText("Subgroups")
    h:SetRelativeWidth(1)
    fillScroll:AddChild(h)

    -- Create "add subgroup" button
    local addGroupBtn = AceGUI:Create("Button")
    addGroupBtn:SetText("Add Subgroup")
    addGroupBtn:SetCallback(
        "OnClick",
        function()
            MB:CreateSubgroup()
        end
    )
    fillScroll:AddChild(addGroupBtn)

    -- Create scroll frame to hold subgroups
    local subGroupHolder = AceGUI:Create("ScrollFrame")
    subGroupHolder:SetHeight(window.content.height * .6)
    subGroupHolder:SetRelativeWidth(1)
    subGroupHolder:SetAutoAdjustHeight(true)
    subGroupHolder:SetLayout("List")
    MB.gh = subGroupHolder
    fillScroll:AddChild(subGroupHolder)

    -- Clear button, rebuild window
    local addGroupBtn = AceGUI:Create("Button")
    addGroupBtn:SetText("Clear")
    addGroupBtn:SetCallback(
        "OnClick",
        function(widget)
            wstat = window.status
            AceGUI:Release(MB.window)
            MB.window = nil
            MB:CreateWindow()
            MB.window:Show()
            -- MB.gh:PerformLayout()
        end
    )
    fillScroll:AddChild(addGroupBtn)

    -- Fill the roster and build the labels
    MB:GetGroupMembers()
    MB:BuildRoster()
end

function MB:CreateSubgroup()
    local g = AceGUI:Create("InlineGroup")
    g:SetLayout("Flow")
    g:SetRelativeWidth(1)

    local b = AceGUI:Create("Button")
    local rel = false
    b:SetText("Delete")
    b:SetCallback(
        "OnClick",
        function()
            MB.gh:ReleaseChildren()
            MB.gh:PerformLayout()
            print("released" .. tostring(g))
            rel = true
        end
    )
    g:AddChild(b)
    MB.gh:AddChild(g)
end

local roster_units = {}
local groups = {}
function MB:GetGroupMembers()
    local numInGroup = GetNumGroupMembers()
    if numInGroup > 0 then
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, numInGroup do
            local playername = GetUnitName(prefix .. i, false)
            local _,
                playerclass = UnitClass(prefix .. i)
            table.insert(roster_units, {name = playername, class = playerclass, group = nil})
        end
    else
        print("MB can't find anyone in your group")
    end
end

function MB:BuildRoster()
    if not MB.window then
        return
    end
    MB.window.r:ReleaseChildren()
    for i, pinfo in ipairs(roster_units) do
        local c = RAID_CLASS_COLORS[string.upper(pinfo["class"])]
        if c then
            local sg = AceGUI:Create("InlineGroup")
            sg:SetLayout("Fill")
            sg:SetWidth(120)
            sg:SetHeight(24)
            local l = AceGUI:Create("InteractiveLabel")
            l:SetText(pinfo["name"])
            l:SetColor(c.r, c.g, c.b)
            l:SetHighlight("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
            l:SetUserData({p = pinfo})
            sg:AddChild(l)
            MB.window.r:AddChild(sg)
        end
    end
    assert(MB.fs)
    MB.fs:PerformLayout()
end

function MB:Debug(input)
    if input == "create" then
        local classes = {
            "Warrior",
            "Paladin",
            "Hunter",
            "Rogue",
            "Priest",
            "DeathKnight",
            "Shaman",
            "Mage",
            "Warlock",
            "Monk",
            "Druid",
            "DemonHunter"
        }
        for j = 1, 5 do
            local cla = classes[math.random(1, 12)]
            local nam = ""
            for i = 1, math.random(4, 12) do
                nam = nam .. string.char(math.random(97, 122))
            end
            if #roster_units < 40 then
                table.insert(roster_units, {name = nam, class = cla, group = nil})
            end
        end
    elseif input == "clear" then
        roster_units = {}
    else
        local tname = GetUnitName("target", false)
        local tclass = UnitClass("target", false)
        if tname and tclass then
            table.insert(roster_units, {name = tname, class = tclass, group = nil})
        end
    end
    MB:BuildRoster()
end
