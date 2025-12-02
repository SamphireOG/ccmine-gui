-- Zone Allocator for Multi-Turtle Coordination
-- Intelligently divides projects into zones to prevent collisions

local zoneAllocator = {}

-- Safe distance between turtles (in blocks)
zoneAllocator.SAFE_DISTANCE = 3

-- ========== ZONE ALLOCATION ==========

function zoneAllocator.allocate(project, turtles)
    local projectType = project.type
    local config = project.config
    local startPos = project.startPos
    
    local allocations = {}
    
    if projectType == "branch_mine" then
        allocations = zoneAllocator.allocateBranchMine(project, turtles)
    elseif projectType == "quarry" then
        allocations = zoneAllocator.allocateQuarry(project, turtles)
    elseif projectType == "strip_mine" then
        allocations = zoneAllocator.allocateStripMine(project, turtles)
    else
        -- Custom project - simple zone numbering
        allocations = zoneAllocator.allocateCustom(project, turtles)
    end
    
    return allocations
end

-- ========== BRANCH MINING ALLOCATION ==========

function zoneAllocator.allocateBranchMine(project, turtles)
    local config = project.config
    local startPos = project.startPos
    local allocations = {}
    
    local totalBranches = config.branchesPerSide * 2
    local turtleCount = #turtles
    
    if turtleCount == 0 then
        return allocations
    end
    
    local branchesPerTurtle = math.ceil(totalBranches / turtleCount)
    local currentBranch = 1
    
    for i, turtleId in ipairs(turtles) do
        local branchStart = currentBranch
        local branchEnd = math.min(currentBranch + branchesPerTurtle - 1, totalBranches)
        
        -- Determine side (left or right)
        local side = "mixed"
        if branchEnd <= config.branchesPerSide then
            side = "left"
        elseif branchStart > config.branchesPerSide then
            side = "right"
        end
        
        -- Calculate boundaries
        local corridorStart = startPos.z + ((branchStart - 1) * config.branchSpacing)
        local corridorEnd = startPos.z + (branchEnd * config.branchSpacing)
        
        allocations[turtleId] = {
            zone = i,
            type = "branch_mine",
            boundaries = {
                minX = startPos.x - config.branchLength - 5,
                maxX = startPos.x + config.branchLength + 5,
                minY = startPos.y - 3,
                maxY = startPos.y + 3,
                minZ = corridorStart,
                maxZ = corridorEnd
            },
            startPos = {
                x = startPos.x,
                y = startPos.y,
                z = corridorStart
            },
            instructions = string.format("Mine branches %d-%d on %s side", 
                branchStart, branchEnd, side),
            branchRange = {
                start = branchStart,
                ending = branchEnd,
                side = side
            }
        }
        
        currentBranch = branchEnd + 1
    end
    
    return allocations
end

-- ========== QUARRY ALLOCATION ==========

function zoneAllocator.allocateQuarry(project, turtles)
    local config = project.config
    local startPos = project.startPos
    local allocations = {}
    
    local turtleCount = #turtles
    
    if turtleCount == 0 then
        return allocations
    end
    
    -- Divide quarry into vertical slices
    local sliceWidth = math.ceil(config.width / turtleCount)
    local currentX = 0
    
    for i, turtleId in ipairs(turtles) do
        local sliceStart = currentX
        local sliceEnd = math.min(currentX + sliceWidth, config.width)
        
        allocations[turtleId] = {
            zone = i,
            type = "quarry",
            boundaries = {
                minX = startPos.x + sliceStart,
                maxX = startPos.x + sliceEnd - 1,
                minY = config.minY,
                maxY = startPos.y,
                minZ = startPos.z,
                maxZ = startPos.z + config.length - 1
            },
            startPos = {
                x = startPos.x + sliceStart,
                y = startPos.y,
                z = startPos.z
            },
            instructions = string.format("Excavate slice %d (X: %d to %d)", 
                i, sliceStart, sliceEnd - 1),
            slice = {
                index = i,
                start = sliceStart,
                ending = sliceEnd - 1
            }
        }
        
        currentX = sliceEnd
    end
    
    return allocations
end

-- ========== STRIP MINING ALLOCATION ==========

function zoneAllocator.allocateStripMine(project, turtles)
    local config = project.config
    local startPos = project.startPos
    local allocations = {}
    
    local turtleCount = #turtles
    
    if turtleCount == 0 then
        return allocations
    end
    
    local tunnelsPerTurtle = math.ceil(config.tunnelCount / turtleCount)
    local currentTunnel = 1
    
    for i, turtleId in ipairs(turtles) do
        local tunnelStart = currentTunnel
        local tunnelEnd = math.min(currentTunnel + tunnelsPerTurtle - 1, config.tunnelCount)
        
        -- Calculate Z coordinates for tunnel range
        local zStart = startPos.z + ((tunnelStart - 1) * config.tunnelSpacing)
        local zEnd = startPos.z + ((tunnelEnd - 1) * config.tunnelSpacing) + 2
        
        allocations[turtleId] = {
            zone = i,
            type = "strip_mine",
            boundaries = {
                minX = startPos.x,
                maxX = startPos.x + config.tunnelLength,
                minY = startPos.y - 3,
                maxY = startPos.y + config.tunnelHeight,
                minZ = zStart,
                maxZ = zEnd
            },
            startPos = {
                x = startPos.x,
                y = startPos.y,
                z = zStart
            },
            instructions = string.format("Mine tunnels %d-%d", 
                tunnelStart, tunnelEnd),
            tunnelRange = {
                start = tunnelStart,
                ending = tunnelEnd
            }
        }
        
        currentTunnel = tunnelEnd + 1
    end
    
    return allocations
end

-- ========== CUSTOM ALLOCATION ==========

function zoneAllocator.allocateCustom(project, turtles)
    local startPos = project.startPos
    local allocations = {}
    
    for i, turtleId in ipairs(turtles) do
        allocations[turtleId] = {
            zone = i,
            type = "custom",
            boundaries = {
                minX = startPos.x - 50,
                maxX = startPos.x + 50,
                minY = startPos.y - 50,
                maxY = startPos.y + 50,
                minZ = startPos.z - 50,
                maxZ = startPos.z + 50
            },
            startPos = {
                x = startPos.x,
                y = startPos.y,
                z = startPos.z
            },
            instructions = string.format("Zone %d - Await manual instructions", i)
        }
    end
    
    return allocations
end

-- ========== COLLISION DETECTION ==========

function zoneAllocator.checkConflict(pos1, pos2, safeDistance)
    local distance = safeDistance or zoneAllocator.SAFE_DISTANCE
    
    local dx = math.abs(pos1.x - pos2.x)
    local dy = math.abs(pos1.y - pos2.y)
    local dz = math.abs(pos1.z - pos2.z)
    
    -- Use 3D Euclidean distance
    local dist3d = math.sqrt(dx*dx + dy*dy + dz*dz)
    
    return dist3d < distance
end

function zoneAllocator.isInBoundary(position, boundaries)
    return position.x >= boundaries.minX and position.x <= boundaries.maxX and
           position.y >= boundaries.minY and position.y <= boundaries.maxY and
           position.z >= boundaries.minZ and position.z <= boundaries.maxZ
end

function zoneAllocator.checkAllConflicts(turtles, safeDistance)
    local conflicts = {}
    local turtleList = {}
    
    -- Convert to list for easier iteration
    for id, turtle in pairs(turtles) do
        table.insert(turtleList, {id = id, pos = turtle.position})
    end
    
    -- Check each pair
    for i = 1, #turtleList do
        for j = i + 1, #turtleList do
            local t1 = turtleList[i]
            local t2 = turtleList[j]
            
            if zoneAllocator.checkConflict(t1.pos, t2.pos, safeDistance) then
                table.insert(conflicts, {
                    turtle1 = t1.id,
                    turtle2 = t2.id,
                    distance = math.sqrt(
                        math.pow(t1.pos.x - t2.pos.x, 2) +
                        math.pow(t1.pos.y - t2.pos.y, 2) +
                        math.pow(t1.pos.z - t2.pos.z, 2)
                    )
                })
            end
        end
    end
    
    return conflicts
end

-- ========== ZONE QUERIES ==========

function zoneAllocator.getTurtleZone(turtleId, allocations)
    return allocations[turtleId]
end

function zoneAllocator.getAdjacentZones(zone, allocations)
    local adjacent = {}
    
    for turtleId, allocation in pairs(allocations) do
        if allocation.zone ~= zone then
            -- Check if zones are adjacent (zone numbers differ by 1)
            if math.abs(allocation.zone - zone) == 1 then
                table.insert(adjacent, {
                    turtleId = turtleId,
                    zone = allocation.zone,
                    boundaries = allocation.boundaries
                })
            end
        end
    end
    
    return adjacent
end

function zoneAllocator.visualizeBoundaries(boundaries, width, height)
    -- Create a simple 2D visualization of boundaries (X-Z plane)
    local visual = {}
    
    for z = 0, height - 1 do
        visual[z] = {}
        for x = 0, width - 1 do
            visual[z][x] = " "
        end
    end
    
    -- Mark boundary corners
    local minX = math.max(0, boundaries.minX)
    local maxX = math.min(width - 1, boundaries.maxX)
    local minZ = math.max(0, boundaries.minZ)
    local maxZ = math.min(height - 1, boundaries.maxZ)
    
    for z = minZ, maxZ do
        for x = minX, maxX do
            if z == minZ or z == maxZ or x == minX or x == maxX then
                visual[z][x] = "#"
            else
                visual[z][x] = "."
            end
        end
    end
    
    return visual
end

-- ========== ZONE INFO HELPERS ==========

function zoneAllocator.getZoneBoundaries(project, zoneNumber)
    -- Ensure startPos has all coordinates with defaults
    local rawStartPos = project.startPos or {}
    local startPos = {
        x = rawStartPos.x or 0,
        y = rawStartPos.y or 11,
        z = rawStartPos.z or 0
    }
    local config = project.config or {}
    
    if project.type == "branch_mine" then
        local branchSpacing = config.branchSpacing or 4
        local branchLength = config.sideTunnelLength or config.branchLength or 32
        local zStart = startPos.z + ((zoneNumber - 1) * branchSpacing * 2)
        
        return {
            minX = startPos.x - branchLength - 5,
            maxX = startPos.x + branchLength + 5,
            minY = startPos.y - 3,
            maxY = startPos.y + 3,
            minZ = zStart,
            maxZ = zStart + (branchSpacing * 2)
        }
    elseif project.type == "quarry" then
        local width = config.width or 16
        local sliceWidth = math.ceil(width / 8)
        local sliceStart = (zoneNumber - 1) * sliceWidth
        
        return {
            minX = startPos.x + sliceStart,
            maxX = startPos.x + sliceStart + sliceWidth - 1,
            minY = config.minY or 5,
            maxY = startPos.y,
            minZ = startPos.z,
            maxZ = startPos.z + (config.length or 16) - 1
        }
    elseif project.type == "strip_mine" then
        local tunnelSpacing = config.tunnelSpacing or 3
        local tunnelLength = config.mainTunnelLength or config.tunnelLength or 64
        local zStart = startPos.z + ((zoneNumber - 1) * tunnelSpacing)
        
        return {
            minX = startPos.x,
            maxX = startPos.x + tunnelLength,
            minY = startPos.y - 3,
            maxY = startPos.y + 3,
            minZ = zStart,
            maxZ = zStart + 2
        }
    else
        return {
            minX = startPos.x - 50,
            maxX = startPos.x + 50,
            minY = startPos.y - 50,
            maxY = startPos.y + 50,
            minZ = startPos.z - 50,
            maxZ = startPos.z + 50
        }
    end
end

function zoneAllocator.getZoneInstructions(project, zoneNumber)
    if project.type == "branch_mine" then
        local side = (zoneNumber % 2 == 1) and "left" or "right"
        local branchNum = math.ceil(zoneNumber / 2)
        return string.format("Mine branch %d on %s side", branchNum, side)
    elseif project.type == "quarry" then
        return string.format("Excavate slice %d", zoneNumber)
    elseif project.type == "strip_mine" then
        return string.format("Mine tunnel %d", zoneNumber)
    else
        return string.format("Zone %d - Await instructions", zoneNumber)
    end
end

function zoneAllocator.getMaxZones(project)
    if project.type == "branch_mine" then
        return 4  -- 2 left, 2 right
    elseif project.type == "quarry" then
        return 8  -- 8 vertical slices
    elseif project.type == "strip_mine" then
        return 6  -- 6 parallel tunnels
    else
        return 4  -- Default
    end
end

-- ========== UTILITIES ==========

function zoneAllocator.calculateDistance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function zoneAllocator.findNearestTurtle(position, turtles)
    local nearest = nil
    local nearestDistance = math.huge
    
    for id, turtle in pairs(turtles) do
        local dist = zoneAllocator.calculateDistance(position, turtle.position)
        if dist < nearestDistance then
            nearest = id
            nearestDistance = dist
        end
    end
    
    return nearest, nearestDistance
end

return zoneAllocator

