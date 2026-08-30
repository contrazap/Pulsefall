# Pulsefall — Game Plan

## Product summary

Pulsefall is a compact single-player survival-action game inspired by the core loop of Vampire Survivors. The player moves through an endless-looking neon arena while weapons fire automatically. Chasing enemies drop XP coins, five level-up choices shape the run, and the final upgrade round summons one spiked boss. Defeating the boss wins the run.

The target is a small but complete desktop prototype made in Godot 4.x with geometric placeholder visuals. A normal run should last about 3–5 minutes after tuning.

## Scope principles

- One player character.
- One normal enemy behavior.
- One boss that reuses the normal enemy’s movement and damage behavior with different stats and a clear spiked visual.
- One base auto-targeting projectile weapon.
- Five level-up selections per run.
- Three combat abilities with at most two ranks each.
- Three procedurally placed world pickups.
- An endless-looking, unobstructed arena; no maze generation, obstacle collision, or pathfinding.
- Defeat when player health reaches zero; victory when the boss dies.

## Core loop

1. Move through the arena using keyboard controls.
2. Normal enemies spawn just outside the viewport and chase the player.
3. The player automatically fires at the nearest enemy.
4. Defeated enemies drop XP coins.
5. At an XP threshold, gameplay pauses and three upgrade choices appear.
6. The player selects Vitality, Haste, or one randomly offered combat ability.
7. After the fifth upgrade selection, the boss appears.
8. Defeat the boss to reach the victory screen, or lose all health to reach the defeat screen.

## Controls

- Move: `WASD` and arrow keys.
- Choose upgrade: mouse click. Keyboard selection is optional polish.
- Restart after victory/defeat: button; a keyboard shortcut is optional polish.

## World and presentation

The arena should appear endless. Use a repeating grid/floor presentation that has no reachable visible boundary. Lightweight, non-colliding decorations can be generated around the player and recycled or capped so the node count cannot grow without limit.

Visual direction: dark background, bright geometric characters/projectiles, readable hit feedback, and contrasting UI. All gameplay must remain understandable with placeholder art.

## Gameplay specifications

### Player and base weapon

- The player has health, movement speed, and brief invulnerability after contact damage.
- The base weapon periodically targets the nearest valid enemy and fires a projectile.
- A projectile damages an enemy and disappears after its hit allowance or lifetime is exhausted.
- Exact health, damage, speed, fire interval, and invulnerability values are exported or centralized for tuning.

### Normal enemy

- Spawns outside the visible viewport, not directly on the player.
- Moves directly toward the player; the empty arena makes pathfinding unnecessary.
- Deals contact damage subject to the player’s invulnerability window.
- Drops one XP coin on death.
- Spawn pressure may increase by player level, but this must remain a small configuration change rather than a separate difficulty system.

### XP and finite progression

- XP coins move into the player or are collected when within pickup range.
- Use five XP thresholds. Initial tuning target, expressed as XP required for each next level: `5, 9, 14, 20, 28`.
- XP beyond a threshold carries into the next level.
- Each threshold grants one upgrade selection.
- The boss phase begins immediately after the fifth selection is applied.

### Upgrade choices

Every level-up screen contains exactly three choices:

1. **Vitality** — increase maximum health by 20 and restore 20 health. It may be selected more than once.
2. **Haste** — increase movement speed by 12%. It may be selected more than once.
3. **Random combat ability** — choose one non-maxed ability at random when the screen opens; do not reroll while the screen is open.

Combat ability pool:

| Ability | Rank 1 | Rank 2 |
| --- | --- | --- |
| Multishot | Fire one additional projectile with a small spread | Fire one more projectile |
| Piercing | Each projectile can pass through one additional enemy | Increase the allowance by one again |
| Nova | Emit a radial damage pulse every 5 seconds | Increase its damage and reduce the interval to about 3.5 seconds |

Gameplay pauses while choices are displayed. Applying an upgrade must update the current run immediately.

### Procedural world pickups

Maintain a small capped set of pickups at valid positions around the player:

- **Health orb:** restore 25 health, capped at maximum health.
- **Coin magnet:** collect all currently active XP coins.
- **Energy bomb:** heavily damage or destroy active normal enemies; it must not instantly defeat the boss.

Pickup generation must avoid unbounded node growth and avoid spawning directly beneath the player.

### Boss phase

- Begins after the fifth upgrade selection.
- Stops or greatly reduces normal enemy spawning; the initial implementation should stop it.
- Uses the reusable enemy implementation with boss-specific health, size, color, speed, and contact damage.
- Has a clearly visible ring/crown of spikes and an on-screen boss health bar.
- Existing normal enemies may remain alive.
- Boss death stops active gameplay and shows the victory screen.

## Explicitly out of scope

- A countdown-based ending.
- Multiple characters, weapons, normal enemy types, bosses, stages, or biomes.
- Inventory, shops, permanent upgrades, saves, achievements, or online features.
- Procedural rooms, terrain topology, blocking props, navigation meshes, or enemy pathfinding.
- Complex animation, external art production, controller/mobile support, audio, and localization.
- Full balance or production-grade accessibility work; basic readability is still required.

## Ordered feature roadmap

Each feature gets one concise file under `plans/` when it becomes the next task. Do not plan the entire implementation in code-level detail upfront; later plans must reflect the project that actually exists.

| ID | Feature | Depends on | Outcome |
| --- | --- | --- | --- |
| F00 | Project foundation | — | Godot project, main scene, input actions, documented run/import verification, and minimal HUD shell |
| F01 | Player and endless-looking arena | F00 | Responsive movement, following camera, repeating floor, and no visible arena edge |
| F02 | Normal enemy and spawn system | F01 | Reusable chasing enemy and capped off-screen spawning |
| F03 | Auto-combat, damage, and defeat | F02 | Nearest-target shooting, projectiles, enemy death, player damage/invulnerability, defeat and restart |
| F04 | XP coins and five-level progression | F03 | Enemy drops, collection, thresholds, carry-over XP, HUD level/XP display, and level-up event |
| F05 | Upgrade choice UI and stat upgrades | F04 | Paused three-choice screen with working Vitality and Haste plus a combat-choice slot |
| F06 | Combat ability upgrades | F05 | Two-rank Multishot, Piercing, and Nova integrated into the random combat choice |
| F07 | Procedural decorations and world pickups | F06 | Capped decorative population plus Health, Magnet, and Bomb pickup behavior |
| F08 | Boss phase and victory | F07 | Reused spiked boss, boss health bar, spawn transition, victory, and restart |
| F09 | Final integration and tuning | F08 | Full-run regression, basic balance/readability polish, and clean verification evidence |

## Cross-feature acceptance criteria

These are checked again during F09:

- A new run starts without parser/runtime errors.
- The player can reach five upgrade selections through normal play.
- Every upgrade has a visible gameplay effect and respects its defined rank behavior.
- Normal enemy, projectile, coin, decoration, and pickup counts remain bounded during a run.
- The boss appears only after the fifth upgrade is chosen.
- Player death produces defeat; boss death produces victory.
- Restart restores clean initial state without retaining upgrades, entities, or progression.
- The complete loop is understandable using the included placeholder presentation.

## Session workflow and useful prompts

Start each new session in this directory and use one of these prompts:

- `Read AGENTS.md and check the current project status. Do not implement anything.`
- `Read AGENTS.md and generate the plan for the next incomplete roadmap feature. Do not implement it.`
- `Read AGENTS.md and implement the next planned feature, including verification and progress updates.`
- `Read AGENTS.md and implement F## according to its plan, then verify and update progress.`

For the most predictable workflow, generate a feature plan in one session and implement it in the next. If a feature is very small, the “implement next feature” workflow may create its missing plan and complete it in one session.
