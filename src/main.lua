local Mod = RegisterMod("Pikmin of Isaac", 1)
local game = Game()
local sound = SFXManager()

local Pik = {}
local Debug = {}

EntityType.ENTITY_PIK = Isaac.GetEntityTypeByName("Pik")

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

function Pik:PikInit(player)
    if game:GetFrameCount() == 1 then
        for x = 1,1 do
            for y = 1,1 do
                Isaac.Spawn(EntityType.ENTITY_PIK, 0, 0, Vector(270 + 50*x, 200 + 50*y), Vector(0,0), nil)
            end
        end
    end
end

-- Main entrypoint for the Pik entity
function Pik:PikUpdate(entity)
    local sprite = entity:GetSprite()
    local data = entity:GetData()

    -- Initialise the base data and state
    if data.State == nil then data.State = 0 end
    if data.StateFrame == nil then data.StateFrame = 0 end
    entity.StateFrame = entity.StateFrame + 1
    
    -- Print basic debug data.
    Isaac.DebugString(string.format("State: %s", Debug:ResolveTableKey(NpcState, entity.State)))
    Isaac.DebugString(string.format("PikState: %s", Debug:ResolveTableKey(PikState, data.State)))
    Isaac.DebugString(string.format("StateFrame: %d", entity.StateFrame))
    
    -- Immediately go to the dismissal state.
    if entity.State == NpcState.STATE_INIT and sprite:IsFinished("Appear") then
        Pik:SetState(entity, PikState.ACTIVE_DISMISS)
        entity.StateFrame = 0
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

    if data.State == PikState.ACTIVE_DISMISS and entity.StateFrame == 0 then
        sprite:Play("GoPlanted")
    elseif sprite:IsFinished("GoPlanted") then
        Pik:SetState(entity, PikState.DISMISS_IDLE)
        sprite:Play("Planted")
    end
end

-- Handle state-management for Pik entities.
function Pik:SetState(entity, pikState)
    local data = entity:GetData()

    if PikState.ACTIVE_DISMISS == pikState then
        data.State = PikState.ACTIVE_DISMISS
        entity.State = NpcState.STATE_IDLE

        -- Disable all collisions with enemies, bullets, etc.
        entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    elseif PikState.DISMISS_IDLE == pikState then
        data.State = PikState.DISMISS_IDLE
        entity.State = NpcState.STATE_IDLE
    end
end

Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Pik.PikInit)
Mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, Pik.PikUpdate, EntityType.ENTITY_PIK)

function Debug:ResolveTableKey(tbl, val)
    for k, v in pairs(tbl) do
        if v == val then return k end
    end
    return nil
end
