local game = Game()
local Pik = {}

require("scripts/pik/pik_enums")
Helpers = require("scripts/helpers")
PikBoid = require("scripts/pik/pik_boid")
PikPickup = require("scripts/pik/pik_pickup")
PikAi = require("scripts/pik/pik_ai")

local debugUsingHealthBars = true

function Pik:SpawnPiks(player)
    if game:GetFrameCount() == 1 then
        for x = 1,1 do
            for y = 1,1 do
                -- Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.PIK, 0, Vector(270 + 50*x, 200 + 50*y), Vector(0,0), nil):ToFamiliar()
            end
        end
    end
end

function Pik:onCache(player, cacheFlag)
    -- Perform cache-related checks here such as ensuring expected on-screen pik count is met.
    if cacheFlag == CacheFlag.CACHE_FAMILIARS then
        -- If the player data was initialised, check that the appropriate piks are present.
        local pikCount = player:GetData().Piks
        
        if pikCount ~= nil then
            local allPiks = Pik:GetAllPiks()

            -- CheckFamiliars does not properly handle our use case, leaving one "phantom" pik, even when all piks should be dead.
            -- So we must create our own "CheckFamiliar" routine.
            if #allPiks > pikCount then
                -- Remove excess piks from the room
                for i = 1, #allPiks - pikCount, 1
                do
                    allPiks[i]:Kill()
                end
            elseif #allPiks < pikCount then
                -- Spawn as many piks on the player as needed to meet the expected amount.
                for i = 1, pikCount - #allPiks, 1
                do
                    Isaac.Spawn(
                        EntityType.ENTITY_FAMILIAR,
                        FamiliarVariant.PIK,
                        0,
                        player.Position,
                        Vector(0, 0),
                        player
                    )
                end
            end

            -- player:CheckFamiliar(FamiliarVariant.PIK, player:GetData().Piks - 1, RNG())
        end
    end
end

function Pik:GetAllPiks()
    -- Get a list of all piks in the room.

    local allEntities = Isaac.GetRoomEntities()
    local pikEntities = {}

    for i,entity in pairs(allEntities)
    do
        if entity.Type == EntityType.ENTITY_FAMILIAR
        and entity.Variant == FamiliarVariant.PIK
        then
            table.insert(pikEntities, entity)
        end
    end

    return pikEntities
end

function Pik:GiveSpiderMod(continuedGame)
    -- Give the Spider Mod collectible to display enemy healthbars.

    if debugUsingHealthBars and not continuedGame then
        Isaac.GetPlayer(0):AddCollectible(CollectibleType.COLLECTIBLE_SPIDER_MOD, 0, true)
    end
end

function Pik:InjectCallbacks(Mod)
    Mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Pik.GiveSpiderMod)
    Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Pik.SpawnPiks)
    Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Pik.onCache)
    PikAi:InjectCallbacks(Mod)
end

return Pik
