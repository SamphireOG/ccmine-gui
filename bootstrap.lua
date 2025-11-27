-- CCMine GUI Framework Bootstrap
-- Quick installer: pastebin run <code>
-- Downloads the full installer from GitHub

local GITHUB_URL = "https://raw.githubusercontent.com/SamphireOG/ccmine-gui/main/installer.lua"

print("============================")
print("   CCMine GUI Framework")
print("   Bootstrap Installer")
print("============================")
print("")

-- Clean old installation if exists
print("Checking for existing installation...")
local oldFiles = {
    "gui-core.lua",
    "gui-components.lua", 
    "gui-layouts.lua",
    "gui-demo.lua",
    "gui-demo-responsive.lua",
    "main.lua",
    "installer.lua"
}

local foundOld = false
for _, file in ipairs(oldFiles) do
    if fs.exists(file) then
        foundOld = true
        break
    end
end

if foundOld then
    print("Found existing installation.")
    print("")
    print("Options:")
    print("1. Fresh install (delete old files)")
    print("2. Update (keep config files)")
    print("3. Cancel")
    print("")
    print("Enter choice (1-3):")
    local choice = read()
    
    if choice == "1" then
        print("")
        print("Removing old files...")
        for _, file in ipairs(oldFiles) do
            if fs.exists(file) then
                fs.delete(file)
                print("Deleted: " .. file)
            end
        end
    elseif choice == "3" then
        print("Installation cancelled.")
        return
    end
    -- Choice 2 doesn't delete files
end

print("")
print("Downloading installer from GitHub...")
print("URL: " .. GITHUB_URL)
print("")

-- Add cache-busting to force fresh download
local cacheBuster = "?t=" .. os.epoch("utc")
local response = http.get(GITHUB_URL .. cacheBuster)

if not response then
    print("ERROR: Could not download installer!")
    print("")
    print("Possible issues:")
    print("1. Internet connection down")
    print("2. GitHub repository not set up")
    print("3. URL is incorrect")
    print("")
    print("Manual installation:")
    print("1. Download files from GitHub")
    print("2. Copy to ComputerCraft folder")
    print("3. Run main.lua or gui-demo.lua")
    return
end

local content = response.readAll()
response.close()

print("Downloaded successfully!")
print("Running installer...")
print("")

-- Save installer for later use
local file = fs.open("installer.lua", "w")
if file then
    file.write(content)
    file.close()
end

-- Run the installer
local func, err = load(content, "installer", "t", _ENV)
if not func then
    print("ERROR: Could not load installer!")
    print(err)
    return
end

-- Execute installer
local success, installErr = pcall(func)
if not success then
    print("")
    print("ERROR during installation:")
    print(installErr)
    print("")
    print("Try running manually:")
    print("  lua> shell.run('installer.lua')")
end

