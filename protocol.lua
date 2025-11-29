-- Protocol System for Rednet Communication
-- Handles message structure, validation, and transmission

local protocol = {}

-- Protocol configuration
protocol.PROTOCOL_NAME = "ccmine_coord"
protocol.PROTOCOL_VERSION = "1.0"

-- Message types
protocol.MSG_TYPES = {
    REGISTER = "REGISTER",
    HEARTBEAT = "HEARTBEAT",
    PROJECT_ASSIGN = "PROJECT_ASSIGN",
    PROJECT_UPDATE = "PROJECT_UPDATE",
    COORD_REQUEST = "COORD_REQUEST",
    COORD_RESPONSE = "COORD_RESPONSE",
    COMMAND = "COMMAND",
    ACK = "ACK"
}

-- Internal state
local state = {
    initialized = false,
    modemSide = nil,
    computerID = nil,
    hostname = nil
}

-- ========== INITIALIZATION ==========

function protocol.init(hostname)
    if state.initialized then
        return true
    end
    
    -- Find wireless modem
    local modem = peripheral.find("modem", function(name, wrapped)
        return wrapped.isWireless()
    end)
    
    if not modem then
        error("No wireless modem found!")
        return false
    end
    
    state.modemSide = peripheral.getName(modem)
    state.computerID = os.getComputerID()
    state.hostname = hostname or ("computer_" .. state.computerID)
    
    -- Open rednet
    rednet.open(state.modemSide)
    
    -- Host the protocol
    rednet.host(protocol.PROTOCOL_NAME, state.hostname)
    
    state.initialized = true
    return true
end

function protocol.close()
    if not state.initialized then
        return
    end
    
    rednet.unhost(protocol.PROTOCOL_NAME)
    rednet.close(state.modemSide)
    state.initialized = false
end

function protocol.isInitialized()
    return state.initialized
end

-- ========== MESSAGE CREATION ==========

function protocol.createMessage(messageType, data, projectId)
    if not protocol.MSG_TYPES[messageType] then
        error("Invalid message type: " .. tostring(messageType))
    end
    
    return {
        type = messageType,
        from = state.computerID,
        to = nil, -- Will be set by send/broadcast
        projectId = projectId,
        timestamp = os.epoch("utc"),
        version = protocol.PROTOCOL_VERSION,
        data = data or {}
    }
end

function protocol.validateMessage(message)
    if type(message) ~= "table" then
        return false, "Message is not a table"
    end
    
    if not message.type or not protocol.MSG_TYPES[message.type] then
        return false, "Invalid or missing message type"
    end
    
    if not message.from then
        return false, "Missing sender ID"
    end
    
    if not message.timestamp then
        return false, "Missing timestamp"
    end
    
    if not message.version then
        return false, "Missing protocol version"
    end
    
    -- Check version compatibility
    if message.version ~= protocol.PROTOCOL_VERSION then
        return false, "Protocol version mismatch"
    end
    
    return true
end

-- ========== MESSAGE TRANSMISSION ==========

function protocol.send(recipient, messageType, data, projectId)
    if not state.initialized then
        error("Protocol not initialized! Call protocol.init() first")
    end
    
    local message = protocol.createMessage(messageType, data, projectId)
    message.to = recipient
    
    rednet.send(recipient, message, protocol.PROTOCOL_NAME)
    return true
end

function protocol.broadcast(messageType, data, projectId)
    if not state.initialized then
        error("Protocol not initialized! Call protocol.init() first")
    end
    
    local message = protocol.createMessage(messageType, data, projectId)
    message.to = "broadcast"
    
    rednet.broadcast(message, protocol.PROTOCOL_NAME)
    return true
end

function protocol.receive(timeout)
    if not state.initialized then
        error("Protocol not initialized! Call protocol.init() first")
    end
    
    local senderID, message, protocolName = rednet.receive(protocol.PROTOCOL_NAME, timeout)
    
    if not senderID then
        return nil -- Timeout
    end
    
    -- Validate message structure
    local valid, error = protocol.validateMessage(message)
    if not valid then
        print("Invalid message received: " .. error)
        return nil
    end
    
    -- Ignore messages from self
    if senderID == state.computerID then
        return nil
    end
    
    return message, senderID
end

-- ========== HELPER FUNCTIONS ==========

function protocol.sendAck(recipient, originalMessage)
    return protocol.send(recipient, protocol.MSG_TYPES.ACK, {
        ackFor = originalMessage.type,
        ackTimestamp = originalMessage.timestamp
    }, originalMessage.projectId)
end

function protocol.findCoordinator()
    if not state.initialized then
        error("Protocol not initialized! Call protocol.init() first")
    end
    
    local coordinatorID = rednet.lookup(protocol.PROTOCOL_NAME, "coordinator")
    return coordinatorID
end

function protocol.getState()
    return {
        initialized = state.initialized,
        modemSide = state.modemSide,
        computerID = state.computerID,
        hostname = state.hostname
    }
end

-- ========== MESSAGE BUILDERS ==========
-- Convenience functions for common message types

function protocol.buildRegisterMessage(capabilities)
    return {
        id = state.computerID,
        label = os.getComputerLabel() or ("Turtle-" .. state.computerID),
        capabilities = capabilities or {},
        position = capabilities and capabilities.position or {x = 0, y = 0, z = 0},
        fuel = capabilities and capabilities.fuel or 0,
        inventory = capabilities and capabilities.inventory or 0
    }
end

function protocol.buildHeartbeatMessage(status, position, fuel, inventory, currentProject)
    return {
        id = state.computerID,
        status = status or "idle",
        position = position or {x = 0, y = 0, z = 0},
        fuel = fuel or 0,
        inventory = inventory or 0,
        currentProject = currentProject
    }
end

function protocol.buildProjectUpdateMessage(projectId, progress, status)
    return {
        turtleId = state.computerID,
        projectId = projectId,
        progress = progress,
        status = status
    }
end

function protocol.buildCoordRequestMessage(projectId)
    return {
        turtleId = state.computerID,
        projectId = projectId
    }
end

-- ========== UTILITY ==========

function protocol.generateUUID()
    local random = math.random
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
        return string.format("%x", v)
    end)
end

return protocol

