local addonName, ns = ...

-- Saved data (account-wide) and the /egb command.

local function InitDB()
  EasyGroupBuilderDB = EasyGroupBuilderDB or {}
  local db = EasyGroupBuilderDB
  db.settings = db.settings or {}
  ns.db = db
end

function ns:Print(...)
  print("|cff33ccffEasyGroupBuilder|r:", ...)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == addonName then
    InitDB()
    frame:UnregisterEvent("ADDON_LOADED")
  end
end)

SLASH_EASYGROUPBUILDER1 = "/egb"
SLASH_EASYGROUPBUILDER2 = "/easygroupbuilder"
SlashCmdList.EASYGROUPBUILDER = function(msg)
  local cmd = (msg:match("^(%S*)") or ""):lower()
  if cmd == "" or cmd == "show" then
    ns.RequestsUI.Toggle()
  elseif cmd == "test" then
    ns.RequestsUI.Test()
  elseif cmd == "clear" then
    ns.Requests.Clear()
  elseif cmd == "autowho" then
    local arg = (msg:match("^%S+%s+(%S+)") or ""):lower()
    if arg == "on" or arg == "off" then ns.db.settings.autoWho = (arg == "on") end
    ns:Print("automatic level / zone lookup: " .. (ns.db.settings.autoWho == false and "off" or "on")
      .. " (/egb autowho on|off)")
  elseif cmd == "debug" then
    ns.db.settings.debug = not ns.db.settings.debug
    ns:Print("debug " .. (ns.db.settings.debug and "on" or "off") .. " - automatic lookups hooked on "
      .. #ns.Requests.hookedBindings .. " bindings, listed: " .. tostring(ns.Requests.IsActive()))
  elseif cmd == "help" then
    ns:Print("/egb - show / hide the join requests window | /egb test - fill it with fake players | /egb clear | /egb autowho on|off | /egb debug")
  else
    ns:Print("unknown command - try /egb help")
  end
end
