local Platform = {}

function Platform.load()
    Platform.x = 250
    Platform.y = 350

    Platform.Sprite = love.graphics.newImage("Assets/PH_Plataform.png")
    Platform.Width = Platform.Sprite:getWidth()
    Platform.Height = Platform.Sprite:getHeight()

    world:addCollisionClass("Platform")

    -- Collider alinhado pelo canto superior-esquerdo (igual ao draw)
    Platform.collider = world:newRectangleCollider(
        Platform.x, Platform.y,
        Platform.Width, Platform.Height
    )
    Platform.collider:setCollisionClass("Platform")
    Platform.collider:setType("static")
end

function Platform.draw()
    love.graphics.draw(Platform.Sprite, Platform.x, Platform.y)
end

return Platform
