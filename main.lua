if arg[2] == "debug" then
    require("lldebugger").start()
end

local border = 50
local squareSize = 50
local squares = 9
local selectionBorder=4

local selection = {x=nil,y=nil}
local board = {}

local function getSquare(x, y)
    local sx, sy = math.floor((x - border) / squareSize), math.floor((y - border) / squareSize)
    if sx >= 0 and sx < squares and sy >= 0 and sy < squares then
        return sx, sy
    else
        return nil,nil
    end
end

function love.load()
    love.window.setMode(border * 2 + squareSize * squares, border * 2 + squareSize * squares)
    love.graphics.setFont(love.graphics.newFont("CozetteVector.ttf", 20))
    for i=1,squares do
        board[i] = {}
        for j=1,squares do
            board[i][j] = 0
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
end

function love.mousereleased(x, y, button)
    if button == 1 then
        selection.x, selection.y = getSquare(x, y)
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
