-- CCMine GUI Framework - Demo & Examples
-- Shows how to use the GUI framework

local gui = require("gui-core")
local components = require("gui-components")
local layouts = require("gui-layouts")

local demo = {}

-- ========== DEMO 1: BASIC BUTTONS ==========

function demo.basicButtons()
    gui.init()
    gui.clear()
    
    -- Title
    gui.centerText("CCMine GUI Demo - Basic Buttons", 1, 
        gui.getColor("primary"), colors.white)
    
    -- Create some buttons
    local btn1 = components.createButton("btn1", 5, 4, 15, 3, "Click Me", function()
        print("Button 1 clicked!")
    end)
    
    local btn2 = components.createButton("btn2", 25, 4, 15, 3, "Success", function()
        print("Success button clicked!")
    end)
    btn2.bgColor = gui.getColor("success")
    
    local btn3 = components.createButton("btn3", 5, 8, 15, 3, "Warning", function()
        print("Warning button clicked!")
    end)
    btn3.bgColor = gui.getColor("warning")
    
    local btn4 = components.createButton("btn4", 25, 8, 15, 3, "Disabled", function()
        print("This shouldn't happen")
    end)
    btn4.enabled = false
    
    -- Exit button
    local exitBtn = components.createButton("exit", 15, 15, 20, 3, "Exit Demo", function()
        gui.clearComponents()
        demo.mainMenu()
    end)
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== DEMO 2: PANELS AND LABELS ==========

function demo.panelsAndLabels()
    gui.init()
    gui.clear()
    
    -- Create main panel
    local mainPanel = components.createPanel("main", 2, 2, 47, 15, "System Status")
    mainPanel.bgColor = gui.getColor("secondary")
    
    -- Add labels
    local label1 = components.createLabel("lbl1", 4, 4, "Fuel Level: 5000")
    label1.fgColor = gui.getColor("success")
    
    local label2 = components.createLabel("lbl2", 4, 6, "Position: X:100 Y:64 Z:200")
    
    local label3 = components.createLabel("lbl3", 4, 8, "Status: Operating")
    label3.fgColor = gui.getColor("success")
    
    -- Add progress bar
    local progress = components.createProgressBar("prog1", 4, 10, 43)
    progress.value = 75
    
    -- Back button
    local backBtn = components.createButton("back", 15, 13, 20, 2, "Back", function()
        gui.clearComponents()
        demo.mainMenu()
    end)
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== DEMO 3: LIST COMPONENT ==========

function demo.listDemo()
    gui.init()
    gui.clear()
    
    -- Title
    gui.centerText("Select a Task", 1, gui.getColor("primary"), colors.white)
    
    -- Create list
    local taskList = components.createList("tasks", 5, 3, 40, 12)
    taskList.borderColor = gui.getColor("border")
    
    -- Add items
    taskList:addItem("Mine Branch 1", {id = 1, type = "mine"})
    taskList:addItem("Return to Base", {id = 2, type = "return"})
    taskList:addItem("Refuel Turtle", {id = 3, type = "refuel"})
    taskList:addItem("Empty Inventory", {id = 4, type = "empty"})
    taskList:addItem("Check Status", {id = 5, type = "status"})
    
    taskList.onSelect = function(item)
        print("Selected: " .. item.text)
    end
    
    -- Back button
    local backBtn = components.createButton("back", 15, 16, 20, 2, "Back", function()
        gui.clearComponents()
        demo.mainMenu()
    end)
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== DEMO 4: INPUT AND CHECKBOX ==========

function demo.inputDemo()
    gui.init()
    gui.clear()
    
    -- Title
    gui.centerText("Configuration", 1, gui.getColor("primary"), colors.white)
    
    -- Labels and inputs
    local lbl1 = components.createLabel("lbl1", 5, 4, "Branch Length:")
    local input1 = components.createTextInput("input1", 20, 4, 20, "Enter length...")
    
    local lbl2 = components.createLabel("lbl2", 5, 6, "Branch Width:")
    local input2 = components.createTextInput("input2", 20, 6, 20, "Enter width...")
    
    -- Checkboxes
    local check1 = components.createCheckbox("check1", 5, 9, "Place torches", true)
    local check2 = components.createCheckbox("check2", 5, 11, "Auto-refuel", false)
    local check3 = components.createCheckbox("check3", 5, 13, "Return when full", true)
    
    -- Buttons
    local saveBtn = components.createButton("save", 5, 16, 15, 2, "Save", function()
        print("Configuration saved!")
    end)
    saveBtn.bgColor = gui.getColor("success")
    
    local backBtn = components.createButton("back", 25, 16, 15, 2, "Back", function()
        gui.clearComponents()
        demo.mainMenu()
    end)
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== DEMO 5: LAYOUTS ==========

function demo.layoutDemo()
    gui.init()
    gui.clear()
    
    -- Title
    gui.centerText("Layout Manager Demo", 1, gui.getColor("primary"), colors.white)
    
    -- Create regions
    local regions = layouts.createRegions({
        header = 3,
        footer = 2,
        sidebar = 15
    })
    
    -- Header panel
    local header = components.createPanel("header", 
        regions.header.x, regions.header.y,
        regions.header.width, regions.header.height,
        "Header")
    
    -- Sidebar panel
    local sidebar = components.createPanel("sidebar",
        regions.sidebar.x, regions.sidebar.y,
        regions.sidebar.width, regions.sidebar.height,
        "Menu")
    
    -- Content panel
    local content = components.createPanel("content",
        regions.content.x, regions.content.y,
        regions.content.width, regions.content.height,
        "Content Area")
    
    -- Footer buttons
    local backBtn = components.createButton("back", 2, regions.footer.y, 15, 2, "Back", function()
        gui.clearComponents()
        demo.mainMenu()
    end)
    
    local nextBtn = components.createButton("next", 35, regions.footer.y, 15, 2, "Themes", function()
        gui.clearComponents()
        demo.themeDemo()
    end)
    nextBtn.bgColor = gui.getColor("success")
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== DEMO 6: THEMES ==========

function demo.themeDemo()
    gui.init()
    gui.clear()
    
    -- Title
    gui.centerText("Theme Demo", 1, gui.getColor("primary"), colors.white)
    
    -- Theme buttons
    local defaultBtn = components.createButton("default", 5, 4, 15, 3, "Default", function()
        gui.setTheme("default")
        gui.clearComponents()
        demo.themeDemo()
    end)
    
    local darkBtn = components.createButton("dark", 5, 8, 15, 3, "Dark", function()
        gui.setTheme("dark")
        gui.clearComponents()
        demo.themeDemo()
    end)
    
    local lightBtn = components.createButton("light", 5, 12, 15, 3, "Light", function()
        gui.setTheme("light")
        gui.clearComponents()
        demo.themeDemo()
    end)
    
    -- Sample components to show theme
    local panel = components.createPanel("sample", 25, 4, 22, 11, "Sample Panel")
    panel.borderColor = gui.getColor("border")
    
    local label = components.createLabel("samplelbl", 27, 6, "Sample Label")
    
    local progress = components.createProgressBar("sampleprog", 27, 8, 18)
    progress.value = 60
    
    local checkbox = components.createCheckbox("samplecheck", 27, 10, "Checkbox", true)
    
    -- Back button
    local backBtn = components.createButton("back", 15, 16, 20, 2, "Back to Menu", function()
        gui.clearComponents()
        demo.mainMenu()
    end)
    
    gui.draw()
    demo.runEventLoop()
end

-- ========== MAIN MENU ==========

function demo.mainMenu()
    gui.init()
    gui.clear()
    
    -- Title
    gui.screen.term.setBackgroundColor(gui.getColor("primary"))
    gui.screen.term.setTextColor(colors.white)
    gui.screen.term.setCursorPos(1, 1)
    gui.screen.term.clearLine()
    gui.centerText("CCMine GUI Framework", 1)
    
    gui.screen.term.setBackgroundColor(gui.getColor("background"))
    gui.screen.term.setTextColor(gui.getColor("foreground"))
    gui.screen.term.setCursorPos(1, 2)
    gui.centerText("Select a Demo", 2)
    
    -- Menu buttons in vertical layout
    local menuLayout = layouts.createVerticalLayout(1, 2)
    
    local btn1 = components.createButton("menu1", 10, 5, 30, 2, "1. Basic Buttons", function()
        gui.clearComponents()
        demo.basicButtons()
    end)
    menuLayout:add(btn1)
    
    local btn2 = components.createButton("menu2", 10, 8, 30, 2, "2. Panels & Labels", function()
        gui.clearComponents()
        demo.panelsAndLabels()
    end)
    menuLayout:add(btn2)
    
    local btn3 = components.createButton("menu3", 10, 11, 30, 2, "3. List Component", function()
        gui.clearComponents()
        demo.listDemo()
    end)
    menuLayout:add(btn3)
    
    local btn4 = components.createButton("menu4", 10, 14, 30, 2, "4. Inputs & Checkboxes", function()
        gui.clearComponents()
        demo.inputDemo()
    end)
    menuLayout:add(btn4)
    
    -- Second column
    local btn5 = components.createButton("menu5", 10, 5, 30, 2, "5. Layouts", function()
        gui.clearComponents()
        demo.layoutDemo()
    end)
    
    local btn6 = components.createButton("menu6", 10, 8, 30, 2, "6. Themes", function()
        gui.clearComponents()
        demo.themeDemo()
    end)
    
    -- Apply layout
    menuLayout:apply(1, 4, 51, 15)
    
    -- Exit button
    local exitBtn = components.createButton("exit", 15, 17, 20, 2, "Exit", function()
        gui.clearComponents()
        gui.clear()
        print("GUI Demo Exited")
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
        elseif event == "mouse_drag" then
            gui.handleMouseMove(param2, param3)
            gui.handleDrag(param2, param3)
        elseif event == "mouse_scroll" then
            gui.handleScroll(param2, param3, param1)
            gui.draw()
        elseif event == "mouse_move" then
            gui.handleMouseMove(param2, param3)
            gui.draw()
        elseif event == "term_resize" then
            gui.init()
            gui.draw()
        elseif event == "key" then
            -- Handle keyboard events
            if param1 == keys.q then
                gui.clearComponents()
                gui.clear()
                print("Exited by 'Q' key")
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

