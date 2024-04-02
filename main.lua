if arg[2] == "debug" then
    require("lldebugger").start()
end

local border = 50
local squareSize = 50
local squares = 9

function love.load()
    love.window.setMode(border * 2 + squareSize * squares, border * 2 + squareSize * squares)
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
end
