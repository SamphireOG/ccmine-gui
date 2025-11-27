-- CCMine GUI Framework - Data Persistence
-- Simple file-based storage for application data

local data = {}

-- ========== FILE OPERATIONS ==========

function data.save(filename, dataTable)
    -- Save a Lua table to a file
    local file = fs.open(filename, "w")
    if file then
        file.write(textutils.serialize(dataTable))
        file.close()
        return true
    end
    return false
end

function data.load(filename)
    -- Load a Lua table from a file
    if not fs.exists(filename) then
        return nil
    end
    
    local file = fs.open(filename, "r")
    if not file then
        return nil
    end
    
    local content = file.readAll()
    file.close()
    
    return textutils.unserialize(content)
end

function data.delete(filename)
    -- Delete a file
    if fs.exists(filename) then
        fs.delete(filename)
        return true
    end
    return false
end

function data.exists(filename)
    -- Check if a file exists
    return fs.exists(filename)
end

-- ========== COLLECTION MANAGEMENT ==========

function data.listByPattern(pattern)
    -- List all files matching a pattern (e.g., "project_*.cfg")
    local results = {}
    for _, file in ipairs(fs.list("/")) do
        if file:match(pattern) then
            table.insert(results, file)
        end
    end
    return results
end

function data.extractName(filename, prefix, suffix)
    -- Extract name from pattern (e.g., "project_name.cfg" -> "name")
    local pattern = "^" .. prefix .. "(.+)" .. suffix .. "$"
    return filename:match(pattern)
end

-- ========== CONFIG HELPERS ==========

function data.saveConfig(name, configTable, prefix, suffix)
    -- Save config with standard naming: prefix + name + suffix
    prefix = prefix or "config_"
    suffix = suffix or ".cfg"
    local filename = prefix .. name .. suffix
    return data.save(filename, configTable)
end

function data.loadConfig(name, prefix, suffix)
    -- Load config by name
    prefix = prefix or "config_"
    suffix = suffix or ".cfg"
    local filename = prefix .. name .. suffix
    return data.load(filename)
end

function data.deleteConfig(name, prefix, suffix)
    -- Delete config by name
    prefix = prefix or "config_"
    suffix = suffix or ".cfg"
    local filename = prefix .. name .. suffix
    return data.delete(filename)
end

function data.listConfigs(prefix, suffix)
    -- List all config names
    prefix = prefix or "config_"
    suffix = suffix or ".cfg"
    
    local files = data.listByPattern("^" .. prefix .. ".+" .. suffix .. "$")
    local names = {}
    
    for _, file in ipairs(files) do
        local name = data.extractName(file, prefix, suffix)
        if name then
            table.insert(names, name)
        end
    end
    
    return names
end

return data

