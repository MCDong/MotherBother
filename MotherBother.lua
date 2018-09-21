MotherBother = LibStub("AceAddon-3.0"):NewAddon("MotherBother", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local Sticky = LibStub("LibSimpleSticky-1.0")

function MotherBother:OnInitialize()
    MotherBother:RegisterChatCommand("motherbother", "ToggleWindow")
    MotherBother:RegisterChatCommand("mb", "ToggleWindow")
    MotherBother:RegisterChatCommand("mbd", "Debug")
end
function MotherBother:OnEnable()
end
function MotherBother:OnDisable()
end

local GetNumGroupMembers = GetNumGroupMembers

function MotherBother:ToggleWindow()
    if not MotherBother.window then
        MotherBother:CreateWindow()
    end
    if MotherBother.window:IsShown() then
        MotherBother.window:Hide()
    else
        MotherBother.window:Show()
    end
end

function MotherBother:CreateWindow()
    if MotherBother.window then
        return
    end

    -- Create Window
    local window = AceGUI:Create("Window")
    window:SetTitle("Assign Subgroups")
    window:SetLayout("Fill")
    window:Hide()
    window:SetStatusTable({width = 1200, height = 720})
    MotherBother.window = window

    local fillScroll = AceGUI:Create("ScrollFrame")
    fillScroll:SetRelativeWidth(1)
    fillScroll:SetLayout("List")
    fillScroll:SetHeight(800)
    MotherBother.fs = fillScroll
    assert(MotherBother.fs)
    window:AddChild(fillScroll)

    -- Create Roster Frame
    local rosterFrame = AceGUI:Create("InlineGroup")
    rosterFrame:SetTitle("Group Members")
    rosterFrame:SetLayout("Flow")
    rosterFrame:SetRelativeWidth(1)
    MotherBother.window.r = rosterFrame
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
            MotherBother:CreateSubgroup()
        end
    )
    fillScroll:AddChild(addGroupBtn)

    -- Create scroll frame to hold subgroups
    local subGroupHolder = AceGUI:Create("ScrollFrame")
    subGroupHolder:SetHeight(window.content.height * .6)
    subGroupHolder:SetRelativeWidth(1)
    subGroupHolder:SetAutoAdjustHeight(true)
    subGroupHolder:SetLayout("List")
    MotherBother.gh = subGroupHolder
    fillScroll:AddChild(subGroupHolder)

    -- Clear button, rebuild window
    local addGroupBtn = AceGUI:Create("Button")
    addGroupBtn:SetText("Clear")
    addGroupBtn:SetCallback(
        "OnClick",
        function(widget)
            AceGUI:Release(MotherBother.window)
            MotherBother.window = nil
            MotherBother:CreateWindow()
            MotherBother.window:Show()
            -- MotherBother.gh:PerformLayout()
        end
    )
    fillScroll:AddChild(addGroupBtn)
    MotherBother:BuildRoster()
end

function MotherBother:CreateSubgroup()
    local g = AceGUI:Create("InlineGroup")
    g:SetLayout("Flow")
    g:SetRelativeWidth(1)

    local b = AceGUI:Create("Button")
    local rel = false
    b:SetText("Delete")
    b:SetCallback(
        "OnClick",
        function()
            MotherBother.gh:ReleaseChildren()
            MotherBother.gh:PerformLayout()
            print("released" .. tostring(g))
            rel = true
        end
    )
    g:AddChild(b)
    MotherBother.gh:AddChild(g)
end

local roster_units = {}
local groups = {}
function MotherBother:BuildRoster()
    if not MotherBother.window then
        return
    end
    MotherBother.window.r:ReleaseChildren()
    local numInGroup = GetNumGroupMembers()
    if numInGroup > 0 then
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, numInGroup do
            local playername = GetUnitName(prefix .. i, false)
            local _, playerclass = UnitClass(prefix .. i)
            table.insert(roster_units, {name = playername, class = playerclass, group = nil})
        end
    else
        print("MotherBother can't find anyone in your group")
    end

    for i, pinfo in ipairs(roster_units) do
        -- DEFAULT_CHAT_FRAME:AddMessage(""..pinfo[1]..pinfo[2])
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
            sg:AddChild(l)
            MotherBother.window.r:AddChild(sg)
        end
    end
    assert(MotherBother.fs)
    MotherBother.fs:PerformLayout()
end

function MotherBother:Debug(input)
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
    MotherBother:BuildRoster()
end
