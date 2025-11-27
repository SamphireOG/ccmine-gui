-- CCMine Dashboard - Project Management GUI
-- Main interface for creating and managing mining projects

local gui = require("gui-core")
local components = require("gui-components")
local layouts = require("gui-layouts")
local dialogs = require("gui-dialogs")
local data = require("gui-data")

local dashboard = {}

-- Get screen dimensions
local screenW, screenH = gui.init()

-- ========== PROJECT STORAGE (using framework helpers) ==========

local function listProjects()
    return data.listConfigs("project_", ".cfg")
end

local function loadProject(projectName)
    return data.loadConfig(projectName, "project_", ".cfg")
end

local function saveProject(projectName, projectData)
    return data.saveConfig(projectName, projectData, "project_", ".cfg")
end

local function deleteProject(projectName)
    return data.deleteConfig(projectName, "project_", ".cfg")
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
        -- No projects message (constrain to panel width)
        local maxLabelWidth = screenW - 10  -- Account for margins and border
        
        local noProjectsLbl = components.createLabel("noprojects", 4, 9, "No projects yet.")
        noProjectsLbl.width = maxLabelWidth
        noProjectsLbl.fgColor = gui.getColor("disabled")
        
        local hintLbl = components.createLabel("hint", 4, 10, "Press 'Create +' above")
        hintLbl.width = maxLabelWidth
        hintLbl.fgColor = gui.getColor("disabled")
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
    
    -- Scrollable Form Panel
    local panelH = screenH - 6
    local panel = components.createPanel("form", 3, 3, screenW - 5, panelH, "Project Details")
    panel.borderColor = gui.getColor("border")
    panel.scrollable = true
    
    -- Form fields - relative to panel interior (panel.x + 2, panel.y + 2)
    local formX = 2  -- Relative to panel
    local formY = 2  -- Start below title
    local inputW = 12
    
    local nameLbl = components.createLabel("namelbl", formX, formY, "Project Name:")
    nameLbl.parent = panel
    panel:addChild(nameLbl)
    
    local nameInput = components.createTextInput("name", formX, formY + 1, screenW - 11, "Enter name...")
    nameInput.parent = panel
    panel:addChild(nameInput)
    
    local mainLbl = components.createLabel("mainlbl", formX, formY + 3, "Main Tunnel L:")
    mainLbl.parent = panel
    panel:addChild(mainLbl)
    
    local mainTunnelInput = components.createTextInput("main", formX, formY + 4, inputW, "64")
    mainTunnelInput.value = "64"
    mainTunnelInput.parent = panel
    panel:addChild(mainTunnelInput)
    
    local sideLbl = components.createLabel("sidelbl", formX, formY + 6, "Side Tunnel L:")
    sideLbl.parent = panel
    panel:addChild(sideLbl)
    
    local sideTunnelInput = components.createTextInput("side", formX, formY + 7, inputW, "32")
    sideTunnelInput.value = "32"
    sideTunnelInput.parent = panel
    panel:addChild(sideTunnelInput)
    
    local startLbl = components.createLabel("startlbl", formX, formY + 9, "Starting Y:")
    startLbl.parent = panel
    panel:addChild(startLbl)
    
    local startYInput = components.createTextInput("starty", formX, formY + 10, inputW, "11")
    startYInput.value = "11"
    startYInput.parent = panel
    panel:addChild(startYInput)
    
    local endLbl = components.createLabel("endlbl", formX, formY + 12, "Ending Y:")
    endLbl.parent = panel
    panel:addChild(endLbl)
    
    local endYInput = components.createTextInput("endy", formX, formY + 13, inputW, "64")
    endYInput.value = "64"
    endYInput.parent = panel
    panel:addChild(endYInput)
    
    -- Options
    local torchCheck = components.createCheckbox("torches", formX, formY + 15, "Place torches", true)
    torchCheck.parent = panel
    panel:addChild(torchCheck)
    
    local wallCheck = components.createCheckbox("walls", formX, formY + 16, "Wall protection", true)
    wallCheck.parent = panel
    panel:addChild(wallCheck)
    
    -- Buttons (at absolute bottom of screen, outside panel)
    local btnW = math.floor((screenW - 10) / 2)
    local createBtn = components.createButton("create", 3, screenH - 2, btnW, 2, "Create", function()
        local name = nameInput.value
        
        if not name or #name == 0 then
            gui.notify("Please enter a project name!", colors.white, colors.red, 3)
            return
        end
        
        -- Check if project already exists
        if data.exists("project_" .. name .. ".cfg") then
            gui.notify("Project already exists!", colors.white, colors.red, 3)
            return
        end
        
        -- Create project
        local projectData = {
            name = name,
            mainTunnelLength = tonumber(mainTunnelInput.value) or 64,
            sideTunnelLength = tonumber(sideTunnelInput.value) or 32,
            startY = tonumber(startYInput.value) or 11,
            endY = tonumber(endYInput.value) or 64,
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
    
    local cancelBtn = components.createButton("cancel", screenW - btnW - 2, screenH - 2, btnW, 2, "Cancel", function()
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
    
    -- Project Info Panel (taller to fit all fields)
    local panel = components.createPanel("info", 3, 3, screenW - 5, 12, "Project Info")
    panel.borderColor = gui.getColor("border")
    
    -- Display project details
    local mainLbl = components.createLabel("main", 5, 5, "Main Tunnel: " .. (project.mainTunnelLength or 64))
    local sideLbl = components.createLabel("side", 5, 6, "Side Tunnel: " .. (project.sideTunnelLength or 32))
    local startLbl = components.createLabel("start", 5, 7, "Start Y: " .. (project.startY or 11))
    local endLbl = components.createLabel("end", 5, 8, "End Y: " .. (project.endY or 64))
    local channelLbl = components.createLabel("channel", 5, 9, "Channel: " .. (project.channel or 101))
    local torchLbl = components.createLabel("torch", 5, 10, "Torches: " .. (project.placeTorches and "Yes" or "No"))
    local wallLbl = components.createLabel("wall", 5, 11, "Wall Protect: " .. (project.wallProtection and "Yes" or "No"))
    
    -- Action Buttons
    local startBtn = components.createButton("start", 3, 16, screenW - 5, 3, "Start Mining", function()
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

-- ========== DELETE CONFIRMATION (using framework dialog) ==========

function dashboard.confirmDelete(projectName)
    dialogs.confirm(
        "Confirm Delete",
        "Delete project '" .. projectName .. "'? This cannot be undone!",
        function()
            -- Yes callback
            if deleteProject(projectName) then
                gui.notify("Project deleted: " .. projectName, colors.white, colors.orange, 2)
                gui.setScreen(dashboard.mainScreen)
            else
                gui.notify("Failed to delete project!", colors.white, colors.red, 3)
            end
        end,
        function()
            -- No callback
            gui.setScreen(dashboard.mainScreen)
        end
    )
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

