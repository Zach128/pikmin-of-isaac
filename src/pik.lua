local game = Game()
local Pik = {}

Helpers = require("helpers")
PikBoid = require("pik_boid")

-- Define enums
FamiliarVariant.PIK = Isaac.GetEntityVariantByName("Pik")
PikState = {
    APPEAR = 0,
    DISMISS_IDLE = 1,
    DISMISS_ACTIVATE = 2,
    ACTIVE_IDLE = 3,
    ACTIVE_FOLLOW = 4,
    ACTIVE_CHASE = 5,
    ACTIVE_ATTACK = 6,
    ACTIVE_SHAKEOFF = 7,
    ACTIVE_DISMISS = 8,
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
    -- Start out dismissed
    Pik:SetState(entity, PikState.DISMISS_ACTIVATE)
    -- Pik:SetState(entity, PikState.ACTIVE_DISMISS)
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
    Isaac.DebugString(string.format("State: %s", Helpers:ResolveTableKey(NpcState, entity.State)))
    Isaac.DebugString(string.format("PikState: %s", Helpers:ResolveTableKey(PikState, data.State)))
    
    -- Immediately go to the dismissal state.

    -- Handle the pik's planted states.
    Pik:Planted(entity)

    -- Handle the pik's active states.
    Pik:Active(entity)

    -- Handle the pik's attacking states.
    Pik:Attack(entity)

    -- Handle direction-facing
    if entity.Velocity.X < 0 then
        sprite.FlipX = true
    else 
        sprite.FlipX = false
    end
end

function Pik:Attack(entity)
    local data = entity:GetData()
    local sprite = entity:GetSprite()

    if data.State == PikState.ACTIVE_ATTACK then
        if data.StateFrame == 1 then
            entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
            entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

            -- Keep track of the initial offset from the target.
            data.TargetAttachmentOffset = entity.Position - entity.Target.Position
        else
            -- Move the entity to the target's postion.
            entity.Position = entity.Target.Position + data.TargetAttachmentOffset
            entity.Velocity = entity.Target.Velocity
        end
    end
end

function Pik:Active(entity)
    local data = entity:GetData()
    local sprite = entity:GetSprite()

    if data.State == PikState.ACTIVE_FOLLOW then
        
        if data.StateFrame == 1 then 
            sprite:Play("Move")

            entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
            entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end
        
        if entity.Velocity:Length() <= 0.1 and not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        elseif entity.Velocity:Length() > 0.1 and not sprite:IsPlaying("Move") then
            sprite:Play("Move", true)
        end

        -- Follow the player
        local piks = Pik:GetRoomPiks()
        PikBoid:UpdateBoid(piks)

        Isaac.DebugString("Checking for enemy! Also note collision set to " .. Helpers:ResolveTableKey(EntityCollisionClass, entity.EntityCollisionClass))
        Pik:PickEnemyTarget(entity)

        if entity.Target ~= nil then
            Pik:SetState(entity, PikState.ACTIVE_CHASE)
        end
    elseif data.State == PikState.ACTIVE_CHASE then

        if data.StateFrame == 1 then
            sprite:Play("Idle", true)
        end

        if entity.Target ~= nil then
            entity:FollowPosition(entity.Target.Position)

            PikBoid:UpdateJustStayAway(Pik:GetRoomPiks(), entity)
            -- debugRenderStr = "Chasing vector " .. entity.TargetPosition.X .. ", " .. entity.TargetPosition.Y
        end
    end
end

function Pik:PickEnemyTarget(pikEntity)
    local entities = Isaac.FindInRadius(pikEntity.Position, 300, EntityPartition.ENEMY)
    debugRenderStr = "Found " .. tostring(#entities) .. " enemies"

    if #entities > 0 then pikEntity.Target = entities[1] end
end

-- Handle the Planted states for Pik entities.
function Pik:Planted(entity)
    local data = entity:GetData()
    local sprite = entity:GetSprite()

    if data.State == PikState.ACTIVE_DISMISS and data.StateFrame == 1 then
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
    elseif data.State == PikState.DISMISS_ACTIVATE and data.StateFrame == 1 then
        sprite:Play("UnPlanted")
    elseif sprite:IsFinished("UnPlanted") and data.State == PikState.DISMISS_ACTIVATE then
        Pik:SetState(entity, PikState.ACTIVE_FOLLOW)
    end
end

-- Get the nearest player to a given pik
function Pik:PlayerNearPlanted(entity)
    -- Get the nearest player and their distance from this pik.
    local closePlayer = game:GetNearestPlayer(entity.Position)
    local playerDist = closePlayer.Position - entity.Position

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
    elseif PikState.DISMISS_ACTIVATE == pikState then
        data.State = PikState.DISMISS_ACTIVATE
        data.StateFrame = 0
        entity.State = NpcState.STATE_IDLE
    elseif PikState.ACTIVE_FOLLOW == pikState then
        data.State = PikState.ACTIVE_FOLLOW
        data.StateFrame = 0
        entity.State = NpcState.STATE_MOVE
    elseif PikState.ACTIVE_CHASE == pikState then
        data.State = PikState.ACTIVE_CHASE
        data.StateFrame = 0
        entity.State = NpcState.STATE_MOVE
    elseif PikState.ACTIVE_ATTACK == pikState then
        data.State = PikState.ACTIVE_ATTACK
        data.StateFrame = 0
        entity.State = NpcState.STATE_ATTACK
    end
end

function Pik:onCollision(pikEntity, collEntity, low)
    Isaac.DebugString("Collision with " .. Helpers:ResolveTableKey(EntityType, collEntity.Type) .. ", low: " .. tostring(low))

    -- -- Enforce enemy collision
    if collEntity.Type ~= EntityType.ENTITY_PLAYER and collEntity:IsEnemy() then
        Isaac.DebugString("Hit an enemy! Attacking...")

        Pik:SetState(pikEntity, PikState.ACTIVE_ATTACK)
    end
end

function Pik:onCache(player, cacheFlag)
    if cacheFlag == CacheFlag.CACHE_FAMILIARS then
        -- If the player data was initialised, check that the appropriate piks are present.
        if player:GetData().Piks ~= nil then
            player:CheckFamiliar(FamiliarVariant.PIK, player:GetData().Piks, RNG())
        end
    end
end

function Pik:GetRoomPiks()
    local allEntities = Isaac.GetRoomEntities()
    local pikEntities = {}

    for i,entity in pairs(allEntities)
    do
        if entity.Type == EntityType.ENTITY_FAMILIAR and entity.Variant == FamiliarVariant.PIK then
            table.insert(pikEntities, entity)
        end
    end

    return pikEntities
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
    Mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, Pik.onCollision, FamiliarVariant.PIK)
end

return Pik
