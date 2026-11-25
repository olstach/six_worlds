#!/usr/bin/env python3
"""Turn the per-level skill bonus tables in perks.json into formulas.

Before: base_bonuses.<skill> = {"stats": [names], "per_level": {"1": {...}, ...}}
After:  base_bonuses.<skill> = {"stats": {name: spec}}  where a spec is
        {"curve": "climb"|"steady", "at_5": n, "at_10": n,
         "base": n, "integer": true, "limit": n}   (last three only if needed)

The formulas (spec section 10.2) — they MUST match PerkSystem.curve_value():
  climb:  L <= 5 -> at_5 * L(L+1)/30 ;  L > 5 -> at_5 + (at_10-at_5)*(L-5)/5
  steady: base + at_10 * L/10
  integer floors; limit bounds the result toward its own sign.

Re-runnable: a file that is already migrated is left alone (the old tables are
gone, so there is nothing to convert and the report is not rewritten).

Usage:  python3 tools/migrate_skill_curves.py          (writes both files)
"""
import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PERKS = os.path.join(ROOT, "resources", "data", "perks.json")
REPORT = os.path.join(ROOT, "docs", "plans", "SKILL_CURVES_2026-11.md")

# Stats that are counts: they floor to whole numbers. Every one of these has an
# all-whole table (checked below); a stat with whole numbers that is NOT a
# count is not listed, so it stays fractional.
COUNT_STATS = {"party_max_companions", "party_skill_check_bonus",
               "effect_duration_turns"}

# Stats whose value past a bound would invert meaning. Each decision (including
# the "no limit" ones) is explained in the report below.
LIMITS = {"mana_cost_reduction": -100.0}

# Why each non-limited stat has no `limit` (consumer file:line, as read in 2026-11).
# Stats not in this table are plain "more is simply more" gains.
NO_LIMIT_NOTES = {
    "magic_resistance_pct": "scripts/autoload/combat_manager.gd:2896 and scripts/combat/resistance.gd:215 already take minf(value, 90)",
    "mental_resistance_pct": "scripts/combat/save_system.gd:145 adds it to a save roll; more is only better, never inverted",
    "party_poison_disease_resistance_pct": "scripts/autoload/character_system.gd:1421 feeds the summed resistance, which scripts/combat/resistance.gd clamps",
    "party_buy_discount_pct": "scripts/autoload/shop_system.gd:344 -> _get_total_discount() (shop_system.gd:365) caps the whole discount at 50%",
    "party_trading_price_pct": "scripts/autoload/shop_system.gd:345 -> the same 50% cap in _get_total_discount()",
    "party_sell_markup_pct": "scripts/autoload/shop_system.gd:218 is a markup (1 + bonus); it grows, it never inverts",
    "repair_efficiency_pct": "scripts/autoload/camp_system.gd:618 already takes minf(value, 75), and the cost is floored at 1",
    "party_supply_duration_pct": "scripts/autoload/game_state.gd:532 already takes minf(value, 100)",
    "crafting_yield_pct": "scripts/autoload/camp_system.gd:928 reads whole hundreds as extra doses; more is only better",
    "movement_pct": "scripts/autoload/character_system.gd:1430 multiplies by (1 + pct/100); a gain, not a reduction",
    "party_travel_speed_pct": "scripts/autoload/map_manager.gd:763 multiplies by (1 + pct/100); a gain",
    "party_xp_gain_pct": "scripts/autoload/companion_system.gd:507 multiplies by (1 + pct/100); a gain",
    "dodge": "scripts/combat/combat_unit.gd:794 adds to the dodge total; more is only better",
    "armor": "added to the armor total; more is only better",
    "status_effect_chance_pct": "scripts/autoload/combat_manager.gd:7955 adds to a chance that is clamped where it is rolled",
}


def curve_value(spec, level):
    """Python twin of PerkSystem.curve_value (kept in step by hand and by the report)."""
    at_10 = float(spec["at_10"])
    if spec["curve"] == "climb":
        at_5 = float(spec["at_5"])
        if level <= 5:
            v = at_5 * level * (level + 1) / 30.0
        else:
            v = at_5 + (at_10 - at_5) * (level - 5) / 5.0
    else:
        v = float(spec.get("base", 0.0)) + at_10 * level / 10.0
    if spec.get("integer", False):
        v = math.floor(v + 1e-6)
    if "limit" in spec:
        lim = float(spec["limit"])
        v = max(v, lim) if lim < 0 else min(v, lim)
    return float(v)


def fit_integer(vals):
    """Steady line for a count: grid-search base and slope, pin levels 1 and 10."""
    best = None
    for bi in range(-300, 301, 5):            # base -3.00 .. 3.00
        base = bi / 100.0
        for si in range(0, 151):              # slope 0.00 .. 1.50 per level
            at_10 = si / 10.0                 # at_10 = 10 * slope
            spec = {"curve": "steady", "base": base, "at_10": at_10, "integer": True}
            errs = [abs(curve_value(spec, l) - vals[l - 1]) for l in range(1, 11)]
            if errs[0] or errs[9]:
                continue
            key = (max(errs), sum(errs), abs(base), at_10)
            if best is None or key < best[0]:
                best = (key, spec)
    return best[1]


def fit(stat, table):
    """Pick the curve with the smaller max error over levels 1-10."""
    vals = [table[l] for l in range(1, 11)]
    integer = stat in COUNT_STATS
    if integer:
        assert all(float(v).is_integer() for v in vals), stat
    # Candidate A: climb through the table's 5 and 10.
    a = {"curve": "climb", "at_5": vals[4], "at_10": vals[9]}
    if stat in LIMITS:
        # A limit exists so the curve may overshoot it: the old table reached
        # its limit before level 10 (mana: -100 at 9), so aim the line far
        # enough that it crosses the limit at that same level.
        lim = LIMITS[stat]
        first = next(l for l in range(1, 11) if vals[l - 1] == lim)
        if first > 5:
            a["at_10"] = vals[4] + (lim - vals[4]) * 5.0 / (first - 5)
        a["limit"] = lim
    # Candidate B: steady. Counts search `base` and the slope so that levels 1
    # and 10 still match the table, and everything between is as close as the
    # flooring allows (Leadership lands on +1 companion at 3, 6 and 9 exactly).
    if integer:
        b = fit_integer(vals)
        a["integer"] = True
    else:
        b = {"curve": "steady", "at_10": vals[9]}
        if stat in LIMITS:
            b["limit"] = LIMITS[stat]

    def err(spec):
        return max(abs(curve_value(spec, l) - vals[l - 1]) for l in range(1, 11))

    best = a if err(a) <= err(b) else b
    # Clean ints for display: 75.0 -> 75 keeps the JSON readable.
    for k, v in list(best.items()):
        if isinstance(v, float) and v.is_integer():
            best[k] = int(v)
    return best, err(best)


def main():
    with open(PERKS, encoding="utf-8") as f:
        data = json.load(f)
    bb = data["base_bonuses"]
    rows = []        # (skill, stat, old table, spec, err)
    migrated = 0
    for skill, tbl in bb.items():
        if skill.startswith("_"):
            continue  # "_comment" dividers are strings, not tables
        if "per_level" not in tbl:
            continue  # already migrated
        per_level = {int(l): v for l, v in tbl["per_level"].items()}
        stats = {}
        for stat in tbl["stats"]:
            table = {l: per_level[l][stat] for l in per_level}
            spec, err = fit(stat, table)
            stats[stat] = spec
            rows.append((skill, stat, table, spec, err))
        tbl["stats"] = stats
        del tbl["per_level"]
        migrated += 1

    if migrated == 0:
        print("Already migrated; nothing to do.")
        return

    with open(PERKS, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    write_report(rows)
    print("Migrated %d skills, %d stats. Report: %s" % (migrated, len(rows), REPORT))


def fmt(v):
    return ("%g" % round(v, 2)) if v is not None else "-"


def write_report(rows):
    shown = (1, 3, 5, 7, 10)
    out = []
    out.append("# Skill bonus curves (2026-11)\n")
    out.append("Generated by `tools/migrate_skill_curves.py`. Each skill stat used to be a "
               "15-entry table (levels 11-15 repeated level 10). It is now a formula that "
               "keeps going: `PerkSystem.curve_value(spec, level)`.\n")
    out.append("- climb: L <= 5 -> `at_5 * L(L+1)/30`; L > 5 -> `at_5 + (at_10 - at_5) * (L-5)/5`")
    out.append("- steady: `base + at_10 * L/10`")
    out.append("- `integer` floors; `limit` bounds the result toward its own sign; no other cap.\n")
    out.append("The curve for each stat is whichever of climb/steady has the smaller maximum error "
               "over levels 1-10. `at_5` / `at_10` are the old table's values at 5 and 10, with two exceptions: `mana_cost_reduction` aims at -106.25 so the line reaches its -100 limit at level 9 as the old table did, and integer counts fit `base` and slope by search (levels 1 and 10 pinned).\n")

    worst = max(rows, key=lambda r: r[4])
    out.append("**Largest difference over levels 1-10:** `%s.%s` (curve `%s`), off by %s.\n"
               % (worst[0], worst[1], worst[3]["curve"], fmt(worst[4])))

    ints = sorted({r[1] for r in rows if r[3].get("integer")})
    out.append("## Integer stats (floored)\n")
    out.append(", ".join("`%s`" % s for s in ints) + ". These are counts; for them `base` is fitted "
               "so levels 1 and 10 match the table. Every one had an all-whole table.\n")

    out.append("## Limits considered\n")
    out.append("| stat | decision | consumer |\n|---|---|---|")
    seen = set()
    for _, stat, _, _, _ in rows:
        if stat in seen:
            continue
        seen.add(stat)
        if stat in LIMITS:
            out.append("| `%s` | `limit: %g` (floor) | `scripts/autoload/combat_manager.gd:3906` "
                       "reads it as a reduction; below -100 the cost would go negative |"
                       % (stat, LIMITS[stat]))
        else:
            note = NO_LIMIT_NOTES.get(stat, "a plain gain or chance; nothing inverts past 100")
            out.append("| `%s` | no limit | %s |" % (stat, note))
    out.append("")

    out.append("## Every skill.stat\n")
    out.append("Cells are `old -> new`. A `*` marks the cell where the difference is largest "
               "for that stat. Levels 15 and 20 are new values only (the old table stopped at 10).\n")
    out.append("| skill.stat | curve | " + " | ".join("L%d" % l for l in shown) + " | L15 | L20 |")
    out.append("|---|---|" + "---|" * (len(shown) + 2))
    for skill, stat, table, spec, err in rows:
        cells = []
        diffs = [abs(curve_value(spec, l) - table[l]) for l in shown]
        top = max(diffs)
        for l, d in zip(shown, diffs):
            mark = "*" if top > 0.005 and d == top else ""
            cells.append("%s -> %s%s" % (fmt(table[l]), fmt(curve_value(spec, l)), mark))
        out.append("| %s.%s | %s | %s | %s | %s |" % (
            skill, stat, spec["curve"], " | ".join(cells),
            fmt(curve_value(spec, 15)), fmt(curve_value(spec, 20))))
    out.append("")
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    with open(REPORT, "w", encoding="utf-8") as f:
        f.write("\n".join(out))


if __name__ == "__main__":
    main()
