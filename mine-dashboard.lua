-- CCMine Dashboard - Project Management GUI
-- Main interface for creating and managing mining projects

local gui = require("gui-core")
local components = require("gui-components")

local dashboard = {}

-- Get screen dimensions
local screenW, screenH = gui.init()

-- ========== PROJECT STORAGE ==========

local function getProjectFilename(projectName)
    return "project_" .. projectName .. ".cfg"
end

local function listProjects()
    local projects = {}
    for _, file in ipairs(fs.list("/")) do
        if file:match("^project_(.+)%.cfg$") then
            local name = file:match("^project_(.+)%.cfg$")
            table.insert(projects, name)
        end
    end
    return projects
end

local function loadProject(projectName)
    local filename = getProjectFilename(projectName)
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

local function saveProject(projectName, data)
    local filename = getProjectFilename(projectName)
    local file = fs.open(filename, "w")
    if file then
        file.write(textutils.serialize(data))
        file.close()
        return true
    end
    return false
end

local function deleteProject(projectName)
    local filename = getProjectFilename(projectName)
    if fs.exists(filename) then
        fs.delete(filename)
        return true
    end
    return false
end

-- ========== MAIN DASHBOARD SCREEN ==========

function dashboard.mainScreen()
    -- Title bar
    gui.screen.term.setBackgroundColor(gui.getColor("primary"))
    gui.screen.term.setTextColor(colors.white)
    gui.screen.term.setCursorPos(1, 1)
    gui.screen.term.clearLine()
    gui.centerText("Mine Dashboard", 1)
    
    -- Create Project button
    local createBtn = components.createButton("create", 2, 3, 15, 3, "Create +", function()
        gui.setScreen(dashboard.createProjectScreen)
    end)
    createBtn.bgColor = gui.getColor("success")
    
    -- Project List Panel
    local panelH = screenH - 7
    local panel = components.createPanel("projects", 2, 7, screenW - 4, panelH, "Projects")
    panel.borderColor = gui.getColor("border")
    
    -- Load and display projects
    local projects = listProjects()
    
    if #projects == 0 then
        -- No projects message
        local noProjectsLbl = components.createLabel("noprojects", 4, 9, "No projects yet. Create one to get started!")
        noProjectsLbl.fgColor = gui.getColor("disabled")
    else
        -- Display projects as list items with delete buttons
        local startY = 9
        for i, projectName in ipairs(projects) do
            local itemY = startY + ((i - 1) * 2)
            
            if itemY + 1 < screenH - 2 then  -- Check if it fits on screen
                -- Project name button (opens project)
                local projectBtn = components.createButton(
                    "proj_" .. i,
                    4,
                    itemY,
                    screenW - 12,
                    2,
                    projectName,
                    function()
                        dashboard.openProject(projectName)
                    end
                )
                
                -- Delete button (X)
                local deleteBtn = components.createButton(
                    "del_" .. i,
                    screenW - 7,
                    itemY,
                    4,
                    2,
                    "X",
                    function()
                        dashboard.confirmDelete(projectName)
                    end
                )
                deleteBtn.bgColor = gui.getColor("error")
            end
        end
        
        -- Show count if more projects exist
        if #projects > (panelH - 3) / 2 then
            local moreLbl = components.createLabel("more", 4, screenH - 3, 
                "+" .. (#projects - math.floor((panelH - 3) / 2)) .. " more (scroll to see)")
            moreLbl.fgColor = gui.getColor("disabled")
        end
    end
end

-- ========== CREATE PROJECT SCREEN ==========

function dashboard.createProjectScreen()
    -- Title
    gui.centerText("Create New Project", 1, gui.getColor("primary"), colors.white)
    
    -- Form Panel
    local panel = components.createPanel("form", 3, 3, screenW - 5, screenH - 6, "Project Details")
    panel.borderColor = gui.getColor("border")
    
    -- Project Name Input
    local nameLbl = components.createLabel("namelbl", 5, 5, "Project Name:")
    local nameInput = components.createTextInput("name", 5, 6, screenW - 11, "Enter project name...")
    
    -- Tunnel Length Input
    local lengthLbl = components.createLabel("lengthlbl", 5, 8, "Tunnel Length:")
    local lengthInput = components.createTextInput("length", 5, 9, 15, "32")
    lengthInput.value = "32"
    
    -- Tunnel Spacing Input
    local spacingLbl = components.createLabel("spacinglbl", 25, 8, "Spacing:")
    local spacingInput = components.createTextInput("spacing", 25, 9, 10, "4")
    spacingInput.value = "4"
    
    -- Options
    local torchCheck = components.createCheckbox("torches", 5, 11, "Place torches", true)
    local wallCheck = components.createCheckbox("walls", 5, 12, "Wall protection", true)
    
    -- Buttons
    local btnW = math.floor((screenW - 10) / 2)
    local createBtn = components.createButton("create", 3, screenH - 3, btnW, 2, "Create", function()
        local name = nameInput.value
        
        if not name or #name == 0 then
            gui.notify("Please enter a project name!", colors.white, colors.red, 3)
            return
        end
        
        -- Check if project already exists
        if fs.exists(getProjectFilename(name)) then
            gui.notify("Project already exists!", colors.white, colors.red, 3)
            return
        end
        
        -- Create project
        local projectData = {
            name = name,
            tunnelLength = tonumber(lengthInput.value) or 32,
            spacing = tonumber(spacingInput.value) or 4,
            placeTorches = torchCheck.checked,
            wallProtection = wallCheck.checked,
            created = os.epoch("utc"),
            channel = 100 + #listProjects() + 1  -- Unique channel
        }
        
        if saveProject(name, projectData) then
            gui.notify("Project created: " .. name, colors.white, colors.green, 2)
            gui.setScreen(dashboard.mainScreen)
        else
            gui.notify("Failed to create project!", colors.white, colors.red, 3)
        end
    end)
    createBtn.bgColor = gui.getColor("success")
    
    local cancelBtn = components.createButton("cancel", screenW - btnW - 2, screenH - 3, btnW, 2, "Cancel", function()
        gui.setScreen(dashboard.mainScreen)
    end)
end

-- ========== PROJECT DETAIL SCREEN ==========

function dashboard.openProject(projectName)
    local project = loadProject(projectName)
    
    if not project then
        gui.notify("Failed to load project!", colors.white, colors.red, 3)
        gui.setScreen(dashboard.mainScreen)
        return
    end
    
    -- Title
    gui.centerText(projectName, 1, gui.getColor("primary"), colors.white)
    
    -- Project Info Panel
    local panel = components.createPanel("info", 3, 3, screenW - 5, 10, "Project Info")
    panel.borderColor = gui.getColor("border")
    
    -- Display project details
    local tunnelLbl = components.createLabel("tunnel", 5, 5, "Tunnel Length: " .. (project.tunnelLength or 32))
    local spacingLbl = components.createLabel("spacing", 5, 6, "Spacing: " .. (project.spacing or 4))
    local channelLbl = components.createLabel("channel", 5, 7, "Channel: " .. (project.channel or 101))
    local torchLbl = components.createLabel("torch", 5, 8, "Torches: " .. (project.placeTorches and "Yes" or "No"))
    local wallLbl = components.createLabel("wall", 5, 9, "Wall Protection: " .. (project.wallProtection and "Yes" or "No"))
    
    -- Action Buttons
    local startBtn = components.createButton("start", 3, 14, screenW - 5, 3, "Start Mining", function()
        gui.notify("Mining system not yet implemented", colors.black, colors.yellow, 3)
        -- TODO: Launch mining coordinator
    end)
    startBtn.bgColor = gui.getColor("success")
    
    local editBtn = components.createButton("edit", 3, screenH - 5, 15, 2, "Edit", function()
        gui.notify("Edit not yet implemented", colors.black, colors.yellow, 2)
        -- TODO: Edit project screen
    end)
    
    local backBtn = components.createButton("back", screenW - 17, screenH - 5, 15, 2, "Back", function()
        gui.setScreen(dashboard.mainScreen)
    end)
end

-- ========== DELETE CONFIRMATION ==========

function dashboard.confirmDelete(projectName)
    -- Create a modal-style delete confirmation
    gui.clearComponents()
    
    -- Dim background effect (draw a panel)
    local confirmPanel = components.createPanel("confirm", 
        math.floor(screenW / 4), 
        math.floor(screenH / 3), 
        math.floor(screenW / 2), 
        8, 
        "Confirm Delete")
    confirmPanel.borderColor = gui.getColor("error")
    
    local msgLbl = components.createLabel("msg", 
        math.floor(screenW / 4) + 2, 
        math.floor(screenH / 3) + 2, 
        "Delete project:")
    
    local nameLbl = components.createLabel("projname", 
        math.floor(screenW / 4) + 2, 
        math.floor(screenH / 3) + 3, 
        projectName)
    nameLbl.fgColor = gui.getColor("error")
    
    local warnLbl = components.createLabel("warn",
        math.floor(screenW / 4) + 2,
        math.floor(screenH / 3) + 5,
        "This cannot be undone!")
    warnLbl.fgColor = gui.getColor("warning")
    
    -- Buttons
    local btnW = math.floor(screenW / 2 / 2) - 2
    local yesBtn = components.createButton("yes", 
        math.floor(screenW / 4) + 1, 
        math.floor(screenH / 3) + 6, 
        btnW, 
        2, 
        "Delete", 
        function()
            if deleteProject(projectName) then
                gui.notify("Project deleted: " .. projectName, colors.white, colors.orange, 2)
                gui.setScreen(dashboard.mainScreen)
            else
                gui.notify("Failed to delete project!", colors.white, colors.red, 3)
            end
        end)
    yesBtn.bgColor = gui.getColor("error")
    
    local noBtn = components.createButton("no", 
        math.floor(screenW / 4) + btnW + 2, 
        math.floor(screenH / 3) + 6, 
        btnW, 
        2, 
        "Cancel", 
        function()
            gui.setScreen(dashboard.mainScreen)
        end)
end

-- ========== RUN DASHBOARD ==========

function dashboard.run()
    -- Use framework's built-in event loop
    gui.runApp(dashboard.mainScreen)
end

-- Auto-run if executed directly
if not ... then
    dashboard.run()
end

return dashboard

