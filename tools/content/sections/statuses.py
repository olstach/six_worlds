"""Statuses, grouped by category. The file holds a LIST, so addresses use the
index; the ident is the status name (unique today). Description is writing;
polarity, duration and what it does are context, worded from the new fields
(the Python port of TooltipText.describe_*). Grouped by group_of().

Only 39 statuses have a description key today; the rest show (empty) and the
key is created when someone fills it in."""
import json
import re
from pathlib import Path

from ..model import Entry, Field, Group
from ._common import clean

TITLE = "Statuses"
FILE = "resources/data/statuses.json"


# ── The status context line ─────────────────────────────────────────────────
# A Python port of TooltipText.describe_* (scripts/ui/tooltip_text.gd), limited
# to what statuses.json uses, so CONTENT.md says what the tooltip says. A
# wording is changed in the tooltip first, then here. The flag words are not
# copied: they are read from TooltipText.FLAG_LABELS itself.
#
# The line reads as lower-case phrases between dots:
#   negative · turns 3 · −10 armor · cannot move
# Numbers that a spell may override read as their default ("5 fire damage").

_ROOT = Path(__file__).resolve().parents[3]
MINUS = "\u2212"      # a real minus sign, which reads better than a hyphen


def _flag_labels() -> dict:
    """The FLAG_LABELS dictionary of tooltip_text.gd, read as text."""
    path = _ROOT / "scripts/ui/tooltip_text.gd"
    if not path.is_file():      # a copy of tools/ (the sync's own tests) has no game
        return {}
    src = path.read_text(encoding="utf-8")
    block = src.split("const FLAG_LABELS: Dictionary = {", 1)[1].split("\n}", 1)[0]
    return dict(re.findall(r'^\t"([a-z_0-9]+)": "([^"]*)",?$', block, re.M))


def _damage_names() -> dict:
    path = _ROOT / "resources/data/damage_types.json"
    if not path.is_file():
        return {}
    types = json.loads(path.read_text(encoding="utf-8")).get("damage_types", {})
    return {k: str(v.get("name", k)).lower() for k, v in types.items()
            if isinstance(v, dict)}


def _aura_names() -> dict:
    path = _ROOT / "resources/data/auras.json"
    if not path.is_file():
        return {}
    auras = json.loads(path.read_text(encoding="utf-8")).get("auras", {})
    return {k: str(v.get("name", k)) for k, v in auras.items() if isinstance(v, dict)}


FLAG_LABELS = _flag_labels()
AURA_NAMES = _aura_names()
DAMAGE_NAMES = _damage_names()

# Who `to: "source"` is, by what set the trigger off (SOURCE_WORDS in GDScript).
SOURCE_WORDS = {"struck": "the attacker", "attacked_in_melee": "the attacker",
                "incoming_attack": "the attacker", "incoming_spell": "the caster",
                "hit": "the unit it hit", "enemy_enters_reach": "the enemy that came close",
                "ally_threatened": "the threatening enemy"}
TRIGGER_WORDS = {"expire": "when it runs out", "turn_start": "at the start of its turn",
                 "turn_end": "at the end of its turn", "struck": "when struck",
                 "hit": "when it hits", "attacked_in_melee": "when attacked in melee",
                 "incoming_attack": "when attacked",
                 "incoming_spell": "when targeted by a spell",
                 "enemy_enters_reach": "when an enemy comes within reach",
                 "ally_threatened": "when an ally is threatened"}
PERIODIC_WORDS = {"turn_start": "at the start of each turn",
                  "turn_end": "at the end of each turn"}
STAT_WORDS = {"crit_chance": "crit chance"}
IMMUNITY = 100       # Resistance.DECLARED_IMMUNITY


def _lc(text: str) -> str:
    """Lower-case the first letter ("Cannot move" -> "cannot move")."""
    return text[:1].lower() + text[1:]


def _num(v) -> str:
    v = float(v)
    return str(int(round(v))) if abs(v - round(v)) < 1e-9 else f"{v:.1f}"


def _kind(t) -> str:
    if isinstance(t, dict):
        return " and ".join(DAMAGE_NAMES.get(k, k) for k in t)
    return DAMAGE_NAMES.get(str(t), str(t))


def _amount(a) -> str:
    """A magnitude: a number, {min,max}, or the default of a borrowed one
    ({from: status.value, default?, add?}), as an abstract tooltip words it."""
    if isinstance(a, dict):
        if "min" in a and "max" in a and "from" not in a:
            return f"{_num(a['min'])} to {_num(a['max'])}"
        if "base" in a:
            return _num(a["base"])
        if a.get("from") in ("status.value", "status.stacks"):
            return _num(float(a.get("default", 0)) + float(a.get("add", 0)))
        if a.get("from") == "event.damage":
            return f"{int(a.get('pct', 100))}% of the damage"
        who, _, path = str(a.get("from", "")).partition(".")
        return f"{int(a.get('pct', 100))}% of the {who}'s {path.split('.')[-1].replace('_', ' ').capitalize()}"
    return _num(a) if isinstance(a, (int, float)) else str(a)


def _note(a) -> str:
    """Where a borrowed number comes from, as the abstract tooltip says it."""
    if not isinstance(a, dict) or a.get("from") != "status.value":
        return ""
    if "default" in a:
        return " (or the spell's value)"
    if "add" in a:
        return " (plus the spell's value)"
    return " (the spell's value)"


def _resist_name(key: str) -> str:
    return {"all": "all damage", "magic": "magic damage"}.get(key, DAMAGE_NAMES.get(key, key))


def _cleared_by(clauses: list, value: str) -> str:
    """What clears lasting damage: "full rest or White magic 5"."""
    clauses = clauses or [{"rest": "full"}, {"restore": value}]
    out = []
    for clause in clauses:
        for kind, want in clause.items():
            rule = want if isinstance(want, dict) else {}
            if kind == "rest":
                out.append(f"{want} rest")
            elif kind == "heal":
                school = str(rule.get("school", "")).removesuffix("_magic").capitalize()
                text = f"{school} magic" if school else "healing"
                if int(rule.get("min_level", 0)) > 0:
                    text += f" {int(rule['min_level'])}"
                out.append(text)
            elif kind == "restore":
                out.append("a restore")
            elif kind == "cleanse":
                out.append(f"a cleanse of {rule.get('category', 'its cause')}")
    return " or ".join(out)


def _modify(e: dict) -> str:
    value, mode, amt = str(e.get("value", "")), str(e.get("mode", "")), e.get("amount", 0)
    ns, _, name = value.partition(".")
    shown, note = _amount(amt), _note(amt)
    num = isinstance(amt, (int, float))
    if ns == "resource":
        pool = {"hp": "HP", "temp_hp": "temporary HP"}.get(name, name)
        if mode == "restore":
            return f"restores {shown} {pool}{note}"
        if mode == "drain":
            return f"drains {shown} {pool}{note}"
        if mode == "absorb":
            return f"takes {shown} {pool} from the target{note}"
    if num and abs(float(amt) - round(float(amt))) < 1e-9:
        n = int(round(float(amt))) * (-1 if mode == "drain" else 1)
        signed = ("+" if n >= 0 else MINUS) + str(abs(n))
    else:
        signed = (MINUS if mode == "drain" else "+") + shown
    if ns == "resist":
        what = _resist_name(name)
        if mode == "set" and num:
            return f"immune to {what}" if amt >= IMMUNITY else f"{what} resistance set to {int(amt)}%"
        if num and mode == "fortify" and amt >= IMMUNITY:
            return f"immune to {what}"
        return f"{what} resistance {signed}%{note}"
    if ns == "stat":
        word = STAT_WORDS.get(name, name.replace("_", " "))
        if mode in ("fortify", "drain"):
            return f"{signed} {word}{note}"
        if mode == "multiply":
            return f"{word} halved" if num and amt == 0.5 else f"{word} x{shown}"
        if mode == "set":
            return f"{word} set to {shown}"
    if ns in ("attribute", "skill"):
        label = name.replace("_", " ").capitalize()
        if mode in ("fortify", "drain"):
            return f"{signed} {label}{note}"
        if mode == "damage":
            return f"{MINUS}{shown} {label} (until {_cleared_by(e.get('cleared_by') or [], value)})"
    return ""


def _status_op(e: dict, who: str) -> str:
    action = str(e.get("action", ""))
    if action != "apply":
        verbs = {"remove": "removes", "steal": "steals", "transfer": "transfers",
                 "convert": "converts"}
        names = (e.get("select") or {}).get("names") or []
        what = ", ".join(names).replace("_", " ") if names else "statuses"
        return f"{verbs.get(action, action)} {what}"
    d = e.get("duration", 1)
    if isinstance(d, (int, float)):
        turns = f"{int(d)} turn{'' if int(d) == 1 else 's'}"
    else:
        turns = "the whole fight" if d == "combat" else "the spell's duration"
    text = f"{str(e.get('status', '')).replace('_', ' ')} ({turns})"
    if float(e.get("chance", 100)) < 100:
        text = f"{round(float(e['chance']))}% chance of {text}"
    if who:
        text += " on " + who
    for cond in e.get("if") or []:
        if isinstance(cond, dict) and "target_lacks" in cond:
            text += f", unless already {str(cond['target_lacks']).replace('_', ' ')}"
    return text


def _effect(e: dict, on: str = "", when: str = "") -> str:
    """One effect as a phrase (the Python side of _effect_sentence)."""
    op = e.get("op")
    # `attack` names its victim with `target`, every other op with `to`.
    other = e.get("target") if e.get("op") == "attack" else e.get("to")
    who = SOURCE_WORDS.get(on, "the other unit") if other == "source" else ""
    a = e.get("amount")
    text = ""
    if op == "damage":
        kind = _kind(e.get("type", "physical"))
        if isinstance(a, dict) and a.get("from") == "event.damage":
            taken = on in ("struck", "attacked_in_melee", "incoming_attack", "incoming_spell")
            share = f"{int(a.get('pct', 100))}% of the damage {'taken' if taken else 'dealt'} as {kind} damage"
            text = ("reflects " + share) if taken else share
            if "min" in a:
                text += f" (at least {int(a['min'])})"
        elif isinstance(a, dict) and a.get("pct_of") == "target.max_hp":
            text = (f"it dies ({kind} damage)" if float(a.get("value", 0)) >= 100
                    else f"{int(a.get('value', 0))}% of max HP as {kind} damage")
        else:
            text = f"{_amount(a)} {kind} damage"
        if who:
            text += " to " + who
        if not isinstance(a, dict) or a.get("from") != "event.damage":
            text += _note(a)
    elif op == "heal":
        text = "heals to full HP" if a == "full" else f"heals {_amount(a)} HP"
        if who:
            text += " for " + who
        text += _note(a)
    elif op == "modify":
        text = _modify(e)
    elif op == "status":
        text = _status_op(e, who)
    elif op == "attack":
        text = "makes a free attack against " + (who or "the other unit")
        if "power_pct" in e:
            text += f" at {int(e['power_pct'])}% power"
    elif op == "negate":
        text = "the attack misses"
    elif op == "reflect":
        text = "it is turned back on whoever sent it"
    elif op == "move":
        n = int(e.get("tiles", 1))
        mover = "moves itself" if e.get("to") == "caster" else "moves " + (who or "the target")
        text = f"{mover} {n} tile{'' if n == 1 else 's'} ({str(e.get('mode', '')).replace('_', ' ')})"
    elif op == "summon":
        n, what = int(e.get("count", 1)), str(e.get("as", "")).replace("_", " ")
        text = f"a {what} emerges" if n == 1 else f"{n} {what} emerge"
    elif op == "kill":
        text = "kills it outright"
    elif op == "zone":
        text = f"lays a {str(e.get('zone', '')).replace('_', ' ')} zone"
    elif op == "resurrect":
        text = "raises the fallen"
    if not text:
        return ""
    if when:
        text += " " + when
    scale = e.get("scale") or {}
    if scale.get("per") == "turn_active":
        text += f", {_num(scale.get('amount', 0))} more for each turn it has lasted"
    elif scale.get("per"):
        text += f", more with {str(scale['per']).replace('_', ' ')}"
    if "chance" in e and op != "status" and float(e["chance"]) < 100:
        text += f" ({round(float(e['chance']))}% chance)"
    return text


def describe_flags(flags) -> list:
    out = []
    for f in flags or []:
        f = str(f)
        text = ("Immune to " + f[len("immune:"):].replace("_", " ") if f.startswith("immune:")
                else FLAG_LABELS.get(f, f.replace("_", " ").capitalize()))
        if text not in out:
            out.append(text)
    return out


def describe_triggers(triggers) -> list:
    out = []
    for t in triggers or []:
        on = str(t.get("on", ""))
        parts = [x for x in (_effect(e, on) for e in t.get("effects", [])) if x]
        if not parts:
            continue
        when = TRIGGER_WORDS.get(on, on.replace("_", " "))
        reach = t.get("reach")
        if on == "struck" and isinstance(reach, int) and reach == 1:
            when = "when struck in melee"
        bits = []
        if "chance" in t:
            bits.append(f"{round(float(t['chance']))}% chance")
        if reach is not None and not (on == "struck" and reach == 1):
            bits.append("within weapon reach" if reach == "weapon"
                        else f"within {int(reach)} tile{'' if int(reach) == 1 else 's'}")
        lim = t.get("limit") or {}
        if lim:
            n = int(lim.get("count", 1))
            text = ("once" if n == 1 else f"up to {n} times") + " a turn"
            if lim.get("once_per_source"):
                text += ", once per attacker"
            bits.append(text)
        out.append(when + (f" ({', '.join(bits)})" if bits else "") + ": " + ", ".join(parts))
    return out


def effect_parts(s: dict) -> list:
    """What a status holds, ticks, answers and switches on, one lower-case
    phrase each, in the order the tooltip words them (while_active, periodic,
    triggers, flags). tools/fixtures/status_wording.json is the GDScript
    side of exactly this list, and a test compares them."""
    parts = [_effect(e) for e in s.get("while_active") or []]
    per = s.get("periodic") or {}
    when = PERIODIC_WORDS.get(per.get("when", "turn_start"), PERIODIC_WORDS["turn_start"])
    parts += [_effect(e, "", when) for e in per.get("effects", [])]
    parts += describe_triggers(s.get("triggers"))
    parts += describe_flags(s.get("flags"))
    return [_lc(p) for p in parts if p]


def _context(s: dict) -> str:
    """negative · turns 3 · −10 armor · cannot move: polarity, duration, then
    what it holds, ticks, answers and switches on, one phrase each."""
    parts = [str(s.get("polarity", ""))]
    dur = s.get("duration") or {}
    if isinstance(dur, dict) and dur.get("kind"):
        n = dur.get("base")
        parts.append(f"{dur['kind']} {n}" if n is not None else str(dur["kind"]))
    parts += effect_parts(s)
    # An aura is worded by the tooltip from auras.json; here it is just named.
    auras = s.get("aura") or []
    for aura_id in ([auras] if isinstance(auras, str) else auras):
        parts.append("aura: " + AURA_NAMES.get(aura_id, str(aura_id).replace("_", " ")))
    if s.get("save"):
        parts.append("save " + str(s["save"].get("stat", "")))
    if s.get("spread"):
        parts.append(f"spreads {round(float(s['spread'].get('chance', 0)))}% a turn")
    return clean(" · ".join(_lc(p) for p in parts if p))


def group_of(s: dict) -> str:
    """The heading a status sits under: its first category, else its polarity.
    `magical` is skipped — it says what a dispel may take, not what the status
    is, and nearly every status has it."""
    for c in s.get("categories", []) or []:
        if c != "magical":
            return str(c)
    return str(s.get("polarity", "other"))


# Readable words for the short category ids. A category made of several
# parts ("dot_cc") is read part by part and joined with "and".
CATEGORY_WORDS = {"cc": "crowd control", "dot": "damage over time",
                  "hot": "healing over time"}
# A category with a dot ("elemental.fire") reads as its two words.


def category_title(cat: str) -> str:
    """'cc' -> 'Crowd control', 'dot_cc' -> 'Damage over time and crowd
    control', 'buff' -> 'Buff'. The id itself stays on the heading as its
    `ident`, so this title is only for reading (renaming it moves nothing)."""
    parts = [CATEGORY_WORDS.get(p, p) for p in str(cat).replace(".", " ").split("_") if p]
    text = " and ".join(parts) if parts else str(cat)
    return text[:1].upper() + text[1:]


def build(ds) -> Group:
    rows = ds.get(FILE).get("statuses", [])
    by_cat: dict = {}
    seen: set = set()
    for i, s in enumerate(rows):
        if not isinstance(s, dict):
            continue
        ident = clean(s.get("name", "")) or f"#{i}"
        if ident in seen:          # keep idents unique among siblings
            ident = f"{ident}#{i}"
        seen.add(ident)
        by_cat.setdefault(group_of(s), []).append((i, ident, s))
    top = Group(TITLE, 1)
    for cat, items in by_cat.items():
        g = Group(category_title(cat), 2, cat)
        for i, ident, s in items:
            # Always emit the field: an absent key shows as (empty) and the
            # sync creates the key when the owner writes text there.
            fields = [Field("desc", s.get("description", ""), "text",
                            (FILE, "statuses", i, "description"))]
            g.entries.append(Entry(
                key=f"statuses:{i}", title=s.get("name", ident), ident=ident,
                title_path=(FILE, "statuses", i, "name"),
                context=_context(s), fields=fields))
        top.groups.append(g)
    return top
