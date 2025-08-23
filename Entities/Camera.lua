local Camera = {}

function Camera.load()
    Camera.x = 0
    Camera.y = 0
    Camera.targetY = 0
    Camera.smoothing = 5 -- Velocidade de suavização da câmera
end

function Camera.update(playerX, playerY, dt)
    -- Garantir que os valores não sejam nil
    playerX = playerX or 0
    playerY = playerY or 0
    dt = dt or 0
    
    -- A câmera segue o player no eixo Y
    Camera.targetY = playerY - love.graphics.getHeight() / 2
    
    -- Suavização da câmera (opcional, pode remover se quiser câmera fixa)
    Camera.y = Camera.y + (Camera.targetY - Camera.y) * Camera.smoothing * dt
    
    -- Mantém X centralizado (pode ajustar se quiser movimento horizontal da câmera)
    Camera.x = 0
end

function Camera.apply()
    love.graphics.push()
    love.graphics.translate(-Camera.x, -Camera.y)
end

function Camera.unapply()
    love.graphics.pop()
end

-- Função para converter coordenadas de tela para mundo
function Camera.screenToWorld(screenX, screenY)
    return screenX + Camera.x, screenY + Camera.y
end

-- Função para converter coordenadas de mundo para tela
function Camera.worldToScreen(worldX, worldY)
    return worldX - Camera.x, worldY - Camera.y
end

return Camera