local lume = require "lume"
if arg[2] == "debug" then
    require("lldebugger").start()
end

local border = 50
local squareSize = 50
local numSquares = 9
local selectionBorder = 4

local choiceBtn = { x=border + selectionBorder,
                    y=border + numSquares * squareSize + selectionBorder,
                    width=squareSize * 2 - selectionBorder * 2,
                    height=squareSize - selectionBorder * 2,
                    text="Choices"}
local solveBtn = {  x=border + 2 * squareSize + selectionBorder,
                    y=border + numSquares * squareSize + selectionBorder,
                    width=squareSize * 2 - selectionBorder * 2,
                    height=squareSize - selectionBorder * 2,
                    text="Solve"}
local clearBtn = {  x = border + 4 * squareSize + selectionBorder,
                    y=border + numSquares * squareSize + selectionBorder,
                    width=squareSize * 2 - selectionBorder * 2,
                    height=squareSize - selectionBorder * 2,
                    text="Clear"}
local saveBtn = {   x=border + 6 * squareSize + selectionBorder,
                    y=border + numSquares * squareSize + selectionBorder,
                    width=squareSize * 2 - selectionBorder * 2,
                    height=squareSize - selectionBorder * 2,
                    text="Save"}
local exitBtn = {   x=border + 8 * squareSize + selectionBorder,
                    y=border + numSquares * squareSize + selectionBorder,
                    width = squareSize * 2 - selectionBorder * 2,
                    height = squareSize - selectionBorder * 2,
                    text="Exit"}
local buttons = {choiceBtn, solveBtn, clearBtn, saveBtn, exitBtn}

local selection = {x=nil,y=nil}
local board = {}
local options = nil
local cozette20 = love.graphics.newFont("CozetteVector.ttf", 20)
local cozette10 = love.graphics.newFont("CozetteVector.ttf", 10)

local function getSquare(x, y) -- returns the grid position of x and y
    local sx, sy = math.floor((x - border) / squareSize), math.floor((y - border) / squareSize)
    if sx >= 0 and sx < numSquares and sy >= 0 and sy < numSquares then
        return sx, sy
    else
        return nil,nil
    end
end

local function saveBoard() -- serializes board data and writes to file
    local serialized = lume.serialize(board)
    love.filesystem.write("sudoku.txt", serialized)
end

local function loadBoard() -- reads file (if available) and loads board data
    if love.filesystem.getInfo("sudoku.txt") then
        local file = love.filesystem.read("sudoku.txt")
        return lume.deserialize(file)
    else
        return false
    end
end

local function clearBoard() -- fills the board with zeros
    for i=1,numSquares do
        board[i] = {}
        for j=1,numSquares do
            board[i][j] = 0
        end
    end
    options = nil
end

local function getOptions() -- generates possibilities for each open square on the board
    if not options then
        options = {}
        for i,v in ipairs(board) do
            options[i] = {}
            for j,w in ipairs(v) do
                if w > 0 then
                    options[i][j] = w
                else
                    options[i][j] = {}
                    for k=1,numSquares do
                        options[i][j][k] = k
                    end
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

local function isSolved() -- checks if all squares on the board are filled (not for correctness)
    for _,v in ipairs(board) do
        for _,w in ipairs(v) do
            if w == 0 then
                return false
            end
        end
    end
    return true
end

local function solveBoard()
    getOptions()
    local changed = false
    for i,v in ipairs(board) do -- fill all squares with only one option
        for j,w in ipairs(v) do
            if w == 0 then
                local o = 0
                local num = 0
                for k=1,#v do
                    if options and options[i][j][k] ~= 0 then
                        o = o + 1
                        num = k
                    end
                end
                if o == 1 then
                    board[i][j] = num
                    changed = true
                    getOptions()
                end
            end
        end
    end

    if not isSolved() then
        for i,v in ipairs(board) do -- fill squares that are the only option for their row
            for num=1,numSquares do
                local unique = true
                local squarej = 0
                for j,w in ipairs(v) do
                    if w == num then
                        unique = false
                        break
                    elseif w == 0 and options and options[i][j][num] ~= 0 then
                        if squarej == 0 then
                            squarej = j
                        else
                            unique = false
                            break
                        end
                    end
                end
                if unique and squarej ~= 0 then
                    v[squarej] = num
                    changed = true
                    getOptions()
                end
            end
        end
        if not isSolved() then
            for j=1,#board[1] do -- fill squares that are the only option for their column
                for num=1,numSquares do
                    local unique = true
                    local squarei = 0
                    for i,v in ipairs(board) do
                        if v[j] == num then
                            unique = false
                            break
                        elseif v[j] == 0 and options and options[i][j][num] ~= 0 then
                            if squarei == 0 then
                                squarei = i
                            else
                                unique = false
                                break
                            end
                        end
                    end
                    if unique and squarei ~= 0 then
                        board[squarei][j] = num
                        changed = true
                        getOptions()
                    end
                end
            end
            if not isSolved() then
                for kh=1,numSquares do -- fill squares that are the only option for their group
                    local jh=math.ceil(kh/3)
                    local ih=kh-((jh-1)*3)
                    for num=1,numSquares do
                        local unique = true
                        local squarei, squarej = 0,0
                        for k=1,numSquares do
                            local kj=math.ceil(k/3)
                            local ki=k-((kj-1)*3)
                            local i=ki+(ih-1)*3
                            local j=kj+(jh-1)*3
                            if board[i][j] == num then
                                unique = false
                                break
                            elseif board[i][j] == 0 and options and options[i][j][num] ~= 0 then
                                if squarei == 0 then
                                    squarei = i
                                    squarej = j
                                else
                                    unique = false
                                    break
                                end
                            end
                        end
                        if unique and squarei ~= 0 then
                            board[squarei][squarej] = num
                            changed = true
                            getOptions()
                        end
                    end
                end

                if changed and not isSolved() then
                    solveBoard()
                end
            end
        end
    end
end

function love.load()
    love.window.setMode(border * 2 + squareSize * numSquares, border * 2 + squareSize * numSquares)
    love.graphics.setFont(cozette20)
    local data = loadBoard()
    if data then
        board = data
    else
        for i=1,numSquares do
            board[i] = {}
            for j=1,numSquares do
                board[i][j] = 0
            end
        end
    end
end

function love.draw()
    local length = border + squareSize * numSquares
    love.graphics.line(border, border, length, border)
    love.graphics.line(border, border, border, length)
    for i=1,numSquares do
        if i % math.sqrt(numSquares) == 0 then
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
            and     y > exitBtn.y and y < exitBtn.y + exitBtn.height then
                love.event.quit()
            elseif  x > solveBtn.x and x < solveBtn.x + solveBtn.width
            and     y > solveBtn.y and y < solveBtn.y + solveBtn.height then
                solveBoard()
            elseif  x > clearBtn.x and x < clearBtn.x + clearBtn.width
            and     y > clearBtn.y and y < clearBtn.y + clearBtn.height then
                clearBoard()
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
                if selection.x >= numSquares then
                    selection.x = 0
                    selection.y = selection.y + 1
                    if selection.y >= numSquares then
                        selection.x, selection.y = nil, nil
                    end
                end
            end
        else
            if not selection.x or not selection.y then
                selection.x, selection.y = numSquares-1, numSquares-1
            else
                selection.x = selection.x - 1
                if selection.x < 0 then
                    selection.x = numSquares - 1
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
                selection.y = numSquares - 1
            else
                selection.y = selection.y - 1
            end
        end
    elseif key == "down" then
        if selection.y then
            if selection.y == numSquares - 1 then
                selection.y = 0
            else
                selection.y = selection.y + 1
            end
        end
    elseif key == "left" then
        if selection.x then
            if selection.x == 0 then
                selection.x = numSquares - 1
            else
                selection.x = selection.x - 1
            end
        end
    elseif key == "right" then
        if selection.x then
            if selection.x == numSquares - 1 then
                selection.x = 0
            else
                selection.x = selection.x + 1
            end
        end
    elseif tonumber(key) then
        board[selection.y+1][selection.x+1] = tonumber(key)
    end
end
