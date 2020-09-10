-- Boid behaviour coordinator heavily based on the following work by Conrad Parker: http://www.kfish.org/boids/pseudocode.html


local PikBoid = {}

-- The final speed is campled to 0 if smaller than this.
PikBoid.ClampToTarget = 1
-- The final speed is limited by this amount
PikBoid.SpeedLimit = 5
PikBoid.SpeedCoefficient = 1
-- How much to separate from other piks
PikBoid.SpacingTarget = 25

function PikBoid:UpdateBoid(piks)

    local v1, v2, v3, v4

    Isaac.DebugString("Updating boids")

    for i,targetPik in ipairs(piks)
    do
        v1 = PikBoid:CalculateSeparation(piks, targetPik)
        v2 = PikBoid:CalculateAlignment(piks, targetPik)
        v3 = PikBoid:CalculateCohesion(piks, targetPik)
        v4 = PikBoid:TendToPlace(targetPik)

        Isaac.DebugString("  Calculating boid for pik " .. tostring(i))

        for otherPik in PikBoid:NotEqualIterator(targetPik,piks)
        do
            Isaac.DebugString("    Entered inequality iterator with pik " .. tostring(otherPik))
        end

        local finalVelocity = v1 + v2 + v3 + v4
        
        PikBoid:LimitVelocity(finalVelocity)
        PikBoid:SoftenTargetApproach(finalVelocity)

        Isaac.DebugString("  Boid calc finished with result " .. finalVelocity.X .. ", " .. finalVelocity.Y)

        targetPik.Velocity = finalVelocity
    end

end

function PikBoid:CalculateSeparation(piks, targetPik)
  local finalVector = Vector(0, 0)
  local totalPiks = #piks
  
  for otherPik in PikBoid:NotEqualIterator(targetPik,piks)
  do
    finalVector = finalVector + otherPik.Position
  end
  
  finalVector = finalVector / (totalPiks - 1)
  
  return (finalVector - targetPik.Position) / 100
end

function PikBoid:CalculateAlignment(piks, targetPik)
  local finalVector = Vector(0, 0)
  
  for otherPik in PikBoid:NotEqualIterator(targetPik,piks)
  do    
    if otherPik.Position:Distance(targetPik.Position) < PikBoid.SpacingTarget then
      finalVector = finalVector - (otherPik.Position - targetPik.Position)
    end
  end
  
  return finalVector
end

function PikBoid:CalculateCohesion(piks, targetPik)
  local finalVector = Vector(0, 0)
  local totalPiks = #piks
  
  for otherPik in PikBoid:NotEqualIterator(targetPik,piks)
  do
    finalVector = finalVector + otherPik.Velocity
  end
  
  finalVector = finalVector / (totalPiks - 1)
  
  return (finalVector - targetPik.Velocity) / 8
end

-- Set a goal for the boid to move to a target position.
function PikBoid:TendToPlace(pik)
  local target = Isaac.GetPlayer(0).Position
  return (target - pik.Position) / (100 / PikBoid.SpeedCoefficient)
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
                return piks[index]
            -- If the element matches, and there are still elements after this one to loop over,
            -- increment and return the element.
            elseif piks[index] == pik and index < count then
                index = index + 1
                return piks[index]
            end
        end
    end
end

function PikBoid:AbsVector(vec)
  return Vector(math.abs(vec.X), math.abs(vec.Y))
end

function PikBoid:LimitVelocity(v)
  local limit = PikBoid.SpeedLimit

  if v:Length() > limit then
    v:Resize(limit)
  end

  return v
end

function PikBoid:SoftenTargetApproach(v)
  if math.abs(v:Length()) < PikBoid.ClampToTarget then
    v.X = 0
    v.Y = 0
  end

  return v
end

return PikBoid