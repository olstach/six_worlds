#!/usr/bin/env python3
"""Export the writable content as Markdown for Olaf to read and edit.

Every editable string sits between HTML-comment anchors that name its exact
JSON path:

    <!--@ hell_events.json | hell_bone_arena | text -->
    A frozen pit ringed with bones …
    <!--@end-->

The anchors do not render, so the documents read as prose. `import_review_docs.py`
reads them back and writes the edits into the JSON, so nothing has to be
re-keyed by hand.

Rules for editing:
  - Change anything between an anchor and its `@end`. Blank lines are fine.
  - Do not edit the anchor lines themselves, or the ids in headings.
  - Anything outside the anchors (headings, mechanical notes, tables) is
    generated and will be regenerated — edits there are lost.

Content added during the 2026-07-27 sessions is marked **NEW**, so a file that
has already had a pass only needs its new parts read.
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs/review")
# Optional snapshot of the data as it was before a writing session, used only to
# mark content as NEW. Absent by default — set REVIEW_BASE_SNAPSHOT to a directory
# of JSON files to turn the NEW markers back on.
BASE_SNAPSHOT = os.environ.get("REVIEW_BASE_SNAPSHOT", "")

REALMS = [
    ("hell_events.json", "EVENTS_HELL.md", "Hell"),
    ("hungry_ghost_events.json", "EVENTS_HUNGRY_GHOST.md", "Hungry Ghost"),
    ("animal_events.json", "EVENTS_ANIMAL.md", "Animal"),
    ("domain_events.json", "EVENTS_DOMAIN.md", "Cross-realm (domain, camp, trait, relationship)"),
]

CHOICE_LABEL = {"default": "grey", "requirement": "blue", "roll": "yellow"}


def anchor(path_parts, text):
    """Wrap an editable string in its path anchor."""
    key = " | ".join(str(p) for p in path_parts)
    body = (text or "").rstrip()
    return f"<!--@ {key} -->\n{body}\n<!--@end-->\n"


def load(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return json.load(f)


def load_base(name):
    if not BASE_SNAPSHOT:
        return None
    p = os.path.join(BASE_SNAPSHOT, name)
    if not os.path.exists(p):
        return None
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def reward_line(rewards):
    """One-line mechanical summary, so the writer can see what a choice pays."""
    if not rewards:
        return ""
    bits = []
    for k in ("xp", "gold", "items", "supplies", "restore", "hp_loss",
              "learn_spell", "skill_up", "buffs", "flags", "wound",
              "add_trait", "remove_trait", "add_traits", "remove_traits",
              "pressure", "gamble", "attribute_loss", "gold_returned"):
        if k in rewards:
            v = rewards[k]
            if k == "pressure":
                v = ", ".join(f"{p.get('element')}{p.get('amount'):+g}"
                              for p in (v if isinstance(v, list) else [v])
                              if isinstance(p, dict))
            bits.append(f"{k}: {v}")
    return "  ·  ".join(bits)


def req_line(reqs):
    if not reqs:
        return ""
    bits = []
    if "trait" in reqs:
        bits.append(f"**trait: {reqs['trait']}**")
    if "not_trait" in reqs:
        bits.append(f"**not_trait: {reqs['not_trait']}**")
    for s, lv in reqs.get("skills", {}).items():
        bits.append(f"{s} {lv}")
    for a, lv in reqs.get("attributes", {}).items():
        bits.append(f"{a} {lv}")
    if "roll" in reqs:
        r = reqs["roll"]
        bits.append(f"roll {r.get('attribute') or r.get('skill')} vs {r.get('difficulty')}")
    return ", ".join(bits)


def export_events(src, outfile, title):
    data = load("resources/data/events/" + src)
    events = data["events"]
    base = load_base(src.replace("_events.json", "") + ".json")
    base_events = (base or {}).get("events", {})
    # Without a base snapshot there is nothing to compare against, so nothing is
    # marked rather than everything being marked new.
    mark_new = base is not None

    new_events = [e for e in events if e not in base_events] if mark_new else []
    intro = (f"{len(new_events)} added since the base snapshot, marked **NEW EVENT**. "
             "Individual choices added to an older event are marked **NEW**."
             if mark_new else
             "No base snapshot is set, so nothing is marked as new — see the header of "
             "`export_review_docs.py` for how to turn the NEW markers back on.")
    lines = [f"# {title} — Events\n",
             f"*{len(events)} events. {intro}*\n",
             "*Edit the prose between the anchors. Headings, ids and the mechanical "
             "lines under each choice are generated — edits there are lost.*\n",
             "---\n"]

    for eid, e in events.items():
        if not isinstance(e, dict):
            continue
        is_new_event = mark_new and eid not in base_events
        old_choice_ids = set()
        if mark_new and not is_new_event and eid in base_events:
            old_choice_ids = {c.get("id") for c in base_events[eid].get("choices", [])
                              if isinstance(c, dict)}

        flag = "  **NEW EVENT**" if is_new_event else ""
        lines.append(f"## {eid}{flag}\n")
        meta = [f"realm: {e.get('realm', '?')}"]
        for k in ("zone", "trigger", "requires_trait", "requires_band", "rarity"):
            if e.get(k):
                meta.append(f"{k}: {e[k]}")
        lines.append("`" + "  ·  ".join(meta) + "`\n")

        lines.append("**Title**\n")
        lines.append(anchor([src, eid, "title"], e.get("title", "")))

        body_key = "text" if "text" in e else "description"
        lines.append("\n**Body**\n")
        lines.append(anchor([src, eid, body_key], e.get(body_key, "")))

        choices = [c for c in e.get("choices", []) if isinstance(c, dict)]
        if choices:
            lines.append("\n### Choices\n")
        for i, c in enumerate(choices):
            # 72 choices in the location events carry no id. Anchor those by
            # index so their prose is still editable and importable.
            cid = c.get("id") or f"[{i}]"
            new = "  **NEW**" if (mark_new and not is_new_event and cid not in old_choice_ids) else ""
            colour = CHOICE_LABEL.get(c.get("type", "default"), c.get("type", ""))
            req = req_line(c.get("requirements", {}))
            head = f"**{cid}** — *{colour}*"
            if req:
                head += f" — requires {req}"
            lines.append(f"\n#### {head}{new}\n")
            lines.append(anchor([src, eid, f"choices.{cid}.text"], c.get("text", "")))

            for branch, label in (("outcome", "Outcome"),
                                  ("outcome_success", "Outcome — success"),
                                  ("outcome_failure", "Outcome — failure")):
                o = c.get(branch)
                if not isinstance(o, dict):
                    continue
                lines.append(f"\n*{label}*")
                mech = []
                if o.get("type") and o["type"] != "text":
                    mech.append(f"type: {o['type']}")
                for k in ("enemy_group", "difficulty", "shop_id", "companion_id",
                          "follow_up_event", "defeat_boss"):
                    if o.get(k):
                        mech.append(f"{k}: {o[k]}")
                if o.get("karma"):
                    mech.append("karma: " + ", ".join(f"{r}{v:+g}" for r, v in o["karma"].items()))
                rl = reward_line(o.get("rewards", {}))
                if rl:
                    mech.append(rl)
                if mech:
                    lines.append(f"\n`{'  ·  '.join(mech)}`\n")
                else:
                    lines.append("\n")
                lines.append(anchor([src, eid, f"choices.{cid}.{branch}.text"], o.get("text", "")))
        lines.append("\n---\n")

    write(outfile, "\n".join(lines))
    return len(events), len(new_events)


def export_animal_companions():
    data = load("resources/data/companions.json")["companions"]
    comps = data if isinstance(data, dict) else {c["id"]: c for c in data}
    base = load_base("companions.json")
    base_comps = {}
    if base:
        bc = base["companions"]
        base_comps = bc if isinstance(bc, dict) else {c["id"]: c for c in bc}

    animal = {k: v for k, v in comps.items()
              if isinstance(v, dict) and v.get("realm") == "animal"}
    lines = ["# Animal Realm — Companions\n",
             f"*{len(animal)} companions.*\n",
             "*Edit the prose between the anchors. The stat block under each name is "
             "generated; change it in `companions.json` instead.*\n", "---\n"]

    by_zone = {}
    for cid, c in animal.items():
        by_zone.setdefault(c.get("zone", "unzoned"), []).append((cid, c))

    for zone in sorted(by_zone):
        lines.append(f"\n# Zone: {zone}\n")
        for cid, c in sorted(by_zone[zone]):
            new = "  **NEW**" if base is not None and cid not in base_comps else ""
            lines.append(f"\n## {c.get('name', cid)}  `{cid}`{new}\n")
            stat = [f"birth: {c.get('birth', '?')}",
                    f"background: {c.get('background', '?')}"]
            if c.get("traits"):
                stat.append("traits: " + ", ".join(c["traits"]))
            if c.get("recruitment_cost") is not None:
                stat.append(f"cost: {c['recruitment_cost']}")
            for k in ("fixed_items", "known_spells"):
                if c.get(k):
                    stat.append(f"{k}: {c[k]}")
            lines.append("`" + "  ·  ".join(str(s) for s in stat) + "`\n")

            # Skills the companion develops into, strongest first. Editable:
            # the importer rewrites build_weights from this list, weighting
            # 5/4/3/2 down the order, and leaves it alone if the list is unchanged.
            bw = c.get("build_weights", {})
            ordered = [k for k, _ in sorted(bw.items(), key=lambda kv: -kv[1])]
            lines.append("\n**Skills** *(strongest first)*\n")
            lines.append(anchor(["companions.json", cid, "build_weights"],
                                ", ".join(ordered)))
            for field in ("flavor_text", "description", "recruitment_text"):
                if field in c:
                    lines.append(f"\n**{field.replace('_', ' ').title()}**\n")
                    lines.append(anchor(["companions.json", cid, field], c[field]))
        lines.append("\n---\n")

    write("ANIMAL_COMPANIONS.md", "\n".join(lines))
    return len(animal)


def export_traits():
    tr = load("resources/data/traits.json")
    traits = {k: v for k, v in tr.items() if isinstance(v, dict) and not k.startswith("_")}
    comps = load("resources/data/companions.json")["companions"]
    comps = list(comps.values()) if isinstance(comps, dict) else comps
    freq = {}
    for c in comps:
        if isinstance(c, dict):
            for t in c.get("traits", []):
                freq[t] = freq.get(t, 0) + 1

    order = ["physical", "personality", "behavioral", "acquired", "racial"]
    lines = ["# Traits\n",
             f"*{len(traits)} traits. The player rolls one inborn **physical**, one "
             "**personality** and one **behavioral** at creation; **acquired** ones are "
             "earned during a run; **racial** ones come with the birth.*\n",
             "*`pressure` shifts the emotional baseline that decay pulls toward: negative "
             "is toward that element's klesha, positive toward its wisdom. `bond` tags are "
             "what RelationshipSystem scores party rapport on.*\n",
             "*Edit names and descriptions between the anchors. The mechanical line is "
             "generated — change it in `traits.json`.*\n", "---\n"]

    for cat in order:
        group = {k: v for k, v in traits.items() if v.get("category") == cat}
        if not group:
            continue
        lines.append(f"\n# {cat.title()}  ({len(group)})\n")
        for tid, t in sorted(group.items()):
            on_comps = freq.get(tid, 0)
            lines.append(f"\n## {tid}\n")
            mech = []
            if t.get("stat_modifiers"):
                mech.append("stats: " + ", ".join(f"{k}{v:+d}" for k, v in t["stat_modifiers"].items()))
            if t.get("skill_modifiers"):
                mech.append("skills: " + ", ".join(f"{k}{v:+d}" for k, v in t["skill_modifiers"].items()))
            if t.get("pressure_modifiers"):
                mech.append("pressure: " + ", ".join(f"{k}{v:+g}" for k, v in t["pressure_modifiers"].items()))
            if t.get("bond_tags"):
                mech.append("bond: " + ", ".join(t["bond_tags"]))
            if t.get("opposed_traits"):
                mech.append("opposed: " + ", ".join(t["opposed_traits"]))
            if t.get("purgeable_by"):
                mech.append(f"purged by {', '.join(t['purgeable_by'])} {t.get('purge_difficulty', 0)}")
            mech.append(f"on {on_comps} companions")
            lines.append("`" + "  ·  ".join(mech) + "`\n")
            lines.append("**Name**\n")
            lines.append(anchor(["traits.json", tid, "name"], t.get("name", "")))
            lines.append("\n**Description**\n")
            lines.append(anchor(["traits.json", tid, "description"], t.get("description", "")))
        lines.append("\n---\n")

    write("TRAITS.md", "\n".join(lines))
    return len(traits)


# ---------------------------------------------------------------------------
# Animal realm — everything outside the companions and the events.
#
# These five documents cover the realm's remaining prose: the births and their
# backgrounds, the bestiary, the places you can walk into, the map itself, and
# the naming lore. Same anchor contract as the rest of the file.
# ---------------------------------------------------------------------------

def _is_record(v):
    return isinstance(v, dict)


def _animal_races(d):
    return {k: v for k, v in d["races"].items()
            if _is_record(v) and v.get("realm") == "animal"}


def export_animal_races():
    d = load("resources/data/races.json")
    races = _animal_races(d)
    backgrounds = {k: v for k, v in d["backgrounds"].items() if _is_record(v)}

    lines = ["# Animal Realm — Births and Backgrounds\n",
             f"*{len(races)} births. A birth is what you were reborn as; a background is "
             "what you did with it. Both descriptions are read at character creation.*\n",
             "*Edit the prose between the anchors. The stat line under each name is "
             "generated — change it in `races.json`.*\n", "---\n"]

    for rid, r in sorted(races.items()):
        lines.append(f"\n## {r.get('name', rid)}  `{rid}`\n")
        mech = []
        mods = {k: v for k, v in r.get("attribute_modifiers", {}).items() if v}
        if mods:
            mech.append("attributes: " + ", ".join(f"{k}{v:+d}" for k, v in mods.items()))
        if r.get("starting_skills"):
            mech.append("skills: " + ", ".join(f"{k} {v}" for k, v in r["starting_skills"].items()))
        if r.get("starting_traits"):
            mech.append("traits: " + ", ".join(r["starting_traits"]))
        if r.get("resistances"):
            mech.append("resists: " + ", ".join(f"{k} {v}%" for k, v in r["resistances"].items()))
        if r.get("body_plan_species"):
            mech.append("body: " + r["body_plan_species"])
        mech.append(f"reincarnation weight: {r.get('reincarnation_weight', 0)}")
        lines.append("`" + "  ·  ".join(mech) + "`\n")

        lines.append("\n**Name**\n")
        lines.append(anchor(["races.json", rid, "name"], r.get("name", "")))
        lines.append("\n**Description**\n")
        lines.append(anchor(["races.json", rid, "description"], r.get("description", "")))

        own = [b for b in r.get("typical_backgrounds", []) if b in backgrounds]
        if own:
            lines.append("\n*Backgrounds: " + ", ".join(f"`{b}`" for b in own) + "*\n")
        lines.append("\n---\n")

    # Backgrounds are written once each, below the births. Several births share
    # the same background, and repeating one under each of them would put the
    # same anchor in the file more than once — the importer reads them in order,
    # so an edit to any copy but the last would be silently thrown away.
    used = {}
    for rid, r in sorted(races.items()):
        for bid in r.get("typical_backgrounds", []):
            if bid in backgrounds:
                used.setdefault(bid, []).append(r.get("name", rid))

    lines.append(f"\n# Backgrounds  ({len(used)})\n")
    lines.append("\n*What the character did with the birth they were given. Each appears "
                 "once here, with the births that can take it.*\n")
    for bid in sorted(used):
        b = backgrounds[bid]
        lines.append(f"\n## {b.get('name', bid)}  `{bid}`\n")
        bm = ["births: " + ", ".join(used[bid])]
        bmods = {k: v for k, v in b.get("attribute_modifiers", {}).items() if v}
        if bmods:
            bm.append("attributes: " + ", ".join(f"{k}{v:+d}" for k, v in bmods.items()))
        if b.get("starting_skills"):
            bm.append("skills: " + ", ".join(f"{k} {v}" for k, v in b["starting_skills"].items()))
        items = b.get("starting_equipment", {}).get("items", [])
        if items:
            bm.append("kit: " + ", ".join(items))
        lines.append("`" + "  ·  ".join(bm) + "`\n")
        lines.append("\n**Name**\n")
        lines.append(anchor(["backgrounds.json", bid, "name"], b.get("name", "")))
        lines.append("\n**Description**\n")
        lines.append(anchor(["backgrounds.json", bid, "description"], b.get("description", "")))

    write("ANIMAL_RACES.md", "\n".join(lines))
    return len(races), len(used)


def export_animal_enemies():
    arch = {k: v for k, v in load("resources/data/enemies/animal_archetypes.json")["archetypes"].items()
            if _is_record(v)}
    enc = {k: v for k, v in load("resources/data/enemies/animal_encounters.json")["encounters"].items()
           if _is_record(v)}

    lines = ["# Animal Realm — Bestiary\n",
             f"*{len(arch)} archetypes across {len(enc)} encounter templates. The name is "
             "what the player sees over the enemy's head; the note beneath it is a design "
             "comment and never appears in game.*\n",
             "*Edit names and notes between the anchors. Everything else — tier, roles, "
             "resistances — is generated from `animal_archetypes.json`.*\n", "---\n"]

    by_region = {}
    for aid, a in arch.items():
        by_region.setdefault(a.get("region", "any"), []).append((aid, a))

    for region in sorted(by_region):
        lines.append(f"\n# Region: {region}  ({len(by_region[region])})\n")
        for aid, a in sorted(by_region[region]):
            lines.append(f"\n## {a.get('name', aid)}  `{aid}`\n")
            mech = [f"tier: {a.get('tier', '?')}",
                    "roles: " + ", ".join(a.get("roles", []) or ["-"])]
            if a.get("ai_behavior"):
                mech.append("ai: " + a["ai_behavior"])
            if a.get("skill_priorities"):
                mech.append("skills: " + ", ".join(a["skill_priorities"]))
            if a.get("resistances"):
                mech.append("resists: " + ", ".join(f"{k} {v}%" for k, v in a["resistances"].items()))
            if a.get("guaranteed_spells"):
                mech.append("spells: " + ", ".join(a["guaranteed_spells"]))
            if a.get("guaranteed_perks"):
                mech.append("perks: " + ", ".join(a["guaranteed_perks"]))
            mech.append(f"threat ×{a.get('threat_multiplier', 1)}")
            lines.append("`" + "  ·  ".join(str(m) for m in mech) + "`\n")

            appears = sorted(eid for eid, e in enc.items()
                             if aid in json.dumps(e) or e.get("region") == a.get("region"))
            direct = sorted(eid for eid, e in enc.items() if aid in json.dumps(e))
            if direct:
                lines.append(f"\n*Named directly in: {', '.join(direct)}*\n")

            lines.append("\n**Name**\n")
            lines.append(anchor(["animal_archetypes.json", aid, "name"], a.get("name", "")))
            if "_comment" in a:
                lines.append("\n**Design note** *(not shown in game)*\n")
                lines.append(anchor(["animal_archetypes.json", aid, "_comment"], a["_comment"]))
        lines.append("\n---\n")

    write("ANIMAL_ENEMIES.md", "\n".join(lines))
    return len(arch), len(enc)


def export_animal_locations():
    shops = {k: v for k, v in load("resources/data/shops.json")["shops"].items()
             if _is_record(v) and k.startswith("animal_")}

    lines = ["# Animal Realm — Places\n",
             f"*{len(shops)} locations the party can walk into: teahouses, guilds, shrines, "
             "merchants and the named sacred sites. The description is what greets the "
             "player on arrival.*\n",
             "*Edit names and descriptions between the anchors. Stock, prices and training "
             "are generated — change those in `shops.json`.*\n", "---\n"]

    by_type = {}
    for sid, sh in shops.items():
        by_type.setdefault(sh.get("type", "other"), []).append((sid, sh))

    for stype in sorted(by_type):
        lines.append(f"\n# {stype.replace('_', ' ').title()}  ({len(by_type[stype])})\n")
        for sid, sh in sorted(by_type[stype]):
            lines.append(f"\n## {sh.get('name', sid)}  `{sid}`\n")
            mech = [f"prices ×{sh.get('price_modifier', 1)}"]
            if sh.get("guild_school"):
                mech.append(f"guild: {sh['guild_school']} up to tier {sh.get('guild_max_tier', '?')}")
            if sh.get("items"):
                mech.append(f"{len(sh['items'])} items in stock")
            if sh.get("spells"):
                mech.append(f"{len(sh['spells'])} spells")
            tr = sh.get("training", {})
            if tr.get("attributes") or tr.get("skills"):
                mech.append("trains: " + ", ".join(list(tr.get("attributes", [])) + list(tr.get("skills", []))))
            if sh.get("available_companions"):
                mech.append("recruits: " + ", ".join(sh["available_companions"]))
            if sh.get("rest"):
                mech.append("rest available")
            lines.append("`" + "  ·  ".join(str(m) for m in mech) + "`\n")
            lines.append("\n**Name**\n")
            lines.append(anchor(["shops.json", sid, "name"], sh.get("name", "")))
            lines.append("\n**Description**\n")
            lines.append(anchor(["shops.json", sid, "description"], sh.get("description", "")))
        lines.append("\n---\n")

    write("ANIMAL_LOCATIONS.md", "\n".join(lines))
    return len(shops)


def export_animal_world():
    m = load("resources/data/map_configs/animal.json")

    lines = ["# Animal Realm — The Map\n",
             "*The realm blurb, the zones the map is built from, the fixed landmarks, and "
             "the pool of settlement names. The zone notes are design comments — they never "
             "appear in game, but they are the description the map is generated against.*\n",
             "*Edit between the anchors. Sizes, terrain weights and spawn densities are "
             "generated — change those in `map_configs/animal.json`.*\n", "---\n",
             f"\n`{m.get('width')}×{m.get('height')} tiles  ·  base speed {m.get('base_speed')}`\n"]

    lines.append("\n## Realm name\n")
    lines.append(anchor(["map_animal.json", "map", "name"], m.get("name", "")))
    lines.append("\n## Realm description\n")
    lines.append(anchor(["map_animal.json", "map", "description"], m.get("description", "")))

    lines.append("\n---\n\n# Zones\n")
    for z in m.get("zones", []):
        zid = z.get("id", "?")
        head = z.get("display_name") or zid
        lines.append(f"\n## {head}  `{zid}`\n")
        zm = []
        if z.get("rows"):
            zm.append(f"rows {z['rows'][0]}–{z['rows'][1]}")
        if z.get("type"):
            zm.append(z["type"])
        if z.get("pass_count"):
            zm.append(f"{z['pass_count'][0]}–{z['pass_count'][1]} passes, width {z.get('pass_width', '?')}")
        if zm:
            lines.append("`" + "  ·  ".join(str(x) for x in zm) + "`\n")
        if "display_name" in z:
            lines.append("\n**Display name** *(shown on the map)*\n")
            lines.append(anchor(["map_animal.json", f"zone.{zid}", "display_name"], z["display_name"]))
        if "_comment" in z:
            lines.append("\n**Zone note** *(design comment, not shown in game)*\n")
            lines.append(anchor(["map_animal.json", f"zone.{zid}", "_comment"], z["_comment"]))

    lines.append("\n---\n\n# Fixed landmarks\n")
    lines.append("\n*Placed by hand rather than rolled. The name is what the player sees "
                 "on the map marker.*\n")
    for lm in m.get("fixed_landmarks", []):
        data = lm.get("data", {})
        eid = data.get("event_id")
        if not eid or "name" not in data:
            continue
        lines.append(f"\n## {data.get('name')}  `{eid}`\n")
        lines.append(f"`{lm.get('type')}  ·  zone {lm.get('zone')}  ·  {lm.get('position')}`\n")
        lines.append("\n**Marker name**\n")
        lines.append(anchor(["map_animal.json", f"landmark.{eid}", "name"], data["name"]))

    towns = m.get("location_names", {}).get("town", [])
    if towns:
        lines.append("\n---\n\n# Settlement names\n")
        lines.append(f"\n*The pool of {len(towns)} names towns are drawn from. Each is edited "
                     "on its own — add or remove entries in `map_configs/animal.json`.*\n")
        note = m.get("location_names", {}).get("_comment")
        if note:
            lines.append("\n**Naming note** *(design comment)*\n")
            lines.append(anchor(["map_animal.json", "location_names", "_comment"], note))
        lines.append("")
        for i, t in enumerate(towns):
            lines.append(anchor(["map_animal.json", "location_names", f"town[{i}]"], t))

    write("ANIMAL_WORLD.md", "\n".join(lines))
    return len(m.get("zones", [])), len(towns)


def _name_block(lines, source, record, field_base, value, label):
    """Emit editable anchors for a string, a list of strings, or a list of
    {name, meaning} dicts — whichever shape the naming data uses here."""
    if isinstance(value, str):
        lines.append(f"\n**{label}**\n")
        lines.append(anchor([source, record, field_base], value))
    elif isinstance(value, list) and value and isinstance(value[0], str):
        lines.append(f"\n**{label}**\n")
        for i, v in enumerate(value):
            lines.append(anchor([source, record, f"{field_base}[{i}]"], v))
    elif isinstance(value, list) and value and isinstance(value[0], dict):
        lines.append(f"\n**{label}**\n")
        for i, v in enumerate(value):
            lines.append(anchor([source, record, f"{field_base}[{i}].name"], v.get("name", "")))
            lines.append("\n*meaning:*\n")
            lines.append(anchor([source, record, f"{field_base}[{i}].meaning"], v.get("meaning", "")))
            lines.append("")


LABELS = {
    "naming_philosophy": "How this birth names",
    "parent_wishes": "Parent wishes",
    "parent_wishes_wolf": "Parent wishes — wolf",
    "parent_wishes_deer": "Parent wishes — deer",
    "personal_names": "Personal names",
    "place_names": "Place names",
    "place_names_wolf": "Place names — wolf",
    "place_names_deer": "Place names — deer",
    "named_places": "Named places",
}


def export_animal_names():
    regions = load("resources/data/animal_realm_names.json")["regions"]

    total = 0
    lines = ["# Animal Realm — Naming Lore\n",
             "*How each birth names itself and its world: the philosophy behind the names, "
             "what parents wish over a newborn, the personal names in use, and the places "
             "each birth has named. This is the source the realm's generated names and much "
             "of its event prose draw on.*\n",
             "*Every name and every meaning is editable between the anchors. The headings and "
             "the birth ids are generated.*\n", "---\n"]

    for region, rdata in regions.items():
        lines.append(f"\n# {region.replace('_', ' ').title()}\n")
        if "_comment" in rdata:
            lines.append("\n**How this region is experienced**\n")
            lines.append(anchor(["animal_realm_names.json", region, "_comment"], rdata["_comment"]))
            total += 1

        lf = rdata.get("landscape_features", {})
        if lf:
            lines.append("\n## Shared geography\n")
            if "_comment" in lf:
                lines.append("\n**Note**\n")
                lines.append(anchor(["animal_realm_names.json", f"{region}.landscape_features",
                                     "_comment"], lf["_comment"]))
                total += 1
            for key, val in lf.items():
                if key == "_comment":
                    continue
                _name_block(lines, "animal_realm_names.json", f"{region}.landscape_features",
                            key, val, LABELS.get(key, key.replace("_", " ").title()))
                total += len(val) if isinstance(val, list) else 1

        for birth, bdata in rdata.get("births", {}).items():
            lines.append(f"\n## {birth.title()}  `{birth}`\n")
            for key, val in bdata.items():
                if key.startswith("_"):
                    continue
                _name_block(lines, "animal_realm_names.json", f"{region}.births.{birth}",
                            key, val, LABELS.get(key, key.replace("_", " ").title()))
                total += len(val) if isinstance(val, list) else 1
        lines.append("\n---\n")

    write("ANIMAL_NAMES.md", "\n".join(lines))
    return len(regions), total


ANCHOR_KEY = re.compile(r"<!--@ (.+?) -->")


def write(name, text):
    # Two anchors on one JSON path would make the document lossy: the importer
    # walks them in order, so every copy but the last is discarded. Fail loudly
    # rather than hand back a file whose edits do not all survive.
    seen, dupes = set(), []
    for key in ANCHOR_KEY.findall(text):
        if key in seen:
            dupes.append(key)
        seen.add(key)
    if dupes:
        raise SystemExit(f"{name}: {len(dupes)} duplicate anchors, first: {dupes[0]}")
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
        f.write(text)
    print(f"  wrote docs/review/{name}  ({len(text.splitlines())} lines)")


if __name__ == "__main__":
    print("exporting review documents:")
    n = export_animal_companions()
    print(f"     {n} animal companions")
    n = export_traits()
    print(f"     {n} traits")
    n, b = export_animal_races()
    print(f"     {n} animal births, {b} backgrounds")
    n, e = export_animal_enemies()
    print(f"     {n} animal archetypes, {e} encounters")
    n = export_animal_locations()
    print(f"     {n} animal locations")
    z, t = export_animal_world()
    print(f"     animal map: {z} zones, {t} settlement names")
    r, n = export_animal_names()
    print(f"     naming lore: {r} regions, {n} entries")
    for src, out, title in REALMS:
        total, new = export_events(src, out, title)
        print(f"     {title}: {total} events, {new} new")
