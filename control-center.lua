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

-- Version number (incremented with each release)
control.VERSION = "2.0"

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
    
    -- Title with version
    local w, h = layouts.getScreenSize()
    gui.centerText("CCMine Control Center", 1, gui.getColor("primary"), colors.white)
    
    -- Version in top right
    term.setCursorPos(w - 4, 1)
    term.setBackgroundColor(gui.getColor("primary"))
    term.setTextColor(colors.lightGray)
    term.write("v" .. control.VERSION)
    
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
    
    -- Trigger discovery
    coordinator.discoverTurtles()
    
    -- Turtle List Panel
    local panelW = isPocket and (w - 1) or 47
    local panelH = isPocket and (h - 9) or 12
    local panelX = isPocket and 1 or 2
    local panelY = 3
    
    local listPanel = components.createPanel("list", panelX, panelY, panelW, panelH, "Online Turtles")
    listPanel.borderColor = gui.getColor("border")
    
    -- Get online turtles
    local turtles = coordinator.getOnlineTurtles()
    local count = 0
    
    -- Store for click detection
    control.state.turtleListItems = {}
    control.state.turtleListBounds = {
        x = panelX + 2,
        y = panelY + 2,
        w = panelW - 4,
        h = panelH - 4
    }
    
    -- Draw turtles manually for better control
    local listY = panelY + 2
    for id, turtle in pairs(turtles) do
        if listY < panelY + panelH - 1 then
            -- Status indicator
            local statusChar = "?"
            local statusColor = colors.gray
            if turtle.status == "working" then
                statusChar = "W"
                statusColor = colors.blue
            elseif turtle.status == "assigned" then
                statusChar = "A"
                statusColor = colors.cyan
            elseif turtle.status == "idle" then
                statusChar = "I"
                statusColor = colors.green
            elseif turtle.status == "lost" then
                statusChar = "X"
                statusColor = colors.red
            end
            
            term.setCursorPos(panelX + 2, listY)
            term.setBackgroundColor(colors.black)
            term.setTextColor(statusColor)
            term.write("[" .. statusChar .. "]")
            term.setTextColor(colors.white)
            
            local label = turtle.label or ("Turtle-" .. id)
            if isPocket then
                term.write(" " .. label:sub(1, 12))
            else
                term.write(string.format(" %s (F:%d)", label:sub(1, 16), turtle.fuel))
            end
            
            table.insert(control.state.turtleListItems, turtle)
            listY = listY + 1
            count = count + 1
        end
    end
    
    -- Update bounds height
    control.state.turtleListBounds.h = count
    
    if count == 0 then
        local msgY = math.floor(panelY + panelH / 2)
        term.setCursorPos(panelX + 2, msgY)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.gray)
        term.write("No turtles online")
        term.setCursorPos(panelX + 2, msgY + 1)
        term.write("Waiting for connections...")
    end
    
    -- Buttons
    local btnY = h - 5
    local btnW = isPocket and math.floor((w - 4) / 2) or 13
    
    if isPocket then
        local refreshBtn = components.createButton("refresh", 2, btnY, btnW, 2, "Refresh",
            function() control.showTurtleList() end)
        refreshBtn.bgColor = gui.getColor("primary")
        
        local backBtn = components.createButton("back", btnW + 3, btnY, btnW, 2, "Back",
            function() control.showDashboard() end)
    else
        local refreshBtn = components.createButton("refresh", 4, 16, 13, 2, "Refresh",
            function() control.showTurtleList() end)
        refreshBtn.bgColor = gui.getColor("primary")
        
        local backBtn = components.createButton("back", 34, 16, 13, 2, "Back",
            function() control.showDashboard() end)
    end
    
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
    local w, h = layouts.getScreenSize()
    local isPocket = (w < 40)
    
    -- Title
    local title = turtle.label or ("Turtle " .. turtle.id)
    gui.centerText(title, 1, gui.getColor("primary"), colors.white)
    
    if isPocket then
        -- Pocket layout
        local currentY = 3
        
        -- Status with color
        local statusColor = turtle.status == "idle" and colors.green or
                           turtle.status == "working" and colors.blue or
                           turtle.status == "assigned" and colors.cyan or colors.gray
        term.setCursorPos(2, currentY)
        term.setBackgroundColor(colors.black)
        term.setTextColor(statusColor)
        term.write("Status: " .. turtle.status:upper())
        currentY = currentY + 1
        
        term.setTextColor(colors.white)
        term.setCursorPos(2, currentY)
        term.write("ID: " .. turtle.id .. "  Fuel: " .. turtle.fuel)
        currentY = currentY + 1
        
        term.setCursorPos(2, currentY)
        term.write(string.format("Pos: %d,%d,%d", 
            turtle.position.x, turtle.position.y, turtle.position.z))
        currentY = currentY + 2
        
        -- Current project
        if turtle.currentProject then
            local project = projectManager.get(turtle.currentProject)
            if project then
                term.setCursorPos(2, currentY)
                term.setTextColor(colors.yellow)
                term.write("Project: " .. project.name:sub(1, 15))
                term.setTextColor(colors.white)
                currentY = currentY + 1
                
                if turtle.zone then
                    term.setCursorPos(2, currentY)
                    term.write("Zone: " .. turtle.zone)
                end
            end
        else
            term.setCursorPos(2, currentY)
            term.setTextColor(colors.gray)
            term.write("No project assigned")
            term.setTextColor(colors.white)
        end
        currentY = currentY + 2
        
        -- Action buttons
        local btnW = w - 4
        local btnX = 2
        
        if turtle.currentProject then
            -- Unlink button
            local unlinkBtn = components.createButton("unlink", btnX, currentY, btnW, 2, "Unlink",
                function()
                    coordinator.unlinkTurtle(turtle.id)
                    gui.notify("Unlinked", colors.white, colors.orange, 1)
                    control.state.selectedTurtle.currentProject = nil
                    control.state.selectedTurtle.zone = nil
                    control.state.selectedTurtle.status = "idle"
                    control.showTurtleDetail()
                end)
            unlinkBtn.bgColor = gui.getColor("warning")
        else
            -- Assign button
            local assignBtn = components.createButton("assign", btnX, currentY, btnW, 2, "Assign to Project",
                function() control.showAssignProject() end)
            assignBtn.bgColor = gui.getColor("primary")
        end
        currentY = currentY + 3
        
        -- Return home button
        local homeBtn = components.createButton("home", btnX, currentY, btnW, 2, "Return Home",
            function()
                coordinator.sendCommand(turtle.id, "return_home")
                gui.notify("Sent home", colors.white, colors.green, 1)
            end)
        
        -- Back button
        local backBtn = components.createButton("back", btnX, h - 2, btnW, 2, "Back",
            function() control.showTurtleList() end)
        
        gui.draw()
        return
    end
    
    -- Regular computer layout
    -- Info Panel
    local infoPanel = components.createPanel("info", 2, 3, 47, 8, "Info")
    infoPanel.borderColor = gui.getColor("border")
    
    -- Status with color
    local statusColor = turtle.status == "idle" and colors.green or
                       turtle.status == "working" and colors.blue or
                       turtle.status == "assigned" and colors.cyan or colors.gray
    term.setCursorPos(4, 5)
    term.setBackgroundColor(colors.black)
    term.write("ID: " .. turtle.id .. "   Status: ")
    term.setTextColor(statusColor)
    term.write(turtle.status:upper())
    term.setTextColor(colors.white)
    
    components.createLabel("fuel", 4, 6, string.format("Fuel: %d", turtle.fuel))
    components.createLabel("inv", 4, 7, string.format("Inventory: %d/16 slots used", turtle.inventory))
    components.createLabel("pos", 4, 8,
        string.format("Position: X:%d Y:%d Z:%d", 
            turtle.position.x, turtle.position.y, turtle.position.z))
    
    -- Project info
    if turtle.currentProject then
        local project = projectManager.get(turtle.currentProject)
        if project then
            components.createLabel("proj", 4, 9,
                string.format("Project: %s (Zone %d)", project.name, turtle.zone or 0))
        end
    else
        local noProj = components.createLabel("proj", 4, 9, "Project: None assigned")
        noProj.fgColor = colors.gray
    end
    
    -- Actions Panel
    local actionsPanel = components.createPanel("actions", 2, 12, 47, 5, "Actions")
    actionsPanel.borderColor = gui.getColor("border")
    
    if turtle.currentProject then
        local unlinkBtn = components.createButton("unlink", 4, 14, 13, 2, "Unlink",
            function()
                coordinator.unlinkTurtle(turtle.id)
                gui.notify("Turtle unlinked", colors.white, colors.orange, 2)
                control.state.selectedTurtle.currentProject = nil
                control.state.selectedTurtle.zone = nil
                control.state.selectedTurtle.status = "idle"
                control.showTurtleDetail()
            end)
        unlinkBtn.bgColor = gui.getColor("warning")
    else
        local assignBtn = components.createButton("assign", 4, 14, 13, 2, "Assign",
            function() control.showAssignProject() end)
        assignBtn.bgColor = gui.getColor("primary")
    end
    
    local homeBtn = components.createButton("home", 18, 14, 13, 2, "Return Home",
        function()
            coordinator.sendCommand(turtle.id, "return_home")
            gui.notify("Sent return home", colors.white, colors.green, 2)
        end)
    
    -- Back button
    local backBtn = components.createButton("back", 34, 14, 11, 2, "Back",
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
    
    local listX = 2
    local listY = 2
    local listW = panelW - 4
    local listH = panelH - 4
    
    local projectList = components.createList("projectList", listX, listY, listW, listH)
    listPanel:addChild(projectList)
    
    local projects = projectManager.getAll()
    local count = 0
    
    -- Store items for click handling
    control.state.projectListItems = {}
    control.state.currentScreen = "projects"
    
    -- Add projects to list with better formatting
    for id, project in pairs(projects or {}) do
        -- Shorten type name
        local typeShort = project.type:gsub("_mine", ""):gsub("branch", "Branch"):gsub("quarry", "Quarry"):gsub("strip", "Strip")
        local itemText = string.format("%s [%s] %d%%", project.name, typeShort, project.progress.completion)
        projectList:addItem(itemText, project)
        table.insert(control.state.projectListItems, project)
        count = count + 1
    end
    
    -- Store bounds for click detection (absolute screen coordinates)
    control.state.projectListBounds = {
        x = panelX + listX,
        y = panelY + listY,
        w = listW,
        h = math.min(listH, count)
    }
    
    -- Show message if no projects
    if count == 0 then
        local msgY = math.floor(panelH / 2)
        local noProjectsLabel = components.createLabel("noProjects", listX, msgY, "No projects created")
        listPanel:addChild(noProjectsLabel)
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

-- ========== PROJECT CONTROL SCREEN ==========

function control.showProjectControl()
    if not control.state.selectedProject then
        control.showProjectList()
        return
    end
    
    control.state.currentScreen = "projectControl"
    term.clear()
    term.setCursorPos(1, 1)
    gui.clearComponents()
    gui.clear()
    
    local project = control.state.selectedProject
    local w, h = layouts.getScreenSize()
    local isPocket = (w < 40)
    
    -- Get linked turtles
    local linkedTurtles = coordinator.getProjectTurtles(project.id)
    local turtleCount = 0
    for _ in pairs(linkedTurtles) do
        turtleCount = turtleCount + 1
    end
    local maxZones = zoneAllocator.getMaxZones(project)
    
    -- Title with project name
    gui.centerText(project.name, 1, gui.getColor("primary"), colors.white)
    
    if isPocket then
        -- Pocket computer layout
        local btnW = w - 4
        local btnX = 2
        local currentY = 3
        
        -- Status indicator
        local statusColor = project.status == "active" and colors.green or 
                           project.status == "paused" and colors.orange or colors.gray
        term.setCursorPos(2, currentY)
        term.setBackgroundColor(colors.black)
        term.setTextColor(statusColor)
        term.write(project.status:upper())
        term.setTextColor(colors.white)
        term.write(string.format(" | %d/%d turtles", turtleCount, maxZones))
        currentY = currentY + 2
        
        -- Show linked turtles (compact)
        if turtleCount > 0 then
            for id, turtle in pairs(linkedTurtles) do
                if currentY < 8 then
                    local statusChar = turtle.status == "working" and "W" or 
                                      turtle.status == "assigned" and "A" or "?"
                    term.setCursorPos(2, currentY)
                    term.write(string.format("[Z%d] %s (%s)", 
                        turtle.zone or 0, 
                        (turtle.label or "T"..id):sub(1,8), 
                        statusChar))
                    currentY = currentY + 1
                end
            end
        else
            term.setCursorPos(2, currentY)
            term.setTextColor(colors.gray)
            term.write("No turtles linked")
            term.setTextColor(colors.white)
        end
        currentY = currentY + 1
        
        -- Link Turtle button
        if turtleCount < maxZones then
            local linkBtn = components.createButton("link", btnX, currentY, btnW, 2, "+ Link Turtle",
                function() control.showLinkTurtlePicker() end)
            linkBtn.bgColor = gui.getColor("primary")
            currentY = currentY + 3
        else
            currentY = currentY + 1
        end
        
        -- Start/Pause button (only if turtles linked)
        if turtleCount > 0 then
            if project.status == "active" then
                local pauseBtn = components.createButton("pause", btnX, currentY, btnW, 2, "Pause",
                    function()
                        projectManager.pause(project.id)
                        control.state.selectedProject.status = "paused"
                        control.showProjectControl()
                    end)
                pauseBtn.bgColor = gui.getColor("warning")
            else
                local startBtn = components.createButton("start", btnX, currentY, btnW, 2, "Start",
                    function()
                        local success, err = coordinator.startProject(project.id)
                        if success then
                            control.state.selectedProject.status = "active"
                            gui.notify("Started!", colors.white, colors.green, 1)
                        else
                            gui.notify(err or "Failed", colors.white, colors.red, 2)
                        end
                        control.showProjectControl()
                    end)
                startBtn.bgColor = gui.getColor("success")
            end
            currentY = currentY + 3
        end
        
        -- Bottom buttons (two rows)
        local halfW = math.floor((w - 5) / 2)
        local btnY = h - 5
        
        local detailsBtn = components.createButton("details", btnX, btnY, halfW, 2, "Details",
            function() control.showProjectDetail() end)
        
        local deleteBtn = components.createButton("delete", btnX + halfW + 1, btnY, halfW, 2, "Delete",
            function()
                projectManager.delete(project.id)
                control.showProjectList()
            end)
        deleteBtn.bgColor = gui.getColor("error")
        
        local backBtn = components.createButton("back", btnX, h - 2, btnW, 2, "Back",
            function() control.showProjectList() end)
        
        gui.draw()
        return
    end
    
    -- Regular computer layout
    -- Left side: Status and turtles
    local leftPanel = components.createPanel("status", 2, 3, 25, 10, "Status")
    leftPanel.borderColor = gui.getColor("border")
    
    -- Status
    local statusColor = project.status == "active" and colors.green or 
                       project.status == "paused" and colors.orange or colors.gray
    term.setCursorPos(4, 5)
    term.setBackgroundColor(colors.black)
    term.setTextColor(statusColor)
    term.write(project.status:upper())
    term.setTextColor(colors.white)
    
    -- Turtle count
    term.setCursorPos(4, 6)
    term.write(string.format("Turtles: %d/%d", turtleCount, maxZones))
    
    -- List linked turtles
    local turtleY = 8
    for id, turtle in pairs(linkedTurtles) do
        if turtleY < 12 then
            local statusChar = turtle.status == "working" and "W" or 
                              turtle.status == "assigned" and "A" or "?"
            term.setCursorPos(4, turtleY)
            term.write(string.format("[Z%d] %s (%s)", 
                turtle.zone or 0, 
                (turtle.label or "Turtle-"..id):sub(1,10), 
                statusChar))
            turtleY = turtleY + 1
        end
    end
    
    if turtleCount == 0 then
        term.setCursorPos(4, 8)
        term.setTextColor(colors.gray)
        term.write("No turtles linked")
        term.setTextColor(colors.white)
    end
    
    -- Right side: Actions
    local rightPanel = components.createPanel("actions", 28, 3, 21, 10, "Actions")
    rightPanel.borderColor = gui.getColor("border")
    
    local btnX = 30
    local btnW = 17
    local currentY = 5
    
    -- Link Turtle button
    if turtleCount < maxZones then
        local linkBtn = components.createButton("link", btnX, currentY, btnW, 2, "+ Link Turtle",
            function() control.showLinkTurtlePicker() end)
        linkBtn.bgColor = gui.getColor("primary")
        currentY = currentY + 3
    end
    
    -- Start/Pause button
    if turtleCount > 0 then
        if project.status == "active" then
            local pauseBtn = components.createButton("pause", btnX, currentY, btnW, 2, "Pause",
                function()
                    projectManager.pause(project.id)
                    control.state.selectedProject.status = "paused"
                    control.showProjectControl()
                end)
            pauseBtn.bgColor = gui.getColor("warning")
        else
            local startBtn = components.createButton("start", btnX, currentY, btnW, 2, "Start Project",
                function()
                    local success, err = coordinator.startProject(project.id)
                    if success then
                        control.state.selectedProject.status = "active"
                        gui.notify("Project started!", colors.white, colors.green, 2)
                    else
                        gui.notify(err or "Failed to start", colors.white, colors.red, 2)
                    end
                    control.showProjectControl()
                end)
            startBtn.bgColor = gui.getColor("success")
        end
    end
    
    -- Bottom buttons
    local detailsBtn = components.createButton("details", 4, 14, 13, 2, "Details",
        function() control.showProjectDetail() end)
    
    local deleteBtn = components.createButton("delete", 18, 14, 13, 2, "Delete",
        function()
            projectManager.delete(project.id)
            gui.notify("Deleted", colors.white, colors.red, 2)
            control.showProjectList()
        end)
    deleteBtn.bgColor = gui.getColor("error")
    
    local backBtn = components.createButton("back", 32, 14, 13, 2, "Back",
        function() control.showProjectList() end)
    
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
    local w, h = layouts.getScreenSize()
    local isPocket = (w < 40)
    
    -- Title
    gui.centerText("Project Details", 1, gui.getColor("primary"), colors.white)
    
    if isPocket then
        -- Pocket computer layout - Info focused
        local panelW = w - 2
        
        -- Info Panel (compact)
        local infoPanel = components.createPanel("info", 1, 3, panelW, 10, project.name)
        infoPanel.borderColor = gui.getColor("border")
        
        -- Shorten type name
        local typeShort = project.type:gsub("_mine", ""):gsub("branch", "Branch"):gsub("quarry", "Quarry"):gsub("strip", "Strip")
        components.createLabel("type", 3, 5, "Type: " .. typeShort)
        components.createLabel("status", 3, 6, "Status: " .. project.status)
        components.createLabel("blocks", 3, 7, "Blocks: " .. project.progress.blocksCleared)
        components.createLabel("ore", 3, 8, "Ore: " .. project.progress.oreFound)
        components.createLabel("progress", 3, 9, "Progress: " .. project.progress.completion .. "%")
        
        -- Assigned Turtles
        local turtleCount = 0
        for _ in pairs(project.assignedTurtles) do
            turtleCount = turtleCount + 1
        end
        components.createLabel("turtles", 3, 10, "Turtles: " .. turtleCount)
        
        -- Config info if branch mine
        if project.config and project.config.mainTunnelLength then
            components.createLabel("config", 3, 11, "Main: " .. project.config.mainTunnelLength .. " Side: " .. (project.config.sideTunnelLength or "?"))
        end
        
        -- Back button
        local backBtn = components.createButton("back", 2, h - 2, w - 3, 2, "Back",
            function() control.showProjectControl() end)
        
        gui.draw()
        return
    end
    
    -- Regular computer layout - Info focused
    -- Info Panel
    local infoPanel = components.createPanel("info", 2, 3, 47, 12, project.name)
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
    
    -- Config info
    if project.config then
        local configStr = ""
        if project.config.mainTunnelLength then
            configStr = "Main: " .. project.config.mainTunnelLength .. ", Side: " .. (project.config.sideTunnelLength or "?")
        end
        if project.config.placeTorches then
            configStr = configStr .. ", Torches: Yes"
        end
        if #configStr > 0 then
            components.createLabel("config", 4, 13, configStr)
        end
    end
    
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
        
        local currentY = formY + 6
        
        -- Branch Mine specific fields
        local mainInput, sideInput, torchCheck, wallCheck
        if selectedType == "branch_mine" then
            components.createLabel("mainLbl", formX, currentY, "Main Length:")
            mainInput = components.createTextInput("main", formX + 13, currentY, 6, "64")
            currentY = currentY + 1
            
            components.createLabel("sideLbl", formX, currentY, "Side Length:")
            sideInput = components.createTextInput("side", formX + 13, currentY, 6, "32")
            currentY = currentY + 2
            
            -- Branch Mine options
            torchCheck = components.createCheckbox("torch", formX, currentY, "Torch", true)
            currentY = currentY + 1
            wallCheck = components.createCheckbox("wall", formX, currentY, "Wall Protect", true)
            currentY = currentY + 2
        else
            currentY = currentY + 1
        end
        
        -- Starting Y Position (depth)
        components.createLabel("yLbl", formX, currentY, "Start Y:")
        local yInput = components.createTextInput("y", formX + 9, currentY, 6, "11")
        
        -- Buttons
        local btnW = math.floor((w - 5) / 2)
        local btnY = h - 2
        
        local createBtn = components.createButton("create", 2, btnY, btnW, 2, "Create",
            function()
                local name = nameInput.value ~= "" and nameInput.value or "New Project"
                
                local config = {}
                
                -- Add branch mine specific config
                if selectedType == "branch_mine" then
                    config.mainTunnelLength = tonumber(mainInput.value) or 64
                    config.sideTunnelLength = tonumber(sideInput.value) or 32
                    config.placeTorches = torchCheck.checked
                    config.wallProtection = wallCheck.checked
                end
                
                -- Starting position with Y depth (X and Z will be set by turtle)
                local startPos = {
                    y = tonumber(yInput.value) or 11
                }
                
                local projectId, project = projectManager.create(selectedType, name, config, startPos)
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
    
    -- Branch Mine Dimensions (only for type 1)
    components.createLabel("branchNote", formX, formY + 7, "(Branch Mine settings below)")
    components.createLabel("mainLbl", formX, formY + 8, "Main Tunnel Length:")
    local mainInput = components.createTextInput("main", formX + 20, formY + 8, 8, "64")
    
    components.createLabel("sideLbl", formX, formY + 9, "Side Tunnel Length:")
    local sideInput = components.createTextInput("side", formX + 20, formY + 9, 8, "32")
    
    -- Branch Mine Options (only for type 1)
    components.createLabel("optLbl", formX, formY + 11, "Branch Mine Options:")
    local torchCheck = components.createCheckbox("torch", formX + 2, formY + 12, "Place Torches", true)
    local wallCheck = components.createCheckbox("wall", formX + 2, formY + 13, "Wall Protection", true)
    
    -- Starting Y Position (depth)
    components.createLabel("yLbl", formX, formY + 15, "Starting Y (Depth):")
    local yInput = components.createTextInput("y", formX + 20, formY + 15, 6, "11")
    
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
            
            local config = {}
            
            -- Only add branch mine config if type is 1 (branch_mine)
            if typeInput.value == "1" then
                config.mainTunnelLength = tonumber(mainInput.value) or 64
                config.sideTunnelLength = tonumber(sideInput.value) or 32
                config.placeTorches = torchCheck.checked
                config.wallProtection = wallCheck.checked
            end
            
            -- Starting position with Y depth (X and Z will be set by turtle)
            local startPos = {
                y = tonumber(yInput.value) or 11
            }
            
            local projectId, project = projectManager.create(projectType, name, config, startPos)
            gui.notify("Project created: " .. name, colors.white, colors.green, 2)
            
            control.showProjectList()
        end)
    createBtn.bgColor = gui.getColor("success")
    
    local cancelBtn = components.createButton("cancel", formX + 17, h - 3, 15, 2, "Cancel",
        function() control.showProjectList() end)
    
    gui.draw()
end

-- ========== LINK TURTLE PICKER SCREEN ==========

function control.showLinkTurtlePicker()
    if not control.state.selectedProject then
        control.showProjectList()
        return
    end
    
    control.state.currentScreen = "linkTurtle"
    term.clear()
    term.setCursorPos(1, 1)
    gui.clearComponents()
    gui.clear()
    
    local project = control.state.selectedProject
    local w, h = layouts.getScreenSize()
    local isPocket = (w < 40)
    
    -- Title
    gui.centerText("Link Turtle", 1, gui.getColor("primary"), colors.white)
    
    -- Get idle turtles
    local idleTurtles = coordinator.getIdleTurtles()
    local count = 0
    
    -- Store for click detection
    control.state.linkTurtleItems = {}
    
    if isPocket then
        -- Pocket layout
        term.setCursorPos(2, 3)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.yellow)
        term.write("To: " .. project.name:sub(1, 16))
        term.setTextColor(colors.white)
        
        local listY = 5
        control.state.linkTurtleBounds = {
            x = 2, y = listY, w = w - 3, h = 0
        }
        
        for id, turtle in pairs(idleTurtles) do
            if listY < h - 4 then
                term.setCursorPos(2, listY)
                term.setTextColor(colors.green)
                term.write("[I]")
                term.setTextColor(colors.white)
                term.write(" " .. (turtle.label or "Turtle-"..id):sub(1, 15))
                
                table.insert(control.state.linkTurtleItems, turtle)
                listY = listY + 1
                count = count + 1
            end
        end
        
        control.state.linkTurtleBounds.h = count
        
        if count == 0 then
            term.setCursorPos(2, 6)
            term.setTextColor(colors.gray)
            term.write("No idle turtles")
            term.setCursorPos(2, 7)
            term.write("available to link")
            term.setTextColor(colors.white)
        end
        
        -- Back button
        local backBtn = components.createButton("back", 2, h - 2, w - 3, 2, "Cancel",
            function() control.showProjectControl() end)
        
        gui.draw()
        return
    end
    
    -- Regular computer layout
    local listPanel = components.createPanel("list", 2, 3, 47, 13, "Available Turtles (Idle)")
    listPanel.borderColor = gui.getColor("border")
    
    term.setCursorPos(4, 4)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.yellow)
    term.write("Linking to: " .. project.name)
    term.setTextColor(colors.white)
    
    local listY = 6
    control.state.linkTurtleBounds = {
        x = 4, y = listY, w = 43, h = 0
    }
    
    for id, turtle in pairs(idleTurtles) do
        if listY < 14 then
            term.setCursorPos(4, listY)
            term.setTextColor(colors.green)
            term.write("[IDLE]")
            term.setTextColor(colors.white)
            term.write(string.format(" %s (ID:%d, Fuel:%d)", 
                (turtle.label or "Turtle"):sub(1, 15), id, turtle.fuel))
            
            table.insert(control.state.linkTurtleItems, turtle)
            listY = listY + 1
            count = count + 1
        end
    end
    
    control.state.linkTurtleBounds.h = count
    
    if count == 0 then
        term.setCursorPos(4, 8)
        term.setTextColor(colors.gray)
        term.write("No idle turtles available to link")
        term.setCursorPos(4, 9)
        term.write("Turtles must be online and not assigned")
        term.setTextColor(colors.white)
    end
    
    -- Back button
    local backBtn = components.createButton("back", 19, 17, 13, 2, "Cancel",
        function() control.showProjectControl() end)
    
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
                    local x, y = p2, p3
                    
                    -- Check if clicked on type button (in Create Project screen)
                    if control.state.typeButtons and control.state.currentScreen == "create_project" then
                        for _, btn in ipairs(control.state.typeButtons) do
                            if y == btn.y and x >= btn.x1 and x <= btn.x2 then
                                -- Update selection and redraw
                                control.state.selectedType = btn.type
                                control.showCreateProject()
                                break
                            end
                        end
                    end
                    
                    -- Check if clicked on project list
                    if control.state.currentScreen == "projects" and control.state.projectListBounds then
                        local bounds = control.state.projectListBounds
                        if x >= bounds.x and x < bounds.x + bounds.w and
                           y >= bounds.y and y < bounds.y + bounds.h then
                            -- Calculate which item was clicked
                            local itemIndex = y - bounds.y + 1
                            local projectList = control.state.projectListItems
                            if projectList and projectList[itemIndex] then
                                control.state.selectedProject = projectList[itemIndex]
                                control.showProjectControl()  -- Go to control screen first
                            end
                        end
                    end
                    
                    -- Check if clicked on turtle list
                    if control.state.currentScreen == "turtles" and control.state.turtleListBounds then
                        local bounds = control.state.turtleListBounds
                        if x >= bounds.x and x < bounds.x + bounds.w and
                           y >= bounds.y and y < bounds.y + bounds.h then
                            -- Calculate which item was clicked
                            local itemIndex = y - bounds.y + 1
                            local turtleList = control.state.turtleListItems
                            if turtleList and turtleList[itemIndex] then
                                control.state.selectedTurtle = turtleList[itemIndex]
                                control.showTurtleDetail()
                            end
                        end
                    end
                    
                    -- Check if clicked on link turtle picker
                    if control.state.currentScreen == "linkTurtle" and control.state.linkTurtleBounds then
                        local bounds = control.state.linkTurtleBounds
                        if x >= bounds.x and x < bounds.x + bounds.w and
                           y >= bounds.y and y < bounds.y + bounds.h then
                            local itemIndex = y - bounds.y + 1
                            local turtleList = control.state.linkTurtleItems
                            if turtleList and turtleList[itemIndex] then
                                local turtle = turtleList[itemIndex]
                                local project = control.state.selectedProject
                                local success, zoneOrErr = coordinator.linkTurtleToProject(turtle.id, project.id)
                                if success then
                                    gui.notify("Linked to zone " .. zoneOrErr, colors.white, colors.green, 2)
                                else
                                    gui.notify(zoneOrErr or "Failed", colors.white, colors.red, 2)
                                end
                                control.showProjectControl()
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
                    -- Pass key events to GUI for text input
                    local handled = gui.handleKey(p1)
                    gui.draw()
                elseif event == "char" then
                    -- Pass character events to GUI for text input
                    local handled = gui.handleChar(p1)
                    gui.draw()
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
