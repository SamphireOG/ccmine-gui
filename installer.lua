-- CCMine GUI Framework Installer
-- Easy installation for ComputerCraft computers and turtles

local GITHUB_BASE = "https://raw.githubusercontent.com/SamphireOG/ccmine-gui/main/"
local VERSION = "2.0.0"

-- Files to download
local CORE_FILES = {
    "gui-core.lua",
    "gui-components.lua",
    "gui-layouts.lua",
    "gui-dialogs.lua",
    "gui-data.lua"
}

local NETWORK_FILES = {
    "protocol.lua",
    "project-manager.lua",
    "zone-allocator.lua",
    "coordinator.lua",
    "turtle-client.lua"
}

local EXAMPLE_FILES = {
    "gui-demo.lua",
    "main.lua",
    "control-center.lua"
}

local DOC_FILES = {
    "README.md",
    "QUICKSTART.md",
    "COMPARISON.md",
    "DEVICE_GUIDE.md",
    "NETWORK_GUIDE.md"
}

-- ========== DOWNLOAD FUNCTIONS ==========

local function downloadFile(url, filename, silent)
    if not silent then
        print("Downloading " .. filename .. "...")
    end
    
    -- Add cache-busting parameter
    local cacheBuster = "?t=" .. os.epoch("utc")
    local fullUrl = url .. cacheBuster
    
    local response = http.get(fullUrl)
    if not response then
        return false, "Download failed"
    end
    
    local content = response.readAll()
    response.close()
    
    -- Check if content looks valid (not 404 page)
    if content:match("404%s*[:-]%s*Not%s*Found") then
        return false, "File not found on server"
    end
    
    local file = fs.open(filename, "w")
    if not file then
        return false, "Could not create file"
    end
    
    file.write(content)
    file.close()
    
    return true
end

local function downloadFromGitHub(fileList)
    local failed = {}
    local success = 0
    
    for _, filename in ipairs(fileList) do
        local url = GITHUB_BASE .. filename
        local ok, err = downloadFile(url, filename)
        
        if not ok then
            print("  FAILED: " .. filename)
            if err then print("    " .. err) end
            table.insert(failed, {file = filename, error = err})
        else
            print("  OK: " .. filename)
            success = success + 1
        end
    end
    
    return success, failed
end

-- ========== INSTALLATION TYPES ==========

local function installCore()
    print("Installing core framework files...")
    print("")
    
    local success, failed = downloadFromGitHub(CORE_FILES)
    
    print("")
    if #failed > 0 then
        print("WARNING: " .. #failed .. " core files failed!")
        print("Installation may not work correctly.")
        return false
    else
        print("Core files installed: " .. success .. "/" .. #CORE_FILES)
        return true
    end
end

local function installNetwork()
    print("")
    print("Installing network modules...")
    print("")
    
    local success, failed = downloadFromGitHub(NETWORK_FILES)
    
    print("")
    if #failed > 0 then
        print("WARNING: " .. #failed .. " network files failed!")
        print("Network features may not work.")
        return false
    else
        print("Network modules installed: " .. success .. "/" .. #NETWORK_FILES)
        return true
    end
end

local function installExamples()
    print("")
    print("Installing example files...")
    print("")
    
    local success, failed = downloadFromGitHub(EXAMPLE_FILES)
    
    print("")
    if #failed > 0 then
        print("Some examples failed to download.")
        return false
    else
        print("Examples installed: " .. success .. "/" .. #EXAMPLE_FILES)
        return true
    end
end

local function installDocs()
    print("")
    print("Installing documentation...")
    print("")
    
    local success, failed = downloadFromGitHub(DOC_FILES)
    
    print("")
    if #failed > 0 then
        print("Some docs failed to download (non-critical).")
    else
        print("Documentation installed: " .. success .. "/" .. #DOC_FILES)
    end
    
    return true
end

-- ========== STARTUP FILE ==========

local function createStartupFile(startupType)
    -- Detect device type
    local deviceType = "computer"
    if turtle and turtle.forward then
        deviceType = "turtle"
    elseif pocket and pocket.equipBack then
        deviceType = "pocket"
    end
    
    print("")
    print("Device detected: " .. deviceType)
    print("")
    print("Create startup file? This will auto-run on boot.")
    
    -- Show appropriate options based on device
    if deviceType == "turtle" then
        print("1. Turtle Interface (recommended)")
        print("2. GUI Demo")
        print("3. No startup file")
        print("")
        print("Enter choice (1-3):")
    elseif deviceType == "pocket" then
        print("1. Control Center (unified manager)")
        print("2. GUI Demo")
        print("3. No startup file")
        print("")
        print("Enter choice (1-3):")
    else
        print("1. Control Center (unified manager)")
        print("2. GUI Demo")
        print("3. No startup file")
        print("")
        print("Enter choice (1-3):")
    end
    
    local choice = read()
    
    local startupContent
    
    -- Generate appropriate startup based on device type
    if deviceType == "turtle" then
        if choice == "1" then
            startupContent = [[-- CCMine Turtle Interface - Auto-start
print("Starting Turtle Interface...")
sleep(0.5)
local app = require("main")
app.run()
]]
        elseif choice == "2" then
            startupContent = [[-- CCMine GUI Demo - Auto-start
print("Starting GUI Demo...")
sleep(0.5)
local demo = require("gui-demo")
demo.run()
]]
        else
            print("No startup file created.")
            return
        end
        
    elseif deviceType == "pocket" then
        if choice == "1" then
            startupContent = [[-- CCMine Control Center - Auto-start
print("Starting Control Center...")
sleep(0.5)
local control = require("control-center")
control.run()
]]
        elseif choice == "2" then
            startupContent = [[-- CCMine GUI Demo - Auto-start
print("Starting GUI Demo...")
sleep(0.5)
local demo = require("gui-demo")
demo.run()
]]
        else
            print("No startup file created.")
            return
        end
        
    else -- Regular computer
        if choice == "1" then
            startupContent = [[-- CCMine Control Center - Auto-start
print("Starting Control Center...")
sleep(0.5)
local control = require("control-center")
control.run()
]]
        elseif choice == "2" then
            startupContent = [[-- CCMine GUI Demo - Auto-start
print("Starting GUI Demo...")
sleep(0.5)
local demo = require("gui-demo")
demo.run()
]]
        else
            print("No startup file created.")
            return
        end
    end
    
    -- Check if startup exists
    if fs.exists("startup.lua") then
        print("")
        print("WARNING: startup.lua already exists!")
        print("Overwrite? (Y/N)")
        local confirm = read()
        if confirm:lower() ~= "y" then
            print("Startup file not created.")
            return
        end
    end
    
    local file = fs.open("startup.lua", "w")
    if file then
        file.write(startupContent)
        file.close()
        print("Startup file created!")
        print("Reboot to auto-start.")
    else
        print("ERROR: Could not create startup file")
    end
end

-- ========== LOCAL INSTALLATION ==========

local function installFromLocal()
    print("Installing from local files...")
    print("")
    
    local allFiles = {}
    for _, f in ipairs(CORE_FILES) do table.insert(allFiles, f) end
    for _, f in ipairs(NETWORK_FILES) do table.insert(allFiles, f) end
    for _, f in ipairs(EXAMPLE_FILES) do table.insert(allFiles, f) end
    
    local missing = {}
    for _, filename in ipairs(allFiles) do
        if not fs.exists(filename) then
            table.insert(missing, filename)
        end
    end
    
    if #missing > 0 then
        print("ERROR: Missing files:")
        for _, file in ipairs(missing) do
            print("  - " .. file)
        end
        print("")
        print("Please download all files to this directory.")
        return false
    end
    
    print("All required files found!")
    return true
end

-- ========== MANUAL INSTALLATION GUIDE ==========

local function showManualInstructions()
    print("=== Manual Installation ===")
    print("")
    print("Download these files from GitHub:")
    print("")
    print("Core files (required):")
    for _, file in ipairs(CORE_FILES) do
        print("  - " .. file)
    end
    print("")
    print("Network files (for turtle coordination):")
    for _, file in ipairs(NETWORK_FILES) do
        print("  - " .. file)
    end
    print("")
    print("Example files (optional):")
    for _, file in ipairs(EXAMPLE_FILES) do
        print("  - " .. file)
    end
    print("")
    print("Place all files in the same directory.")
    print("")
    print("Then run:")
    print("  lua> demo = require('gui-demo')")
    print("  lua> demo.run()")
    print("")
    print("For coordinator: control = require('control-center')")
    print("For turtles: app = require('main')")
    print("")
end

-- ========== VERIFICATION ==========

local function verifyInstallation()
    print("")
    print("Verifying installation...")
    print("")
    
    local allGood = true
    
    -- Check core files
    print("Core files:")
    for _, file in ipairs(CORE_FILES) do
        if fs.exists(file) then
            local size = fs.getSize(file)
            print("  OK: " .. file .. " (" .. size .. " bytes)")
        else
            print("  MISSING: " .. file)
            allGood = false
        end
    end
    
    -- Check network files
    print("")
    print("Network files:")
    local networkGood = true
    for _, file in ipairs(NETWORK_FILES) do
        if fs.exists(file) then
            local size = fs.getSize(file)
            print("  OK: " .. file .. " (" .. size .. " bytes)")
        else
            print("  MISSING: " .. file)
            networkGood = false
        end
    end
    
    print("")
    if allGood then
        print("Core installation verified successfully!")
        if networkGood then
            print("Network modules verified successfully!")
        else
            print("WARNING: Some network files missing!")
            print("Network features will not work.")
        end
        return true
    else
        print("WARNING: Some core files are missing!")
        print("Framework may not work correctly.")
        return false
    end
end

-- ========== TEST FRAMEWORK ==========

local function testFramework()
    print("")
    print("Test the framework now? (Y/N)")
    local test = read()
    
    if test:lower() ~= "y" then
        return
    end
    
    print("")
    print("Loading GUI framework...")
    
    local success, gui = pcall(require, "gui-core")
    if not success then
        print("ERROR: Could not load gui-core!")
        print(gui)
        return
    end
    
    print("  gui-core.lua loaded")
    
    success, comp = pcall(require, "gui-components")
    if not success then
        print("ERROR: Could not load gui-components!")
        print(comp)
        return
    end
    
    print("  gui-components.lua loaded")
    
    success, layouts = pcall(require, "gui-layouts")
    if not success then
        print("ERROR: Could not load gui-layouts!")
        print(layouts)
        return
    end
    
    print("  gui-layouts.lua loaded")
    
    print("")
    print("Framework test PASSED!")
    print("All modules loaded successfully.")
end

-- ========== MAIN INSTALLER ==========

local function main()
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Detect device type
    local deviceType = "Computer"
    if turtle and turtle.forward then
        deviceType = "Turtle"
    elseif pocket and pocket.equipBack then
        deviceType = "Pocket Computer"
    end
    
    print("============================")
    print("    CCMine - Mining System")
    print("    Version " .. VERSION)
    print("============================")
    print("")
    print("Device: " .. deviceType)
    print("")
    print("Installing...")
    print("")
    
    -- Install everything automatically
    local coreSuccess = installCore()
    
    if not coreSuccess then
        print("")
        print("ERROR: Download failed!")
        print("Check your internet connection.")
        return
    end
    
    installNetwork()
    installExamples()
    
    -- Verify
    if not verifyInstallation() then
        print("")
        print("WARNING: Some files missing!")
        print("Continuing anyway...")
    end
    
    -- Ask user what startup they want
    createStartupFile()
    
    -- Success!
    local deviceType = "computer"
    if turtle and turtle.forward then
        deviceType = "turtle"
    elseif pocket and pocket.equipBack then
        deviceType = "pocket"
    end
    
    print("")
    print("============================")
    print("  Installation Complete!")
    print("============================")
    print("")
    
    -- Show device-specific recommendations
    if deviceType == "turtle" then
        print("Recommended for Turtles:")
        print("  - main: Turtle interface")
        print("")
        print("Also available:")
        print("  - gui-demo: Framework demo")
    elseif deviceType == "pocket" then
        print("Recommended for Pocket:")
        print("  - control-center: Unified fleet & project manager")
        print("")
        print("Also available:")
        print("  - gui-demo: Framework demo")
    else
        print("Recommended for Computers:")
        print("  - control-center: Unified fleet & project manager")
        print("    (Runs coordinator + manages projects + turtles)")
        print("")
        print("Also available:")
        print("  - gui-demo: Framework demo")
    end
    
    print("")
    print("Reboot to auto-start, or run manually.")
    print("")
    print("Press any key to exit...")
    os.pullEvent("key")
end

-- Run installer
main()

