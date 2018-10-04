MB = LibStub("AceAddon-3.0"):NewAddon("MotherBother", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local Sticky = LibStub("LibSimpleSticky-1.0")

function MB:OnInitialize()
    MB:RegisterChatCommand("motherbother", "ToggleWindow")
    MB:RegisterChatCommand("mb", "ToggleWindow")
    MB:RegisterChatCommand("mbd", "Debug")
end
function MB:OnEnable()
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end
function MB:OnDisable()
end

local GetNumGroupMembers = GetNumGroupMembers
-- LOCALS --
local orders = {}
orders[0] = {}
orders[1] = {}

function MB:ToggleWindow(input)
    if not MB.window then
        -- TODO: Finish this
        -- MB:CreateWindow()
        if not MB.roster then
            MB.roster = {}
        end
        if input == "rebuild" then
            MB:CreateSimpleWindow(true)
        else
            MB:CreateSimpleWindow(false)
        end
        MB.window:SetCallback(
            "OnClose",
            function(widget)
                -- MB.savedtext = MB.ed:GetText()
                AceGUI:Release(widget)
                MB.window = nil
            end
        )
        MB.window:Show()
    else
        AceGUI:Release(MB.window)
        MB.window = nil
    end
end

function MB:GetGroupMembers()
    MB.roster = {}
    local numInGroup = GetNumGroupMembers()
    if numInGroup > 0 then
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, numInGroup do
            local playername, _ = UnitName(prefix .. i)
            local _,
                playerclass = UnitClass(prefix .. i)
            local playerrole = UnitGroupRolesAssigned(prefix .. i)
            table.insert(MB.roster, {name = playername, class = playerclass, role = playerrole})
        end
    else
        print("MotherBother can't find anyone in your group")
    end
end

local function roleInOrder(player, order)
    for i, v in ipairs(order) do
        if v.role == player.role then
            return true
        end
    end
    return false
end

local lastorder = {}
local function insertIntoEmpty(player, limit)
    if #orders[1] < 2 then
        if (player.role == "TANK" or player.role == "HEALER") and not roleInOrder(player, orders[1]) then
            table.insert(orders[1], player)
            return
        end
    end
    if #lastorder < 3 then
        if not roleInOrder(player, lastorder) then
            table.insert(lastorder, player)
            return
        end
    end
    for i, v in ipairs(orders) do
        if #v < limit and i~= 1 then
            table.insert(orders[i], player)
            return
        end
    end
    _t = {}
    table.insert(_t, player)
    table.insert(orders, _t)
end

function MB:BuildDefaultRoster(d)
    d = d or false -- d for debug groups
    if not d then
        MB:GetGroupMembers()
    end
    orders = {}
    orders[0] = MB.roster
    orders[1] = {}
    lastorder = {}
    for i, v in ipairs(orders[0]) do
        insertIntoEmpty(v, 3)
    end
    if next(lastorder) then
        table.insert(orders, lastorder)
    end
    orders[0] = {}
end

local function getNames(t)
    ret = {}
    for i, v in ipairs(t) do
        table.insert(ret, v.name)
    end
    return ret
end

local function buildRoster()
    local lines = {}
    if next(orders[0]) then
        table.insert(lines, "Unassigned: " .. table.concat(getNames(orders[0]), ", "))
    end
    for i, v in ipairs(orders) do
        if i ~= 0 then
            table.insert(lines, "Group " .. i .. ": " .. table.concat(getNames(v), ", "))
        end
    end
    return table.concat(lines, "\n")
end

local function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function MB:GROUP_ROSTER_UPDATE()
    if not MB.savedtext then
        MB:CreateSimpleWindow(true)
    end
end

StaticPopupDialogs["MB_CONFIRM_RESET"] = {
    text = "This will DELETE all changes you've made and rebuild from scratch. Are you sure?",
    button1 = YES,
    button2 = CANCEL,
    OnAccept = function()
        MB:BuildDefaultRoster()
        MB.savedtext = nil
        MB.ed:SetText(buildRoster())
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

function MB:CreateSimpleWindow(rebuild)
    if MB.window then
        return
    end
    local wstat = {width = 300, height = 270, top = nil, left = nil}
    -- Create Window
    local window = AceGUI:Create("Window")
    window:SetLayout("Fill")
    window:Hide()
    window:SetStatusTable(wstat)
    window:SetTitle("MotherBother")
    window:EnableResize(false)
    MB.window = window

    -- Create global scroll frame to hold all UI elements inside window
    local fillScroll = AceGUI:Create("ScrollFrame")
    fillScroll:SetRelativeWidth(1)
    fillScroll:SetLayout("List")
    fillScroll:SetHeight(window.status.height)
    MB.fs = fillScroll
    window:AddChild(fillScroll)

    -- Create button frame
    local editButtonFrame = AceGUI:Create("SimpleGroup")
    editButtonFrame:SetLayout("Flow")
    editButtonFrame:SetRelativeWidth(1)
    MB.ebf = editButtonFrame
    fillScroll:AddChild(editButtonFrame)

    -- Report button
    local reportBtn = AceGUI:Create("Button")
    reportBtn:SetText("Report to Raid")
    
    reportBtn:SetCallback("OnClick",
        function(widget)
            for i,v in ipairs(split(MB.ed:GetText(), '\n')) do
                SendChatMessage(v , "RAID" , nil , "");
            end
        end    
    )
    reportBtn:SetRelativeWidth(.75)
    editButtonFrame:AddChild(reportBtn)

    -- Reset button

    local resetBtn = AceGUI:Create("Button")
    resetBtn:SetText("Reset")
    resetBtn:SetCallback("OnClick",
        function(widget)
            StaticPopup_Show("MB_CONFIRM_RESET")
        end    
    )
    resetBtn:SetRelativeWidth(.25)
    editButtonFrame:AddChild(resetBtn)

    -- Text box with groups
    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox:SetRelativeWidth(1)
    editbox:SetLabel("Assign Groups")
    editbox:SetNumLines(10)
    -- Setting MB.savedtext is how we flag that there's been user input
    if not MB.savedtext or rebuild then
        MB:BuildDefaultRoster()
        MB.savedtext = nil
        editbox:SetText(buildRoster())
    else
        editbox:SetText(MB.savedtext)
    end
    editbox.button:Hide()
    -- editbox:SetCallback(
    --     "OnEnterPressed",
    --     function(widget, text)
    --         MB.savedtext = MB.ed:GetText()
    --     end
    -- )
    -- editbox:SetCallback(
    --     "OnEditFocusLost",
    --     function(widget)
    --         MB.savedtext = MB.ed:GetText()
    --     end
    -- )
    editbox:SetCallback(
        "OnTextChanged",
        function(widget, text)
            MB.savedtext = MB.ed:GetText()
        end
    )
    MB.ed = editbox
    fillScroll:AddChild(editbox)
end





-- CODE BELOW THIS POINT IS UNFINISHED AND UNUSED





local function groupLabels(name, od)
    local g = AceGUI:Create("InlineGroup")
    g:SetRelativeWidth(1)
    g:SetLayout("Flow")
    g:SetTitle(name)

    -- local nm = AceGUI:Create("Label")
    -- nm:SetText(name..": ")
    -- g:AddChild(nm)

    for i, v in ipairs(od) do
        local l = AceGUI:Create("Label")
        l:SetText(v.name)
        l:SetWidth(90)
        local c = RAID_CLASS_COLORS[string.upper(v.class)]
        l:SetColor(c.r, c.g, c.b)
        g:AddChild(l)
    end
    return g
end

local function rosterLabels(f)
    f:AddChild(groupLabels("Unassigned", orders[0]))
    for i, v in ipairs(orders) do
        f:AddChild(groupLabels("Group " .. i, v))
    end
end

function MB:CreateWindow()
    if MB.window then
        return
    end
    local wstat = {width = 1200, height = 720, top = nil, left = nil}
    -- Create Window
    local window = AceGUI:Create("Window")
    window:SetLayout("Fill")
    window:Hide()
    window:SetStatusTable(wstat)
    MB.window = window

    -- Create global scroll frame to hold all UI elements inside window
    local fillScroll = AceGUI:Create("ScrollFrame")
    fillScroll:SetRelativeWidth(1)
    fillScroll:SetLayout("Flow")
    fillScroll:SetHeight(window.status.height)
    MB.fs = fillScroll
    window:AddChild(fillScroll)

    -- Create button frame
    local editButtonFrame = AceGUI:Create("SimpleGroup")
    editButtonFrame:SetLayout("Flow")
    editButtonFrame:SetRelativeWidth(1)
    MB.ebf = editButtonFrame
    fillScroll:AddChild(editButtonFrame)

    -- Global simple group to hold subframes (maybe unnecessary)
    local gsg = AceGUI:Create("SimpleGroup")
    gsg:SetRelativeWidth(1)
    gsg:SetLayout("Flow")
    MB.gsg = gsg
    fillScroll:AddChild(gsg)

    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox:SetRelativeWidth(.5)
    editbox:SetLabel("Assign Groups")
    editbox:SetNumLines(16)
    editbox:SetText(buildRoster())
    MB.ed = editbox
    fillScroll:AddChild(editbox)

    local orderFrame = AceGUI:Create("InlineGroup")
    orderFrame:SetRelativeWidth(.5)
    orderFrame:SetTitle("Assigned Groups")
    orderFrame:SetLayout("List")
    rosterLabels(orderFrame)
    MB.of = orderFrame
    fillScroll:AddChild(orderFrame)
end

function MB:Debug(input)
    if not MB.roster then MB.roster = {} end
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
            if #MB.roster < 40 then
                local r = ""
                if j == 1 then
                    r = "TANK"
                elseif j == 5 then
                    r = "HEALER"
                else
                    r = "DAMAGER"
                end
                table.insert(MB.roster, {name = nam, class = cla, role = r})
            end
        end
    elseif input == "clear" then
        orders = {}
        MB.roster = {}
    else
        local tname = GetUnitName("target", false)
        local tclass = UnitClass("target", false)
        if tname and tclass then
            table.insert(MB.roster, {name = tname, class = tclass, role = "DAMAGER"})
        end
    end
    orders[0] = MB.roster
    MB:BuildDefaultRoster(true)
    MB.savedtext = buildRoster()
    print(buildRoster())
end
