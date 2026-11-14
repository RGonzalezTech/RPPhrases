--[[
    RP Phrases — cast -> phrase engine.

    Listens for the player's own casts and, on success, looks up any rules
    stored under that spell's name, rolls RNG per rule, and sends the winning
    phrase to chat.

    Forever/Midnight hazard isolation (see docs/research.md):
      * getSpellName()  — spellID -> name via C_Spell.GetSpellInfo (always-safe
        per community testing, but the spellID delivered by the event may be
        secret during combat).
      * resolveTarget() — name to substitute for --t; UnitName() on hostile
        units may be secret in combat, so we fall back gracefully.
]]

local ADDON_NAME, ns = ...

-- In-flight cast state, keyed by castGUID. UNIT_SPELLCAST_SENT caches the
-- spellID/target; UNIT_SPELLCAST_SUCCEEDED consumes it. Instant casts may
-- skip SENT entirely, so SUCCEEDED falls back to its own spellID arg.
local pendingCast = {}

-- ---------------------------------------------------------------------------
-- Resolution helpers
-- ---------------------------------------------------------------------------

local function getSpellName(spellID)
    if not spellID then return nil end
    local info = C_Spell.GetSpellInfo(spellID)
    return info and info.name or nil
end

local function resolveTarget()
    -- Preferred: the player's current target at trigger time.
    local name = UnitName("target")
    if name and name ~= "" then
        return name
    end
    return "you"
end

-- ---------------------------------------------------------------------------
-- Event handlers
-- ---------------------------------------------------------------------------

local function onSpellcastSent(unit, target, castGUID, spellID)
    if unit ~= "player" then return end
    pendingCast[castGUID] = { target = target, spellID = spellID }
end

local function onSpellcastSucceeded(unit, castGUID, spellID)
    if unit ~= "player" then return end

    local db = ns.db
    if not db or not db.enabled then return end

    local cast = pendingCast[castGUID]
    pendingCast[castGUID] = nil

    -- Prefer the event's spellID; fall back to the SENT-cached one.
    local effectiveSpellID = spellID or (cast and cast.spellID)
    if not effectiveSpellID then return end

    local spellName = getSpellName(effectiveSpellID)
    if not spellName then return end

    local rules = db[spellName]
    if type(rules) ~= "table" or #rules == 0 then return end

    local targetName -- resolved lazily, only when a phrase actually fires

    for i = 1, #rules do
        local rule = rules[i]
        if rule and rule.text then
            local chance = rule.chance or 100
            if math.random(1, 100) <= chance then
                targetName = targetName or resolveTarget()
                -- Function form of gsub avoids %-in-target substitution bugs.
                local finalText = string.gsub(rule.text, "%-%-t", function()
                    return targetName
                end)
                SendChatMessage(finalText, rule.channel or "SAY")
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Registration
-- ---------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_SPELLCAST_SENT" then
        onSpellcastSent(...)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        onSpellcastSucceeded(...)
    end
end)
