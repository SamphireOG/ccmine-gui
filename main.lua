-- CCMine - Main Application
-- Example mining control application using the GUI framework

local gui = require("gui-core")
local components = require("gui-components")
local layouts = require("gui-layouts")
local client = require("turtle-client")

local app = {}

-- ========== STATE ==========

app.state = {
    currentScreen = "main",
    mining = false,
    position = {x = 0, y = 0, z = 0, facing = 0},
    fuel = 5000,
    maxFuel = 20000,
    inventory = 0,
    maxInventory = 16,
    networkEnabled = false,
    networkStatus = nil
}

-- ========== SCREENS ==========

function app.createMainScreen()
    app.state.currentScreen = "main"
    gui.clearComponents()
    
    -- Create layout regions
    local regions = layouts.createRegions({
        header = 3,
        footer = 3
    })
    
    -- Header
    local header = components.createPanel("header",
        regions.header.x, regions.header.y,
        regions.header.width, regions.header.height,
        "CCMine Control System v2.0")
    header.titleBgColor = gui.getColor("primary")
    
    -- Status Panel
    local statusPanel = components.createPanel("status", 2, 5, 47, 8, "Status")
    statusPanel.borderColor = gui.getColor("border")
    
    -- Status Labels
    local statusLabel = components.createLabel("statusText", 4, 7,
        app.state.mining and "Status: MINING" or "Status: IDLE")
    statusLabel.fgColor = app.state.mining and gui.getColor("success") or gui.getColor("warning")
    
    -- Network Status Indicator
    if app.state.networkEnabled then
        local netStatus = app.state.networkStatus or {}
        local netLabel = components.createLabel("netStatus", 35, 7,
            netStatus.connected and "[NET: ON]" or "[NET: OFF]")
        netLabel.fgColor = netStatus.connected and gui.getColor("success") or gui.getColor("error")
    end
    
    local posLabel = components.createLabel("position", 4, 8,
        string.format("Position: X:%d Y:%d Z:%d", 
            app.state.position.x, app.state.position.y, app.state.position.z))
    
    -- Fuel Progress
    local fuelLabel = components.createLabel("fuelLabel", 4, 10, "Fuel:")
    local fuelPercent = math.floor((app.state.fuel / app.state.maxFuel) * 100)
    local fuelBar = components.createProgressBar("fuelBar", 10, 10, 37)
    fuelBar.value = fuelPercent
    fuelBar.fillColor = fuelPercent > 50 and gui.getColor("success") or 
                        fuelPercent > 20 and gui.getColor("warning") or 
                        gui.getColor("error")
    
    -- Inventory Progress
    local invLabel = components.createLabel("invLabel", 4, 11, "Inv:")
    local invPercent = math.floor((app.state.inventory / app.state.maxInventory) * 100)
    local invBar = components.createProgressBar("invBar", 10, 11, 37)
    invBar.value = invPercent
    
    -- Control Buttons
    local startBtn = components.createButton("start", 5, 14, 18, 3, 
        app.state.mining and "STOP MINING" or "START MINING",
        function()
            app.toggleMining()
        end)
    startBtn.bgColor = app.state.mining and gui.getColor("error") or gui.getColor("success")
    
    local configBtn = components.createButton("config", 27, 14, 18, 3, "CONFIGURE",
        function()
            app.showConfigScreen()
        end)
    configBtn.bgColor = gui.getColor("primary")
    
    -- Footer buttons
    local manualBtn = components.createButton("manual", 2, regions.footer.y, 11, 2, "Manual",
        function()
            app.showManualScreen()
        end)
    
    local statsBtn = components.createButton("stats", 14, regions.footer.y, 11, 2, "Stats",
        function()
            app.showStatsScreen()
        end)
    
    local networkBtn = components.createButton("network", 26, regions.footer.y, 11, 2, "Network",
        function()
            app.showNetworkScreen()
        end)
    networkBtn.bgColor = app.state.networkEnabled and gui.getColor("primary") or colors.gray
    
    local exitBtn = components.createButton("exit", 38, regions.footer.y, 11, 2, "Exit",
        function()
            app.exit()
        end)
    exitBtn.bgColor = gui.getColor("error")
    
    gui.draw()
end

function app.showConfigScreen()
    app.state.currentScreen = "config"
    gui.clearComponents()
    
    -- Title
    gui.centerText("Mining Configuration", 1, gui.getColor("primary"), colors.white)
    
    -- Config Panel
    local panel = components.createPanel("configPanel", 5, 3, 41, 13, "Settings")
    panel.borderColor = gui.getColor("border")
    
    -- Branch Length
    local lengthLabel = components.createLabel("lengthLbl", 7, 5, "Branch Length:")
    local lengthInput = components.createTextInput("lengthInput", 22, 5, 18, "32")
    lengthInput.value = "32"
    
    -- Branch Width
    local widthLabel = components.createLabel("widthLbl", 7, 7, "Branch Width:")
    local widthInput = components.createTextInput("widthInput", 22, 7, 18, "3")
    widthInput.value = "3"
    
    -- Spacing
    local spacingLabel = components.createLabel("spacingLbl", 7, 9, "Branch Spacing:")
    local spacingInput = components.createTextInput("spacingInput", 22, 9, 18, "4")
    spacingInput.value = "4"
    
    -- Options
    local torchCheck = components.createCheckbox("torches", 7, 11, "Place torches", true)
    local refuelCheck = components.createCheckbox("refuel", 7, 12, "Auto-refuel", true)
    local returnCheck = components.createCheckbox("return", 7, 13, "Return when full", true)
    
    -- Buttons
    local saveBtn = components.createButton("save", 5, 17, 18, 2, "Save & Return",
        function()
            print("Configuration saved!")
            app.createMainScreen()
        end)
    saveBtn.bgColor = gui.getColor("success")
    
    local cancelBtn = components.createButton("cancel", 27, 17, 18, 2, "Cancel",
        function()
            app.createMainScreen()
        end)
    
    gui.draw()
end

function app.showManualScreen()
    app.state.currentScreen = "manual"
    gui.clearComponents()
    
    -- Title
    gui.centerText("Manual Control", 1, gui.getColor("primary"), colors.white)
    
    -- Control Panel
    local panel = components.createPanel("manual", 5, 3, 41, 14, "Turtle Controls")
    panel.borderColor = gui.getColor("border")
    
    -- Movement buttons (grid layout)
    local upBtn = components.createButton("up", 20, 5, 10, 2, "UP", function()
        print("Moving up...")
        app.state.position.y = app.state.position.y + 1
        app.updateDisplay()
    end)
    
    local forwardBtn = components.createButton("fwd", 20, 8, 10, 2, "FORWARD", function()
        print("Moving forward...")
        app.state.position.z = app.state.position.z + 1
        app.updateDisplay()
    end)
    
    local backBtn = components.createButton("back", 20, 11, 10, 2, "BACK", function()
        print("Moving back...")
        app.state.position.z = app.state.position.z - 1
        app.updateDisplay()
    end)
    
    local downBtn = components.createButton("down", 20, 14, 10, 2, "DOWN", function()
        print("Moving down...")
        app.state.position.y = app.state.position.y - 1
        app.updateDisplay()
    end)
    
    -- Rotation buttons
    local leftBtn = components.createButton("left", 8, 8, 10, 2, "< LEFT", function()
        print("Turning left...")
    end)
    
    local rightBtn = components.createButton("right", 32, 8, 10, 2, "RIGHT >", function()
        print("Turning right...")
    end)
    
    -- Action buttons
    local digBtn = components.createButton("dig", 8, 11, 10, 2, "DIG", function()
        print("Digging...")
    end)
    digBtn.bgColor = gui.getColor("warning")
    
    local placeBtn = components.createButton("place", 32, 11, 10, 2, "PLACE", function()
        print("Placing...")
    end)
    placeBtn.bgColor = gui.getColor("success")
    
    -- Back button
    local returnBtn = components.createButton("return", 15, 17, 20, 2, "Return to Main",
        function()
            app.createMainScreen()
        end)
    
    gui.draw()
end

function app.showStatsScreen()
    app.state.currentScreen = "stats"
    gui.clearComponents()
    
    -- Title
    gui.centerText("Mining Statistics", 1, gui.getColor("primary"), colors.white)
    
    -- Stats Panel
    local panel = components.createPanel("stats", 5, 3, 41, 12, "Performance")
    panel.borderColor = gui.getColor("border")
    
    -- Stats list
    local statsList = components.createList("statsList", 7, 5, 37, 8)
    statsList:addItem("Blocks Mined: 1,234", {})
    statsList:addItem("Ore Found: 87", {})
    statsList:addItem("Fuel Used: 15,000", {})
    statsList:addItem("Runtime: 2h 34m", {})
    statsList:addItem("Distance Traveled: 456m", {})
    statsList:addItem("Efficiency: 92%", {})
    
    -- Back button
    local backBtn = components.createButton("back", 15, 16, 20, 2, "Back",
        function()
            app.createMainScreen()
        end)
    
    gui.draw()
end

function app.showNetworkScreen()
    app.state.currentScreen = "network"
    gui.clearComponents()
    
    -- Title
    gui.centerText("Network Status", 1, gui.getColor("primary"), colors.white)
    
    local status = app.state.networkStatus or {}
    
    -- Connection Panel
    local connPanel = components.createPanel("conn", 2, 3, 47, 7, "Connection")
    connPanel.borderColor = gui.getColor("border")
    
    local connLabel = components.createLabel("connStatus", 4, 5,
        status.connected and "Status: Connected to Coordinator" or "Status: Disconnected")
    connLabel.fgColor = status.connected and gui.getColor("success") or gui.getColor("error")
    
    local idLabel = components.createLabel("id", 4, 6,
        string.format("Turtle ID: %d", os.getComputerID()))
    
    local labelText = os.getComputerLabel() or "Unlabeled"
    local labelLabel = components.createLabel("label", 4, 7,
        string.format("Label: %s", labelText))
    
    if status.coordinatorId then
        local coordLabel = components.createLabel("coord", 4, 8,
            string.format("Coordinator: %d", status.coordinatorId))
    end
    
    -- Project Panel
    if status.currentProject then
        local projPanel = components.createPanel("proj", 2, 11, 47, 8, "Current Project")
        projPanel.borderColor = gui.getColor("border")
        
        local projName = components.createLabel("projName", 4, 13,
            "Project: " .. (status.currentProject.name or "Unknown"))
        
        local projType = components.createLabel("projType", 4, 14,
            "Type: " .. (status.currentProject.type or "Unknown"))
        
        if status.assignment then
            local zoneLabel = components.createLabel("zone", 4, 15,
                string.format("Zone: %d", status.assignment.zone or 0))
            
            local instrLabel = components.createLabel("instr", 4, 16,
                status.assignment.instructions or "No instructions")
        end
        
        -- Peers List
        if status.peers and #status.peers > 0 then
            local peerLabel = components.createLabel("peerLbl", 4, 17,
                string.format("Other Turtles: %d", #status.peers))
        end
    else
        local noProjLabel = components.createLabel("noProj", 4, 12,
            "No project assigned")
        noProjLabel.fgColor = colors.gray
    end
    
    -- Control Buttons
    local btnY = 17
    if not status.currentProject then
        btnY = 14
    end
    
    if not app.state.networkEnabled then
        local enableBtn = components.createButton("enable", 5, btnY, 18, 2, "Enable Network",
            function()
                app.enableNetwork()
            end)
        enableBtn.bgColor = gui.getColor("success")
    else
        local refreshBtn = components.createButton("refresh", 5, btnY, 18, 2, "Refresh Status",
            function()
                app.refreshNetworkStatus()
            end)
        refreshBtn.bgColor = gui.getColor("primary")
    end
    
    -- Back button
    local backBtn = components.createButton("back", 27, btnY, 18, 2, "Back",
        function()
            app.createMainScreen()
        end)
    
    gui.draw()
end

-- ========== ACTIONS ==========

function app.toggleMining()
    app.state.mining = not app.state.mining
    print(app.state.mining and "Mining started!" or "Mining stopped!")
    
    -- Simulate mining with a timer
    if app.state.mining then
        app.simulateMining()
    end
    
    app.createMainScreen()
end

function app.simulateMining()
    -- This would be replaced with actual mining logic
    -- For demo, just update some values
    if app.state.mining then
        app.state.fuel = math.max(0, app.state.fuel - 10)
        app.state.inventory = math.min(app.state.maxInventory, app.state.inventory + 1)
        app.updateDisplay()
    end
end

function app.updateDisplay()
    -- Refresh the current screen
    if app.state.currentScreen == "main" then
        app.createMainScreen()
    end
end

function app.exit()
    gui.clearComponents()
    gui.clear()
    
    -- Close network if enabled
    if app.state.networkEnabled then
        client.close()
    end
    
    print("CCMine exited. Thank you!")
end

-- ========== NETWORK FUNCTIONS ==========

function app.enableNetwork()
    print("Enabling network...")
    
    local success = client.init(os.getComputerLabel())
    
    if success then
        app.state.networkEnabled = true
        app.refreshNetworkStatus()
        print("Network enabled!")
        
        -- Start background service in parallel
        -- Note: This would need proper parallel handling in production
    else
        print("Failed to enable network!")
    end
    
    app.showNetworkScreen()
end

function app.refreshNetworkStatus()
    if not app.state.networkEnabled then
        return
    end
    
    app.state.networkStatus = client.getStatus()
    
    if app.state.currentScreen == "main" then
        app.createMainScreen()
    elseif app.state.currentScreen == "network" then
        app.showNetworkScreen()
    end
end

-- ========== MAIN ==========

function app.run()
    -- Initialize
    gui.init()
    gui.setTheme("default")
    
    -- Try to auto-enable network if modem available
    local modem = peripheral.find("modem")
    if modem then
        print("Modem detected. Network available.")
        -- Don't auto-enable, let user choose
    end
    
    -- Show main screen
    app.state.currentScreen = "main"
    app.createMainScreen()
    
    -- Event loop
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
            app.updateDisplay()
        elseif event == "key" then
            if p1 == keys.q and keys.leftCtrl then
                app.exit()
                break
            end
        end
        
        -- Simulate mining updates (in real app, use os.startTimer)
        if app.state.mining and math.random() < 0.1 then
            app.simulateMining()
        end
    end
end

-- Auto-run if executed directly
if not ... then
    app.run()
end

return app

