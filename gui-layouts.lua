-- CCMine GUI Framework - Layout Manager
-- Automatic component positioning and responsive layouts

local guiCore = require("gui-core")
local gui = guiCore

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

return layouts

