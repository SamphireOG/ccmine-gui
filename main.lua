-- CCMine Turtle Interface
-- Turtle-specific GUI with mining controls and network features

local gui = require("gui-core")
local components = require("gui-components")
local layouts = require("gui-layouts")

local app = {}
local client = nil  -- Load lazily when needed

-- Check if running on a turtle
if not turtle then
    error("This program must be run on a turtle!")
end

-- Load client module when needed
local function getClient()
    if not client then
        local success, result = pcall(require, "turtle-client")
        if success then
            client = result
        else
            print("Warning: turtle-client not available")
            print(result)
        end
    end
    return client
end

-- ========== STATE ==========

app.state = {
    currentScreen = "main",
    mining = false,
    position = {x = 0, y = 0, z = 0, facing = 0},
    fuel = turtle.getFuelLevel(),
    maxFuel = turtle.getFuelLimit(),
    inventory = 0,
    maxInventory = 16,
    networkEnabled = false,
    networkStatus = nil,
    targetPos = nil
}

-- ========== TURTLE FUNCTIONS ==========

function app.updateTurtleInfo()
    app.state.fuel = turtle.getFuelLevel()
    
    -- Count inventory slots used
    local used = 0
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            used = used + 1
        end
    end
    app.state.inventory = used
    
    -- Try to get GPS position
    if app.state.networkEnabled then
        local c = getClient()
        if c then
            app.state.position = c.getPosition()
        end
    end
end

function app.refuelFromSlot(slot)
    turtle.select(slot)
    if turtle.refuel() then
        gui.notify("Refueled!", colors.white, gui.getColor("success"), 2)
        app.updateTurtleInfo()
        return true
    else
        gui.notify("Not fuel!", colors.white, gui.getColor("error"), 2)
        return false
    end
end

-- ========== MAIN SCREEN ==========

function app.createMainScreen()
    app.state.currentScreen = "main"
    gui.clearComponents()
    
    app.updateTurtleInfo()
    
    -- Get screen dimensions using responsive helper
    local w, h = layouts.getScreenSize()
    
    -- Create layout regions
    local regions = layouts.createRegions({
        header = 3,
        footer = 3
    })
    
    -- Header
    local turtleLabel = os.getComputerLabel() or ("Turtle-" .. os.getComputerID())
    local header = components.createPanel("header",
        regions.header.x, regions.header.y,
        regions.header.width, regions.header.height,
        turtleLabel)
    header.titleBgColor = gui.getColor("primary")
    
    -- Status Panel (responsive using helper)
    local statusPanel = layouts.createFullWidthPanel("status", 5, 8, "Turtle Status")
    statusPanel.borderColor = gui.getColor("border")
    
    -- Fuel Bar (responsive)
    local fuelLabel = components.createLabel("fuelLabel", 2, 7, "Fuel:")
    local fuelPercent = math.floor((app.state.fuel / app.state.maxFuel) * 100)
    local fuelBar = components.createProgressBar("fuelBar", 8, 7, w - 10)
    fuelBar.value = fuelPercent
    fuelBar.fillColor = fuelPercent > 50 and gui.getColor("success") or 
                        fuelPercent > 20 and gui.getColor("warning") or 
                        gui.getColor("error")
    
    -- Inventory Bar (responsive)
    local invLabel = components.createLabel("invLabel", 2, 8, "Inv:")
    local invPercent = math.floor((app.state.inventory / app.state.maxInventory) * 100)
    local invBar = components.createProgressBar("invBar", 8, 8, w - 10)
    invBar.value = invPercent
    
    -- Position
    local posLabel = components.createLabel("position", 2, 10,
        string.format("X:%d Y:%d Z:%d", 
            app.state.position.x, app.state.position.y, app.state.position.z))
    
    -- Status
    local statusText = app.state.mining and "MINING" or "IDLE"
    local statusLabel = components.createLabel("statusText", 2, 11, "Status: " .. statusText)
    statusLabel.fgColor = app.state.mining and gui.getColor("success") or gui.getColor("warning")
    
    -- Network Status (only if enough space)
    if app.state.networkEnabled and w >= 39 then
        local netStatus = app.state.networkStatus or {}
        local netLabel = components.createLabel("netStatus", w - 10, 11,
            netStatus.connected and "[NET:ON]" or "[NET:OFF]")
        netLabel.fgColor = netStatus.connected and gui.getColor("success") or gui.getColor("error")
    end
    
    -- Footer buttons using responsive helper
    local _, positions = layouts.calculateButtonRow(4, 1, 0)
    
    local moveBtn = components.createButton("move", positions[1].x, regions.footer.y, positions[1].width, 2, "Move",
        function()
            app.showMoveScreen()
        end)
    moveBtn.bgColor = gui.getColor("primary")
    
    local mineBtn = components.createButton("mine", positions[2].x, regions.footer.y, positions[2].width, 2, "Mine",
        function()
            app.showMineScreen()
        end)
    mineBtn.bgColor = gui.getColor("success")
    
    local netBtn = components.createButton("network", positions[3].x, regions.footer.y, positions[3].width, 2, "Net",
        function()
            app.showNetworkScreen()
        end)
    netBtn.bgColor = app.state.networkEnabled and gui.getColor("primary") or colors.gray
    
    local exitBtn = components.createButton("exit", positions[4].x, regions.footer.y, positions[4].width, 2, "Exit",
        function()
            app.exit()
        end)
    exitBtn.bgColor = gui.getColor("error")
    
    gui.draw()
end

-- ========== MOVE SCREEN ==========

function app.showMoveScreen()
    app.state.currentScreen = "move"
    gui.clearComponents()
    
    local w, h = term.getSize()
    
    gui.centerText("Turtle Movement", 1, gui.getColor("primary"), colors.white)
    
    -- Movement Panel (responsive)
    local panel = components.createPanel("move", 1, 3, w - 1, 14, "Controls")
    panel.borderColor = gui.getColor("border")
    
    -- Center column for main buttons
    local centerX = math.floor(w / 2) - 4
    local sideX = math.floor(w / 2) - 15
    local rightX = math.floor(w / 2) + 6
    
    -- Up
    local upBtn = components.createButton("up", centerX, 5, 9, 2, "UP", function()
        if turtle.up() then
            app.state.position.y = app.state.position.y + 1
            app.updateTurtleInfo()
            app.showMoveScreen()
        end
    end)
    
    -- Forward
    local fwdBtn = components.createButton("fwd", centerX, 8, 9, 2, "FORWARD", function()
        if turtle.forward() then
            app.updateTurtleInfo()
            app.showMoveScreen()
        end
    end)
    
    -- Back
    local backBtn = components.createButton("back", centerX, 11, 9, 2, "BACK", function()
        if turtle.back() then
            app.updateTurtleInfo()
            app.showMoveScreen()
        end
    end)
    
    -- Down
    local downBtn = components.createButton("down", centerX, 14, 9, 2, "DOWN", function()
        if turtle.down() then
            app.state.position.y = app.state.position.y - 1
            app.updateTurtleInfo()
            app.showMoveScreen()
        end
    end)
    
    -- Turn Left
    local leftBtn = components.createButton("left", sideX, 8, 9, 2, "< LEFT", function()
        turtle.turnLeft()
        app.showMoveScreen()
    end)
    
    -- Turn Right
    local rightBtn = components.createButton("right", rightX, 8, 9, 2, "RIGHT >", function()
        turtle.turnRight()
        app.showMoveScreen()
    end)
    
    -- Back button (centered)
    local backBtnW = 14
    local backBtnX = math.floor(w / 2) - math.floor(backBtnW / 2)
    local returnBtn = components.createButton("return", backBtnX, h - 1, backBtnW, 2, "Back",
        function()
            app.createMainScreen()
        end)
    
    gui.draw()
end

-- ========== MINE SCREEN ==========

function app.showMineScreen()
    app.state.currentScreen = "mine"
    gui.clearComponents()
    
    local w, h = term.getSize()
    
    gui.centerText("Mining Controls", 1, gui.getColor("primary"), colors.white)
    
    -- Mining Panel (responsive)
    local panel = components.createPanel("mine", 1, 3, w - 1, h - 5, "Actions")
    panel.borderColor = gui.getColor("border")
    
    -- Button sizing (3 columns)
    local btnW = math.floor((w - 8) / 3)
    local col1 = 3
    local col2 = col1 + btnW + 1
    local col3 = col2 + btnW + 1
    -- Ensure third column doesn't exceed screen
    local btn3W = math.min(btnW, w - col3 - 1)
    
    -- Dig Forward
    local digFwdBtn = components.createButton("digfwd", col1, 5, btnW, 2, "Dig Fwd", function()
        if turtle.dig() then
            gui.notify("Dug forward", colors.white, gui.getColor("success"), 1)
        end
    end)
    digFwdBtn.bgColor = gui.getColor("warning")
    
    -- Dig Up
    local digUpBtn = components.createButton("digup", col2, 5, btnW, 2, "Dig Up", function()
        if turtle.digUp() then
            gui.notify("Dug up", colors.white, gui.getColor("success"), 1)
        end
    end)
    digUpBtn.bgColor = gui.getColor("warning")
    
    -- Dig Down
    local digDownBtn = components.createButton("digdown", col3, 5, btn3W, 2, "Dig Dn", function()
        if turtle.digDown() then
            gui.notify("Dug down", colors.white, gui.getColor("success"), 1)
        end
    end)
    digDownBtn.bgColor = gui.getColor("warning")
    
    -- Place Forward
    local placeFwdBtn = components.createButton("placefwd", col1, 8, btnW, 2, "Plc Fwd", function()
        if turtle.place() then
            gui.notify("Placed", colors.white, gui.getColor("success"), 1)
        end
    end)
    placeFwdBtn.bgColor = gui.getColor("success")
    
    -- Place Up
    local placeUpBtn = components.createButton("placeup", col2, 8, btnW, 2, "Plc Up", function()
        if turtle.placeUp() then
            gui.notify("Placed up", colors.white, gui.getColor("success"), 1)
        end
    end)
    placeUpBtn.bgColor = gui.getColor("success")
    
    -- Place Down
    local placeDownBtn = components.createButton("placedown", col3, 8, btn3W, 2, "Plc Dn", function()
        if turtle.placeDown() then
            gui.notify("Placed", colors.white, gui.getColor("success"), 1)
        end
    end)
    placeDownBtn.bgColor = gui.getColor("success")
    
    -- Refuel button (2 columns)
    local btn2W = math.floor((w - 6) / 2)
    local btn2Col2 = 3 + btn2W + 1
    local btn2W2 = w - btn2Col2 - 1
    
    local refuelBtn = components.createButton("refuel", 3, 11, btn2W, 2, "Refuel", function()
        app.refuelFromSlot(1)
    end)
    refuelBtn.bgColor = gui.getColor("primary")
    
    -- Inventory button
    local invBtn = components.createButton("inventory", btn2Col2, 11, btn2W2, 2, "Inv", function()
        app.showInventoryScreen()
    end)
    
    -- Drop All button (centered)
    local dropBtnW = math.floor((w - 6) / 2)
    local dropBtn = components.createButton("drop", 3, 14, dropBtnW, 2, "Drop All", function()
        for slot = 1, 16 do
            turtle.select(slot)
            turtle.drop()
        end
        app.updateTurtleInfo()
        gui.notify("Dropped", colors.white, gui.getColor("warning"), 2)
    end)
    dropBtn.bgColor = gui.getColor("error")
    
    -- Back button (centered)
    local backBtnW = 10
    local backBtnX = math.floor(w / 2) - math.floor(backBtnW / 2)
    local returnBtn = components.createButton("return", backBtnX, h - 1, backBtnW, 2, "Back",
        function()
            app.createMainScreen()
        end)
    
    gui.draw()
end

-- ========== INVENTORY SCREEN ==========

function app.showInventoryScreen()
    app.state.currentScreen = "inventory"
    gui.clearComponents()
    
    local w, h = term.getSize()
    
    gui.centerText("Turtle Inventory", 1, gui.getColor("primary"), colors.white)
    
    -- Inventory grid (responsive)
    local panel = components.createPanel("inv", 1, 3, w - 1, h - 4, "16 Slots")
    panel.borderColor = gui.getColor("border")
    
    -- Calculate button size for 4x4 grid
    local btnW = math.floor((w - 9) / 4)
    local btnH = 2
    local spacing = 1
    
    -- Show slots in 4x4 grid
    for slot = 1, 16 do
        local row = math.floor((slot - 1) / 4)
        local col = (slot - 1) % 4
        
        local x = 3 + (col * (btnW + spacing))
        local y = 5 + (row * (btnH + spacing))
        
        local item = turtle.getItemDetail(slot)
        local slotText = tostring(slot)
        if item then
            slotText = slotText .. ":" .. item.count
        end
        
        local slotBtn = components.createButton("slot" .. slot, x, y, btnW, btnH, slotText, function()
            turtle.select(slot)
            gui.notify("Slot " .. slot, colors.white, gui.getColor("primary"), 1)
        end)
        slotBtn.bgColor = item and gui.getColor("success") or colors.gray
    end
    
    -- Back button (centered)
    local backBtnW = 10
    local backBtnX = math.floor(w / 2) - math.floor(backBtnW / 2)
    local returnBtn = components.createButton("return", backBtnX, h - 1, backBtnW, 2, "Back",
        function()
            app.showMineScreen()
        end)
    
    gui.draw()
end

-- ========== NETWORK SCREEN ==========

function app.showNetworkScreen()
    app.state.currentScreen = "network"
    gui.clearComponents()
    
    local w, h = term.getSize()
    
    gui.centerText("Network Status", 1, gui.getColor("primary"), colors.white)
    
    local status = app.state.networkStatus or {}
    
    -- Connection Panel (responsive)
    local connPanel = components.createPanel("conn", 1, 3, w - 1, 7, "Connection")
    connPanel.borderColor = gui.getColor("border")
    
    local connLabel = components.createLabel("connStatus", 3, 5,
        status.connected and "Connected" or "Disconnected")
    connLabel.fgColor = status.connected and gui.getColor("success") or gui.getColor("error")
    
    local idLabel = components.createLabel("id", 3, 6,
        string.format("ID: %d", os.getComputerID()))
    
    local labelText = os.getComputerLabel() or "Unlabeled"
    local labelLabel = components.createLabel("label", 3, 7,
        string.format("Label: %s", labelText))
    
    if status.coordinatorId then
        local coordLabel = components.createLabel("coord", 3, 8,
            string.format("Coord: %d", status.coordinatorId))
    end
    
    -- Project Panel (responsive)
    if status.currentProject then
        local projPanel = components.createPanel("proj", 1, 11, w - 1, 7, "Project")
        projPanel.borderColor = gui.getColor("border")
        
        local projName = components.createLabel("projName", 3, 13,
            "Proj: " .. (status.currentProject.name or "Unknown"))
        
        if status.assignment then
            local zoneLabel = components.createLabel("zone", 3, 14,
                string.format("Zone: %d", status.assignment.zone or 0))
            
            local instrLabel = components.createLabel("instr", 3, 15,
                status.assignment.instructions or "Awaiting...")
            instrLabel.fgColor = gui.getColor("warning")
        end
        
        -- Peers
        if status.peers and #status.peers > 0 then
            local peerLabel = components.createLabel("peerLbl", 3, 16,
                string.format("Team: %d", #status.peers))
            peerLabel.fgColor = gui.getColor("primary")
        end
    else
        local noProjLabel = components.createLabel("noProj", 3, 12,
            "No project assigned")
        noProjLabel.fgColor = colors.gray
    end
    
    -- Control Buttons (responsive, 2 columns)
    local btnY = h - 2
    local btnW = math.floor((w - 3) / 2)  -- Account for gap
    local btn2X = 1 + btnW + 1
    local btn2W = w - btn2X  -- Calculate remaining width for second button
    
    if not app.state.networkEnabled then
        local enableBtn = components.createButton("enable", 1, btnY, btnW, 2, "Enable",
            function()
                app.enableNetwork()
            end)
        enableBtn.bgColor = gui.getColor("success")
    else
        local refreshBtn = components.createButton("refresh", 1, btnY, btnW, 2, "Refresh",
            function()
                app.refreshNetworkStatus()
            end)
        refreshBtn.bgColor = gui.getColor("primary")
    end
    
    -- Back button
    local backBtn = components.createButton("back", btn2X, btnY, btn2W, 2, "Back",
        function()
            app.createMainScreen()
        end)
    
    gui.draw()
end

-- ========== NETWORK FUNCTIONS ==========

function app.enableNetwork()
    -- Show loading screen
    gui.clearComponents()
    
    local w, h = layouts.getScreenSize()
    
    gui.centerText("Network Connection", 1, gui.getColor("primary"), colors.white)
    
    local panelW = math.min(40, w - 4)
    local panelX = layouts.centerHorizontally(panelW)
    local panel = components.createPanel("connecting", panelX, 6, panelW, 6, "Connecting")
    panel.borderColor = gui.getColor("border")
    
    local statusLabel = components.createLabel("connStatus", panelX + 2, 8, "Searching for coordinator...")
    statusLabel.fgColor = gui.getColor("warning")
    
    local spinnerLabel = components.createLabel("connSpinner", panelX + 2, 10, "")
    
    gui.draw()
    
    -- Attempt connection with animation
    local connected, skipped = app.animateLoading(5, function()
        local c = getClient()
        if not c then return false end
        
        local success = c.init(os.getComputerLabel())
        if success then
            app.state.networkEnabled = true
            app.refreshNetworkStatus()
        end
        return success
    end)
    
    -- Show result
    statusLabel = gui.getComponent("connStatus")
    spinnerLabel = gui.getComponent("connSpinner")
    
    if skipped then
        if statusLabel then
            statusLabel.text = "Connection cancelled"
            statusLabel.fgColor = colors.gray
        end
        if spinnerLabel then
            spinnerLabel.text = "Skipped"
        end
    elseif connected then
        if statusLabel then
            statusLabel.text = "Connected successfully!"
            statusLabel.fgColor = gui.getColor("success")
        end
        if spinnerLabel then
            spinnerLabel.text = "Ready!"
        end
    else
        if statusLabel then
            statusLabel.text = "Connection failed"
            statusLabel.fgColor = gui.getColor("error")
        end
        if spinnerLabel then
            spinnerLabel.text = "No coordinator found"
        end
    end
    
    gui.draw()
    sleep(1.5)
    
    app.showNetworkScreen()
end

function app.refreshNetworkStatus()
    if not app.state.networkEnabled then
        return
    end
    
    local c = getClient()
    if c then
        app.state.networkStatus = c.getStatus()
        app.updateTurtleInfo()
    end
end

-- ========== EXIT ==========

function app.exit()
    gui.clearComponents()
    gui.clear()
    
    -- Close network if enabled
    if app.state.networkEnabled then
        local c = getClient()
        if c then
            c.close()
        end
    end
    
    term.clear()
    term.setCursorPos(1, 1)
    print("CCMine Turtle Interface")
    print("Thank you for using CCMine!")
    print("")
    print("Turtle ID: " .. os.getComputerID())
    if app.state.networkEnabled then
        print("Network: Disconnected")
    end
end

-- ========== LOADING SCREEN ==========

function app.showLoadingScreen()
    gui.clearComponents()
    
    local w, h = layouts.getScreenSize()
    
    -- Title with Turtle ID
    local turtleLabel = os.getComputerLabel() or ("Turtle-" .. os.getComputerID())
    gui.centerText(turtleLabel, 1, gui.getColor("primary"), colors.white)
    
    -- Loading panel
    local panelW = math.min(40, w - 4)
    local panelX = layouts.centerHorizontally(panelW)
    local panel = components.createPanel("loading", panelX, 4, panelW, 9, "Network Connection")
    panel.borderColor = gui.getColor("border")
    
    -- Turtle info
    local idLabel = components.createLabel("turtleId", panelX + 2, 6, 
        string.format("ID: %d", os.getComputerID()))
    idLabel.fgColor = colors.lightGray
    
    -- Status label
    local statusLabel = components.createLabel("status", panelX + 2, 8, "Searching for coordinator...")
    statusLabel.fgColor = gui.getColor("warning")
    
    -- Loading spinner (will be updated)
    local spinnerLabel = components.createLabel("spinner", panelX + 2, 10, "")
    
    -- Skip hint
    local skipLabel = components.createLabel("skip", panelX + 2, 11, "Press any key to skip")
    skipLabel.fgColor = colors.gray
    
    gui.draw()
end

function app.animateLoading(duration, callback)
    local frames = {".", "..", "...", "....", ".....", "......"}
    local spinnerFrames = {"|", "/", "-", "\\"}
    local frameIndex = 1
    local spinnerIndex = 1
    local startTime = os.clock()
    local result = nil
    local done = false
    local skipped = false
    
    -- Run callback in parallel with animation and key detection
    parallel.waitForAny(
        function()
            -- Animation loop
            while not done and not skipped do
                local elapsed = os.clock() - startTime
                if elapsed > duration then
                    break
                end
                
                -- Update spinner with both dot animation and spinner
                local spinner = gui.getComponent("spinner")
                local connSpinner = gui.getComponent("connSpinner")
                
                if spinner then
                    spinner.text = spinnerFrames[spinnerIndex] .. " " .. frames[frameIndex]
                    gui.draw()
                end
                
                if connSpinner then
                    connSpinner.text = spinnerFrames[spinnerIndex] .. " " .. frames[frameIndex]
                    gui.draw()
                end
                
                frameIndex = frameIndex + 1
                if frameIndex > #frames then
                    frameIndex = 1
                end
                
                spinnerIndex = spinnerIndex + 1
                if spinnerIndex > #spinnerFrames then
                    spinnerIndex = 1
                end
                
                sleep(0.2)
            end
        end,
        function()
            -- Connection attempt
            result = callback()
            done = true
        end,
        function()
            -- Skip on any key press
            os.pullEvent("key")
            skipped = true
        end
    )
    
    return result, skipped
end

function app.startupSequence()
    -- Save original pullEvent and disable termination during startup
    local originalPullEvent = os.pullEvent
    os.pullEvent = os.pullEventRaw
    
    -- Show loading screen
    gui.clearComponents()
    gui.clear()
    
    local w, h = layouts.getScreenSize()
    
    -- Title with Turtle ID
    local turtleLabel = os.getComputerLabel() or ("Turtle-" .. os.getComputerID())
    gui.centerText(turtleLabel, 1, gui.getColor("primary"), colors.white)
    
    -- Loading panel
    local panelW = math.min(40, w - 4)
    local panelH = 10
    local panelX = layouts.centerHorizontally(panelW)
    local panelY = math.floor((h - panelH) / 2)
    local panel = components.createPanel("loading", panelX, panelY, panelW, panelH, "Network Connection")
    panel.borderColor = gui.getColor("border")
    
    -- Turtle info
    local idLabel = components.createLabel("turtleId", panelX + 2, panelY + 2, 
        string.format("ID: %d", os.getComputerID()))
    idLabel.fgColor = colors.lightGray
    idLabel.parent = panel
    panel:addChild(idLabel)
    
    -- Status label
    local statusLabel = components.createLabel("status", panelX + 2, panelY + 4, "Checking for modem...")
    statusLabel.fgColor = gui.getColor("warning")
    statusLabel.parent = panel
    panel:addChild(statusLabel)
    
    -- Loading spinner (will be updated)
    local spinnerLabel = components.createLabel("spinner", panelX + 2, panelY + 6, "")
    spinnerLabel.parent = panel
    panel:addChild(spinnerLabel)
    
    gui.draw()
    sleep(0.3)
    
    -- ===== STEP 1: WAIT FOR MODEM =====
    local modem = peripheral.find("modem")
    
    if not modem then
        statusLabel = gui.getComponent("status")
        spinnerLabel = gui.getComponent("spinner")
        
        if statusLabel then
            statusLabel.text = "Waiting for Modem"
            statusLabel.fgColor = gui.getColor("warning")
        end
        if spinnerLabel then
            spinnerLabel.text = ""
        end
        
        gui.draw()
        
        -- Wait for modem to be attached with loading circle animation
        local circleFrames = {
            "    o o o    ",
            "   o   o     ",
            "  o     o    ",
            "  o      o   ",
            " o        o  ",
            "o          o ",
            "o          o ",
            " o        o  ",
            "  o      o   ",
            "  o     o    ",
            "   o   o     ",
            "    o o      "
        }
        
        -- Better circle animation using segments
        local circleSegments = {
            "   .....   ",
            "  .     .  ",
            " .       . ",
            ".         .",
            "           ",
            ".         .",
            " .       . ",
            "  .     .  ",
        }
        
        -- Rotating segments
        local loadingFrames = {
            "     o     ",
            "    ooo    ",
            "   o   o   ",
            "  o     o  ",
            " o       o ",
            "o         o",
            "           ",
            "o         o",
            " o       o ",
            "  o     o  ",
            "   o   o   ",
            "    ooo    ",
        }
        
        -- Simple rotating circle
        local rotatingCircle = {
            "    ●      ",
            "   ●       ",
            "  ●        ",
            " ●         ",
            "●          ",
            " ●         ",
            "  ●        ",
            "   ●       ",
        }
        
        local frameIndex = 1
        
        while not modem do
            -- Wait for event with timeout (filter out key/char events)
            local timer = os.startTimer(0.15)
            repeat
                local event, p1 = os.pullEvent()
                
                if event == "timer" and p1 == timer then
                    -- Update loading circle animation
                    frameIndex = frameIndex % #rotatingCircle + 1
                    
                    if spinnerLabel then
                        spinnerLabel.text = rotatingCircle[frameIndex]
                        spinnerLabel.fgColor = gui.getColor("primary")
                    end
                    gui.draw()
                    break
                elseif event == "peripheral" or event == "peripheral_attach" then
                    -- Check if modem was attached
                    modem = peripheral.find("modem")
                    if modem then break end
                end
                -- Ignore key, char, mouse events - keep waiting
            until event == "timer" or event == "peripheral" or event == "peripheral_attach"
        end
        
        -- Modem found!
        statusLabel = gui.getComponent("status")
        if statusLabel then
            statusLabel.text = "Modem Found!"
            statusLabel.fgColor = gui.getColor("success")
        end
        spinnerLabel = gui.getComponent("spinner")
        if spinnerLabel then
            spinnerLabel.text = "     ✓     "
            spinnerLabel.fgColor = gui.getColor("success")
        end
        gui.draw()
        sleep(1)
    else
        -- Already has modem
        statusLabel = gui.getComponent("status")
        if statusLabel then
            statusLabel.text = "Modem Detected"
            statusLabel.fgColor = gui.getColor("success")
        end
        spinnerLabel = gui.getComponent("spinner")
        if spinnerLabel then
            spinnerLabel.text = "     ✓     "
            spinnerLabel.fgColor = gui.getColor("success")
        end
        gui.draw()
        sleep(0.5)
    end
    
    -- ===== STEP 2: WAIT FOR COORDINATOR =====
    statusLabel = gui.getComponent("status")
    if statusLabel then
        statusLabel.text = "Linking to Coordinator"
        statusLabel.fgColor = gui.getColor("warning")
    end
    spinnerLabel = gui.getComponent("spinner")
    if spinnerLabel then
        spinnerLabel.text = ""
    end
    gui.draw()
    sleep(0.3)
    
    -- Attempt connection with loading circle animation (no skip)
    local connected = false
    
    -- Rotating circle animation
    local rotatingCircle = {
        "    ●      ",
        "   ●       ",
        "  ●        ",
        " ●         ",
        "●          ",
        " ●         ",
        "  ●        ",
        "   ●       ",
    }
    
    local frameIndex = 1
    
    -- Start connection attempt in parallel with animation
    parallel.waitForAny(
        function()
            -- Connection attempt
            local c = getClient()
            if c then
                connected = c.init(os.getComputerLabel())
                if connected then
                    app.state.networkEnabled = true
                    app.refreshNetworkStatus()
                end
            end
        end,
        function()
            -- Animation loop - ignore all key presses
            while not connected do
                local timer = os.startTimer(0.15)
                repeat
                    local event, p1 = os.pullEvent()
                    -- Only process timer events, ignore key/char/mouse
                    if event == "timer" and p1 == timer then
                        frameIndex = frameIndex % #rotatingCircle + 1
                        spinnerLabel = gui.getComponent("spinner")
                        if spinnerLabel then
                            spinnerLabel.text = rotatingCircle[frameIndex]
                            spinnerLabel.fgColor = gui.getColor("primary")
                        end
                        gui.draw()
                        break
                    end
                until event == "timer"
            end
        end
    )
    
    -- Update final status
    statusLabel = gui.getComponent("status")
    spinnerLabel = gui.getComponent("spinner")
    
    if connected then
        if statusLabel then
            statusLabel.text = "Connected!"
            statusLabel.fgColor = gui.getColor("success")
        end
        if spinnerLabel then
            spinnerLabel.text = "     ✓     "
            spinnerLabel.fgColor = gui.getColor("success")
        end
        gui.draw()
        sleep(1.5)
    else
        if statusLabel then
            statusLabel.text = "Link Failed"
            statusLabel.fgColor = gui.getColor("error")
        end
        if spinnerLabel then
            spinnerLabel.text = "     ✗     "
            spinnerLabel.fgColor = gui.getColor("error")
        end
        gui.draw()
        sleep(2)
    end
    
    -- Restore original pullEvent (re-enable termination)
    os.pullEvent = originalPullEvent
    
    -- Show main screen
    app.createMainScreen()
end

-- ========== MAIN ==========

function app.run()
    -- Initialize
    gui.init()
    gui.setTheme("default")
    
    -- Run startup sequence with loading screen
    app.startupSequence()
    
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
            if app.state.currentScreen == "main" then
                app.createMainScreen()
            elseif app.state.currentScreen == "move" then
                app.showMoveScreen()
            elseif app.state.currentScreen == "mine" then
                app.showMineScreen()
            elseif app.state.currentScreen == "network" then
                app.showNetworkScreen()
            end
        elseif event == "key" then
            if p1 == keys.q and keys.leftCtrl then
                app.exit()
                break
            end
        end
    end
end

-- Auto-run if executed directly
if not ... then
    app.run()
end

return app
