-- CCMine Control Center - Unified Fleet & Project Management
-- Complete interface for managing turtles, creating projects, and coordinating mining operations

local gui = require("gui-core")
local components = require("gui-components")
local layouts = require("gui-layouts")
local dialogs = require("gui-dialogs")
local data = require("gui-data")
local coordinator = require("coordinator")
local projectManager = require("project-manager")
local zoneAllocator = require("zone-allocator")

local control = {}

-- ========== STATE ==========

control.state = {
    currentScreen = "dashboard",
    selectedTurtle = nil,
    selectedProject = nil,
    coordinatorRunning = false
}

-- ========== PROJECT DATA PERSISTENCE ==========

local function listSavedProjects()
    return data.listConfigs("project_", ".cfg")
end

local function loadSavedProject(projectName)
    return data.loadConfig(projectName, "project_", ".cfg")
end

local function saveSavedProject(projectName, projectData)
    return data.saveConfig(projectName, projectData, "project_", ".cfg")
end

local function deleteSavedProject(projectName)
    return data.deleteConfig(projectName, "project_", ".cfg")
end

-- ========== DASHBOARD SCREEN ==========

function control.showDashboard()
    control.state.currentScreen = "dashboard"
    term.clear()
    term.setCursorPos(1, 1)
    gui.clearComponents()
    gui.clear()
    
    -- Title
    gui.centerText("CCMine Control Center", 1, gui.getColor("primary"), colors.white)
    
    local w, h = layouts.getScreenSize()
    
    -- Detect pocket computer (smaller screen)
    local isPocket = (w < 40)
    
    if isPocket then
        -- Simplified pocket layout
        local statsPanel = components.createPanel("stats", 1, 3, w - 1, 9, "Fleet")
        statsPanel.borderColor = gui.getColor("border")
        
        local stats = coordinator.getStats()
        components.createLabel("totalTurtles", 3, 5,
            string.format("Turtles: %d (Idle:%d)", stats.totalTurtles, stats.idleTurtles))
        components.createLabel("totalProjects", 3, 7,
            string.format("Projects: %d active", stats.activeProjects))
        
        -- Main action buttons (moved down more)
        local btnY = 15
        local btnW = math.floor((w - 4) / 2)
        
        local turtlesBtn = components.createButton("turtlesBtn", 2, btnY, btnW, 2, "Turtles",
            function() control.showTurtleList() end)
        turtlesBtn.bgColor = gui.getColor("primary")
        
        local projectsBtn = components.createButton("projectsBtn", btnW + 3, btnY, btnW, 2, "Projects",
            function() control.showProjectList() end)
        projectsBtn.bgColor = gui.getColor("primary")
        
        -- Exit button
        local exitBtn = components.createButton("exit", 2, h - 2, w - 3, 2, "Exit",
            function() control.exit() end)
        exitBtn.bgColor = gui.getColor("error")
        
        gui.draw()
        return
    end
    
    -- Regular computer layout
    local statsPanel = components.createPanel("stats", 2, 3, 23, 8, "Fleet Overview")
    statsPanel.borderColor = gui.getColor("border")
    
    local stats = coordinator.getStats()
    
    components.createLabel("totalTurtles", 4, 5,
        string.format("Turtles: %d", stats.totalTurtles))
    components.createLabel("idleTurtles", 4, 6,
        string.format("  Idle: %d", stats.idleTurtles))
    components.createLabel("workingTurtles", 4, 7,
        string.format("  Working: %d", stats.workingTurtles))
    
    if stats.lostTurtles > 0 then
        local lostLabel = components.createLabel("lostTurtles", 4, 8,
            string.format("  Lost: %d", stats.lostTurtles))
        lostLabel.fgColor = gui.getColor("error")
    end
    
    components.createLabel("totalProjects", 4, 9,
        string.format("Projects: %d active", stats.activeProjects))
    
    -- Project Summary Panel
    local projPanel = components.createPanel("projects", 26, 3, 23, 8, "Project Stats")
    projPanel.borderColor = gui.getColor("border")
    
    local projectSummary = projectManager.getSummary()
    
    components.createLabel("projTotal", 28, 5,
        string.format("Total: %d", projectSummary.totalProjects))
    components.createLabel("projActive", 28, 6,
        string.format("Active: %d", projectSummary.activeProjects))
    components.createLabel("projComplete", 28, 7,
        string.format("Complete: %d", projectSummary.completedProjects))
    components.createLabel("totalBlocks", 28, 9,
        string.format("Blocks: %d", projectSummary.totalBlocksCleared))
    
    -- Quick Actions
    local actionsPanel = components.createPanel("actions", 2, 12, 47, 6, "Quick Actions")
    actionsPanel.borderColor = gui.getColor("border")
    
    local turtlesBtn = components.createButton("turtlesBtn", 4, 14, 13, 2, "Turtles",
        function() control.showTurtleList() end)
    turtlesBtn.bgColor = gui.getColor("primary")
    
    local projectsBtn = components.createButton("projectsBtn", 18, 14, 13, 2, "Projects",
        function() control.showProjectList() end)
    projectsBtn.bgColor = gui.getColor("primary")
    
    local createBtn = components.createButton("createBtn", 32, 14, 13, 2, "New Project",
        function() control.showCreateProject() end)
    createBtn.bgColor = gui.getColor("success")
    
    -- Footer
    local exitBtn = components.createButton("exit", 19, 19, 13, 2, "Exit",
        function() control.exit() end)
    exitBtn.bgColor = gui.getColor("error")
    
    gui.draw()
end

-- ========== TURTLE LIST SCREEN ==========

function control.showTurtleList()
    control.state.currentScreen = "turtles"
    term.clear()
    term.setCursorPos(1, 1)
    gui.clearComponents()
    gui.clear()
    
    -- Title
    gui.centerText("Turtle Fleet", 1, gui.getColor("primary"), colors.white)
    
    local w, h = layouts.getScreenSize()
    local isPocket = (w < 40)
    
    -- Turtle List Panel
    local panelW = isPocket and (w - 1) or 47
    local panelH = isPocket and (h - 6) or 15
    local panelX = isPocket and 1 or 2
    local panelY = 3
    
    local listPanel = components.createPanel("list", panelX, panelY, panelW, panelH, "All Turtles")
    listPanel.borderColor = gui.getColor("border")
    
    local listX = panelX + 2
    local listY = panelY + 2
    local listW = panelW - 4
    local listH = panelH - 4
    
    local turtleList = components.createList("turtleList", listX, listY, listW, listH)
    
    local turtles = coordinator.getAllTurtles()
    local count = 0
    
    for id, turtle in pairs(turtles) do
        local statusColor = ""
        if turtle.status == "working" then
            statusColor = "W"
        elseif turtle.status == "idle" then
            statusColor = "I"
        elseif turtle.status == "lost" then
            statusColor = "L"
        end
        
        local itemText = string.format("[%s] %d: %s (Fuel: %d)", 
            statusColor, id, turtle.label, turtle.fuel)
        turtleList:addItem(itemText, turtle)
        count = count + 1
    end
    
    if count == 0 then
        local msgY = math.floor(panelY + panelH / 2)
        components.createLabel("noTurtles", listX, msgY, "No turtles registered")
    end
    
    -- Selection handler
    turtleList.onSelect = function(item)
        control.state.selectedTurtle = item.data
        control.showTurtleDetail()
    end
    
    -- Back button
    local btnW = isPocket and (w - 3) or 13
    local btnX = isPocket and 2 or 19
    local btnY = h - 2
    
    local backBtn = components.createButton("back", btnX, btnY, btnW, 2, "Back",
        function() control.showDashboard() end)
    
    gui.draw()
end

-- ========== TURTLE DETAIL SCREEN ==========

function control.showTurtleDetail()
    if not control.state.selectedTurtle then
        control.showTurtleList()
        return
    end
    
    control.state.currentScreen = "turtleDetail"
    term.clear()
    term.setCursorPos(1, 1)
    gui.clearComponents()
    gui.clear()
    
    local turtle = control.state.selectedTurtle
    
    -- Title
    gui.centerText("Turtle Details", 1, gui.getColor("primary"), colors.white)
    
    -- Info Panel
    local infoPanel = components.createPanel("info", 2, 3, 47, 10, turtle.label)
    infoPanel.borderColor = gui.getColor("border")
    
    components.createLabel("id", 4, 5, string.format("ID: %d", turtle.id))
    components.createLabel("status", 4, 6, string.format("Status: %s", turtle.status))
    components.createLabel("fuel", 4, 7, string.format("Fuel: %d", turtle.fuel))
    components.createLabel("inv", 4, 8, string.format("Inventory: %d/16", turtle.inventory))
    components.createLabel("pos", 4, 9,
        string.format("Position: X:%d Y:%d Z:%d", 
            turtle.position.x, turtle.position.y, turtle.position.z))
    
    if turtle.currentProject then
        local project = projectManager.get(turtle.currentProject)
        if project then
            components.createLabel("proj", 4, 10,
                string.format("Project: %s", project.name))
        end
    end
    
    -- Actions
    local actionsPanel = components.createPanel("actions", 2, 14, 47, 4, "Actions")
    actionsPanel.borderColor = gui.getColor("border")
    
    local assignBtn = components.createButton("assign", 4, 16, 13, 1, "Assign Project",
        function() control.showAssignProject() end)
    
    local homeBtn = components.createButton("home", 18, 16, 13, 1, "Return Home",
        function()
            coordinator.sendCommand(turtle.id, "return_home")
            gui.notify("Sent return home command", colors.white, colors.green, 2)
        end)
    
    local unassignBtn = components.createButton("unassign", 32, 16, 13, 1, "Unassign",
        function()
            coordinator.unassignFromProject(turtle.id)
            gui.notify("Turtle unassigned", colors.white, colors.orange, 2)
        end)
    
    -- Back button
    local backBtn = components.createButton("back", 19, 19, 13, 2, "Back",
        function() control.showTurtleList() end)
    
    gui.draw()
end

-- ========== PROJECT LIST SCREEN ==========

function control.showProjectList()
    control.state.currentScreen = "projects"
    term.clear()
    term.setCursorPos(1, 1)
    gui.clearComponents()
    gui.clear()
    
    -- Title
    gui.centerText("Project Manager", 1, gui.getColor("primary"), colors.white)
    
    local w, h = layouts.getScreenSize()
    local isPocket = (w < 40)
    
    -- Project List Panel
    local panelW = isPocket and (w - 1) or 47
    local panelH = isPocket and (h - 9) or 15
    local panelX = isPocket and 1 or 2
    local panelY = 3
    
    local listPanel = components.createPanel("list", panelX, panelY, panelW, panelH, "All Projects")
    listPanel.borderColor = gui.getColor("border")
    
    local listX = panelX + 2
    local listY = panelY + 2
    local listW = panelW - 4
    local listH = panelH - 4
    
    local projectList = components.createList("projectList", listX, listY, listW, listH)
    
    local projects = projectManager.getAll()
    local count = 0
    
    for id, project in pairs(projects) do
        local itemText = string.format("%s (%s) - %d%%",
            project.name, project.type, project.progress.completion)
        projectList:addItem(itemText, project)
        count = count + 1
    end
    
    if count == 0 then
        local msgY = math.floor(panelY + panelH / 2)
        components.createLabel("noProjects", listX, msgY, "No projects created")
    end
    
    -- Selection handler
    projectList.onSelect = function(item)
        control.state.selectedProject = item.data
        control.showProjectDetail()
    end
    
    -- Buttons
    local btnY = h - 5
    local btnW = isPocket and math.floor((w - 4) / 2) or 13
    local btn1X = isPocket and 2 or 14
    local btn2X = isPocket and (btnW + 3) or 28
    
    local newBtn = components.createButton("new", btn1X, btnY, btnW, 2, "New Project",
        function() control.showCreateProject() end)
    newBtn.bgColor = gui.getColor("success")
    
    local backBtn = components.createButton("back", btn2X, btnY, btnW, 2, "Back",
        function() control.showDashboard() end)
    
    gui.draw()
end

-- ========== PROJECT DETAIL SCREEN ==========

function control.showProjectDetail()
    if not control.state.selectedProject then
        control.showProjectList()
        return
    end
    
    control.state.currentScreen = "projectDetail"
    term.clear()
    term.setCursorPos(1, 1)
    gui.clearComponents()
    gui.clear()
    
    local project = control.state.selectedProject
    
    -- Title
    gui.centerText("Project Details", 1, gui.getColor("primary"), colors.white)
    
    -- Info Panel
    local infoPanel = components.createPanel("info", 2, 3, 47, 9, project.name)
    infoPanel.borderColor = gui.getColor("border")
    
    components.createLabel("type", 4, 5, string.format("Type: %s", project.type))
    components.createLabel("status", 4, 6, string.format("Status: %s", project.status))
    
    local progressBar = components.createProgressBar("progress", 4, 7, 43)
    progressBar.value = project.progress.completion
    
    components.createLabel("blocks", 4, 9,
        string.format("Blocks Cleared: %d", project.progress.blocksCleared))
    components.createLabel("ore", 4, 10,
        string.format("Ore Found: %d", project.progress.oreFound))
    
    -- Assigned Turtles
    local turtleCount = 0
    for _ in pairs(project.assignedTurtles) do
        turtleCount = turtleCount + 1
    end
    components.createLabel("turtles", 4, 11,
        string.format("Assigned Turtles: %d", turtleCount))
    
    -- Actions
    local actionsPanel = components.createPanel("actions", 2, 13, 47, 5, "Actions")
    actionsPanel.borderColor = gui.getColor("border")
    
    if project.status == "active" then
        local pauseBtn = components.createButton("pause", 4, 15, 11, 2, "Pause",
            function()
                projectManager.pause(project.id)
                gui.notify("Project paused", colors.white, colors.orange, 2)
            end)
        pauseBtn.bgColor = gui.getColor("warning")
    elseif project.status == "paused" then
        local resumeBtn = components.createButton("resume", 4, 15, 11, 2, "Resume",
            function()
                projectManager.resume(project.id)
                gui.notify("Project resumed", colors.white, colors.green, 2)
            end)
        resumeBtn.bgColor = gui.getColor("success")
    end
    
    local coordBtn = components.createButton("coord", 16, 15, 11, 2, "Broadcast",
        function()
            coordinator.broadcastCoordination(project.id)
            gui.notify("Sent coordination update", colors.white, colors.blue, 2)
        end)
    
    local deleteBtn = components.createButton("delete", 28, 15, 11, 2, "Delete",
        function()
            projectManager.cancel(project.id)
            gui.notify("Project deleted", colors.white, colors.red, 2)
            control.showProjectList()
        end)
    deleteBtn.bgColor = gui.getColor("error")
    
    -- Back button
    local backBtn = components.createButton("back", 19, 19, 13, 2, "Back",
        function() control.showProjectList() end)
    
    gui.draw()
end

-- ========== CREATE PROJECT SCREEN ==========

function control.showCreateProject()
    control.state.currentScreen = "createProject"
    term.clear()
    term.setCursorPos(1, 1)
    gui.clearComponents()
    gui.clear()
    
    local w, h = layouts.getScreenSize()
    local isPocket = (w < 40)
    
    -- Title
    gui.centerText("Create New Project", 1, gui.getColor("primary"), colors.white)
    
    -- Simplified form for pocket computers
    if isPocket then
        local formX = 2
        local formY = 3
        
        -- Project Name
        components.createLabel("nameLbl", formX, formY, "Name:")
        local nameInput = components.createTextInput("name", formX, formY + 1, w - 4, "North Mine")
        
        -- Project Type (with manual toggle buttons)
        components.createLabel("typeLbl", formX, formY + 3, "Type:")
        
        -- Use stored selection or default to branch_mine
        if not control.state.selectedType then
            control.state.selectedType = "branch_mine"
        end
        local selectedType = control.state.selectedType
        
        -- Draw type selection manually
        local function drawTypeButtons()
            local btnW = 8
            local typeY = formY + 4
            
            -- Branch button
            term.setBackgroundColor(selectedType == "branch_mine" and gui.getColor("primary") or colors.gray)
            term.setTextColor(colors.white)
            term.setCursorPos(formX, typeY)
            term.write(string.rep(" ", btnW))
            term.setCursorPos(formX + 1, typeY)
            term.write("Branch")
            
            -- Quarry button
            term.setBackgroundColor(selectedType == "quarry" and gui.getColor("primary") or colors.gray)
            term.setCursorPos(formX + btnW + 1, typeY)
            term.write(string.rep(" ", btnW))
            term.setCursorPos(formX + btnW + 2, typeY)
            term.write("Quarry")
            
            -- Strip button
            term.setBackgroundColor(selectedType == "strip_mine" and gui.getColor("primary") or colors.gray)
            term.setCursorPos(formX + (btnW + 1) * 2, typeY)
            term.write(string.rep(" ", btnW))
            term.setCursorPos(formX + (btnW + 1) * 2 + 1, typeY)
            term.write("Strip")
            
            term.setBackgroundColor(colors.black)
        end
        
        -- Store type button positions for click detection
        control.state.typeButtons = {
            { x1 = formX, x2 = formX + 7, y = formY + 4, type = "branch_mine" },
            { x1 = formX + 9, x2 = formX + 16, y = formY + 4, type = "quarry" },
            { x1 = formX + 18, x2 = formX + 25, y = formY + 4, type = "strip_mine" }
        }
        control.state.currentScreen = "create_project"
        
        drawTypeButtons()
        
        -- Starting Position (compact)
        components.createLabel("posLbl", formX, formY + 6, "Start Pos:")
        components.createLabel("xLbl", formX, formY + 7, "X:")
        local xInput = components.createTextInput("x", formX + 3, formY + 7, 6, "0")
        components.createLabel("yLbl", formX + 11, formY + 7, "Y:")
        local yInput = components.createTextInput("y", formX + 14, formY + 7, 5, "11")
        components.createLabel("zLbl", formX, formY + 8, "Z:")
        local zInput = components.createTextInput("z", formX + 3, formY + 8, 6, "0")
        
        -- Options
        local torchCheck = components.createCheckbox("torch", formX, formY + 10, "Torch", true)
        local wallCheck = components.createCheckbox("wall", formX, formY + 11, "Wall Protect", true)
        
        -- Buttons
        local btnW = math.floor((w - 5) / 2)
        local btnY = h - 2
        
        local createBtn = components.createButton("create", 2, btnY, btnW, 2, "Create",
            function()
                local name = nameInput.value ~= "" and nameInput.value or "New Project"
                
                local config = {
                    mainTunnelLength = 64,
                    sideTunnelLength = 32,
                    placeTorches = torchCheck.checked,
                    wallProtection = wallCheck.checked
                }
                local startPos = {
                    x = tonumber(xInput.value) or 0,
                    y = tonumber(yInput.value) or 11,
                    z = tonumber(zInput.value) or 0
                }
                
                local projectId = projectManager.create(selectedType, name, config, startPos)
                gui.notify("Project created: " .. name, colors.white, colors.green, 2)
                control.showProjectList()
            end)
        createBtn.bgColor = gui.getColor("success")
        
        local cancelBtn = components.createButton("cancel", btnW + 3, btnY, btnW, 2, "Cancel",
            function() control.showProjectList() end)
        
        gui.draw()
        return
    end
    
    -- Regular computer layout (original)
    local formPanel = components.createPanel("form", 3, 3, w - 6, h - 6, "Project Configuration")
    formPanel.borderColor = gui.getColor("border")
    
    local formX = 5
    local formY = 5
    
    -- Project Name
    components.createLabel("nameLbl", formX, formY, "Project Name:")
    local nameInput = components.createTextInput("name", formX + 15, formY, w - 24, "North Mine")
    
    -- Project Type
    components.createLabel("typeLbl", formX, formY + 2, "Project Type:")
    components.createLabel("type1", formX + 2, formY + 3, "1) Branch Mine")
    components.createLabel("type2", formX + 2, formY + 4, "2) Quarry")
    components.createLabel("type3", formX + 2, formY + 5, "3) Strip Mine")
    local typeInput = components.createTextInput("type", formX + 15, formY + 2, 5, "1")
    
    -- Dimensions
    components.createLabel("mainLbl", formX, formY + 7, "Main Tunnel Length:")
    local mainInput = components.createTextInput("main", formX + 20, formY + 7, 8, "64")
    
    components.createLabel("sideLbl", formX, formY + 8, "Side Tunnel Length:")
    local sideInput = components.createTextInput("side", formX + 20, formY + 8, 8, "32")
    
    -- Starting Position
    components.createLabel("posLbl", formX, formY + 10, "Starting Position:")
    components.createLabel("xLbl", formX + 2, formY + 11, "X:")
    local xInput = components.createTextInput("x", formX + 5, formY + 11, 6, "0")
    
    components.createLabel("yLbl", formX + 13, formY + 11, "Y:")
    local yInput = components.createTextInput("y", formX + 16, formY + 11, 6, "11")
    
    components.createLabel("zLbl", formX + 24, formY + 11, "Z:")
    local zInput = components.createTextInput("z", formX + 27, formY + 11, 6, "0")
    
    -- Options
    components.createLabel("optLbl", formX, formY + 13, "Options:")
    local torchCheck = components.createCheckbox("torch", formX + 2, formY + 14, "Place Torches", true)
    local wallCheck = components.createCheckbox("wall", formX + 2, formY + 15, "Wall Protection", true)
    
    -- Buttons
    local createBtn = components.createButton("create", formX, h - 3, 15, 2, "Create",
        function()
            local typeMap = {
                ["1"] = "branch_mine",
                ["2"] = "quarry",
                ["3"] = "strip_mine"
            }
            
            local projectType = typeMap[typeInput.value] or "branch_mine"
            local name = nameInput.value ~= "" and nameInput.value or "New Project"
            
            local config = {
                mainTunnelLength = tonumber(mainInput.value) or 64,
                sideTunnelLength = tonumber(sideInput.value) or 32,
                placeTorches = torchCheck.checked,
                wallProtection = wallCheck.checked
            }
            
            local startPos = {
                x = tonumber(xInput.value) or 0,
                y = tonumber(yInput.value) or 11,
                z = tonumber(zInput.value) or 0
            }
            
            local projectId = projectManager.create(projectType, name, config, startPos)
            gui.notify("Project created: " .. name, colors.white, colors.green, 2)
            
            control.showProjectList()
        end)
    createBtn.bgColor = gui.getColor("success")
    
    local cancelBtn = components.createButton("cancel", formX + 17, h - 3, 15, 2, "Cancel",
        function() control.showProjectList() end)
    
    gui.draw()
end

-- ========== ASSIGN PROJECT SCREEN ==========

function control.showAssignProject()
    if not control.state.selectedTurtle then
        control.showTurtleList()
        return
    end
    
    control.state.currentScreen = "assignProject"
    term.clear()
    term.setCursorPos(1, 1)
    gui.clearComponents()
    gui.clear()
    
    local turtle = control.state.selectedTurtle
    
    -- Title
    gui.centerText("Assign to Project", 1, gui.getColor("primary"), colors.white)
    
    components.createLabel("turtleLabel", 2, 2,
        string.format("Turtle: %s (ID: %d)", turtle.label, turtle.id))
    
    -- Project List
    local listPanel = components.createPanel("list", 2, 3, 47, 13, "Available Projects")
    listPanel.borderColor = gui.getColor("border")
    
    local projectList = components.createList("projectList", 4, 5, 43, 9)
    
    local projects = projectManager.getByStatus("active")
    local count = 0
    
    for id, project in pairs(projects) do
        local itemText = string.format("%s (%s)", project.name, project.type)
        projectList:addItem(itemText, project)
        count = count + 1
    end
    
    -- Also include pending projects
    local pendingProjects = projectManager.getByStatus("pending")
    for id, project in pairs(pendingProjects) do
        local itemText = string.format("%s (%s) [PENDING]", project.name, project.type)
        projectList:addItem(itemText, project)
        count = count + 1
    end
    
    if count == 0 then
        components.createLabel("noProjects", 4, 10, "No projects available")
    end
    
    -- Selection handler
    projectList.onSelect = function(item)
        local success, err = coordinator.assignToProject(turtle.id, item.data.id)
        if success then
            gui.notify("Turtle assigned successfully!", colors.white, colors.green, 2)
            control.showTurtleDetail()
        else
            gui.notify("Assignment failed: " .. (err or "unknown"), colors.white, colors.red, 3)
        end
    end
    
    -- Back button
    local backBtn = components.createButton("back", 19, 17, 13, 2, "Back",
        function() control.showTurtleDetail() end)
    
    gui.draw()
end

-- ========== MAIN FUNCTIONS ==========

function control.exit()
    gui.clearComponents()
    gui.clear()
    
    -- Stop coordinator
    if control.state.coordinatorRunning then
        coordinator.stop()
    end
    
    print("Control Center closed.")
end

function control.updateDisplay()
    if control.state.currentScreen == "dashboard" then
        control.showDashboard()
    elseif control.state.currentScreen == "turtles" then
        control.showTurtleList()
    elseif control.state.currentScreen == "projects" then
        control.showProjectList()
    end
end

-- ========== MAIN LOOP ==========

function control.run()
    -- Initialize GUI
    gui.init()
    gui.setTheme("default")
    
    -- Start coordinator
    term.clear()
    term.setCursorPos(1, 1)
    print("Starting coordinator...")
    local success = coordinator.start()
    
    if not success then
        print("Failed to start coordinator!")
        print("Make sure a wireless modem is attached.")
        print("Press any key to exit...")
        os.pullEvent("key")
        return
    end
    
    control.state.coordinatorRunning = true
    print("Coordinator started successfully!")
    sleep(1)
    
    -- Clear screen before showing GUI
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Show dashboard
    control.showDashboard()
    
    -- Main event loop
    parallel.waitForAny(
        function()
            -- Coordinator message loop
            coordinator.messageLoop()
        end,
        function()
            -- Coordinator health check loop
            coordinator.healthCheckLoop()
        end,
        function()
            -- GUI event loop
            while true do
                local event, p1, p2, p3 = os.pullEvent()
                
                if event == "mouse_click" then
                    -- Check if clicked on type button (in Create Project screen)
                    if control.state.typeButtons and control.state.currentScreen == "create_project" then
                        local x, y = p2, p3
                        for _, btn in ipairs(control.state.typeButtons) do
                            if y == btn.y and x >= btn.x1 and x <= btn.x2 then
                                -- Update selection and redraw
                                control.state.selectedType = btn.type
                                control.showCreateProject()
                                break
                            end
                        end
                    end
                    
                    local clicked = gui.handleClick(p2, p3, p1)
                    if clicked then
                        gui.draw()
                    end
                elseif event == "mouse_move" then
                    gui.handleMouseMove(p2, p3)
                    gui.draw()
                elseif event == "mouse_scroll" then
                    gui.handleScroll(p2, p3, p1)
                    gui.draw()
                elseif event == "term_resize" then
                    gui.init()
                    control.updateDisplay()
                elseif event == "key" then
                    if p1 == keys.q and keys.leftCtrl then
                        control.exit()
                        break
                    end
                end
            end
        end
    )
end

-- Auto-run if executed directly
if not ... then
    control.run()
end

return control
