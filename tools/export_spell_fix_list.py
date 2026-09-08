#!/usr/bin/env python3
"""Generate docs/review/SPELL_FIXES.md — the per-spell worklist for migrating
`special.legacy` onto the effect registry.

Rerun after any migration: the lists shrink, and a spell drops out of the
document entirely once its `legacy` block is empty. That is the progress bar.

    python3 tools/export_spell_fix_list.py
"""
import json
import collections
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPELLS = os.path.join(ROOT, "resources", "data", "spells.json")
REGISTRY = os.path.join(ROOT, "resources", "data", "spell_effects.json")
OUT = os.path.join(ROOT, "docs", "review", "SPELL_FIXES.md")

# Keys that name a mechanic and can be routed onto a registry type. The value is
# (effect_type, what the migration still needs from Olaf or "" if nothing).
ROUTE = {
    "freeze_chance": ("apply_status", "chance % and which freeze status"),
    "stun_chance": ("apply_status", "chance %"),
    "obstacle_bonus_damage": ("bonus_damage_vs", ""),
    "damage_split": ("note", "damage typing is not modelled — decide if it should be"),
    "push_distance": ("push", ""),
    "pushes_enemies": ("push", "distance"),
    "launches_into_air": ("push", "distance, and whether 'up' differs from 'away'"),
    "teleport_range": ("teleport", ""),
    "heals_all_allies": ("heal", "amount"),
    "heals_allies": ("heal", "amount"),
    "heal_per_turn": ("heal", "amount per turn"),
    "grants_flight": ("apply_status", "there is no Flying status yet"),
    "flying": ("apply_status", "there is no Flying status yet"),
    "casts_black_magic": ("caster_ai", ""),
    "gold_on_kill": ("reward", "amount"),
    "gold_on_break": ("reward", "amount"),
    "gold_scales_with": ("reward", ""),
    "prevents_resurrection": ("prevent", "duration"),
    "dodge_bonus": ("stat_bonus", "amount"),
    "high_dodge": ("stat_bonus", "amount"),
    "initiative_bonus": ("stat_bonus", "amount"),
    "defense_bonus": ("stat_bonus", "amount"),
    "fire_resist_pct": ("resistance", ""),
    "water_resist_pct": ("resistance", ""),
    "fire_vulnerability": ("resistance", "negative resistance — confirm the sign"),
    "bonus_damage_vs_undead_demons": ("bonus_damage_vs", "pct"),
    "bonus_damage_vs_living": ("bonus_damage_vs", "pct"),
    "illusions": ("illusion", "count and hp"),
    "summon_count": ("summon_extra", ""),
    "summon_hp": ("summon_extra", ""),
    "summon_on_trigger": ("summon_extra", "what the trigger is"),
    "cloud_effect": ("ground_effect", "what the cloud does"),
    "dispellable": ("note", "every buff is dispellable — probably delete"),
    "status_scales_with": ("scaling", ""),
    "damages_all_enemies": ("note", "this is targeting, not a special — check the aoe block"),
    "poisons": ("apply_status", "which poison status, chance"),
    "poisons_melee_attackers": ("reflect", "which status, chance"),
    "slows_movement": ("apply_status", "which slow status"),
    "extinguishes_burning": ("remove_status", ""),
    "instant_kill": ("apply_status", "this needs a mechanic, not a flag"),
    "damage_increases_each_turn": ("scaling", "how much per turn, and a cap"),
    "each_effect_independent_chance": ("apply_status", ""),
    "instant_kill_on_failed_save": ("apply_status", "which attribute, and the DC"),
    "walk_on_water": ("immunity", "terrain movement is not modelled"),
    "ignore_water_terrain": ("immunity", "terrain movement is not modelled"),
}

# Keys that describe a vibe, an intensity or a redundancy rather than a mechanic.
# These want a yes/no from Olaf: make it real, or delete it.
# Keys with no mechanic in them at all. Kept separate from PROSE_ONLY only
# because these were spotted during the first audit pass.
FLAVOUR = {
    "creepy_circus_vibe", "high_damage", "considerable_bonus", "gold_dust_falls",
    "erupts_from_ground",
}

# Broad routing. Most legacy keys are one-offs, but their *names* say plainly
# enough which registry type they belong to; what they almost never say is the
# number. Order matters — first match wins.
SUFFIX_RULES = [
    ("_chance", "apply_status", "chance %"),
    ("_resist_pct", "resistance", ""),
    ("_resistance", "resistance", "pct"),
    ("_bonus", "stat_bonus", "amount"),
    ("_buff", "stat_bonus", "which stat, how much"),
    ("_boost", "stat_bonus", "which stat, how much"),
    ("_debuff", "stat_bonus", "which stat, how much (negative)"),
    ("_scales_with", "scaling", ""),
    ("_pct", "stat_bonus", ""),
    ("_count", "summon_extra", "confirm what is being counted"),
]
PREFIX_RULES = [
    ("bonus_damage_vs_", "bonus_damage_vs", "pct"),
    ("bonus_damage_", "bonus_damage_vs", "what tag, and the pct"),
    ("devastating_vs_", "bonus_damage_vs", "pct"),
    ("damage_multiplier_", "bonus_damage_vs", "pct"),
    ("casts_", "caster_ai", ""),
    ("aura", "aura", "radius, and what it grants"),
    ("summon", "summon_extra", "count"),
    ("spawns_", "summon_extra", "template and count"),
    ("constantly_spawns_", "summon_extra", "template and rate"),
    ("prevents_", "prevent", "duration"),
    ("blocks_", "prevent", "duration"),
    ("cannot_", "prevent", "duration"),
    ("heals", "heal", "amount"),
    ("heal_", "heal", "amount"),
    ("gold_", "reward", "amount"),
    ("teleport", "teleport", ""),
    ("blink", "teleport", "range"),
    ("creates_portal", "teleport", "range and duration"),
    ("creates_permanent_portal", "teleport", "this is an overworld effect, not a combat one"),
    ("between_map_locations", "teleport", "this is an overworld effect, not a combat one"),
    ("push", "push", "distance"),
    ("pulls", "push", "distance, direction toward_caster"),
    ("chain", "chain", "count and damage falloff"),
    ("chains_", "chain", "count and damage falloff"),
    ("cleanses", "remove_status", "which statuses"),
    ("can_be_cleansed", "remove_status", "every debuff can — probably delete"),
    ("dispels", "remove_status", "which statuses"),
    ("removes_", "remove_status", "which statuses"),
    ("creates_illusion", "illusion", "count and hp"),
    ("creates_illusory", "illusion", "count and hp"),
    ("copies_", "illusion", "count and hp"),
    ("copy_", "illusion", "count and hp"),
    ("reflect", "reflect", "pct"),
    ("returns_damage", "reflect", "pct"),
    ("lifesteal", "lifesteal", "pct"),
    ("drains_", "lifesteal", "pct, and whether it feeds the caster"),
    ("immune", "immunity", "to what, and for how long"),
    ("caster_immune", "immunity", "to what, and for how long"),
    ("buffs_", "stat_bonus", "which stats, how much"),
    ("debuff", "stat_bonus", "which stats, how much (negative)"),
    ("debuffs_", "stat_bonus", "which stats, how much (negative)"),
    ("terrain", "ground_effect", "what the terrain does, radius, duration"),
    ("enemies_entering", "ground_effect", "what happens on enter"),
    ("enemies_crossing", "ground_effect", "what happens on enter"),
    ("allies_in_area", "aura", "radius, and what it grants"),
    ("allies_inside", "aura", "radius, and what it grants"),
    ("damages_", "ground_effect", "is this the aoe block instead?"),
    ("damage_per_turn", "ground_effect", "amount"),
    ("continuous_damage", "ground_effect", "amount per turn"),
    ("blinds", "apply_status", "which blind status, chance"),
    ("charms", "apply_status", "which charm status, chance"),
    ("dominates", "apply_status", "which status, chance"),
    ("stuns", "apply_status", "chance %"),
    ("freezes", "apply_status", "chance %"),
    ("burns", "apply_status", "chance %"),
    ("applies_", "apply_status", "which status, chance"),
    ("grants_", "apply_status", "which status — check it exists"),
    ("destroys_", "note", "no destruction mechanic exists"),
    ("dies_after", "summon_extra", "duration belongs on the summon, not here"),
]


# Keys that describe the *summoned creature*, not the spell. Every one of these
# sits on a spell with a `summon` block, and every one of them belongs on that
# creature's entry in summon_templates.json instead. Migration here means moving
# the fact, not inventing a number.
SUMMON_FLAVOUR = {
    "man_bird_hybrid", "luminous_humanoid", "powerful_ancestor", "lich_like",
    "rahula_like", "phurba_spirit", "host_of_ancestors", "honored_dead",
    "powerful_outer_being", "powerful_vengeful_spirit", "powerful_fighter",
    "defensive_fighter", "support_fighter", "support_white_mage",
    "support_abilities", "buffed_spirits", "swarm", "tentacles_and_eyes",
    "from_outer_night", "moves_randomly", "moves_slowly", "does_not_fight",
    "draws_attacks", "attack_enemies", "fast", "static", "low_hp", "melee",
    "ranged", "protective", "annoying", "vampiric_attack", "attacks_with",
    "multiple_kinnaras", "multiple_puppets", "multiple_trickster_masks",
    "multiple_daggers", "respects_undead_allies", "fears_strong_undead",
}

# Keys that are targeting or shape, written into the wrong field. `target` and
# `aoe` already model all of this.
BELONGS_ON_TARGETING = {
    "short_range", "medium_range", "long_range", "melee_range", "line_of_sight",
    "ignore_line_of_sight", "ignore_height", "affects_all_enemies",
    "affects_everyone", "affects_party", "allies", "enemies", "explosion_aoe",
    "scatter_range", "self_movement",
}

# Keys that restate the spell's own description and carry nothing the engine
# could act on. The default answer is deletion.
PROSE_ONLY = {
    "creepy_circus_vibe", "dissipates_into_light", "gold_dust_falls",
    "like_lightning_but_black", "white_fire_explosion", "erupts_from_ground",
    "heavy_sinks_to_low_ground", "illusion_of_fear", "obscures_vision",
    "mental_manipulation", "assassin_setup", "associated_with_disease",
    "lays_corpse_to_rest", "speak_with_dead", "gain_information",
    "high_damage", "low_damage", "reliable_damage", "considerable_bonus",
    "less_damage_than_normal_lightning", "short_duration", "long_range",
}


def route(key):
    """-> (effect_type, needs) or (None, None) if nothing sensible suggests itself."""
    if key in ROUTE:
        return ROUTE[key]
    if key in SUMMON_FLAVOUR:
        return ("__summon__", "move it onto the creature in summon_templates.json")
    if key in BELONGS_ON_TARGETING:
        return ("__targeting__", "the `target` / `aoe` blocks already model this")
    if key in PROSE_ONLY or key in FLAVOUR:
        return ("__prose__", "restates the description — delete unless it should be real")
    for suf, typ, needs in SUFFIX_RULES:
        if key.endswith(suf):
            return (typ, needs)
    for pre, typ, needs in PREFIX_RULES:
        if key.startswith(pre):
            return (typ, needs)
    return (None, "unrouted — decide what it means")


def main():
    spells = json.load(open(SPELLS, encoding="utf-8"))["spells"]
    registry = json.load(open(REGISTRY, encoding="utf-8"))

    work = {}
    for sid, s in sorted(spells.items()):
        legacy = (s.get("special") or {}).get("legacy") or {}
        if legacy:
            work[sid] = (s, legacy)

    # Bucket each spell by the hardest thing any of its keys needs.
    PSEUDO = {"__summon__", "__targeting__", "__prose__"}
    mechanical, misplaced, needs_number, needs_meaning = [], [], [], []
    for sid, (s, legacy) in work.items():
        rows = []
        hardest = 0
        for k, v in sorted(legacy.items()):
            typ, needs = route(k)
            if typ and typ not in PSEUDO and v is not True and not needs:
                rank = 0          # migratable as-is
            elif typ in PSEUDO:
                rank = 1          # the fact is fine, it is filed in the wrong place
            elif typ:
                rank = 2          # routed, but the number was never written down
            else:
                rank = 3          # nobody has decided what it means
            hardest = max(hardest, rank)
            rows.append((k, v, typ, needs, rank))
        entry = (sid, s, rows)
        [mechanical, misplaced, needs_number, needs_meaning][hardest].append(entry)

    key_uses = collections.Counter()
    for sid, (s, legacy) in work.items():
        for k in legacy:
            key_uses[k] += 1

    L = []
    w = L.append
    w("<!-- Generated by tools/export_spell_fix_list.py — rerun it, do not hand-edit. -->")
    w("")
    w("# Spells still to fix")
    w("")
    w("Every spell below still carries keys in `special.legacy`. A spell leaves this")
    w("document when that block is empty, so the counts are the progress bar.")
    w("")
    w("The registry is `resources/data/spell_effects.json`; `validate_data.py` enforces")
    w("it. Migrating a spell means moving each legacy key into `special.effects` as a")
    w("typed entry and deleting it from `legacy` **and** from the frozen list in the")
    w("registry — the frozen list may shrink and must never grow.")
    w("")
    w("## The shape of the job")
    w("")
    w("| Batch | Spells | What it needs |")
    w("|---|---:|---|")
    w(f"| A — mechanical | {len(mechanical)} | Every key routes to a type and already carries its value. No decisions. |")
    w(f"| B — filed in the wrong place | {len(misplaced)} | The fact is fine; it belongs on the summon template, the targeting block, or nowhere. |")
    w(f"| C — needs a number | {len(needs_number)} | The key names a real mechanic and was written as bare `true`. Someone picks the number. |")
    w(f"| D — needs a decision | {len(needs_meaning)} | No registry type fits. What should the spell actually do? |")
    w(f"| **total** | **{len(work)}** | of {len(spells)} spells |")
    w("")
    w("**Do them in that order.** A and B are mechanical and shrink the list fast; C is")
    w("far fewer decisions than it looks because the keys repeat — answer `freeze_chance`")
    w("once and eight spells migrate. D is the genuinely new design work and it is worth")
    w("asking, spell by spell, whether the spell needs the mechanic at all.")
    w("")
    w("### Keys used by more than one spell")
    w("")
    w("Every answer here migrates several spells at once. Work this table before the")
    w("per-spell lists.")
    w("")
    w("| Key | Spells | Routes to | Decision |")
    w("|---|---:|---|---|")
    for k, c in key_uses.most_common():
        if c < 2:
            continue
        typ, needs = route(k)
        if not needs:
            continue
        label = {"__summon__": "summon template", "__targeting__": "targeting block",
                 "__prose__": "delete"}.get(typ, ("`" + typ + "`") if typ else "—")
        w(f"| `{k}` | {c} | {label} | {needs} |")
    w("")

    def dump(title, entries, blurb):
        w("")
        w(f"## {title}")
        w("")
        w(blurb)
        w("")
        for sid, s, rows in entries:
            schools = "/".join(s.get("schools", []))
            w(f"### `{sid}` — {s.get('name', sid)}")
            w("")
            w(f"{schools} L{s.get('level')} · {s.get('mana_cost')} mana · "
              f"{s.get('description', '').rstrip('.')}")
            w("")
            for k, v, typ, needs, rank in rows:
                val = "" if v is True else f" = `{json.dumps(v, ensure_ascii=False)}`"
                label = {"__summon__": "**summon template**",
                         "__targeting__": "**targeting block**",
                         "__prose__": "**delete**"}.get(typ)
                dest = label if label else (f"→ `{typ}`" if typ else "→ **?**")
                tail = f" — {needs}" if needs else ""
                w(f"- `{k}`{val} {dest}{tail}")
            w("")

    dump("Batch A — mechanical, no decisions needed", mechanical,
         "Every key here routes onto a registry type and already carries the value that "
         "type wants. These can be migrated in one pass without asking anyone anything.")
    dump("Batch B — the fact is right, the field is wrong", misplaced,
         "Nothing here needs inventing. These keys describe the summoned creature (which "
         "belongs on its entry in `summon_templates.json`), or the spell's range and shape "
         "(which `target` and `aoe` already model), or they restate the description in "
         "snake_case and carry nothing the engine could act on — those just go.")
    dump("Batch C — a real mechanic missing its number", needs_number,
         "The key names something the game could do; it was written as a bare `true`, so "
         "migrating it means choosing the number it never carried. Work the recurring-key "
         "table above first — most of these fall out of a handful of answers.")
    w("")
    w("### What batch D is telling us")
    w("")
    w("Reading the unrouted keys together, they are not 90 unrelated ideas. Four")
    w("clusters account for most of them, and each is one missing registry type:")
    w("")
    w("1. **A trigger wrapper.** `triggers_on`, `triggers_when_ally_dies`,")
    w("   `when_target_dies`, `if_kills_chain_to_next_target`, `if_kills_raise_as_zombie`,")
    w("   `on_success`, `melee_counter_burn`, `breaks_on_offensive_action`,")
    w("   `consumed_on_hit`. The registry has no way to say *when* an effect fires. This")
    w("   is the single biggest gap and probably wants a `when` param on every effect")
    w("   rather than a type of its own.")
    w("2. **Damage typing.** `white_damage`, `adds_air_damage`, `damage_split`,")
    w("   `non_physical_damage_only`, `cannot_deal_physical`. Damage currently has no")
    w("   element attached to it at all. That is a combat-system decision, not a spell one.")
    w("3. **Shields and absorbs.** `hp_shield`, `physical_immunity`,")
    w("   `physical_negation_25_percent`, `spell_damage_reduction`,")
    w("   `ranged_damage_reduction`, `must_destroy_before_damage`. All want one")
    w("   `damage_reduction` or `shield` type with a source filter.")
    w("4. **Resurrection.** `resurrects_with_1hp`, `resurrects_with_full_hp`,")
    w("   `resurrects_all_fallen_allies`, `partial_hp_on_resurrect`, `rise_as_zombie`,")
    w("   `return_next_turn`, `return_with_20_percent_hp`. One `resurrect` type with an")
    w("   hp param covers every one.")
    w("")
    w("The remainder are genuinely one-off and several should probably just be cut.")
    w("")
    dump("Batch D — no registry type fits", needs_meaning,
         "These are the ones worth talking through. Some want a new effect type in the "
         "registry (`hp_shield`, `stops_time`, `resurrects_*`, the several `spreads_to_*` "
         "keys). Some describe a mechanic the game does not have and may not want. Some "
         "are one spell's private idea. For each: new effect type, existing type with a "
         "stretch, or cut it.")
    w("")
    w("---")
    w("")
    w(f"Registry: {len(registry['effects'])} effect types, "
      f"{sum(1 for e in registry['effects'].values() if e['implemented'])} implemented. "
      f"Frozen legacy list: {len(registry['legacy_keys'])} keys.")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(L) + "\n")
    print(f"wrote {OUT}")
    print(f"  A mechanical      {len(mechanical):4}")
    print(f"  B wrong field     {len(misplaced):4}")
    print(f"  C needs number    {len(needs_number):4}")
    print(f"  D needs decision  {len(needs_meaning):4}")
    print(f"  total           {len(work):4}")


if __name__ == "__main__":
    main()
