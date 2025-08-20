local Input = require("../Engine.Input")
local Player = {}

function Player.load()
    Player.x = 320
    Player.y = 240
    Player.speed = 250
end

function Player.update(dt)
    Player.x = Player.x + Input.dx * Input.speed * dt
    Player.y = Player.y + Input.dy * Input.speed * dt
end

function Player.draw()
    love.graphics.circle("fill", Player.x, Player.y, 10)
end

return Player