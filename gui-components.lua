-- CCMine GUI Framework - Components
-- Reusable UI components (buttons, panels, inputs, etc.)

local guiCore = require("gui-core")
local gui = guiCore
local Component = gui.Component

local components = {}

-- ========== PANEL COMPONENT ==========

local Panel = {}
setmetatable(Panel, {__index = Component})

function Panel:new(id, x, y, width, height)
    local obj = Component:new(id, "panel", x, y, width, height)
    setmetatable(obj, {__index = Panel})
    
    obj.title = nil
    obj.titleBgColor = gui.getColor("primary")
    obj.titleFgColor = gui.getColor("foreground")
    obj.scrollOffset = 0
    obj.scrollable = false
    obj.contentHeight = 0
    
    return obj
end

function Panel:draw()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePosition()
    
    -- Draw background
    gui.screen.term.setBackgroundColor(self.bgColor)
    for dy = 0, self.height - 1 do
        gui.screen.term.setCursorPos(absX, absY + dy)
        gui.screen.term.write(string.rep(" ", self.width))
    end
    
    -- Draw border first
    if self.borderColor then
        self:drawBorder(absX, absY)
    end
    
    -- Draw title bar on top of border
    local contentStartY = 0
    if self.title then
        -- Title needs to fit INSIDE the border (width - 2 for left/right border)
        local titleWidth = self.borderColor and (self.width - 2) or self.width
        gui.screen.term.setCursorPos(absX + 1, absY)  -- +1 to skip left border
        gui.screen.term.setBackgroundColor(self.titleBgColor)
        gui.screen.term.setTextColor(self.titleFgColor)
        local titleText = " " .. self.title .. " "
        -- Ensure title fits within available width
        if #titleText > titleWidth then
            titleText = titleText:sub(1, titleWidth)
        else
            titleText = titleText .. string.rep(" ", math.max(0, titleWidth - #titleText))
        end
        gui.screen.term.write(titleText)
        contentStartY = 1
    end
    
    -- Always reset colors and cursor position after title/border drawing
    gui.screen.term.setBackgroundColor(self.bgColor)
    gui.screen.term.setTextColor(self.fgColor or colors.white)
    -- Move cursor to safe position (bottom-right of panel)
    gui.screen.term.setCursorPos(absX + self.width - 1, absY + self.height - 1)
    
    -- Draw children with scroll offset
    for _, child in ipairs(self.children) do
        if self.scrollable then
            child.y = child.y - self.scrollOffset
        end
        if child.y + child.height > contentStartY then
            child:draw()
        end
    end
end

components.Panel = Panel

function components.createPanel(id, x, y, width, height, title)
    local panel = Panel:new(id, x, y, width, height)
    panel.title = title
    panel.borderColor = gui.getColor("border")
    return gui.registerComponent(panel)
end

-- ========== BUTTON COMPONENT ==========

local Button = {}
setmetatable(Button, {__index = Component})

function Button:new(id, x, y, width, height, text)
    local obj = Component:new(id, "button", x, y, width, height)
    setmetatable(obj, {__index = Button})
    
    obj.text = text or ""
    obj.icon = nil
    obj.callback = nil
    obj.bgColor = gui.getColor("primary")
    obj.fgColor = gui.getColor("foreground")
    obj.hoverBgColor = gui.getColor("hover")
    obj.activeBgColor = gui.getColor("active")
    obj.disabledBgColor = gui.getColor("disabled")
    obj.isHovered = false
    obj.isPressed = false
    obj.originalBgColor = nil
    obj.flashTimer = nil
    obj.enableClickFeedback = true  -- Visual feedback on click
    
    -- Event handlers
    obj:on("click", function(self)
        if self.enabled then
            -- Visual click feedback
            if self.enableClickFeedback then
                self.originalBgColor = self.bgColor
                self.bgColor = colors.white
                gui.requestRedraw()
                gui.draw()
                
                -- Restore color after brief flash
                self.flashTimer = os.startTimer(0.15)
            end
            
            -- Execute callback
            if self.callback then
                self.callback(self)
            end
        end
    end)
    
    obj:on("mouseEnter", function(self)
        self.isHovered = true
        gui.requestRedraw()
    end)
    
    obj:on("mouseLeave", function(self)
        self.isHovered = false
        self.isPressed = false
        gui.requestRedraw()
    end)
    
    return obj
end

function Button:draw()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePosition()
    
    -- Determine colors
    local bgColor = self.bgColor
    if not self.enabled then
        bgColor = self.disabledBgColor
    elseif self.isPressed then
        bgColor = self.activeBgColor
    elseif self.isHovered then
        bgColor = self.hoverBgColor
    end
    
    -- Draw button background
    gui.screen.term.setBackgroundColor(bgColor)
    gui.screen.term.setTextColor(self.fgColor)
    
    for dy = 0, self.height - 1 do
        gui.screen.term.setCursorPos(absX, absY + dy)
        gui.screen.term.write(string.rep(" ", self.width))
    end
    
    -- Draw text (centered)
    local displayText = self.text
    if self.icon then
        displayText = self.icon .. " " .. displayText
    end
    
    local textY = absY + math.floor(self.height / 2)
    local textX = absX + math.floor((self.width - #displayText) / 2)
    gui.screen.term.setCursorPos(textX, textY)
    gui.screen.term.write(displayText)
end

components.Button = Button

function components.createButton(id, x, y, width, height, text, callback)
    local button = Button:new(id, x, y, width, height, text)
    button.callback = callback
    return gui.registerComponent(button)
end

-- ========== TEXT LABEL COMPONENT ==========

local Label = {}
setmetatable(Label, {__index = Component})

function Label:new(id, x, y, text)
    local obj = Component:new(id, "label", x, y, #text, 1)
    setmetatable(obj, {__index = Label})
    
    obj.text = text or ""
    obj.align = "left" -- left, center, right
    obj.bgColor = gui.getColor("background")
    obj.fgColor = gui.getColor("foreground")
    
    return obj
end

function Label:draw()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePosition()
    
    gui.screen.term.setCursorPos(absX, absY)
    gui.screen.term.setBackgroundColor(self.bgColor)
    gui.screen.term.setTextColor(self.fgColor)
    
    local displayText = self.text
    
    -- Truncate text if it exceeds width
    if #displayText > self.width then
        displayText = displayText:sub(1, self.width - 3) .. "..."
    end
    
    if self.align == "center" then
        local padding = math.floor((self.width - #displayText) / 2)
        displayText = string.rep(" ", padding) .. displayText
    elseif self.align == "right" then
        local padding = self.width - #displayText
        displayText = string.rep(" ", padding) .. displayText
    end
    
    gui.screen.term.write(displayText)
end

components.Label = Label

function components.createLabel(id, x, y, text, align)
    local label = Label:new(id, x, y, text)
    label.align = align or "left"
    return gui.registerComponent(label)
end

-- ========== TEXT INPUT COMPONENT ==========

local TextInput = {}
setmetatable(TextInput, {__index = Component})

function TextInput:new(id, x, y, width)
    local obj = Component:new(id, "textinput", x, y, width, 1)
    setmetatable(obj, {__index = TextInput})
    
    obj.value = ""
    obj.placeholder = ""
    obj.maxLength = nil
    obj.isFocused = false
    obj.cursorPos = 0
    obj.bgColor = gui.getColor("background")
    obj.fgColor = gui.getColor("foreground")
    obj.borderColor = gui.getColor("border")
    obj.focusBorderColor = gui.getColor("primary")
    
    obj:on("click", function(self)
        self.isFocused = true
        gui.state.focusedComponent = self
        -- Debug notification
        gui.notify("Input focused - type now", colors.white, colors.blue, 2)
        gui.requestRedraw()
    end)
    
    return obj
end

function TextInput:handleChar(char)
    if self.isFocused then
        if not self.maxLength or #self.value < self.maxLength then
            self.value = self.value .. char
            self.cursorPos = #self.value
            -- Debug: show that char was received
            gui.notify("Typed: " .. char, colors.white, colors.green, 1)
            gui.requestRedraw()
            return true
        end
    else
        -- Debug: not focused
        gui.notify("Not focused!", colors.white, colors.red, 1)
    end
    return false
end

function TextInput:handleKey(key)
    if self.isFocused then
        if key == keys.backspace then
            if #self.value > 0 then
                self.value = self.value:sub(1, -2)
                self.cursorPos = #self.value
                gui.requestRedraw()
            end
            return true
        elseif key == keys.delete then
            self.value = ""
            self.cursorPos = 0
            gui.requestRedraw()
            return true
        elseif key == keys.enter then
            self.isFocused = false
            gui.state.focusedComponent = nil
            gui.screen.term.setCursorBlink(false)
            gui.requestRedraw()
            return true
        end
    end
    return false
end

function TextInput:draw()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePosition()
    
    -- Draw background
    gui.screen.term.setCursorPos(absX, absY)
    gui.screen.term.setBackgroundColor(self.bgColor)
    gui.screen.term.setTextColor(self.fgColor)
    
    local displayText = self.value
    if #displayText == 0 and #self.placeholder > 0 then
        gui.screen.term.setTextColor(gui.getColor("disabled"))
        displayText = self.placeholder
    end
    
    displayText = gui.truncateText(displayText, self.width - 2)
    gui.screen.term.write(" " .. displayText .. string.rep(" ", self.width - #displayText - 1))
    
    -- Draw border
    local borderColor = self.isFocused and self.focusBorderColor or self.borderColor
    if borderColor then
        gui.screen.term.setTextColor(borderColor)
        gui.screen.term.setCursorPos(absX, absY)
        gui.screen.term.write("[")
        gui.screen.term.setCursorPos(absX + self.width - 1, absY)
        gui.screen.term.write("]")
    end
    
    -- Draw cursor if focused
    if self.isFocused then
        gui.screen.term.setCursorPos(absX + 1 + #self.value, absY)
        gui.screen.term.setCursorBlink(true)
    else
        gui.screen.term.setCursorBlink(false)
    end
end

components.TextInput = TextInput

function components.createTextInput(id, x, y, width, placeholder)
    local input = TextInput:new(id, x, y, width)
    input.placeholder = placeholder or ""
    return gui.registerComponent(input)
end

-- ========== PROGRESS BAR COMPONENT ==========

local ProgressBar = {}
setmetatable(ProgressBar, {__index = Component})

function ProgressBar:new(id, x, y, width)
    local obj = Component:new(id, "progressbar", x, y, width, 1)
    setmetatable(obj, {__index = ProgressBar})
    
    obj.value = 0 -- 0-100
    obj.showLabel = true
    obj.fillColor = gui.getColor("success")
    obj.bgColor = gui.getColor("secondary")
    obj.fgColor = gui.getColor("foreground")
    
    return obj
end

function ProgressBar:draw()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePosition()
    
    -- Calculate fill width
    local fillWidth = math.floor((self.value / 100) * self.width)
    
    -- Draw filled portion
    gui.screen.term.setCursorPos(absX, absY)
    gui.screen.term.setBackgroundColor(self.fillColor)
    gui.screen.term.write(string.rep(" ", fillWidth))
    
    -- Draw empty portion
    gui.screen.term.setBackgroundColor(self.bgColor)
    gui.screen.term.write(string.rep(" ", self.width - fillWidth))
    
    -- Draw label
    if self.showLabel then
        local label = math.floor(self.value) .. "%"
        local labelX = absX + math.floor((self.width - #label) / 2)
        gui.screen.term.setCursorPos(labelX, absY)
        gui.screen.term.setTextColor(self.fgColor)
        gui.screen.term.write(label)
    end
end

components.ProgressBar = ProgressBar

function components.createProgressBar(id, x, y, width)
    local bar = ProgressBar:new(id, x, y, width)
    return gui.registerComponent(bar)
end

-- ========== LIST COMPONENT ==========

local List = {}
setmetatable(List, {__index = Component})

function List:new(id, x, y, width, height)
    local obj = Component:new(id, "list", x, y, width, height)
    setmetatable(obj, {__index = List})
    
    obj.items = {}
    obj.selectedIndex = nil
    obj.scrollOffset = 0
    obj.itemHeight = 1
    obj.onSelect = nil
    obj.bgColor = gui.getColor("background")
    obj.fgColor = gui.getColor("foreground")
    obj.selectedBgColor = gui.getColor("primary")
    obj.hoverBgColor = gui.getColor("hover")
    
    return obj
end

function List:addItem(text, data)
    table.insert(self.items, {text = text, data = data})
    gui.requestRedraw()
end

function List:clearItems()
    self.items = {}
    self.selectedIndex = nil
    self.scrollOffset = 0
    gui.requestRedraw()
end

function List:draw()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePosition()
    
    local visibleItems = math.floor(self.height / self.itemHeight)
    local startIdx = self.scrollOffset + 1
    local endIdx = math.min(startIdx + visibleItems - 1, #self.items)
    
    for i = startIdx, endIdx do
        local item = self.items[i]
        local itemY = absY + ((i - startIdx) * self.itemHeight)
        
        -- Determine background color
        local bgColor = self.bgColor
        if i == self.selectedIndex then
            bgColor = self.selectedBgColor
        end
        
        gui.screen.term.setCursorPos(absX, itemY)
        gui.screen.term.setBackgroundColor(bgColor)
        gui.screen.term.setTextColor(self.fgColor)
        
        local displayText = gui.truncateText(item.text, self.width)
        displayText = displayText .. string.rep(" ", self.width - #displayText)
        gui.screen.term.write(displayText)
    end
end

function List:handleClick(x, y)
    local absX, absY = self:getAbsolutePosition()
    local relY = y - absY
    local clickedIndex = self.scrollOffset + math.floor(relY / self.itemHeight) + 1
    
    if clickedIndex >= 1 and clickedIndex <= #self.items then
        self.selectedIndex = clickedIndex
        if self.onSelect then
            self.onSelect(self.items[clickedIndex])
        end
        self:emit("select", self.items[clickedIndex])
        gui.requestRedraw()
    end
end

components.List = List

function components.createList(id, x, y, width, height)
    local list = List:new(id, x, y, width, height)
    list:on("click", function(self, x, y)
        self:handleClick(x, y)
    end)
    return gui.registerComponent(list)
end

-- ========== CHECKBOX COMPONENT ==========

local Checkbox = {}
setmetatable(Checkbox, {__index = Component})

function Checkbox:new(id, x, y, label)
    local obj = Component:new(id, "checkbox", x, y, 3 + #label, 1)
    setmetatable(obj, {__index = Checkbox})
    
    obj.checked = false
    obj.label = label or ""
    obj.onChange = nil
    obj.bgColor = gui.getColor("background")
    obj.fgColor = gui.getColor("foreground")
    obj.checkColor = gui.getColor("success")
    
    obj:on("click", function(self)
        self.checked = not self.checked
        if self.onChange then
            self.onChange(self.checked)
        end
        self:emit("change", self.checked)
        gui.requestRedraw()
    end)
    
    return obj
end

function Checkbox:draw()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePosition()
    
    gui.screen.term.setCursorPos(absX, absY)
    gui.screen.term.setBackgroundColor(self.bgColor)
    gui.screen.term.setTextColor(self.fgColor)
    
    local checkmark = self.checked and "X" or " "
    gui.screen.term.setTextColor(self.checkColor)
    gui.screen.term.write("[" .. checkmark .. "]")
    
    gui.screen.term.setTextColor(self.fgColor)
    gui.screen.term.write(" " .. self.label)
end

components.Checkbox = Checkbox

function components.createCheckbox(id, x, y, label, checked)
    local checkbox = Checkbox:new(id, x, y, label)
    checkbox.checked = checked or false
    return gui.registerComponent(checkbox)
end

return components

