# Overview

This document serves as reference for desired behaviour of the Pik familiars. As additional features and behaviours get added to them, this describes how they should behave.

## Enemy targeting

Targetting is based simply on the following:

Target enemies that are _vulnerable_, _visible_, and active; Don't attack inactive enemies or invincible ones, to avoid soft-locking the piks.

Once an assaulted target fails to satisfy the above criteria, the target is forgotten, and the piks return to the player. Once the target can satisfy the above criteria again, it is game for attack once more.

Below is a table of some sample entities and how piks should behave with them when looking for enemies to attack.

Name | ID | Expectation
--- | --- | ---
Stone Eye | 201.0 | Should not be targeted due to not being a vulnerable enemy.
Constant Stone Shooter | 202.0 | Should not be targeted despite constantly shooting tears.
Fire place | 33.0 | Shouldn't be targeted.
Slide | 44.1 | Shouldn't be targeted.
Cod worm | 221.0 | Only when vulnerable should the Piks target the enemy.
Round worm | 244.0 | Only targeted when head is above-ground (visible) do piks attack the head. Once below ground (invisible), piks should go back to following state, allowing for retargeting of the enemy.
Stoney | 302.0 | Should not be attacked by the piks.
Pitfalls | 291._x_ | Piks walk around them.
Mask | 93.0 | The mask itself is ignored, while the heart is targeted.
Mask of Infamy | 97.0 | Mask is ignored until the heart is defeated. Mask becomes targeted afterwards.
The Bloat | 68.1 | Ignores eyes, targets the body.
Scolex | 62.1 | Only the vulnerable tail segment should be targeted. All other segments should be left alone.

