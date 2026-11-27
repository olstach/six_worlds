#!/usr/bin/env python3
"""Turn every aura and zone payload into an effect (stage 2b, Task 8).

Before: auras.json and zones.json had their own little language, the payload
    {"kind": "stat", "stat": "accuracy", "amount": -10}
read by AuraSystem and CombatManager._apply_aura_payload. After: the same
effect language spells and statuses use,
    {"op": "modify", "value": "stat.accuracy", "mode": "drain", "amount": 10}
in lists named for WHEN they happen:
    auras   while_inside                     (modifies are read where they
                                              apply; the rest fire each turn)
    zones   while_inside, on_enter, turn_start_inside, turn_end_inside,
            on_death_inside

Kind by kind (today's numbers, unchanged):
    stat              modify stat.<stat>        fortify / drain by the sign
    stat_pct          modify stat.<stat>        amount {pct_of: target.<stat>, value}
    max_hp            modify stat.max_hp        fortify / drain
    resistance        modify resist.<type>      fortify / drain (afflictions too)
    damage_taken_pct  modify stat.<kind>_damage_taken  multiply (1 + amount/100),
                      one per kind when no `only` narrows it, because the old
                      payloads multiplied together and `multiply` holds do too
    grant_status      status apply, with `if: [{target_lacks: <status>}]` (the
                      old applier skipped anyone who already had it), chance
                      0..1 -> 0..100, save {attribute, dc, dc_drop_per_pass}
                      -> {stat, dc, dc_drop_per_pass}
    heal              heal
    damage            damage, `element` -> `type`
    raise             summon `as` <summon>, `from: corpse`, owner from `for`

A zone payload's own `affects` becomes the effect's `to` (allies_in_area,
enemies_in_area, all_in_area), judged by the zone owner's team. When every
payload of a zone names the same audience, it moves up to the zone's own
`affects` instead, which says the same thing once.

A status's `aura_value` becomes `{from: status.value, default: <the number>}`
on the aura's effects, and the key leaves the status. That is only done where
the number equals the aura's own (it is today for the one status that has
one); anything else stops the script, because it needs a person.

Re-runnable: a file already in the effect shape is left as it is. Writes in
place. Run from the project root:  python3 tools/migrate_auras_zones.py
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AURAS = os.path.join(ROOT, "resources/data/auras.json")
ZONES = os.path.join(ROOT, "resources/data/zones.json")
STATUSES = os.path.join(ROOT, "resources/data/statuses.json")

ZONE_TRIGGERS = ["while_inside", "on_enter", "turn_start_inside",
                 "turn_end_inside", "on_death_inside"]
TO_FOR_AFFECTS = {"allies": "allies_in_area", "enemies": "enemies_in_area",
                  "all": "all_in_area"}


def _num(x):
    """An int when the number is whole, so 35.0 is written 35."""
    x = round(float(x), 6)
    return int(x) if x == int(x) else x


def _signed_modify(value, amount):
    amount = _num(amount)
    if isinstance(amount, (int, float)) and amount < 0:
        return {"op": "modify", "value": value, "mode": "drain", "amount": _num(-amount)}
    return {"op": "modify", "value": value, "mode": "fortify", "amount": amount}


def convert_payload(p, where):
    """One old payload -> a list of effects (damage_taken_pct may need two)."""
    kind = p.get("kind")
    if kind == "stat":
        return [_signed_modify("stat." + p["stat"], p["amount"])]
    if kind == "stat_pct":
        e = _signed_modify("stat." + p["stat"], p["amount"])
        e["amount"] = {"pct_of": "target." + p["stat"], "value": e["amount"]}
        return [e]
    if kind == "max_hp":
        return [_signed_modify("stat.max_hp", p["amount"])]
    if kind == "resistance":
        return [_signed_modify("resist." + p["type"], p["amount"])]
    if kind == "damage_taken_pct":
        factor = _num(1.0 + float(p["amount"]) / 100.0)
        kinds = [p["only"]] if p.get("only") else ["magic", "physical"]
        return [{"op": "modify", "value": "stat.%s_damage_taken" % k,
                 "mode": "multiply", "amount": factor} for k in kinds]
    if kind == "grant_status":
        e = {"op": "status", "action": "apply", "status": p["status"],
             "duration": p.get("duration", 2),
             "if": [{"target_lacks": p["status"]}]}
        if "chance" in p and float(p["chance"]) < 1.0:
            e["chance"] = _num(float(p["chance"]) * 100.0)
        if "save" in p:
            s = p["save"]
            save = {"stat": s.get("attribute", "focus"), "dc": s.get("dc", 12)}
            if "dc_drop_per_pass" in s:
                save["dc_drop_per_pass"] = s["dc_drop_per_pass"]
            e["save"] = save
        return [e]
    if kind == "heal":
        return [{"op": "heal", "amount": _num(p["amount"])}]
    if kind == "damage":
        return [{"op": "damage", "amount": _num(p["amount"]),
                 "type": p.get("element", "physical")}]
    if kind == "raise":
        e = {"op": "summon", "as": p.get("summon", "Zombie"), "from": "corpse"}
        if p.get("for", "caster") != "caster":
            e["owner"] = "target"
        return [e]
    sys.exit(f"{where}: payload kind '{kind}' has no op; map it by hand")


def migrate_auras(data):
    changed = False
    for aid, a in data["auras"].items():
        if aid.startswith("_") or "payloads" not in a:
            continue
        effects = []
        for i, p in enumerate(a.pop("payloads")):
            effects.extend(convert_payload(p, f"auras.{aid}.payloads[{i}]"))
        a["while_inside"] = effects
        changed = True
    return changed


def migrate_zones(data):
    changed = False
    for zid, z in data["zones"].items():
        if zid.startswith("_"):
            continue
        payloads = [p for t in ZONE_TRIGGERS for p in z.get(t, [])
                    if isinstance(p, dict) and "kind" in p]
        if not payloads:
            continue
        audiences = {p.get("affects", z.get("affects", "all")) for p in payloads}
        hoist = len(audiences) == 1
        if hoist:
            z["affects"] = audiences.pop()
        for t in ZONE_TRIGGERS:
            if t not in z:
                continue
            effects = []
            for i, p in enumerate(z[t]):
                for e in convert_payload(p, f"zones.{zid}.{t}[{i}]"):
                    if not hoist and "affects" in p:
                        if e["op"] == "summon":
                            sys.exit(f"zones.{zid}: a summon cannot carry its own "
                                     "audience; give the zone one `affects`")
                        e["to"] = TO_FOR_AFFECTS[p["affects"]]
                    effects.append(e)
            z[t] = effects
        changed = True
    return changed


def migrate_aura_values(statuses, auras):
    """A status's aura_value -> {from: status.value, default: n} on its auras."""
    changed = False
    for s in statuses["statuses"]:
        if "aura_value" not in s:
            continue
        value = s.pop("aura_value")
        ids = s.get("aura", [])
        ids = [ids] if isinstance(ids, str) else ids
        for aid in ids:
            for e in auras["auras"][aid].get("while_inside", []):
                amount = e.get("amount")
                if isinstance(amount, dict):
                    continue   # already borrowed
                if not isinstance(amount, (int, float)):
                    continue
                if _num(amount) != _num(value):
                    sys.exit(f"status {s['name']}: aura_value {value} differs from "
                             f"aura {aid}'s {amount}; decide by hand")
                e["amount"] = {"from": "status.value", "default": _num(value)}
        changed = True
    return changed


AURA_COMMENTS = {
    "_comment": "Aura definitions. An aura is a field around a unit that affects other units by proximity. Any source may declare one with an `aura` key naming an id here: an item (passive_aura), a status (aura), a perk (aura), or a spell/active skill (aura, which applies its carrier status). What it does is a list of effects in the shared effect language, under `while_inside`: a `modify` is READ wherever the number is used (ValuePaths, Resistance), so walking out of the aura ends it with nothing to undo; every other effect fires once on the emitter's turn, through EffectResolver. An item may override the aura's flat numbers with `aura_value` (signed: a negative one drains). A status's own value reaches an effect through {\"from\": \"status.value\"}. Resolution lives in scripts/combat/aura_system.gd; EffectVocab.validate_aura checks every definition.",
    "_comment_radius": "Radius is in grid tiles, Chebyshev distance, and never includes the emitter unless `affects` is 'self' or `self_included` is true.",
    "_comment_affects": "allies | enemies | all | self. `invert_for_enemies` flips the sign of every number for units on the other team (a multiply of 0.8 becomes 1.2), which is how one declaration expresses 'helps my side, hurts theirs'. The aura's effects carry no `to` of their own: who they reach is the aura's question.",
    "_comment_immune_system": "Immune System guards against three afflictions — things that happen to you rather than things that hit you — with `resist.poison`, `resist.bleed` and `resist.disease`. Its 15 reads as a 15% chance not to catch them (Resistance.resists_affliction) and, for poison, 15% off poison damage too (Resistance.total).",
    "_comment_shield_wall": "Shield Wall is two auras on one status (Shield_Wall), because the wall and its cover want different amounts. The amount is {pct_of: target.armor, value: 25}: a percentage of the receiving unit's OWN sheet Armor - +25% of your Armor, +10% of each adjacent ally's - which a flat number cannot express.",
}

ZONE_COMMENTS = {
    "_comment": "Zones: areas that do something to whoever is in them, anchored to the ground rather than to a unit. What they do is written in the shared effect language, the same as auras, spells and statuses, because a zone is an aura with a place instead of a body. The effects run through EffectResolver with the zone's owner as the caster and the zone tile as the position; EffectVocab.validate_zone checks every definition.",
    "_comment_triggers": "`while_inside`: a `modify` is read wherever the number is used, for as long as a unit stands in the zone; every other effect fires each round on everyone standing in it. `on_enter` fires once on a unit that steps in. `turn_start_inside` and `turn_end_inside` fire at the start or end of the turn of a unit standing in it. `on_death_inside` fires when a unit dies on its ground. The zone's `affects` says who it reaches; an effect's own `to` (allies_in_area, enemies_in_area, all_in_area, judged by the owner's team) overrides it, because a zone often wants both at once.",
    "_comment_footprint": "The tiles come from the casting spell's `aoe` block, so every shape AoEResolver knows — circle, arc, cone, line, cross, band — is available to a zone without naming any of them here.",
}


def _set_comments(section_parent, comments):
    """Replace the documentation keys, keeping their place in the file."""
    for k, v in comments.items():
        section_parent[k] = v


def _load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _save(path, data, indent):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=indent, ensure_ascii=False)
        f.write("\n")


def main():
    auras = _load(AURAS)
    zones = _load(ZONES)
    statuses = _load(STATUSES)

    a_changed = migrate_auras(auras)
    v_changed = migrate_aura_values(statuses, auras)
    z_changed = migrate_zones(zones)

    if a_changed or v_changed:
        _set_comments(auras, {k: v for k, v in AURA_COMMENTS.items() if k in ("_comment", "_comment_radius", "_comment_affects", "_comment_immune_system")})
        auras["auras"]["_comment_shield_wall"] = AURA_COMMENTS["_comment_shield_wall"]
        _save(AURAS, auras, 2)
    if z_changed:
        _set_comments(zones, ZONE_COMMENTS)
        _save(ZONES, zones, 2)
    if v_changed:
        _save(STATUSES, statuses, "\t")
    print(f"auras: {'migrated' if a_changed else 'already effects'}; "
          f"zones: {'migrated' if z_changed else 'already effects'}; "
          f"status aura_value: {'moved' if v_changed else 'none left'}")


if __name__ == "__main__":
    main()
