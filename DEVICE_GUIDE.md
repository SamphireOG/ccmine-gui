# CCMine Device Guide

## Which Program for Which Device?

CCMine automatically detects your device type and recommends the appropriate programs.

### 🐢 Turtles

**Recommended: `main.lua`**

The turtle interface provides:
- Movement controls (Up/Down/Forward/Back/Turn)
- Mining actions (Dig/Place in all directions)
- Inventory management (visual 16-slot grid)
- Fuel monitoring and refueling
- Network features (connect to coordinator)
- Real-time position tracking (with GPS)

**Run:**
```lua
local app = require("main")
app.run()
```

**Requirements:**
- Must be a turtle (will error on other devices)
- Wireless modem for network features (optional)
- Fuel for movement

---

### 📱 Pocket Computers

**Recommended: `mine-dashboard.lua` or `control-center.lua`**

#### Mine Dashboard (Project Management)
Create and manage mining projects, link turtles to projects.

**Run:**
```lua
local dashboard = require("mine-dashboard")
dashboard.run()
```

#### Control Center (Fleet Coordinator)
Manage entire turtle fleet, view all turtles, assign projects.

**Run:**
```lua
local control = require("control-center")
control.run()
```

---

### 💻 Computers

**Recommended: `control-center.lua`**

The control center acts as the network coordinator for all turtles.

**Features:**
- Dashboard with fleet overview
- View all registered turtles
- Create and manage projects
- Assign turtles to projects with zone allocation
- Monitor progress in real-time
- Send commands to turtles

**Run:**
```lua
local control = require("control-center")
control.run()
```

**Requirements:**
- Wireless modem (required for coordination)
- Should remain online to manage fleet

**Alternative: `mine-dashboard.lua`**
Use for project management without fleet coordination.

---

## Installation

The installer automatically detects your device and offers appropriate choices:

### On Turtles:
```
1. Turtle Interface (recommended)
2. GUI Demo
3. No startup file
```

### On Pocket Computers:
```
1. Mine Dashboard (project manager)
2. Control Center (coordinator)
3. GUI Demo
4. No startup file
```

### On Computers:
```
1. Control Center (coordinator)
2. Mine Dashboard (project manager)
3. GUI Demo
4. No startup file
```

---

## Quick Setup Guide

### 1. Install on Coordinator Computer
```lua
pastebin run <bootstrap-code>
```
Choose: **Control Center**

### 2. Install on Turtles
```lua
pastebin run <bootstrap-code>
```
Choose: **Turtle Interface**

### 3. Start Coordinator
Reboot the computer - Control Center starts automatically

### 4. Start Turtles
Reboot each turtle - Turtle interface starts automatically

### 5. Enable Network on Turtles
1. Click "Network" button
2. Click "Enable Network"
3. Turtle auto-connects to coordinator

### 6. Create Project on Coordinator
1. Click "New Project"
2. Fill in details
3. Click "Create"

### 7. Assign Turtles
1. Click "Turtles" on coordinator
2. Select a turtle
3. Click "Assign Project"
4. Select the project

Done! Turtles will receive their assignments automatically.

---

## Program Compatibility

| Program | Computer | Pocket | Turtle | Network |
|---------|----------|--------|--------|---------|
| **main.lua** | ❌ | ❌ | ✅ | Optional |
| **control-center.lua** | ✅ | ✅ | ❌ | Required |
| **mine-dashboard.lua** | ✅ | ✅ | ❌ | No |
| **gui-demo.lua** | ✅ | ✅ | ✅ | No |

---

## Tips

### For Turtles:
- Label your turtles: `os.setComputerLabel("Miner-01")`
- Keep fuel stocked (slot 1 for quick refuel)
- Use GPS for accurate positioning
- Enable network before starting mining

### For Coordinators:
- Place centrally for maximum wireless range
- Keep chunk loaded (use chunk loader)
- Monitor dashboard for lost turtles
- Use wired modem for wired network (optional)

### For Pocket Computers:
- Great for portable project management
- Can act as backup coordinator
- Limited screen size - some features compact

---

## Troubleshooting

### "This program must be run on a turtle!"
You're trying to run `main.lua` on a non-turtle device.
- Use `control-center.lua` or `mine-dashboard.lua` instead

### Turtle won't connect
- Check wireless modem is attached
- Verify coordinator is running
- Check wireless range
- Reboot both devices

### No programs show in installer
- Internet connection required
- Check HTTP API is enabled
- Try manual download from GitHub

---

## Next Steps

- Read [NETWORK_GUIDE.md](NETWORK_GUIDE.md) for network details
- Check [README.md](README.md) for GUI framework info
- See [QUICKSTART.md](QUICKSTART.md) for quick examples

---

Built with CCMine GUI Framework

