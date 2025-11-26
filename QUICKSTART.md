# CCMine GUI Framework - Quick Start Guide

Get started with the CCMine GUI framework in 5 minutes!

## Installation

### Method 1: Direct Download (ComputerCraft)

In ComputerCraft, run these commands:

```lua
-- Download all files
pastebin get <code> gui-core.lua
pastebin get <code> gui-components.lua
pastebin get <code> gui-layouts.lua
pastebin get <code> gui-demo.lua
pastebin get <code> main.lua
```

### Method 2: Manual Copy

Copy these files to your ComputerCraft computer:
- `gui-core.lua`
- `gui-components.lua`
- `gui-layouts.lua`
- `gui-demo.lua` (optional - for examples)
- `main.lua` (optional - example app)

## Running the Demo

```lua
lua> demo = require("gui-demo")
lua> demo.run()
```

This will show you 6 interactive demos of all framework features.

## Your First GUI App

Create a file called `myapp.lua`:

```lua
local gui = require("gui-core")
local components = require("gui-components")

-- Initialize
gui.init()
gui.clear()

-- Create a panel
local panel = components.createPanel("main", 5, 3, 40, 12, "My First App")
panel.borderColor = gui.getColor("border")

-- Add a button
local button = components.createButton("btn1", 10, 7, 20, 3, "Click Me!",
    function()
        print("Button clicked!")
    end)
button.bgColor = gui.getColor("success")

-- Add a label
local label = components.createLabel("lbl1", 10, 11, "Welcome to CCMine!")

-- Draw
gui.draw()

-- Event loop
while true do
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "mouse_click" then
        gui.handleClick(p2, p3, p1)
        gui.draw()
    elseif event == "key" and p1 == keys.q then
        break
    end
end

-- Cleanup
gui.clearComponents()
gui.clear()
print("Exited")
```

Run it:
```lua
lua> shell.run("myapp")
```

## Common Patterns

### 1. Multiple Screens

```lua
function showMainMenu()
    gui.clearComponents()
    -- Create main menu components
    local btn = components.createButton("start", 10, 5, 20, 3, "Start",
        function() showGameScreen() end)
    gui.draw()
end

function showGameScreen()
    gui.clearComponents()
    -- Create game components
    local backBtn = components.createButton("back", 10, 15, 20, 3, "Back",
        function() showMainMenu() end)
    gui.draw()
end

showMainMenu()
```

### 2. Updating Values

```lua
local fuelBar = components.createProgressBar("fuel", 5, 5, 30)
fuelBar.value = 50

-- Update later
function updateFuel(newValue)
    fuelBar.value = newValue
    gui.requestRedraw()
    gui.draw()
end
```

### 3. Using Layouts

```lua
local layouts = require("gui-layouts")

-- Create regions
local regions = layouts.createRegions({
    header = 3,
    footer = 2
})

-- Use regions
local header = components.createPanel("header",
    regions.header.x, regions.header.y,
    regions.header.width, regions.header.height,
    "Header")
```

### 4. Lists with Actions

```lua
local list = components.createList("tasks", 5, 5, 30, 10)

list:addItem("Mine Branch 1", {action = "mine", id = 1})
list:addItem("Return to Base", {action = "return"})
list:addItem("Refuel", {action = "refuel"})

list.onSelect = function(item)
    if item.data.action == "mine" then
        startMining(item.data.id)
    elseif item.data.action == "return" then
        returnToBase()
    end
end
```

### 5. Form Inputs

```lua
local nameInput = components.createTextInput("name", 10, 5, 30, "Enter name...")
local enabledCheck = components.createCheckbox("enabled", 10, 7, "Enabled", true)

local submitBtn = components.createButton("submit", 10, 10, 20, 3, "Submit",
    function()
        local name = nameInput.value
        local enabled = enabledCheck.checked
        print("Name: " .. name .. ", Enabled: " .. tostring(enabled))
    end)
```

## Running the Example App

The included `main.lua` shows a complete mining control application:

```lua
lua> app = require("main")
lua> app.run()
```

Features:
- Main control screen with status
- Configuration screen with inputs
- Manual control screen with buttons
- Statistics screen with lists
- Real-time status updates

## Keyboard Shortcuts

In the demo and example app:
- `Q` - Exit (some screens)
- `Ctrl+Q` - Force exit (main app)

## Tips for Success

1. **Always call `gui.draw()` after changes** - The GUI won't update otherwise
2. **Use `gui.clearComponents()` when switching screens** - Prevents component overlap
3. **Store component references** - You'll need them to update values
4. **Handle all event types** - At minimum: mouse_click, key
5. **Test on actual ComputerCraft** - Behavior may differ from desktop Lua

## Common Issues

### Components not showing
- Did you call `gui.draw()`?
- Is the component visible? Check `component.visible`
- Is it off-screen? Check x, y, width, height

### Click not working
- Are you calling `gui.handleClick()` in the event loop?
- Is the component enabled? Check `component.enabled`
- Is another component overlapping? Check zIndex

### Theme not applying
- Call `gui.setTheme()` before creating components
- Or set colors manually on existing components

## Next Steps

1. Read the full [README.md](README.md) for complete API documentation
2. Study the demos in `gui-demo.lua` for advanced examples
3. Look at `main.lua` for a complete application structure
4. Build your own mining/automation GUI!

## Example Project Structure

```
my-mining-project/
├── gui-core.lua         - Framework core
├── gui-components.lua   - UI components
├── gui-layouts.lua      - Layouts
├── main.lua             - Your main app
├── mining.lua           - Mining logic
├── navigation.lua       - Turtle movement
└── config.lua           - Configuration
```

## Support

- Check README.md for full API documentation
- Run gui-demo.lua to see examples
- Experiment with the code - it's designed to be modified!

## What's Next?

Now that you have a GUI framework, consider adding:
- Mining algorithms
- Pathfinding
- Inventory management
- Networking (for multi-turtle control)
- Data persistence
- Remote monitoring

Happy coding! 🚀

