-- Coordinator Server for Turtle Network Management
-- Runs on a control computer to manage turtle fleet

local protocol = require("protocol")
local projectManager = require("project-manager")
local zoneAllocator = require("zone-allocator")

local coordinator = {}

-- Configuration
coordinator.HEARTBEAT_TIMEOUT = 300 -- 5 minutes in seconds
coordinator.HEALTH_CHECK_INTERVAL = 30 -- Check every 30 seconds

-- Internal state
local state = {
    running = false,
    registry = {},
    startTime = nil
}

-- ========== INITIALIZATION ==========

function coordinator.start()
    if state.running then
        print("Coordinator already running!")
        return false
    end
    
    print("Starting CCMine Coordinator...")
    
    -- Initialize protocol
    local success = protocol.init("coordinator")
    if not success then
        print("Failed to initialize protocol!")
        return false
    end
    
    state.running = true
    state.startTime = os.epoch("utc")
    
    print("Coordinator started successfully!")
    print("Computer ID: " .. os.getComputerID())
    print("Listening for turtle connections...")
    
    return true
end

function coordinator.stop()
    if not state.running then
        return
    end
    
    print("Stopping coordinator...")
    protocol.close()
    state.running = false
    print("Coordinator stopped.")
end

function coordinator.isRunning()
    return state.running
end

-- ========== TURTLE REGISTRY ==========

function coordinator.handleRegister(turtleId, data)
    print(string.format("Turtle %d (%s) registered", turtleId, data.label or "Unlabeled"))
    
    state.registry[turtleId] = {
        id = turtleId,
        label = data.label or ("Turtle-" .. turtleId),
        capabilities = data.capabilities or {},
        lastHeartbeat = os.epoch("utc"),
        status = "idle",
        position = data.position or {x = 0, y = 0, z = 0},
        fuel = data.fuel or 0,
        inventory = data.inventory or 0,
        currentProject = nil,
        registeredAt = os.epoch("utc")
    }
    
    -- Send acknowledgment
    protocol.send(turtleId, protocol.MSG_TYPES.ACK, {
        message = "Registration successful",
        coordinatorId = os.getComputerID()
    })
    
    return true
end

function coordinator.handleHeartbeat(turtleId, data)
    local turtle = state.registry[turtleId]
    
    if not turtle then
        -- Turtle not registered, ask it to register
        protocol.send(turtleId, protocol.MSG_TYPES.COMMAND, {
            command = "register",
            reason = "Not in registry"
        })
        return false
    end
    
    -- Update turtle data
    turtle.lastHeartbeat = os.epoch("utc")
    turtle.status = data.status or turtle.status
    turtle.position = data.position or turtle.position
    turtle.fuel = data.fuel or turtle.fuel
    turtle.inventory = data.inventory or turtle.inventory
    turtle.currentProject = data.currentProject or turtle.currentProject
    
    return true
end

function coordinator.getTurtle(turtleId)
    return state.registry[turtleId]
end

function coordinator.getAllTurtles()
    return state.registry
end

function coordinator.getTurtlesByStatus(status)
    local filtered = {}
    for id, turtle in pairs(state.registry) do
        if turtle.status == status then
            filtered[id] = turtle
        end
    end
    return filtered
end

-- ========== PROJECT ASSIGNMENT ==========

function coordinator.assignToProject(turtleId, projectId)
    local turtle = state.registry[turtleId]
    if not turtle then
        return false, "Turtle not found in registry"
    end
    
    local project = projectManager.get(projectId)
    if not project then
        return false, "Project not found"
    end
    
    -- Get current turtle assignments for zone allocation
    local assignedTurtles = projectManager.getAssignedTurtles(projectId)
    local turtleList = {}
    for id in pairs(assignedTurtles) do
        table.insert(turtleList, id)
    end
    table.insert(turtleList, turtleId)
    
    -- Allocate zones
    local allocations = zoneAllocator.allocate(project, turtleList)
    local assignment = allocations[turtleId]
    
    if not assignment then
        return false, "Failed to allocate zone"
    end
    
    -- Assign to project
    local success, err = projectManager.assign(turtleId, projectId, "miner", assignment.zone)
    if not success then
        return false, err
    end
    
    -- Update turtle registry
    turtle.currentProject = projectId
    turtle.status = "assigned"
    
    -- Send assignment to turtle
    protocol.send(turtleId, protocol.MSG_TYPES.PROJECT_ASSIGN, {
        projectId = projectId,
        project = project,
        assignment = assignment
    }, projectId)
    
    print(string.format("Assigned Turtle %d to Project '%s' (Zone %d)", 
        turtleId, project.name, assignment.zone))
    
    return true
end

function coordinator.unassignFromProject(turtleId)
    local turtle = state.registry[turtleId]
    if not turtle then
        return false, "Turtle not found"
    end
    
    if not turtle.currentProject then
        return false, "Turtle not assigned to any project"
    end
    
    local projectId = turtle.currentProject
    projectManager.unassign(turtleId, projectId)
    
    turtle.currentProject = nil
    turtle.status = "idle"
    
    -- Notify turtle
    protocol.send(turtleId, protocol.MSG_TYPES.COMMAND, {
        command = "unassign",
        projectId = projectId
    })
    
    print(string.format("Unassigned Turtle %d from project", turtleId))
    
    return true
end

-- ========== COORDINATION ==========

function coordinator.handleCoordRequest(turtleId, data)
    local projectId = data.projectId
    
    if not projectId then
        return false, "No project ID provided"
    end
    
    local coordination = projectManager.getCoordination(projectId)
    
    if not coordination then
        return false, "Project not found"
    end
    
    -- Add current positions from registry
    for _, turtleInfo in ipairs(coordination.turtles) do
        local turtle = state.registry[turtleInfo.id]
        if turtle then
            turtleInfo.position = turtle.position
            turtleInfo.status = turtle.status
            turtleInfo.label = turtle.label
        end
    end
    
    -- Send coordination data
    protocol.send(turtleId, protocol.MSG_TYPES.COORD_RESPONSE, coordination, projectId)
    
    return true
end

function coordinator.broadcastCoordination(projectId)
    local coordination = projectManager.getCoordination(projectId)
    
    if not coordination then
        return false
    end
    
    -- Add current positions
    for _, turtleInfo in ipairs(coordination.turtles) do
        local turtle = state.registry[turtleInfo.id]
        if turtle then
            turtleInfo.position = turtle.position
            turtleInfo.status = turtle.status
        end
    end
    
    -- Send to all turtles on this project
    local assignedTurtles = projectManager.getAssignedTurtles(projectId)
    for turtleId in pairs(assignedTurtles) do
        protocol.send(turtleId, protocol.MSG_TYPES.COORD_RESPONSE, coordination, projectId)
    end
    
    return true
end

-- ========== HEALTH MONITORING ==========

function coordinator.checkHealth()
    local currentTime = os.epoch("utc")
    local lostTurtles = {}
    
    for turtleId, turtle in pairs(state.registry) do
        local timeSinceHeartbeat = (currentTime - turtle.lastHeartbeat) / 1000 -- Convert to seconds
        
        if timeSinceHeartbeat > coordinator.HEARTBEAT_TIMEOUT then
            table.insert(lostTurtles, turtleId)
            
            -- If turtle was on a project, unassign it
            if turtle.currentProject then
                projectManager.unassign(turtleId, turtle.currentProject)
            end
            
            turtle.status = "lost"
            print(string.format("Warning: Turtle %d (%s) connection lost", turtleId, turtle.label))
        end
    end
    
    return lostTurtles
end

function coordinator.healthCheckLoop()
    while state.running do
        coordinator.checkHealth()
        sleep(coordinator.HEALTH_CHECK_INTERVAL)
    end
end

-- ========== MESSAGE HANDLING ==========

function coordinator.handleMessage(message, senderID)
    local msgType = message.type
    
    if msgType == protocol.MSG_TYPES.REGISTER then
        coordinator.handleRegister(senderID, message.data)
        
    elseif msgType == protocol.MSG_TYPES.HEARTBEAT then
        coordinator.handleHeartbeat(senderID, message.data)
        
    elseif msgType == protocol.MSG_TYPES.PROJECT_UPDATE then
        local data = message.data
        projectManager.updateProgress(data.projectId, senderID, data.progress)
        
    elseif msgType == protocol.MSG_TYPES.COORD_REQUEST then
        coordinator.handleCoordRequest(senderID, message.data)
        
    else
        print(string.format("Unknown message type from %d: %s", senderID, msgType))
    end
end

function coordinator.messageLoop()
    while state.running do
        local message, senderID = protocol.receive(1) -- 1 second timeout
        
        if message then
            coordinator.handleMessage(message, senderID)
        end
    end
end

-- ========== MAIN LOOP ==========

function coordinator.run()
    if not coordinator.start() then
        return
    end
    
    print("Coordinator is running. Press Ctrl+T to stop.")
    
    -- Run message loop and health check in parallel
    parallel.waitForAny(
        function() coordinator.messageLoop() end,
        function() coordinator.healthCheckLoop() end
    )
end

-- ========== STATISTICS ==========

function coordinator.getStats()
    local stats = {
        uptime = 0,
        totalTurtles = 0,
        idleTurtles = 0,
        workingTurtles = 0,
        lostTurtles = 0,
        totalProjects = 0,
        activeProjects = 0
    }
    
    if state.startTime then
        stats.uptime = math.floor((os.epoch("utc") - state.startTime) / 1000)
    end
    
    for _, turtle in pairs(state.registry) do
        stats.totalTurtles = stats.totalTurtles + 1
        
        if turtle.status == "idle" then
            stats.idleTurtles = stats.idleTurtles + 1
        elseif turtle.status == "working" or turtle.status == "assigned" then
            stats.workingTurtles = stats.workingTurtles + 1
        elseif turtle.status == "lost" then
            stats.lostTurtles = stats.lostTurtles + 1
        end
    end
    
    local projectSummary = projectManager.getSummary()
    stats.totalProjects = projectSummary.totalProjects
    stats.activeProjects = projectSummary.activeProjects
    
    return stats
end

-- ========== COMMANDS ==========

function coordinator.sendCommand(turtleId, command, params)
    return protocol.send(turtleId, protocol.MSG_TYPES.COMMAND, {
        command = command,
        params = params or {}
    })
end

function coordinator.broadcastCommand(command, params)
    return protocol.broadcast(protocol.MSG_TYPES.COMMAND, {
        command = command,
        params = params or {}
    })
end

return coordinator

