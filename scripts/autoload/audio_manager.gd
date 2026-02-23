extends Node
## AudioManager - Global sound effect player
##
## Usage:  AudioManager.play("sound_name")
##         AudioManager.play("sound_name", -6.0)   # softer
##
## Sounds are defined in SOUND_MAP below: logical event name → source file prefix.
## Each prefix maps to up to 6 numbered variants (_HY_PC-001 … _HY_PC-006).
## A random variant is picked on every play() call for natural variety.
##
## To swap a sound later: just change the prefix string in SOUND_MAP.
## All other code stays the same.

const SFX_PATH := "res://resources/audio/sfx/"

## Master SFX volume in dB.  0 = full, -7 ≈ 70%, -24 = off.
var sfx_volume_db: float = -7.0

## ============================================================
## DIRECT SOUNDS  —  logical event name → single filename
## ============================================================
## These bypass the variant system: one file, played as-is.
## Takes priority over SOUND_MAP when the same name appears in both.
## ============================================================
const DIRECT_SOUNDS: Dictionary = {
	"ui_click":      "ui_click_kenney.ogg",   # Kenney UI click3
	"ui_denied":     "ui_denied_rpg.wav",      # RPG Sound Pack interface6
	"buff_stats_up": "buff_upgrade_bird.wav",  # Helton Yan Bird Buff 002
}

## ============================================================
## SOUND MAP  —  logical event name → file prefix
## ============================================================
## File pattern: SFX_PATH + prefix + "_HY_PC-NNN.wav"  (NNN = 001–006)
## ============================================================
const SOUND_MAP: Dictionary = {

	# --- WEAPON ATTACKS  (played on the attacker, when the hit lands) ---
	"attack_sword":         "DSGNMisc_MELEE-Sword Slash",         # swords, spears
	"attack_dagger":        "DSGNMisc_MELEE-Bit Sword",           # daggers (lighter, quicker)
	"attack_axe":           "DSGNImpt_MELEE-Homerunner",           # axes (heavy swing)
	"attack_mace":          "FGHTImpt_HIT-Strong Smack",          # maces (blunt impact)
	"attack_unarmed":       "DSGNImpt_MELEE-Hollow Punch",        # fists / unarmed
	"attack_martial_arts":  "DSGNImpt_MELEE-Magic Kick",          # martial arts (mystical kick)
	"attack_ranged":        "DSGNMisc_PROJECTILE-Hollow Point",   # bows / crossbows
	"attack_generic":       "DSGNMisc_HIT-Noisy Hit",             # fallback for unknown weapon

	# --- HIT REACTIONS  (played on the defender when damage lands) ---
	"hit_physical":         "DSGNMisc_HIT-Noisy Hit",             # taking physical damage
	"hit_magic":            "DSGNMisc_HIT-Spell Hit",             # taking magic damage
	"hit_crit":             "DSGNMisc_SKILL IMPACT-Critical Strike", # critical hit lands
	"hit_miss":             "DSGNMisc_MOVEMENT-Phase Swish",      # dodge / miss swish

	# --- SPELL SOUNDS ---
	"spell_cast":           "MAGSpel_CAST-Sphere Up",             # generic spell cast wind-up
	"spell_cast_fire":      "MAGSpel_CAST-Aura Rise",             # fire / explosive cast
	"spell_impact_fire":    "DSGNImpt_EXPLOSION-Fire Hit",        # fire damage lands
	"spell_impact_electric":"DSGNImpt_EXPLOSION-Electric Hit",    # lightning / air damage
	"spell_impact_pierce":  "DSGNImpt_EXPLOSION-Mecha Piercing Punch", # piercing spell impact
	"spell_impact_generic": "DSGNMisc_HIT-Spell Hit",             # generic magic impact

	# --- BUFFS & STATUS ---
	"buff_apply":           "DSGNSynth_BUFF-Generic Buff",        # positive buff gained
	"buff_stats_up":        "DSGNSynth_BUFF-Stats Up",            # stat boost specifically
	"debuff_apply":         "DSGNSynth_BUFF-Enemy Debuff",        # debuff / status inflicted
	"buff_failed":          "DSGNSynth_BUFF-Failed Buff",         # buff resisted / failed
	"heal":                 "MAGAngl_BUFF-Simple Heal",           # healing received

	# --- OVERWORLD / PICKUPS ---
	"pickup_gold":          "DSGNTonl_USABLE-Coin Toss",          # gold found
	"pickup_item":          "DSGNTonl_USABLE-Magic Item",          # item pickup
	"pickup_buff":          "DSGNTonl_USABLE-Coin Spend",          # map buff collected
	"pickup_cursed":        "DSGNSynth_BUFF-Failed Buff",          # cursed pickup triggered

	# --- UI ---
	"ui_click":             "UIClick_INTERFACE-Positive Click",   # any button press
	"ui_denied":            "UIMisc_INTERFACE-Denied",             # can't do that / locked
}

# Internal: cache of loaded streams, keyed by prefix → Array[AudioStream]
var _cache: Dictionary = {}


func _ready() -> void:
	# Preload direct single-file sounds
	for filename in DIRECT_SOUNDS.values():
		_load_direct(filename)
	# Preload all variant sounds so first-play has no stutter
	for prefix in SOUND_MAP.values():
		_load_variants(prefix)


## Play a named sound.  volume_offset_db is added on top of sfx_volume_db.
func play(sound_name: String, volume_offset_db: float = 0.0) -> void:
	# Check direct (single-file) sounds first
	if sound_name in DIRECT_SOUNDS:
		var stream: AudioStream = _load_direct(DIRECT_SOUNDS[sound_name])
		if stream == null:
			return
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = sfx_volume_db + volume_offset_db
		add_child(player)
		player.play()
		player.finished.connect(player.queue_free)
		return

	# Fall back to variant system
	var prefix: String = SOUND_MAP.get(sound_name, "")
	if prefix.is_empty():
		push_warning("AudioManager.play: unknown sound '%s'" % sound_name)
		return

	var streams: Array = _load_variants(prefix)
	if streams.is_empty():
		return

	var player := AudioStreamPlayer.new()
	player.stream = streams[randi() % streams.size()]
	player.volume_db = sfx_volume_db + volume_offset_db
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


# ----------------------------------------------------------------
# Internal helpers
# ----------------------------------------------------------------

## Load and cache a single direct-path sound file.
func _load_direct(filename: String) -> AudioStream:
	var cache_key := "@" + filename
	if cache_key in _cache:
		var arr: Array = _cache[cache_key]
		return arr[0] if not arr.is_empty() else null
	var path := SFX_PATH + filename
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: direct sound not found: %s" % path)
		_cache[cache_key] = []
		return null
	var s: AudioStream = load(path)
	_cache[cache_key] = [s] if s else []
	return s


## Load and cache all variant files for a given prefix.
func _load_variants(prefix: String) -> Array:
	if prefix in _cache:
		return _cache[prefix]

	var streams: Array = []
	for i in range(1, 7):
		var path := "%s%s_HY_PC-%03d.wav" % [SFX_PATH, prefix, i]
		if ResourceLoader.exists(path):
			var s: AudioStream = load(path)
			if s:
				streams.append(s)

	_cache[prefix] = streams
	return streams
