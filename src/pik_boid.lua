local PikBoid = {}

function PikBoid:UpdateBoid(piks)

    local v1, v2, v3

    Isaac.DebugString("Updating boids")

    for i,targetPik in ipairs(piks)
    do
        v1 = PikBoid:CalculateSeparation()
        v2 = PikBoid:CalculateAlignment()
        v3 = PikBoid:CalculateCohesion()

        Isaac.DebugString("  Calculating boid for pik " .. tostring(i))

        for otherPik in PikBoid:NotEqualIterator(targetPik,piks)
        do
            Isaac.DebugString("    Entered inequality iterator with pik " .. tostring(otherPik))
        end

        local finalVelocity = v1 + v2 + v3
        
        Isaac.DebugString("  Boid calc finished with result " .. tostring(finalVelocity))
    end

end

function PikBoid:CalculateSeparation()
  return Vector(1, 1)
end

function PikBoid:CalculateAlignment()
  return Vector(1, 1)
end

function PikBoid:CalculateCohesion()
  return Vector(1, 1)
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

return PikBoid