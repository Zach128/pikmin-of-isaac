local Mod = RegisterMod("Pikmin of Isaac", 1)

Pik = require("pik")
PikPickup = require("pik_pickup")

Pik:InjectCallbacks(Mod)
PikPickup:InjectCallbacks(Mod)
