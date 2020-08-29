StartDebug()

local Mod = RegisterMod("Pikmin of Isaac", 1)
local game = Game()
local sound = SFXManager()

local Pik = {}

EntityType.ENTITY_PIK = Isaac.GetEntityTypeByName("Pik")

MDState = {
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
        for x = 0,2 do
            for y = 0,2 do
                Isaac.Spawn(EntityType.ENTITY_PIK, 0, 0, Vector(270 + 50*x, 200 + 50*y), Vector(0,0), nil)
            end
        end
    end
end

-- Main entrypoint for the Pik entity
function Pik:PikUpdate(entity)
    Isaac.DebugString("Pik!")
    -- local data = entity:GetData(EntityType.ENTITY_PIK)

    -- Isaac.DebugString(string.format("StateFrame: %s", table.tostring(data)))

    -- if type(data) == "table" then
    --     -- Initialise the base data and state
    --     if data.State == nil then data.State = 0 end
    --     if data.StateFrame == nil then data.StateFrame = 0 end
    
    --     local playerTarget = entity:GetPlayerTarget()
    
    --     data.StateFrame = data.StateFrame + 1
    
    --     if data.State == MDState.APPEAR and entity:GetSprite():IsFinished("Appear") then
    --         data.State = MDState.DISMISS_IDLE
    --         data.StateFrame = 0
    --     elseif data.State == MDState.DISMISS_IDLE then
    --         -- Stay jiving in the spot, forever (or until we change it).
    --         if data.StateFrame == 1 then
    --             entity:GetSprite():Play("Planted", true)
    --         end
    --     elseif data.State == MDState.DISMISS_ACTIVATE then
    --         -- if data.StateFrame == 1 then
    --         -- end
    --     elseif data.State == MDState.ACTIVE_IDLE then
    --         -- if data.StateFrame == 1 then
    --         -- end
    --     elseif data.State == MDState.ACTIVE_FOLLOW then
    --         -- if data.StateFrame == 1 then
    --         -- end
    --     elseif data.State == MDState.ACTIVE_CHASE then
    --         -- if data.StateFrame == 1 then
    --         -- end
    --     elseif data.State == MDState.ACTIVE_ATTACK then
    --         -- if data.StateFrame == 1 then
    --         -- end
    --     elseif data.State == MDState.ACTIVE_SHAKEOFF then
    --         -- if data.StateFrame == 1 then
    --         -- end
    --     elseif data.State == MDState.ACTIVE_DISMISS then
    --         -- if data.StateFrame == 1 then
    --         -- end
    --     end
    -- end

    if entity.Velocity.X > 0 then
        entity:GetSprite().FlipX = true
    else 
        entity:GetSprite().FlipX = false
    end
end

Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Pik.PikInit)
Mod:AddCallback(0, Pik.PikUpdate, EntityType.ENTITY_PIK)
