# Responsive Layout Guide

## Overview

CCMine GUI Framework now includes responsive layout helpers in `gui-layouts.lua` to make creating adaptive interfaces easy.

## Quick Start

```lua
local gui = require("gui-core")
local layouts = require("gui-layouts")
local components = require("gui-components")

-- Get screen size
local w, h = layouts.getScreenSize()

-- Create full-width panel
local panel = layouts.createFullWidthPanel("main", 3, 10, "My Panel")

-- Create responsive button row
local _, positions = layouts.calculateButtonRow(4, 1, 0)
for i = 1, 4 do
    components.createButton("btn" .. i, 
        positions[i].x, 10, positions[i].width, 2, 
        "Button " .. i, function() end)
end
```

## API Reference

### Screen Information

#### `layouts.getScreenSize()`
Returns current screen dimensions.

```lua
local width, height = layouts.getScreenSize()
-- Same as term.getSize() but more semantic
```

---

### Button Rows

#### `layouts.calculateButtonRow(numButtons, spacing, margin)`
Calculate responsive button positions for a horizontal row.

**Parameters:**
- `numButtons` (number) - Number of buttons in the row
- `spacing` (number, optional) - Gap between buttons (default: 1)
- `margin` (number, optional) - Margin from screen edges (default: 0)

**Returns:**
- `buttonWidth` (number) - Calculated width for each button
- `positions` (table) - Array of {x, width} for each button

**Example:**
```lua
local _, positions = layouts.calculateButtonRow(3, 1, 2)
-- Creates 3 buttons with 1-space gaps and 2-space margins

local btn1 = components.createButton("b1", positions[1].x, 10, positions[1].width, 2, "One")
local btn2 = components.createButton("b2", positions[2].x, 10, positions[2].width, 2, "Two")
local btn3 = components.createButton("b3", positions[3].x, 10, positions[3].width, 2, "Three")
```

---

### Grid Layouts

#### `layouts.createResponsiveGrid(cols, rows, spacing, margin)`
Calculate positions for a responsive grid.

**Parameters:**
- `cols` (number) - Number of columns
- `rows` (number) - Number of rows
- `spacing` (number, optional) - Gap between cells (default: 1)
- `margin` (number, optional) - Margin from screen edges (default: 1)

**Returns:**
- `cellWidth` (number) - Width of each cell
- `cellHeight` (number) - Height of each cell
- `positions` (table) - 2D array [row][col] of {x, y, width, height}

**Example:**
```lua
local _, _, grid = layouts.createResponsiveGrid(4, 4, 1, 2)

-- Create 4x4 grid of inventory slots
for row = 1, 4 do
    for col = 1, 4 do
        local pos = grid[row][col]
        local slot = ((row - 1) * 4) + col
        components.createButton("slot" .. slot, 
            pos.x, pos.y, pos.width, pos.height,
            tostring(slot))
    end
end
```

---

### Panels

#### `layouts.createFullWidthPanel(id, y, height, title)`
Create a panel that spans the full screen width.

**Parameters:**
- `id` (string) - Component ID
- `y` (number) - Y position
- `height` (number) - Panel height
- `title` (string) - Panel title

**Returns:**
- Panel component

**Example:**
```lua
local statusPanel = layouts.createFullWidthPanel("status", 5, 8, "Status")
statusPanel.borderColor = gui.getColor("border")
```

---

### Centering

#### `layouts.centerHorizontally(componentWidth)`
Calculate X position to center a component horizontally.

```lua
local x = layouts.centerHorizontally(20)
components.createButton("centered", x, 10, 20, 2, "Centered")
```

#### `layouts.centerVertically(componentHeight)`
Calculate Y position to center a component vertically.

```lua
local y = layouts.centerVertically(10)
```

#### `layouts.centerBoth(componentWidth, componentHeight)`
Calculate X and Y to center a component.

```lua
local x, y = layouts.centerBoth(30, 10)
components.createPanel("centered", x, y, 30, 10, "Centered Panel")
```

---

### Column Layouts

#### `layouts.calculateColumns(weights, spacing, margin)`
Calculate responsive column widths based on proportional weights.

**Parameters:**
- `weights` (table) - Array of relative weights (e.g., {1, 2, 1} = 25%/50%/25%)
- `spacing` (number, optional) - Gap between columns (default: 1)
- `margin` (number, optional) - Margin from screen edges (default: 0)

**Returns:**
- `columns` (table) - Array of {x, width} for each column

**Example:**
```lua
-- Create 3 columns: 25% | 50% | 25%
local cols = layouts.calculateColumns({1, 2, 1}, 1, 2)

components.createPanel("left", cols[1].x, 5, cols[1].width, 10, "Left")
components.createPanel("center", cols[2].x, 5, cols[2].width, 10, "Center")
components.createPanel("right", cols[3].x, 5, cols[3].width, 10, "Right")
```

---

### Footer Helper

#### `layouts.createFooter(height, buttonLabels, callbacks, margin)`
Create a responsive footer with evenly distributed buttons.

**Parameters:**
- `height` (number, optional) - Footer height (default: 3)
- `buttonLabels` (table) - Array of button labels
- `callbacks` (table) - Array of button callbacks
- `margin` (number, optional) - Margin from screen edges (default: 0)

**Returns:**
- `buttons` (table) - Array of created button components
- `footerY` (number) - Y position of footer

**Example:**
```lua
local buttons, footerY = layouts.createFooter(3, 
    {"Move", "Mine", "Network", "Exit"},
    {moveFunc, mineFunc, networkFunc, exitFunc})

-- Customize button colors
buttons[4].bgColor = gui.getColor("error")
```

---

### Content Area

#### `layouts.getContentArea(headerHeight, footerHeight)`
Get safe content area excluding header/footer.

**Parameters:**
- `headerHeight` (number, optional) - Height of header (default: 0)
- `footerHeight` (number, optional) - Height of footer (default: 0)

**Returns:**
- Table with {x, y, width, height}

**Example:**
```lua
local content = layouts.getContentArea(3, 3)
-- Use content.x, content.y, content.width, content.height
local panel = components.createPanel("content", 
    content.x, content.y, content.width, content.height, "Content")
```

---

### Validation

#### `layouts.fitsOnScreen(x, y, width, height)`
Check if component fits on screen.

```lua
if layouts.fitsOnScreen(10, 10, 30, 10) then
    -- Component will fit
end
```

#### `layouts.constrainToScreen(x, y, width, height)`
Constrain dimensions to fit on screen.

```lua
local x, y, w, h = layouts.constrainToScreen(100, 100, 50, 50)
-- Returns adjusted values that fit on screen
```

---

## Complete Example

```lua
local gui = require("gui-core")
local layouts = require("gui-layouts")
local components = require("gui-components")

function createResponsiveUI()
    gui.init()
    gui.clearComponents()
    
    local w, h = layouts.getScreenSize()
    
    -- Header
    gui.centerText("My App", 1, gui.getColor("primary"), colors.white)
    
    -- Full-width status panel
    local statusPanel = layouts.createFullWidthPanel("status", 3, 6, "Status")
    statusPanel.borderColor = gui.getColor("border")
    
    -- Centered content
    local contentWidth = math.min(40, w - 4)
    local contentX = layouts.centerHorizontally(contentWidth)
    components.createLabel("info", contentX, 5, "This is centered!")
    
    -- Responsive grid for buttons
    local _, _, grid = layouts.createResponsiveGrid(3, 2, 1, 2)
    for row = 1, 2 do
        for col = 1, 3 do
            local pos = grid[row][col]
            local btnNum = ((row - 1) * 3) + col
            components.createButton("btn" .. btnNum,
                pos.x, pos.y, pos.width, pos.height,
                "Btn " .. btnNum)
        end
    end
    
    -- Footer with 3 buttons
    local buttons = layouts.createFooter(2,
        {"Option 1", "Option 2", "Exit"},
        {func1, func2, exitFunc})
    
    gui.draw()
end
```

---

## Tips

1. **Always use `layouts.getScreenSize()`** instead of `term.getSize()` for clarity

2. **Calculate once, use many times** - Store positions/sizes if creating multiple components

3. **Test on different screen sizes** - Turtles (39x13), Pockets (26x20), Computers (51x19)

4. **Use appropriate helpers**:
   - Buttons in a row → `calculateButtonRow()`
   - Grid layout → `createResponsiveGrid()`
   - Proportional columns → `calculateColumns()`
   - Full-width → `createFullWidthPanel()`

5. **Always adjust last element** - Helpers automatically adjust the last button/column to fill remaining space

6. **Margins vs Spacing**:
   - `margin` - Space from screen edges
   - `spacing` - Gap between components

---

## Migration Guide

### Old Way (Manual Calculation):
```lua
local w, h = term.getSize()
local btnW = math.floor((w - 5) / 4)
local btn1X = 1
local btn2X = btn1X + btnW + 1
local btn3X = btn2X + btnW + 1
local btn4X = btn3X + btnW + 1
local btn4W = w - btn4X

components.createButton("b1", btn1X, 10, btnW, 2, "One")
components.createButton("b2", btn2X, 10, btnW, 2, "Two")
components.createButton("b3", btn3X, 10, btnW, 2, "Three")
components.createButton("b4", btn4X, 10, btn4W, 2, "Four")
```

### New Way (Responsive Helpers):
```lua
local _, positions = layouts.calculateButtonRow(4, 1, 0)
for i, label in ipairs({"One", "Two", "Three", "Four"}) do
    components.createButton("b" .. i, 
        positions[i].x, 10, positions[i].width, 2, label)
end
```

---

Built with CCMine GUI Framework

