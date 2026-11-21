local _, ns = ...

-- Join requests: while your group is listed in the group finder and you lead it (or list
-- alone), every player who whispers you is added to the list with their class (from the
-- whisper's GUID). Level and zone need a /who, which the game only allows from a click,
-- so the window has a "Who" button per player. Players leave the list when they join.
--
-- Forever runs the "camelot" game type, which loads Blizzard_GroupFinder_VanillaStyle:
-- people browse listings and whisper the leader (ChatFrameUtil.SendTell(leaderName)).
-- APIs checked in the Forever UI source (Gethe/wow-ui-source 70ef1b2): C_LFGList.
-- HasActiveEntryInfo + LFG_LIST_ACTIVE_ENTRY_UPDATE, GetPlayerInfoByGUID, C_FriendList.
-- SendWho (HasRestrictions: hardware event) / GetNumWhoResults / GetWhoInfo
-- (level, classStr, filename, area) + WHO_LIST_UPDATE, C_PartyInfo.InviteUnit.

local Requests = { list = {} }
ns.Requests = Requests

local WHO_COOLDOWN = 3       -- seconds between two /who (the server throttles them)
local MAX_AGE = 30 * 60      -- requests older than this are dropped

local lastWho = 0

local function Short(name)
  return (Ambiguate and Ambiguate(name, "short") or name:match("^[^-]+")) or name
end

local function Notify()
  if Requests.OnChange then Requests.OnChange() end
end

--- Listed in the group finder, and leading the group (or alone).
function Requests.IsActive()
  if not (C_LFGList and C_LFGList.HasActiveEntryInfo and C_LFGList.HasActiveEntryInfo()) then return false end
  return not IsInGroup() or UnitIsGroupLeader("player")
end

local function InGroup(short)
  return UnitInParty(short) or UnitInRaid(short)
end

function Requests.Find(name)
  local short = Short(name):lower()
  for i, entry in ipairs(Requests.list) do
    if entry.short:lower() == short then return entry, i end
  end
end

local function FillFromGUID(entry)
  if entry.classFile or not entry.guid or not GetPlayerInfoByGUID then return end
  local className, classFile, race = GetPlayerInfoByGUID(entry.guid)
  if classFile then
    entry.class, entry.classFile, entry.race = className, classFile, race
  end
end

--- Adds (or refreshes) a request. `force` skips the listing check (test mode).
function Requests.Add(sender, message, guid, force)
  if not sender or sender == "" then return end
  if not force and not Requests.IsActive() then return end
  local short = Short(sender)
  if short == UnitName("player") or InGroup(short) then return end
  local entry = Requests.Find(sender)
  if not entry then
    entry = { name = sender, short = short }
    table.insert(Requests.list, entry)
  end
  entry.guid = guid or entry.guid
  entry.message = message
  entry.time = time()
  FillFromGUID(entry)
  Notify()
  return entry
end

function Requests.Remove(name)
  local _, i = Requests.Find(name)
  if i then table.remove(Requests.list, i); Notify() end
end

function Requests.Clear()
  wipe(Requests.list)
  Notify()
end

--- Drops players who joined and requests that are too old.
function Requests.Prune()
  local now, changed = time(), false
  for i = #Requests.list, 1, -1 do
    local entry = Requests.list[i]
    if InGroup(entry.short) or now - (entry.time or now) > MAX_AGE then
      table.remove(Requests.list, i)
      changed = true
    end
  end
  if changed then Notify() end
end

function Requests.Invite(name)
  local entry = Requests.Find(name)
  if not entry then return end
  local invite = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
  invite(entry.name)
  entry.invited = true
  Notify()
end

--- /who for one player (call from a click: the game requires a hardware event).
function Requests.Who(name)
  local entry = Requests.Find(name)
  if not entry then return false, "not in the list" end
  local wait = WHO_COOLDOWN - (GetTime() - lastWho)
  if wait > 0 then return false, ("wait %d s between two lookups"):format(math.ceil(wait)) end
  lastWho = GetTime()
  entry.looking = true
  C_FriendList.SendWho(('n-"%s"'):format(entry.short))
  Notify()
  return true
end

--- Takes level / zone / class from any /who result that matches a request.
function Requests.OnWhoResults()
  local changed = false
  for i = 1, (C_FriendList.GetNumWhoResults() or 0) do
    local info = C_FriendList.GetWhoInfo(i)
    local entry = info and info.fullName and Requests.Find(info.fullName)
    if entry then
      entry.level, entry.zone = info.level, info.area
      if not entry.classFile then entry.class, entry.classFile = info.classStr, info.filename end
      entry.race = entry.race or info.raceStr
      entry.looking = nil
      changed = true
    end
  end
  if changed then Notify() end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("WHO_LIST_UPDATE")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
frame:SetScript("OnEvent", function(_, event, ...)
  if event == "CHAT_MSG_WHISPER" then
    local message, sender = ...
    local guid = select(12, ...)
    if Requests.Add(sender, message, guid) and ns.RequestsUI then ns.RequestsUI.Show() end
  elseif event == "WHO_LIST_UPDATE" then
    Requests.OnWhoResults()
  elseif event == "GROUP_ROSTER_UPDATE" then
    Requests.Prune()
    if not Requests.IsActive() and ns.RequestsUI then ns.RequestsUI.HideIfIdle() end
  elseif event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
    -- Listing removed (group full, delisted): a new listing starts a new list.
    if not Requests.IsActive() then
      Requests.Clear()
      if ns.RequestsUI then ns.RequestsUI.HideIfIdle() end
    end
  end
end)
