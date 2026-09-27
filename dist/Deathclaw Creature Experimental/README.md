# Deathclaw Creature — territorial v3.3

Local mod requiring CET and Codeware. Restart through MO2 Play after installation,
load a save, and open CET. The panel must say **Territorial brawler v3.3**.
Remove an existing creature before spawning another. Nothing spawns automatically.

- **Spawn beside V**: eight metres ahead, grounded by raycast. Use clear outdoor ground.
- **Spawn Mother beside V (2x)**: separate entity with experimental animation graph
  that applies a 2x transform to Root after the deformation pose. This replaces
  v3.2's ineffective visualScale. Native graph roundtrip verifies the scale and
  upstream connection; visible size and animation still need an engine test.
  Native collision and melee reach are not doubled. Choose size when spawning.
- **Spawn creature**: original Wind Farm location. **Visit creature area** teleports V there.
- **Patrol and hunt NPCs**: patrol waypoints extend about190m from spawn (200m territory),
  detect within120m, pursue automatic targets within300m of spawn. Reject patrol
  ground more than10m above/below spawn to limit roof/street excursions from beaches.
- **Attack NPC I am looking at**: aim with CET closed, then open it. Explicitly selected
  follower NPCs have their follower role and companion cache cleared; restore through
  AMM or respawn afterward. AMM invulnerability is untouched. Its registry augments
  native target detection.
- **Attack V**, **Inspect creature**, **Remove creature** remain available.

V is ignored during automatic patrol unless it attacks. Health is20x the donor,
outgoing damage4x. V3 telemetry verified7776 maxHP and4x pre-final hit damage.
V3.3 filters the donor equipment to Wea_Fists only for both weapon groups and strips
unexpected ranged weapons from hand slots. The installed game database was read
and confirms the primary donor group contains a Wea_Fists item. Donor records and
other Animals NPCs are never edited. Damage modification is scoped to this creature.

Threats persist without repeatedly restarting attacks. No close-target or manual
combat timeout; distant automatic stalled pursuits can be released after30seconds.
CET's scanner name chunk is overridden only for this entity to Deathclaw or Mother
Deathclaw, without the donor archetype suffix. Other scanner fields may still reflect
native NPC data. Names and new loadout require an in-game check.

No distance-based despawn. A temporarily missing entity handle retains its ID and
is retried instead of being immediately deleted. Manual removal, CET shutdown/reload
and a20-second initial spawn failure can remove it. The creature does not persist
in saves; world unloading ends the session. This is loaded-world AI, not an offscreen
wildlife simulation. The game can still unload actors independently.

V3.2 disappearance cause is not proven: the last snapshot had a living entity about
192m from V and31m higher. The controller now logs missing handles and deletion
reasons; the panel shows last measured distance. Diagnostics in MO2 overwrite's
DeathclawCreature directory include health, target, position, hit counts, weapon
removals and warnings. These cannot prove visible rendering.

The normal1.96m body retains v2's man_big brawler rig, attacks and archive. Tail and
fingers remain rigid. The independent3.2m Wind Farm statue remains available.
The separate deathclaw_mother.archive adds only the Mother entity and animation graph.
Restart is required to load that new archive. No vehicle passenger ejection or
vehicle-smashing animations are implemented; use soldiers on foot for early tests.

Mock controller regression tests and Mother native graph readback pass. V3.3 native
combat, scanner names, Mother size and rendering need user testing. Keep all extracted
Bethesda assets and this prototype local. V3.2 rollback ZIP is preserved in dist.
