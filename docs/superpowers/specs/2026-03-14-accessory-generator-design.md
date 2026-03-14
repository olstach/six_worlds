# Accessory Generator — Design Spec
Date: 2026-03-14

## Overview

Procedurally generated rings, amulets, and necklaces using the same budget-point pattern as the existing talisman generator. Items have synergistic stat packages at low tiers, and gain skill bonuses and perks at high tiers. 80% of multi-effect items draw from an attribute-anchored synergy group; 20% are fully random.

---

## Item Types & Slots

| Type | Slot | Forms |
|------|------|-------|
| ring | ring1 / ring2 | Ring, Band, Loop, Signet, Seal, Coil |
| amulet | trinket1 / trinket2 | Amulet, Pendant, Token, Ward, Lingam, Eye |
| necklace | trinket1 / trinket2 | Necklace, Chain, Cord, Beads, Strand, Braid |

Slot assignment: rings always equip to ring slots; amulets and necklaces equip to trinket slots.

---

## Rarity Budgets

| Rarity | Budget pts | Max effects | Skill chance | Perk chance |
|--------|-----------|-------------|--------------|-------------|
| common | 2 | 1 | 0% | 0% |
| uncommon | 4 | 2 | 0% | 0% |
| rare | 7 | 3 | 30% | 0% |
| epic | 12 | 3 | 60% | 20% |
| legendary | 18 | 4 | 80% | 50% |

A "skill effect" adds +1 to a skill within the synergy group's skill pool. A "perk effect" grants a passive perk compatible with the synergy group.

---

## Synergy Groups (attribute-anchored)

Used 80% of the time when an item has more than one effect. Each group defines which stats, skills, and perks are valid secondaries.

| Group | Primary Stats | Secondary Stats | Skills (rare+) |
|-------|--------------|-----------------|----------------|
| **Strength** | damage, armor | max_hp | swords, axes, maces, unarmed, armor |
| **Finesse** | dodge, crit_chance | initiative, movement | daggers, ranged, thievery, guile |
| **Constitution** | max_hp, max_stamina | armor | might, martial_arts |
| **Focus** | spellpower, max_mana | (any magic school skill at rare+) | fire_magic, water_magic, earth_magic, air_magic, space_magic, white_magic, black_magic, sorcery, enchantment, summoning |
| **Awareness** | max_mana, initiative | crit_chance | space_magic, air_magic, guile, learning |
| **Charm** | luck (attr), crit_chance | initiative | persuasion, leadership, performance |
| **Luck** | crit_chance, dodge | max_hp | thievery, guile, alchemy |

**Skill ID note:** All skill names in synergy group skill pools are the full IDs used in `character.skills` (e.g., `"white_magic"`, `"black_magic"`, `"armor"`). Do **not** use the shortened forms found in `talisman_tables.json` (e.g., `"white"`, `"black"`) — those are a pre-existing inconsistency in the talisman system and are not resolved by `CharacterSystem.get_skill_level()`.

The 20% "wild" roll ignores synergy groups entirely and picks stats freely from the global pool.

---

## Stat Costs (budget points)

Each stat has a point cost and a rolled amount range per point spent. Accessories use integer costs and smaller budgets than talismans (which use fractional costs and larger budgets). This is intentional — accessories are a distinct item class with different power density. Do not "correct" these costs to match `talisman_tables.json`.

| Stat | Cost | Amount per point |
|------|------|-----------------|
| damage | 1 | 2–4 |
| armor | 1 | 1–3 |
| dodge | 1 | 2–4 |
| crit_chance | 1 | 1–2 |
| initiative | 1 | 1–3 |
| movement | 2 | 1 |
| max_hp | 1 | 5–10 |
| max_mana | 1 | 5–10 |
| max_stamina | 1 | 5–8 |
| spellpower | 1 | 2–4 |
| strength / finesse / constitution / focus / awareness / charm / luck | 2 | 1 |
| skill +1 | 3 | 1 level |
| perk | variable (3–6) | one perk |

Note: `luck` is an attribute (stored in `character.attributes`), not a derived stat. It costs 2 points per +1 like all other attributes. It feeds into `derived.crit_chance` via `update_derived_stats()`.

Note: `damage` from accessories is valid. `character_system.gd` line 619 sets `derived.damage = equip_bonus.get("damage", 0)`, and `combat_unit.gd` line 634 adds `derived.damage` into `get_attack_damage()`. The full pipeline is confirmed.

Note: `movement` is a derived stat set from `finesse` but also read directly from `derived.movement` by the combat unit. An accessory `movement` bonus routes through `equip_bonus` → `derived.movement` in `update_derived_stats()`. The stat key is `"movement"`.

Note: single-effect items (common rarity, max_effects = 1) pick freely from the group's stat pool without applying the 80/20 split — there is no secondary stat to be synergistic with. The synergy group is still rolled (for naming consistency), but only one stat is drawn from it.

---

## Naming System

Three parts: **[prefix] [form] [suffix]**. Prefix tier matches rarity. Suffix is drawn from the rolled synergy group's suffix pool (or the wild pool for 20% random rolls).

### Prefixes by rarity

| Rarity | Prefixes |
|--------|---------|
| common | Copper, Bone, Crude, Scratched, Tarnished |
| uncommon | Silver, Jade, Carved, Worn, Conch, Lacquer |
| rare | Onyx, Amber, Inscribed, Ancient, Lapis |
| epic | Obsidian, Ivory, Runed, Wrathful |
| legendary | Crystal, Void, Dakini Hair, Sapphire, Emerald, Ruby |

### Forms by type (see table above)

### Suffixes by synergy group

| Group | Suffixes |
|-------|---------|
| Strength | of the Ox, of the Bear, of the Yak, of the Boar, of the Bull Elephant, of Crushing Force, of Iron Will |
| Finesse | of the Crow, of Stolen Steps, of the Viper, of the Cat, of the Fox, of the Heron, of the Mongoose, of Quick Hands |
| Constitution | of the Tortoise, of the Badger, of the Sleeping Bear, of Stone Flesh, of the Enduring |
| Focus | of the Serpent, of the Garuda, of the Peacock, of the Naga, of the Mandala, of the Dreaming Eye |
| Awareness | of the Owl, of the Open Sky, of the Raven, of the Bat, of Bardo's Edge, of Subtle Sight |
| Charm | of the Songbird, of the Golden Pheasant, of the Deer, of Silver Words, of Pleasant Lies |
| Luck | of the Magpie, of the Three-Legged Toad, of the White Rabbit, of the Lucky Bone, of Samsara's Whim, of the Fortunate Fall |
| wild | of Unclear Purpose, of Strange Workmanship, of the Confused Pilgrim, of the Lost Traveler |

**Example outputs:** "Dakini Hair Cord of the Open Sky", "Conch Lingam of the Garuda", "Ruby Band of Stolen Steps", "Bone Ring of Unclear Purpose", "Lapis Eye of the Raven"

---

## Data File

`resources/data/accessory_tables.json` — contains all pools, budgets, synergy groups, and name parts. Follows the same structure as `talisman_tables.json` so the pattern is familiar.

---

## Code

Single new function in `scripts/autoload/item_system.gd`:

```
generate_accessory(item_type: String, rarity: String) -> String
```

- Rolls synergy group (or wild 20% chance on multi-effect items)
- Builds stats from group's pool, spending budget points
- At rare+: optionally adds +1 skill from group's skill pool
- At epic/legendary: optionally adds a compatible perk
- Generates name from name_parts tables
- Calls `register_runtime_item()` and returns the item ID

Helper: `_generate_accessory_name(item_type, rarity, synergy_group) -> String`

**Slot field in generated item dict:**
- Ring items: `"slot": "ring1"` (mirrors talisman pattern of hardcoding the first valid slot)
- Amulet/necklace items: `"slot": "trinket1"`

The player equips to ring2 / trinket2 via the equip UI passing the slot explicitly. The hardcoded `"slot"` in the item dict is only a default hint and does not block equipping to the secondary slot.

## Perk Pools

Perks are defined per synergy group in `accessory_tables.json` under a `"perk_pools"` key. Each group lists 4–6 valid perk IDs drawn from `perks.json`. Perks that are broad combat or utility modifiers are preferred over highly situational ones. The implementer populates these by consulting `perks.json` at implementation time.

Guidelines per group:
- **Strength**: on-hit physical perks, armor penetration, brute-force effects
- **Finesse**: evasion procs, crit-on-dodge type effects, mobility perks
- **Constitution**: damage reduction, bleed-out survival, stamina perks
- **Focus**: spell cost reduction, overcast bonuses, elemental affinity perks
- **Awareness**: initiative procs, crit-on-awareness effects, detection perks
- **Charm**: leadership auras, morale effects, social perks
- **Luck**: loot/gold bonuses, crit-cascade perks, fortune-type effects

---

## Integration Points

The generator produces a valid item ID that works everywhere existing items work. Integration:

- **Bone pile rewards** (`hell.json`): add `item_random_scaled` tier entries for accessories (common at weak, uncommon at medium, rare at strong)
- **Shop** (`item_system.gd` shop generation or `shops.json`): accessories tab can include procedural rings/amulets alongside static ones
- **Combat loot** (`combat_manager.gd` reward calculation): small chance to add a generated accessory to post-combat rewards
- **Events** (`event_manager.gd`): new reward type `"accessory_random"` with rarity parameter

Integration is additive — no existing systems need to change, only new call sites added.

---

## Out of Scope

- Weapon generation (separate system, different complexity)
- Armor generation (separate system)
- Accessory sets / set bonuses
- Item identification / curse mechanic
