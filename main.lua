local lume = require "lume"
if arg[2] == "debug" then
    require("lldebugger").start()
end

local border = 50
local squareSize = 50
local squares = 9
local selectionBorder = 4

local choiceBtn = { x=border + selectionBorder,
                    y=border + squares * squareSize + selectionBorder,
                    width=squareSize * 3 - selectionBorder * 2,
                    height=squareSize - selectionBorder * 2,
                    text="Show Choices"}
local saveBtn = {   x=border + 5 * squareSize + selectionBorder,
                    y=border + squares * squareSize + selectionBorder,
                    width=squareSize * 2 - selectionBorder * 2,
                    height=squareSize - selectionBorder * 2,
                    text="Save"}
local solveBtn = {  x=border + 3 * squareSize + selectionBorder,
                    y=border + squares * squareSize + selectionBorder,
                    width=squareSize * 2 - selectionBorder * 2,
                    height=squareSize - selectionBorder * 2,
                    text="Solve"}
local exitBtn = {   x=border + 7 * squareSize + selectionBorder,
                    y=border + squares * squareSize + selectionBorder,
                    width = squareSize * 2 - selectionBorder * 2,
                    height = squareSize - selectionBorder * 2,
                    text="Exit"}
local buttons = {choiceBtn, saveBtn, solveBtn, exitBtn}

local selection = {x=nil,y=nil}
local board = {}
local options = nil
local cozette20 = love.graphics.newFont("CozetteVector.ttf", 20)
local cozette10 = love.graphics.newFont("CozetteVector.ttf", 10)

local function getSquare(x, y)
    local sx, sy = math.floor((x - border) / squareSize), math.floor((y - border) / squareSize)
    if sx >= 0 and sx < squares and sy >= 0 and sy < squares then
        return sx, sy
    else
        return nil,nil
    end
end

local function saveBoard()
    local serialized = lume.serialize(board)
    love.filesystem.write("sudoku.txt", serialized)
end

local function loadBoard()
    if love.filesystem.getInfo("sudoku.txt") then
        local file = love.filesystem.read("sudoku.txt")
        return lume.deserialize(file)
    else
        return false
    end
end

local function getOptions()
    if not options then
        options = {}
        for i,v in ipairs(board) do
            options[i] = {}
            for j,w in ipairs(v) do
                if w > 0 then
                    options[i][j] = w
                else
                    options[i][j] = {1,2,3,4,5,6,7,8,9}
                end
            end
        end
    end
    for i,v in ipairs(board) do
        for j,w in ipairs(v) do
            if w == 0 then
                local ih = math.ceil(i/3)
                local jh = math.ceil(j/3)
                for k=1,#v do
                    if v[k] ~= 0 then
                        options[i][j][v[k]] = 0
                    end
                    if board[k][j] ~= 0 then
                        options[i][j][board[k][j]] = 0
                    end
                    local kj = math.ceil(k/3)
                    local ki = k - (kj - 1) * 3
                    local kih = ki + (ih - 1) * 3
                    local kjh = kj + (jh - 1) * 3
                    if board[kih][kjh] ~= 0 then
                        options[i][j][board[kih][kjh]] = 0
                    end
                end
            end
        end
    end
end

function love.load()
    love.window.setMode(border * 2 + squareSize * squares, border * 2 + squareSize * squares)
    love.graphics.setFont(cozette20)
    local data = loadBoard()
    if data then
        board = data
    else
        for i=1,squares do
            board[i] = {}
            for j=1,squares do
                board[i][j] = 0
            end
        end
    end
end

function love.draw()
    local length = border + squareSize * squares
    love.graphics.line(border, border, length, border)
    love.graphics.line(border, border, border, length)
    for i=1,squares do
        if i % math.sqrt(squares) == 0 then
            love.graphics.setColor(1,1,1,1)
        else
            love.graphics.setColor(1,1,1,0.6)
        end
        local position = border + squareSize * i
        love.graphics.line(border, position, length, position)
        love.graphics.line(position, border, position, length)
    end
    if selection.x and selection.y then
        love.graphics.rectangle("line", border + selection.x * squareSize + selectionBorder, border + selection.y * squareSize + selectionBorder,
             squareSize - selectionBorder * 2, squareSize - selectionBorder * 2)
    end
    for i,v in ipairs(board) do
        for j,w in ipairs(v) do
            if w > 0 then
                love.graphics.print(w,  border + squareSize * (j-1) + math.floor(squareSize/3),
                                        border + squareSize * (i-1) + math.floor(squareSize/3), 0)
            end
        end
    end
    
    if options then
        love.graphics.setFont(cozette10)
        for i,v in ipairs(board) do
            for j,w in ipairs(v) do
                if w == 0 then
                    for k,x in ipairs(options[i][j]) do
                        if x > 0 and x < 6 then
                            love.graphics.print(x,  border + squareSize * (j-1) + math.floor(squareSize/6) * (k-1) + selectionBorder,
                                                    border + squareSize * (i-1) + selectionBorder)
                        elseif x >= 6 then
                            love.graphics.print(x,  border + squareSize * (j-1) + math.floor(squareSize/6) * (k-6) + selectionBorder,
                                                    border + squareSize * (i-1) + math.floor(squareSize/4) + selectionBorder)
                        end
                    end
                end
            end
        end
        love.graphics.setFont(cozette20)
    end

    for i,btn in ipairs(buttons) do
        love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height)
        love.graphics.print(btn.text, btn.x + selectionBorder, btn.y + math.floor(btn.height/3))
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        selection.x, selection.y = getSquare(x, y)
        if selection.x == nil then
            if  x > choiceBtn.x and x < choiceBtn.x + choiceBtn.width
            and y > choiceBtn.y and y < choiceBtn.y + choiceBtn.height then
                getOptions()
            elseif  x > saveBtn.x and x < saveBtn.x + saveBtn.width
            and     y > saveBtn.y and y < saveBtn.y + saveBtn.height then
                saveBoard()
            elseif  x > exitBtn.x and x < exitBtn.x + exitBtn.width
            and     y > exitBtn.y and y < exitBtn.y + exitBtn.width then
                love.event.quit()
            end
        end
    end
end

function love.keypressed(key)
    if key == "tab" then
        if not (love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift")) then
            if not selection.x or not selection.y then
                selection.x, selection.y = 0, 0
            else
                selection.x = selection.x + 1
                if selection.x >= squares then
                    selection.x = 0
                    selection.y = selection.y + 1
                    if selection.y >= squares then
                        selection.x, selection.y = nil, nil
                    end
                end
            end
        else
            if not selection.x or not selection.y then
                selection.x, selection.y = squares-1, squares-1
            else
                selection.x = selection.x - 1
                if selection.x < 0 then
                    selection.x = squares - 1
                    selection.y = selection.y - 1
                    if selection.y < 0 then
                        selection.x, selection.y = nil, nil
                    end
                end
            end
        end
    elseif key == "up" then
        if selection.y then
            if selection.y == 0 then
                selection.y = squares - 1
            else
                selection.y = selection.y - 1
            end
        end
    elseif key == "down" then
        if selection.y then
            if selection.y == squares - 1 then
                selection.y = 0
            else
                selection.y = selection.y + 1
            end
        end
    elseif key == "left" then
        if selection.x then
            if selection.x == 0 then
                selection.x = squares - 1
            else
                selection.x = selection.x - 1
            end
        end
    elseif key == "right" then
        if selection.x then
            if selection.x == squares - 1 then
                selection.x = 0
            else
                selection.x = selection.x + 1
            end
        end
    elseif tonumber(key) then
        board[selection.y+1][selection.x+1] = tonumber(key)
    end
end
