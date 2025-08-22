local Input = require("Engine.Input")
local Player = require("Entities.Player")
local Platform = require("Entities.Platform")


function love.load()
    wf = require "Libs.windfield.windfield"
    world = wf.newWorld(0, 100, true)

    Input.load()
    Player.load()
    Platform.load()
    love.window.setMode(640, 480)

    --Background
    bg_Img = love.graphics.newImage("Assets/PH_Background.png")

end

function love.update(dt)
    Input.update(dt)
    world:update(dt)
    Player.update(dt)
    
    
    -- Gravidade Player


    -- Background Infinite

    
    
    
end

function love.draw()
    
    love.graphics.draw(bg_Img, 0, 0)
    Player.draw()
    love.graphics.print("x: " .. Input.dx .. " y: " .. Input.dy, 10, 10)
    Platform.draw()
    world:draw()
end