local game = Game()
local Pik = {}

helpers = require("helpers")

-- Define enums
FamiliarVariant.PIK = Isaac.GetEntityVariantByName("Pik")
PikState = {
    APPEAR = 0,
    DISMISS_IDLE = 1,
    DISMISS_ACTIVATE = 2,
    ACTIVE_IDLE = 3,
    ACTIVE_FOLLOW = 4,
    ACTIVE_CHASE = 3,
    ACTIVE_ATTACK = 4,
    ACTIVE_SHAKEOFF = 5,
    ACTIVE_DISMISS = 6,
}

-- Player trigger radious and offsets round a planted pik.
local plantedCollisionRadius = {
    X = 15,
    XOff = 0,
    Y = 6,
    YOff = -3
}

-- Initialise debug data.
local debugRenderStr = ""
local debugRenderRGBA = {
  R = 255,
  G = 0,
  B = 0,
  A = 255
}

function Pik:SpawnPiks(player)
    if game:GetFrameCount() == 1 then
        for x = 1,1 do
            for y = 1,1 do
                Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.PIK, 0, Vector(270 + 50*x, 200 + 50*y), Vector(0,0), nil):ToFamiliar()
            end
        end
    end
end

function Pik:OnPikSpawn(entity)
    entity.IsFollower = true
end

-- Main entrypoint for the Pik entity
function Pik:PikUpdate(entity)
    local sprite = entity:GetSprite()
    local data = entity:GetData()

    -- Initialise the base data and state
    if data.State == nil then data.State = 0 end
    if data.StateFrame == nil then data.StateFrame = 0 end

    data.StateFrame = data.StateFrame + 1
    
    -- Print basic debug data.
    Isaac.DebugString(string.format("State: %s", helpers:ResolveTableKey(NpcState, entity.State)))
    Isaac.DebugString(string.format("PikState: %s", helpers:ResolveTableKey(PikState, data.State)))
    
    -- Immediately go to the dismissal state.
    if entity.State == NpcState.STATE_INIT then
        Pik:SetState(entity, PikState.ACTIVE_DISMISS)
    end

    -- Handle the pik's planted state
    Pik:Planted(entity)

    -- Handle direction-facing
    if entity.Velocity.X > 0 then
        sprite.FlipX = true
    else 
        sprite.FlipX = false
    end
end

-- Handle the Planted states for Pik entities.
function Pik:Planted(entity)
    local data = entity:GetData()
    local sprite = entity:GetSprite()

    if data.State == PikState.ACTIVE_DISMISS and data.StateFrame == 0 then
        sprite:Play("GoPlanted")
    elseif sprite:IsFinished("GoPlanted") then
        Pik:SetState(entity, PikState.DISMISS_IDLE)
        sprite:Play("Planted")
    elseif data.State == PikState.DISMISS_IDLE then
        Isaac.DebugString("Awaiting player!")
        
        local nearestPlayer = Pik:PlayerNearPlanted(entity)

        if nearestPlayer ~= nil then
            debugRenderRGBA.R = 0
            debugRenderRGBA.G = 255
        else
            debugRenderRGBA.R = 255
            debugRenderRGBA.G = 0
        end
    end
end

-- Get the nearest player to a given pik
function Pik:PlayerNearPlanted(entity)
    -- Get the nearest player and their distance from this pik.
    local closePlayer = game:GetNearestPlayer(entity.Position)
    local playerDist = closePlayer.Position - entity.Position

    -- Log the distance.
    debugRenderStr = string.format("dist: %d,%d", playerDist.X//1, playerDist.Y//1)
    Isaac.DebugString(debugRenderStr)

    -- Check if player is in range. If so, return them.
    if
        math.abs(playerDist.X + plantedCollisionRadius.XOff) <= plantedCollisionRadius.X and
        math.abs(playerDist.Y + plantedCollisionRadius.YOff) <= plantedCollisionRadius.Y
    then return closePlayer
    else return nil
    end
end

-- Handle state-management for Pik entities.
function Pik:SetState(entity, pikState)
    local data = entity:GetData()

    if PikState.ACTIVE_DISMISS == pikState then
        data.State = PikState.ACTIVE_DISMISS
        data.StateFrame = 0
        entity.State = NpcState.STATE_IDLE
        -- Disable all collisions with enemies, bullets, etc.
        entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    elseif PikState.DISMISS_IDLE == pikState then
        data.State = PikState.DISMISS_IDLE
        data.StateFrame = 0
        entity.State = NpcState.STATE_IDLE
    end
end

function Pik:onCache(player, cacheFlag)
    if cacheFlag == CacheFlag.CACHE_FAMILIARS then
        Isaac.DebugString("Checking Familiars")
        if player:GetData().Piks ~= nil then
            Isaac.DebugString("  Checking Piks")
            player:CheckFamiliar(FamiliarVariant.PIK, player:GetData().Piks, RNG())
        end
    end
end

function Pik:RenderDebugStr()
    Isaac.RenderText(debugRenderStr, 100, 100, debugRenderRGBA.R, debugRenderRGBA.G, debugRenderRGBA.B, debugRenderRGBA.A)
end

function Pik:InjectCallbacks(Mod)
    Mod:AddCallback(ModCallbacks.MC_POST_RENDER, Pik.RenderDebugStr)
    Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Pik.SpawnPiks)
    Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Pik.onCache)
    Mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, Pik.OnPikSpawn, FamiliarVariant.PIK)
    Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, Pik.PikUpdate, FamiliarVariant.PIK)
end

return Pik