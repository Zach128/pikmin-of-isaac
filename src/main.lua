local Mod = RegisterMod("Pikmin of Isaac", 1)

Pik = require("scripts/pik/pik")
PikPickup = require("scripts/pik/pik_pickup")
PikBoid = require("scripts/pik/pik_boid")
PikCmd = require("scripts/pik/pik_cmd")

Pik:InjectCallbacks(Mod)
PikPickup:InjectCallbacks(Mod)
PikBoid:InjectCallbacks(Mod)
PikCmd:InjectCallbacks(Mod)
