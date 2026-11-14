# Product Requirements Document & Technical Specification
## Addon Name: RP Phrases
**Target Client:** World of Warcraft: Forever (Patch 1.15.x / Modern Architecture)
**Environment:** Lua 5.1 / WoW API

---

### 1. Product Overview
**RP Phrases** is a lightweight, roleplay-enhancing World of Warcraft addon. It allows users to define custom chat messages that have a random chance to trigger when they cast specific spells. The addon features a graphical user interface (GUI) for creating, editing, and deleting these rules, and supports dynamic text replacement (e.g., inserting the target's name into the chat message).

### 2. Core Features & Requirements
*   **Dynamic Triggers:** Users can link a specific `Spell Name` to an array of possible chat outputs.
*   **Probability Engine:** Each phrase requires a user-defined percentage chance (1-100%) to trigger upon a successful cast.
*   **Target Parsing:** The addon must support the `--t` token in the user's phrase string. At runtime, the engine will replace `--t` with the intended target's name.
*   **Channel Selection:** Users can route the output to different channels (SAY, YELL, PARTY, RAID, EMOTE).
*   **In-Game GUI:** A configuration panel accessible via `/rp` to manage the phrase database (CRUD operations).
*   **Data Persistence:** User configurations must be saved across sessions.

---

### 3. Technical Architecture
The addon should be decoupled into three primary layers to ensure maintainability and low memory overhead during combat.

#### 3.1. File Structure
```text
RPPhrases/
├── RPPhrases.toc      # Manifest and metadata
├── Init.lua           # Database initialization and loading
├── Core.lua           # Event listener, caching, and RNG execution
└── GUI.lua            # Configuration interface (AceGUI recommended)
```

#### 3.2. Data Model (SavedVariables)
The addon will rely on a single global `SavedVariables` table defined in the `.toc` file.
**Table Structure:** Keyed by Spell Name (String), containing an array of rule objects.
```lua
RPPhrasesDB = {
    ["Fireball"] = {
        { chance = 20, channel = "YELL", text = "Burn, --t!" },
        { chance = 5, channel = "SAY", text = "Oops, dropped my cast." }
    },
    ["Arcane Intellect"] = {
        { chance = 100, channel = "PARTY", text = "Empowering your mind, --t." }
    }
}
```

#### 3.3. Event Flow & Execution Logic
Due to the decoupled nature of WoW's spellcasting API, the target is declared when a cast *starts*, but the spell only succeeds when the cast *finishes*.

1.  **Listener 1:** `UNIT_SPELLCAST_SENT` (Player)
    *   **Action:** Capture the `targetName` payload. Cache this in a local table (`pendingCast.target = targetName`).
2.  **Listener 2:** `UNIT_SPELLCAST_SUCCEEDED` (Player)
    *   **Action:** Retrieve the `spellID`, convert it to `spellName` via `C_Spell.GetSpellInfo(spellID)`.
    *   **Lookup:** Check `RPPhrasesDB[spellName]`. If rules exist, proceed to RNG evaluation.
    *   **Cleanup:** Clear the `pendingCast` cache immediately after evaluation to prevent state bleeding.

#### 3.4. Token Parsing Engine
If a phrase passes the RNG threshold check, parse the string before routing it to `SendChatMessage()`.
*   **Operation:** Use standard Lua string substitution.
*   **Implementation:** `local finalString = string.gsub(rule.text, "%-%-t", targetName)`
*   **Edge Case Handling (AoE Spells):** If a spell has no target (e.g., Arcane Explosion) and `--t` is present, default the replacement to an empty string, or fallback terms like `"everyone"` or `"you"`.

---

### 4. User Interface (GUI) Guidelines
To accelerate development and ensure a native look-and-feel, the engineering team is strongly encouraged to utilize the **Ace3 Framework** (specifically `AceGUI-3.0` and `AceConfig-3.0`), embedded locally or packaged as external dependencies.

**UI Elements Required:**
*   **Main Frame:** Scrollable list of existing configured spells.
*   **Rule Creation Modal:**
    *   `EditBox`: Spell Name (string).
    *   `Slider`: Trigger Chance (1 to 100, step 1).
    *   `Dropdown`: Chat Channel (Say, Yell, Party, Raid, Emote).
    *   `EditBox`: Phrase Text (supports `--t`).
    *   `Button`: Save/Commit.

### 5. Known Engineering Hazards & Taint Prevention
*   **Combat Lockdown:** This addon does *not* modify secure execution paths (it does not cast spells or change target logic). Therefore, standard UI rendering and chat output will not cause action taint.
*   **Global Cooldown Spam:** By tying the trigger to `UNIT_SPELLCAST_SUCCEEDED` rather than `UNIT_SPELLCAST_SENT`, the addon natively avoids spamming chat if the user mashes a button while stunned, out of range, or out of mana.
*   **Performance:** String manipulation and table lookups must be highly optimized. Avoid creating garbage/anonymous tables during the `UNIT_SPELLCAST_SUCCEEDED` event to prevent Lua Garbage Collection stuttering in 40-man raid environments.