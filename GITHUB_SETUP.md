# GitHub Setup Instructions

Follow these steps to publish your CCMine GUI Framework to GitHub.

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com)
2. Click the **+** icon (top right) → **New repository**
3. Fill in:
   - **Repository name**: `ccmine-gui` (or your preferred name)
   - **Description**: "Modern GUI framework for ComputerCraft"
   - **Visibility**: Public (so others can use it!)
   - **DO NOT** initialize with README (we already have one)
4. Click **Create repository**

## Step 2: Connect Local Repository to GitHub

GitHub will show you commands. Use these from your CCMine directory:

```bash
# Set the remote URL (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/ccmine-gui.git

# Set main branch name
git branch -M main

# Push to GitHub
git push -u origin main
```

Or in PowerShell (Windows):

```powershell
git remote add origin https://github.com/YOUR_USERNAME/ccmine-gui.git
git branch -M main
git push -u origin main
```

## Step 3: Update URLs in Files

After creating the repository, update these files with your actual GitHub username:

### 1. bootstrap.lua (line 4)
```lua
-- OLD:
local GITHUB_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/ccmine-gui/main/installer.lua"

-- NEW (replace YOUR_USERNAME):
local GITHUB_URL = "https://raw.githubusercontent.com/YourActualUsername/ccmine-gui/main/installer.lua"
```

### 2. installer.lua (line 4)
```lua
-- OLD:
local GITHUB_BASE = "https://raw.githubusercontent.com/YOUR_USERNAME/ccmine-gui/main/"

-- NEW (replace YOUR_USERNAME):
local GITHUB_BASE = "https://raw.githubusercontent.com/YourActualUsername/ccmine-gui/main/"
```

### 3. Commit the changes
```bash
git add bootstrap.lua installer.lua
git commit -m "Update GitHub URLs with actual username"
git push
```

## Step 4: Upload Bootstrap to Pastebin

1. Go to [Pastebin.com](https://pastebin.com)
2. Create new paste:
   - Copy contents of `bootstrap.lua`
   - Title: "CCMine GUI Framework Bootstrap"
   - Expiration: Never
   - Exposure: Public
3. Click **Create New Paste**
4. Note the code (e.g., `abc123`)

## Step 5: Update README with Pastebin Code

Edit `GITHUB_README.md`:

```markdown
### Install via Bootstrap

pastebin run YOUR_CODE_HERE
```

Replace `YOUR_CODE_HERE` with your actual Pastebin code.

Commit and push:
```bash
git add GITHUB_README.md
git commit -m "Add Pastebin code to README"
git push
```

## Step 6: Test the Installation

In ComputerCraft:

```lua
pastebin run YOUR_CODE
```

This should:
1. Download the installer from your GitHub
2. Download all framework files
3. Set up the GUI framework
4. Offer to run the demo

## Step 7: Customize (Optional)

### Add Topics/Tags
On GitHub repository page:
1. Click the gear icon next to "About"
2. Add topics: `computercraft`, `lua`, `gui`, `framework`, `minecraft`

### Enable Issues
Settings → Features → Check "Issues"

### Create Releases
1. Click "Releases" (right sidebar)
2. "Create a new release"
3. Tag: `v2.0.0`
4. Title: "CCMine GUI Framework v2.0.0"
5. Description: Features and installation instructions

## Quick Reference Commands

### Make changes and push
```bash
git add .
git commit -m "Your change description"
git push
```

### Create a new version
```bash
# Update version in files
git add .
git commit -m "Version 2.1.0: Add new features"
git tag v2.1.0
git push
git push --tags
```

### Check status
```bash
git status
git log --oneline
```

## Troubleshooting

### Push fails with authentication error
Use a Personal Access Token:
1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Select: `repo` permissions
4. Use token instead of password when pushing

### Files not updating in ComputerCraft
- Cache-busting is built into installer (adds timestamp)
- Wait a minute and try again
- Check that URLs are correct

## Next Steps

1. Share your repository with the ComputerCraft community!
2. Post on forums: [ComputerCraft Forums](https://forums.computercraft.cc/)
3. Add screenshots/GIFs to README
4. Create video tutorial
5. Build example projects using the framework

## Support

If users have issues:
1. Check GitHub Issues
2. Verify Pastebin code is correct
3. Ensure repository is public
4. Test installation yourself

Good luck! 🚀

