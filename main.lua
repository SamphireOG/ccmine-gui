-- CCMine - Main Application
-- Example mining control application using the GUI framework

local gui = require("gui-core")
local components = require("gui-components")
local layouts = require("gui-layouts")

local app = {}

-- ========== STATE ==========

app.state = {
    currentScreen = "main",
    mining = false,
    position = {x = 0, y = 0, z = 0, facing = 0},
    fuel = 5000,
    maxFuel = 20000,
    inventory = 0,
    maxInventory = 16
}

-- ========== SCREENS ==========

function app.createMainScreen()
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
    local manualBtn = components.createButton("manual", 2, regions.footer.y, 15, 2, "Manual Control",
        function()
            app.showManualScreen()
        end)
    
    local statsBtn = components.createButton("stats", 18, regions.footer.y, 15, 2, "Statistics",
        function()
            app.showStatsScreen()
        end)
    
    local exitBtn = components.createButton("exit", 34, regions.footer.y, 15, 2, "Exit",
        function()
            app.exit()
        end)
    exitBtn.bgColor = gui.getColor("error")
    
    gui.draw()
end

function app.showConfigScreen()
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
    print("CCMine exited. Thank you!")
end

-- ========== MAIN ==========

function app.run()
    -- Initialize
    gui.init()
    gui.setTheme("default")
    
    -- Show main screen
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

