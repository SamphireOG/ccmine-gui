# CCMine GUI Framework

A modern, component-based GUI framework for ComputerCraft turtles and computers.

## Features

### Core Features
- **Component-Based Architecture** - Modular, reusable UI components
- **Event System** - Robust event handling with mouse and keyboard support
- **Theme Support** - Multiple built-in themes (default, dark, light)
- **Layout Manager** - Automatic component positioning and responsive layouts
- **Error Handling** - Comprehensive error catching and user-friendly error display

### Components

#### Basic Components
- **Panel** - Container with optional title bar
- **Button** - Interactive buttons with hover/press states
- **Label** - Text labels with alignment options
- **TextInput** - Text input fields with placeholders
- **ProgressBar** - Visual progress indicators
- **List** - Scrollable lists with selection
- **Checkbox** - Toggle checkboxes with labels

#### Component Features
- Visibility control
- Enable/disable states
- Custom colors and styling
- Parent-child relationships
- Z-index layering
- Event callbacks

### Layouts

#### Layout Types
- **VerticalLayout** - Stack components vertically
- **HorizontalLayout** - Stack components horizontally
- **GridLayout** - Arrange in rows and columns
- **StackLayout** - Overlay components (tab-like)
- **AnchorLayout** - Absolute positioning with anchors

#### Layout Helpers
- `centerComponent()` - Center a component on screen
- `fillScreen()` - Make component fill the screen
- `splitVertical()` - Split screen vertically
- `splitHorizontal()` - Split screen horizontally
- `createRegions()` - Create header/footer/sidebar regions

## Quick Start

### 1. Basic Setup

```lua
local gui = require("gui-core")
local components = require("gui-components")

-- Initialize the GUI
gui.init()
gui.clear()

-- Create a button
local button = components.createButton(
    "myButton",     -- ID
    10, 5,          -- x, y
    20, 3,          -- width, height
    "Click Me",     -- text
    function()      -- callback
        print("Button clicked!")
    end
)

-- Draw the GUI
gui.draw()
```

### 2. Event Loop

```lua
while true do
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "mouse_click" then
        gui.handleClick(p2, p3, p1)
        gui.draw()
    elseif event == "key" and p1 == keys.q then
        break
    end
end
```

### 3. Using Panels

```lua
-- Create a panel
local panel = components.createPanel("panel1", 5, 3, 40, 12, "My Panel")
panel.borderColor = gui.getColor("border")

-- Add components inside the panel
local label = components.createLabel("label1", 7, 5, "Welcome!")
local progress = components.createProgressBar("prog1", 7, 7, 36)
progress.value = 75
```

### 4. Using Layouts

```lua
local layouts = require("gui-layouts")

-- Create a vertical layout
local vLayout = layouts.createVerticalLayout(1, 2)

-- Add components
vLayout:add(button1)
vLayout:add(button2)
vLayout:add(button3)

-- Apply the layout
vLayout:apply(1, 1, 51, 19)
```

### 5. Themes

```lua
-- Change theme
gui.setTheme("dark")    -- or "light", "default"

-- Get theme colors
local primaryColor = gui.getColor("primary")
local successColor = gui.getColor("success")
```

## Component API

### Button

```lua
local btn = components.createButton(id, x, y, width, height, text, callback)

-- Properties
btn.enabled = true
btn.visible = true
btn.bgColor = colors.blue
btn.fgColor = colors.white
btn.icon = ">"

-- Events
btn:on("click", function(self, x, y) ... end)
btn:on("mouseEnter", function(self) ... end)
btn:on("mouseLeave", function(self) ... end)
```

### Panel

```lua
local panel = components.createPanel(id, x, y, width, height, title)

-- Properties
panel.title = "My Panel"
panel.titleBgColor = colors.blue
panel.scrollable = false
panel.borderColor = colors.gray

-- Methods
panel:addChild(childComponent)
panel:removeChild(childComponent)
```

### List

```lua
local list = components.createList(id, x, y, width, height)

-- Methods
list:addItem("Item Text", {custom = "data"})
list:clearItems()

-- Properties
list.selectedIndex = 1
list.onSelect = function(item) ... end

-- Events
list:on("select", function(self, item) ... end)
```

### TextInput

```lua
local input = components.createTextInput(id, x, y, width, placeholder)

-- Properties
input.value = "text"
input.placeholder = "Enter text..."
input.maxLength = 50
input.isFocused = false

-- Events
input:on("change", function(self, newValue) ... end)
```

### ProgressBar

```lua
local bar = components.createProgressBar(id, x, y, width)

-- Properties
bar.value = 75  -- 0-100
bar.showLabel = true
bar.fillColor = colors.green
bar.bgColor = colors.gray
```

### Checkbox

```lua
local check = components.createCheckbox(id, x, y, label, checked)

-- Properties
check.checked = true
check.onChange = function(checked) ... end

-- Events
check:on("change", function(self, checked) ... end)
```

## Layout API

### Vertical Layout

```lua
local layout = layouts.createVerticalLayout(spacing, padding)
layout:add(component)
layout:apply(x, y, width, height)
```

### Grid Layout

```lua
local grid = layouts.createGridLayout(columns, rows, spacing, padding)
grid:add(component1)
grid:add(component2)
grid:apply(x, y, width, height)
```

### Regions

```lua
local regions = layouts.createRegions({
    header = 3,      -- Fixed height
    footer = 2,      -- Fixed height
    sidebar = 15,    -- Fixed width
    content = true   -- Remaining space
})

-- Use regions
panel.x = regions.header.x
panel.y = regions.header.y
panel.width = regions.header.width
panel.height = regions.header.height
```

## Event System

### Component Events

All components support these events:
- `click` - Mouse click on component
- `mouseEnter` - Mouse enters component area
- `mouseLeave` - Mouse leaves component area
- `mouseMove` - Mouse moves within component
- `drag` - Mouse drag on component
- `scroll` - Scroll wheel on component

### Custom Events

```lua
component:on("customEvent", function(self, ...)
    -- Handle event
end)

component:emit("customEvent", data1, data2)
```

## Complete Example

```lua
local gui = require("gui-core")
local components = require("gui-components")
local layouts = require("gui-layouts")

-- Initialize
gui.init()
gui.setTheme("dark")

-- Create regions
local regions = layouts.createRegions({
    header = 3,
    footer = 2
})

-- Header
local header = components.createPanel("header", 
    regions.header.x, regions.header.y,
    regions.header.width, regions.header.height,
    "Mining Control System")

-- Content
local statusLabel = components.createLabel("status", 5, 5, "Status: Ready")
statusLabel.fgColor = colors.green

local fuelBar = components.createProgressBar("fuel", 5, 7, 40)
fuelBar.value = 80

local startBtn = components.createButton("start", 5, 10, 15, 3, "Start Mining", function()
    print("Mining started!")
end)
startBtn.bgColor = gui.getColor("success")

local stopBtn = components.createButton("stop", 25, 10, 15, 3, "Stop", function()
    print("Mining stopped!")
end)
stopBtn.bgColor = gui.getColor("error")

-- Footer
local exitBtn = components.createButton("exit", 2, regions.footer.y, 15, 2, "Exit", function()
    gui.clearComponents()
end)

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
```

## Running the Demo

```lua
-- Load and run the demo
local demo = require("gui-demo")
demo.run()
```

The demo includes 6 interactive examples showing all framework features.

## File Structure

```
CCMine/
├── gui-core.lua         - Core framework
├── gui-components.lua   - UI components
├── gui-layouts.lua      - Layout manager
├── gui-demo.lua         - Demo application
└── README.md            - This file
```

## Tips

1. **Always call `gui.draw()` after making changes** to components
2. **Use `gui.requestRedraw()` to mark the screen as needing a redraw**
3. **Handle events in your main loop** for interactive components
4. **Use layouts** for responsive designs that adapt to screen size
5. **Set themes early** before creating components for consistent styling
6. **Use panels as containers** to group related components
7. **Check `component.visible` and `component.enabled`** to control interaction

## Performance

- Components only redraw when `gui.state.needsRedraw` is true
- Use `zIndex` to control draw order (higher = drawn on top)
- Minimize component updates in tight loops
- Use event delegation for lists with many items

## License

Open source - feel free to use, modify, and extend!

## Credits

Built for ComputerCraft by the CCMine team.
Based on modern GUI framework patterns adapted for Lua and ComputerCraft.

