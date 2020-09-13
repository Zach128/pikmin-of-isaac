local game = Game()
local sound = SFXManager()

local PikPickup = {}

Helpers = require("helpers")

PickupVariant.PICKUP_PIK = Isaac.GetEntityVariantByName("Blue Pik Seed")
PikSubType = {
    PIK_BLUE = 1
}

-- Screen coordinates for Pik UI
PikUILayout = {
    PIK_FRAME = 12,
    PIK_ICON = Vector(28, 32),
    PIK_NUM = Vector(42, 36)
}

local MAX_PIKS = 99

-- Fetch necessary graphics
local HudPickups = Sprite()
HudPickups:Load("gfx/ui/hudpickups.anm2", true)
local HudNumbers = Sprite()
HudNumbers:Load("font/counter_numbers.anm2", true)

PikPickup.Mod = nil

-- Render a 2-digit number.
function RenderNumber(n, Position)
    if n == nil then n = 0 end
    -- Second digit
    HudNumbers:SetFrame("Idle", n//10)
    HudNumbers:RenderLayer(0, Position)
    -- First digit
    HudNumbers:SetFrame("Idle", n % 10)
    HudNumbers:RenderLayer(0, Position + Vector(6,0))
end

-- Save the current state accordingly.
function PikPickup:SaveState()
    local player = Isaac.GetPlayer(0)
    local SaveData = ""
    -- Pad with 0 if number is single-digit
    if player:GetData().Piks < 10 then
        SaveData = SaveData .. "0"
    end
    SaveData = SaveData .. player:GetData().Piks
    Isaac.DebugString("Piks Save Data: " .. SaveData)
    PikPickup.Mod:SaveData(SaveData)
end

function PikPickup:onUpdate(player)

    if game:GetFrameCount() == 1 then
        -- If we started a new game, give ourselves a handful of piks.
        player:GetData().Piks = 5
        PikPickup:SaveState()
        PikPickup:InvalidatePiks(player)
    elseif player.FrameCount == 1 and PikPickup.Mod:HasData() then
        -- Otherwise. load up our previous save-state.
        local ModData = PikPickup.Mod:LoadData()
        -- Load the first two characters as the number of piks the player has.
        player:GetData().Piks = tonumber(ModData:sub(1,2))
        PikPickup:InvalidatePiks(player)
    end

    -- Loop through all entities currently on-screen.
    for _, entity in pairs(Isaac.GetRoomEntities()) do
        -- Check if the player is touching the pickup
        if entity.Type == EntityType.ENTITY_PICKUP
        and (player.Position - entity.Position):Length() < player.Size + entity.Size
        then
            --onPickup (userdata cannot be sent to lua functions)
            if entity.Variant == PickupVariant.PICKUP_PIK
            and entity:GetSprite():IsPlaying("Idle")
            and entity:GetData().Picked == nil then
                -- Pick up a Pik
                entity:GetData().Picked = true
                entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                entity:GetSprite():Play("Collect", true)
                sound:Play(SoundEffect.SOUND_PLOP, 1, 0, false, 1)
                if entity.SubType == PikSubType.PIK_BLUE then

                    player:GetData().Piks = math.min(player:GetData().Piks + 1, MAX_PIKS)
                    PikPickup:InvalidatePiks(player)
                end

                -- Save state afterwards in case the player exits
                PikPickup:SaveState()
            end
        end

        -- If the entity has been picked up, delete it.
        if entity.Type == EntityType.ENTITY_PICKUP
        and entity:GetData().Picked == true
        and entity:GetSprite():GetFrame() == 6
        then
            entity:Remove()
        end
    end
end

-- Invalidates the familiar cache to despawn/respawn necessary piks
function PikPickup:InvalidatePiks(player)
  -- Invalidate the familiars cache to spawn the new familiars.
  player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
  player:EvaluateItems()
end

function PikPickup:onRender()
    local player = Isaac.GetPlayer(0)
    HudPickups:SetFrame("Idle", PikUILayout.PIK_FRAME)
    HudPickups:RenderLayer(0, PikUILayout.PIK_ICON)
    RenderNumber(player:GetData().Piks, PikUILayout.PIK_NUM)
end

function PikPickup:InjectCallbacks(Mod)
    PikPickup.Mod = Mod
    Mod:AddCallback(ModCallbacks.MC_POST_RENDER, PikPickup.onRender)
    Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, PikPickup.onUpdate)
end

return PikPickup
