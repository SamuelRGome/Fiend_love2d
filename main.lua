local Input = require("Engine.Input")
local Player = require("Entities.Player")
local Platform = require("Entities.Platform")
local bump = require("Libs/bump/bump")

local bg_y = 0 -- posição vertical do background

function love.load()
    Input.load()
    Player.load()
    Platform.load()
    love.window.setMode(640, 480)

    -- Mundo de colisão
    world = bump.newWorld()
    world:add(Player, Player.x, Player.y, Player.Width, Player.Height)
    world:add(Platform, Platform.x, Platform.y, Platform.Width, Platform.Height)

    -- Background
    bg_Img = love.graphics.newImage("Assets/PH_Background.png")
end

function love.update(dt)
    Input.update(dt)
    Player.update(dt)


end

function love.draw()
    -- desenha o background considerando a posição Y
    love.graphics.draw(bg_Img, 0, bg_y)

    Player.draw()
    Platform.draw()

    -- debugzinho
    love.graphics.print("x: " .. Input.dx .. " y: " .. Input.dy, 10, 10)
end
