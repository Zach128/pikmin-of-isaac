# Progress notes

## (Familiar) Pikmin
* Begun by creating custom entity known internally as *Piks*.
* Could not keep piks persistent across rooms as mere NPCs as considered enemies.
* Converted piks to familiar entitites, allowing for persistence across rooms.
* Added "_Blue Pik Seed_" pickups to spawn in new piks.
* Tie pik familiars to total Blue Pik Seed count by the player, persisting this value between game sessions (closing and reopening the game).
* Make piks follow player in traditional-to-Isaac, train-like behaviour.
* Piks now use basic flock-like behaviour through boid algorithm.