local game = Game()
local Pik = {}

Helpers = require("helpers")
PikBoid = require("pik_boid")
PikPickup = require("pik_pickup")

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

local damagePerCycle = 2

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
    if data.PikDied == nil then data.PikDied = false end

    data.StateFrame = data.StateFrame + 1

    if entity:HasMortalDamage() then
        Isaac.DebugString("Oh No! The pik has diedeuh!")
        PikPickup:AdjustPikCount(Isaac.GetPlayer(0), -1)
    end
    
    -- Print basic debug data.
    Isaac.DebugString(string.format("State: %s", Helpers:ResolveTableKey(NpcState, entity.State)))
    Isaac.DebugString(string.format("PikState: %s", Helpers:ResolveTableKey(PikState, data.State)))

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
        if entity.Target:IsDead() then
            -- If our target is dead, the attack job is done; go back to following the player.
            entity.Target = nil

            Pik:SetState(entity, PikState.ACTIVE_FOLLOW)
        else
            if data.StateFrame == 1 then
                -- If we just entered this state, begin initialisation

                -- Keep track of the initial offset from the target.
                data.TargetAttachmentOffset = entity.Position - entity.Target.Position
    
                -- Start the Attack animation.
                sprite:Play("Attack", true)
            else
                if Pik:IsEnemyValidForAttack(entity.Target) then
                    debugRenderRGBA.R = 0
                    debugRenderRGBA.G = 255
                else
                    debugRenderRGBA.R = 255
                    debugRenderRGBA.G = 0

                    -- We lost our target! Go back to the player.
                    Pik:SetState(entity, PikState.ACTIVE_FOLLOW)
                end

                -- Move the entity to the target's postion.
                entity.Position = entity.Target.Position + data.TargetAttachmentOffset
                entity.Velocity = entity.Target.Velocity
    
                debugRenderStr = "Chasing vector " .. entity.Target.Position.X .. ", " .. entity.Target.Position.Y
                
                -- Attack the target, in sync with the attack animation.
                if sprite:IsEventTriggered("Attack1") then
                    entity.Target:TakeDamage(damagePerCycle, 0, EntityRef(entity), 1)
                end
            end
        end
    end
end

function Pik:Active(entity)
    -- Handle all active states for Pik entities.
    local data = entity:GetData()
    local sprite = entity:GetSprite()

    if data.State == PikState.ACTIVE_FOLLOW then
        
        -- Set up our pik's collision and initial following state.
        if data.StateFrame == 1 then 
            sprite:Play("Move")
        end
        
        -- Select the appropriate animation based on their velocity.
        if entity.Velocity:Length() <= 0.1 and not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        elseif entity.Velocity:Length() > 0.1 and not sprite:IsPlaying("Move") then
            sprite:Play("Move", true)
        end

        -- Follow the player.
        local piks = Pik:GetRoomCollideablePiks()
        PikBoid:UpdateBoid(piks)

        Isaac.DebugString("Checking for enemy! Also note collision set to " .. Helpers:ResolveTableKey(EntityCollisionClass, entity.EntityCollisionClass))
        Pik:PickEnemyTarget(entity)

        -- If we picked up a target, begin chasing them.
        if entity.Target ~= nil then
            Pik:SetState(entity, PikState.ACTIVE_CHASE)
        end
    elseif data.State == PikState.ACTIVE_CHASE then

        if data.StateFrame == 1 then
            sprite:Play("Idle", true)
        end

        if entity.Target ~= nil then
            entity:FollowPosition(entity.Target.Position)

            PikBoid:UpdateJustStayAway(Pik:GetRoomCollideablePiks(), entity)
            -- debugRenderStr = "Chasing vector " .. entity.TargetPosition.X .. ", " .. entity.TargetPosition.Y
        end
    end
end

function Pik:PickEnemyTarget(entity)
    -- Pick a suitable enemy target for a pik to attack.

    local entities = Isaac.FindInRadius(entity.Position, 300, EntityPartition.ENEMY)
    debugRenderStr = "Found " .. tostring(#entities) .. " enemies"
    
    -- Loop through the obtained list and identify a valid target.
    for i, enemy in pairs(entities) do
        if entity.Target ~= nil then break end

        if Pik:IsEnemyValidForAttack(enemy) then
            entity.Target = enemy
        end
    end
end

function Pik:IsEnemyValidForAttack(enemy)
    -- Helper function that checks if an enemy can in-fact be attacked by piks.
    return enemy:IsVulnerableEnemy()-- Enemy needs to be vulnerable to attacks.
    and enemy:IsVisible()           -- Piks can't attack what they can't see.
    and not enemy:IsInvincible()    -- Double-check the enemy isn't invincible.
    and enemy:IsActiveEnemy(false)  -- Ensure the enemy is in-fact active.
end

function Pik:Planted(entity)
    -- Handle the Planted states for Pik entities.

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

function Pik:SetState(entity, pikState)
    -- Handle state-management for Pik entities.

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

        -- Ensure collisions are enabled.
        entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    elseif PikState.ACTIVE_CHASE == pikState then
        data.State = PikState.ACTIVE_CHASE
        data.StateFrame = 0
        entity.State = NpcState.STATE_MOVE
    elseif PikState.ACTIVE_ATTACK == pikState then
        data.State = PikState.ACTIVE_ATTACK
        data.StateFrame = 0
        entity.State = NpcState.STATE_ATTACK

        -- Disable all but basic collisions.
        entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    end
end

function Pik:onCollision(pikEntity, collEntity, low)
    Isaac.DebugString("Collision with " .. Helpers:ResolveTableKey(EntityType, collEntity.Type) .. ", low: " .. tostring(low))

    -- If we collide with an enemy, attack it.
    if collEntity.Type ~= EntityType.ENTITY_PLAYER and collEntity:IsEnemy() and Pik:IsEnemyValidForAttack(collEntity) then
        Isaac.DebugString("Hit an enemy! Attacking...")

        -- Make sure we set the correct target based on the enemy we hit.
        pikEntity.Target = collEntity

        Pik:SetState(pikEntity, PikState.ACTIVE_ATTACK)
    end
end

function Pik:onCache(player, cacheFlag)
    -- Perform cache-related checks here such as ensuring expected on-screen pik count is met.
    if cacheFlag == CacheFlag.CACHE_FAMILIARS then
        -- If the player data was initialised, check that the appropriate piks are present.
        if player:GetData().Piks ~= nil then
            player:CheckFamiliar(FamiliarVariant.PIK, player:GetData().Piks, RNG())
        end
    end
end

function Pik:GetRoomCollideablePiks()
    -- Get a list of all collideable piks in the room. This excludes those in an attack state of sorts.

    local allEntities = Isaac.GetRoomEntities()
    local pikEntities = {}

    for i,entity in pairs(allEntities)
    do
        if entity.Type == EntityType.ENTITY_FAMILIAR
        and entity.Variant == FamiliarVariant.PIK
        and entity:GetData().State ~= PikState.ACTIVE_ATTACK
        then
            table.insert(pikEntities, entity)
        end
    end

    return pikEntities
end

function Pik:RenderDebugStr()
    Isaac.RenderText(debugRenderStr, 100, 100, debugRenderRGBA.R, debugRenderRGBA.G, debugRenderRGBA.B, debugRenderRGBA.A)
end

function Pik:GiveSpiderMod(continuedGame)
    -- Give the Spider Mod collectible to display enemy healthbars.

    if debugUsingHealthBars and not continuedGame then
        Isaac.GetPlayer(0):AddCollectible(CollectibleType.COLLECTIBLE_SPIDER_MOD, 0, true)
    end
end

function Pik:OnDamage(entity, amount, flags, src, countdown)
    -- Only allow damage by explosions. We only want 
    if entity.Type == EntityType.ENTITY_FAMILIAR and entity.Variant == FamiliarVariant.PIK then
        if flags & DamageFlag.DAMAGE_EXPLOSION then
            Isaac.DebugString("Damage to Pik by entity " .. Helpers:ResolveTableKey(EntityType, src.Type))

            return true
        else
            return false
        end
    end
end

function Pik:OnDeath(entity, elm)

    -- if entity.Variant == FamiliarVariant.PIK then
    --     Isaac.DebugString(tostring(elm))
    --     Isaac.DebugString("Pik died!")
    --     PikPickup:AdjustPikCount(Isaac.GetPlayer(0), -1)
    -- end
end

function Pik:InjectCallbacks(Mod)
    Mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Pik.GiveSpiderMod)
    Mod:AddCallback(ModCallbacks.MC_POST_RENDER, Pik.RenderDebugStr)
    Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Pik.SpawnPiks)
    Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Pik.onCache)
    Mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, Pik.OnPikSpawn, FamiliarVariant.PIK)
    Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, Pik.PikUpdate, FamiliarVariant.PIK)
    Mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Pik.OnDamage, EntityType.ENTITY_FAMILIAR)
    Mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, Pik.OnDeath, EntityType.ENTITY_FAMILIAR)
    Mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, Pik.onCollision, FamiliarVariant.PIK)
end

return Pik
