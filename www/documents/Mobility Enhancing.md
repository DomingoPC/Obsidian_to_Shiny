# Mobility Enhancing
Mobility Enhancing is one of the <a href='#' class='note-link' data-id='Manifestations' onclick="Shiny.setInputValue('linked_doc_click', 'Manifestations', {priority: 'event'}); return false;">Manifestations</a> of the Source of <a href='#' class='note-link' data-id='Flow' onclick="Shiny.setInputValue('linked_doc_click', 'Flow', {priority: 'event'}); return false;">Flow</a>. It allows the user to gain speed and maneuverability on any terrain.

---

**Passive:** When you fall prone, you can choose to slide on your belly instead to keep your speed unchanged. As a result, only the following rules apply when you are prone:
- An attacker within 5 ft of you has advantage on attack rolls against you.
- An attacker further than 5 ft of you has disadvantage on attack rolls against you.

**Ground Shake:** as an action, you can generate waves in the ground targeting a creature.
- **If you target yourself:** your speed increases 15 ft.
- **If you target another creature:** You make a ranged attack roll to hit a creature in a range of 30 ft of you. If you are successful, the creature receives 1d4 impact damage and a 5 ft speed reduction.

**Chained Thrust:** as a bonus action, you can go through one creature. This action doesn't trigger a reaction attack when leaving the target's range.
- As part of this skill, you can damage your target releasing part of your remaining speed inside them. The damage is truncated from the result of $\text{Damage} = \frac{1}{5}\cdot\text{(Spent Speed in ft)}$, to avoid decimal numbers.
- When leaving the target's body, you get launched 10 ft into a direction you choose—which is not added to your speed. If you hit another creature, you can freely use this skill again, otherwise, the collision just stops you, leaving you prone or standing.

**Sudden Impulse:** Whenever you are in contact with a creature, as an action you can make them roll a DEX saving throw against your spellcasting DC (8 + INT modifier). 
- If the **target fails**, it is pushed 10 ft into a direction you choose.
- If the **target succeeds**, nothing happens.
- If you are going throw the target as part of **Chained Thrust**, the target fails automatically.

**Ground pulse:** When you are in contact with a surface, you can feel the vibrations inside it. If you succeed in a Perception check, you can know the location of a creature by its steps.
- The target must be up to 60 ft of you.
- For very populated areas, like markets, you roll with disadvantage.
You can also send vibration pulses to creatures in range.
