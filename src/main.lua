local Mod = RegisterMod("Pikmin of Isaac", 1)

Pik = require("pik")
PikPickup = require("pik_pickup")
PikBoid = require("pik_boid")
PikCmd = require("pik_cmd")

Pik:InjectCallbacks(Mod)
PikPickup:InjectCallbacks(Mod)
PikBoid:InjectCallbacks(Mod)
PikCmd:InjectCallbacks(Mod)
