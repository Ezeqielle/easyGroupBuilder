local addonName, ns = ...

-- Saved data (account-wide) and the /egb command. Features come next.

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
  if cmd == "" or cmd == "help" then
    ns:Print("commands: /egb help")
  else
    ns:Print("unknown command - try /egb help")
  end
end
