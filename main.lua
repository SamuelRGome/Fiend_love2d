local Input = require("Engine.Input")
local Player = require("Entities.Player")


function love.load()
    love.window.setMode(640, 480)
    Input.load()
    Player.load()
end

function love.update(dt)
    Input.update(dt)

    Player.update(dt)

    -- Movimento pelas setas
    if Input.isDown("left") then
        Player.x = Player.x - Player.speed * dt
    end
    if Input.isDown("right") then
        Player.x = Player.x + Player.speed * dt
    end
    if Input.isDown("up") then
        Player.y = Player.y - Player.speed * dt
    end
    if Input.isDown("down") then
        Player.y = Player.y + Player.speed * dt
    end
    
end

function love.draw()
    Player.draw()
end
