# Forever addon-API research notes

Compiled while scaffolding RP Phrases. Sources are at the bottom.

## TL;DR

Forever is **not** "Patch 1.15.x" — that's Classic-era numbering. Forever
shares Mainline (Midnight, 12.x) UI architecture: internally it's game type
"camelot" vs retail's "standard", and the Midnight "addon disarmament"
(Secret Values + CLEU removal) is active in Forever too.

What that means for this addon:

- The core path — hear your own cast, look up the spell name, send a chat
  line — is low-risk, because it's out-of-combat roleplay and uses
  player-own unit events.
- Two payloads may still be "secret" during combat (see Risks): the
  spellID/target delivered by `UNIT_SPELLCAST_*`, and `UnitName()` on
  non-player units. Both are isolated behind small helpers in `Core.lua`.

## Key facts

1. **Client / versioning**
   - Forever = game type `camelot`; retail = `standard`. Same Mainline code
     family, sharing "the vast majority" of the 12.1.5 API.
   - Forever TOC interface: `16001` (Beta/Test). The live number ships at
     launch — read it in-game with `GetBuildInfo()`. `RPPhrases.toc` carries
     `## Interface: 16001` and should be bumped when Forever leaves beta.

2. **Secret Values (Midnight 12.0+, active in Forever)**
   - Combat state — health, buffs/debuffs, enemy actions, and spell
     name/ID/target for *other units* — becomes an opaque "black box" in
     combat and inside instances.
   - Addons can display the box (size, color, position) but not read what's
     inside.
   - Restrictions are primarily enforced during boss encounters / Mythic+;
     unit-spellcast events are expected to be unrestricted outside combat.

3. **CLEU removal**
   - `COMBAT_LOG_EVENT_UNFILTERED` is gone for addons. Spell-cast tracking
     must use unit events: `UNIT_SPELLCAST_START`, `UNIT_SPELLCAST_SUCCEEDED`,
     `UNIT_SPELLCAST_SENT`.
   - RP Phrases already keys off `UNIT_SPELLCAST_SUCCEEDED` — correct.

4. **Namespace migration (12.0)**
   - `GetSpellInfo(id)` -> `C_Spell.GetSpellInfo(id)` (returns a table; `.name`).
   - `GetSpellCooldown` -> `C_Spell.GetSpellCooldown`, `GetSpellLink` ->
     `C_Spell.GetSpellLink`, `IsUsableSpell` -> `C_Spell.IsSpellUsable`, etc.

5. **Documented always-safe** (per addon-community testing)
   - `C_Spell.GetSpellInfo(id)` / `C_Spell.GetSpellName(id)` -> name/icon always safe.
   - `GetSpecialization()`, `UnitIsDeadOrGhost()`, `UnitExists()` — always safe.
   - Conditionally-safe need a `C_Secrets` check first, e.g.
     `C_Spell.GetSpellCooldown` / `C_UnitAuras.*` with
     `C_Secrets.ShouldSpellCooldownBeSecret()`.

## Risks / open questions (validate on the live client)

1. **`UNIT_SPELLCAST_*` payload secrecy.** The events fire, but the spellID /
   target arguments may be secret values during combat. RP is out-of-combat,
   so expected low impact; still isolated behind `getSpellName()` /
   `resolveTarget()` in `Core.lua`.

2. **`SendChatMessage` in instances.** Combat-log chat is converted to
   KStrings and addon-to-addon comms are blocked in instances — but a normal
   player SAY / YELL / EMOTE is unaffected. RP happens out of instances, so
   low risk. Validate.

3. **Target-name resolution.** `UnitName()` on a hostile unit may be secret in
   combat. The fallback uses the player's current target at trigger time.

## Sources

- Wowhead — "WoW: Forever Will Have Addon Changes from Midnight"
  https://www.wowhead.com/news/wow-forever-will-have-addon-changes-from-midnight-382921
- Wowhead — "Combat Addons Disabled in End-Game Content in Midnight"
  https://www.wowhead.com/news/combat-addons-disabled-in-end-game-content-in-midnight-378679
- Warcraft Wiki — Patch 12.0.0 API changes notes
  https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes/notes
- Warcraft Wiki — TOC format (game-type interface table)
  https://warcraft.wiki.gg/wiki/TOC_format
- better-addons.com — WoW Addon Development Guide (Midnight 12.0)
  https://www.better-addons.com
- GitHub — wow-addon-dev (TheMizeGuy / DennysOliveira), `references/midnight-12.md`
  https://github.com/TheMizeGuy/wow-addon-dev
- GitHub — JustAC `AURA_DETECTION_ALTERNATIVES.md` (secret-value safety table)
  https://github.com/wealdly/justac
