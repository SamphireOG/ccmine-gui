-- CCMine GUI Framework - Core System
-- Modern component-based GUI framework for ComputerCraft
-- Version: 2.0

local gui = {}

-- ========== CORE CONFIGURATION ==========

gui.screen = {
    width = 51,
    height = 19,
    term = term
}

gui.state = {
    components = {},
    focusedComponent = nil,
    hoveredComponent = nil,
    isDragging = false,
    needsRedraw = true,
    eventListeners = {},
    currentScreen = nil,
    shouldExit = false,
    notification = "",
    notificationColor = colors.white,
    notificationBg = colors.gray,
    notificationTimer = nil
}

-- ========== THEME SYSTEM ==========

gui.themes = {
    default = {
        background = colors.black,
        foreground = colors.white,
        primary = colors.blue,
        secondary = colors.gray,
        success = colors.green,
        warning = colors.yellow,
        error = colors.red,
        border = colors.lightGray,
        hover = colors.lightGray,
        active = colors.white,
        disabled = colors.gray,
        shadow = colors.black
    },
    dark = {
        background = colors.gray,
        foreground = colors.white,
        primary = colors.cyan,
        secondary = colors.lightGray,
        success = colors.lime,
        warning = colors.orange,
        error = colors.red,
        border = colors.white,
        hover = colors.white,
        active = colors.yellow,
        disabled = colors.black,
        shadow = colors.black
    },
    light = {
        background = colors.white,
        foreground = colors.black,
        primary = colors.blue,
        secondary = colors.lightGray,
        success = colors.green,
        warning = colors.orange,
        error = colors.red,
        border = colors.gray,
        hover = colors.lightGray,
        active = colors.gray,
        disabled = colors.lightGray,
        shadow = colors.gray
    }
}

gui.currentTheme = gui.themes.default

function gui.setTheme(themeName)
    if gui.themes[themeName] then
        gui.currentTheme = gui.themes[themeName]
        gui.requestRedraw()
        return true
    end
    return false
end

function gui.getColor(colorName)
    return gui.currentTheme[colorName] or colors.white
end

-- ========== COMPONENT BASE CLASS ==========

local Component = {}
Component.__index = Component

function Component:new(id, type, x, y, width, height)
    local obj = {
        id = id,
        type = type,
        x = x or 1,
        y = y or 1,
        width = width or 10,
        height = height or 3,
        visible = true,
        enabled = true,
        parent = nil,
        children = {},
        zIndex = 0,
        bgColor = gui.getColor("background"),
        fgColor = gui.getColor("foreground"),
        borderColor = nil,
        padding = {top = 0, right = 0, bottom = 0, left = 0},
        margin = {top = 0, right = 0, bottom = 0, left = 0},
        events = {}
    }
    setmetatable(obj, self)
    return obj
end

function Component:addChild(child)
    table.insert(self.children, child)
    child.parent = self
    gui.requestRedraw()
end

function Component:removeChild(child)
    for i, c in ipairs(self.children) do
        if c.id == child.id then
            table.remove(self.children, i)
            child.parent = nil
            gui.requestRedraw()
            break
        end
    end
end

function Component:isPointInside(x, y)
    if not self.visible then return false end
    
    -- Get absolute position (accounts for parent offset and scroll)
    local absX, absY = self:getAbsolutePosition()
    
    return x >= absX and x < absX + self.width and
           y >= absY and y < absY + self.height
end

function Component:getAbsolutePosition()
    local absX, absY = self.x, self.y
    
    -- Account for parent position and scroll offset
    if self.parent then
        local parentX, parentY = self.parent:getAbsolutePosition()
        absX = absX + parentX
        absY = absY + parentY
        
        -- Apply parent's scroll offset if it's a scrollable panel
        if self.parent.type == "panel" and self.parent.scrollable and self.parent.scrollOffset then
            absY = absY - self.parent.scrollOffset
        end
    end
    
    return absX, absY
end

function Component:on(eventName, callback)
    if not self.events[eventName] then
        self.events[eventName] = {}
    end
    table.insert(self.events[eventName], callback)
end

function Component:emit(eventName, ...)
    if self.events[eventName] then
        for _, callback in ipairs(self.events[eventName]) do
            local success, err = pcall(callback, self, ...)
            if not success then
                gui.handleError("Event Error", err)
            end
        end
    end
end

function Component:draw()
    if not self.visible then return end
    
    -- Override in subclasses
    local absX, absY = self:getAbsolutePosition()
    
    -- Draw background
    gui.screen.term.setBackgroundColor(self.bgColor)
    gui.screen.term.setTextColor(self.fgColor)
    
    for dy = 0, self.height - 1 do
        gui.screen.term.setCursorPos(absX, absY + dy)
        gui.screen.term.write(string.rep(" ", self.width))
    end
    
    -- Draw border if specified
    if self.borderColor then
        self:drawBorder(absX, absY)
    end
    
    -- Draw children
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function Component:drawBorder(absX, absY)
    gui.screen.term.setTextColor(self.borderColor)
    
    -- Top and bottom
    gui.screen.term.setCursorPos(absX, absY)
    gui.screen.term.write(string.rep("-", self.width))
    gui.screen.term.setCursorPos(absX, absY + self.height - 1)
    gui.screen.term.write(string.rep("-", self.width))
    
    -- Sides
    for dy = 1, self.height - 2 do
        gui.screen.term.setCursorPos(absX, absY + dy)
        gui.screen.term.write("|")
        gui.screen.term.setCursorPos(absX + self.width - 1, absY + dy)
        gui.screen.term.write("|")
    end
end

function Component:update(dt)
    -- Override in subclasses for animations/updates
    for _, child in ipairs(self.children) do
        child:update(dt)
    end
end

function Component:destroy()
    if self.parent then
        self.parent:removeChild(self)
    end
    gui.state.components[self.id] = nil
end

gui.Component = Component

-- ========== COMPONENT REGISTRY ==========

function gui.registerComponent(component)
    gui.state.components[component.id] = component
    gui.requestRedraw()
    return component
end

function gui.getComponent(id)
    return gui.state.components[id]
end

function gui.removeComponent(id)
    local component = gui.state.components[id]
    if component then
        component:destroy()
    end
end

function gui.clearComponents()
    -- Properly destroy all components first
    for id, component in pairs(gui.state.components) do
        if component.events then
            component.events = {}
        end
        if component.children then
            component.children = {}
        end
    end
    
    gui.state.components = {}
    gui.state.focusedComponent = nil
    gui.state.hoveredComponent = nil
    gui.requestRedraw()
end

-- ========== SCREEN MANAGEMENT ==========

function gui.init()
    -- Get actual screen dimensions
    gui.screen.width, gui.screen.height = gui.screen.term.getSize()
    gui.clear()
    return gui.screen.width, gui.screen.height
end

function gui.clear()
    gui.screen.term.setBackgroundColor(gui.getColor("background"))
    gui.screen.term.setTextColor(gui.getColor("foreground"))
    gui.screen.term.clear()
    gui.screen.term.setCursorPos(1, 1)
    gui.requestRedraw()
end

function gui.requestRedraw()
    gui.state.needsRedraw = true
end

function gui.draw()
    if not gui.state.needsRedraw then return end
    
    -- Sort components by zIndex
    local sortedComponents = {}
    for _, component in pairs(gui.state.components) do
        if not component.parent then -- Only draw root components
            table.insert(sortedComponents, component)
        end
    end
    
    table.sort(sortedComponents, function(a, b)
        return a.zIndex < b.zIndex
    end)
    
    -- Draw all components
    for _, component in ipairs(sortedComponents) do
        component:draw()
    end
    
    -- Draw notification bar (always on bottom)
    gui.drawNotificationBar()
    
    gui.state.needsRedraw = false
end

-- ========== EVENT HANDLING ==========

function gui.handleClick(x, y, button)
    -- Find topmost component at position
    local clicked = gui.findComponentAt(x, y)
    
    -- Unfocus old component if clicking elsewhere
    if gui.state.focusedComponent and gui.state.focusedComponent ~= clicked then
        if gui.state.focusedComponent.isFocused ~= nil then
            gui.state.focusedComponent.isFocused = false
            gui.screen.term.setCursorBlink(false)
        end
    end
    
    if clicked then
        clicked:emit("click", x, y, button)
        gui.state.focusedComponent = clicked
        return clicked
    end
    
    gui.state.focusedComponent = nil
    return nil
end

function gui.handleDrag(x, y)
    if gui.state.hoveredComponent then
        local component = gui.state.components[gui.state.hoveredComponent]
        if component then
            component:emit("drag", x, y)
        end
    end
end

function gui.handleScroll(x, y, direction)
    -- First, find if we're inside any scrollable panel
    local scrollablePanel = nil
    for _, component in pairs(gui.state.components) do
        if component.type == "panel" and component.scrollable and component.visible then
            local absX, absY = component:getAbsolutePosition()
            if x >= absX and x < absX + component.width and 
               y >= absY and y < absY + component.height then
                scrollablePanel = component
                break
            end
        end
    end
    
    -- If we found a scrollable panel, scroll it
    if scrollablePanel then
        scrollablePanel:emit("scroll", x, y, direction)
        return scrollablePanel
    end
    
    -- Fallback: try to find component and propagate
    local component = gui.findComponentAt(x, y)
    if component then
        component:emit("scroll", x, y, direction)
        
        -- Propagate scroll up to parent panels
        local current = component
        while current.parent do
            current = current.parent
            if current.type == "panel" and current.scrollable then
                current:emit("scroll", x, y, direction)
                break
            end
        end
        
        return component
    end
    return nil
end

function gui.handleMouseMove(x, y)
    local newHovered = gui.findComponentAt(x, y)
    local newHoveredId = newHovered and newHovered.id or nil
    
    -- Handle mouse leave
    if gui.state.hoveredComponent and gui.state.hoveredComponent ~= newHoveredId then
        local oldComponent = gui.state.components[gui.state.hoveredComponent]
        if oldComponent then
            oldComponent:emit("mouseLeave")
        end
    end
    
    -- Handle mouse enter
    if newHoveredId and newHoveredId ~= gui.state.hoveredComponent then
        if newHovered then
            newHovered:emit("mouseEnter", x, y)
        end
    end
    
    gui.state.hoveredComponent = newHoveredId
    
    if newHovered then
        newHovered:emit("mouseMove", x, y)
    end
end

function gui.findComponentAt(x, y)
    -- Find topmost component at position (highest zIndex)
    local found = nil
    local highestZ = -math.huge
    
    for _, component in pairs(gui.state.components) do
        if component:isPointInside(x, y) and component.zIndex >= highestZ then
            found = component
            highestZ = component.zIndex
        end
    end
    
    return found
end

-- ========== KEYBOARD HANDLING ==========

function gui.handleKey(key)
    -- Pass key events to focused component
    if gui.state.focusedComponent then
        local component = gui.state.components[gui.state.focusedComponent]
        if component and component.handleKey then
            component:handleKey(key)
            gui.requestRedraw()
        end
    end
end

function gui.handleChar(char)
    -- Pass character events to focused component
    if gui.state.focusedComponent then
        local component = gui.state.components[gui.state.focusedComponent]
        if component and component.handleChar then
            component:handleChar(char)
            gui.requestRedraw()
        end
    end
end

-- ========== ERROR HANDLING ==========

function gui.handleError(title, message)
    gui.clear()
    gui.screen.term.setBackgroundColor(colors.red)
    gui.screen.term.setTextColor(colors.white)
    gui.screen.term.setCursorPos(1, 1)
    gui.screen.term.clearLine()
    print(" " .. title)
    gui.screen.term.setBackgroundColor(colors.black)
    gui.screen.term.setTextColor(colors.red)
    print("")
    print(tostring(message))
    print("")
    gui.screen.term.setTextColor(colors.gray)
    print("Press any key to continue...")
    os.pullEvent("key")
    gui.clear()
end

-- ========== UTILITY FUNCTIONS ==========

function gui.centerText(text, y, bgColor, fgColor)
    local x = math.floor((gui.screen.width - #text) / 2) + 1
    gui.screen.term.setCursorPos(x, y)
    if bgColor then gui.screen.term.setBackgroundColor(bgColor) end
    if fgColor then gui.screen.term.setTextColor(fgColor) end
    gui.screen.term.write(text)
end

function gui.truncateText(text, maxWidth)
    if #text <= maxWidth then
        return text
    end
    return text:sub(1, maxWidth - 3) .. "..."
end

function gui.wrapText(text, maxWidth)
    local lines = {}
    local currentLine = ""
    
    for word in text:gmatch("%S+") do
        if #currentLine + #word + 1 <= maxWidth then
            currentLine = currentLine .. (currentLine ~= "" and " " or "") .. word
        else
            if #currentLine > 0 then
                table.insert(lines, currentLine)
            end
            currentLine = word
        end
    end
    
    if #currentLine > 0 then
        table.insert(lines, currentLine)
    end
    
    return lines
end

-- ========== SCREEN MANAGEMENT ==========

function gui.setScreen(screenFunction)
    -- Clear old screen
    gui.clearComponents()
    gui.clear()
    
    -- Set new screen
    gui.state.currentScreen = screenFunction
    
    -- Draw new screen
    if screenFunction then
        screenFunction()
    end
    
    gui.requestRedraw()
    gui.draw()
end

function gui.refreshScreen()
    if gui.state.currentScreen then
        gui.setScreen(gui.state.currentScreen)
    end
end

-- ========== BUILT-IN EVENT LOOP ==========

function gui.runApp(initialScreen)
    -- Set initial screen
    gui.setScreen(initialScreen)
    
    -- Main event loop
    while not gui.state.shouldExit do
        local event, param1, param2, param3 = os.pullEvent()
        
        if event == "mouse_click" then
            gui.handleClick(param2, param3, param1)
            gui.draw()
        elseif event == "mouse_move" then
            gui.handleMouseMove(param2, param3)
            gui.draw()
        elseif event == "mouse_scroll" then
            gui.handleScroll(param2, param3, param1)
            gui.draw()
        elseif event == "timer" then
            -- Restore button colors after click flash
            for _, component in pairs(gui.state.components) do
                if component.type == "button" and component.flashTimer == param1 then
                    if component.originalBgColor then
                        component.bgColor = component.originalBgColor
                        component.originalBgColor = nil
                        component.flashTimer = nil
                        gui.requestRedraw()
                        gui.draw()
                    end
                end
            end
            
            -- Clear notification after timeout
            if gui.state.notificationTimer == param1 then
                gui.clearNotification()
            end
        elseif event == "char" then
            -- Dispatch to focused component
            if gui.state.focusedComponent and gui.state.focusedComponent.handleChar then
                gui.state.focusedComponent:handleChar(param1)
                gui.draw()
            end
        elseif event == "key" then
            -- Dispatch to focused component first
            local handled = false
            if gui.state.focusedComponent and gui.state.focusedComponent.handleKey then
                handled = gui.state.focusedComponent:handleKey(param1)
                gui.draw()
            end
            
            -- Allow Q key to exit (if not handled)
            if not handled and param1 == keys.q then
                gui.state.shouldExit = true
            end
        elseif event == "term_resize" then
            gui.init()
            gui.refreshScreen()
        end
    end
    
    -- Clean exit
    gui.clearComponents()
    gui.clear()
end

function gui.exit()
    gui.state.shouldExit = true
end

-- ========== NOTIFICATION SYSTEM ==========

function gui.notify(message, color, bgColor, duration)
    -- Show a notification in the bottom bar
    gui.state.notification = message or ""
    gui.state.notificationColor = color or colors.white
    gui.state.notificationBg = bgColor or colors.gray
    
    -- Clear existing timer
    if gui.state.notificationTimer then
        gui.state.notificationTimer = nil
    end
    
    -- Set auto-clear timer if duration specified
    if duration and duration > 0 then
        gui.state.notificationTimer = os.startTimer(duration)
    end
    
    gui.requestRedraw()
    gui.draw()
end

function gui.clearNotification()
    gui.state.notification = ""
    gui.state.notificationTimer = nil
    gui.requestRedraw()
    gui.draw()
end

function gui.drawNotificationBar()
    -- Draw bottom bar for notifications
    local y = gui.screen.height
    
    gui.screen.term.setCursorPos(1, y)
    gui.screen.term.setBackgroundColor(gui.state.notificationBg)
    gui.screen.term.setTextColor(gui.state.notificationColor)
    
    if gui.state.notification and #gui.state.notification > 0 then
        -- Center the notification
        local text = gui.truncateText(gui.state.notification, gui.screen.width - 2)
        local padding = math.floor((gui.screen.width - #text) / 2)
        local line = string.rep(" ", padding) .. text .. string.rep(" ", gui.screen.width - padding - #text)
        gui.screen.term.write(line)
    else
        -- Empty bar
        gui.screen.term.write(string.rep(" ", gui.screen.width))
    end
end

return gui

