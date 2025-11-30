-- CCMine Turtle Interface
-- Turtle-specific GUI with mining controls and network features

local gui = require("gui-core")
local components = require("gui-components")
local layouts = require("gui-layouts")
local client = require("turtle-client")

local app = {}

-- Check if running on a turtle
if not turtle then
    error("This program must be run on a turtle!")
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
        app.state.position = client.getPosition()
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
    
    -- Get screen dimensions
    local w, h = term.getSize()
    
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
    
    -- Status Panel (responsive width)
    local statusPanel = components.createPanel("status", 1, 5, w, 8, "Turtle Status")
    statusPanel.borderColor = gui.getColor("border")
    
    -- Fuel Bar (responsive)
    local fuelLabel = components.createLabel("fuelLabel", 3, 7, "Fuel:")
    local fuelPercent = math.floor((app.state.fuel / app.state.maxFuel) * 100)
    local fuelBar = components.createProgressBar("fuelBar", 9, 7, w - 10)
    fuelBar.value = fuelPercent
    fuelBar.fillColor = fuelPercent > 50 and gui.getColor("success") or 
                        fuelPercent > 20 and gui.getColor("warning") or 
                        gui.getColor("error")
    
    -- Inventory Bar (responsive)
    local invLabel = components.createLabel("invLabel", 3, 8, "Inv:")
    local invPercent = math.floor((app.state.inventory / app.state.maxInventory) * 100)
    local invBar = components.createProgressBar("invBar", 9, 8, w - 10)
    invBar.value = invPercent
    
    -- Position (shortened for narrow screens)
    local posLabel = components.createLabel("position", 3, 10,
        string.format("X:%d Y:%d Z:%d", 
            app.state.position.x, app.state.position.y, app.state.position.z))
    
    -- Status
    local statusText = app.state.mining and "MINING" or "IDLE"
    local statusLabel = components.createLabel("statusText", 3, 11, "Status: " .. statusText)
    statusLabel.fgColor = app.state.mining and gui.getColor("success") or gui.getColor("warning")
    
    -- Network Status (only if enough space)
    if app.state.networkEnabled and w >= 39 then
        local netStatus = app.state.networkStatus or {}
        local netLabel = components.createLabel("netStatus", w - 9, 11,
            netStatus.connected and "[NET:ON]" or "[NET:OFF]")
        netLabel.fgColor = netStatus.connected and gui.getColor("success") or gui.getColor("error")
    end
    
    -- Footer buttons - responsive sizing
    local btnW = math.floor((w - 2) / 4)
    local btn1X = 1
    local btn2X = btn1X + btnW
    local btn3X = btn2X + btnW
    local btn4X = btn3X + btnW
    
    local moveBtn = components.createButton("move", btn1X, regions.footer.y, btnW, 2, "Move",
        function()
            app.showMoveScreen()
        end)
    moveBtn.bgColor = gui.getColor("primary")
    
    local mineBtn = components.createButton("mine", btn2X, regions.footer.y, btnW, 2, "Mine",
        function()
            app.showMineScreen()
        end)
    mineBtn.bgColor = gui.getColor("success")
    
    local netBtn = components.createButton("network", btn3X, regions.footer.y, btnW, 2, "Net",
        function()
            app.showNetworkScreen()
        end)
    netBtn.bgColor = app.state.networkEnabled and gui.getColor("primary") or colors.gray
    
    local exitBtn = components.createButton("exit", btn4X, regions.footer.y, btnW + 1, 2, "Exit",
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
    local panel = components.createPanel("move", 2, 3, w - 2, 14, "Controls")
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
    local panel = components.createPanel("mine", 2, 3, w - 2, h - 5, "Actions")
    panel.borderColor = gui.getColor("border")
    
    -- Button sizing (3 columns)
    local btnW = math.floor((w - 6) / 3)
    local col1 = 4
    local col2 = col1 + btnW + 1
    local col3 = col2 + btnW + 1
    
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
    local digDownBtn = components.createButton("digdown", col3, 5, btnW, 2, "Dig Down", function()
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
    local placeDownBtn = components.createButton("placedown", col3, 8, btnW, 2, "Plc Down", function()
        if turtle.placeDown() then
            gui.notify("Placed", colors.white, gui.getColor("success"), 1)
        end
    end)
    placeDownBtn.bgColor = gui.getColor("success")
    
    -- Refuel button (2 columns)
    local btn2W = math.floor((w - 5) / 2)
    local refuelBtn = components.createButton("refuel", 4, 11, btn2W, 2, "Refuel S1", function()
        app.refuelFromSlot(1)
    end)
    refuelBtn.bgColor = gui.getColor("primary")
    
    -- Inventory button
    local invBtn = components.createButton("inventory", 4 + btn2W + 1, 11, btn2W, 2, "Inventory", function()
        app.showInventoryScreen()
    end)
    
    -- Drop All button (centered)
    local dropBtnW = math.floor((w - 4) / 2)
    local dropBtn = components.createButton("drop", 4, 14, dropBtnW, 2, "Drop All", function()
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
    local panel = components.createPanel("inv", 2, 3, w - 2, h - 4, "16 Slots")
    panel.borderColor = gui.getColor("border")
    
    -- Calculate button size for 4x4 grid
    local btnW = math.floor((w - 8) / 4)
    local btnH = 2
    local spacing = 1
    
    -- Show slots in 4x4 grid
    for slot = 1, 16 do
        local row = math.floor((slot - 1) / 4)
        local col = (slot - 1) % 4
        
        local x = 4 + (col * (btnW + spacing))
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
    local connPanel = components.createPanel("conn", 1, 3, w, 7, "Connection")
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
        local projPanel = components.createPanel("proj", 1, 11, w, 7, "Project")
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
    local btnW = math.floor((w - 2) / 2)
    
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
    local backBtn = components.createButton("back", 1 + btnW + 1, btnY, btnW, 2, "Back",
        function()
            app.createMainScreen()
        end)
    
    gui.draw()
end

-- ========== NETWORK FUNCTIONS ==========

function app.enableNetwork()
    gui.notify("Enabling network...", colors.white, gui.getColor("primary"), 2)
    
    local success = client.init(os.getComputerLabel())
    
    if success then
        app.state.networkEnabled = true
        app.refreshNetworkStatus()
        gui.notify("Network enabled!", colors.white, gui.getColor("success"), 2)
    else
        gui.notify("Network failed!", colors.white, gui.getColor("error"), 2)
    end
    
    sleep(2)
    app.showNetworkScreen()
end

function app.refreshNetworkStatus()
    if not app.state.networkEnabled then
        return
    end
    
    app.state.networkStatus = client.getStatus()
    app.updateTurtleInfo()
end

-- ========== EXIT ==========

function app.exit()
    gui.clearComponents()
    gui.clear()
    
    -- Close network if enabled
    if app.state.networkEnabled then
        client.close()
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

-- ========== MAIN ==========

function app.run()
    -- Initialize
    gui.init()
    gui.setTheme("default")
    
    -- Check for modem
    local modem = peripheral.find("modem")
    if modem then
        print("Wireless modem detected!")
        print("Network features available.")
        sleep(1)
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
