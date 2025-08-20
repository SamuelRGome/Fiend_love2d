local Input = require("Engine.Input")
local Player = require("Entities.Player")
local Platform = require("Entities.Platform")

function love.load()
    love.window.setMode(640, 480)
    Input.load()
    Player.load()

    -- Background
    background = love.graphics.newImage("Assets/PH_Background.png")
    bgY = 0
end

function love.update(dt)
    -- atualiza player (inclui input)
    Player.update(dt)

    -- move o background de acordo com o DeltaY do player
    bgY = bgY - Player.DeltaY

    -- loop do background
    if bgY >= love.graphics.getHeight() then
        bgY = bgY - love.graphics.getHeight()
    elseif bgY <= -love.graphics.getHeight() then
        bgY = bgY + love.graphics.getHeight()
    end

    -- aqui você também vai mover plataformas/inimigos usando Player.DeltaY
end

function love.draw()
    -- desenha background infinito
    love.graphics.draw(background, 0, bgY)
    love.graphics.draw(background, 0, bgY + background:getHeight())

    -- desenha player
    Player.draw()

    -- aqui vai desenhar plataformas/inimigos
    Platform.draw()
end
