# Status Effects Wiring Plan

## Critical Bug: Status Definitions Never Load

`combat_manager.gd:140` tries to load status data from `spells.json`:
```gdscript
_status_effects = data.get("status_effects", {})
```

But `spells.json` has no `"status_effects"` key. The actual data lives in `statuses.json` under a `"statuses"` **array** — and nothing ever loads it. This means `_status_effects` is always `{}`, so:

- **DoT never ticks** — `effect_def.get("damage_per_turn", 0)` always returns 0
- **Incapacitation never fires** — `effect_def.get("blocks_actions", false)` always returns false
- **Movement blocking never fires** — `effect_def.get("blocks_movement", false)` always false
- All status processing in `_process_status_effects()` is effectively dead code

**Fix (Step 0):** Load `statuses.json` and index by name into a dict.

---

## Current State

### What exists (data)
- **88 status effects** fully defined in `statuses.json` with rich metadata
- Categories: CC (14), DoT (10), buff/debuff (40+), transformation (5+), aura (4), special (5+)
- Each status has: `effects` array (behavior strings), `duration_type`, `dispellable`, `dispel_methods`, `save_type`, `damage_per_turn`, `heal_per_turn`, `stackable`, `spread`, `grants_vulnerability`
- **326 spells** reference statuses via `statuses_caused` / `statuses_removed`
- **Items** reference statuses: weapon oils have `status`/`status_chance`, bombs have `statuses` arrays
- **Active perks** reference statuses in `combat_data.statuses`

### What exists (code)
- `_apply_status_effect()` — appends `{status, duration, value}` to unit
- `_cleanse_status_effects()` — removes from hardcoded list
- `_process_status_effects()` — turn-start processing (DoT, HoT, skip turn, duration tick) — all broken due to empty lookup
- `_process_terrain_effects()` — terrain damage/heal works, but no status application
- `is_unit_incapacitated()` / `can_unit_move()` — broken (same empty lookup)
- Spell casting applies statuses via `statuses_caused` field
- Visual display shows status abbreviations on units

### What's broken
1. Status definitions never load (see above)
2. `_cleanse_status_effects()` uses hardcoded status list instead of `dispellable`/`dispel_methods`
3. No saving throws — `save_type` and `save_at_end_of_turn` fields exist but aren't processed
4. No stacking logic — `stackable` field exists but code just appends duplicates regardless

### What's missing
1. **Effects processor** — the `effects` array strings (e.g., `"skip_turn"`, `"cannot_move"`, `"vulnerable_to_physical"`) are never interpreted
2. **Stat modifiers from statuses** — Blessed should give attack/defense, Hasted should give speed/initiative, Cursed should penalize, etc.
3. **Reactive statuses** — Fireshield (damage melee attackers), Pain_Mirror (reflect damage), Lifelink (lifesteal), Poison_Skin
4. **Behavior overrides** — Confused (random targeting), Feared (flee), Berserk (attack nearest), Charmed (won't attack caster), Pacified (won't fight)
5. **Terrain → Status** — fire terrain should apply Burning, ice should apply Slowed, poison should apply Poisoned
6. **Status → Terrain** — Burning units could ignite flammable terrain, frozen units could create ice patches
7. **Status spread** — Burning has spread rules (`"chance": "low"`, `"range": "melee"`)
8. **Expiry callbacks** — Infected spawns fungal, Doomed kills, etc.
9. **Vulnerability/resistance from statuses** — `grants_vulnerability` field never applied
10. **Aura statuses** — Favorable_Wind, Aura_of_Blessing, Soothing_Presence, Magnetizing_Aura

---

## Implementation Plan

### Step 0: Fix the loading bug
Load `statuses.json` and index by name. This alone makes DoT, HoT, and incapacitation work.

```gdscript
func _load_status_definitions() -> void:
    var file = FileAccess.open("res://resources/data/statuses.json", FileAccess.READ)
    var data = JSON.parse_string(file.get_as_text())
    file.close()
    # Convert array to dict keyed by name for O(1) lookup
    for status in data.get("statuses", []):
        _status_effects[status.name] = status
```

**Immediately unlocks:** DoT ticking, HoT healing, incapacitation (Frozen/Stunned/Petrified skip turns).

### Step 1: Add missing flags to status definitions
The code checks `blocks_actions` and `blocks_movement` but the JSON doesn't have these — it uses `effects` array strings like `"skip_turn"` and `"cannot_move"`. Two options:

**Option A (recommended):** Add explicit flags to statuses.json:
```json
{
  "name": "Frozen",
  "blocks_actions": true,
  "blocks_movement": true,
  "grants_vulnerability": {"physical": 50},
  ...
}
```

**Option B:** Parse the `effects` array at load time and set flags:
```gdscript
# During _load_status_definitions:
if "skip_turn" in status.effects or "cannot_act" in status.effects:
    status["blocks_actions"] = true
if "cannot_move" in status.effects:
    status["blocks_movement"] = true
```

Option B keeps the data clean and derives flags from the effects array — probably better long-term since the effects array is already there.

### Step 2: Stat modifiers from statuses
Many buff/debuff statuses should modify combat stats. Add a `stat_modifiers` dict to status definitions:

```json
{
  "name": "Blessed",
  "stat_modifiers": {"accuracy": 10, "armor": 10},
  ...
},
{
  "name": "Hasted",
  "stat_modifiers": {"movement": 2, "initiative": 5},
  ...
},
{
  "name": "Cursed",
  "stat_modifiers": {"accuracy": -10, "armor": -10},
  ...
},
{
  "name": "Slowed",
  "stat_modifiers": {"movement_pct": -50},
  ...
}
```

**Apply in CombatUnit:** Modify `get_accuracy()`, `get_dodge()`, `get_armor()`, etc. to sum status modifiers:

```gdscript
func _get_status_stat_bonus(stat: String) -> int:
    var total := 0
    for effect in status_effects:
        var def = CombatManager.get_status_definition(effect.status)
        var mods = def.get("stat_modifiers", {})
        total += mods.get(stat, 0)
    return total

func get_armor() -> int:
    var derived = character_data.get("derived", {})
    return derived.get("armor", 0) + _get_status_stat_bonus("armor")
```

### Step 3: Fix cleanse to use status definitions

Replace hardcoded list with data-driven check:

```gdscript
func _cleanse_status_effects(unit: Node, count: int) -> int:
    # ... existing loop ...
    var status_name = unit.status_effects[i].status
    var def = _status_effects.get(status_name, {})
    if def.get("dispellable", false) and def.get("type", "") == "debuff":
        to_remove.append(i)
        removed += 1
```

### Step 4: Saving throws
Process `save_at_end_of_turn` during `_process_status_effects()`:

```gdscript
# After decrementing duration, before removal check:
if effect_def.get("save_at_end_of_turn", false):
    var save_type = effect_def.get("save_type", "Constitution")
    var save_attr = unit.character_data.get("attributes", {}).get(save_type.to_lower(), 10)
    var roll = randi_range(1, 20) + save_attr
    if roll >= 15:  # DC 15 base, could be configurable
        effect.duration = 0  # Mark for removal
```

For `"duration_type": "until_save"` statuses (like Held), don't decrement duration normally — only remove on successful save.

### Step 5: Terrain ↔ Status integration
This is the geo-status connection you mentioned.

**Terrain → Status application** (in `_process_terrain_effects()`):

```gdscript
CombatGrid.TerrainEffect.FIRE:
    apply_damage(unit, value, "fire")
    # Apply Burning if not already burning
    if not unit.has_status("Burning"):
        _apply_status_effect(unit, "Burning", 2)
    terrain_damage.emit(unit, value, effect_name)

CombatGrid.TerrainEffect.ICE:
    # Ice applies Slowed instead of damage
    if not unit.has_status("Slowed") and not unit.has_status("Frozen"):
        _apply_status_effect(unit, "Slowed", 1)

CombatGrid.TerrainEffect.POISON:
    apply_damage(unit, value, "physical")
    if not unit.has_status("Poisoned"):
        _apply_status_effect(unit, "Poisoned", 3)
    terrain_damage.emit(unit, value, effect_name)

CombatGrid.TerrainEffect.CURSED:
    apply_damage(unit, value, "black")
    # Small chance to apply Cursed debuff
    if randf() < 0.3 and not unit.has_status("Cursed"):
        _apply_status_effect(unit, "Cursed", 2)
    terrain_damage.emit(unit, value, effect_name)

CombatGrid.TerrainEffect.BLESSED:
    unit.heal(value)
    # Could briefly grant Blessed buff
    terrain_heal.emit(unit, value, effect_name)
```

**Status → Terrain creation** (after status application):

```gdscript
# When a unit is killed while Burning, create fire terrain
# When Frozen expires, leave ice patch
# When poisoned unit dies, create poison pool
func _on_status_terrain_interaction(unit: Node, status_name: String, event: String) -> void:
    if combat_grid == null:
        return
    match [status_name, event]:
        ["Burning", "unit_died"]:
            combat_grid.add_terrain_effect(unit.grid_position, CombatGrid.TerrainEffect.FIRE, 2)
        ["Frozen", "expired"]:
            combat_grid.add_terrain_effect(unit.grid_position, CombatGrid.TerrainEffect.ICE, 2)
        ["Poisoned", "unit_died"]:
            combat_grid.add_terrain_effect(unit.grid_position, CombatGrid.TerrainEffect.POISON, 2)
```

### Step 6: Reactive statuses
Statuses that trigger when something happens to/near the unit.

**On melee attack received:**
```gdscript
# In attack_unit(), after damage is dealt:
if hit:
    # Check defender's reactive statuses
    if defender.has_status("Fireshield"):
        var fire_dmg = 5  # or scaled by spellpower
        apply_damage(attacker, fire_dmg, "fire")
    if defender.has_status("Poison_Skin"):
        if not attacker.has_status("Poisoned"):
            _apply_status_effect(attacker, "Poisoned", 3)
    if defender.has_status("Pain_Mirror"):
        var reflect_dmg = int(result.damage * 0.5)
        apply_damage(attacker, reflect_dmg, "physical")

    # Check attacker's reactive statuses
    if attacker.has_status("Lifelink") or attacker.has_status("Blood_Hunger"):
        var heal = int(result.damage * 0.5)
        attacker.heal(heal)
        unit_healed.emit(attacker, heal)
```

### Step 7: Behavior overrides (AI/turn control)
Complex CC statuses that change how a unit acts.

Add to turn processing in `_process_turn()` or equivalent:

```gdscript
func _get_behavior_override(unit: Node) -> String:
    # Returns the highest-priority behavior override, or "" for normal
    if unit.has_status("Feared"):
        return "flee"
    if unit.has_status("Confused") or unit.has_status("Chaotic"):
        return "random"
    if unit.has_status("Berserk"):
        return "attack_nearest"
    if unit.has_status("Charmed"):
        return "charmed"
    if unit.has_status("Pacified"):
        return "pacified"  # Skip turn but not incapacitated
    if unit.has_status("Forgetful"):
        return "move_only"
    return ""
```

For player units, this overrides normal input — the unit acts automatically under CC.

### Step 8: Expiry callbacks
Handle statuses with special on-expire behavior:

```gdscript
# In _process_status_effects(), when removing expired effect:
_on_status_expired(unit, status_name, effect_def)

func _on_status_expired(unit: Node, status_name: String, def: Dictionary) -> void:
    var effects = def.get("effects", [])
    if "death_on_expire" in effects:
        # Doomed
        apply_damage(unit, unit.max_hp * 10, "black")  # Guaranteed kill
    if "damage_on_expire" in effects:
        apply_damage(unit, def.get("expire_damage", 20), "physical")
    if "bleed_on_expire" in effects:
        _apply_status_effect(unit, "Bleeding", 3)
    if "spawn_fungal_spawn_on_expire" in effects:
        # Infected — spawn enemy unit at position
        _spawn_unit_at(unit.grid_position, "fungal_spawn", CombatManager.Team.ENEMY)
```

### Step 9: Status spread
Burning has spread rules: low chance, melee range, base level only.

```gdscript
# At end of _process_status_effects(), check spread:
for effect in unit.status_effects:
    var def = _status_effects.get(effect.status, {})
    var spread = def.get("spread", {})
    if spread.is_empty():
        continue
    var chance = _spread_chance_to_float(spread.get("chance", "none"))
    if randf() > chance:
        continue
    # Find adjacent units
    var adj_units = _get_adjacent_units(unit)
    for adj in adj_units:
        if not adj.has_status(effect.status):
            _apply_status_effect(adj, effect.status, def.get("default_duration", 2))
            break  # Spread to one unit per tick

func _spread_chance_to_float(chance_str: String) -> float:
    match chance_str:
        "low": return 0.15
        "medium": return 0.30
        "high": return 0.50
        _: return 0.0
```

### Step 10: Stackable vs non-stackable
```gdscript
func _apply_status_effect(unit: Node, status: String, duration: int, value: int = 0) -> void:
    var def = _status_effects.get(status, {})

    if unit.has_status(status):
        if def.get("stackable", false):
            # Stackable: add another instance (Burning stacks)
            pass  # Fall through to append
        else:
            # Non-stackable: refresh duration if longer
            for existing in unit.status_effects:
                if existing.status == status:
                    existing.duration = maxi(existing.duration, duration)
                    return

    unit.status_effects.append({
        "status": status,
        "duration": duration,
        "value": value
    })
```

---

## Status Effect Behavior Reference

A mapping from `effects` array strings to what they should do in code:

### Action blockers
| Effect string | Behavior |
|---|---|
| `skip_turn` | Unit skips entire turn |
| `cannot_act` | Cannot attack or cast (can still be moved by allies?) |
| `cannot_move` | Cannot move but can act |
| `cannot_cast` | Cannot cast spells (Silenced) |
| `cannot_attack` | Cannot make weapon attacks (Forgetful) |
| `cannot_use_ranged` | Cannot use ranged attacks (Blinded) |
| `cannot_target_spells` | Cannot target spells (Blinded) |
| `cannot_target_enemies` | Cannot target enemies (Sanctuary) |
| `cannot_be_targeted` | Cannot be targeted by enemies (Invisible, Sanctuary) |
| `cannot_teleport` | Prevents teleport abilities |
| `cannot_flee` | Prevents retreat |
| `cannot_deal_physical` | Physical attacks deal 0 (Thin Air) |

### Behavior overrides
| Effect string | Behavior |
|---|---|
| `flee_from_source` | Move away from caster each turn (Feared) |
| `random_movement` | Move to random tile |
| `random_target` | Attack random unit (friend or foe) |
| `attacks_closest_creature` | Attack nearest regardless of team (Berserk) |
| `ignores_allegiance` | Treats all as enemies |
| `treats_caster_as_ally` | Won't attack caster (Charmed) |
| `will_not_attack_caster` | Same as above |
| `will_not_attack` | Skip combat actions (Pacified) |
| `controlled_by_caster` | Full AI control change (Dominated) |
| `attack_breaks_invisibility` | Attacking removes Invisible |
| `breaks_on_offensive_action` | Any offensive action removes status (Sanctuary) |

### Stat modifiers
| Effect string | Behavior |
|---|---|
| `attack_bonus` / `attack_penalty` | +/- accuracy/damage |
| `defense_bonus` / `defense_penalty` | +/- armor |
| `speed_bonus` / `speed_penalty` | +/- movement |
| `initiative_bonus` / `initiative_penalty` | +/- initiative |
| `dodge_bonus` / `minor_dodge_bonus` | +/- dodge |
| `evasion_bonus` | Large dodge boost |
| `melee_damage_bonus` | +damage on melee |
| `melee_hit_chance_halved` | 50% accuracy penalty |
| `movement_reduced_50` | Half movement |
| `major_speed_boost` | Large movement increase |
| `range_bonus` | +range |
| `accuracy_bonus` | +accuracy |
| `critical_bonus_ranged` | +crit on ranged |

### Damage/heal effects
| Effect string | Behavior |
|---|---|
| `fire_damage_per_turn` | DoT (use `damage_per_turn` field) |
| `poison_damage_per_turn` | DoT |
| `physical_damage_per_turn` | DoT |
| `space_damage_per_turn` | DoT |
| `black_damage_per_turn` | DoT |
| `fire_damage_per_turn_internal` | DoT (bypasses fire resist?) |
| `damage_increases_each_turn` | Escalating DoT (Festering) |
| `heal_per_turn` | HoT |
| `heal_50_percent_of_damage_dealt` | Lifesteal (Lifelink) |
| `lifesteal_on_attacks` | Lifesteal (Blood_Hunger) |
| `share_healing_75_percent` | Link healing to another unit |

### Reactive effects
| Effect string | Behavior |
|---|---|
| `fire_damage_to_melee_attackers` | Fireshield |
| `poisons_melee_attackers` | Poison_Skin |
| `deal_50_percent_damage_taken_to_attacker` | Pain_Mirror |
| `lightning_aura_damages_attackers` | Storm_Lord |
| `lightning_aura_damages_and_stuns` | Lightning_Form |
| `charm_chance_on_enemy_melee_approach` | Magnetizing_Aura |
| `attack_damage_buff_when_ally_dies` | Ancestral_Vengeance |

### Immunity/resistance/vulnerability
| Effect string | Behavior |
|---|---|
| `vulnerable_to_physical` | +physical damage taken (Frozen) |
| `physical_immunity` | 100% physical resist (Petrified) |
| `physical_resist_50` | 50% physical resist |
| `physical_damage_negation_50_percent` | 50% physical damage reduction (Phasing) |
| `immune_to_all_damage` | Invulnerable |
| `air_damage_immunity` | 100% air resist |
| `immune_to_ground_effects` | Ignore terrain effects |
| `immune_to_terrain_hazards` | Same |
| `immune_to_melee_unless_flyer` | Melee can't reach (Flying) |
| `immune_to_ranged` | Ranged can't hit (Storm_Lord) |
| `fire_resistance_minus_50` | +50% fire vulnerability |
| `water_resistance_minus_25/50` | +25/50% water vulnerability |
| `elemental_resistance_25` | +25% all elemental resist |
| `ranged_damage_reduction` | Reduce ranged damage taken (Air_Shield) |
| `spell_damage_reduction` | Reduce spell damage taken (Magic_Shield) |
| `spell_reflect_chance` | Chance to reflect spells (Magic_Mirror) |
| `hp_shield` | Absorb damage (Mantric_Armor) |

### Movement/terrain
| Effect string | Behavior |
|---|---|
| `grants_flight` | Flying movement mode |
| `can_move_through_enemies` | Pass through enemy tiles (Smoke_Form) |
| `immobilized` | Cannot move |
| `rooted` | Cannot move (Shadow_Pinned) |
| `damage_on_move_attempt` | Take damage if trying to move while rooted |

### Special
| Effect string | Behavior |
|---|---|
| `next_ranged_guaranteed_hit` | Auto-hit on next ranged (Blessed_Shot) |
| `damage_boost` / `critical_boost` | Damage/crit buff |
| `adds_air_damage_to_attacks` | Bonus air damage on attacks (Electrified_Weapon) |
| `stun_chance_on_hit` | Chance to stun on attack |
| `increase_burning_damage_dealt` | Boost Burning DoT applied by this unit |
| `illusory_copies` / `copies_absorb_attacks` | Mirror Images mechanic |
| `stealth_bonus` | Detection avoidance |
| `can_move` | Explicitly can move (Forgetful: can move, can't attack) |
| `save_at_end_of_turn` | Roll save to end status early |
| `focus_save_on_damage` | Must save or lose action (Swarmed) |
| `hp_cannot_drop_below_1` | Death immunity |
| `return_on_death_next_turn` | Revive mechanic (Eternal_Vow) |
| `return_with_20_percent_hp` | Revive HP amount |
| `death_resistance` | Resist death effects |
| `linked_to_ally` | Share effects with linked ally |
| `buffs_two_highest_stats` | Buff best 2 attributes |
| `buffs_all_stats_considerably` | Buff all attributes |
| `minor_all_stats_bonus` | Small all-stat buff |
| `all_stats_penalty` | Debuff all attributes |
| `joins_party_permanently` | Dominated — recruit permanently |
| `spawn_fungal_spawn_on_expire` | Infected expire callback |
| `damage_on_expire` | Damage when status ends |
| `bleed_on_expire` | Apply Bleeding when status ends |
| `death_on_expire` | Kill unit when status ends (Doomed) |
| `spreads_on_contact` | Transfer to adjacent units |
| `relationship_bonus` | Non-combat social bonus |
| `heal_allies_per_turn_in_aura` | Aura heal (Soothing_Presence) |
| `aura_grants_haste` / `aura_grants_precision` | Aura buffs (Favorable_Wind) |
| `grants_blessed_to_nearby_allies` | Aura (Aura_of_Blessing) |
| `disengaged_from_combat` | Not in combat (Pacified) |

---

## Priority Order

1. **Step 0: Fix loading** — immediate, unlocks everything else
2. **Step 1: Derive flags from effects** — makes incapacitation/movement blocking work
3. **Step 2: Stat modifiers** — makes buffs/debuffs feel real
4. **Step 5: Terrain ↔ Status** — the geo-status connection
5. **Step 3: Fix cleanse** — data-driven dispel
6. **Step 10: Stack handling** — prevents duplicate status issues
7. **Step 6: Reactive statuses** — makes Fireshield/Pain_Mirror/Lifelink work
8. **Step 4: Saving throws** — adds counterplay
9. **Step 7: Behavior overrides** — CC that changes unit actions
10. **Step 8: Expiry callbacks** — Doomed/Infected special effects
11. **Step 9: Status spread** — Burning contagion

---

## File Touchpoints

| File | Changes |
|------|---------|
| `scripts/autoload/combat_manager.gd` | Load statuses.json, fix `_apply_status_effect`, add reactive/spread/save/expiry processing |
| `resources/data/statuses.json` | Add `stat_modifiers` dicts, possibly `blocks_actions`/`blocks_movement` flags |
| `scripts/combat/combat_unit.gd` | Add `_get_status_stat_bonus()`, modify stat getters |
| `scripts/combat/combat_grid.gd` | No changes needed (terrain system works) |
