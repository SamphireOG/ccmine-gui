# CCMine Network System Guide

## Overview

The CCMine Network System allows you to coordinate multiple turtles across shared mining projects using ComputerCraft's rednet protocol.

## Architecture

- **Hybrid System**: Central coordinator for discovery/management + direct P2P communication
- **Coordinator Server**: Runs on a control computer to manage the fleet
- **Turtle Clients**: Network-capable turtles that register and receive assignments
- **Zone Allocation**: Automatic division of work areas to prevent collisions

## Quick Start

### 1. Set Up Coordinator (Control Computer)

Run on a computer with a wireless modem:

```lua
local control = require("control-center")
control.run()
```

Or set it as startup:

```lua
-- startup.lua
local control = require("control-center")
control.run()
```

### 2. Set Up Turtles

Run on turtles with wireless modems:

```lua
local app = require("main")
app.run()
```

The turtle will automatically:
- Detect the modem
- Show "Network" button in the GUI
- Allow you to enable networking

### 3. Enable Network on Turtle

1. Click "Network" button in main screen
2. Click "Enable Network" button
3. Turtle will automatically find and register with coordinator
4. Status will show "Connected" when successful

### 4. Create a Project

On the Control Center:

1. Click "New Project"
2. Enter project details:
   - Name (e.g., "North Mine")
   - Type: 1=Branch Mine, 2=Quarry, 3=Strip Mine
   - Start position (X, Y, Z coordinates)
3. Click "Create"

### 5. Assign Turtles to Project

On the Control Center:

1. Click "Turtles" to see all registered turtles
2. Click on a turtle to see details
3. Click "Assign Project"
4. Select the project from the list
5. Turtle will automatically receive assignment and zone allocation

## Project Types

### Branch Mining

Creates a main corridor with side branches on both sides.

**Config:**
- Corridor Length: Length of main tunnel
- Branch Length: How far each branch extends
- Branch Spacing: Blocks between branches
- Branches Per Side: Number on each side

**Multi-Turtle:** Divides branches among turtles (e.g., Turtle 1: branches 1-5, Turtle 2: branches 6-10)

### Quarry

Excavates an entire rectangular area to a specified depth.

**Config:**
- Width & Length: Area dimensions
- Depth: How deep to dig
- Min Y: Minimum Y level

**Multi-Turtle:** Divides into vertical slices

### Strip Mining

Creates parallel mining tunnels.

**Config:**
- Tunnel Length: How long each tunnel
- Tunnel Count: Number of parallel tunnels
- Tunnel Spacing: Blocks between tunnels
- Tunnel Height: Height of each tunnel

**Multi-Turtle:** Assigns different tunnels to each turtle

## Network Communication

### Message Types

- **REGISTER**: Turtle registers with coordinator
- **HEARTBEAT**: Status updates every 30 seconds
- **PROJECT_ASSIGN**: Coordinator assigns project
- **PROJECT_UPDATE**: Progress updates
- **COORD_REQUEST**: Request coordination info
- **COORD_RESPONSE**: Peer positions/zones
- **COMMAND**: Direct commands (return home, pause, etc.)
- **ACK**: Acknowledgments

### Heartbeat System

Turtles send status updates every 30 seconds including:
- Current position (via GPS if available)
- Fuel level
- Inventory status
- Current project
- Work status

If no heartbeat received for 5 minutes, turtle is marked as "lost".

## Zone Allocation

The system automatically divides work areas to prevent collisions:

- Each turtle gets a specific zone/boundary
- Zones include min/max X, Y, Z coordinates
- Safe distance maintained between turtles
- Clear instructions provided (e.g., "Mine branches 1-5 on left side")

## Coordination

### Peer Communication

Turtles on the same project can request coordination info:

```lua
local client = require("turtle-client")
client.requestCoordination()

-- Get peer turtles
local peers = client.getPeers()
for _, peer in ipairs(peers) do
    print(string.format("Turtle %d at zone %d", peer.id, peer.zone))
end
```

### Nearby Detection

Check for nearby turtles:

```lua
local nearby = client.getNearbyPeers(10) -- Within 10 blocks
```

## Progress Tracking

Turtles automatically track and report:
- Blocks cleared
- Ore found
- Fuel used
- Distance traveled

Coordinator aggregates this into project statistics.

## Control Center Features

### Dashboard
- Overview of all turtles and projects
- Quick stats (idle/working/lost turtles)
- Active projects count
- Total blocks cleared

### Turtle List
- View all registered turtles
- Status indicators (Working, Idle, Lost)
- Fuel levels and positions
- Select turtle for details

### Turtle Details
- Full turtle information
- Current project assignment
- Send commands (return home, unassign)
- Assign to project

### Project Manager
- List all projects with progress
- View project details
- Control projects (pause/resume/cancel)
- Broadcast coordination updates

### Project Details
- Progress bar with completion percentage
- Blocks cleared and ore found
- Assigned turtle count
- Project controls

## Commands

Coordinator can send commands to turtles:

- **return_home**: Return to starting position
- **pause**: Pause current work
- **resume**: Resume work
- **unassign**: Remove from project
- **register**: Force re-registration

## Troubleshooting

### Turtle Won't Connect

1. Check wireless modem is attached
2. Verify coordinator is running
3. Check if turtle is within wireless range
4. Try manual re-registration

### Lost Connection

Turtles marked "lost" after 5 minutes without heartbeat:
- Check if turtle is running
- Verify fuel isn't empty
- Check chunk loading (turtles need loaded chunks)
- Reboot turtle to re-register

### No Projects Available

Create projects on Control Center before assigning turtles.

### Zone Conflicts

The system prevents this automatically, but if issues occur:
- Check coordinator logs
- Verify zone allocations on Control Center
- Broadcast coordination update

## API Usage

### Turtle Client API

```lua
local client = require("turtle-client")

-- Initialize
client.init("Miner-01")

-- Get status
local status = client.getStatus()

-- Update progress
client.updateProgress(10, 2, 50, 15) -- blocks, ore, fuel, distance

-- Send progress to coordinator
client.sendProgressUpdate()

-- Check if assigned
if client.isAssignedToProject() then
    local assignment = client.getProjectAssignment()
    print(assignment.instructions)
end
```

### Coordinator API

```lua
local coordinator = require("coordinator")

-- Start coordinator
coordinator.start()

-- Assign turtle to project
coordinator.assignToProject(turtleId, projectId)

-- Send command
coordinator.sendCommand(turtleId, "return_home")

-- Get statistics
local stats = coordinator.getStats()
```

### Project Manager API

```lua
local projectManager = require("project-manager")

-- Create project
local projectId = projectManager.create("branch_mine", "My Mine", config, startPos)

-- Assign turtle
projectManager.assign(turtleId, projectId, "miner", 1)

-- Update progress
projectManager.updateProgress(projectId, turtleId, progressData)

-- Get project
local project = projectManager.get(projectId)
```

## Files

- `protocol.lua` - Message protocol system
- `project-manager.lua` - Project management
- `zone-allocator.lua` - Zone division logic
- `coordinator.lua` - Coordinator server
- `turtle-client.lua` - Turtle network client
- `control-center.lua` - Control computer GUI
- `main.lua` - Turtle GUI (with network integration)

## Requirements

- ComputerCraft (or CC: Tweaked)
- Wireless modems on coordinator and turtles
- Turtles need fuel
- GPS system recommended (for position tracking)

## Tips

1. **Set Labels**: Give turtles unique labels for easy identification
   ```lua
   os.setComputerLabel("Miner-01")
   ```

2. **GPS Setup**: Install GPS hosts for accurate positioning

3. **Fuel Management**: Keep turtles fueled - they report low fuel automatically

4. **Range Limits**: Wireless modems have range limits - place coordinator centrally

5. **Chunk Loading**: Use chunk loaders to keep turtles loaded

6. **Backup**: Coordinator stores project data in memory - add save/load for persistence

## License

Open source - part of CCMine GUI Framework

