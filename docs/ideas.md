# Pikmin of Isaac ideas

Ideas on what to implement:

## 1. Minimum requirements

### (Familiar) **Pikmin**

* Closely follows the player.
* Latches onto nearby enemies and attacks repeatedly, dealing *x* damage per hit.
* Can be killed by explosions (being vulnerable to tears makes them too great a liability).
* If enemies disappear (burrow, jump, teleport, etc), pikmin are shaken off, making them seek out the enemy once they reappear.
* On death, pikmin ghost entity summoned at location as part of dying animation.
  * Ghost does nothing, serving only as visual decoration.
* Exist in 2 main states. Planted, or active.
  * When planted, they:
    * Cannot be killed by any attacks whatsoever.
    * Don't help the player at all as they are lying dormant.
    * Can be uprooted by the player if walked over (or maybe by tapping Ctrl? Requires play-testing).
    * Spawn naturally on all floors and non-special rooms.
    * Once 20 pikmin reached, those planted pikmin will not uproot by any means until existing active pikmin dismissed or killed.
    * Up to 5 pikmin may spawn in a room, with each pikmin-loaded room existing 3 rooms or so away from the last one. The chance for a room to be a pikmin room is determined at random on floor generation.
  * When active, they:
    * Don't spawn naturally.
    * Follow the player, attack for the player, etc.
* 1 variant of Pikmin:
  * Blue
    * Standard, base pikmin with no special attributes.

### (Passive) **Pikpik Carrot**

* Increases maximum pikmin that can occur in a room by 3.
* Increases likelihood of room bearing pikmin (decreases distance between each room by 1, meaning the nearest room will always be two rooms away).
* Belongs to the shop and treasure room pools.

### (Active) **Olimar's whistle**

* Dismisses pikmin, sending them into their planted state.
* Allows for saving pikmin for later use.
* Found exclusively in item pools.

### (Pill) **Pikmin's Throat**

* Let out a whistling call which uproots all pikmin in the room or up until your max active pikmin count is reached or none at all if already reached.

### (Card) **Night-time**

* Causes the room to darken for a short duration.
* All active pikmin are given the *Olimar's Whistle* effect, dismissing them.

## "Would be nice" requirements

### (Familiar) **Pikmin**

* 3 variants of pikmin:
  * Blue
    * Become most common naturally-occuring pikmin.
  * Red
    * Deal the most damage to enemies through better damage-per-hit. Least common.
  * Yellow
    * Slow down enemies when they latch on, using their large ears for drag.
* Can mature from leaves to buds and finally, flowers.
  * Planted/dormant pikmin spawn as leaves, retaining their maturity if already active.
  * A multiplier from being in one of these 3 stages determines a pikmin's additional effectiveness in all it's traits (damage, movement speed, special ability).
  * Maturity can be increased by the pikmin touching nectar. This will immediately set the pikmin to a flower pikmin.
  * Maturity can be decreased by one point per-reduction through being shaken off by enemies. This happens on a randomly-selected chance (possibly affected by Luck stat?).
  * Pikmin undergo a transformation when maturing. When doing so, they are not interactable by neither player nor enemy until their animation is complete.

### (Environment) **Nectar**

* Environmental entity like rocks or poop which allows pikmin to mature.
* Can spawn as many as three times in a room, but only for every five floors in a room. Numbers may vary upon play-testing.
