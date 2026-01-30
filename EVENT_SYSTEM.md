# Event System Documentation

## Overview
The event system provides FTL-style encounters with three types of choices that create meaningful decision-making and reward character building.

## Choice Types

### 🔘 Default Choices (Grey)
- Always available to all players
- Basic options that anyone can take
- Example: "Attack without hesitation", "Walk away"

### ⚡ Requirement Choices (Blue)
- Require specific attribute or skill thresholds
- **Party-wide checking**: ANY party member meeting the requirement allows the choice
- Shows which character meets the requirement
- Rewards specialization and party composition
- Example: "Compliment its fierce appearance" (requires Charm 15)

### 🎲 Roll Choices (Yellow)
- Require a dice roll against a difficulty number
- Roll formula: `d20 + best_party_attribute`
- Uses the highest relevant attribute in the party
- Has separate success/failure outcomes
- Adds tension and unpredictability
- Example: "Attempt to flee" (Finesse vs DC 12)

## Event Data Structure

```json
{
  "id": "unique_event_id",
  "title": "Event Title",
  "realm": "hell",
  "text": "Full event description...",
  "image": null,
  "choices": [
    {
      "id": "choice_id",
      "type": "default|requirement|roll",
      "text": "Choice description",
      "requirements": {
        "attributes": {"charm": 15},
        "skills": {"fire_magic": 2},
        "roll": {"attribute": "finesse", "difficulty": 12}
      },
      "outcome": {...},
      "outcome_success": {...},  // For rolls
      "outcome_failure": {...}   // For rolls
    }
  ]
}
```

## Outcome Structure

```json
{
  "type": "text|combat|shop",
  "text": "Result description",
  "rewards": {
    "xp": 100,
    "items": ["item_id_1", "item_id_2"]
  },
  "karma": {
    "hell": 5,
    "human": -3,
    "god": 2
  }
}
```

## Party-Wide Checking

**Important Design Decision**: Companions' attributes and skills matter!

When evaluating requirement choices:
1. System checks EVERY party member
2. If ANY member meets the requirement, the choice is available
3. UI shows which character enables the choice
4. This makes party composition strategically important

Example:
- Player has Charm 10, companion has Charm 18
- Choice requires Charm 15
- Choice is AVAILABLE because companion meets requirement
- Button shows: "⚡ Compliment its fierce appearance [Companion Name]"

## Roll System

For yellow (roll) choices:

1. **Find Best Roller**: Check all party members for highest relevant attribute
2. **Make Roll**: d20 + that attribute value
3. **Compare**: Total vs difficulty number
4. **Apply Outcome**: Success or failure path

Example:
- Party has Finesse values: 12, 15, 10
- Roll choice needs Finesse check, DC 18
- Uses highest Finesse (15)
- Rolls 8 on d20
- Total: 8 + 15 = 23
- Success! (23 ≥ 18)

## Karma Integration

Every choice can modify karma across multiple realms:

```json
"karma": {
  "hell": 5,      // Violent choice
  "asura": 3,     // Competitive action
  "human": -3,    // Moving away from balance
  "god": 2        // Slight compassion
}
```

Karma accumulates invisibly and determines next reincarnation.

## Current Test Events

### "Wandering Devil" (Hell Realm)
Tests all three choice types:
- Default: Attack or reason
- Requirement: Charm 15 to compliment, Fire Magic 2 to duel
- Roll: Finesse DC 12 to flee

### "Mysterious Trader" (Human Realm)
Tests trading and wisdom:
- Default: Browse shop or walk away
- Requirement: Awareness 14 for special wisdom

## UI Design

**Aesthetic**: Tibetan thangka painting meets manuscript
- Deep reds, golds, indigos (sacred colors)
- Ornate borders with shadow effects
- Choice buttons styled like prayer flags
- Color coding: grey/blue/yellow by type
- Rich text formatting for outcomes
- Roll results displayed prominently

**Visual Hierarchy**:
1. Event title (large, golden)
2. Description (flowing text)
3. Choices (prominent buttons with icons)
4. Outcome (centered, with formatting)

## Integration with Other Systems

### Character System
- Reads attributes/skills for requirement checks
- Grants XP rewards
- Will add items to inventory (TODO)

### Karma System
- Processes karma changes from every choice
- Karma tags guide reincarnation
- No visibility to player (thematic mystery)

### Game State
- Events can trigger combat (TODO: combat system)
- Events can open shops (TODO: shop system)
- Events advance the narrative

## Adding New Events

1. Create event data in EventManager's `event_database`
2. Set realm for proper context
3. Design meaningful choices (mix all three types)
4. Balance karma impacts
5. Write evocative text
6. Test all outcome paths

**Best Practices**:
- Mix choice types (don't use only defaults)
- Make requirements achievable but special (Attribute 12-18, Skill 2-4)
- Set roll DCs challenging but possible (DC 10-18)
- Give meaningful rewards for risky choices
- Use karma to reflect philosophical implications
- Write atmospheric descriptions

## Future Enhancements

### Planned:
- [ ] Load events from JSON files (one per realm)
- [ ] Conditional events (based on previous choices)
- [ ] Multi-stage events (choices lead to more events)
- [ ] Character-specific events (race/background triggers)
- [ ] Rare events with special rewards
- [ ] Combat integration
- [ ] Shop integration
- [ ] Visual images for events
- [ ] Sound effects for choice selection
- [ ] Animated transitions

### Under Consideration:
- Should karma visibility increase with Yoga skill?
- Should there be "hidden" choices that only appear with very high requirements?
- Should some events be one-time only per run?
- Should events have prerequisites (story flags)?

---

**Philosophy**: Events should feel like meaningful encounters in a living world. Every choice matters. Every character has value. Every decision shapes your karma and your fate.
