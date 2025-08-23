local Input = require("Engine.Input")
local Player = require("Entities.Player")
local Platform = require("Entities.Platform")
local Background = require("Entities.Background")
local Camera = require("Entities.Camera")
local bump = require("Libs/bump/bump")

function love.load()
    Input.load()
    Player.load()
    Background.load()
    Camera.load()
    love.window.setMode(640, 480)
    
    -- Mundo de colisão
    world = bump.newWorld()
    world:add(Player, Player.x, Player.y, Player.Width, Player.Height)
    
    -- Platform.load() agora cria as plataformas e as adiciona ao world automaticamente
    Platform.load()
end

function love.update(dt)
    Input.update(dt)
    Player.update(dt)
    
    -- Atualiza a câmera baseado na posição do player
    Camera.update(Player.x, Player.y, dt)
    
    -- Atualiza o background baseado na posição da câmera
    Background.update(Camera.y, dt)
    
    -- Atualiza o sistema de plataformas
    Platform.update(Player.y, dt)
end

function love.draw()
    -- Desenha o background primeiro (não afetado pela câmera)
    Background.draw()
    
    -- Aplica a transformação da câmera para elementos do mundo
    Camera.apply()
    
    -- Desenha os objetos do jogo (afetados pela câmera)
    Platform.draw()
    Player.draw()
    
    -- Remove a transformação da câmera
    Camera.unapply()
    
    -- UI/Debug (não afetados pela câmera)
    love.graphics.setColor(1, 1, 1) -- Garante que o texto seja branco
    love.graphics.print("Input - x: " .. Input.dx .. " y: " .. Input.dy, 10, 10)
    love.graphics.print("Player Y: " .. math.floor(Player.y), 10, 30)
    love.graphics.print("Camera Y: " .. math.floor(Camera.y), 10, 50)
    love.graphics.print("Platforms: " .. Platform.getCount(), 10, 70)
end