--[[
    RP Phrases — configuration GUI (Ace3).

    STATUS: skeleton. Registers an AceConfig options table, wires /rp to open
    it in the Blizzard Interface panel, and exposes ns.OpenConfig for Init.lua.

    The full CRUD UI — scrollable spell list, per-rule modal with chance
    slider / channel dropdown / phrase editbox — is the next milestone. Rules
    are already usable by editing RPPhrasesDB directly (see README).

    Falls back to a slash-command-only experience when Ace3 isn't installed.
]]

local ADDON_NAME, ns = ...

local hasAce3 = C_AddOns.IsAddOnLoaded("Ace3")

if hasAce3 then
    local AceConfig = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    local options = {
        type = "group",
        name = "RP Phrases",
        args = {
            enabled = {
                type = "toggle",
                name = "Enabled",
                desc = "Master toggle for all RP Phrases.",
                order = 1,
                get = function() return ns.db and ns.db.enabled end,
                set = function(_, value)
                    if ns.db then ns.db.enabled = value end
                end,
            },
            -- TODO(next): dynamic rule editor. One group per spell, with a
            -- chance slider, channel dropdown, and phrase editbox per rule.
        },
    }

    AceConfig:RegisterOptionsTable(ADDON_NAME, options)
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "RP Phrases")

    ns.OpenConfig = function()
        InterfaceOptionsFrame_OpenToCategory("RP Phrases")
    end
else
    ns.OpenConfig = function()
        print("|cff33ff99RP Phrases:|r Ace3 not installed — GUI disabled. Rules live in RPPhrasesDB (SavedVariables).")
    end
end
