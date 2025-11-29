-- Control Center - Turtle Fleet Management Interface
-- Standalone application for managing all turtles and projects

local gui = require("gui-core")
local components = require("gui-components")
local layouts = require("gui-layouts")
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

-- ========== DASHBOARD SCREEN ==========

function control.showDashboard()
    control.state.currentScreen = "dashboard"
    gui.clearComponents()
    
    -- Title
    gui.centerText("CCMine Control Center", 1, gui.getColor("primary"), colors.white)
    
    -- Stats Panel
    local statsPanel = components.createPanel("stats", 2, 3, 23, 8, "Overview")
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
    local projPanel = components.createPanel("projects", 26, 3, 23, 8, "Projects")
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
        function() control.showProjectManager() end)
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
    gui.clearComponents()
    
    -- Title
    gui.centerText("Turtle Fleet", 1, gui.getColor("primary"), colors.white)
    
    -- Turtle List Panel
    local listPanel = components.createPanel("list", 2, 3, 47, 15, "All Turtles")
    listPanel.borderColor = gui.getColor("border")
    
    local turtleList = components.createList("turtleList", 4, 5, 43, 11)
    
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
        components.createLabel("noTurtles", 4, 10, "No turtles registered")
    end
    
    -- Selection handler
    turtleList.onSelect = function(item)
        control.state.selectedTurtle = item.data
        control.showTurtleDetail()
    end
    
    -- Back button
    local backBtn = components.createButton("back", 19, 18, 13, 2, "Back",
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
    gui.clearComponents()
    
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
            print("Sent return home command")
        end)
    
    local unassignBtn = components.createButton("unassign", 32, 16, 13, 1, "Unassign",
        function()
            coordinator.unassignFromProject(turtle.id)
            print("Turtle unassigned")
        end)
    
    -- Back button
    local backBtn = components.createButton("back", 19, 19, 13, 2, "Back",
        function() control.showTurtleList() end)
    
    gui.draw()
end

-- ========== PROJECT MANAGER SCREEN ==========

function control.showProjectManager()
    control.state.currentScreen = "projects"
    gui.clearComponents()
    
    -- Title
    gui.centerText("Project Manager", 1, gui.getColor("primary"), colors.white)
    
    -- Project List Panel
    local listPanel = components.createPanel("list", 2, 3, 47, 15, "All Projects")
    listPanel.borderColor = gui.getColor("border")
    
    local projectList = components.createList("projectList", 4, 5, 43, 11)
    
    local projects = projectManager.getAll()
    local count = 0
    
    for id, project in pairs(projects) do
        local itemText = string.format("%s (%s) - %d%%",
            project.name, project.type, project.progress.completion)
        projectList:addItem(itemText, project)
        count = count + 1
    end
    
    if count == 0 then
        components.createLabel("noProjects", 4, 10, "No projects created")
    end
    
    -- Selection handler
    projectList.onSelect = function(item)
        control.state.selectedProject = item.data
        control.showProjectDetail()
    end
    
    -- Buttons
    local newBtn = components.createButton("new", 14, 18, 13, 2, "New Project",
        function() control.showCreateProject() end)
    newBtn.bgColor = gui.getColor("success")
    
    local backBtn = components.createButton("back", 28, 18, 13, 2, "Back",
        function() control.showDashboard() end)
    
    gui.draw()
end

-- ========== PROJECT DETAIL SCREEN ==========

function control.showProjectDetail()
    if not control.state.selectedProject then
        control.showProjectManager()
        return
    end
    
    control.state.currentScreen = "projectDetail"
    gui.clearComponents()
    
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
                print("Project paused")
            end)
        pauseBtn.bgColor = gui.getColor("warning")
    elseif project.status == "paused" then
        local resumeBtn = components.createButton("resume", 4, 15, 11, 2, "Resume",
            function()
                projectManager.resume(project.id)
                print("Project resumed")
            end)
        resumeBtn.bgColor = gui.getColor("success")
    end
    
    local coordBtn = components.createButton("coord", 16, 15, 11, 2, "Broadcast",
        function()
            coordinator.broadcastCoordination(project.id)
            print("Sent coordination update")
        end)
    
    local cancelBtn = components.createButton("cancel", 28, 15, 11, 2, "Cancel",
        function()
            projectManager.cancel(project.id)
            print("Project cancelled")
        end)
    cancelBtn.bgColor = gui.getColor("error")
    
    -- Back button
    local backBtn = components.createButton("back", 19, 19, 13, 2, "Back",
        function() control.showProjectManager() end)
    
    gui.draw()
end

-- ========== CREATE PROJECT SCREEN ==========

function control.showCreateProject()
    control.state.currentScreen = "createProject"
    gui.clearComponents()
    
    -- Title
    gui.centerText("Create New Project", 1, gui.getColor("primary"), colors.white)
    
    -- Form Panel
    local formPanel = components.createPanel("form", 5, 3, 41, 14, "Project Details")
    formPanel.borderColor = gui.getColor("border")
    
    components.createLabel("nameLbl", 7, 5, "Name:")
    local nameInput = components.createTextInput("name", 15, 5, 27, "North Mine")
    
    components.createLabel("typeLbl", 7, 7, "Type:")
    components.createLabel("type1", 15, 7, "1) Branch Mine")
    components.createLabel("type2", 15, 8, "2) Quarry")
    components.createLabel("type3", 15, 9, "3) Strip Mine")
    local typeInput = components.createTextInput("type", 15, 10, 5, "1")
    
    components.createLabel("xLbl", 7, 12, "Start X:")
    local xInput = components.createTextInput("x", 16, 12, 8, "0")
    
    components.createLabel("yLbl", 26, 12, "Y:")
    local yInput = components.createTextInput("y", 29, 12, 8, "64")
    
    components.createLabel("zLbl", 7, 13, "Start Z:")
    local zInput = components.createTextInput("z", 16, 13, 8, "0")
    
    -- Buttons
    local createBtn = components.createButton("create", 8, 17, 15, 2, "Create",
        function()
            local typeMap = {
                ["1"] = "branch_mine",
                ["2"] = "quarry",
                ["3"] = "strip_mine"
            }
            
            local projectType = typeMap[typeInput.value] or "branch_mine"
            local name = nameInput.value ~= "" and nameInput.value or "New Project"
            
            local startPos = {
                x = tonumber(xInput.value) or 0,
                y = tonumber(yInput.value) or 64,
                z = tonumber(zInput.value) or 0
            }
            
            local projectId = projectManager.create(projectType, name, nil, startPos)
            print("Project created: " .. name)
            
            control.showProjectManager()
        end)
    createBtn.bgColor = gui.getColor("success")
    
    local cancelBtn = components.createButton("cancel", 26, 17, 15, 2, "Cancel",
        function() control.showProjectManager() end)
    
    gui.draw()
end

-- ========== ASSIGN PROJECT SCREEN ==========

function control.showAssignProject()
    if not control.state.selectedTurtle then
        control.showTurtleList()
        return
    end
    
    control.state.currentScreen = "assignProject"
    gui.clearComponents()
    
    local turtle = control.state.selectedTurtle
    
    -- Title
    gui.centerText("Assign to Project", 1, gui.getColor("primary"), colors.white)
    
    components.createLabel("turtleLabel", 2, 2,
        string.format("Turtle: %s", turtle.label))
    
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
            print("Turtle assigned successfully!")
            control.showTurtleDetail()
        else
            print("Assignment failed: " .. (err or "unknown error"))
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
        control.showProjectManager()
    end
end

-- ========== MAIN LOOP ==========

function control.run()
    -- Initialize GUI
    gui.init()
    gui.setTheme("default")
    
    -- Start coordinator
    print("Starting coordinator...")
    local success = coordinator.start()
    
    if not success then
        print("Failed to start coordinator!")
        print("Press any key to exit...")
        os.pullEvent("key")
        return
    end
    
    control.state.coordinatorRunning = true
    
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

