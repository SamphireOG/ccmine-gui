-- CCMine GUI Framework - Layout Manager
-- Automatic component positioning and responsive layouts

local guiCore = require("gui-core")
local gui = guiCore
local Component = gui.Component
local components = require("gui-components")

local layouts = {}

-- ========== LAYOUT BASE CLASS ==========

local Layout = {}
Layout.__index = Layout

function Layout:new(type)
    local obj = {
        type = type,
        children = {},
        spacing = 1,
        padding = 1
    }
    setmetatable(obj, self)
    return obj
end

function Layout:add(component)
    table.insert(self.children, component)
end

function Layout:remove(component)
    for i, c in ipairs(self.children) do
        if c.id == component.id then
            table.remove(self.children, i)
            break
        end
    end
end

function Layout:clear()
    self.children = {}
end

function Layout:apply(x, y, width, height)
    -- Override in subclasses
end

-- ========== VERTICAL LAYOUT ==========

local VerticalLayout = {}
setmetatable(VerticalLayout, {__index = Layout})

function VerticalLayout:new()
    local obj = Layout:new("vertical")
    setmetatable(obj, {__index = VerticalLayout})
    return obj
end

function VerticalLayout:apply(x, y, width, height)
    local currentY = y + self.padding
    local availableWidth = width - (self.padding * 2)
    
    for i, component in ipairs(self.children) do
        component.x = x + self.padding
        component.y = currentY
        component.width = availableWidth
        
        currentY = currentY + component.height + self.spacing
        
        -- Stop if we exceed available height
        if currentY > y + height - self.padding then
            break
        end
    end
end

layouts.VerticalLayout = VerticalLayout

function layouts.createVerticalLayout(spacing, padding)
    local layout = VerticalLayout:new()
    layout.spacing = spacing or 1
    layout.padding = padding or 1
    return layout
end

-- ========== HORIZONTAL LAYOUT ==========

local HorizontalLayout = {}
setmetatable(HorizontalLayout, {__index = Layout})

function HorizontalLayout:new()
    local obj = Layout:new("horizontal")
    setmetatable(obj, {__index = HorizontalLayout})
    return obj
end

function HorizontalLayout:apply(x, y, width, height)
    local currentX = x + self.padding
    local availableHeight = height - (self.padding * 2)
    
    for i, component in ipairs(self.children) do
        component.x = currentX
        component.y = y + self.padding
        component.height = availableHeight
        
        currentX = currentX + component.width + self.spacing
        
        -- Stop if we exceed available width
        if currentX > x + width - self.padding then
            break
        end
    end
end

layouts.HorizontalLayout = HorizontalLayout

function layouts.createHorizontalLayout(spacing, padding)
    local layout = HorizontalLayout:new()
    layout.spacing = spacing or 1
    layout.padding = padding or 1
    return layout
end

-- ========== GRID LAYOUT ==========

local GridLayout = {}
setmetatable(GridLayout, {__index = Layout})

function GridLayout:new(columns, rows)
    local obj = Layout:new("grid")
    setmetatable(obj, {__index = GridLayout})
    obj.columns = columns or 2
    obj.rows = rows or 2
    return obj
end

function GridLayout:apply(x, y, width, height)
    local cellWidth = math.floor((width - (self.spacing * (self.columns + 1))) / self.columns)
    local cellHeight = math.floor((height - (self.spacing * (self.rows + 1))) / self.rows)
    
    for i, component in ipairs(self.children) do
        local col = ((i - 1) % self.columns)
        local row = math.floor((i - 1) / self.columns)
        
        component.x = x + self.padding + (col * (cellWidth + self.spacing))
        component.y = y + self.padding + (row * (cellHeight + self.spacing))
        component.width = cellWidth
        component.height = cellHeight
    end
end

layouts.GridLayout = GridLayout

function layouts.createGridLayout(columns, rows, spacing, padding)
    local layout = GridLayout:new(columns, rows)
    layout.spacing = spacing or 1
    layout.padding = padding or 1
    return layout
end

-- ========== STACK LAYOUT ==========

local StackLayout = {}
setmetatable(StackLayout, {__index = Layout})

function StackLayout:new()
    local obj = Layout:new("stack")
    setmetatable(obj, {__index = StackLayout})
    obj.activeIndex = 1
    return obj
end

function StackLayout:apply(x, y, width, height)
    -- Hide all components except active one
    for i, component in ipairs(self.children) do
        if i == self.activeIndex then
            component.visible = true
            component.x = x
            component.y = y
            component.width = width
            component.height = height
        else
            component.visible = false
        end
    end
end

function StackLayout:showComponent(index)
    if index >= 1 and index <= #self.children then
        self.activeIndex = index
        gui.requestRedraw()
    end
end

function StackLayout:next()
    self.activeIndex = (self.activeIndex % #self.children) + 1
    gui.requestRedraw()
end

function StackLayout:previous()
    self.activeIndex = self.activeIndex - 1
    if self.activeIndex < 1 then
        self.activeIndex = #self.children
    end
    gui.requestRedraw()
end

layouts.StackLayout = StackLayout

function layouts.createStackLayout()
    return StackLayout:new()
end

-- ========== ANCHOR LAYOUT (Absolute Positioning) ==========

local AnchorLayout = {}
setmetatable(AnchorLayout, {__index = Layout})

function AnchorLayout:new()
    local obj = Layout:new("anchor")
    setmetatable(obj, {__index = AnchorLayout})
    obj.anchors = {} -- Store anchor rules per component
    return obj
end

function AnchorLayout:addWithAnchor(component, anchor)
    -- anchor = {
    --   top = 10, left = 5, right = nil, bottom = nil,
    --   width = 20, height = 5
    -- }
    table.insert(self.children, component)
    self.anchors[component.id] = anchor
end

function AnchorLayout:apply(x, y, width, height)
    for _, component in ipairs(self.children) do
        local anchor = self.anchors[component.id]
        if anchor then
            -- Apply anchor rules
            if anchor.left then
                component.x = x + anchor.left
            elseif anchor.right then
                component.x = x + width - anchor.right - (anchor.width or component.width)
            end
            
            if anchor.top then
                component.y = y + anchor.top
            elseif anchor.bottom then
                component.y = y + height - anchor.bottom - (anchor.height or component.height)
            end
            
            if anchor.width then
                component.width = anchor.width
            end
            
            if anchor.height then
                component.height = anchor.height
            end
            
            -- Center anchors
            if anchor.centerX then
                component.x = x + math.floor((width - component.width) / 2)
            end
            
            if anchor.centerY then
                component.y = y + math.floor((height - component.height) / 2)
            end
        end
    end
end

layouts.AnchorLayout = AnchorLayout

function layouts.createAnchorLayout()
    return AnchorLayout:new()
end

-- ========== RESPONSIVE LAYOUT HELPERS ==========

function layouts.getScreenSize()
    return gui.screen.width, gui.screen.height
end

function layouts.centerComponent(component)
    local screenW, screenH = layouts.getScreenSize()
    component.x = math.floor((screenW - component.width) / 2) + 1
    component.y = math.floor((screenH - component.height) / 2) + 1
end

function layouts.fillScreen(component)
    local screenW, screenH = layouts.getScreenSize()
    component.x = 1
    component.y = 1
    component.width = screenW
    component.height = screenH
end

function layouts.splitVertical(ratio, padding)
    -- Returns two regions: top and bottom
    -- ratio = 0.5 means 50/50 split
    local screenW, screenH = layouts.getScreenSize()
    local pad = padding or 0
    
    local topHeight = math.floor(screenH * ratio) - pad
    local bottomHeight = screenH - topHeight - pad
    
    return {
        top = {x = 1, y = 1, width = screenW, height = topHeight},
        bottom = {x = 1, y = topHeight + pad + 1, width = screenW, height = bottomHeight}
    }
end

function layouts.splitHorizontal(ratio, padding)
    -- Returns two regions: left and right
    local screenW, screenH = layouts.getScreenSize()
    local pad = padding or 0
    
    local leftWidth = math.floor(screenW * ratio) - pad
    local rightWidth = screenW - leftWidth - pad
    
    return {
        left = {x = 1, y = 1, width = leftWidth, height = screenH},
        right = {x = leftWidth + pad + 1, y = 1, width = rightWidth, height = screenH}
    }
end

function layouts.createRegions(config)
    -- config = {
    --   header = 3,     -- Fixed height
    --   footer = 2,     -- Fixed height
    --   sidebar = 15,   -- Fixed width (optional)
    --   content = true  -- Remaining space
    -- }
    local screenW, screenH = layouts.getScreenSize()
    local regions = {}
    
    local headerH = config.header or 0
    local footerH = config.footer or 0
    local sidebarW = config.sidebar or 0
    
    if headerH > 0 then
        regions.header = {x = 1, y = 1, width = screenW, height = headerH}
    end
    
    if footerH > 0 then
        regions.footer = {x = 1, y = screenH - footerH + 1, width = screenW, height = footerH}
    end
    
    local contentY = headerH + 1
    local contentH = screenH - headerH - footerH
    
    if sidebarW > 0 then
        regions.sidebar = {x = 1, y = contentY, width = sidebarW, height = contentH}
        regions.content = {x = sidebarW + 1, y = contentY, width = screenW - sidebarW, height = contentH}
    else
        regions.content = {x = 1, y = contentY, width = screenW, height = contentH}
    end
    
    return regions
end

-- ========== LAYOUT MANAGER ==========

local LayoutManager = {}

function LayoutManager:new()
    local obj = {
        layouts = {},
        activeLayout = nil
    }
    setmetatable(obj, {__index = LayoutManager})
    return obj
end

function LayoutManager:registerLayout(name, layout)
    self.layouts[name] = layout
end

function LayoutManager:activateLayout(name, x, y, width, height)
    local layout = self.layouts[name]
    if layout then
        self.activeLayout = name
        local w = width or gui.screen.width
        local h = height or gui.screen.height
        layout:apply(x or 1, y or 1, w, h)
        gui.requestRedraw()
        return true
    end
    return false
end

function LayoutManager:getLayout(name)
    return self.layouts[name]
end

function LayoutManager:reapply()
    if self.activeLayout then
        local layout = self.layouts[self.activeLayout]
        if layout then
            layout:apply(1, 1, gui.screen.width, gui.screen.height)
            gui.requestRedraw()
        end
    end
end

layouts.LayoutManager = LayoutManager

function layouts.createManager()
    return LayoutManager:new()
end

-- ========== FORM LAYOUT ==========
-- Automatically stacks form fields (label above input)

local FormLayout = {}
setmetatable(FormLayout, {__index = Component})

function FormLayout:new(id, x, y, width)
    local obj = Component:new(id, "formlayout", x, y, width, 1)
    setmetatable(obj, {__index = FormLayout})
    
    obj.fieldSpacing = 1  -- Space between fields
    obj.labelHeight = 1
    obj.inputHeight = 1
    
    return obj
end

function FormLayout:addField(labelText, inputPlaceholder, inputWidth, defaultValue)
    local currentFieldCount = math.floor(#self.children / 2)  -- Each field is label + input
    local fieldY = self.y + (currentFieldCount * (self.labelHeight + self.inputHeight + self.fieldSpacing))
    
    -- Create label (will be drawn by main loop, not by FormLayout)
    local labelId = self.id .. "_lbl_" .. currentFieldCount
    local label = components.createLabel(labelId, self.x, fieldY, labelText)
    -- Don't set parent - let main loop draw it
    table.insert(self.children, label)
    
    -- Create input below label (will be drawn by main loop)
    local inputId = self.id .. "_input_" .. currentFieldCount
    local input = components.createTextInput(inputId, self.x, fieldY + 1, inputWidth or self.width, inputPlaceholder)
    if defaultValue then
        input.value = defaultValue
    end
    -- Don't set parent - let main loop draw it
    table.insert(self.children, input)
    
    -- Update layout height
    self.height = (currentFieldCount + 1) * (self.labelHeight + self.inputHeight + self.fieldSpacing)
    
    return input
end

function FormLayout:draw()
    -- FormLayout is just a helper for positioning
    -- Children are drawn by main loop since they have no parent
end

layouts.FormLayout = FormLayout

function layouts.createFormLayout(id, x, y, width)
    local layout = FormLayout:new(id, x, y, width)
    return gui.registerComponent(layout)
end

-- ========== RESPONSIVE LAYOUT HELPERS ==========

-- Get current screen dimensions
function layouts.getScreenSize()
    return term.getSize()
end

-- Calculate responsive button sizes for a row
-- Returns: buttonWidth, positions array
function layouts.calculateButtonRow(numButtons, spacing, margin)
    local w = term.getSize()
    spacing = spacing or 1
    margin = margin or 0
    
    local availableWidth = w - (margin * 2) - (spacing * (numButtons - 1))
    local buttonWidth = math.floor(availableWidth / numButtons)
    
    local positions = {}
    for i = 1, numButtons do
        positions[i] = {
            x = margin + ((i - 1) * (buttonWidth + spacing)),
            width = buttonWidth
        }
    end
    
    -- Adjust last button to fill remaining space
    if numButtons > 0 then
        local lastPos = positions[numButtons]
        lastPos.width = w - lastPos.x - margin
    end
    
    return buttonWidth, positions
end

-- Create a responsive grid layout
-- Returns: cellWidth, cellHeight, grid positions
function layouts.createResponsiveGrid(cols, rows, spacing, margin)
    local w, h = term.getSize()
    spacing = spacing or 1
    margin = margin or 1
    
    local availableWidth = w - (margin * 2) - (spacing * (cols - 1))
    local availableHeight = h - (margin * 2) - (spacing * (rows - 1))
    
    local cellWidth = math.floor(availableWidth / cols)
    local cellHeight = math.floor(availableHeight / rows)
    
    local positions = {}
    for row = 1, rows do
        positions[row] = {}
        for col = 1, cols do
            local x = margin + ((col - 1) * (cellWidth + spacing))
            local y = margin + ((row - 1) * (cellHeight + spacing))
            
            -- Adjust last column to fill remaining width
            local w = cellWidth
            if col == cols then
                w = term.getSize() - x - margin
            end
            
            positions[row][col] = {
                x = x,
                y = y,
                width = w,
                height = cellHeight
            }
        end
    end
    
    return cellWidth, cellHeight, positions
end

-- Create a full-width panel
function layouts.createFullWidthPanel(id, y, height, title)
    local w = term.getSize()
    return components.createPanel(id, 1, y, w - 1, height, title)
end

-- Center a component horizontally
function layouts.centerHorizontally(componentWidth)
    local w = term.getSize()
    return math.floor((w - componentWidth) / 2)
end

-- Center a component vertically
function layouts.centerVertically(componentHeight)
    local _, h = term.getSize()
    return math.floor((h - componentHeight) / 2)
end

-- Center a component both horizontally and vertically
function layouts.centerBoth(componentWidth, componentHeight)
    return layouts.centerHorizontally(componentWidth), 
           layouts.centerVertically(componentHeight)
end

-- Calculate responsive column widths
-- Takes array of weights (e.g., {1, 2, 1} for 25%, 50%, 25%)
function layouts.calculateColumns(weights, spacing, margin)
    local w = term.getSize()
    spacing = spacing or 1
    margin = margin or 0
    
    local numCols = #weights
    local totalWeight = 0
    for _, weight in ipairs(weights) do
        totalWeight = totalWeight + weight
    end
    
    local availableWidth = w - (margin * 2) - (spacing * (numCols - 1))
    
    local columns = {}
    local currentX = margin
    
    for i, weight in ipairs(weights) do
        local colWidth = math.floor((availableWidth * weight) / totalWeight)
        
        -- Last column gets remaining space
        if i == numCols then
            colWidth = w - currentX - margin
        end
        
        columns[i] = {
            x = currentX,
            width = colWidth
        }
        
        currentX = currentX + colWidth + spacing
    end
    
    return columns
end

-- Create responsive footer with evenly distributed buttons
function layouts.createFooter(height, buttonLabels, callbacks, margin)
    local w, h = term.getSize()
    height = height or 3
    margin = margin or 0
    
    local footerY = h - height + 1
    local numButtons = #buttonLabels
    local _, positions = layouts.calculateButtonRow(numButtons, 1, margin)
    
    local buttons = {}
    for i, label in ipairs(buttonLabels) do
        local pos = positions[i]
        local btn = components.createButton(
            "footer_btn_" .. i,
            pos.x,
            footerY,
            pos.width,
            height - 1,
            label,
            callbacks[i]
        )
        table.insert(buttons, btn)
    end
    
    return buttons, footerY
end

-- Get safe content area (excludes header/footer)
function layouts.getContentArea(headerHeight, footerHeight)
    local w, h = term.getSize()
    headerHeight = headerHeight or 0
    footerHeight = footerHeight or 0
    
    return {
        x = 1,
        y = headerHeight + 1,
        width = w,
        height = h - headerHeight - footerHeight
    }
end

-- Check if component fits on screen
function layouts.fitsOnScreen(x, y, width, height)
    local w, h = term.getSize()
    return x >= 1 and y >= 1 and (x + width - 1) <= w and (y + height - 1) <= h
end

-- Constrain dimensions to fit screen
function layouts.constrainToScreen(x, y, width, height)
    local w, h = term.getSize()
    
    -- Constrain position
    x = math.max(1, math.min(x, w))
    y = math.max(1, math.min(y, h))
    
    -- Constrain size
    width = math.min(width, w - x + 1)
    height = math.min(height, h - y + 1)
    
    return x, y, width, height
end

return layouts

