--[[
    RP Phrases — configuration GUI (Ace3).

    Full CRUD over RPPhrasesDB, built on AceConfig-3.0's dynamic-options
    support: the options table is generated on demand by a function passed to
    RegisterOptionsTable, and structural edits (add/remove spell or phrase)
    fire AceConfigRegistry:NotifyChange to re-feed the open panel.

    /rp opens AceConfigDialog's standalone window (version-proof across
    Midnight/Forever — InterfaceOptionsFrame_OpenToCategory is deprecated).
    The same options also appear under Interface > AddOns > RP Phrases.

    Without Ace3 installed, /rp falls back to a hint and rules stay editable
    directly in RPPhrasesDB.
]]

local ADDON_NAME, ns = ...

local hasAce3 = C_AddOns.IsAddOnLoaded("Ace3")

if hasAce3 then
    local AceConfig = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

    local CHANNELS = {
        SAY = "Say",
        YELL = "Yell",
        PARTY = "Party",
        RAID = "Raid",
        EMOTE = "Emote",
    }

    -- Session-local buffer for the "new spell" name field (not persisted).
    local pendingSpellName = ""

    local rebuildOptions -- forward declaration; assigned below

    local function buildRuleGroup(spellName, rules, index)
        local rule = rules[index]
        return {
            type = "group",
            name = "Phrase " .. index,
            inline = true,
            order = 10 + index,
            args = {
                text = {
                    type = "input",
                    name = "Phrase text",
                    desc = "Use --t where you want the target's name.",
                    order = 1,
                    width = "full",
                    get = function() return rule.text or "" end,
                    set = function(_, value) rule.text = value end,
                },
                chance = {
                    type = "range",
                    name = "Chance (%)",
                    desc = "1-100% chance to fire on a successful cast.",
                    order = 2,
                    min = 1,
                    max = 100,
                    step = 1,
                    get = function() return rule.chance or 50 end,
                    set = function(_, value) rule.chance = value end,
                },
                channel = {
                    type = "select",
                    name = "Channel",
                    order = 3,
                    values = CHANNELS,
                    get = function() return rule.channel or "SAY" end,
                    set = function(_, value) rule.channel = value end,
                },
                deleteRule = {
                    type = "execute",
                    name = "Delete phrase",
                    order = 4,
                    confirm = true,
                    confirmText = "Delete this phrase?",
                    func = function()
                        table.remove(rules, index)
                        rebuildOptions()
                    end,
                },
            },
        }
    end

    local function buildSpellGroup(spellName, rules, order)
        local group = {
            type = "group",
            name = spellName,
            inline = true,
            order = order,
            args = {
                addPhrase = {
                    type = "execute",
                    name = "Add phrase",
                    order = 1,
                    width = "half",
                    func = function()
                        table.insert(rules, { chance = 50, channel = "SAY", text = "" })
                        rebuildOptions()
                    end,
                },
                deleteSpell = {
                    type = "execute",
                    name = "Delete spell",
                    order = 2,
                    width = "half",
                    confirm = true,
                    confirmText = "Delete all phrases for " .. spellName .. "?",
                    func = function()
                        ns.db[spellName] = nil
                        rebuildOptions()
                    end,
                },
            },
        }
        for i = 1, #rules do
            group.args["rule" .. i] = buildRuleGroup(spellName, rules, i)
        end
        return group
    end

    -- Generator passed to RegisterOptionsTable; runs fresh on every feed so
    -- get/set closures always reference live rule objects.
    local function buildOptions()
        local db = ns.db
        if not db then
            return { type = "group", name = "RP Phrases", args = {} }
        end

        local args = {
            enabled = {
                type = "toggle",
                name = "Enabled",
                desc = "Master toggle for all RP Phrases.",
                order = 1,
                get = function() return db.enabled end,
                set = function(_, value) db.enabled = value end,
            },
            desc = {
                type = "description",
                name = "Cast a spell to fire a random phrase. Use --t in a phrase for the target's name.",
                order = 2,
            },
            newSpellName = {
                type = "input",
                name = "New spell name",
                desc = "Type a spell name (e.g. Fireball), then click Add spell.",
                order = 10,
                width = "full",
                get = function() return pendingSpellName end,
                set = function(_, value) pendingSpellName = value end,
            },
            addSpell = {
                type = "execute",
                name = "Add spell",
                order = 11,
                width = "half",
                disabled = function() return (pendingSpellName or ""):trim() == "" end,
                func = function()
                    local name = (pendingSpellName or ""):trim()
                    if name == "" then return end
                    if db[name] then return end -- already exists
                    db[name] = {}
                    pendingSpellName = ""
                    rebuildOptions()
                end,
            },
            spells = {
                type = "group",
                name = "Configured spells",
                inline = true,
                order = 20,
                args = {},
            },
        }

        local spellArgs = args.spells.args
        local order = 1
        for spellName, rules in pairs(db) do
            if type(rules) == "table" then
                spellArgs["spell" .. order] = buildSpellGroup(spellName, rules, order)
                order = order + 1
            end
        end

        return { type = "group", name = "RP Phrases", args = args }
    end

    -- Re-feed the open panel after a structural change.
    rebuildOptions = function()
        AceConfigRegistry:NotifyChange(ADDON_NAME)
    end

    AceConfig:RegisterOptionsTable(ADDON_NAME, buildOptions)
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "RP Phrases")

    ns.OpenConfig = function()
        AceConfigDialog:Open(ADDON_NAME)
    end
else
    ns.OpenConfig = function()
        print("|cff33ff99RP Phrases:|r Ace3 not installed — GUI disabled. Rules live in RPPhrasesDB (SavedVariables).")
    end
end
