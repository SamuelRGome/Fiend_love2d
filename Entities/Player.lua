local Input = require("Engine.Input")
local Player = {}

function Player.load()
    Player.x = 250
    Player.y = 250
    Player.vx = 0
    Player.vy = 0
    Player.Speed = 200
    Player.Gravity = 400
    Player.JumpForce = 200
    Player.Sprite = love.graphics.newImage("Assets/PH_Fiend.png")
    Player.Width = Player.Sprite:getWidth()
    Player.Height = Player.Sprite:getHeight()
end

function Player.update(dt)
    -- Movimento horizontal
    Player.vx = 0
    if Input.isDown("left") then
        Player.vx = -Player.Speed
    elseif Input.isDown("right") then
        Player.vx = Player.Speed
    end

    -- Gravidade
    Player.vy = Player.vy + Player.Gravity * dt

    -- Move com bump
    local futureX, futureY = Player.x + Player.vx * dt, Player.y + Player.vy * dt
    local actualX, actualY, cols, len = world:move(Player, futureX, futureY)

    Player.x, Player.y = actualX, actualY

    -- Checa colisões
    local onGround = false
    for i = 1, len do
        local col = cols[i]
        if col.normal.y == -1 then
            onGround = true
            Player.vy = 0
        end
    end

    -- Pulo
    if Input.isDown("up") and onGround then
        Player.vy = -Player.JumpForce
    end
end

function Player.draw()
    love.graphics.draw(Player.Sprite, Player.x, Player.y)
end

return Player
