--[[
    RP Phrases — entry point.

    Owns the addon namespace, SavedVariables defaults, and the /rp slash
    command. Core.lua (engine) and GUI.lua (config) both reach back in via the
    shared namespace table `ns`.
]]

local ADDON_NAME, ns = ...

ns.name = ADDON_NAME

-- Top-level defaults. Merged into RPPhrasesDB without clobbering rule data.
local DEFAULTS = {
    enabled = true,
}

-- ---------------------------------------------------------------------------
-- Database init
-- ---------------------------------------------------------------------------

local function initDB()
    RPPhrasesDB = RPPhrasesDB or {}
    for k, v in pairs(DEFAULTS) do
        if RPPhrasesDB[k] == nil then
            RPPhrasesDB[k] = v
        end
    end
    ns.db = RPPhrasesDB
end

-- ---------------------------------------------------------------------------
-- Slash command
-- ---------------------------------------------------------------------------

local function handleSlash(msg)
    msg = (msg or ""):trim()

    if msg == "" then
        -- Open the config GUI if available, otherwise point at the DB.
        if ns.OpenConfig then
            ns.OpenConfig()
        else
            print("|cff33ff99RP Phrases:|r rules live in RPPhrasesDB (SavedVariables).")
        end
    elseif msg == "list" then
        if not ns.db then
            print("|cff33ff99RP Phrases:|r not loaded yet.")
            return
        end
        local count = 0
        for spell, rules in pairs(ns.db) do
            if type(rules) == "table" and #rules > 0 then
                count = count + #rules
                print(("|cff33ff99RP Phrases:|r %s -> %d rule(s)"):format(spell, #rules))
            end
        end
        print(("|cff33ff99RP Phrases:|r %d configured rule(s) total."):format(count))
    else
        print("|cff33ff99RP Phrases:|r /rp (config)  |  /rp list")
    end
end

SLASH_RPPHRASES1 = "/rp"
SlashCmdList["RPPHRASES"] = handleSlash

-- ---------------------------------------------------------------------------
-- Load hook
-- ---------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        initDB()
        frame:UnregisterEvent("ADDON_LOADED")
    end
end)
