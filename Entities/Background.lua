
background = {
    Backgroundy = 1
}
function background.load()
   -- other things
   background = love.graphics.newImage("Assets/PH_Background.png")
end

-- other callbacks

function background.draw()
    for i = 0, love.graphics.getWidth() / background.getWidth() do
        for j = 0, love.graphics.getHeight() / background:getHeight() do
            love.graphics.draw(background, i * background:getWidth(), j * background:getHeight())
        end
    end
    -- draw other things
end

return Background