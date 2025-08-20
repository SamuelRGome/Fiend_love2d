local Input = require("../Engine.Input")
local Player = {}

function Player.load()
    Player.x = 320              -- posição horizontal na tela
    Player.ScreenY = 240        -- posição vertical fixa na tela
    Player.WorldY = 0           -- posição vertical no mundo
    Player.speed = 250
    Player.DeltaY = 0
    Player.sprite = love.graphics.newImage("Assets/PH_Fiend.png")
end

function Player.update(dt)
    -- atualiza input (teclado ou joystick)
    Input.update(dt)

    -- calcula movimento vertical do jogador no mundo
    local moveY = 0

    -- teclado
    if Input.isDown("up") then
        moveY = -Player.speed
    elseif Input.isDown("down") then
        moveY = Player.speed
    end
    if Input.isDown("left") then
        Player.x = Player.x - Player.speed * dt
    elseif Input.isDown("right") then
        Player.x = Player.x + Player.speed * dt
    end

    -- joystick/d-pad
    moveY = moveY + Input.dy * Player.speed

    -- atualiza posição do mundo
    Player.WorldY = Player.WorldY + moveY * dt

    -- deltaY usado para mover o background e plataformas
    Player.DeltaY = moveY * dt
end

function Player.draw()
    love.graphics.draw(Player.sprite, Player.x, Player.ScreenY)
end

return Player
