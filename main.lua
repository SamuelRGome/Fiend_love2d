local Input = require("Engine.Input")
local Player = require("Entities.Player")
local Platform = require("Entities.Platform")
local Background = require("Entities.Background")
local bump = require("Libs/bump/bump")

function love.load()
    Input.load()
    Player.load()
    Platform.load()
    Background.load()
    
    love.window.setMode(640, 480)
    
    -- Mundo de colisão
    world = bump.newWorld()
    world:add(Player, Player.x, Player.y, Player.Width, Player.Height)
    world:add(Platform, Platform.x, Platform.y, Platform.Width, Platform.Height)
end

function love.update(dt)
    Input.update(dt)
    Player.update(dt)
    
    -- Atualiza o background baseado na posição do player
    Background.update(Player.y, dt)
end

function love.draw()
    -- Desenha o background primeiro (atrás de tudo)
    Background.draw()
    
    -- Desenha os objetos do jogo
    Platform.draw()
    Player.draw()
    
    -- Debug
    love.graphics.setColor(1, 1, 1) -- Garante que o texto seja branco
    love.graphics.print("Input - x: " .. Input.dx .. " y: " .. Input.dy, 10, 10)
    love.graphics.print("Player Y: " .. math.floor(Player.y), 10, 30)
end