# Handoff / remaining verification

The goal is **not complete**. The requested result is a New Vegas Deathclaw statue
actually present and verified somewhere in Cyberpunk's desert.

## Latest resumed audit

User requested continuation after the previous blocked audit. This is the first
resumed attempt. Cyberpunk and MO2 were closed. Reopened MO2 with its correct
working directory; discovery succeeded with a fresh window handle. Graphical
capture again failed with `FrameArrived timed out`; after refreshing and activating
the window, the single retry failed with `window capture timed out`.
No game was launched, no mod files were changed, and in-game verification remains
outstanding. The runtime status still has zero spawn attempts and verified=false.
The goal tool continues to report the prior blocked status; do not mark complete.
Current source/build: `E:\Modding\DeathclawBadlands`.
Installed files match `installed-files.json`. Final ZIP is
`dist/deathclaw_badlands_local_dev.zip`. A complete rebuild via `tools/rebuild.py`
passed. `build_verification.json` deliberately records in-game checks as false.

The latest startup test of the native-constructor entity build remained running
for several minutes with CET reporting DeathclawBadlands loaded. Its status stayed
at “Ready”, zero spawn attempts: no save/nearby-player state was verified.
The game was closed with Alt+F4 before installing the final reproducible rebuild.
The test crash reporter dialogs were dismissed. MO2 remains open on Play.

Launch with:
`E:\Modding\Cyberpunk2077\ModOrganizer.exe -p Play run -e "Cyberpunk 2077"`
Use working directory `E:\Modding\Cyberpunk2077`. The initial guessed named-instance
shortcut failed; this command works. Do not infer startup success from a process
alone: a live process proves running, not that the menu or statue is visible.

Windows Computer Use `@oai/sky` works for window discovery and accessibility text,
but all graphical captures timed out, even after kernel reset and restoring the
game window. The user has a pending question asking whether their normal Play
launch succeeds or their display is off/locked. No answer arrived during this turn.
Do not interact with game menus without a usable observation.

Next requirements:

1. Restore graphical observation, load a suitable existing save, and use the CET
   **Deathclaw Badlands → Visit the statue** button. CET overlay binding is 0xC0
   (backtick key) in the current bindings file.
2. Check actual entity spawn, textures/materials, terrain placement and collision.
   Fix issues based on observed game state. Verify departure/return and save reload.
3. Capture a genuine in-game result and document location. Only then complete goal.

Runtime evidence written under MO2 overwrite:
`E:\Modding\Cyberpunk2077\overwrite\bin\x64\plugins\cyber_engine_tweaks\mods\DeathclawBadlands`.
The matching `init.lua` copy there is intentional: CET otherwise switches its Lua
sandbox to that runtime directory and reports “cannot open init.lua”.

Optional AMM registration is excluded from source/resources, installed files, and
the ZIP. It is preserved in `optional/amm`. Earlier full-package launches crashed;
script-only and script+archive launches without AMM registration stayed running.
The AMM registration issue is narrowed, not proven. It is not needed for the
requested fixed Wind Farm statue. Avoid re-enabling it without diagnosis.

Save backup from before testing: `save-backup-before-testing`. No save was
deliberately loaded, saved, or restored by the agent. No existing MO2 mod settings
or profile selections were changed. The task repository `mo2modlist` was not edited.

## Windowed-mode continuation

User confirmed desktop/display on and changed game to windowed mode. Second resumed
attempt: launched Play through MO2. CET scripting.log at 20:19:00 confirms the
DeathclawBadlands mod loaded. Fresh game window capture failed with `FrameArrived
timed out`; refreshed selection and retry failed with `window capture timed out`.
Game remains running for user-assisted observation. Runtime is Ready, zero spawn
attempts. Need user to load a save, open CET (backtick), use Deathclaw Badlands →
Visit the statue, close overlay and share a screenshot. Inspect writes runtime
evidence we can read directly. No new mod changes in this attempt.

## In-game statue confirmed by user and screenshot

User reports the statue is present and looks great. Game Bar PNG captures at
C:\Users\d\Videos\Captures\Cyberpunk 2077 (C) 2020 by CD Projekt RED 27_09_2026 20_26_00.png
and 20_25_54.png provide actual in-game visual evidence. Runtime inspection confirms
entityFound=true at (3816,-1555,130.17906188965); player is at the viewing spot.
The 20_26_00 capture shows the textured Deathclaw standing on terrain at the Wind
Farm with a cast shadow, partly obscured by the weapon wheel. Collision and reload
checks remain unverified. User is now asking about a roaming creature that attacks
passersby; this requires a separate animated NPC/combat implementation.

## Android creature prototype installed (20:51)

User authorized an animated android-based creature. Separate project under creature/;
new deathclaw_creature.archive and DeathclawCreature CET mod installed in physical
root and MO2 overwrite. Existing statue unchanged. Current game process was left
running; new archive/scripts require a restart through Play.

Extracted original rig into work/creature/fallout_rig.json: 78 nodes, 66 weighted
bones, 4248 vertices, 13 KF animations. Rebound source weights to boxing android's
181-bone man_base_deformations rig. Actual android walk exported and previewed in
Blender (work/creature/android_walk_preview.gif). This is an offline preview, not
in-game confirmation. Tail and fingers rigid; body about 1.8m, giant scaling pending.

New entity clones generic__boxingrobot_ma.ent, keeps 106 components and root
protectors skinned component bound to deformations; replaces mesh with local body,
clears appearances to avoid android exterior. Native NPCPuppet readback verified.
Script clones Character.boxingrobot_easy into Character.LocalDeathclawAndroid.
No global character/faction replacement. Panel: Visit creature area, Spawn creature,
Patrol and hunt NPCs, Attack NPC I am looking at, Attack V, Remove creature, Inspect.
Spawn is manual; patrol begins upon spawn, nearby living NPC search range22m.
Nonpersistent; distance cleanup250m. Mock lifecycle tests passed; native APIs,
appearance-less root mesh behavior, AI, damage, collision, and ragdoll unverified.

Compiled mesh roundtrip:6930triangles,181bones,normalized weights,correct material.
Build verification and installation hashes in creature/. Package under
 dist/deathclaw_creature_experimental.zip.
Next: user restart game, load save, open new CET panel, visit and spawn; read
MO2 overwrite/.../mods/DeathclawCreature/status.json and inspection.json to diagnose.
Native capture still unavailable; user Game Bar captures are usable in Videos/Captures.
Do not claim creature works until actual in-game verification.

## Creature diagnostics follow-up

Previous goal turn made progress (separate animated prototype built/installed).
Revalidated game PID23196 still started20:18:53; CET has not loaded DeathclawCreature
and no runtime status/inspection exists yet. Asked user to restart and spawn it.
Added optional healthPercent, target health/dead/id, maxDistanceFromSpawn diagnostics;
mock tests now exercise movement5m and health72%. Package rebuilt, checks passed,
new script installed to physical+overwrite. Installer skips identical file copies.
This turn also made concrete diagnostic progress; no completion claim. Next required
proof remains the restarted game loading and spawning the actual animated NPC.

## First no-progress creature runtime audit

Previous turn made diagnostic progress. This turn verified a live wait against
Cyberpunk PID23196 (started20:18:53), polling for25seconds. Same process remains;
DeathclawCreature directory contains only init.lua, with no status/inspection.
No new CET startup occurred. No changes to mod assets in this audit. First
consecutive no-progress audit for waiting on restart and in-game creature test.
User already has restart/spawn instructions and a pending result question.

## Second consecutive creature runtime blocker audit

Previous turn was a verified wait on live game PID23196 but produced no new runtime
evidence. Revalidated current state: same PID/start time, creature directory still
only init.lua, no status/inspection, latest Game Bar PNG remains20:26 statue capture.
No safe observation-based game interaction is available because native capture
failed previously; user restart/spawn question remains pending. No mod changes.
Second consecutive audit with the same need for external restart/in-game test.

## Third consecutive creature runtime blocker audit

Previous turn made no progress. Current revalidation again finds game PID23196,
started20:18:53 before installation, no new CET startup and no creature runtime
status or inspection file. Same blocker has now recurred across three consecutive
audits. Native graphical capture remains unavailable; user restart and spawn test
is needed for authoritative runtime evidence. Do not substitute offline previews
or compilation for actual movement/combat verification. Mark goal blocked, not
complete. Resume upon new user input or runtime evidence. No asset changes.

## Large brawler v2 installed and startup checked

User tested v1: spawned, walked/patrolled with limp, entered combat but only blocked,
never attacked, took damage and died in a few hits. Runtime travel15.37m supports
patrol. Preserved in creature/user_test_android_v1.json. User requested aggressive
melee NPC animations and large-human size, confirmed game closed for installation.

Replaced full entity donor with gang__animals_mb.ent and record with
Character.dtn_animals_bouncer2_melee2_fists_mb, cloned as
Character.LocalDeathclawBrawlerV2. Native CreatureEntityBuilder reads donor and adds
body component (102 total), clears appearances. Root/deformation rigs now man_big.
Refit mesh to man_big bind pose:1.956m tall vs1.815m old. Weight mapping still23bones
with rigid tail/fingers;181bones compiled. No arbitrary mesh-only scaling.

Actual man_big melee combat set has124clips including combos/charge/jump attacks;
previewed melee_combo_01_p1 on body. New walk preview uses Animals walk_0. All
compiled verification and lifecycle tests pass. Verifier requires man_big rigs,
normal unarmed action set, and no android animation paths. V2 archive and scripts
installed (physical + MO2 overwrite). Original v1 ZIP preserved as
 dist/deathclaw_creature_android_v1.zip.

Launched Play at21:19:42, PID22400. CET21:19:49 confirms DeathclawCreature loaded;
status.json refreshed to Prototype ready (record initialization succeeded).
Game left running for user test; v2 actual attacks/damage/appearance NOT verified.
Panel still Deathclaw Creature - experimental; version label Large melee brawler v2.
Next: user load save, Visit creature area, Spawn creature, Attack V and allow attack.
No new blocked audit yet: meaningful implementation progress this turn.


## Territorial brawler v3: user-requested aggression and convoy balance

User confirmed v2 attacked/killed V, later fought Voodoo Boys but was hesitant,
NPC hunt/look-at commands unreliable, and durability low. Saved testimony in
creature/user_test_brawler_v2.json. Retained exact v2 creature archive/rig; only Lua
and documentation change. V2 package backed up as dist/deathclaw_creature_brawler_v2.zip.

New unique Character.LocalDeathclawTerritorialV3 clones same Animals brawler,
appends one unique Health Multiplier 20 record without stacking on reload.
ProcessRagdollHit ObserveAfter modifies this creature's outgoing hits x4 before
DealDamages, skips projection, and queues retaliation against incoming instigator.
Game script dump confirms stage order and tracker AddThreat signature; AMM already
uses same damage stage. Patrol scans creature-centered at 50m every0.4s, updates
0.2s, ignores V unless provoked/manual, injects specific threat, sets actor-only
mutual hostility, caches look-at off-overlay. Combat no longer returns early just
because victim is alive; refreshes stalled targets, times out, leashes territorial
pursuits at85m from spawn. Moving/landing hits counts as progress. No vehicle
passenger ejection or smashing animation added.

Mock tests pass; native v3 behavior and actual max HP not tested yet. Running game
PID22400 still contains v2 script; fresh restart/spawn required to validate v3.
Inspect inspection.json for maxHealth, threatInjections, candidates, hit counts,
lastDamage before/after and warning. Physical+MO2 overwrite install required.


## Territorial v3.1: remove combat watchdog interference

User saw repeated wind-ups, one hit, then fight ending with both NPCs alive.
Saved runtime snapshot as creature/user_test_territorial_v3_inspection.json:
maxHP7776, outgoingHits1, incomingHits3, damage28.482->113.929, injections24,
status Target unreachable; resuming territory scan. Thus v3 HP/damage code works,
but watchdog explicitly ended engagement and repeatedly re-triggered it first.
Missing candidates field suggests GetTargetParts(creature,query) returned false.

V3.1 keeps same mesh/archive and health record. Injects threat once on changed
target; sets persistence using CommandInjectThreat source enum from native record.
Clears own persistence before releasing target. Gives opponent its own threat and
TriggerCombat(creature), without making opponent hostile to V. No repeated combat
restart, no close-range timeout, no manual-target timeout. Distant automatic
pursuit (>12m) can time out after30s of no movement/hits. Native target query now
uses player targeting component with range50+distance(V,creature) and filters
actual distance from creature to50m. Diagnostics add querySucceeded, target range/
reason and tracker known/visible/persistence if available.

Regression tests pass including65seconds close combat without restarts or release,
40seconds distant manual target retained, persistence cleared on cancellation,
reciprocal combat invocation, radius filtering and previous lifecycle/damage tests.
V3.1 actual native AI behavior still untested. Restart and fresh spawn needed.
V3 rollback ZIP: dist/deathclaw_creature_territorial_v3.zip.


## V3.2 nearby spawn, broad territory and experimental Mother
User verified decisive attacks on V in v3.1, still ignored spawned NPC. Added
AMM registry as candidate source; manually selected follower NPCs have role/cache
cleared using installed AMM's API pattern. No invulnerability changes.
Spawn beside V places creature8m ahead grounded; Mother variant sets protectors
visualScale2 with Toggle refresh, same as AMM mesh scaling. NOT full rig/hitbox/
reach scaling. Reversible Restore normal size. Needs visual engine test.
Patrol200m radius (waypoints max~194m), detection120m, leash300m, cleanup650m.
Waypoint arrival or120s timeout instead of replacing distant goals every8s.
Mock regression tests include AMM detection, near-V positioning, reversible scale
and explicit follower-role cleanup. Installed Lua only; archive unchanged.


## V3.3: no guns, missing-entity handling, scanner identity, Mother graph
User: v3.2 attacks on Pacifica beach but uses gun, sometimes vanishes; Mother same
size; wants scanner name instead of donor. Snapshot preserved: entity alive,
~192m from V/31m higher, 24outgoing37incoming hits,93.98%health. No evidence of
distance deletion in snapshot; do not claim actual disappearance cause known.

Fists-only equipment group built from donor primary/secondary Wea_Fists entries.
Offline native TweakDB read confirms primary item114125024658 has typeWea_Fists,
entry217750287262. Defensive hand-slot ranged removal every update. Stats untouched.
ScannerName chunk replaced after NPCPuppet.CompileScannerChunks only for this entity;
Deathclaw/Mother Deathclaw, no archetype suffix. Native game script API verified.
Distance deletion disabled; missing live handles retain ID and retry, actual removals
record reason. Ground waypoint elevation capped10m from spawn to reduce roof routes.

Mother: visualScale failed per user. Separate entity references cloned man_big
deformation animgraph. MotherBuilder native CR2W reader/writer inserts SetBoneTransform
NoSnapping offset scale2 at Root before Output node. Original root.OutputNode was
unused; actual animAnimNode_Output.Node link is wrapped. Native readback confirms
scale2 and original upstream animAnimNode_PoseMsToLs. Do NOT use JSON graph conversion:
WolvenKit serializer stack-overflows on cyclic references. Graph uses native reader.
Mother root/deformation components longRange/clientForcedVisibility. No doubled
collision or melee reach. Native engine visual validation still pending.
New additive archive deathclaw_mother.archive installed; basearchive unchanged.
Source tools/MotherBuilder, assets creature/mother/archive. Scriptv3.3 installed
physical+overwrite; fresh restart required for newarchive. Tests pass.
