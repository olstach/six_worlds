#!/usr/bin/env python3
"""Build the Six Worlds writer's guide as one HTML file (rendered to PDF by render.js).

Everything the writer will edit (events, companions, births, backgrounds, shops, bestiary
notes, naming lore) is read straight from resources/data/*.json and printed unedited.
Hand-written explanatory chapters live in prose.py.

    python3 tools/writer_guide/build.py [out.html] [pages.json]

pages.json (optional) maps TOC entry ids to page numbers; render.sh produces it with a first pass.
"""
import html, json, re, sys, collections
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
DATA = ROOT / "resources" / "data"
sys.path.insert(0, str(HERE))
import prose as P  # noqa: E402

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "guide.html"
PAGES = json.loads(Path(sys.argv[2]).read_text()) if len(sys.argv) > 2 and Path(sys.argv[2]).exists() else {}


def J(rel):
    return json.loads((DATA / rel).read_text(encoding="utf-8"))


# ------------------------------------------------------------------ data
RACES_FILE = J("races.json")
RACES = {k: v for k, v in RACES_FILE["races"].items() if isinstance(v, dict)}
BGS = {k: v for k, v in RACES_FILE["backgrounds"].items() if isinstance(v, dict)}
SKILLS = J("skills.json")["skills"]
TRAITS = {k: v for k, v in J("traits.json").items() if isinstance(v, dict)}
SPELLS = J("spells.json")["spells"]
PERKS = J("perks.json")["skill_perks"]
DOMAINS = J("domains.json")["domains"]
COMP = J("companions.json")["companions"]
SHOPS = J("shops.json")["shops"]
QUESTS = J("quests.json")["quests"]
NAMES = J("animal_realm_names.json")["regions"]
EVENTS = {r: {k: v for k, v in J(f"events/{f}_events.json")["events"].items() if isinstance(v, dict)}
          for r, f in (("hell", "hell"), ("hungry_ghost", "hungry_ghost"), ("animal", "animal"), ("domain", "domain"))}
ARCH = {r: {k: v for k, v in J(f"enemies/{r}_archetypes.json")["archetypes"].items() if isinstance(v, dict)}
        for r in ("hell", "hungry_ghost", "animal", "domain")}
MAPS = {r: J(f"map_configs/{r}.json") for r in ("hell", "hungry_ghost", "animal")}

REALM_NAME = {"hell": "Hell", "hungry_ghost": "Hungry Ghost", "animal": "Animal",
              "human": "Human", "asura": "Asura", "god": "God"}
REALM_ORDER = list(REALM_NAME)


def esc(s):
    return html.escape(str(s), quote=False)


def para(text):
    """Game text -> paragraphs, preserving the author's line and paragraph breaks."""
    out = []
    for block in re.split(r"\n\s*\n", str(text).strip()):
        out.append("<p>" + esc(block).replace("\n", "<br>") + "</p>")
    return "".join(out)


def title(s):
    return str(s).replace("_", " ").strip().title()


def skill_name(i):
    return SKILLS.get(i, {}).get("name", title(i))


def trait_name(i):
    if isinstance(i, dict):
        i = i.get("id") or i.get("trait") or next(iter(i.values()), "")
    if isinstance(i, list):
        return ", ".join(trait_name(x) for x in i)
    return TRAITS.get(i, {}).get("name", title(i))


def race_name(i):
    return RACES.get(i, {}).get("name", title(i))


def bg_name(i):
    return BGS.get(i, {}).get("name", title(i))


def realm_label(i):
    return REALM_NAME.get(i, title(i))


# ------------------------------------------------------------------ TOC machinery
TOC = []  # (level, id, label)
_ids = collections.Counter()


def heading(level, label, toc=True, cls=""):
    """Emit a heading and (optionally) register it in the TOC."""
    _ids[label] += 1
    hid = "h-" + re.sub(r"[^a-z0-9]+", "-", label.lower()).strip("-")[:60] + (f"-{_ids[label]}" if _ids[label] > 1 else "")
    if toc:
        TOC.append((level, hid, label))
    return f'<h{level} id="{hid}" class="{cls}">{esc(label)}</h{level}>'


# ------------------------------------------------------------------ event rendering
ATTR = {a: a.title() for a in ("strength", "constitution", "finesse", "focus", "awareness", "charm", "luck")}
CHOICE_BADGE = {"default": ("Grey", "grey"), "requirement": ("Blue", "blue"), "roll": ("Yellow", "yellow")}
DIFF = {"trivial": "trivial", "easy": "easy", "normal": "normal", "hard": "hard", "very_hard": "very hard"}


def pretty_amount(v):
    return str(v).replace("_", " ") if isinstance(v, str) else str(v)


def req_text(req):
    bits = []
    for k, v in (req or {}).items():
        if k == "attributes":
            bits += [f"{ATTR.get(a, title(a))} {n}+" for a, n in v.items()]
        elif k == "skills":
            bits += [f"{skill_name(s)} {n}+" for s, n in v.items()]
        elif k == "trait":
            bits.append(f"Trait: {trait_name(v)}")
        elif k == "roll":
            what = ATTR.get(v.get("attribute"), None) or skill_name(v.get("skill", "")) if (v.get("attribute") or v.get("skill")) else "luck"
            bits.append(f"Roll: {what}, {DIFF.get(v.get('difficulty'), v.get('difficulty', 'normal'))} difficulty")
        else:
            bits.append(f"{title(k)}: {v}")
    return "; ".join(bits)


def cost_text(cost):
    if not cost:
        return ""
    bits = []
    for k, v in cost.items():
        if isinstance(v, list):
            v = ", ".join(title(x) for x in v)
        bits.append(f"{title(k)} ({pretty_amount(v)})")
    return "Cost: " + ", ".join(bits)


def karma_text(k):
    if not k:
        return ""
    return "Karma: " + ", ".join(f"{realm_label(r)} {n:+d}" for r, n in k.items())


def rewards_text(rw):
    if not isinstance(rw, dict):
        return ""
    bits = []
    for k, v in rw.items():
        if k == "flags":
            continue
        if k == "xp":
            bits.append(f"XP {v}")
        elif k == "gold":
            bits.append(f"gold {pretty_amount(v)}")
        elif k == "items":
            bits.append("items: " + ", ".join(title(i) for i in v))
        elif k == "add_trait":
            bits.append(f"gains trait: {trait_name(v)}")
        elif k == "remove_trait":
            bits.append(f"loses trait: {trait_name(v)}")
        elif k == "pressure":
            bits.append("mind: " + ", ".join(f"{title(p['element'])} {p['amount']:+d}" for p in v))
        elif k == "hp_loss":
            bits.append(f"HP loss ({pretty_amount(v.get('amount'))}, {v.get('target', '')})")
        elif k == "supplies":
            bits.append("supplies: " + ", ".join(f"{title(a)} {b}" for a, b in v.items()))
        elif k == "buffs":
            bits.append("buff: " + ", ".join(f"{title(b['stat'])} {b['amount']:+d}" for b in v))
        elif k == "learn_spell":
            bits.append("learns a spell" + (f" ({title(v['school'])})" if isinstance(v, dict) and v.get("school") else ""))
        elif k == "skill_up":
            bits.append(f"{skill_name(v['skill'])} +{v['amount']}")
        elif k == "wound":
            bits.append(f"wound: {title(v.get('id', ''))}")
        elif k == "restore":
            bits.append("full restore")
        elif k == "gamble":
            bits.append("gamble")
        else:
            bits.append(f"{k}: {json.dumps(v)}")
    return "Effects: " + "; ".join(bits) if bits else ""


def comp_name(cid):
    if cid in (None, "random"):
        return "a random companion from this zone"
    return COMP.get(cid, {}).get("name", title(cid))


def shop_name(sid):
    return SHOPS.get(sid, {}).get("name", title(sid))


def outcome_html(o, label=None):
    if not isinstance(o, dict):
        return ""
    out = ['<div class="outcome">']
    if label:
        out.append(f'<span class="olabel">{label}</span> ')
    t = o.get("type")
    if t == "combat":
        out.append(f'<span class="otag">Combat: {esc(title(o.get("enemy_group", "")))} ({esc(o.get("difficulty", ""))})</span>')
    elif t == "shop":
        out.append(f'<span class="otag">Opens: {esc(shop_name(o.get("shop_id")))}</span>')
    elif t == "recruit_companion":
        out.append(f'<span class="otag">Recruit: {esc(comp_name(o.get("companion_id")))}</span>')
    elif t == "follow_up":
        out.append(f'<span class="otag">Leads to: {esc(title(o.get("follow_up_event", "")))}</span>')
    if o.get("text"):
        out.append(para(o["text"]))
    ov = o.get("on_victory")
    if isinstance(ov, dict):
        out.append('<div class="after"><span class="olabel">After victory:</span> ')
        if ov.get("type") == "shop":
            out.append(f'<span class="otag">Opens: {esc(shop_name(ov.get("shop_id")))}</span>')
        if ov.get("text"):
            out.append(para(ov["text"]))
        out.append("</div>")
    meta = " · ".join(x for x in (rewards_text(o.get("rewards")), karma_text(o.get("karma"))) if x)
    if o.get("free"):
        meta = ("No cost. " + meta).strip()
    if meta:
        out.append(f'<div class="mech">{esc(meta)}</div>')
    out.append("</div>")
    return "".join(out)


def event_html(eid, e):
    out = ['<div class="event">']
    out.append(f'<h4>{esc(e.get("title", eid))} <span class="id">{esc(e.get("id", eid))}</span></h4>')
    meta = []
    if e.get("trigger"):
        meta.append(f"Trigger: {e['trigger']}")
    if e.get("requires_trait"):
        meta.append(f"Concerns a character with trait: {trait_name(e['requires_trait'])}")
    if e.get("requires_band"):
        meta.append(f"Relationship: {e['requires_band']}")
    if e.get("domain"):
        meta.append(f"Domain: {title(e['domain'])}")
    if e.get("rarity"):
        meta.append(f"Rarity: {title(e['rarity'])}")
    if meta:
        out.append(f'<div class="mech">{esc(" · ".join(meta))}</div>')
    if e.get("description"):
        out.append(f'<div class="mech">{esc(e["description"])}</div>')
    if e.get("text"):
        out.append(f'<div class="etext">{para(e["text"])}</div>')
    for c in e.get("choices", []):
        label, cls = CHOICE_BADGE.get(c.get("type"), ("Grey", "grey"))
        out.append(f'<div class="choice {cls}"><div class="chead"><span class="badge {cls}">{label}</span> '
                   f'<span class="ctext">{esc(c.get("text", ""))}</span></div>')
        sub = []
        if c.get("requirements"):
            sub.append(("Requires: " if c.get("type") == "requirement" else "") + req_text(c["requirements"]))
        if c.get("prerequisite"):
            sub.append("Only after: " + ", ".join(title(k) for k in c["prerequisite"] if k != "value")
                       + (" is set" if c["prerequisite"].get("value") else ""))
        if c.get("cost"):
            sub.append(cost_text(c["cost"]))
        if sub:
            out.append(f'<div class="req">{esc("  ·  ".join(sub))}</div>')
        if c.get("outcome_success") or c.get("outcome_failure"):
            out.append(outcome_html(c.get("outcome_success"), "If it succeeds:"))
            out.append(outcome_html(c.get("outcome_failure"), "If it fails:"))
        else:
            out.append(outcome_html(c.get("outcome")))
        out.append("</div>")
    out.append("</div>")
    return "".join(out)


def events_section(realm, ids=None):
    evs = EVENTS[realm]
    parts = []
    for eid, e in evs.items():
        parts.append(event_html(eid, e))
    return "".join(parts), len(evs)


# ------------------------------------------------------------------ companions / births / backgrounds
def load_meanings():
    """Name etymologies live in CHARACTERS.md (hand-maintained design source)."""
    text = (ROOT / "CHARACTERS.md").read_text(encoding="utf-8")
    out, cur = {}, None
    for line in text.splitlines():
        if line.startswith("### "):
            cur = line[4:].strip()
        elif line.startswith("**Meaning:**") and cur:
            out[cur.lower()] = line[len("**Meaning:**"):].strip()
    return out


MEANINGS = load_meanings()


def md_inline(s):
    s = esc(s)
    s = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", s)
    return s


def top_skills(c, n=3):
    bw = c.get("build_weights") or {}
    return [skill_name(k) for k, _ in sorted(bw.items(), key=lambda kv: -kv[1])[:n]]


def companion_html(c):
    out = ['<div class="comp">']
    out.append(f'<h4>{esc(c["name"])} <span class="id">{esc(c["id"])}</span></h4>')
    meaning = MEANINGS.get(c["name"].lower())
    if meaning:
        out.append(f'<div class="meaning"><strong>Name:</strong> {md_inline(meaning)}</div>')
    out.append(f'<div class="cmeta">{esc(race_name(c["birth"]))} · {esc(bg_name(c["background"]))}'
               + (f' · {esc(title(c["zone"]))}' if c.get("zone") else "") + "</div>")
    out.append(f'<div class="flavor">{para(c["flavor_text"])}</div>')
    traits = ", ".join(trait_name(t) for t in c.get("traits", []))
    out.append(f'<div class="cmeta2"><strong>Traits:</strong> {esc(traits) or "none"} &nbsp;|&nbsp; '
               f'<strong>Strongest skills:</strong> {esc(", ".join(top_skills(c)))}</div>')
    out.append("</div>")
    return "".join(out)


def birth_html(rid, r):
    out = ['<div class="birth">']
    out.append(f'<h4>{esc(r["name"])} <span class="id">{esc(rid)}</span></h4>')
    out.append(f'<div class="flavor">{para(r["description"])}</div>')
    bits = []
    am = {a: v for a, v in r.get("attribute_modifiers", {}).items() if v}
    hi = [ATTR[a] for a, v in sorted(am.items(), key=lambda kv: -kv[1]) if v > 0]
    lo = [ATTR[a] for a, v in sorted(am.items(), key=lambda kv: kv[1]) if v < 0]
    if hi:
        bits.append(f"<strong>Gifted in:</strong> {esc(', '.join(hi))}")
    if lo:
        bits.append(f"<strong>Weaker in:</strong> {esc(', '.join(lo))}")
    aff = r.get("elemental_affinity_bonuses") or {}
    if aff:
        bits.append("<strong>Elemental lean:</strong> " + esc(", ".join(title(a) for a in aff)))
    sk = r.get("starting_skills") or {}
    if sk:
        bits.append("<strong>Starts with:</strong> " + esc(", ".join(skill_name(s) for s in sk)))
    if r.get("starting_traits"):
        bits.append("<strong>Innate traits:</strong> " + esc(", ".join(trait_name(t) for t in r["starting_traits"])))
    if bits:
        out.append('<div class="cmeta2">' + " &nbsp;|&nbsp; ".join(bits) + "</div>")
    tb = r.get("typical_backgrounds") or []
    if tb:
        out.append('<div class="cmeta2"><strong>Typical backgrounds:</strong> ' + esc(", ".join(bg_name(b) for b in tb)) + "</div>")
    ncomp = [c["name"] for c in COMP.values() if c["birth"] == rid]
    if ncomp:
        out.append('<div class="cmeta2"><strong>Companions of this birth:</strong> ' + esc(", ".join(ncomp)) + "</div>")
    out.append("</div>")
    return "".join(out)


def bg_realms(b):
    rs = {RACES[r]["realm"] for r in b.get("available_races", []) if r in RACES}
    return rs


# ------------------------------------------------------------------ pieces
def trait_table():
    cats = collections.OrderedDict()
    for tid, t in TRAITS.items():
        cats.setdefault(t.get("category", "other"), []).append((tid, t))
    order = ["physical", "personality", "behavioral", "acquired", "racial"]
    keys = sorted(cats, key=lambda c: order.index(c) if c in order else 99)
    WIS = {"space": "openness", "fire": "warmth", "water": "clarity", "earth": "equanimity", "air": "alertness"}
    POI = {"space": "delusion", "fire": "desire", "water": "aversion", "earth": "pride", "air": "envy"}
    out = []
    total = 0
    for cat in keys:
        out.append(heading(3, f"{title(cat)} traits", toc=False))
        out.append('<table class="grid traits"><tr><th style="width:17%">Trait</th><th>Description</th><th style="width:22%">Effect on the character</th><th style="width:20%">Mind leans toward</th></tr>')
        for tid, t in cats[cat]:
            eff = [f"{ATTR.get(a, title(a))} {v:+d}" for a, v in (t.get("stat_modifiers") or {}).items() if isinstance(v, (int, float)) and v]
            eff += [f"{skill_name(s)} {v:+d}" for s, v in (t.get("skill_modifiers") or {}).items() if isinstance(v, (int, float)) and v]
            lean = []
            for el, v in (t.get("pressure_modifiers") or {}).items():
                if v:
                    lean.append(f"{POI[el]} (more)" if v < 0 else f"{WIS[el]} (more)")
            how = []
            if t.get("inborn"):
                how.append("inborn")
            out.append(f'<tr><td><strong>{esc(t["name"])}</strong><br><span class="id">{esc(tid)}</span></td>'
                       f'<td>{esc(t.get("description", ""))}</td><td>{esc("; ".join(eff)) or "&mdash;"}</td>'
                       f'<td>{esc("; ".join(lean)) or "&mdash;"}</td></tr>')
            total += 1
        out.append("</table>")
    return "".join(out), total


def skill_sections():
    out = []
    ELS = ["space", "air", "fire", "water", "earth"]
    for el in ELS:
        out.append(heading(3, f"{title(el)} skills", toc=False))
        out.append('<table class="grid"><tr><th style="width:18%">Skill</th><th>What it does for a character</th><th style="width:20%">Leans on</th></tr>')
        for sid, s in SKILLS.items():
            if s["element"] != el:
                continue
            attrs = [ATTR[s["primary_attribute"]]]
            if s.get("secondary_attribute"):
                attrs.append(ATTR[s["secondary_attribute"]])
            out.append(f'<tr><td><strong>{esc(s["name"])}</strong></td><td>{esc(P.SKILL_BLURBS[sid])}</td><td>{esc(" / ".join(attrs))}</td></tr>')
        out.append("</table>")
    return "".join(out)


def spell_name_lookup():
    return {v["name"]: (k, v) for k, v in SPELLS.items()}


def school_sections():
    look = spell_name_lookup()
    out = []
    for school, names in P.SCHOOL_PICKS.items():
        out.append(f'<div class="school"><h4>{school}</h4><p>{esc(P.SCHOOL_TEXT[school])}</p><ul class="spells">')
        for n in names:
            k, v = look[n]
            others = [s for s in v["schools"] if s != school]
            also = f" (also {', '.join(others)})" if others else ""
            out.append(f'<li><strong>{esc(n)}</strong> <span class="lvl">level {v["level"]}{esc(also)}</span>: {esc(v.get("description") or "")}</li>')
        out.append("</ul></div>")
    return "".join(out)


def domain_sections():
    out = []
    for k, d in DOMAINS.items():
        out.append(f'<div class="school"><h4>{esc(d["name"])} <span class="lvl">{esc(" + ".join(d["elements"]))}</span></h4>')
        out.append(f'<p><em>{esc(d["theme"])}</em></p><p>{esc(d["description"])}</p>')
        names = [SPELLS[s]["name"] for s in d["spells"] if s in SPELLS]
        out.append(f'<p class="cmeta2"><strong>Spells:</strong> {esc(", ".join(names))}'
                   f' &nbsp;|&nbsp; <strong>Found through the event:</strong> {esc(title(d.get("event", "")))}</p></div>')
    return "".join(out)


def perk_examples():
    out = []
    by_skill = collections.defaultdict(dict)
    for pid, v in PERKS.items():
        if isinstance(v, dict) and v.get("skill"):
            by_skill[v["skill"]][pid] = v
    for sid in SKILLS:
        perks = by_skill.get(sid)
        if not perks:
            continue
        items = [(k, v) for k, v in perks.items() if not v.get("is_mantra")]
        if not items:
            continue
        items.sort(key=lambda kv: kv[1].get("required_level", 0))
        pick = [items[0]]
        if len(items) > 1:
            pick.append(items[-1])
        cells = "".join(f'<div class="perk"><strong>{esc(v["name"])}</strong> <span class="lvl">skill level {v.get("required_level")}</span>: {esc(v["description"])}</div>'
                        for _, v in pick)
        out.append(f'<div class="place"><strong class="pskill">{esc(skill_name(sid))}</strong>{cells}</div>')
    return "".join(out)


def shop_group(realm):
    out = []
    items = []
    for sid, s in SHOPS.items():
        if sid.endswith("_domain_shop"):
            continue
        r = "animal" if sid.startswith("animal_") else "hungry_ghost" if sid.startswith("hg_") else "hell"
        if r == realm:
            items.append((sid, s))
    return items


SHOP_TYPE = {"general": "General merchant", "spell_trainer": "Spell trainer", "skill_trainer": "Skill trainer",
             "mixed": "Mixed", "teahouse": "Teahouse", "mercenary_guild": "Mercenary guild",
             "veteran_camp": "Veteran camp", "yogini_circle": "Yogini circle", "spell_guild": "Spell guild",
             "town": "Town", "blacksmith": "Blacksmith", "fletcher": "Fletcher", "healer": "Healer",
             "alchemist": "Alchemist", "domain_spell_trainer": "Domain spell trainer"}


def shops_html(realm):
    items = shop_group(realm)
    by = collections.OrderedDict()
    for sid, s in items:
        by.setdefault(s.get("type", "other"), []).append((sid, s))
    out = []
    n = 0
    for t, lst in by.items():
        out.append(f'<h4 class="sub">{esc(SHOP_TYPE.get(t, title(t)))}</h4>')
        for sid, s in lst:
            tr = (s.get("training") or {})
            trains = ", ".join(skill_name(x) for x in tr.get("skills", [])) if isinstance(tr, dict) else ""
            out.append(f'<div class="place"><strong>{esc(s["name"])}</strong> <span class="id">{esc(sid)}</span>'
                       f'<div>{esc(s.get("description", ""))}</div>'
                       + (f'<div class="mech">Trains: {esc(trains)}</div>' if trains else "") + "</div>")
            n += 1
    return "".join(out), n


def bestiary_html(realm):
    out = []
    for aid, a in ARCH[realm].items():
        note = a.get("_comment")
        roles = ", ".join(a.get("roles", []))
        out.append(f'<div class="place"><strong>{esc(a["name"])}</strong> <span class="id">{esc(aid)}</span>'
                   f'<span class="mech"> &nbsp; {esc(a.get("region", ""))}{" · " + esc(roles) if roles else ""}</span>'
                   + (f'<div class="dnote">{esc(note)}</div>' if note else "") + "</div>")
    return "".join(out), len(ARCH[realm])


def quests_html(realm):
    qs = [q for q in QUESTS.values() if q.get("realm") == realm] if isinstance(QUESTS, dict) else []
    if not qs:
        return '<p>No quests have been written for this realm yet.</p>'
    out = []
    for q in qs:
        steps = "".join(f"<li>{esc(s['text'])}</li>" for s in q.get("steps", []))
        out.append(f'<div class="place"><strong>{esc(q["name"])}</strong> <span class="id">{esc(q["id"])}</span>'
                   f'<div>{esc(q["description"])}</div><ol class="steps small">{steps}</ol></div>')
    return "".join(out)


ZONE_NOTES = {
    "cold_hell": "The northern half of Naraka: frozen wastes, glacier and ice. The party begins here, at the top-left corner of the map.",
    "fire_hell": "The southern half: burning badlands. The portal to the Hungry Ghost realm lies at the far bottom-right corner.",
    "divider": "The impassable mountain range between the cold and the fire. It can only be crossed at a pass, which is guarded.",
}


def zones_html(realm):
    m = MAPS[realm]
    out = [f'<p class="flavor">{esc(m["description"])}</p>',
           '<p class="mech">The notes under each region are design comments for the writer; the player never sees them.</p>']
    for z in m["zones"]:
        c = z.get("_comment") or ZONE_NOTES.get(z.get("id"))
        nm = z.get("name") or title(z.get("id", ""))
        out.append(f'<div class="place"><strong>{esc(nm)}</strong> <span class="id">{esc(z.get("id", ""))}</span>'
                   + (f'<div>{esc(c)}</div>' if c else "") + "</div>")
    lm = []
    for f in m.get("fixed_landmarks", []):
        d = f.get("data") or {}
        if f.get("type") in ("portal",):
            lm.append(("Portal", f"Leads to the {realm_label(d.get('destination_realm', ''))} realm."
                       + (" Opens only once the realm's boss is defeated." if d.get("requires_boss_defeated") else ""), ""))
        elif d.get("name") and d.get("event_id"):
            ev = EVENTS[realm].get(d["event_id"], {})
            lm.append((d["name"], f"{title(f.get('type', '')).replace('Event', 'Scene')} in {title(f.get('zone', ''))}; event: {ev.get('title', title(d['event_id']))}", d["event_id"]))
    if lm:
        out.append('<h4 class="sub">Fixed landmarks</h4>')
        for n, t, eid in lm:
            out.append(f'<div class="place"><strong>{esc(n)}</strong><div class="mech">{esc(t)}</div></div>')
    names = (m.get("location_names") or {}).get("town")
    if names:
        out.append('<h4 class="sub">Settlement names used on the map</h4><p>' + esc(", ".join(names)) + "</p>")
    return "".join(out)


def naming_lore():
    out = []
    for region, rv in NAMES.items():
        rn = {"sky_distributed": "Sky births (found in every region)"}.get(region, title(region))
        out.append(heading(3, f"{rn}", toc=False))
        if rv.get("_comment"):
            out.append(f'<p class="flavor">{esc(rv["_comment"])}</p>')
        lf = rv.get("landscape_features") or {}
        if lf.get("named_places"):
            out.append('<h4 class="sub">Shared geography</h4>')
            if lf.get("_comment"):
                out.append(f'<p class="mech">{esc(lf["_comment"])}</p>')
            out.append('<ul class="names">' + "".join(
                f'<li><strong>{esc(p["name"])}:</strong> {esc(p.get("meaning", ""))}</li>' for p in lf["named_places"]) + "</ul>")
        for bid, b in (rv.get("births") or {}).items():
            out.append(f'<div class="birth"><h4>{esc(race_name(bid))} <span class="id">{esc(bid)}</span></h4>')
            for k, v in b.items():
                lab = title(k)
                if isinstance(v, str):
                    out.append(f'<p><strong>{esc(lab)}.</strong> {esc(v)}</p>')
                elif isinstance(v, list) and v and isinstance(v[0], str):
                    out.append(f'<p><strong>{esc(lab)}:</strong> ' + esc("; ".join(v)) + "</p>")
                elif isinstance(v, list):
                    out.append(f'<p><strong>{esc(lab)}:</strong></p><ul class="names">' + "".join(
                        f'<li><strong>{esc(x.get("name", ""))}</strong>' + (f': {esc(x["meaning"])}' if x.get("meaning") else "") + "</li>"
                        for x in v if isinstance(x, dict)) + "</ul>")
                elif isinstance(v, dict):
                    out.append(f'<p><strong>{esc(lab)}:</strong> {esc(json.dumps(v, ensure_ascii=False))}</p>')
            out.append("</div>")
    return "".join(out)


# ------------------------------------------------------------------ assemble
def ev_count(r):
    return len(EVENTS[r])


def comp_count(r):
    return sum(1 for c in COMP.values() if c["realm"] == r)


def fill(s):
    rep = {"__HELL_EV__": ev_count("hell"), "__HG_EV__": ev_count("hungry_ghost"), "__AN_EV__": ev_count("animal"),
           "__HELL_CO__": comp_count("hell"), "__HG_CO__": comp_count("hungry_ghost"), "__AN_CO__": comp_count("animal"),
           "__DOM_EV__": ev_count("domain"), "__N_TRAITS__": len(TRAITS), "__N_BG__": len(BGS)}
    for r, key in (("human", "__HUMAN_BIRTHS__"), ("asura", "__ASURA_BIRTHS__"), ("god", "__GOD_BIRTHS__")):
        rep[key] = ", ".join(v["name"] for v in RACES.values() if v["realm"] == r)
    for k, v in rep.items():
        s = s.replace(k, str(v))
    return s


body = []


def add(x):
    body.append(x)


def part(num, label):
    text = f"Part {num}: {label}" if num else label
    add(f'<section class="part-page">{heading(1, text, cls="part")}</section>')


def chapter(num, label, content, newpage=True):
    add(f'<section class="chapter">{heading(2, f"{num}. {label}")}{fill(content)}</section>')


def realm_chapter(num, realm, label, tagline, intro, comp_pointer):
    births = [(k, v) for k, v in RACES.items() if v["realm"] == realm]
    ev_html, nev = events_section(realm)
    shops, nshops = shops_html(realm)
    best, nbest = bestiary_html(realm)
    add('<section class="chapter">')
    add(heading(2, f"{num}. {label}"))
    add(f'<p class="tagline">{esc(tagline)}</p>')
    add(fill(intro))
    add(f'<div class="note">At a glance: <strong>{len(births)}</strong> births · <strong>{comp_count(realm)}</strong> companions · '
        f'<strong>{nev}</strong> events · <strong>{nbest}</strong> enemy types · <strong>{nshops}</strong> places.</div>')
    add(heading(3, f"{num}.1 The land and its regions"))
    add(zones_html(realm))
    add(heading(3, f"{num}.2 Births of this realm"))
    add("<p>" + esc(", ".join(v["name"] for _, v in births)) + f". Full entries are in chapter 25; companions are in chapter 27.</p>")
    add(heading(3, f"{num}.3 Places: shops, guilds and teahouses"))
    add("<p>Each of these has a name and a short description shown when the party arrives.</p>" + shops)
    add(heading(3, f"{num}.4 Bestiary"))
    add("<p>Enemy types met in this realm. The note under a name is a design comment for the writer and never shown to the player.</p>" + best)
    add(heading(3, f"{num}.5 Quests"))
    add(quests_html(realm))
    add(heading(3, f"{num}.6 Event catalogue ({nev} events)"))
    add('<p>Every event written for this realm, in the order they are stored. <span class="badge grey">Grey</span> choices are always available, '
        '<span class="badge blue">Blue</span> choices need a party member with a skill, attribute or trait, '
        '<span class="badge yellow">Yellow</span> choices are rolls. The small grey lines are reference labels, not game text.</p>')
    add(ev_html)
    add("</section>")


# ---- front matter
add(f'''<section class="cover"><div class="cover-in">
<div class="rule"></div>
<h1 class="title">Six Worlds</h1>
<div class="subtitle">A Writer's Guide to the Game</div>
<div class="rule"></div>
<div class="for">Prepared for Alice</div>
<div class="small">A tactical RPG roguelike of rebirth through the six realms<br>
Everything the game is, and everything it contains so far</div>
</div></section>''')
add("@@TOC@@")

add('<section class="chapter">' + heading(2, "Welcome, Alice") + fill(P.WELCOME) + "</section>")

# ---- Part I
part("I", "The Game in Brief")
chapter(1, "The premise", P.CH1)
chapter(2, "The loop", P.CH2)
chapter(3, "Tone and visual identity", P.CH3)
chapter(4, "Where the game stands", P.CH4)

# ---- Part II
part("II", "Core Systems, in Player Terms")
chapter(5, "Karma and rebirth", P.CH5)
chapter(6, "The character: attributes", P.CH6)
add('<section class="chapter">' + heading(2, "7. Skills and the five elements") + P.CH7_INTRO + skill_sections() + "</section>")
add('<section class="chapter">' + heading(2, "8. Magic") + P.CH8_INTRO + school_sections()
    + P.CH8_DOMAINS + domain_sections() + "</section>")
trait_html, ntr = trait_table()
add('<section class="chapter">' + heading(2, "9. Perks and traits") + P.CH9_INTRO
    + heading(3, "9.1 The full trait list", ) + f"<p>All {ntr} traits in the game. “Effect” lists the stat changes a trait carries; “mind leans toward” shows which way it tilts the emotional scales of chapter 10 (a trait that makes a character more prone to pride, for instance).</p>"
    + trait_html + heading(3, "9.2 Perks") + P.CH9_PERKS + perk_examples() + "</section>")
psy = '<table class="grid"><tr><th>Element</th><th>Poison</th><th>Poison states: minor / major / crisis</th><th>Wisdom states: minor / major / crisis</th></tr>' + "".join(
    f"<tr><td>{a}</td><td>{b}</td><td>{c}</td><td>{d}</td></tr>" for a, b, c, d in P.PSYCH_TABLE) + "</table>"
chapter(10, "The inner life: poisons and wisdoms", P.CH10 + psy + P.CH10_AFTER)
chapter(11, "Body, wounds and illness", P.CH11)
chapter(12, "Combat", P.CH12)
chapter(13, "Events and dialogue", P.CH13)
chapter(14, "The party", P.CH14)
chapter(15, "Camp, rest and time", P.CH15)
chapter(16, "Items, shops and money", P.CH16)
chapter(17, "Practice and devotion", P.CH17)

# ---- Part III
part("III", "The Six Realms")
chapter(18, "The cosmology", P.CH18)

realm_chapter(19, "hell", "Hell (Naraka)", "The realm of hatred, punishment and ordered cruelty.",
              "<p>Naraka is split between the frozen wastes of the north and the burning badlands of the south, divided by an impassable mountain range. It is the first realm and the one the game is most thoroughly built around: "
              "the hells are mostly combat, but they are also a society, with wardens, clerks, guards, prisoners and the occasional devil who has had enough. "
              "Its births are six colours of devil, each belonging to a different hell.</p>", True)
realm_chapter(20, "hungry_ghost", "Hungry Ghost (Pretaloka)", "The realm of insatiable craving, decay and clinging to what is gone.",
              "<p>Pretaloka is divided into fetid swamps crawling with the newly dead, ancient graveyards haunted by desiccated skeletons, and the charnel grounds where vetalas hold court in palaces that are not quite real. "
              "The theme is scarcity: hunger amid plenty, things that can never be enough. Its births are the undead, the starving and the spirit nobility. There is a great variety of skeletons: bone, silver, copper, golden, iron, turquoise.</p>", True)
realm_chapter(21, "animal", "Animal (Tiryakloka)", "The realm of instinct, appetite and territory.",
              "<p>Tiryakloka is the realm of primal instinct and predation. The vast ocean depths hold naga courts older than memory and makara that swallow ships whole. Inland, the ancient forest is territory, contested, marked, fought over, "
              "while the open meadows are the world's great stage, where khadga charge and bhramara darken the sun. The birds live everywhere, but the high places belong to them alone. "
              "The realm mixes fighting and negotiation, and each birth has its own way of naming things (Appendix C).</p>", True)
chapter(22, "Human, Asura and God", P.CH22)

# cross-realm events
dom_html, ndom = events_section("domain")
add('<section class="chapter">' + heading(2, "23. Events across the realms")
    + f"<p>{ndom} events are not tied to one realm. Some are the <strong>domain events</strong>: rare places that teach a domain's spells (chapter 8). Others are <strong>camp events</strong>, occurring on a rest night, and <strong>trait events</strong> and <strong>relationship events</strong>, which are about a particular character or a pair of companions and use <code>{{a}}</code> and <code>{{b}}</code> for their names.</p>"
    + dom_html + heading(3, "23.1 Domain teachers")
    + "<p>After a domain event, the party can find someone who teaches that domain's spells. Each has a name and a greeting, shown when the shop opens.</p>"
    + "".join(f'<div class="place"><strong>{esc(s["name"])}</strong> <span class="id">{esc(sid)}</span><div>{esc(s.get("description", ""))}</div></div>'
              for sid, s in SHOPS.items() if sid.endswith("_domain_shop")) + "</section>")

# ---- Part IV
part("IV", "Births, Backgrounds and Companions")
chapter(24, "How a character begins", P.CH24)

add('<section class="chapter">' + heading(2, f"25. Birth catalogue ({len(RACES)} births)")
    + "<p>A birth is what you were reborn as. Each entry gives the birth's description exactly as the player reads it, followed by a short reference line summarising its leanings. The leanings are for orientation only.</p>")
for realm in REALM_ORDER:
    births = [(k, v) for k, v in RACES.items() if v["realm"] == realm]
    if not births:
        continue
    add(heading(3, f"25.{REALM_ORDER.index(realm) + 1} {realm_label(realm)} births ({len(births)})"))
    if realm in ("human", "asura", "god"):
        add('<p class="mech">The realm itself has no content yet; these births are defined and waiting.</p>')
    for k, v in births:
        add(birth_html(k, v))
add("</section>")

universal = [(k, v) for k, v in BGS.items() if not v.get("available_races")]
restricted = [(k, v) for k, v in BGS.items() if v.get("available_races")]
add('<section class="chapter">' + heading(2, f"26. Background catalogue ({len(BGS)} backgrounds)")
    + f"<p>A background is what a character did before the story begins. {len(universal)} are open to every birth; the other {len(restricted)} belong to specific births. Descriptions are exactly as the player reads them.</p>")
add(heading(3, f"26.1 Open to every birth ({len(universal)})"))
for k, v in sorted(universal, key=lambda kv: kv[1]["name"]):
    add(f'<div class="bg"><h4>{esc(v["name"])} <span class="id">{esc(k)}</span></h4><div class="flavor">{para(v["description"])}</div>'
        f'<div class="cmeta2"><strong>Teaches:</strong> {esc(", ".join(skill_name(s) for s in v.get("starting_skills", {})))}</div></div>')
groups = collections.OrderedDict()
for k, v in restricted:
    rs = bg_realms(v)
    key = next(iter(rs)) if len(rs) == 1 else "multi"
    groups.setdefault(key, []).append((k, v))
n = 2
for key in REALM_ORDER + ["multi"]:
    if key not in groups:
        continue
    lab = f"Specific to {realm_label(key)} births" if key != "multi" else "Shared by births of several realms"
    add(heading(3, f"26.{n} {lab} ({len(groups[key])})"))
    n += 1
    for k, v in sorted(groups[key], key=lambda kv: kv[1]["name"]):
        who = ", ".join(race_name(r) for r in v.get("available_races", []))
        add(f'<div class="bg"><h4>{esc(v["name"])} <span class="id">{esc(k)}</span></h4><div class="flavor">{para(v["description"])}</div>'
            f'<div class="cmeta2"><strong>Open to:</strong> {esc(who)} &nbsp;|&nbsp; <strong>Teaches:</strong> {esc(", ".join(skill_name(s) for s in v.get("starting_skills", {})))}</div></div>')
add("</section>")

# companions
add('<section class="chapter">' + heading(2, f"27. Companion catalogue ({len(COMP)} companions)")
    + "<p>Companions are the characters the player can recruit. Each entry shows the name (with its meaning, where one is recorded), birth and background, the full bio exactly as the player reads it, then a reference line of traits and strongest skills. "
      "They are grouped by realm and then by birth.</p>")
race_order = list(RACES)
for realm in REALM_ORDER:
    cs = [c for c in COMP.values() if c["realm"] == realm]
    if not cs:
        continue
    add(heading(3, f"27.{REALM_ORDER.index(realm) + 1} {realm_label(realm)} companions ({len(cs)})"))
    cur = None
    for c in sorted(cs, key=lambda c: (race_order.index(c["birth"]) if c["birth"] in race_order else 99, c["name"])):
        if c["birth"] != cur:
            cur = c["birth"]
            add(f'<h4 class="sub birthhead">{esc(race_name(cur))}</h4>')
        add(companion_html(c))
add("</section>")

# ---- Part V
part("V", "Writing for Six Worlds")
chapter(28, "What is written, and what needs you", P.CH28)
chapter(29, "Style guide", P.CH29)
chapter(30, "How to send work back", P.CH30)

# ---- Appendices
part("", "Appendices")
add('<section class="chapter">' + heading(2, "Appendix A: Glossary")
    + '<table class="grid">' + "".join(f"<tr><td style='width:20%'><strong>{esc(a)}</strong></td><td>{esc(b)}</td></tr>" for a, b in P.GLOSSARY) + "</table></section>")

rows = []
for r in REALM_ORDER:
    nb = sum(1 for v in RACES.values() if v["realm"] == r)
    rows.append(f"<tr><td>{realm_label(r)}</td><td>{nb}</td><td>{ev_count(r) if r in EVENTS else 0}</td><td>{comp_count(r)}</td>"
                f"<td>{len(ARCH[r]) if r in ARCH else 0}</td><td>{len(shop_group(r)) if r in ('hell','hungry_ghost','animal') else 0}</td></tr>")
add('<section class="chapter">' + heading(2, "Appendix B: The realms at a glance")
    + '<table class="grid"><tr><th>Realm</th><th>Births</th><th>Events</th><th>Companions</th><th>Enemy types</th><th>Places</th></tr>'
    + "".join(rows) + f"</table><p>Plus {ev_count('domain')} cross-realm events, {len(ARCH['domain'])} enemy types shared across realms, and {len(DOMAINS)} special spell domains.</p></section>")

add('<section class="chapter">' + heading(2, "Appendix C: Animal realm naming lore")
    + "<p>How each animal-realm birth names itself and its world: the philosophy behind its names, what parents wish over a newborn, the personal names in use and the places it has named. "
      "This is the source the realm's generated names and much of its event prose draw on. Printed as stored.</p>"
    + naming_lore() + "</section>")

# ------------------------------------------------------------------ TOC render
def toc_html():
    rows = []
    for lvl, hid, label in TOC:
        pg = PAGES.get(hid, "")
        rows.append(f'<div class="toc l{lvl}"><a href="#{hid}"><span class="tl">{esc(label)}</span><span class="dots"></span><span class="tp">{pg}</span></a></div>')
    return '<section class="toc-page"><h2 class="tochead">Contents</h2>' + "".join(rows) + "</section>"


CSS = (HERE / "style.css").read_text()
doc = ("<!doctype html><html lang='en'><head><meta charset='utf-8'><title>Six Worlds: A Writer's Guide</title><style>"
       + CSS + "</style></head><body>" + "".join(body).replace("@@TOC@@", toc_html()) + "</body></html>")
OUT.write_text(doc, encoding="utf-8")
Path(OUT.with_suffix(".toc.json")).write_text(json.dumps([{"level": l, "id": i, "label": t} for l, i, t in TOC]), encoding="utf-8")
print(f"wrote {OUT} ({len(doc)//1024} KB); TOC entries: {len(TOC)}")
