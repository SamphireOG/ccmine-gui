# CCMine GUI Framework

A modern, component-based GUI framework for ComputerCraft. Build beautiful, interactive interfaces for your mining turtles, computers, and pocket computers!

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![ComputerCraft](https://img.shields.io/badge/ComputerCraft-Compatible-orange)

## ✨ Features

- **Component-Based Architecture** - Modular, reusable UI components
- **7+ Built-in Components** - Buttons, panels, labels, inputs, progress bars, lists, checkboxes
- **5 Layout Systems** - Automatic positioning with vertical, horizontal, grid, stack, and anchor layouts
- **3 Built-in Themes** - Default, dark, and light themes
- **Event System** - Mouse click, hover, drag, scroll, and custom events
- **Responsive Design** - Automatic layout adjustment and screen management
- **Zero Dependencies** - Pure Lua, works on all ComputerCraft devices

## 🚀 Quick Start

### Install via Bootstrap

The easiest way to install:

```lua
-- In ComputerCraft, run:
pastebin run <bootstrap_code>
```

*Note: Pastebin code will be added after first upload*

### Manual Installation

1. Download all files from this repository
2. Copy to your ComputerCraft computer
3. Run the installer:

```lua
lua> shell.run("installer.lua")
```

### Your First GUI

```lua
local gui = require("gui-core")
local components = require("gui-components")

-- Initialize
gui.init()
gui.clear()

-- Create a button
local button = components.createButton("btn1", 10, 5, 20, 3, "Click Me!",
    function()
        print("Button clicked!")
    end)

-- Draw
gui.draw()

-- Event loop
while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "mouse_click" then
        gui.handleClick(p2, p3, p1)
        gui.draw()
    end
end
```

## 📦 What's Included

- **gui-core.lua** - Core framework with component system, events, and themes
- **gui-components.lua** - All UI components (buttons, panels, inputs, etc.)
- **gui-layouts.lua** - Layout managers for automatic positioning
- **gui-demo.lua** - Interactive demo with 6 examples
- **main.lua** - Complete mining control app example
- **README.md** - Full API documentation
- **QUICKSTART.md** - 5-minute getting started guide
- **COMPARISON.md** - Comparison with old GUI systems

## 🎮 Try the Demo

```lua
local demo = require("gui-demo")
demo.run()
```

The demo includes:
1. Basic Buttons - Simple button interactions
2. Panels & Labels - Container and text components
3. List Component - Scrollable lists with selection
4. Inputs & Checkboxes - Form components
5. Layouts - Automatic positioning examples
6. Themes - Theme switching demo

## 📚 Documentation

- [README.md](README.md) - Complete API reference
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [COMPARISON.md](COMPARISON.md) - Old vs new system comparison

## 🔧 Components

### Button
```lua
local btn = components.createButton(id, x, y, width, height, text, callback)
btn:on("mouseEnter", function() print("Hover!") end)
```

### Panel
```lua
local panel = components.createPanel(id, x, y, width, height, title)
panel.borderColor = gui.getColor("border")
```

### List
```lua
local list = components.createList(id, x, y, width, height)
list:addItem("Item 1", {custom = "data"})
list.onSelect = function(item) print(item.text) end
```

### Progress Bar
```lua
local bar = components.createProgressBar(id, x, y, width)
bar.value = 75  -- 0-100
```

### And more!
- Labels with alignment
- Text inputs with focus
- Checkboxes with change events

## 📐 Layouts

### Vertical Layout
```lua
local layout = layouts.createVerticalLayout(spacing, padding)
layout:add(component1)
layout:add(component2)
layout:apply(x, y, width, height)
```

### Regions
```lua
local regions = layouts.createRegions({
    header = 3,
    footer = 2,
    sidebar = 15
})
```

## 🎨 Themes

```lua
gui.setTheme("dark")   -- or "light", "default"
```

All components automatically adapt to the active theme!

## 📱 Device Support

Works on all ComputerCraft devices:
- ✅ Mining Turtles
- ✅ Computers
- ✅ Pocket Computers
- ✅ Advanced Computers
- ✅ Command Computers

## 🤝 Contributing

Contributions welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Share your creations

## 📄 License

MIT License - Feel free to use in your projects!

## 🌟 Examples

Check out the included `main.lua` for a complete mining control application featuring:
- Multi-screen navigation
- Real-time status updates
- Configuration screens
- Manual control interface
- Statistics display

## 🔗 Links

- [ComputerCraft Wiki](https://computercraft.info/)
- [CC: Tweaked Documentation](https://tweaked.cc/)

## 🙏 Credits

Built for the ComputerCraft community with ❤️

Inspired by modern GUI frameworks and adapted for Lua and ComputerCraft.

---

**Star this repo if you find it useful!** ⭐

