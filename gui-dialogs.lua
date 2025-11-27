-- CCMine GUI Framework - Dialog System
-- Modal dialogs for confirmations, alerts, and prompts

local gui = require("gui-core")
local components = require("gui-components")

local dialogs = {}

-- ========== MODAL BACKGROUND ==========

local function drawModalBackground()
    -- Dim the background to show this is a modal
    local screenW, screenH = gui.screen.width, gui.screen.height
    gui.screen.term.setBackgroundColor(colors.black)
    for y = 1, screenH do
        gui.screen.term.setCursorPos(1, y)
        gui.screen.term.write(string.rep(" ", screenW))
    end
end

-- ========== CONFIRM DIALOG ==========

function dialogs.confirm(title, message, onYes, onNo)
    -- Clear screen and show modal
    gui.clearComponents()
    drawModalBackground()
    
    local screenW, screenH = gui.screen.width, gui.screen.height
    local dialogW = math.min(screenW - 10, 40)
    local dialogH = 9
    local dialogX = math.floor((screenW - dialogW) / 2)
    local dialogY = math.floor((screenH - dialogH) / 2)
    
    -- Dialog panel
    local panel = components.createPanel("confirmDialog", dialogX, dialogY, dialogW, dialogH, title)
    panel.borderColor = gui.getColor("warning")
    
    -- Message
    local msgY = dialogY + 2
    local maxMsgWidth = dialogW - 4
    
    -- Split message into lines if needed
    local words = {}
    for word in message:gmatch("%S+") do
        table.insert(words, word)
    end
    
    local lines = {}
    local currentLine = ""
    for _, word in ipairs(words) do
        if #currentLine + #word + 1 <= maxMsgWidth then
            currentLine = currentLine .. (currentLine ~= "" and " " or "") .. word
        else
            table.insert(lines, currentLine)
            currentLine = word
        end
    end
    if #currentLine > 0 then
        table.insert(lines, currentLine)
    end
    
    -- Display message lines
    for i, line in ipairs(lines) do
        local label = components.createLabel("msg" .. i, dialogX + 2, msgY + i - 1, line)
        label.fgColor = gui.getColor("foreground")
    end
    
    -- Buttons
    local btnY = dialogY + dialogH - 3
    local btnW = math.floor((dialogW - 6) / 2)
    
    local yesBtn = components.createButton("yes", dialogX + 2, btnY, btnW, 2, "Yes", function()
        if onYes then onYes() end
    end)
    yesBtn.bgColor = gui.getColor("error")
    
    local noBtn = components.createButton("no", dialogX + dialogW - btnW - 2, btnY, btnW, 2, "No", function()
        if onNo then onNo() end
    end)
    
    gui.requestRedraw()
    gui.draw()
end

-- ========== ALERT DIALOG ==========

function dialogs.alert(title, message, onOk)
    gui.clearComponents()
    drawModalBackground()
    
    local screenW, screenH = gui.screen.width, gui.screen.height
    local dialogW = math.min(screenW - 10, 40)
    local dialogH = 8
    local dialogX = math.floor((screenW - dialogW) / 2)
    local dialogY = math.floor((screenH - dialogH) / 2)
    
    -- Dialog panel
    local panel = components.createPanel("alertDialog", dialogX, dialogY, dialogW, dialogH, title)
    panel.borderColor = gui.getColor("primary")
    
    -- Message
    local msgLabel = components.createLabel("msg", dialogX + 2, dialogY + 3, message)
    msgLabel.width = dialogW - 4
    
    -- OK Button
    local btnW = 12
    local okBtn = components.createButton("ok", 
        dialogX + math.floor((dialogW - btnW) / 2), 
        dialogY + dialogH - 3, 
        btnW, 
        2, 
        "OK", 
        function()
            if onOk then onOk() end
        end)
    okBtn.bgColor = gui.getColor("primary")
    
    gui.requestRedraw()
    gui.draw()
end

-- ========== PROMPT DIALOG ==========

function dialogs.prompt(title, message, defaultValue, onSubmit, onCancel)
    gui.clearComponents()
    drawModalBackground()
    
    local screenW, screenH = gui.screen.width, gui.screen.height
    local dialogW = math.min(screenW - 10, 40)
    local dialogH = 10
    local dialogX = math.floor((screenW - dialogW) / 2)
    local dialogY = math.floor((screenH - dialogH) / 2)
    
    -- Dialog panel
    local panel = components.createPanel("promptDialog", dialogX, dialogY, dialogW, dialogH, title)
    panel.borderColor = gui.getColor("primary")
    
    -- Message
    local msgLabel = components.createLabel("msg", dialogX + 2, dialogY + 2, message)
    msgLabel.width = dialogW - 4
    
    -- Input
    local input = components.createTextInput("promptInput", dialogX + 2, dialogY + 4, dialogW - 4, "")
    if defaultValue then
        input.value = defaultValue
    end
    
    -- Buttons
    local btnY = dialogY + dialogH - 3
    local btnW = math.floor((dialogW - 6) / 2)
    
    local submitBtn = components.createButton("submit", dialogX + 2, btnY, btnW, 2, "Submit", function()
        if onSubmit then onSubmit(input.value) end
    end)
    submitBtn.bgColor = gui.getColor("success")
    
    local cancelBtn = components.createButton("cancel", dialogX + dialogW - btnW - 2, btnY, btnW, 2, "Cancel", function()
        if onCancel then onCancel() end
    end)
    
    gui.requestRedraw()
    gui.draw()
end

return dialogs

