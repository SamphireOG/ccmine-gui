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
    
    -- Create Project button (smaller and more compact)
    local createBtn = components.createButton("create", 2, 3, 12, 2, "Create +", function()
        gui.setScreen(dashboard.createProjectScreen)
    end)
    createBtn.bgColor = gui.getColor("success")
    
    -- Project List Panel
    local panelH = screenH - 6
    local panel = components.createPanel("projects", 2, 6, screenW - 4, panelH, "Projects")
    panel.borderColor = gui.getColor("border")
    
    -- Load and display projects
    local projects = listProjects()
    
    if #projects == 0 then
        -- No projects message (constrain to panel width)
        local maxLabelWidth = screenW - 10  -- Account for margins and border
        
        local noProjectsLbl = components.createLabel("noprojects", 4, 8, "No projects yet.")
        noProjectsLbl.width = maxLabelWidth
        noProjectsLbl.fgColor = gui.getColor("disabled")
        
        local hintLbl = components.createLabel("hint", 4, 9, "Press 'Create +' above")
        hintLbl.width = maxLabelWidth
        hintLbl.fgColor = gui.getColor("disabled")
    else
        -- Display projects as list items with delete buttons (more compact)
        local startY = 8
        for i, projectName in ipairs(projects) do
            local itemY = startY + ((i - 1) * 1)  -- Single line spacing
            
            if itemY < screenH - 2 then  -- Check if it fits on screen
                -- Project name button (opens project) - height 1
                local projectBtn = components.createButton(
                    "proj_" .. i,
                    4,
                    itemY,
                    screenW - 11,
                    1,
                    projectName,
                    function()
                        dashboard.openProject(projectName)
                    end
                )
                
                -- Delete button (X) - height 1, width 3
                local deleteBtn = components.createButton(
                    "del_" .. i,
                    screenW - 6,
                    itemY,
                    3,
                    1,
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
    nameLbl.zIndex = 10
    panel:addChild(nameLbl)
    
    local nameInput = components.createTextInput("name", formX, formY + 1, screenW - 11, "Enter name...")
    nameInput.parent = panel
    nameInput.zIndex = 10
    panel:addChild(nameInput)
    
    local mainLbl = components.createLabel("mainlbl", formX, formY + 3, "Main Tunnel L:")
    mainLbl.parent = panel
    mainLbl.zIndex = 10
    panel:addChild(mainLbl)
    
    local mainTunnelInput = components.createTextInput("main", formX, formY + 4, inputW, "64")
    mainTunnelInput.value = "64"
    mainTunnelInput.parent = panel
    mainTunnelInput.zIndex = 10
    panel:addChild(mainTunnelInput)
    
    local sideLbl = components.createLabel("sidelbl", formX, formY + 6, "Side Tunnel L:")
    sideLbl.parent = panel
    sideLbl.zIndex = 10
    panel:addChild(sideLbl)
    
    local sideTunnelInput = components.createTextInput("side", formX, formY + 7, inputW, "32")
    sideTunnelInput.value = "32"
    sideTunnelInput.parent = panel
    sideTunnelInput.zIndex = 10
    panel:addChild(sideTunnelInput)
    
    local startLbl = components.createLabel("startlbl", formX, formY + 9, "Starting Y:")
    startLbl.parent = panel
    startLbl.zIndex = 10
    panel:addChild(startLbl)
    
    local startYInput = components.createTextInput("starty", formX, formY + 10, inputW, "11")
    startYInput.value = "11"
    startYInput.parent = panel
    startYInput.zIndex = 10
    panel:addChild(startYInput)
    
    local endLbl = components.createLabel("endlbl", formX, formY + 12, "Ending Y:")
    endLbl.parent = panel
    endLbl.zIndex = 10
    panel:addChild(endLbl)
    
    local endYInput = components.createTextInput("endy", formX, formY + 13, inputW, "64")
    endYInput.value = "64"
    endYInput.parent = panel
    endYInput.zIndex = 10
    panel:addChild(endYInput)
    
    -- Options
    local torchCheck = components.createCheckbox("torches", formX, formY + 15, "Place torches", true)
    torchCheck.parent = panel
    torchCheck.zIndex = 10
    panel:addChild(torchCheck)
    
    local wallCheck = components.createCheckbox("walls", formX, formY + 16, "Wall protection", true)
    wallCheck.parent = panel
    wallCheck.zIndex = 10
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

-- ========== PROJECT CONTROL SCREEN ==========

function dashboard.openProject(projectName)
    local project = loadProject(projectName)
    
    if not project then
        gui.notify("Failed to load project!", colors.white, colors.red, 3)
        gui.setScreen(dashboard.mainScreen)
        return
    end
    
    -- Initialize turtles list if not exists
    if not project.turtles then
        project.turtles = {}
    end
    
    -- Title bar
    gui.screen.term.setBackgroundColor(gui.getColor("primary"))
    gui.screen.term.setTextColor(colors.white)
    gui.screen.term.setCursorPos(1, 1)
    gui.screen.term.clearLine()
    gui.centerText(projectName, 1)
    
    -- Settings button (top-right)
    local settingsBtn = components.createButton("settings", screenW - 12, 3, 11, 1, "Settings", function()
        dashboard.openProjectSettings(projectName, project)
    end)
    
    -- Link Turtle button
    local linkBtn = components.createButton("link", 2, 3, 12, 1, "Link Turtle", function()
        dashboard.linkTurtleDialog(projectName, project)
    end)
    linkBtn.bgColor = gui.getColor("success")
    
    -- Scrollable Turtle List Panel
    local panelH = screenH - 6
    local panel = components.createPanel("turtles", 2, 5, screenW - 4, panelH, "Linked Turtles")
    panel.borderColor = gui.getColor("border")
    panel.scrollable = true
    
    -- Display linked turtles
    if #project.turtles == 0 then
        local noTurtlesLbl = components.createLabel("noturtles", 2, 2, "No turtles linked yet")
        noTurtlesLbl.parent = panel
        noTurtlesLbl.fgColor = gui.getColor("disabled")
        noTurtlesLbl.zIndex = 10
        panel:addChild(noTurtlesLbl)
        
        local hintLbl = components.createLabel("hint", 2, 3, "Press 'Link Turtle' above")
        hintLbl.parent = panel
        hintLbl.fgColor = gui.getColor("disabled")
        hintLbl.zIndex = 10
        panel:addChild(hintLbl)
    else
        -- Display each turtle with its info
        local formY = 2
        for i, turtle in ipairs(project.turtles) do
            local turtleY = formY + ((i - 1) * 5)  -- 5 lines per turtle
            
            -- Turtle ID/Name
            local nameLbl = components.createLabel("turtle_name_" .. i, 2, turtleY, "ID: " .. (turtle.id or "???"))
            nameLbl.parent = panel
            nameLbl.fgColor = gui.getColor("primary")
            nameLbl.zIndex = 10
            panel:addChild(nameLbl)
            
            -- Status
            local statusColor = turtle.status == "active" and gui.getColor("success") or gui.getColor("disabled")
            local statusLbl = components.createLabel("turtle_status_" .. i, 2, turtleY + 1, "Status: " .. (turtle.status or "idle"))
            statusLbl.parent = panel
            statusLbl.fgColor = statusColor
            statusLbl.zIndex = 10
            panel:addChild(statusLbl)
            
            -- Fuel
            local fuelLbl = components.createLabel("turtle_fuel_" .. i, 2, turtleY + 2, "Fuel: " .. (turtle.fuel or "0"))
            fuelLbl.parent = panel
            fuelLbl.zIndex = 10
            panel:addChild(fuelLbl)
            
            -- Position
            local posLbl = components.createLabel("turtle_pos_" .. i, 2, turtleY + 3, "Pos: " .. (turtle.x or "?") .. "," .. (turtle.y or "?") .. "," .. (turtle.z or "?"))
            posLbl.parent = panel
            posLbl.zIndex = 10
            panel:addChild(posLbl)
            
            -- Unlink button
            local unlinkBtn = components.createButton("unlink_" .. i, screenW - 12, turtleY, 8, 1, "Unlink", function()
                dashboard.unlinkTurtle(projectName, project, i)
            end)
            unlinkBtn.parent = panel
            unlinkBtn.bgColor = gui.getColor("error")
            unlinkBtn.zIndex = 10
            panel:addChild(unlinkBtn)
        end
    end
    
    -- Back button (bottom)
    local backBtn = components.createButton("back", 2, screenH - 1, 10, 1, "Back", function()
        gui.setScreen(dashboard.mainScreen)
    end)
end

-- ========== PROJECT SETTINGS SCREEN ==========

function dashboard.openProjectSettings(projectName, project)
    gui.notify("Project settings coming soon!", colors.white, colors.orange, 2)
    -- TODO: Create settings screen with editable project parameters
    gui.setScreen(function() dashboard.openProject(projectName) end)
end

-- ========== LINK TURTLE DIALOG ==========

function dashboard.linkTurtleDialog(projectName, project)
    dialogs.prompt(
        "Link Turtle",
        "Enter Turtle ID:",
        "",
        function(turtleId)
            -- Confirm callback
            if turtleId and #turtleId > 0 then
                -- Add turtle to project
                table.insert(project.turtles, {
                    id = turtleId,
                    status = "idle",
                    fuel = 0,
                    x = 0,
                    y = 0,
                    z = 0,
                    linkedAt = os.epoch("utc")
                })
                
                if saveProject(projectName, project) then
                    gui.notify("Turtle " .. turtleId .. " linked!", colors.white, colors.green, 2)
                    gui.setScreen(function() dashboard.openProject(projectName) end)
                else
                    gui.notify("Failed to save project!", colors.white, colors.red, 3)
                end
            else
                gui.notify("Invalid Turtle ID", colors.white, colors.red, 2)
                gui.setScreen(function() dashboard.openProject(projectName) end)
            end
        end,
        function()
            -- Cancel callback
            gui.setScreen(function() dashboard.openProject(projectName) end)
        end
    )
end

-- ========== UNLINK TURTLE ==========

function dashboard.unlinkTurtle(projectName, project, turtleIndex)
    local turtle = project.turtles[turtleIndex]
    if not turtle then return end
    
    dialogs.confirm(
        "Unlink Turtle",
        "Unlink turtle '" .. turtle.id .. "'?",
        function()
            -- Yes callback
            table.remove(project.turtles, turtleIndex)
            if saveProject(projectName, project) then
                gui.notify("Turtle unlinked", colors.white, colors.orange, 2)
                gui.setScreen(function() dashboard.openProject(projectName) end)
            else
                gui.notify("Failed to save!", colors.white, colors.red, 3)
            end
        end,
        function()
            -- No callback
            gui.setScreen(function() dashboard.openProject(projectName) end)
        end
    )
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

