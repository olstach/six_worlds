# Perk Wiring Plan — Passive Effect Integration

## Status Quo

### What works
- **Base skill bonuses** (`base_bonuses` in perks.json) — per-level stat tables (attack, damage, crit, armor, etc.) flow into `update_derived_stats()` via `PerkSystem.get_base_skill_bonuses_at_level()`.
- **Elemental affinity bonuses** — `PerkSystem.get_affinity_bonuses()` feeds into `update_derived_stats()`.
- **Active perks** (31 with `combat_data`) — full pipeline: stamina cost, cooldowns, targeting, 8 effect types (`attack_with_bonus`, `dash_attack`, `buff_self`, `debuff_target`, `aoe_attack`, `teleport`, `stance`, `heal_self`), plus AI usage scoring.

### The gap
~507 passive perks are stored on characters as `{id, name}`. Their effects exist only as human-readable `description` strings. No code reads or applies them.

---

## Effect Taxonomy

Every passive perk's description maps to one or more of these effect types:

### 1. `stat_bonus` — Flat or percentage stat modification
Most common type. Permanently modifies a derived stat while conditions are met.

```json
{
  "type": "stat_bonus",
  "stat": "armor",
  "value": 15,
  "is_pct": true,
  "condition": "wielding_sword"
}
```

**Examples:**
- Parry: "20% of Attack → Armor while wielding sword" → `stat_conversion` (see below)
- Focused Mind: "+15% resistance to mental effects" → `{"stat": "mental_resistance_pct", "value": 15}`
- Steady Aim: "+10% damage on ranged attacks if you did not move" → `{"stat": "damage_pct", "value": 10, "condition": "did_not_move", "weapon_type": "ranged"}`

### 2. `stat_conversion` — Derive one stat from another
A percentage of one stat is added to another.

```json
{
  "type": "stat_conversion",
  "source_stat": "accuracy",
  "target_stat": "armor",
  "pct": 20,
  "condition": "wielding_sword"
}
```

**Examples:**
- Parry: 20% Attack → Armor (wielding sword, not flanked)
- Improved Parry: 40% Attack → Armor (always)
- Body as Conduit: 25% Spellpower → Martial Arts scaling

### 3. `cost_reduction` — Reduce resource costs
Mana or stamina cost reduction for specific spell schools or skill types.

```json
{
  "type": "cost_reduction",
  "resource": "mana",
  "value": 15,
  "is_pct": true,
  "school": "fire"
}
```

**Examples:**
- Void Adept: "Space magic costs -15% mana"
- Efficient Strikes: "Sword abilities cost -2 Stamina"

### 4. `damage_modifier` — Modify outgoing damage
Percentage or flat bonus to damage under conditions.

```json
{
  "type": "damage_modifier",
  "value": 10,
  "is_pct": true,
  "condition": "all_weapons"
}
```

**Examples:**
- Weapon Master: "+10% damage with all weapons"
- Backstab: "+20% crit chance and +50% crit damage from behind"
- Momentum: "+15% crit chance after moving 1+ tile"

### 5. `on_trigger` — Reactive/conditional effect
Fires when a specific combat event occurs. Grants a temporary buff, counterattack, or special action.

```json
{
  "type": "on_trigger",
  "trigger": "dodge_success",
  "effect": {
    "type": "buff",
    "stat": "damage_pct",
    "value": 25,
    "duration": 1
  }
}
```

**Trigger types:**
- `dodge_success` — Successfully dodged an attack
- `parry_success` — Successfully parried
- `on_hit` — Landing an attack
- `on_kill` — Killing an enemy
- `on_crit` — Scoring a critical hit
- `combat_start` — First turn of combat
- `turn_start` — Each turn start
- `take_damage` — When damaged
- `ally_damaged` — When nearby ally takes damage

**Examples:**
- Riposte: "On dodge, next sword attack costs -2 Stamina and +25% damage"
- Quick Kill: "On kill with dagger, free action (move or re-enter stealth)"
- Borrowed Force: "On dodge, 50% chance to reposition behind attacker dealing 50% dagger damage"

### 6. `aura` — Passive area buff/debuff
Affects allies or enemies within range. Always active during combat.

```json
{
  "type": "aura",
  "targets": "allies",
  "range": 0,
  "effects": [
    {"stat": "movement", "value": 1},
    {"stat": "initiative", "value": 2},
    {"stat": "dodge_pct", "value": 5}
  ]
}
```

`range: 0` means line-of-sight/all. Otherwise tile radius.

**Examples:**
- Inspiring Presence: "All allies gain +1 Movement, +2 Initiative, +5% Dodge"
- Phalanx Fighter: "Adjacent allies gain +15% Armor"
- Intimidating Aura: "Enemies entering 2-tile radius must Focus save or become Pacified"

### 7. `resistance` — Elemental/status resistance
Flat or percentage resistance to damage types or status effects.

```json
{
  "type": "resistance",
  "damage_type": "mental",
  "value": 15,
  "is_pct": true
}
```

**Examples:**
- Inner Fortress: "+20% resistance to mental effects, +25% save vs forced movement/stun/knockdown"
- Elemental Resilience: "+20% resistance to all elemental damage"
- Fortress of Will: "Passing a save grants 50% resistance to that type for 2 turns"

### 8. `resource_regen` — Per-turn resource recovery
Stamina, mana, or HP regeneration each turn.

```json
{
  "type": "resource_regen",
  "resource": "stamina",
  "value": 2,
  "is_pct": false,
  "condition": null
}
```

**Examples:**
- Second Wind: "+2 Stamina per turn"
- Efficient Casting: "Regain 5-10% of mana spent after casting"

### 9. `spell_modifier` — Modify spell behavior
Changes how spells of a given school/type work.

```json
{
  "type": "spell_modifier",
  "school": "white",
  "modifier": "aoe_splash",
  "splash_range": 1,
  "splash_pct": 50
}
```

**Modifier subtypes:**
- `aoe_splash` — Single-target spells splash to nearby targets
- `duration_extend` — Status effects last +N turns
- `chain` — Spell chains to additional targets
- `cost_reduction` — Mana cost reduced (overlaps with type 3)
- `guaranteed_effect` — Status effects bypass saves

**Examples:**
- Healing Circle: "Single-target heals also affect allies within 1 tile at 50%"
- Lingering Power: "Status effects from your spells last +1 turn"
- Lightning Chain: "Lightning spells 30% chance to chain to 1 extra target at 50% damage"

### 10. `summon_modifier` — Buff summoned creatures
Modifies stats or behavior of summoned units.

```json
{
  "type": "summon_modifier",
  "summon_school": "black",
  "effects": [
    {"stat": "max_hp_pct", "value": 15},
    {"stat": "damage_pct", "value": 10}
  ]
}
```

**Examples:**
- Undead Vigor: "Black summons gain +15% HP and +10% damage"
- Dark Mastery: "Black summons gain +20% Attack/Damage and on-hit status effects"

### 11. `non_combat` — Out-of-combat effects
Trade, social, crafting, exploration bonuses. Applied by ShopSystem, EventManager, etc.

```json
{
  "type": "non_combat",
  "category": "trade",
  "effect": "price_modifier",
  "value": 10,
  "is_pct": true
}
```

**Subcategories:**
- `trade` — Buy/sell price modifiers
- `social` — Dialogue check bonuses
- `crafting` — Item creation bonuses
- `exploration` — Trap detection, hidden object finding
- `karma` — Hidden karma modifications
- `income` — Passive gold generation

**Examples:**
- Merchant Prince: "+10% buy/sell prices, unlock elite mercenaries"
- Silver Tongue: "+10% success on dialogue checks"
- Trap Sense: "Detect traps within 3 tiles"
- Passive Income: "Gain 3% of current gold per day (min 50)"

### 12. `special` — Unique mechanics
One-off rules that don't fit other categories. Keep the description as documentation and implement individually.

```json
{
  "type": "special",
  "mechanic": "dual_wield",
  "description": "Can dual-wield sword and dagger. Off-hand at 50% damage. Free weapon switching."
}
```

**Examples:**
- Dual Discipline: Dual-wield sword + dagger
- Mantra passives: Ongoing area effects with Deity Yoga upgrades
- Casting doesn't interrupt mantras

---

## Condition Reference

Conditions that gate when an effect applies:

| Condition | Where checked | Description |
|-----------|--------------|-------------|
| `wielding_sword` | CombatUnit.get_equipped_weapon() | Equipped weapon type matches |
| `wielding_ranged` | CombatUnit.is_ranged_weapon() | Using a ranged weapon |
| `not_flanked` | CombatGrid adjacency check | No enemy behind unit |
| `unarmored_or_light` | Equipment weight check | No heavy armor |
| `did_not_move` | CombatManager turn tracking | Unit hasn't moved this turn |
| `moved_this_turn` | CombatManager turn tracking | Unit moved 1+ tiles |
| `first_attack_combat` | Per-combat counter | First attack of the fight |
| `first_attack_turn` | Per-turn counter | First attack this turn |
| `from_stealth` | Status effect check | Unit is stealthed |
| `from_behind` | Grid position check | Attacking from rear facing |
| `target_bleeding` | Status effect check | Target has bleed status |
| `target_debuffed` | Status effect count | Target has 2+ debuffs |
| `on_terrain_type` | CombatGrid terrain check | Standing on earth/stone/etc. |

---

## Implementation Steps

### Step 1: Define effect schema (this document)
Done. The 12 types above cover all ~507 passive perks.

### Step 2: Add `effects` arrays to perks.json
Batch process — parse each perk's description and generate structured effects.

**Approach:**
- Script-assisted: Use patterns in descriptions to auto-generate most effects
- Manual review: Complex perks (mantras, special mechanics) need hand-tuning
- Preserve `description` field — it's the player-facing text, effects are for code

**Example transformation:**
```json
// BEFORE
"parry": {
  "name": "Parry",
  "skill": "swords",
  "required_level": 3,
  "description": "Passive. 20% of your Attack is added to Armor while wielding a sword. Does not apply if flanked."
}

// AFTER
"parry": {
  "name": "Parry",
  "skill": "swords",
  "required_level": 3,
  "description": "Passive. 20% of your Attack is added to Armor while wielding a sword. Does not apply if flanked.",
  "effects": [
    {
      "type": "stat_conversion",
      "source_stat": "accuracy",
      "target_stat": "armor",
      "pct": 20,
      "conditions": ["wielding_sword", "not_flanked"]
    }
  ]
}
```

### Step 3: Add query methods to PerkSystem

```gdscript
## Collect all passive effects from a character's owned perks.
## Returns Array of {perk_id, effect} dicts.
func get_passive_effects(character: Dictionary, filter_type: String = "") -> Array[Dictionary]:
    ...

## Get stat bonuses from passive perks (for update_derived_stats).
## Evaluates conditions that can be checked outside combat.
func get_passive_stat_bonuses(character: Dictionary) -> Dictionary:
    ...

## Get combat-relevant passive effects (for CombatUnit/CombatManager).
## Includes triggers, auras, conditional modifiers.
func get_combat_passives(character: Dictionary) -> Array[Dictionary]:
    ...

## Get non-combat effects (for ShopSystem, EventManager, etc.).
func get_non_combat_effects(character: Dictionary) -> Array[Dictionary]:
    ...
```

### Step 4: Hook into `update_derived_stats()`

In `character_system.gd`, after the existing affinity/equipment/base-bonus blocks:

```gdscript
# Apply passive perk stat bonuses
if PerkSystem:
    var perk_bonuses = PerkSystem.get_passive_stat_bonuses(character)
    for stat_key in perk_bonuses:
        derived[stat_key] = derived.get(stat_key, 0) + perk_bonuses[stat_key]
```

This handles types: `stat_bonus`, `stat_conversion`, `resistance` (unconditional ones).

### Step 5: Hook into CombatUnit

Add a method to CombatUnit that evaluates conditional passives at combat time:

```gdscript
## Get total stat modifier including passive perk conditions.
## Called by get_accuracy(), get_dodge(), get_armor(), etc.
func _get_perk_combat_bonus(stat: String) -> int:
    # Check each passive effect that modifies this stat
    # Evaluate conditions (wielding_sword, not_flanked, etc.)
    # Return total bonus
    ...
```

Modify existing getters to include perk bonuses:
```gdscript
func get_armor() -> int:
    var derived = character_data.get("derived", {})
    return derived.get("armor", 0) + _get_perk_combat_bonus("armor")
```

### Step 6: Hook into CombatManager for triggers

In `attack_unit()`, `apply_damage()`, etc., add trigger checks:

```gdscript
# After dodge succeeds:
_fire_perk_triggers(defender, "dodge_success", {"attacker": attacker})

# After a kill:
_fire_perk_triggers(attacker, "on_kill", {"target": defender})
```

```gdscript
func _fire_perk_triggers(unit: Node, trigger_type: String, context: Dictionary) -> void:
    var passives = PerkSystem.get_combat_passives(unit.character_data)
    for entry in passives:
        var effect = entry.effect
        if effect.type != "on_trigger" or effect.trigger != trigger_type:
            continue
        _apply_trigger_effect(unit, effect, context)
```

### Step 7: Hook into non-combat systems

**ShopSystem** — check for trade price modifiers:
```gdscript
var non_combat = PerkSystem.get_non_combat_effects(character)
for entry in non_combat:
    if entry.effect.category == "trade":
        price_modifier += entry.effect.value
```

**EventManager** — check for dialogue/social bonuses:
```gdscript
# When rolling skill checks, add perk bonuses
var social_bonus = PerkSystem.get_social_check_bonus(character, check_type)
```

---

## Priority Order

1. **stat_bonus + stat_conversion** — Biggest gameplay impact, simplest to wire
2. **damage_modifier + cost_reduction** — Direct combat feel improvement
3. **on_trigger** — Makes perks feel reactive and exciting
4. **aura** — Party composition matters more
5. **spell_modifier + summon_modifier** — Magic system depth
6. **non_combat** — Polish layer
7. **special** — Case-by-case implementation

---

## File Touchpoints

| File | Changes |
|------|---------|
| `resources/data/perks.json` | Add `effects` arrays to all passive perks |
| `scripts/autoload/perk_system.gd` | Add query methods (`get_passive_effects`, etc.) |
| `scripts/autoload/character_system.gd` | Hook `get_passive_stat_bonuses()` into `update_derived_stats()` |
| `scripts/combat/combat_unit.gd` | Add `_get_perk_combat_bonus()`, modify stat getters |
| `scripts/autoload/combat_manager.gd` | Add `_fire_perk_triggers()`, call at hit/dodge/kill/etc. |
| `scripts/autoload/shop_system.gd` | Query non-combat trade effects |
| `scripts/autoload/event_manager.gd` | Query non-combat social/exploration effects |
