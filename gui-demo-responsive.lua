-- CCMine GUI Framework - Responsive Demo
-- Auto-adjusts to ComputerCraft screen size (51x19 or smaller)

local gui = require("gui-core")
local components = require("gui-components")
local layouts = require("gui-layouts")

local demo = {}

-- Get screen dimensions
local screenW, screenH = gui.init()

-- Calculate responsive sizes
local btnWidth = math.min(screenW - 6, 40)  -- Max 40, min margins
local btnHeight = 2
local spacing = 1

-- ========== DEMO 1: BASIC BUTTONS ==========

function demo.basicButtons()
    gui.clearComponents()
    gui.clear()
    
    -- Title
    gui.centerText("Basic Buttons", 1, gui.getColor("primary"), colors.white)
    
    -- Calculate button positions
    local col1X = 3
    local col2X = math.floor(screenW / 2) + 2
    local btnW = math.floor((screenW - 8) / 2)
    
    -- Create buttons
    local btn1 = components.createButton("btn1", col1X, 4, btnW, 2, "Click Me", function()
        print("Button 1!")
    end)
    
    local btn2 = components.createButton("btn2", col2X, 4, btnW, 2, "Success", function()
        print("Success!")
    end)
    btn2.bgColor = gui.getColor("success")
    
    local btn3 = components.createButton("btn3", col1X, 7, btnW, 2, "Warning", function()
        print("Warning!")
    end)
    btn3.bgColor = gui.getColor("warning")
    
    local btn4 = components.createButton("btn4", col2X, 7, btnW, 2, "Disabled", function()
        print("Not clickable")
    end)
    btn4.enabled = false
    
    -- Back button
    local backBtn = components.createButton("back", col1X, screenH - 3, btnWidth, 2, "Back to Menu", function()
        gui.clearComponents()
        demo.mainMenu()
    end)
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== DEMO 2: PANELS AND LABELS ==========

function demo.panelsAndLabels()
    gui.clearComponents()
    gui.clear()
    
    -- Title
    gui.centerText("Panels & Labels", 1, gui.getColor("primary"), colors.white)
    
    -- Main panel - responsive size
    local panelW = screenW - 4
    local panelH = screenH - 7
    local panel = components.createPanel("main", 3, 3, panelW, panelH, "Status")
    panel.bgColor = gui.getColor("secondary")
    
    -- Labels inside panel
    local label1 = components.createLabel("lbl1", 5, 5, "Fuel: 5000")
    label1.fgColor = gui.getColor("success")
    
    local label2 = components.createLabel("lbl2", 5, 7, "Position: X:100 Y:64")
    
    local label3 = components.createLabel("lbl3", 5, 9, "Status: Operating")
    label3.fgColor = gui.getColor("success")
    
    -- Progress bar
    local progress = components.createProgressBar("prog1", 5, 11, panelW - 6)
    progress.value = 75
    
    -- Back button
    local backBtn = components.createButton("back", 3, screenH - 2, btnWidth, 2, "Back", function()
        gui.clearComponents()
        demo.mainMenu()
    end)
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== DEMO 3: LIST COMPONENT ==========

function demo.listDemo()
    gui.clearComponents()
    gui.clear()
    
    -- Title
    gui.centerText("Task List", 1, gui.getColor("primary"), colors.white)
    
    -- Create list
    local listW = screenW - 6
    local listH = screenH - 7
    local taskList = components.createList("tasks", 4, 3, listW, listH)
    
    -- Add items
    taskList:addItem("1. Mine Branch", {id = 1})
    taskList:addItem("2. Return Home", {id = 2})
    taskList:addItem("3. Refuel", {id = 3})
    taskList:addItem("4. Empty Inventory", {id = 4})
    taskList:addItem("5. Check Status", {id = 5})
    
    taskList.onSelect = function(item)
        print("Selected: " .. item.text)
    end
    
    -- Back button
    local backBtn = components.createButton("back", 4, screenH - 2, btnWidth, 2, "Back", function()
        gui.clearComponents()
        demo.mainMenu()
    end)
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== DEMO 4: INPUT AND CHECKBOX ==========

function demo.inputDemo()
    gui.clearComponents()
    gui.clear()
    
    -- Title
    gui.centerText("Configuration", 1, gui.getColor("primary"), colors.white)
    
    -- Input width
    local inputW = math.min(20, screenW - 22)
    
    -- Branch Length
    local lbl1 = components.createLabel("lbl1", 3, 4, "Length:")
    local input1 = components.createTextInput("input1", 12, 4, inputW, "32")
    input1.value = "32"
    
    -- Branch Width
    local lbl2 = components.createLabel("lbl2", 3, 6, "Width:")
    local input2 = components.createTextInput("input2", 12, 6, inputW, "3")
    input2.value = "3"
    
    -- Checkboxes
    local check1 = components.createCheckbox("check1", 3, 9, "Torches", true)
    local check2 = components.createCheckbox("check2", 3, 11, "Auto-refuel", false)
    
    -- Buttons
    local btnW2 = math.floor((btnWidth - 2) / 2)
    local saveBtn = components.createButton("save", 3, screenH - 2, btnW2, 2, "Save", function()
        print("Saved!")
    end)
    saveBtn.bgColor = gui.getColor("success")
    
    local backBtn = components.createButton("back", 3 + btnW2 + 2, screenH - 2, btnW2, 2, "Back", function()
        gui.clearComponents()
        demo.mainMenu()
    end)
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== MAIN MENU ==========

function demo.mainMenu()
    gui.clearComponents()
    gui.clear()
    
    -- Title bar
    gui.screen.term.setBackgroundColor(gui.getColor("primary"))
    gui.screen.term.setTextColor(colors.white)
    gui.screen.term.setCursorPos(1, 1)
    gui.screen.term.clearLine()
    gui.centerText("CCMine GUI Framework", 1)
    
    gui.screen.term.setBackgroundColor(gui.getColor("background"))
    gui.centerText("Select a Demo", 2)
    
    -- Calculate menu button size
    local menuBtnW = screenW - 6
    local menuBtnX = 4
    local startY = 4
    
    -- Create menu buttons
    local btn1 = components.createButton("menu1", menuBtnX, startY, menuBtnW, 2, "1. Basic Buttons", function()
        gui.clearComponents()
        demo.basicButtons()
    end)
    
    local btn2 = components.createButton("menu2", menuBtnX, startY + 3, menuBtnW, 2, "2. Panels & Labels", function()
        gui.clearComponents()
        demo.panelsAndLabels()
    end)
    
    local btn3 = components.createButton("menu3", menuBtnX, startY + 6, menuBtnW, 2, "3. List Component", function()
        gui.clearComponents()
        demo.listDemo()
    end)
    
    local btn4 = components.createButton("menu4", menuBtnX, startY + 9, menuBtnW, 2, "4. Inputs & Forms", function()
        gui.clearComponents()
        demo.inputDemo()
    end)
    
    -- Exit button
    local exitBtn = components.createButton("exit", menuBtnX, screenH - 2, menuBtnW, 2, "Exit", function()
        gui.clearComponents()
        gui.clear()
        print("Exited")
    end)
    exitBtn.bgColor = gui.getColor("error")
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== EVENT LOOP ==========

function demo.runEventLoop()
    while true do
        local event, param1, param2, param3 = os.pullEvent()
        
        if event == "mouse_click" then
            local clicked = gui.handleClick(param2, param3, param1)
            if clicked then
                gui.draw()
            end
        elseif event == "mouse_move" then
            gui.handleMouseMove(param2, param3)
            gui.draw()
        elseif event == "key" then
            if param1 == keys.q then
                gui.clearComponents()
                gui.clear()
                print("Exited")
                break
            end
        end
    end
end

-- ========== RUN DEMO ==========

function demo.run()
    demo.mainMenu()
end

-- Auto-run if executed directly
if not ... then
    demo.run()
end

return demo

