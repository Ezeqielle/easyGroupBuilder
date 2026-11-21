local _, ns = ...
local Requests = ns.Requests

-- "Join requests" window: one row per player who whispered you while your group is
-- listed: name (class color), class, level, zone, Who (level + zone lookup), Invite and
-- remove. Five rows visible, the rest by scrolling. Hover a row to read the whisper.
-- Templates checked in the Forever UI source: ButtonFrameTemplate (+ HidePortrait,
-- HideAttic, ShowButtonBar, SetTitle), WowScrollBoxList, MinimalScrollBar,
-- UIPanelButtonTemplate, UIPanelCloseButton.

local UI = {}
ns.RequestsUI = UI

local ROW_HEIGHT = 26
local VISIBLE_ROWS = 5
local WIDTH = 560
local COLUMNS = { -- x offset, width
  name = { 8, 120 }, class = { 132, 80 }, level = { 216, 40 }, zone = { 260, 130 },
}

local window, scrollBox, emptyText, statusText
UI.testMode = false

local function ClassColor(entry)
  local color = entry.classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.classFile]
  return color and color.colorStr and ("|c" .. color.colorStr) or "|cffffffff"
end

local function SetStatus(text)
  if statusText then statusText:SetText(text or "") end
end

local function Text(parent, column, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint("LEFT", COLUMNS[column][1], 0)
  fs:SetWidth(COLUMNS[column][2])
  fs:SetJustifyH(justify or "LEFT")
  fs:SetWordWrap(false)
  return fs
end

local function SmallButton(parent, text, width)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 20)
  b:SetText(text)
  return b
end

local function InitRow(row, entry)
  if not row.built then
    row.built = true
    row:SetHeight(ROW_HEIGHT)
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(1, 1, 1, 0.08)
    row.name, row.class = Text(row, "name"), Text(row, "class")
    row.level, row.zone = Text(row, "level", "CENTER"), Text(row, "zone")
    row.remove = CreateFrame("Button", nil, row, "UIPanelCloseButton")
    row.remove:SetSize(22, 22)
    row.remove:SetPoint("RIGHT", -2, 0)
    row.invite = SmallButton(row, "Invite", 64)
    row.invite:SetPoint("RIGHT", row.remove, "LEFT", -2, 0)
    row.who = SmallButton(row, "Who", 48)
    row.who:SetPoint("RIGHT", row.invite, "LEFT", -4, 0)
    row:SetScript("OnEnter", function(self)
      local e = self.entry
      if not e then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(ClassColor(e) .. e.name .. "|r")
      if e.race then GameTooltip:AddLine(e.race .. (e.class and (" " .. e.class) or ""), 1, 1, 1) end
      if e.message then GameTooltip:AddLine('"' .. e.message .. '"', 1, 0.82, 0, true) end
      if e.time then GameTooltip:AddLine(date("%H:%M", e.time), 0.6, 0.6, 0.6) end
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.remove:SetScript("OnClick", function(self) Requests.Remove(self:GetParent().entry.name) end)
    row.invite:SetScript("OnClick", function(self) Requests.Invite(self:GetParent().entry.name) end)
    row.who:SetScript("OnClick", function(self)
      local ok, err = Requests.Who(self:GetParent().entry.name)
      SetStatus(ok and "" or ("|cffff8040" .. err .. "|r"))
    end)
  end
  row.entry = entry
  row.stripe:SetColorTexture(1, 1, 1, (entry.index % 2 == 0) and 0.04 or 0)
  row.name:SetText(ClassColor(entry) .. entry.short .. "|r")
  row.class:SetText(entry.class or "|cff888888?|r")
  local waiting = entry.looking and GetTime() - entry.looking < 10
  local unknown = waiting and "..." or "|cff888888?|r"
  row.level:SetText(entry.level and tostring(entry.level) or unknown)
  row.zone:SetText(entry.zone or unknown)
  row.who:SetShown(not entry.level)
  row.invite:SetText(entry.invited and "Invited" or "Invite")
end

function UI.Refresh()
  if not window then return end
  local provider = CreateDataProvider()
  for i, entry in ipairs(Requests.list) do
    entry.index = i
    provider:Insert(entry)
  end
  scrollBox:SetDataProvider(provider, ScrollBoxConstants.RetainScrollPosition)
  emptyText:SetShown(#Requests.list == 0)
  window:SetTitle(("Join requests (%d)"):format(#Requests.list))
end
Requests.OnChange = UI.Refresh

local function SavePosition()
  local point, _, relPoint, x, y = window:GetPoint()
  ns.db.settings.requestsPoint = { point, relPoint, x, y }
end

local function Build()
  window = CreateFrame("Frame", "EasyGroupBuilderRequestsFrame", UIParent, "ButtonFrameTemplate")
  ButtonFrameTemplate_HidePortrait(window)
  -- No attic (it left an empty band above the headers), a button bar for Clear / status.
  ButtonFrameTemplate_HideAttic(window)
  ButtonFrameTemplate_ShowButtonBar(window)
  window:SetSize(WIDTH, 86 + VISIBLE_ROWS * ROW_HEIGHT)
  local p = ns.db and ns.db.settings.requestsPoint
  if p then window:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else window:SetPoint("CENTER", 0, 120) end
  window:SetFrameStrata("HIGH")
  window:SetMovable(true)
  window:EnableMouse(true)
  window:RegisterForDrag("LeftButton")
  window:SetScript("OnDragStart", window.StartMoving)
  window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition() end)
  window:SetClampedToScreen(true)
  table.insert(UISpecialFrames, window:GetName()) -- Escape closes it

  local inset = window.Inset
  local header = CreateFrame("Frame", nil, inset)
  header:SetPoint("TOPLEFT", 4, -4)
  header:SetPoint("TOPRIGHT", -24, -4)
  header:SetHeight(18)
  for key, title in pairs({ name = "Name", class = "Class", level = "Level", zone = "Zone" }) do
    local fs = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", COLUMNS[key][1], 0)
    fs:SetWidth(COLUMNS[key][2])
    fs:SetJustifyH(key == "level" and "CENTER" or "LEFT")
    fs:SetText(title)
  end

  scrollBox = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
  scrollBox:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
  scrollBox:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -2)
  scrollBox:SetHeight(VISIBLE_ROWS * ROW_HEIGHT)
  local bar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
  bar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
  bar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 0)
  local view = CreateScrollBoxListLinearView()
  view:SetElementExtent(ROW_HEIGHT)
  view:SetElementInitializer("Button", InitRow)
  ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, bar, view)

  emptyText = inset:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  emptyText:SetPoint("CENTER", scrollBox)
  emptyText:SetText("Players who whisper you while your group is listed show up here.")

  statusText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  statusText:SetPoint("BOTTOMLEFT", 12, 9)
  statusText:SetPoint("RIGHT", -100, 0)
  statusText:SetJustifyH("LEFT")

  local clear = SmallButton(window, "Clear", 70)
  clear:SetPoint("BOTTOMRIGHT", -8, 4)
  clear:SetScript("OnClick", function() Requests.Clear() end)

  window:SetScript("OnHide", function() UI.testMode = false end)
end

function UI.Show()
  if not window then Build() end
  UI.Refresh()
  window:Show()
end

function UI.Toggle()
  if window and window:IsShown() then window:Hide() else UI.Show() end
end

--- Closes the window when the listing / leadership ends (not while testing).
function UI.HideIfIdle()
  if window and window:IsShown() and not UI.testMode and #Requests.list == 0 then window:Hide() end
end

--- /egb test: fills the list with fake players to check the window.
function UI.Test()
  UI.testMode = true
  local fake = {
    { "Thrall-Forever", "WARRIOR", "Warrior", 24, "The Barrens" }, { "Jaina-Forever", "MAGE", "Mage", 22, "Stormwind City" },
    { "Anduin-Forever", "PRIEST", "Priest", 25, nil }, { "Rexxar-Forever", "HUNTER", "Hunter", nil, nil },
    { "Valeera-Forever", "ROGUE", "Rogue", 23, "Duskwood" }, { "Malfurion-Forever", "DRUID", "Druid", 26, "Darnassus" },
    { "Uther-Forever", "PALADIN", "Paladin", 21, "Westfall" },
  }
  for _, f in ipairs(fake) do
    local entry = Requests.Add(f[1], "inv please, " .. f[3]:lower() .. " lf group", nil, true)
    if entry then entry.classFile, entry.class, entry.level, entry.zone = f[2], f[3], f[4], f[5] end
  end
  UI.Show()
end
