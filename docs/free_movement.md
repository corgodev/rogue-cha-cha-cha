# Continuous movement

Arrow keys steer the always-moving party; holding two keys steers diagonally.
Releasing them keeps the current heading. Turning is gradual, including when
blocked. Walls, missing ground, closed doors, enemies, and nonadjacent party
members block movement. Walls and self-collision do not damage the party.

Each recruited character automatically aims at its nearest visible enemy and
attacks on its own cooldown. Attacks remain ready when there is no target.
Touch a recruit with the leader to append it at the tail. Recruitment waits if
there is insufficient trail history or the tail position is occupied. Any member
can collect a healing potion. Press R to restart.

## Tuning in the Inspector

| Resource/node | Properties | Initial values |
| --- | --- | --- |
| MainGame / Snake | `speed`, `turn_speed_degrees`, `member_spacing` | 48 px/s, 360 degrees/s, 16 px |
| World entities | `collision_radius` | 5 px |
| Attack resources | `damage`, `cooldown`, `reach`, `width` | Existing damage, 1 s cooldown |
| Warrior attack | `reach`, `width` | 16 × 16 px |
| Mage attack | `reach`, `width` | 16 × 48 px |
| Archer attack (used by Rogue) | `reach`, `width` | 48 × 8 px |
| Enemy definitions | `speed`, `contact_damage`, `contact_cooldown` | 48 px/s, 1 HP, 1 s |
| Patrol resources | `directions`, `distance_per_leg` | Existing routes; distances in pixels |

Attack areas are rectangles extending forward from their caster and rotated
toward the selected target. Every enemy intersecting the area can be hit once
per attack, provided terrain or a closed door does not obscure its center.
The `shape` enum retains the existing attack identity; dimensions are explicit.
Contact damage has one cooldown per enemy, shared across all party members.

## Implementation

`GameplayController` replaces the global turn timer with physics updates. It
integrates movement, recruitment, attacks, enemy movement/contact, and pickups
in steps no larger than 1/120 second. Defeat stops the simulation immediately.

`Snake` stores world-space path points and samples them by arc length. The
entire chain advances only when every member's sweep is clear. A relative-motion
sweep tests nonadjacent members against one another. The retained path includes
space for one extra member; recruitment never invents a path through terrain.
The connector follows the recorded path while character sprites aim separately.

`WorldEntity` supplies circular collision geometry. Collision is resolved by
explicit geometric sweeps rather than independent physics-body movement, so a
blocked follower cannot compress or split the party. `RoomGrid` now supplies
terrain queries only: it sweeps circles against wall/missing-ground tile edges.
Keep the room's Ground and Walls tile layers aligned, square, and uniformly
scaled. Actor positions are no longer snapped to cells.

The existing scene hierarchy and room artwork are retained. Door signals remain
available; this change does not implement room transitions. A starting party
must have distinct characters spaced by `member_spacing`, with unobstructed
connections between them.

## Verification

Run from the project directory with Godot 4.7 and the bundled FMOD extension:

```powershell
godot_console --headless --path . --script tests/free_movement_test.gd
godot_console --headless --path . --quit-after 180
```

The regression script covers frame-rate independence, swept wall/self-collision,
missing ground, following, recruitment, attacks, damage cooldowns, healing,
patrols, scene loading, defeat, and restart. For a visual playtest, steer through
curves, recruit both characters, and watch their separate attack areas near enemies.
