-- Project Manager for Mining Operations
-- Handles project creation, management, and progress tracking

local protocol = require("protocol")
local projectManager = {}

-- Project types
projectManager.PROJECT_TYPES = {
    BRANCH_MINE = "branch_mine",
    QUARRY = "quarry",
    STRIP_MINE = "strip_mine",
    CUSTOM = "custom"
}

-- Project status
projectManager.STATUS = {
    PENDING = "pending",
    ACTIVE = "active",
    PAUSED = "paused",
    COMPLETED = "completed",
    CANCELLED = "cancelled"
}

-- Internal storage
local projects = {}
local nextProjectNumber = 1

-- Debug: Module load counter
if not _G.projectManagerLoadCount then
    _G.projectManagerLoadCount = 0
end
_G.projectManagerLoadCount = _G.projectManagerLoadCount + 1
print("DEBUG: project-manager.lua loaded (count: " .. _G.projectManagerLoadCount .. ")")

-- ========== PROJECT CREATION ==========

function projectManager.create(projectType, name, config, startPos)
    if not projectManager.PROJECT_TYPES[projectType:upper()] then
        error("Invalid project type: " .. projectType)
    end
    
    local projectId = protocol.generateUUID()
    
    local project = {
        id = projectId,
        type = projectType,
        name = name or ("Project-" .. nextProjectNumber),
        status = projectManager.STATUS.PENDING,
        created = os.epoch("utc"),
        startPos = startPos or {x = 0, y = 0, z = 0},
        config = config or projectManager.getDefaultConfig(projectType),
        assignedTurtles = {},
        progress = {
            blocksCleared = 0,
            oreFound = 0,
            completion = 0,
            lastUpdate = os.epoch("utc")
        },
        stats = {
            startTime = nil,
            endTime = nil,
            totalFuelUsed = 0,
            totalDistance = 0
        }
    }
    
    projects[projectId] = project
    nextProjectNumber = nextProjectNumber + 1
    
    -- Debug: Verify storage
    local count = 0
    for _ in pairs(projects) do count = count + 1 end
    print("DEBUG: Project stored. Total projects in table: " .. count)
    
    return projectId, project
end

function projectManager.getDefaultConfig(projectType)
    local configs = {
        branch_mine = {
            corridorLength = 100,
            branchLength = 32,
            branchSpacing = 4,
            branchesPerSide = 10,
            branchWidth = 3,
            placeTorches = true,
            torchSpacing = 8
        },
        quarry = {
            width = 16,
            length = 16,
            depth = 64,
            minY = -64,
            removeFluid = true
        },
        strip_mine = {
            tunnelLength = 64,
            tunnelCount = 10,
            tunnelSpacing = 3,
            tunnelHeight = 3
        },
        custom = {}
    }
    
    return configs[projectType] or {}
end

-- ========== PROJECT ASSIGNMENT ==========

function projectManager.assign(turtleId, projectId, role, zone)
    local project = projects[projectId]
    if not project then
        return false, "Project not found"
    end
    
    if project.assignedTurtles[turtleId] then
        return false, "Turtle already assigned to this project"
    end
    
    project.assignedTurtles[turtleId] = {
        id = turtleId,
        role = role or "miner",
        zone = zone or 1,
        assignedAt = os.epoch("utc"),
        status = "assigned"
    }
    
    -- If this is the first turtle, activate the project
    if project.status == projectManager.STATUS.PENDING then
        project.status = projectManager.STATUS.ACTIVE
        project.stats.startTime = os.epoch("utc")
    end
    
    return true
end

function projectManager.unassign(turtleId, projectId)
    local project = projects[projectId]
    if not project then
        return false, "Project not found"
    end
    
    if not project.assignedTurtles[turtleId] then
        return false, "Turtle not assigned to this project"
    end
    
    project.assignedTurtles[turtleId] = nil
    
    -- Check if any turtles remain
    local count = 0
    for _ in pairs(project.assignedTurtles) do
        count = count + 1
    end
    
    if count == 0 and project.status == projectManager.STATUS.ACTIVE then
        project.status = projectManager.STATUS.PAUSED
    end
    
    return true
end

-- ========== PROJECT QUERIES ==========

function projectManager.get(projectId)
    return projects[projectId]
end

function projectManager.getAll()
    local count = 0
    for _ in pairs(projects) do count = count + 1 end
    print("DEBUG: projectManager.getAll() called - returning " .. count .. " projects")
    return projects
end

function projectManager.getByStatus(status)
    local filtered = {}
    for id, project in pairs(projects) do
        if project.status == status then
            filtered[id] = project
        end
    end
    return filtered
end

function projectManager.getTurtleProject(turtleId)
    for projectId, project in pairs(projects) do
        if project.assignedTurtles[turtleId] then
            return projectId, project
        end
    end
    return nil
end

function projectManager.getAssignedTurtles(projectId)
    local project = projects[projectId]
    if not project then
        return {}
    end
    return project.assignedTurtles
end

-- ========== ZONE MANAGEMENT ==========

function projectManager.getZones(projectId)
    local project = projects[projectId]
    if not project then
        return {}
    end
    
    local zones = {}
    for turtleId, assignment in pairs(project.assignedTurtles) do
        zones[turtleId] = assignment.zone
    end
    
    return zones
end

function projectManager.assignZone(projectId, turtleId, zone)
    local project = projects[projectId]
    if not project then
        return false, "Project not found"
    end
    
    if not project.assignedTurtles[turtleId] then
        return false, "Turtle not assigned to project"
    end
    
    project.assignedTurtles[turtleId].zone = zone
    return true
end

-- ========== PROGRESS TRACKING ==========

function projectManager.updateProgress(projectId, turtleId, progressData)
    local project = projects[projectId]
    if not project then
        return false, "Project not found"
    end
    
    -- Update project-level progress
    if progressData.blocksCleared then
        project.progress.blocksCleared = project.progress.blocksCleared + progressData.blocksCleared
    end
    
    if progressData.oreFound then
        project.progress.oreFound = project.progress.oreFound + progressData.oreFound
    end
    
    if progressData.fuelUsed then
        project.stats.totalFuelUsed = project.stats.totalFuelUsed + progressData.fuelUsed
    end
    
    if progressData.distance then
        project.stats.totalDistance = project.stats.totalDistance + progressData.distance
    end
    
    project.progress.lastUpdate = os.epoch("utc")
    
    -- Calculate completion percentage
    project.progress.completion = projectManager.calculateCompletion(project)
    
    -- Update turtle-specific status
    if project.assignedTurtles[turtleId] then
        project.assignedTurtles[turtleId].status = progressData.status or "working"
        project.assignedTurtles[turtleId].lastUpdate = os.epoch("utc")
    end
    
    -- Check if project is complete
    if project.progress.completion >= 100 then
        project.status = projectManager.STATUS.COMPLETED
        project.stats.endTime = os.epoch("utc")
    end
    
    return true
end

function projectManager.calculateCompletion(project)
    local config = project.config
    local progress = project.progress
    
    if project.type == projectManager.PROJECT_TYPES.BRANCH_MINE then
        local totalBranches = config.branchesPerSide * 2
        local blocksPerBranch = config.branchLength * config.branchWidth * 3
        local totalBlocks = config.corridorLength * 3 * 3 + (totalBranches * blocksPerBranch)
        return math.min(100, math.floor((progress.blocksCleared / totalBlocks) * 100))
        
    elseif project.type == projectManager.PROJECT_TYPES.QUARRY then
        local totalBlocks = config.width * config.length * config.depth
        return math.min(100, math.floor((progress.blocksCleared / totalBlocks) * 100))
        
    elseif project.type == projectManager.PROJECT_TYPES.STRIP_MINE then
        local blocksPerTunnel = config.tunnelLength * config.tunnelHeight * 3
        local totalBlocks = blocksPerTunnel * config.tunnelCount
        return math.min(100, math.floor((progress.blocksCleared / totalBlocks) * 100))
        
    else
        -- For custom projects, just return 0 or manually set completion
        return 0
    end
end

-- ========== COORDINATION ==========

function projectManager.getCoordination(projectId)
    local project = projects[projectId]
    if not project then
        return nil
    end
    
    local coordination = {
        projectId = projectId,
        projectType = project.type,
        startPos = project.startPos,
        config = project.config,
        turtles = {}
    }
    
    for turtleId, assignment in pairs(project.assignedTurtles) do
        table.insert(coordination.turtles, {
            id = turtleId,
            role = assignment.role,
            zone = assignment.zone,
            status = assignment.status
        })
    end
    
    return coordination
end

-- ========== PROJECT CONTROL ==========

function projectManager.pause(projectId)
    local project = projects[projectId]
    if not project then
        return false, "Project not found"
    end
    
    if project.status == projectManager.STATUS.ACTIVE then
        project.status = projectManager.STATUS.PAUSED
        return true
    end
    
    return false, "Project is not active"
end

function projectManager.resume(projectId)
    local project = projects[projectId]
    if not project then
        return false, "Project not found"
    end
    
    if project.status == projectManager.STATUS.PAUSED then
        project.status = projectManager.STATUS.ACTIVE
        return true
    end
    
    return false, "Project is not paused"
end

function projectManager.cancel(projectId)
    local project = projects[projectId]
    if not project then
        return false, "Project not found"
    end
    
    project.status = projectManager.STATUS.CANCELLED
    project.stats.endTime = os.epoch("utc")
    return true
end

function projectManager.delete(projectId)
    if not projects[projectId] then
        return false, "Project not found"
    end
    
    projects[projectId] = nil
    return true
end

-- ========== STATISTICS ==========

function projectManager.getStats(projectId)
    local project = projects[projectId]
    if not project then
        return nil
    end
    
    local stats = {
        blocksCleared = project.progress.blocksCleared,
        oreFound = project.progress.oreFound,
        completion = project.progress.completion,
        fuelUsed = project.stats.totalFuelUsed,
        distance = project.stats.totalDistance,
        assignedTurtles = 0,
        runtime = 0
    }
    
    for _ in pairs(project.assignedTurtles) do
        stats.assignedTurtles = stats.assignedTurtles + 1
    end
    
    if project.stats.startTime then
        local endTime = project.stats.endTime or os.epoch("utc")
        stats.runtime = math.floor((endTime - project.stats.startTime) / 1000) -- Convert to seconds
    end
    
    return stats
end

function projectManager.getSummary()
    local summary = {
        totalProjects = 0,
        activeProjects = 0,
        completedProjects = 0,
        totalTurtles = 0,
        totalBlocksCleared = 0,
        totalOreFound = 0
    }
    
    for _, project in pairs(projects) do
        summary.totalProjects = summary.totalProjects + 1
        
        if project.status == projectManager.STATUS.ACTIVE then
            summary.activeProjects = summary.activeProjects + 1
        elseif project.status == projectManager.STATUS.COMPLETED then
            summary.completedProjects = summary.completedProjects + 1
        end
        
        for _ in pairs(project.assignedTurtles) do
            summary.totalTurtles = summary.totalTurtles + 1
        end
        
        summary.totalBlocksCleared = summary.totalBlocksCleared + project.progress.blocksCleared
        summary.totalOreFound = summary.totalOreFound + project.progress.oreFound
    end
    
    return summary
end

return projectManager

