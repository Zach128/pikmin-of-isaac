local PikminOfIsaacMod = RegisterMod("PikminOfIsaacMod", 1)

-- Sample method.
function PikminOfIsaacMod:Immortality(_PikminOfIsaacMod)
    -- Get our active player (player 1).
    local player = Isaac.GetPlayer(0)

    player:SetFullHearts()
    -- Drop 1 battery at the player's feet.
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, 1, player.Position, player.Velocity, player)
end

-- On every damage event to the player entities, run Immortality.
PikminOfIsaacMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PikminOfIsaacMod.Immortality, EntityType.ENTITY_PLAYER)
