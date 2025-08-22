local Background = {}

function Background.load()
    Background.image = love.graphics.newImage("Assets/PH_Background.png")
    Background.width = Background.image:getWidth()
    Background.height = Background.image:getHeight()
    Background.scrollY = 0
end

function Background.update(playerY, dt)
    -- O background se move baseado na posição do player
    -- Fator de parallax (0.5 = move metade da velocidade do player)
    Background.scrollY = playerY * 0.5
end

function Background.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Calcula quantas repetições precisamos
    local tilesX = math.ceil(screenWidth / Background.width) + 1
    local tilesY = math.ceil(screenHeight / Background.height) + 2
    
    -- Calcula offset para scroll infinito
    local offsetY = Background.scrollY % Background.height
    
    -- Desenha tiles do background
    for i = 0, tilesX do
        for j = -1, tilesY do
            local drawX = i * Background.width
            local drawY = j * Background.height - offsetY
            love.graphics.draw(Background.image, drawX, drawY)
        end
    end
end

return Background