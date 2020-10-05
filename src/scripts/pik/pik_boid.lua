-- Boid behaviour coordinator heavily based on the following work by Conrad Parker: http://www.kfish.org/boids/pseudocode.html


local PikBoid = {}

-- The final speed is campled to 0 if smaller than this.
PikBoid.ClampToTarget = 1
-- The final speed is limited by this amount
PikBoid.SpeedLimit = 1
PikBoid.SpeedCoefficient = 1
-- How much to separate from other piks
PikBoid.SpacingTarget = 15
PikBoid.LastFrameUpdate = 0

PikBoid.EnableDebugTargetDestinations = false
local DebugTarget = Sprite()
local DebugTargetPositions = {}
DebugTarget:Load("gfx/debug_target.anm2", true)
DebugTarget:SetFrame("Idle", 0)

PikBoid.PlayerGatherRadius = 50

function PikBoid:UpdateJustStayAway(piks, entity)
  local addedVector = PikBoid:SeparateTargets(piks, entity)

  addedVector = PikBoid:LimitVelocity(addedVector)

  entity.Velocity = entity.Velocity + addedVector
end

function PikBoid:UpdateBoid(piks)

  local v1, v2, v3, v4
  local currFrame = Game():GetFrameCount()

  Isaac.DebugString("Updating boids")

  -- Only run once per-frame
  if currFrame == PikBoid.LastFrameUpdate then return end

  for i,targetPik in ipairs(piks)
  do

    local finalVector;

    v1 = PikBoid:MoveToPlayer(targetPik)
    v2 = PikBoid:SeparateTargets(piks, targetPik)

    finalVector = v1

    -- Begin by checking that the pik isn't approaching it's resting position.
    -- How we calculate the vectors from here on differs according to the above condition.
    if finalVector:Length() > 0.2 then
      -- If heading to a target, our final vector is the sum of all previous rules.
      finalVector = v1 + v2

      targetPik:ToFamiliar():FollowPosition(finalVector)

      table.insert(DebugTargetPositions, finalVector)
    else
      -- If at target, our final vector is all previous rules with the piks' current position as the target.
      finalVector = targetPik.Position + v2

      targetPik:ToFamiliar():FollowPosition(finalVector)

      -- Do a basic deceleration towards stopping.
      if targetPik.Velocity:Length() > 0.1 then
        targetPik.Velocity = targetPik.Velocity * 0.9
      else
        targetPik.Velocity = targetPik.Velocity * 0
      end
    end

  end

  PikBoid.LastFrameUpdate = Game():GetFrameCount()
end

-- Make the piks seek out player
function PikBoid:MoveToPlayer(targetPik)
  local player = Isaac.GetPlayer(0)
  local pikDist = targetPik.Position:Distance(player.Position)

  Isaac.DebugString("Pik dist: " .. pikDist)

  -- If the player is too far away, seek them out.
  if pikDist > PikBoid.PlayerGatherRadius then

    local targetPosition = player.Position - (player.Position - targetPik.Position):Normalized()

    return targetPosition
  else
    return Vector(0, 0)
  end
end

function PikBoid:SeparateTargets(piks, targetPik)
  local finalVector = Vector(0, 0)
  
  -- For every other pik, if the distance between is too great, move them away by the desired spacing.
  for otherPik, i in PikBoid:NotEqualIterator(targetPik,piks)
  do
    if otherPik.Position:Distance(targetPik.Position) < PikBoid.SpacingTarget then
      finalVector = (finalVector - (otherPik.Position - targetPik.Position)):Normalized() * PikBoid.SpacingTarget

      -- If piks are exactly over eachother, nudge them away.
      if finalVector:Length() == 0 then
        finalVector = Vector(i, i + 1 % 5)
      end
    end
  end
  
  return finalVector
end

-- Higher-order iterator for boid calculations which iterates over every element NOT equal to the given filter.
function PikBoid:NotEqualIterator(pik,piks)
    local index = 0
    local count = #piks -- Get the total length of the collection.

    return function ()
        index = index + 1
        
        -- If we still have elements left to iterate over
        if index <= count then
            -- If the element is not equal to the filter value, return it.
            if piks[index] ~= pik then
                return piks[index], index
            -- If the element matches, and there are still elements after this one to loop over,
            -- increment and return the element.
            elseif piks[index] == pik and index < count then
                index = index + 1
                return piks[index], index
            end
        end
    end
end

function PikBoid:LimitVelocity(v)
  local limit = PikBoid.SpeedLimit

  if v:Length() > limit then
    v:Resize(limit)
  end

  return v
end

function PikBoid:OnRender()
  if PikBoid.EnableDebugTargetDestinations then
    local coord = Vector(25, 25)
  
    for i, pos in ipairs(DebugTargetPositions) do
      coord = Isaac.WorldToScreen(pos)
  
      Isaac.DebugString("Debug target " .. coord.X .. ", " .. coord.Y)
  
      DebugTarget:RenderLayer(0, coord)
      table.remove(DebugTargetPositions, i)
    end
  end
end

function PikBoid:InjectCallbacks(Mod)
  Mod:AddCallback(ModCallbacks.MC_POST_RENDER, PikBoid.OnRender)
end

return PikBoid