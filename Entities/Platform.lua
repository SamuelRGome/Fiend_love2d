local Platform = {}

function Platform.load()
    Platform.x = 300
    Platform.y = 400
    Platform.sprite = love.graphics.newImage("Assets/PH_Plataform.png")
end

function Platform.update(dt)

end

function Platform.draw()
    love.graphics.draw(Platform.sprite, Platform.x, Platform.y)
end

return Platform