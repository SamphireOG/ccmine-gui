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
    
    -- Status Panel
    local statusPanel = components.createPanel("status", 2, 5, 47, 8, "Turtle Status")
    statusPanel.borderColor = gui.getColor("border")
    
    -- Fuel Bar
    local fuelLabel = components.createLabel("fuelLabel", 4, 7, "Fuel:")
    local fuelPercent = math.floor((app.state.fuel / app.state.maxFuel) * 100)
    local fuelBar = components.createProgressBar("fuelBar", 10, 7, 37)
    fuelBar.value = fuelPercent
    fuelBar.fillColor = fuelPercent > 50 and gui.getColor("success") or 
                        fuelPercent > 20 and gui.getColor("warning") or 
                        gui.getColor("error")
    
    -- Inventory Bar
    local invLabel = components.createLabel("invLabel", 4, 8, "Inv:")
    local invPercent = math.floor((app.state.inventory / app.state.maxInventory) * 100)
    local invBar = components.createProgressBar("invBar", 10, 8, 37)
    invBar.value = invPercent
    
    -- Position
    local posLabel = components.createLabel("position", 4, 10,
        string.format("Pos: X:%d Y:%d Z:%d", 
            app.state.position.x, app.state.position.y, app.state.position.z))
    
    -- Status
    local statusText = app.state.mining and "MINING" or "IDLE"
    local statusLabel = components.createLabel("statusText", 4, 11, "Status: " .. statusText)
    statusLabel.fgColor = app.state.mining and gui.getColor("success") or gui.getColor("warning")
    
    -- Network Status
    if app.state.networkEnabled then
        local netStatus = app.state.networkStatus or {}
        local netLabel = components.createLabel("netStatus", 35, 11,
            netStatus.connected and "[NET: ON]" or "[NET: OFF]")
        netLabel.fgColor = netStatus.connected and gui.getColor("success") or gui.getColor("error")
    end
    
    -- Footer buttons - turtle-specific
    local moveBtn = components.createButton("move", 2, regions.footer.y, 11, 2, "Move",
        function()
            app.showMoveScreen()
        end)
    moveBtn.bgColor = gui.getColor("primary")
    
    local mineBtn = components.createButton("mine", 14, regions.footer.y, 11, 2, "Mine",
        function()
            app.showMineScreen()
        end)
    mineBtn.bgColor = gui.getColor("success")
    
    local netBtn = components.createButton("network", 26, regions.footer.y, 11, 2, "Network",
        function()
            app.showNetworkScreen()
        end)
    netBtn.bgColor = app.state.networkEnabled and gui.getColor("primary") or colors.gray
    
    local exitBtn = components.createButton("exit", 38, regions.footer.y, 11, 2, "Exit",
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
    
    gui.centerText("Turtle Movement", 1, gui.getColor("primary"), colors.white)
    
    -- Movement Panel
    local panel = components.createPanel("move", 5, 3, 41, 14, "Controls")
    panel.borderColor = gui.getColor("border")
    
    -- Up
    local upBtn = components.createButton("up", 20, 5, 10, 2, "UP", function()
        if turtle.up() then
            app.state.position.y = app.state.position.y + 1
            app.updateTurtleInfo()
            app.showMoveScreen()
        end
    end)
    
    -- Forward
    local fwdBtn = components.createButton("fwd", 20, 8, 10, 2, "FORWARD", function()
        if turtle.forward() then
            app.updateTurtleInfo()
            app.showMoveScreen()
        end
    end)
    
    -- Back
    local backBtn = components.createButton("back", 20, 11, 10, 2, "BACK", function()
        if turtle.back() then
            app.updateTurtleInfo()
            app.showMoveScreen()
        end
    end)
    
    -- Down
    local downBtn = components.createButton("down", 20, 14, 10, 2, "DOWN", function()
        if turtle.down() then
            app.state.position.y = app.state.position.y - 1
            app.updateTurtleInfo()
            app.showMoveScreen()
        end
    end)
    
    -- Turn Left
    local leftBtn = components.createButton("left", 8, 8, 10, 2, "< LEFT", function()
        turtle.turnLeft()
        app.showMoveScreen()
    end)
    
    -- Turn Right
    local rightBtn = components.createButton("right", 32, 8, 10, 2, "RIGHT >", function()
        turtle.turnRight()
        app.showMoveScreen()
    end)
    
    -- Back button
    local returnBtn = components.createButton("return", 15, 18, 20, 2, "Back to Main",
        function()
            app.createMainScreen()
        end)
    
    gui.draw()
end

-- ========== MINE SCREEN ==========

function app.showMineScreen()
    app.state.currentScreen = "mine"
    gui.clearComponents()
    
    gui.centerText("Mining Controls", 1, gui.getColor("primary"), colors.white)
    
    -- Mining Panel
    local panel = components.createPanel("mine", 5, 3, 41, 14, "Actions")
    panel.borderColor = gui.getColor("border")
    
    -- Dig Forward
    local digFwdBtn = components.createButton("digfwd", 8, 5, 13, 2, "Dig Forward", function()
        if turtle.dig() then
            gui.notify("Dug forward", colors.white, gui.getColor("success"), 1)
        end
    end)
    digFwdBtn.bgColor = gui.getColor("warning")
    
    -- Dig Up
    local digUpBtn = components.createButton("digup", 22, 5, 13, 2, "Dig Up", function()
        if turtle.digUp() then
            gui.notify("Dug up", colors.white, gui.getColor("success"), 1)
        end
    end)
    digUpBtn.bgColor = gui.getColor("warning")
    
    -- Dig Down
    local digDownBtn = components.createButton("digdown", 36, 5, 9, 2, "Dig Down", function()
        if turtle.digDown() then
            gui.notify("Dug down", colors.white, gui.getColor("success"), 1)
        end
    end)
    digDownBtn.bgColor = gui.getColor("warning")
    
    -- Place Forward
    local placeFwdBtn = components.createButton("placefwd", 8, 8, 13, 2, "Place Fwd", function()
        if turtle.place() then
            gui.notify("Placed forward", colors.white, gui.getColor("success"), 1)
        end
    end)
    placeFwdBtn.bgColor = gui.getColor("success")
    
    -- Place Up
    local placeUpBtn = components.createButton("placeup", 22, 8, 13, 2, "Place Up", function()
        if turtle.placeUp() then
            gui.notify("Placed up", colors.white, gui.getColor("success"), 1)
        end
    end)
    placeUpBtn.bgColor = gui.getColor("success")
    
    -- Place Down
    local placeDownBtn = components.createButton("placedown", 36, 8, 9, 2, "Place Dn", function()
        if turtle.placeDown() then
            gui.notify("Placed down", colors.white, gui.getColor("success"), 1)
        end
    end)
    placeDownBtn.bgColor = gui.getColor("success")
    
    -- Refuel button
    local refuelBtn = components.createButton("refuel", 8, 11, 15, 2, "Refuel (Slot 1)", function()
        app.refuelFromSlot(1)
    end)
    refuelBtn.bgColor = gui.getColor("primary")
    
    -- Inventory button
    local invBtn = components.createButton("inventory", 24, 11, 13, 2, "Inventory", function()
        app.showInventoryScreen()
    end)
    
    -- Drop All button
    local dropBtn = components.createButton("drop", 8, 14, 13, 2, "Drop All", function()
        for slot = 1, 16 do
            turtle.select(slot)
            turtle.drop()
        end
        app.updateTurtleInfo()
        gui.notify("Dropped inventory", colors.white, gui.getColor("warning"), 2)
    end)
    dropBtn.bgColor = gui.getColor("error")
    
    -- Back button
    local returnBtn = components.createButton("return", 15, 18, 20, 2, "Back to Main",
        function()
            app.createMainScreen()
        end)
    
    gui.draw()
end

-- ========== INVENTORY SCREEN ==========

function app.showInventoryScreen()
    app.state.currentScreen = "inventory"
    gui.clearComponents()
    
    gui.centerText("Turtle Inventory", 1, gui.getColor("primary"), colors.white)
    
    -- Inventory grid
    local panel = components.createPanel("inv", 5, 3, 41, 14, "16 Slots")
    panel.borderColor = gui.getColor("border")
    
    -- Show slots in 4x4 grid
    for slot = 1, 16 do
        local row = math.floor((slot - 1) / 4)
        local col = (slot - 1) % 4
        
        local x = 7 + (col * 10)
        local y = 5 + (row * 3)
        
        local item = turtle.getItemDetail(slot)
        local slotText = tostring(slot)
        if item then
            slotText = slotText .. ":" .. item.count
        end
        
        local slotBtn = components.createButton("slot" .. slot, x, y, 9, 2, slotText, function()
            turtle.select(slot)
            gui.notify("Selected slot " .. slot, colors.white, gui.getColor("primary"), 1)
        end)
        slotBtn.bgColor = item and gui.getColor("success") or colors.gray
    end
    
    -- Back button
    local returnBtn = components.createButton("return", 15, 18, 20, 2, "Back",
        function()
            app.showMineScreen()
        end)
    
    gui.draw()
end

-- ========== NETWORK SCREEN ==========

function app.showNetworkScreen()
    app.state.currentScreen = "network"
    gui.clearComponents()
    
    gui.centerText("Network Status", 1, gui.getColor("primary"), colors.white)
    
    local status = app.state.networkStatus or {}
    
    -- Connection Panel
    local connPanel = components.createPanel("conn", 2, 3, 47, 7, "Connection")
    connPanel.borderColor = gui.getColor("border")
    
    local connLabel = components.createLabel("connStatus", 4, 5,
        status.connected and "Status: Connected" or "Status: Disconnected")
    connLabel.fgColor = status.connected and gui.getColor("success") or gui.getColor("error")
    
    local idLabel = components.createLabel("id", 4, 6,
        string.format("ID: %d", os.getComputerID()))
    
    local labelText = os.getComputerLabel() or "Unlabeled"
    local labelLabel = components.createLabel("label", 4, 7,
        string.format("Label: %s", labelText))
    
    if status.coordinatorId then
        local coordLabel = components.createLabel("coord", 4, 8,
            string.format("Coordinator: %d", status.coordinatorId))
    end
    
    -- Project Panel
    if status.currentProject then
        local projPanel = components.createPanel("proj", 2, 11, 47, 7, "Current Project")
        projPanel.borderColor = gui.getColor("border")
        
        local projName = components.createLabel("projName", 4, 13,
            "Project: " .. (status.currentProject.name or "Unknown"))
        
        if status.assignment then
            local zoneLabel = components.createLabel("zone", 4, 14,
                string.format("Zone: %d", status.assignment.zone or 0))
            
            local instrLabel = components.createLabel("instr", 4, 15,
                status.assignment.instructions or "Awaiting instructions...")
            instrLabel.fgColor = gui.getColor("warning")
        end
        
        -- Peers
        if status.peers and #status.peers > 0 then
            local peerLabel = components.createLabel("peerLbl", 4, 16,
                string.format("Teammates: %d turtles", #status.peers))
            peerLabel.fgColor = gui.getColor("primary")
        end
    else
        local noProjLabel = components.createLabel("noProj", 4, 12,
            "No project assigned")
        noProjLabel.fgColor = colors.gray
    end
    
    -- Control Buttons
    local btnY = 18
    
    if not app.state.networkEnabled then
        local enableBtn = components.createButton("enable", 5, btnY, 18, 2, "Enable Network",
            function()
                app.enableNetwork()
            end)
        enableBtn.bgColor = gui.getColor("success")
    else
        local refreshBtn = components.createButton("refresh", 5, btnY, 18, 2, "Refresh",
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
