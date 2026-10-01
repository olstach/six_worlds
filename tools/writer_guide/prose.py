"""Hand-written chapters of the writer's guide (everything that is not pulled from game data).

Each chapter is a function returning an HTML string. Headings are added by build.py,
so these hold body content only. Keep the voice plain: the reader is a writer, not an engineer.
"""

WELCOME = """
<p>Alice, thank you for taking this on.</p>
<p>This document is the whole of <em>Six Worlds</em> as it stands, written for someone who will be
writing inside it. It explains what the game is and how it works in terms a player would
recognise, with no code and no numbers you don't need. Then it sets out everything the game
already contains: the realms, the births, the backgrounds, the companions and every event
written so far.</p>
<p>The game is a passion project by Olaf, who has written most of what is here. The remainder was drafted by an AI assistant
and is waiting for a human hand; wherever that matters, this guide says so (see chapter 28).
Your voice is wanted most in the two places the game leans on hardest: <strong>characters</strong>
(the companions you can recruit, the births and backgrounds that define who you are) and
<strong>events</strong> (the short branching scenes you meet while travelling).</p>
<h3>How to read this guide</h3>
<ul>
<li><strong>Parts I and II</strong> are context: what the game is, and how its systems work.
Read them once, then keep them for reference.</li>
<li><strong>Part III</strong> walks through the realms and prints <em>every event written so far</em>, verbatim.</li>
<li><strong>Part IV</strong> prints every birth, background and companion, verbatim.</li>
<li><strong>Part V</strong> covers what needs writing, the conventions to follow and how to send work back.</li>
</ul>
<div class="note"><strong>Verbatim means verbatim.</strong> Where this guide prints game text (event scenes, choices,
descriptions, companion bios) it is copied straight from the game's data files, unedited.
Small grey lines under it, such as ids and karma, are reference labels added for you and are not game text.</div>
<p>Every event, companion, birth, background and trait carries an <span class="id">id</span>. If you write a
replacement or a new version, quoting the id is all that is needed for it to find its place.</p>
"""

# ---------------------------------------------------------------- PART I

CH1 = """
<p><em>Six Worlds</em> is a tactical role-playing roguelike set inside the Tibetan Buddhist wheel of
life. The wheel has six realms of rebirth: the hells, the hungry ghosts, the animals, the humans, the
jealous gods (asuras) and the gods. The player does not play one hero. They play a stream of lives. A
character is born into one realm as one kind of being, travels and fights and chooses, and sooner or
later dies. Then they are reborn, and <em>where</em> they are reborn is the game's central question.</p>
<p>The game is played in three modes that alternate:</p>
<ul>
<li><strong>Overworld.</strong> A map of one realm, crossed in real time. Towns, shrines, wandering monsters, hidden places
and portals to the next realm.</li>
<li><strong>Events.</strong> Short scenes in the style of <em>FTL</em>: a paragraph of description and a handful of choices. Most of the
game's writing lives here.</li>
<li><strong>Combat.</strong> Turn-based fights on a grid, with spells, weapons, positioning and a party of up to several
characters.</li>
</ul>
<p>It is built in the Godot engine. The visual style is a <strong>thangka</strong> painting frame (ornate
borders in deep red, gold and indigo) around classic <strong>pixel art</strong> characters and landscapes.</p>
<div class="note">The central design idea: Buddhist concepts are not decoration on top of the game; they <em>are</em> the
mechanics. Karma decides your next life. There are no levels, because cultivation is gradual. Your
emotional state (the five poisons and five wisdoms) changes how you fight and what you can do. Writing for the
game means writing inside that cosmology.</div>
"""

CH2 = """
<p>A single run of the game is a loop that repeats across lifetimes:</p>
<ol class="steps">
<li><strong>Reincarnate.</strong> The game picks a realm, a birth (the kind of being you are) and a background (what you did in life). See chapter 5.</li>
<li><strong>Explore.</strong> You cross that realm's map: three to five regions, each with its own feel, monsters and people.</li>
<li><strong>Meet events.</strong> At places on the map, a scene opens. You read it, pick a choice, and something happens: a gift, a fight, a
recruit, a wound, a change of heart. Each choice quietly shifts your karma.</li>
<li><strong>Fight, rest, recruit.</strong> Combat is turn-based. Between fights the party makes camp and recovers, and
companions can be hired in towns and met on the road.</li>
<li><strong>Cross the realm.</strong> At the far end of each realm waits a portal to the next. Some are guarded by a boss.</li>
<li><strong>Die.</strong> When the party falls, the life ends. Karma is tallied; the realm where it is highest becomes your next birth.</li>
</ol>
<p>The loop is roguelike: you start over, but not from nothing. Some things carry across lives, and the
player's own knowledge carries most of all. The realms you have visited are the ones you can be reborn into, so the more of the
wheel you have walked, the more of it can claim you.</p>
<div class="figure">
<svg viewBox="0 0 640 150" width="100%" role="img" aria-label="The loop: born, explore, events and combat, die, karma, reborn">
<defs><marker id="ar" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="#7a1f1f"/></marker></defs>
<g font-family="Liberation Serif, serif" font-size="14" text-anchor="middle">
<rect x="10" y="50" width="100" height="50" rx="6" fill="#f6efe0" stroke="#7a1f1f"/><text x="60" y="80" fill="#2b2118">Reborn</text>
<rect x="150" y="50" width="110" height="50" rx="6" fill="#f6efe0" stroke="#7a1f1f"/><text x="205" y="80" fill="#2b2118">Explore the realm</text>
<rect x="300" y="50" width="110" height="50" rx="6" fill="#f6efe0" stroke="#7a1f1f"/><text x="355" y="73" fill="#2b2118">Events &amp;</text><text x="355" y="90" fill="#2b2118">combat</text>
<rect x="450" y="50" width="80" height="50" rx="6" fill="#f6efe0" stroke="#7a1f1f"/><text x="490" y="80" fill="#2b2118">Death</text>
<rect x="550" y="50" width="80" height="50" rx="6" fill="#efe3c4" stroke="#b8902f"/><text x="590" y="73" fill="#2b2118">Karma</text><text x="590" y="90" fill="#2b2118">tallied</text>
<path d="M110,75 L148,75" stroke="#7a1f1f" marker-end="url(#ar)" fill="none"/>
<path d="M260,75 L298,75" stroke="#7a1f1f" marker-end="url(#ar)" fill="none"/>
<path d="M410,75 L448,75" stroke="#7a1f1f" marker-end="url(#ar)" fill="none"/>
<path d="M530,75 L548,75" stroke="#7a1f1f" marker-end="url(#ar)" fill="none"/>
<path d="M590,100 L590,130 L60,130 L60,102" stroke="#7a1f1f" marker-end="url(#ar)" fill="none" stroke-dasharray="5 4"/>
<text x="325" y="124" fill="#7a1f1f" font-style="italic">the realm with the most karma decides the next birth</text>
</g></svg>
</div>
"""

CH3 = """
<h3>Tone</h3>
<p>The game is serious about its subject and not solemn about it. The hells are cruel but they are also
bureaucratic, absurd and occasionally funny: a demon who files every permit, a torturer who is merely good
at his job. The hungry ghosts are pitiful and uncanny. The animal realm is predatory but also tender and
territorial. A good scene in this game can make you wince and laugh in the same paragraph.</p>
<p>A few rules of thumb, drawn from what already works:</p>
<ul>
<li><strong>Impermanence over spectacle.</strong> Things are always falling apart, being reborn or being forgotten.
Endings are rarely clean.</li>
<li><strong>No moralising.</strong> The game never tells the player a choice was good or bad. Karma is hidden. The consequence is
simply what happens next.</li>
<li><strong>Beings have reasons.</strong> Every monster is somebody: a soldier, a mother, a clerk, a pack leader. Even
the cruel ones are in the realm they are in because of what they did and what they wanted.</li>
<li><strong>Craving, hatred and delusion are the engine.</strong> The realms are made of the same poisons you can feel in
yourself. Let them show up as human, specific and slightly embarrassing motives.</li>
<li><strong>Practice is real.</strong> Mantras, offerings, mandalas, meditation and rites are treated respectfully and
accurately. Sacred names of deities are <em>translated</em> into English, never printed in the original.</li>
</ul>
<h3>Visual identity</h3>
<p>Think of a thangka: the ordered, gilded frame around a scene. The interface is that frame, with deep reds, golds and
indigos. Inside the frame is pixel art, in the manner of classic 16-bit role-playing games. Writing should suit both: crisp
and compact, ornament held back for where it counts. Event text appears in a window the size of a few paragraphs, so
brevity is a virtue.</p>
"""

CH4 = """
<p>The game's systems are all built and the engine runs; what is thin is <em>content</em>. A snapshot:</p>
<table class="grid">
<tr><th>Realm</th><th>Status</th><th>Births</th><th>Events</th><th>Companions</th></tr>
<tr><td>Hell (Naraka)</td><td>Complete first pass</td><td>6</td><td>__HELL_EV__</td><td>__HELL_CO__</td></tr>
<tr><td>Hungry Ghost (Pretaloka)</td><td>Complete first pass</td><td>14</td><td>__HG_EV__</td><td>__HG_CO__</td></tr>
<tr><td>Animal (Tiryakloka)</td><td>Complete first pass</td><td>18</td><td>__AN_EV__</td><td>__AN_CO__</td></tr>
<tr><td>Human</td><td><strong>Empty</strong></td><td>4 defined</td><td>0</td><td>0</td></tr>
<tr><td>Asura</td><td><strong>Empty</strong></td><td>2 defined</td><td>0</td><td>0</td></tr>
<tr><td>God</td><td><strong>Empty</strong></td><td>3 defined</td><td>0</td><td>0</td></tr>
</table>
<p>In addition there are __DOM_EV__ cross-realm events that can occur anywhere, and __N_TRAITS__ traits, __N_BG__ backgrounds and 600-odd
perks.</p>
<p><strong>The game has not yet been played from start to finish.</strong> Each system works on its own, but the complete loop
(reborn, explore, fight, die, reborn) has not been sat down with. Expect the first real playthrough to find rough edges. Part of the
reason for this guide is to get a human reader's eye on the content before it does.</p>
<p>Three realms (Human, Asura, God) have no map, no enemies and no events yet. They are the largest gaps and the
most exciting places to write. Chapter 22 describes what is intended for them.</p>
"""

# ---------------------------------------------------------------- PART II

CH5 = """
<p>Every realm has a hidden <strong>karma</strong> score. Nearly every choice in an event nudges one or more of them up. For
instance, giving food to a starving ghost raises human and god karma, while attacking the weakened thing raises hell. The player
is never shown the numbers. They find out only when they die.</p>
<p>When the party falls, the game checks which realm's karma is highest among the realms the player has visited. That
realm is where the next life begins. Within it, the game rolls a <strong>birth</strong> (some births are common, some rare) and then a
<strong>background</strong>. A fraction of the karma persists into the next life, so habits and tendencies carry over: a player who
steadily feeds the hungry will drift towards the human and god realms, while one who steadily harms will remain among the hells.</p>
<h3>The six karmas</h3>
<table class="grid">
<tr><th>Realm</th><th>The poison behind it</th><th>Typical acts that feed it in events</th></tr>
<tr><td>Hell</td><td>Hatred, anger</td><td>Violence, cruelty, vengeance, killing the helpless</td></tr>
<tr><td>Hungry Ghost</td><td>Craving, greed, clinging</td><td>Hoarding, grasping, refusing to share, clinging to the past</td></tr>
<tr><td>Animal</td><td>Ignorance, instinct</td><td>Trickery, theft, base appetite, avoiding thought</td></tr>
<tr><td>Human</td><td>Desire and a mixed life</td><td>Ordinary decency, trade, kindness with self-interest</td></tr>
<tr><td>Asura</td><td>Jealousy, rivalry</td><td>Competition, ambition, fighting for status</td></tr>
<tr><td>God</td><td>Pride, comfortable bliss</td><td>Compassion, generosity, practice, release</td></tr>
</table>
<div class="note">The Human, Asura and God rows are provisional, since those realms have no content yet. This table is a writer's guideline, not an exact rule. Every choice can move several karmas at once, and the
karma lines printed under each choice in Part III show how Olaf has used it so far. Good writing here
means the choice reads as natural and the karma is a quiet echo of it.</div>
<p>One open design question: should deep practice (Yoga) ever let a character glimpse their own karma? For now, no. The mystery is
part of the point.</p>
"""

CH6 = """
<p>A character has no level. Instead, they have <strong>seven attributes</strong>, a set of <strong>skills</strong>
(chapter 7) and a pool of <strong>experience</strong> they spend freely on improving either. Because XP is spent, never "banked
until the next level", growth is gradual and reflects the idea that enlightenment is not a threshold you cross.</p>
<h3>The seven attributes</h3>
<table class="grid">
<tr><th>Attribute</th><th>What it means in the fiction</th><th>What it does</th></tr>
<tr><td><strong>Strength</strong></td><td>Raw muscle, force of body.</td><td>Hitting hard in melee, carrying more.</td></tr>
<tr><td><strong>Constitution</strong></td><td>Toughness, endurance, a body that holds up under strain.</td><td>Hit points. Half of stamina.</td></tr>
<tr><td><strong>Finesse</strong></td><td>Agility, speed, coordination, light-footedness.</td><td>Dodging, acting first, moving farther, critical hits. Half of stamina.</td></tr>
<tr><td><strong>Focus</strong></td><td>Concentration, discipline of the mind, will.</td><td>Spell power, how strong your magic is.</td></tr>
<tr><td><strong>Awareness</strong></td><td>Perception, intuition, sensitivity to what is around you and within you.</td><td>Mana pool, acting first, noticing things on the map and in events, critical hits.</td></tr>
<tr><td><strong>Charm</strong></td><td>Presence, warmth, the ability to move people.</td><td>Social choices in events, leadership.</td></tr>
<tr><td><strong>Luck</strong></td><td>The way things fall for you. Not a skill; a tilt in the world.</td><td>Critical chance, quality of loot.</td></tr>
</table>
<h3>Derived measures</h3>
<p>A few bars on the character sheet are built out of the attributes: <strong>HP</strong> (life), <strong>Mana</strong> (the
well magic is drawn from), <strong>Stamina</strong> (what physical actions cost), <strong>Initiative</strong> (who acts first),
<strong>Movement</strong> and <strong>Dodge</strong>.</p>
<h3>Power without levels</h3>
<p>Because there are no levels, the game describes how strong someone is <em>relative to you</em> in words: "slightly stronger",
"vastly weaker", and so on. This appears when hiring mercenaries or sizing up an enemy. If you write a line in which a character
judges an opponent, use that register.</p>
<h3>Attributes in events</h3>
<p>Events can open a choice because someone in your party has a high enough attribute ("Charm 15"). Rolls (yellow choices) take the
best party member's attribute plus a d20 against a difficulty. See chapter 13.</p>
"""

CH7_INTRO = """
<p>There are <strong>35 skills</strong>, seven for each of the five elements. A point in a skill does two things: it makes the
character better at the thing the skill names, and it adds to that element's <strong>affinity</strong>. For example, Maces 2 + Earth
Magic 3 + Summoning 1 gives an Earth affinity of 6, which pays out in broader benefits (Earth, for instance, favours hit points and wealth).
Characters therefore drift towards an elemental temperament by what they practise.</p>
<h3>The five elements</h3>
<p>The elements come from the Tibetan tradition, where each is tied to a mental poison and the wisdom it can turn into. This
shapes both skills and the emotional life of characters (chapter 10).</p>
<table class="grid">
<tr><th>Element</th><th>Poison</th><th>Wisdom</th><th>Character</th></tr>
<tr><td>Space</td><td>Delusion</td><td>Openness, clear awareness</td><td>Subtle, transcendent, mind and perception. Healing, curses, persuasion and yoga.</td></tr>
<tr><td>Air</td><td>Envy</td><td>Skilful action</td><td>Quick, restless, clever. Lightning and wind, stealth, knowledge, wit.</td></tr>
<tr><td>Fire</td><td>Desire</td><td>Discernment, warmth</td><td>Passionate, forceful, charismatic. Flames, brute strength, leading, performing.</td></tr>
<tr><td>Water</td><td>Aversion</td><td>Mirror-like clarity</td><td>Flowing, adaptive, subtle. Ice, healing arts, grace, thievery.</td></tr>
<tr><td>Earth</td><td>Pride</td><td>Equanimity</td><td>Solid, patient, material. Stone, armour, trade, smithing, summoning.</td></tr>
</table>
<h3>Skills at a glance</h3>
<p>Each skill is listed with the element it belongs to, a plain description of what it does for a character, and the attribute it
leans on most. Some skills have special value in events (a high Medicine opens healing options; a high Comedy opens a joke that
defuses the situation).</p>
"""

SKILL_BLURBS = {
 # plain-language descriptions, one or two sentences, aimed at writers
 "swords": "Fighting with bladed weapons. Precise, clear-headed, the swordsman's discipline.",
 "martial_arts": "Transcendent unarmed and weapon-less fighting in a wuxia spirit: flying kicks, leaping strikes, a body trained until it seems to move on its own.",
 "space_magic": "Magic of void, distance and dimensions: teleporting, blinking, rifts, illusions of space.",
 "white_magic": "Healing, protection, sacred light: the benevolent magic of blessing and mending.",
 "black_magic": "Curses, debuffs and necromancy: harm that works through the unseen.",
 "persuasion": "Talking people round with words and presence. Opens social choices and gets better prices.",
 "yoga": "Internal cultivation: mantras, meditation, insight into karma, and peaceful solutions. Gives resistance to mental harm.",
 "ranged": "Bows, crossbows and thrown weapons.",
 "daggers": "Small blades and quick strikes. Close, fast and often sneaky.",
 "air_magic": "Wind and lightning. Fast, high-damage magic that can stun and scatter.",
 "ritual": "External ceremony: drawing mandalas, using material components, boosting spells. The craft of rites.",
 "learning": "Knowledge of realms, monsters and lore. Helps in lore-based choices and improves how fast the party learns.",
 "comedy": "Wit, humour and trickster dialogue. A well-placed joke can defuse a fight; also nudges luck.",
 "guile": "Stealth, sneaking, intrigue. Slipping past, lying well, being where you are not expected.",
 "axes": "Axes and heavy chopping weapons.",
 "unarmed": "Fighting with bare hands, fangs or claws. Passionate, direct combat.",
 "fire_magic": "Flame and heat: burning, wide-area damage, and the charming fire of the lotus.",
 "sorcery": "Direct magical power: spells that simply happen (a Fireball, a bolt). The workhorse of attack magic.",
 "might": "Feats of strength and endurance: lifting the gate, wrestling the beast, outlasting hardship.",
 "leadership": "Inspiring and commanding others in battle and beyond. Lets a character lead a larger company.",
 "performance": "Passionate artistic expression: song, dance, seduction. Moves crowds and lifts morale.",
 "spears": "Spears, halberds and polearms. Reach and discipline.",
 "water_magic": "Water and ice: freezing, flooding and controlling the battlefield rather than raw damage.",
 "enchantment": "Spells with duration: buffs, wards, shields, charms. Changes that last for a while.",
 "grace": "Agility, balance and flowing movement. Makes a character harder to hit, quicker to act and faster across the map.",
 "medicine": "Healing arts: treating wounds and illness, making the party's recovery better. Uses up herbs.",
 "alchemy": "Brewing potions and transmuting materials.",
 "thievery": "Lock-picking, pickpocketing, acquiring things that were not offered. Finds better loot and spots traps.",
 "maces": "Blunt weapons and crushing blows.",
 "armor": "Wearing armour and shields well. Better protection from the same gear.",
 "earth_magic": "Stone and earth: spikes, walls, tremors, bark skin, and the sturdiness of the ground.",
 "summoning": "Calling creatures and objects into being: imps, nagas, guardians, hosts.",
 "logistics": "Provisioning and moving a party: stretching food, travelling faster. Uses up food.",
 "trade": "Bargaining, valuing, finding rare goods. Better prices when buying and selling.",
 "smithing": "Making and mending: repairs equipment and restores ammunition. Uses up scrap.",
}

CH8_INTRO = """
<p>Magic in the game is organised by <strong>schools</strong>. There are ten: the five elements (<em>Space, Air, Fire, Water, Earth</em>) and
five further disciplines that cut across them: <em>Sorcery, Enchantment, Summoning, White</em> and <em>Black</em>. Spells are tagged with
more than one school. A Fireball is Fire <em>and</em> Sorcery; a stone shield might be Earth <em>and</em> Enchantment. To cast a spell the character
needs at least one of its schools at the spell's required level; every matching school the character has adds further bonuses to damage or cost.</p>
<p>Spells are bought from guilds and spell trainers in towns, learned from events, or come with a birth or a background. There are about
370 of them, in five tiers of power (levels 1, 3, 5, 7 and 9).</p>
<h3>The ten schools, with sample spells</h3>
"""

SCHOOL_TEXT = {
 "Space": "Void, distance, illusion, perception. Spells that move you, hide you or confuse the enemy.",
 "Air": "Wind and lightning. High damage with stun, scattering and speed. Also birds, flight, sound.",
 "Fire": "Flame, heat, radiance. Burning damage over time in wide areas, plus charm and warmth from the lotus family.",
 "Water": "Ice, flood, vajra-thunderbolt. Less damage than other schools but strong at control: freezing, binding, pushing.",
 "Earth": "Stone, plants, metal, glass. Sturdy protection and solid damage; also growing things and wealth.",
 "Sorcery": "Direct, instant magical power: bolts, balls, blasts. If it just happens, it is probably Sorcery.",
 "Enchantment": "Changes that last: buffs, wards and charms that hold for a number of turns.",
 "Summoning": "Creatures and objects called out of nowhere: imps, skeletons, nagas, hosts and guardians.",
 "White": "Healing, protection, blessing and sacred light. Also dealing with the dead and the departed.",
 "Black": "Curses, poison, necromancy and debuffs. The craft of harm and decay.",
}

# Chosen spell ids per school are looked up by display name in build.py
SCHOOL_PICKS = {
 "Space": ["Magic Missile", "Blink", "Dimensional Rift"],
 "Air": ["Gentle Breeze", "Lightning", "Garuda"],
 "Fire": ["Firebolt", "Fire Lotus", "Balefire"],
 "Water": ["Ice Bolt", "Naga", "Rain of Revival"],
 "Earth": ["Stone Spike", "Stone Wall", "Earthquake"],
 "Sorcery": ["Fireball", "Mark for Death", "Voidbolt"],
 "Enchantment": ["Haste", "Mirror Image", "Berserk"],
 "Summoning": ["Imp", "Skeleton", "Agnideva Lord"],
 "White": ["Cure", "Pacify", "Cleansing Fire"],
 "Black": ["Life Drain", "Hands of the Damned", "Festering Wound"],
}

CH8_DOMAINS = """
<h3>The domains: spells that cross two elements</h3>
<p>Beyond the ten schools there are <strong>ten special domains</strong>, each born where two elements meet. Domain spells are
<em>not</em> sold in ordinary guilds. They can only be learned through rare events in the world, each tied to a place, such as a crystal
cave or a smoking mirror, and some are sold afterwards by the people you meet there. A domain is as much a place and a story as a set of spells.</p>
"""

CH9_INTRO = """
<h3>Traits</h3>
<p>A <strong>trait</strong> is a standing fact about a character: something they are or have become, not something they have bought.
Traits are the main way a character feels like a <em>person</em> in a scene. They show up in events (a character who is
<em>curious</em> sees options that an <em>incurious</em> one does not), shape how companions get along, and subtly tilt the emotional
life described in chapter 10.</p>
<p>Traits come from several places:</p>
<ul>
<li><strong>Inborn:</strong> rolled at creation: one <em>physical</em>, one <em>personality</em> and one <em>behavioral</em> trait.</li>
<li><strong>Racial:</strong> come with the birth (a dura is <em>armored</em>, a gana has the <em>colony mind</em>).</li>
<li><strong>Acquired:</strong> earned during play. A scar after a severe wound, a limp after losing a limb, <em>death-touched</em> after
surviving a fatal blow, <em>long-marched</em> after thirty rests on the road, <em>bloodied</em> after killing a boss. Events can also grant or remove traits.</li>
</ul>
<p>Traits are one of the most useful things for an event writer, because an event can open (or close) a choice depending on whether a
party member has a given trait, and companions come with their own. The full list follows.</p>
"""

CH9_PERKS = """
<p>Skills also unlock <strong>perks</strong>: special abilities bought with experience once a skill is high enough. There are around
600. Some are passive (a standing bonus), some active (a technique used in combat), a few are <em>mantras</em> (spiritual practices).
Perks are the "purchase" side of a character: a trait is what you are, a perk is what you learned to do.</p>
<p>Roughly 500 of them have an empty flavour line waiting for a human voice. A flavour line is one evocative sentence
under the mechanical description. Below, two perks from each skill give the idea. (The mechanical wording is Olaf's shorthand and
is not the final player-facing text.)</p>
"""

CH10 = """
<p>Beneath hit points and skills, every character has a quieter set of numbers: a <strong>mind</strong>. Five scales, one per element,
each running between a poison (<em>klesha</em>) and the wisdom it can become. Events and fights press on these scales
(<em>pressure</em>), and the scales slowly drift back towards a baseline the character's birth and traits set. A character whose pressure
is pushed far enough tips into a named state. A character who is happy and well might sit in a wisdom state; one under
strain may become <em>Irritable</em>, then <em>Grief-struck</em>, then <em>Poisonous</em>. These states change what they can do in a fight and which options an event offers.</p>
<p>There are 30 named states: five elements × two poles × three intensities. This is the canonical five-poisons / five-wisdoms scheme:</p>
"""

PSYCH_TABLE = [
 ("Space", "delusion", "Confused / Dissociated / Absent", "Clear-headed / Open / Luminous"),
 ("Fire", "desire", "Restless / Craving / Consumed", "Warm / Magnetizing / Radiant"),
 ("Water", "aversion", "Irritable / Grief-struck / Poisonous", "Focused / Clear-eyed / Compassionate"),
 ("Earth", "pride", "Insecure / Arrogant / Humiliated", "Grounded / Equanimous / Unshakeable"),
 ("Air", "envy", "Anxious / Paranoid / Envious", "Alert / Inspired / Brilliant"),
]

CH10_AFTER = """
<p>In practice, when writing an event the useful question is: <em>which of the five does this situation touch, and does it make the
character better or worse at it?</em> A scene about a bereaved parent presses on Water; a scene about a rival's success presses on
Air. Events can push a character's mind in either direction as a reward or a cost.</p>
<h3>Relationships between characters</h3>
<p>Companions also form bonds with each other. The game scores their rapport on shared interests and temperaments (vices, devotion,
martial pursuits, the arts, scholarship, sociability, solitude, grief, order, animals, hardship, wonder) and sorts each pair into
<em>rival, cool, neutral, warm</em> or <em>sworn</em>. Certain pairings trigger short events at camp; more of these are welcome.</p>
"""

CH11 = """
<p>Bodies matter. Characters can be <strong>wounded</strong>, and wounds are not just lost hit points: a deep cut, a broken arm, an
infection or a disease stays with the character, can worsen if untreated, and needs a healer or rest to mend. Where a wound lands
(head, torso, arm, leg and so on) changes what it costs them.</p>
<p>Not every birth has a human body. The game has <strong>body plans</strong> (human, four-armed, serpentine, avian, mantis and others), so a
naga does not wear gloves and a four-armed yaksha can hold a weapon in each pair of hands. Equipment and wounds follow the plan.</p>
<p>Permanent injury leaves marks that can themselves be characterful: a scarred veteran, a maimed survivor, a character who has grown
a prosthetic. Writing that acknowledges the body (a limp noticed by a guard, a missing arm mentioned by a healer) adds weight to a scene.</p>
<p>Wounds and illness are one place the game currently has <em>too few</em> realm-specific varieties. Frostbite and burns for hell,
malnutrition for the hungry ghosts and parasites for the animals are all wanted (chapter 28).</p>
"""

CH12 = """
<p>Combat is a turn-based tactical battle on a grid. Both sides take turns in an order set by initiative. On a turn, a character can
move, strike with a weapon, cast a spell, use a skill or item, or hold position. Position matters: who is adjacent, who is flanked, what the terrain is.</p>
<ul>
<li><strong>Weapons</strong> follow the weapon skills (swords, spears, axes, maces, daggers, ranged, unarmed). Different weapons have different reach.</li>
<li><strong>Spells</strong> may hit a single target or an area, apply lasting <em>statuses</em> (burning, frozen, stunned, blessed and many more) and can be
resisted by a saving throw.</li>
<li><strong>Terrain and auras</strong> change a fight: cursed soil that raises the dead, a circle that protects allies from magic, a shroud of darkness.</li>
<li><strong>Enemies</strong> are generated from <em>archetypes</em> (a Demon Warrior, a Preta, a Gana Alpha) with roles such as frontline, ranged or support. Their strength is
built to the party's own, so they are neither pushovers nor walls.</li>
<li><strong>Bosses</strong> guard the portals between realms and are meant to be set pieces. Their special mechanics are mostly still to be designed.</li>
</ul>
<p>The writer's job in combat is mostly through <em>names and framing</em>: the names of enemy types, what a pass-guardian says before the fight, what an event describes just before blades
are drawn, and what is said after victory. Combat outcomes in events specify which group of enemies appears and how hard the fight is.</p>
"""

CH13 = """
<p>Events are the heart of the writing. An event is a short scene that opens when the party walks onto a particular place on the map,
or sometimes when they camp. It has a <strong>title</strong>, a <strong>body</strong> (usually one to four paragraphs), and a set of
<strong>choices</strong>. The player picks one and gets an <strong>outcome</strong>: a few lines of text, plus anything that happens
(a fight, a shop opening, a companion joining, items, wounds, a change of mind).</p>
<h3>Three kinds of choice</h3>
<p>The game follows the <em>FTL</em> model, using colours:</p>
<table class="grid">
<tr><th>Colour</th><th>Kind</th><th>When it appears</th><th>Typical use</th></tr>
<tr><td><span class="badge grey">Grey</span></td><td>Default</td><td>Always available.</td><td>The basic options: fight, flee, give, ignore, ask.</td></tr>
<tr><td><span class="badge blue">Blue</span></td><td>Requirement</td><td>Only if someone in the party meets a condition (a skill level, an attribute, a trait). Always succeeds.</td><td>The reward for building a character well: the healer's remedy, the scholar's insight, the yogi's teaching.</td></tr>
<tr><td><span class="badge yellow">Yellow</span></td><td>Roll</td><td>Always shown. A d20 plus the best party attribute or skill against a difficulty.</td><td>The risky option with a good and a bad ending. Needs <em>two</em> outcomes written.</td></tr>
</table>
<h3>The whole party counts</h3>
<p>If <em>any</em> party member meets a requirement, the choice opens, and the interface shows who enabled it. This is why companions matter:
bringing the right person makes whole branches of the game appear. When writing a blue choice, consider which kind of character would
naturally have that knowledge and let the line reflect it.</p>
<h3>Outcomes</h3>
<p>An outcome is one of a few types:</p>
<ul>
<li><strong>Text:</strong> some prose, with optional rewards or penalties (experience, gold, items, a trait, a wound, a shift of mind).</li>
<li><strong>Combat:</strong> a fight against a named group, easy, normal or hard. May carry a line of prose before it and another after victory.</li>
<li><strong>Shop:</strong> opens a merchant or trainer.</li>
<li><strong>Recruit:</strong> a companion offers to join, either a specific one or a random one from the zone.</li>
<li><strong>Follow-up:</strong> chains to another event.</li>
</ul>
<h3>Karma on every choice</h3>
<p>Each choice records which realms it feeds. In Part III this appears as a small line such as <span class="karma">Karma: Hell +3, Asura +2</span>.
These are Olaf's choices and not rules; if your outcome has a different moral colour, the karma line may need to change with it.</p>
<h3>Triggered events</h3>
<p>Some events do not live on the map at all. They occur at camp on a rest night: <em>trait events</em> (a character with a particular trait is
the subject) and <em>relationship events</em> (two companions whose bond has reached a certain level). These use <code>{a}</code> and <code>{b}</code> as
placeholders for the characters' names. Eleven exist; more are very welcome.</p>
<h3>Practical notes for writing events</h3>
<ul>
<li>Target at least <strong>two meaningful checks</strong> (blue or yellow choices) per event. About 53 events are currently grey-only.</li>
<li>Keep outcome text short. A line or two is often better than a paragraph.</li>
<li>Think about who might be in the party: a yogi, a thief, a hunter, a priest. Give them a moment.</li>
<li>Remember that choices cost things: a yellow choice may cost gold or food, and the cost appears with the choice.</li>
</ul>
"""

CH14 = """
<p>A party is the player's character plus up to several <strong>companions</strong>. Companions are recruited in towns (as mercenaries, for a
fee), met on the road (some join through events) or found in guilds. Each is a complete character, using the same rules as the player's:
a birth, a background, traits, a build of skills, spells and gear. The only difference is that their story has already been
started: they come with a short bio, a personality and often a reason to be there.</p>
<p>This is the main area where your writing lives. A companion bio is two or three sentences that must do a great deal: who they were,
why they are here, what they are like to travel with. The best existing ones do it with one telling detail and a dry joke, for instance
a butcher "who followed every regulation, filed every permit, and enjoyed his work with a thoroughness that made inspectors nervous."</p>
<p>Companions have <strong>names with meanings</strong>. Hell and hungry-ghost companions have names drawn from Tibetan, Sanskrit and other languages, and
each has a short note saying what it means. The animal realm has its own naming traditions for each birth (Appendix C).</p>
<p>Companions also react to each other (chapter 10) and to the events they are part of. They are never silent equipment.</p>
"""

CH15 = """
<p>Time passes as the party moves. Days and nights accumulate, and the game keeps a <strong>lunar calendar</strong>: new moons and full moons matter,
for karma and for certain practices. Resting costs time and supplies.</p>
<h3>Rest</h3>
<p>There are three tiers of rest: a <strong>Quick Rest</strong> (a partial recovery that costs a little food), a <strong>Camp</strong> (a better recovery that also uses herbs and scrap and mends some gear), and a
<strong>Full Rest</strong> (full recovery, a clean slate for the mind, and fully repaired gear, at the highest cost in food, herbs and scrap). Each takes the night. Rest is not free healing; it is a choice about supplies and risk, and things can happen in the dark.</p>
<h3>Camp activities</h3>
<p>At camp, party members can spend their time on activities that use their skills:</p>
<ul>
<li><strong>Sadhana:</strong> karma-purification practice (Ritual and Yoga).</li>
<li><strong>Mantra recitation:</strong> quiet accumulation of mantras; counts build towards the yidam relationship and, in time, earn traits.</li>
<li><strong>Spiritual cleansing:</strong> purifying psychic corruption and spiritual miasma.</li>
<li><strong>Herb preparation, field surgery, brew potions, brew bombs and poisons:</strong> the medicine and alchemy side.</li>
<li><strong>Deep repair and weapon work:</strong> smithing and upkeep.</li>
<li><strong>Night music:</strong> performance and morale.</li>
</ul>
<p>Camp is also where triggered events happen (chapter 13), and where a quiet moment between two companions can show who they really are.
Realm-specific "something stirs in the night" events are one of the things still wanted.</p>
"""

CH16 = """
<h3>Items</h3>
<p>The game has more than 600 items: weapons, armour, talismans (accessories), ritual implements, potions, ammunition and supplies. Many
are <em>procedurally generated</em> within rarity tiers, so the same sword can come in plain or legendary versions. The four supplies
that drive the overworld are <strong>food, herbs, reagents and scrap</strong>.</p>
<p>Ritual implements and talismans are where the Tibetan material culture shows: bells, vajras, skull cups, thighbone trumpets, mandala plates,
protective amulets. A ritual item may have a story, and item descriptions are another place a writer can add colour.</p>
<h3>Shops, guilds and training</h3>
<p>Towns and places on the map contain people who sell or teach. There are several kinds:</p>
<ul>
<li><strong>General merchants:</strong> sell goods only. <strong>Blacksmiths, fletchers and alchemists</strong> sell weapons, armour, ranged gear and potions and also train a related skill; <strong>healers</strong> sell remedies and white magic.</li>
<li><strong>Towns:</strong> general goods and companions to hire.</li>
<li><strong>Teahouses:</strong> a place to rest, and to recruit companions.</li>
<li><strong>Mercenary guilds:</strong> weapons, armour and fighters for hire. <strong>Veteran camps:</strong> combat training and veterans for hire.</li>
<li><strong>Spell guilds</strong> teach a fixed curriculum of spells in one school; <strong>spell trainers</strong> teach spells and may sell magical items; <strong>yogini circles</strong> offer spells, magic supplies and spiritual companions.</li>
<li><strong>Skill trainers:</strong> pay experience for lessons in skills and attributes.</li>
<li><strong>Domain teachers:</strong> appear only after a domain event; they teach the domain's rare spells (catalogued in chapter 23).</li>
</ul>
<p>Every shop has a name and a short description that greets the player when they arrive. These are catalogued per realm in Part III.</p>
<h3>Money</h3>
<p>Gold is common to all realms, though what it buys differs. Prices shift with the realm and with the party's Trade and Persuasion.
The party can also barter. Money is deliberately scarce and often something events ask you to spend.</p>
"""

CH17 = """
<p>The game treats spiritual practice as a first-class activity, in a few layers.</p>
<h3>Ritual and Yoga</h3>
<p>These are two different skills, and the distinction matters for writing.</p>
<ul>
<li><strong>Ritual</strong> is <em>external ceremony</em>: drawing a mandala, laying out offerings, using material components, and chanting a rite to strengthen a spell.</li>
<li><strong>Yoga</strong> is <em>internal cultivation</em>: meditation, mantra, insight into karma, patient non-violence. Yoga opens the pacifist dialogue options in events.</li>
</ul>
<h3>Mantras and sadhana</h3>
<p>Characters with the right skills can accumulate mantra recitations at camp and perform sadhana, a purification practice that
reduces karma (including the karma that would carry them to a lower rebirth). Both have lunar timing: a full or new moon amplifies them.</p>
<h3>Yidam and Dharmapala (designed, not yet built)</h3>
<p>Two further layers are fully designed but not yet in the game.</p>
<ul>
<li><strong>Yidam</strong> is a personal deity practice. A character develops a relationship with a single meditational deity through
five stages: <em>Heard, Connected, Practicing, Established, Realized</em>. Deities are translated into English ("Adamantine Terrifier", not their Sanskrit
names), each tied to a mantra, a dedicated spell, a possible mask and a quest chain. Commitment to one deity is rewarded.</li>
<li><strong>Dharmapala</strong> are protector deities met at shrines on the map. The relationship is <em>transactional and worldly</em>, a
matter of offerings, and runs through <em>Stranger, Known, Favorable, Under Protection, Bonded</em>. Each protector can intervene a limited number
of times (rerolling fate, giving a glimpse, weakening an enemy) and asks for vows. Breaking a vow damages the bond.</li>
</ul>
<p>Both relationships would persist from one life to the next once deep enough. If you write about practice, avoid inventing sacred names;
see the style guide in chapter 29.</p>
"""

# ---------------------------------------------------------------- PART III

CH18 = """
<p>The traditional wheel of life shows six realms of rebirth. The game follows them in a fixed <em>geography of descent and ascent</em>:
the player starts in Hell, and portals lead outward from realm to realm.</p>
<table class="grid">
<tr><th>Realm</th><th>Sanskrit name</th><th>Quality</th><th>In the game</th></tr>
<tr><td>Hell</td><td>Naraka</td><td>Suffering of hatred. Torment and punishment, ordered and bureaucratic.</td><td>Playable. Combat-focused. Cold hells in the north, hot hells in the south.</td></tr>
<tr><td>Hungry Ghost</td><td>Pretaloka</td><td>Insatiable craving. Starvation amid plenty; clinging to what is gone.</td><td>Playable. Resource scarcity. Swamps, graveyards, charnel grounds.</td></tr>
<tr><td>Animal</td><td>Tiryakloka</td><td>Instinct and predation. Territory, appetite, no time to think.</td><td>Playable. Combat and negotiation. Ocean, forest, meadow, sky.</td></tr>
<tr><td>Human</td><td>Manushyaloka</td><td>The mixed realm. Pleasure and pain in balance; the realm where practice is possible.</td><td>Not yet built. Planned as dialogue- and quest-heavy.</td></tr>
<tr><td>Asura</td><td>Asuraloka</td><td>Jealousy and war. Titans who envy the gods.</td><td>Not yet built. Planned as competitive: duels and rivalry.</td></tr>
<tr><td>God</td><td>Devaloka</td><td>Pleasure and pride. Long lives of bliss that end in surprise.</td><td>Not yet built. Planned as diplomacy and trade, almost no combat.</td></tr>
</table>
<p>Realms are connected by <strong>portals</strong> at the far end of each map, sometimes guarded by a boss. Hell leads to the Hungry Ghost realm,
which leads to the Animal realm, which leads to the Human realm. The order in which the player encounters the realms is the order of this table.
The player may be <em>reborn</em> into any realm they have already visited. Reincarnation destinations thus open gradually.</p>
<p>Each realm carries a <strong>theme</strong> that also shapes its play:</p>
<ul>
<li>Hell is combat. Hungry Ghost is scarcity. Animal is a mix of fighting and negotiation.</li>
<li>Human is for dialogue and quests. Asura is competition. God is diplomacy.</li>
</ul>
<p>The next three chapters present each completed realm: its character, geography, places, creatures, quests and then all of its events in full.</p>
"""

CH22 = """
<p>These three realms have no map, no enemies, no shops and no events yet. What exists is a set of <strong>births</strong> and design notes. This is the
part of the game most in need of writing, and where a fresh pair of eyes will do the most good.</p>
<h3>Human realm</h3>
<p>The most dialogue-heavy realm: a mix of quests, towns and negotiation, with three zones and a different tone for each:</p>
<ul>
<li><strong>West: the steppe of Oddiyana and Gandhara.</strong> Scythian-style nomads and cavalry; a country of riders, archers and raiders. Skills favoured: Ranged, Guile, Daggers.</li>
<li><strong>North-east: Zhang-Zhung.</strong> The proto-Tibetan land of shamanic Bön: yak herders, ritual specialists, high pastures. Skills favoured: Ritual, Yoga, Earth magic.</li>
<li><strong>South-east: coastal trade cities.</strong> Cosmopolitan and mercantile: harbours, caravanserais, bazaars. Skills favoured: Trade, Persuasion, Alchemy.</li>
</ul>
<p>Births already defined: __HUMAN_BIRTHS__.</p>
<h3>Asura realm</h3>
<p>The realm of the jealous gods, locked in endless war with the gods above. Intended to be <strong>competitive</strong>: duels, tournaments, rivalry, a
society organised around status and the constant sting of envy. Births defined: __ASURA_BIRTHS__.</p>
<h3>God realm</h3>
<p>Almost no combat. A realm of <strong>diplomacy and trade</strong>: refined courts, bargaining over beauty and time, and the quiet dread
of those who know the bliss will end. Births defined: __GOD_BIRTHS__.</p>
<h3>What each realm needs</h3>
<p>For each of the three: a map with regions and landmark places; a bestiary (enemy types); a pool of events (the existing realms have 80–150 each);
companions (the existing realms have 23–24 each); backgrounds specific to their births; shops and guilds; a boss and a pass-guardian; and a set of place and personal names.</p>
<p>Realm-specific mechanics to bear in mind while writing: the Human realm is the one where practice becomes possible, so Yoga and Ritual choices should matter more there;
the Asura realm rewards confrontation; the God realm rewards diplomacy and punishes pride.</p>
"""

# ---------------------------------------------------------------- PART IV

CH24 = """
<p>A new life is built from three things:</p>
<ol class="steps">
<li><strong>A realm</strong>, chosen by karma (chapter 5).</li>
<li><strong>A birth</strong>: the kind of being you are reborn as. This is the largest decision: a dura of the animal realm, a red devil of
the hells, a rolang of the hungry ghosts. A birth shapes the body, the temperament, the innate talents and the starting emotional state. Some are common, some rare.</li>
<li><strong>A background</strong>: what that being did before the story begins: a hunter, a guard, an infernal scribe, a charnel yogi. A background
grants starting skills and gear. Some backgrounds are open to all, others belong to one or a handful of births.</li>
</ol>
<p>On top of these: a rolled set of inborn traits (chapter 9), the birth's own racial traits, a few starting skills and spells. From there the player
spends experience however they like.</p>
<p>The player's own life is made this way, and so are <strong>companions</strong>, who are hand-written with a birth and background of their own. A good
companion usually makes the combination <em>mean</em> something: a mantis "who has become a monk", a devil who showed mercy and was exiled.</p>
<p>The next three chapters print the full catalogue: 47 births, every background, and all 99 companions.</p>
"""

# ---------------------------------------------------------------- PART V

CH28 = """
<p>This is a practical list of where writing is wanted, from Olaf's own to-do list, reworded for you.</p>
<h3>1. Prose in the existing realms</h3>
<ul>
<li><strong>A human pass over AI-drafted prose.</strong> The animal realm's 47 zone events, the hungry ghost realm's 34 gap-filling events, the three hungry-ghost boss and pass-guardian events,
and all 24 animal-realm companion bios were drafted by an AI assistant, not by Olaf. They are functional but want a human voice. This is the largest single item.</li>
<li><strong>Events with no checks.</strong> 53 events have only grey choices. The target is at least two meaningful (blue or yellow) options per event.</li>
<li><strong>Perk flavour.</strong> About 500 of 600 perks have no flavour line at all.</li>
</ul>
<h3>2. New events</h3>
<ul>
<li><strong>Hell event chains</strong> from Olaf's original list that were never written: a soul caravan ambush, a devil deserter, a contraband deal, a corrupted simple, a chained pilgrim, a rival party.</li>
<li><strong>More trait events and relationship events</strong> (chapter 13). Only eleven exist.</li>
<li><strong>Realm-specific rest events</strong>: "something stirs in the night" scenes for resting in hell and in the hungry ghost realm.</li>
<li><strong>Quests.</strong> There are three, all in Hell. The hungry ghost and animal realms have none. A quest is a short chain of steps tracked on a board.</li>
<li><strong>Boss and miniboss scenes.</strong> Hungry ghost candidates: the Bone Lord (an earth-magic undead commander), the Great Devourer (a shaza), the Mirror of the Setting Sun (a copper construct), the Matriarch of All Longing (a yidag).</li>
</ul>
<h3>3. Whole realms</h3>
<p>Human, Asura and God (chapter 22). Each needs the full set: map, bestiary, events, companions, backgrounds, shops, bosses, names.</p>
<h3>4. Systems waiting for content</h3>
<ul>
<li><strong>Realm-specific wounds and diseases.</strong> Five exist; ten would be better. Wanted: an arrow wound, a poisoned wound, spiritual corruption (which medicine cannot fix and needs ritual or yoga), hungry-ghost malnutrition, animal parasites, hell frostbite and burns.</li>
<li><strong>Consumables and equipment with realm flavour.</strong> Legendary items exist but ordinary gear is thin on character.</li>
<li><strong>Spells:</strong> astrological spells (Space), a divination-and-eclipse family for the Sun Priestess companion, and prosperity spells (Earth) that give teeth to merchant builds.</li>
<li><strong>Ritual implements' special properties</strong> (a conch's pacifying aura, a bone's life-drain, sky-iron's void field).</li>
<li><strong>Yidam and Dharmapala:</strong> a full roster of deities (translated names, mantras, spells, masks, offerings, vows) and a quest chain for each.</li>
<li><strong>Masks:</strong> a whole design space (wrathful, peaceful, animal-form, ritual, deity masks) for the face slot.</li>
</ul>
<h3>5. Open design questions your writing may inform</h3>
<ul>
<li>Should Yoga let the player glimpse their karma, or should it stay mysterious?</li>
<li>What should it cost to bring someone back from the dead in an event?</li>
<li>Should the world move without the player (external events, rival parties, changing places)?</li>
<li>Should battlefields be marked after a fight?</li>
</ul>
"""

CH29 = """
<h3>Names</h3>
<ul>
<li><strong>Place names</strong> are compounds in Tibetan and Sanskrit. Hell uses short Tibetan roots for what the place <em>is</em>: <em>ro</em> corpse, <em>nag</em> black, <em>dur</em> charnel, <em>trak</em> blood,
<em>mun</em> darkness, <em>jik</em> fear, <em>shi</em> death, <em>bar</em> blazing, <em>me</em> fire, <em>gang</em> glacier, <em>drang</em> cold, <em>drag</em> fierce; joined to place endings such as <em>khar</em> (fort), <em>thang</em> (plain), <em>yul</em> (land), <em>lung</em> (valley),
<em>ri</em> (mountain), <em>dzong</em> (citadel), <em>pura</em> (city). Examples: Rokhar, Nagthang, Krodhapura.</li>
<li><strong>Companion names</strong> come with a meaning. Hell and hungry-ghost companions draw on Tibetan, Sanskrit and other sources (even Egyptian or English) and each has a note on the root.
A name that sounds like what the person is, or ironically unlike it, is a good one.</li>
<li><strong>Animal-realm births name themselves by their own philosophy</strong> (Appendix C): what parents wish over a child, what a place is called. Follow the logic of the birth.</li>
</ul>
<h3>Sacred things</h3>
<ul>
<li>Deities' names are <strong>translated</strong>, not transliterated ("Adamantine Terrifier"): this respects the tradition without publishing what is held to be secret, while keeping the meaning.</li>
<li>Mantras, offerings and rites should be shown accurately and without mockery. Humour should come from <em>people</em> (their vanity, bureaucracy, appetites), not from the practice itself.</li>
</ul>
<h3>Voice</h3>
<ul>
<li>Short, concrete, a little dry. One telling detail beats a paragraph of description.</li>
<li>Choices are written in the imperative or as a short action: "Draw your weapon and attack", "Give teachings".</li>
<li>Outcome text answers the choice immediately. It can be a single line of dialogue.</li>
<li>Dialogue uses straight double quotes and speech in the characters' own idiom.</li>
<li>Never state the karmic or moral meaning of a choice in the text.</li>
</ul>
<h3>Karma guidelines used so far</h3>
<ul>
<li>Feeding, sharing, compassion, release, practice: God and Human.</li>
<li>Greed, hoarding, clinging: Hungry Ghost.</li>
<li>Violence against the weak or against the dead: Hell, Asura.</li>
<li>Trickery and theft: Animal, Hungry Ghost.</li>
<li>Buddhist practice (Yoga, Ritual): God.</li>
</ul>
<h3>Skill and attribute names to use for gates</h3>
<p>Blue choices need a requirement. Use the 35 skill names in chapter 7 and the seven attributes in chapter 6; or a trait by name (chapter 9). A requirement
should make narrative sense: a ritual needs Ritual, a lie needs Guile or Persuasion, a bargain needs Trade.</p>
"""

CH30 = """
<p>Write however is comfortable: a document, a spreadsheet, plain text. What matters is that each piece of text can be matched to the
thing it replaces or extends. Every event, companion, birth, background, trait and shop in this guide carries an <span class="id">id</span> in small grey type; quote it and the text can
be put in its place.</p>
<h3>Editing existing text</h3>
<p>Copy the id, then give the new version of whichever fields you changed (title, body, a choice, an outcome, a companion's bio). Fields you do not mention stay as they are.</p>
<h3>New events</h3>
<p>Use the structure of the printed ones: a title; a body; choices, each marked grey, blue or yellow; for blue, the requirement (a skill and level, an attribute and number, or a trait);
for yellow, what is being rolled on and <em>two</em> outcomes; and an outcome for each. Add a suggested karma line if you have a view; Olaf will check it.</p>
<h3>New companions</h3>
<p>A name (with its meaning), a birth, a background, up to three or four traits from chapter 9, the three skills they are strongest in, and the short bio. Check the birth and background are compatible: backgrounds listed for specific births can only be taken by those births.</p>
<h3>Notes for Olaf</h3>
<p>Anything that feels off (a requirement that does not suit the scene, a choice that never opens, a missing path) is worth flagging in the margin, not silently changing. The game is
untested end to end; fresh eyes will catch things that checks cannot.</p>
"""

GLOSSARY = [
 ("Asura", "The jealous gods, titans who war with the gods. Fifth realm on the wheel in this game's order."),
 ("Background", "What a character did before the story begins. Grants starting skills and gear."),
 ("Birth", "The kind of being a character is reborn as; formerly called 'race' in the code."),
 ("Bön", "The indigenous shamanic religion of the Tibetan plateau that predates Buddhism."),
 ("Charnel ground", "A place where corpses are left; a meditation site in Tibetan Buddhism and a region of the Hungry Ghost realm."),
 ("Dharmapala", "A protector deity. In the game, a worldly, transactional relationship built by offerings at shrines."),
 ("Domain", "A special spell group born where two elements meet; learned only through rare events."),
 ("Element", "One of five: Space, Air, Fire, Water, Earth. Each skill belongs to one."),
 ("Event", "A short scene with choices, met on the map or at camp."),
 ("Karma", "A hidden score for each realm. The highest at death decides the next birth."),
 ("Klesha", "A mental poison: delusion, desire, aversion, pride, envy."),
 ("Mandala", "A sacred diagram or circle. In the game, a ritual construction that boosts spells."),
 ("Mantra", "A sacred utterance repeated in practice. Accumulates at camp."),
 ("Naraka", "The hell realms."),
 ("Perk", "A purchased ability unlocked by a skill level."),
 ("Pretaloka", "The realm of hungry ghosts (pretas)."),
 ("Pressure", "The push on a character's mind that events and fights apply."),
 ("Sadhana", "A spiritual practice. In the game, a camp activity that purifies karma."),
 ("Thangka", "A Tibetan painting on cloth, with an ornate frame. The game's visual model."),
 ("Tiryakloka", "The animal realm."),
 ("Trait", "A standing fact about a character: inborn, racial or acquired."),
 ("Vajra", "A thunderbolt-diamond ritual implement; a symbol of indestructibility."),
 ("Wisdom", "The pure state each klesha can become: openness, warmth, clarity, equanimity, skilful action."),
 ("Yidam", "A personal meditational deity. In the game, a deity practice with five relationship stages."),
]
