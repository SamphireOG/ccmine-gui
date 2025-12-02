-- Turtle Client for Network Communication
-- Runs on turtles to connect to coordinator and handle projects

local protocol = require("protocol")

local client = {}

-- Configuration
client.HEARTBEAT_INTERVAL = 30 -- Send heartbeat every 30 seconds
client.COORD_REQUEST_INTERVAL = 60 -- Request coordination every 60 seconds

-- Internal state
local state = {
    initialized = false,
    connected = false,
    coordinatorId = nil,
    currentProject = nil,
    currentAssignment = nil,
    status = "idle",
    position = {x = 0, y = 0, z = 0},
    startPosition = {x = 0, y = 0, z = 0},
    peers = {},
    stats = {
        blocksCleared = 0,
        oreFound = 0,
        fuelUsed = 0,
        distance = 0
    }
}

-- ========== INITIALIZATION ==========

function client.init(label)
    if state.initialized then
        print("Client already initialized")
        return true
    end
    
    print("Initializing turtle client...")
    
    -- Set label if provided
    if label and not os.getComputerLabel() then
        os.setComputerLabel(label)
    end
    
    -- Initialize protocol
    local success = protocol.init(os.getComputerLabel() or "turtle")
    if not success then
        print("Failed to initialize protocol!")
        return false
    end
    
    -- Get initial position (GPS if available)
    state.position = client.getPosition()
    state.startPosition = {
        x = state.position.x,
        y = state.position.y,
        z = state.position.z
    }
    
    state.initialized = true
    
    -- Try to register with coordinator
    client.registerWithCoordinator()
    
    print("Client initialized successfully")
    return true
end

function client.close()
    if not state.initialized then
        return
    end
    
    protocol.close()
    state.initialized = false
    state.connected = false
end

-- ========== REGISTRATION ==========

function client.registerWithCoordinator()
    print("Looking for coordinator...")
    
    local coordinatorId = protocol.findCoordinator()
    
    if not coordinatorId then
        print("No coordinator found. Will retry later.")
        state.connected = false
        return false
    end
    
    print("Found coordinator: " .. coordinatorId)
    state.coordinatorId = coordinatorId
    
    -- Send registration
    local data = protocol.buildRegisterMessage({
        position = state.position,
        fuel = turtle.getFuelLevel(),
        inventory = client.getInventoryCount()
    })
    
    protocol.send(coordinatorId, protocol.MSG_TYPES.REGISTER, data)
    
    -- Wait for ACK
    local message, senderID = protocol.receive(5)
    if message and message.type == protocol.MSG_TYPES.ACK then
        state.connected = true
        print("Successfully registered with coordinator!")
        return true
    else
        print("No acknowledgment received")
        state.connected = false
        return false
    end
end

-- ========== HEARTBEAT ==========

function client.sendHeartbeat()
    if not state.connected or not state.coordinatorId then
        -- Try to reconnect
        client.registerWithCoordinator()
        return
    end
    
    local data = protocol.buildHeartbeatMessage(
        state.status,
        state.position,
        turtle.getFuelLevel(),
        client.getInventoryCount(),
        state.currentProject
    )
    
    protocol.send(state.coordinatorId, protocol.MSG_TYPES.HEARTBEAT, data)
end

function client.heartbeatLoop()
    while true do
        client.sendHeartbeat()
        sleep(client.HEARTBEAT_INTERVAL)
    end
end

-- ========== MESSAGE HANDLING ==========

function client.handleMessage(message, senderID)
    local msgType = message.type
    
    if msgType == protocol.MSG_TYPES.PROJECT_ASSIGN then
        client.handleProjectAssignment(message.data)
        
    elseif msgType == protocol.MSG_TYPES.COORD_RESPONSE then
        client.handleCoordResponse(message.data)
        
    elseif msgType == protocol.MSG_TYPES.COMMAND then
        client.handleCommand(message.data)
        
    elseif msgType == protocol.MSG_TYPES.ACK then
        -- Acknowledgment received
        
    else
        print("Unknown message type: " .. msgType)
    end
end

function client.handleProjectAssignment(data)
    print("Received project assignment!")
    print("Project: " .. data.project.name)
    print("Zone: " .. data.assignment.zone)
    
    state.currentProject = data.projectId
    state.currentAssignment = data.assignment
    state.projectData = data.project
    
    -- Check if we should wait for start or begin immediately
    if data.waitForStart then
        state.status = "assigned"
        print("Waiting for start command...")
    else
        state.status = "working"
        print("Starting immediately...")
        os.queueEvent("project_start", data.projectId)
    end
    
    print("Instructions: " .. (data.assignment.instructions or "None"))
end

function client.handleCoordResponse(data)
    -- Update peer information
    state.peers = {}
    
    for _, turtleInfo in ipairs(data.turtles) do
        if turtleInfo.id ~= os.getComputerID() then
            table.insert(state.peers, turtleInfo)
        end
    end
    
    -- Debug: print peer count
    -- print("Updated peer info: " .. #state.peers .. " other turtles")
end

function client.handleCommand(data)
    local command = data.command
    
    if command == "register" then
        print("Coordinator requested re-registration")
        client.registerWithCoordinator()
        
    elseif command == "discover" then
        -- Respond to discovery broadcast
        if state.connected and state.coordinatorId then
            client.sendHeartbeat()
        else
            -- Try to register with the coordinator that sent discovery
            if data.coordinatorId then
                state.coordinatorId = data.coordinatorId
                client.registerWithCoordinator()
            end
        end
        
    elseif command == "unassign" or command == "unlink" then
        print("Unlinked from project")
        state.currentProject = nil
        state.currentAssignment = nil
        state.projectData = nil
        state.status = "idle"
        
    elseif command == "start" then
        -- Start working on assigned project
        if state.currentProject and state.currentAssignment then
            print("Starting work on project!")
            state.status = "working"
            -- Trigger mining start (will be handled by main loop)
            os.queueEvent("project_start", state.currentProject)
        else
            print("Cannot start - no project assigned")
        end
        
    elseif command == "stop" then
        print("Stop command received")
        state.status = "assigned"
        os.queueEvent("project_stop")
        
    elseif command == "return_home" then
        print("Return home command received")
        client.returnHome()
        
    elseif command == "pause" then
        print("Pause command received")
        state.status = "paused"
        os.queueEvent("project_pause")
        
    elseif command == "resume" then
        print("Resume command received")
        if state.currentProject then
            state.status = "working"
            os.queueEvent("project_resume")
        end
        
    else
        print("Unknown command: " .. command)
    end
end

function client.messageLoop()
    while true do
        local message, senderID = protocol.receive(1)
        
        if message then
            client.handleMessage(message, senderID)
        end
    end
end

-- ========== COORDINATION ==========

function client.requestCoordination()
    if not state.currentProject or not state.connected then
        return false
    end
    
    local data = protocol.buildCoordRequestMessage(state.currentProject)
    protocol.send(state.coordinatorId, protocol.MSG_TYPES.COORD_REQUEST, data, state.currentProject)
    
    return true
end

function client.getPeers()
    return state.peers
end

function client.getNearbyPeers(maxDistance)
    local nearby = {}
    
    for _, peer in ipairs(state.peers) do
        if peer.position then
            local dx = state.position.x - peer.position.x
            local dy = state.position.y - peer.position.y
            local dz = state.position.z - peer.position.z
            local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
            
            if distance <= maxDistance then
                table.insert(nearby, {
                    peer = peer,
                    distance = distance
                })
            end
        end
    end
    
    return nearby
end

-- ========== PROGRESS TRACKING ==========

function client.updateProgress(blocksCleared, oreFound, fuelUsed, distance)
    if blocksCleared then
        state.stats.blocksCleared = state.stats.blocksCleared + blocksCleared
    end
    
    if oreFound then
        state.stats.oreFound = state.stats.oreFound + oreFound
    end
    
    if fuelUsed then
        state.stats.fuelUsed = state.stats.fuelUsed + fuelUsed
    end
    
    if distance then
        state.stats.distance = state.stats.distance + distance
    end
end

function client.sendProgressUpdate()
    if not state.currentProject or not state.connected then
        return false
    end
    
    local data = protocol.buildProjectUpdateMessage(
        state.currentProject,
        {
            blocksCleared = state.stats.blocksCleared,
            oreFound = state.stats.oreFound,
            fuelUsed = state.stats.fuelUsed,
            distance = state.stats.distance
        },
        state.status
    )
    
    protocol.send(state.coordinatorId, protocol.MSG_TYPES.PROJECT_UPDATE, data, state.currentProject)
    
    return true
end

-- ========== STATUS ==========

function client.updateStatus(newStatus, extraData)
    state.status = newStatus
    
    if extraData then
        for key, value in pairs(extraData) do
            state[key] = value
        end
    end
    
    -- Send immediate heartbeat with new status
    client.sendHeartbeat()
end

function client.getStatus()
    return {
        initialized = state.initialized,
        connected = state.connected,
        coordinatorId = state.coordinatorId,
        status = state.status,
        currentProject = state.currentProject and state.projectData,
        assignment = state.currentAssignment,
        position = state.position,
        fuel = turtle.getFuelLevel(),
        inventory = client.getInventoryCount(),
        peers = state.peers,
        stats = state.stats
    }
end

-- ========== UTILITIES ==========

function client.getPosition()
    -- Try GPS first
    local x, y, z = gps.locate(2)
    
    if x then
        return {x = math.floor(x), y = math.floor(y), z = math.floor(z)}
    else
        -- Return current position or default
        return state.position or {x = 0, y = 0, z = 0}
    end
end

function client.updatePosition()
    state.position = client.getPosition()
    return state.position
end

function client.getInventoryCount()
    local count = 0
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            count = count + 1
        end
    end
    return count
end

function client.returnHome()
    state.status = "returning"
    
    -- This is a placeholder - actual pathfinding would go here
    print("Returning to start position...")
    print(string.format("Target: X:%d Y:%d Z:%d", 
        state.startPosition.x, state.startPosition.y, state.startPosition.z))
    
    -- Update status when done
    state.status = "idle"
end

-- ========== BACKGROUND SERVICE ==========

function client.startBackgroundService()
    if not state.initialized then
        error("Client not initialized! Call client.init() first")
    end
    
    print("Starting background service...")
    
    -- Run heartbeat and message loops in parallel
    parallel.waitForAny(
        function() client.heartbeatLoop() end,
        function() client.messageLoop() end
    )
end

-- ========== INTEGRATION HELPERS ==========

function client.isAssignedToProject()
    return state.currentProject ~= nil
end

function client.getProjectAssignment()
    return state.currentAssignment
end

function client.canStartWork()
    return state.connected and state.currentProject and state.status == "assigned"
end

function client.getInstructions()
    if state.currentAssignment then
        return state.currentAssignment.instructions
    end
    return nil
end

return client

