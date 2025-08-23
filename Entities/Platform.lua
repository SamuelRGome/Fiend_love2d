local Platform = {}

function Platform.load()
    -- Lista de todas as plataformas ativas
    Platform.platforms = {}
    
    -- Configurações de geração
    Platform.sprite = love.graphics.newImage("Assets/PH_Plataform.png")
    Platform.width = Platform.sprite:getWidth()
    Platform.height = Platform.sprite:getHeight()
    
    -- Configurações de spawn
    Platform.spawnDistance = 150 -- Balanceado para decisões estratégicas
    Platform.lastSpawnY = 0
    Platform.screenBuffer = 450
    
    -- Configurações de espaçamento (considerando dash e pulo duplo)
    Platform.minGapX = Platform.width + 20 -- Gap que pode ser atravessado com dash
    Platform.minGapY = 250 -- Gap para pulo duplo
    Platform.dashDistance = 80 -- Distância aproximada do dash
    Platform.doubleJumpHeight = 60 -- Altura aproximada do pulo duplo
    
    -- Zonas da tela
    Platform.minX = 15
    Platform.maxX = 600 - Platform.width - 15
    Platform.leftZone = Platform.minX + 90
    Platform.rightZone = Platform.maxX - 90
    Platform.centerZone = 320 - Platform.width/2
    Platform.midLeftZone = 160 - Platform.width/2
    Platform.midRightZone = 460 - Platform.width/2
    
    -- Tipos de plataforma (para futuro uso com itens/obstáculos)
    Platform.types = {
        NORMAL = "normal",
        ITEM = "item",         -- Terá item em cima
        OBSTACLE = "obstacle", -- Terá obstáculo
        SAFE = "safe",         -- Sempre segura
        RISKY = "risky"        -- Perigosa mas pode ter recompensa
    }
    
    Platform.createInitialPlatforms()
end

function Platform.createInitialPlatforms()
    -- Plataforma inicial (sempre segura)
    Platform.addPlatform(250, 350, Platform.types.SAFE)
    
    -- Cria plataformas iniciais com tipos variados
    for i = 1, 8 do
        local baseY = 350 + (i * Platform.spawnDistance)
        
        if i == 1 then
            Platform.generateTutorialPattern(baseY) -- Primeiro nível mais simples
        elseif i % 3 == 0 then
            Platform.generateRiskRewardPattern(baseY) -- Padrões com risco/recompensa
        elseif i % 2 == 0 then
            Platform.generateSkillTestPattern(baseY) -- Testa habilidades
        else
            Platform.generateStrategicPattern(baseY) -- Padrão estratégico
        end
    end
    
    Platform.lastSpawnY = 350 + (8 * Platform.spawnDistance)
end

function Platform.addPlatform(x, y, platformType)
    platformType = platformType or Platform.types.NORMAL
    
    if Platform.checkOverlap(x, y) then
        return false
    end
    
    local platform = {
        x = x,
        y = y,
        width = Platform.width,
        height = Platform.height,
        type = platformType,
        hasItem = platformType == Platform.types.ITEM,
        hasObstacle = platformType == Platform.types.OBSTACLE,
        id = "platform_" .. #Platform.platforms + 1
    }
    
    table.insert(Platform.platforms, platform)
    world:add(platform, x, y, Platform.width, Platform.height)
    return true
end

function Platform.checkOverlap(newX, newY)
    for _, platform in ipairs(Platform.platforms) do
        local dx = math.abs(newX - platform.x)
        local dy = math.abs(newY - platform.y)
        
        if dx < Platform.minGapX and dy < Platform.minGapY then
            return true
        end
    end
    return false
end

function Platform.update(playerY, dt)
    Platform.removeFarPlatforms(playerY)
    Platform.generateNewPlatforms(playerY)
end

function Platform.removeFarPlatforms(playerY)
    local removeDistance = 700 -- Maior para dar tempo de usar poderes
    
    for i = #Platform.platforms, 1, -1 do
        local platform = Platform.platforms[i]
        
        if platform.y < playerY - removeDistance then
            world:remove(platform)
            table.remove(Platform.platforms, i)
        end
    end
end

function Platform.generateNewPlatforms(playerY)
    local screenHeight = love.graphics.getHeight()
    local generateAhead = playerY + screenHeight + Platform.screenBuffer
    
    while Platform.lastSpawnY < generateAhead do
        Platform.lastSpawnY = Platform.lastSpawnY + Platform.spawnDistance
        
        local yVariation = math.random(-10, 10)
        local baseY = Platform.lastSpawnY + yVariation
        
        -- Padrões pensados para mecânicas de poder
        local patternType = math.random(1, 100)
        
        if patternType <= 25 then
            -- 25% - Padrão risco/recompensa
            Platform.generateRiskRewardPattern(baseY)
            
        elseif patternType <= 45 then
            -- 20% - Teste de habilidades (dash, pulo duplo, etc)
            Platform.generateSkillTestPattern(baseY)
            
        elseif patternType <= 60 then
            -- 15% - Padrão estratégico (escolha de rota)
            Platform.generateStrategicPattern(baseY)
            
        elseif patternType <= 75 then
            -- 15% - Padrão de travessia (bom para atravessar plataformas)
            Platform.generateTraversalPattern(baseY)
            
        elseif patternType <= 85 then
            -- 10% - Padrão vertical (pulo duplo necessário)
            Platform.generateVerticalChallengePattern(baseY)
            
        elseif patternType <= 95 then
            -- 10% - Padrão dash (gaps de dash)
            Platform.generateDashChallengePattern(baseY)
            
        else
            -- 5% - Padrão combo (múltiplas habilidades)
            Platform.generateComboPattern(baseY)
        end
    end
end

function Platform.generateTutorialPattern(baseY)
    -- Padrão simples para ensinar mecânicas básicas
    Platform.addPlatform(Platform.minX + 20, baseY, Platform.types.SAFE)
    Platform.addPlatform(Platform.centerZone, baseY, Platform.types.ITEM) -- Item fácil
    Platform.addPlatform(Platform.maxX - 20, baseY, Platform.types.SAFE)
end

function Platform.generateRiskRewardPattern(baseY)
    -- Bordas sempre bloqueadas + escolhas no meio
    Platform.addPlatform(Platform.minX + math.random(0, 20), baseY + math.random(-10, 10), Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.maxX - math.random(0, 20), baseY + math.random(-10, 10), Platform.types.OBSTACLE)
    
    -- Rota segura vs rota com item
    Platform.addPlatform(Platform.midLeftZone, baseY - 20, Platform.types.SAFE)
    Platform.addPlatform(Platform.centerZone, baseY + 5, Platform.types.ITEM) -- Item arriscado
    Platform.addPlatform(Platform.midRightZone, baseY - 20, Platform.types.SAFE)
    
    -- Plataforma perigosa mas com possível recompensa
    if math.random() < 0.3 then
        Platform.addPlatform(Platform.centerZone + 60, baseY + 30, Platform.types.RISKY)
    end
end

function Platform.generateSkillTestPattern(baseY)
    -- Testa habilidades específicas
    local skillType = math.random(1, 3)
    
    if skillType == 1 then
        -- Teste de dash - gaps largos
        Platform.addPlatform(Platform.leftZone, baseY, Platform.types.SAFE)
        Platform.addPlatform(Platform.rightZone, baseY, Platform.types.ITEM) -- Recompensa por usar dash
        Platform.addPlatform(Platform.minX, baseY + 20, Platform.types.OBSTACLE)
        Platform.addPlatform(Platform.maxX, baseY + 20, Platform.types.OBSTACLE)
        
    elseif skillType == 2 then
        -- Teste de pulo duplo - plataformas altas
        Platform.addPlatform(Platform.centerZone, baseY + 40, Platform.types.SAFE)
        Platform.addPlatform(Platform.midLeftZone, baseY - 15, Platform.types.ITEM)
        Platform.addPlatform(Platform.midRightZone, baseY - 15, Platform.types.ITEM)
        Platform.addPlatform(Platform.minX + 40, baseY + 60, Platform.types.OBSTACLE)
        Platform.addPlatform(Platform.maxX - 40, baseY + 60, Platform.types.OBSTACLE)
        
    else
        -- Teste de atravessar - linha densa
        Platform.addPlatform(Platform.leftZone, baseY, Platform.types.OBSTACLE)
        Platform.addPlatform(Platform.centerZone - 30, baseY, Platform.types.ITEM)
        Platform.addPlatform(Platform.centerZone + 30, baseY, Platform.types.OBSTACLE)
        Platform.addPlatform(Platform.rightZone, baseY, Platform.types.OBSTACLE)
        Platform.addPlatform(Platform.centerZone, baseY - 30, Platform.types.SAFE) -- Alternativa por cima
    end
end

function Platform.generateStrategicPattern(baseY)
    -- Múltiplas rotas com diferentes riscos/recompensas
    Platform.addPlatform(Platform.minX + 10, baseY, Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.maxX - 10, baseY, Platform.types.OBSTACLE)
    
    -- Rota alta (segura mas sem itens)
    Platform.addPlatform(Platform.midLeftZone, baseY - 35, Platform.types.SAFE)
    Platform.addPlatform(Platform.midRightZone, baseY - 35, Platform.types.SAFE)
    
    -- Rota média (equilibrada)
    Platform.addPlatform(Platform.centerZone - 50, baseY - 15, Platform.types.NORMAL)
    Platform.addPlatform(Platform.centerZone + 50, baseY - 15, Platform.types.ITEM)
    
    -- Rota baixa (arriscada mas com recompensas)
    Platform.addPlatform(Platform.centerZone, baseY + 20, Platform.types.RISKY)
end

function Platform.generateTraversalPattern(baseY)
    -- Linha densa boa para usar atravessar plataformas
    Platform.addPlatform(Platform.minX + 30, baseY, Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.leftZone + 20, baseY, Platform.types.ITEM)
    Platform.addPlatform(Platform.centerZone - 20, baseY, Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.centerZone + 20, baseY, Platform.types.ITEM)
    Platform.addPlatform(Platform.rightZone - 20, baseY, Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.maxX - 30, baseY, Platform.types.ITEM)
    
    -- Alternativas por cima e por baixo
    Platform.addPlatform(Platform.centerZone, baseY - 40, Platform.types.SAFE)
    Platform.addPlatform(Platform.centerZone, baseY + 40, Platform.types.SAFE)
end

function Platform.generateVerticalChallengePattern(baseY)
    -- Torres que exigem pulo duplo
    Platform.addPlatform(Platform.minX + 20, baseY + 30, Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.maxX - 20, baseY + 30, Platform.types.OBSTACLE)
    
    -- Torres no meio
    Platform.addPlatform(Platform.midLeftZone, baseY, Platform.types.SAFE)
    Platform.addPlatform(Platform.midLeftZone, baseY - 50, Platform.types.ITEM)
    
    Platform.addPlatform(Platform.midRightZone, baseY, Platform.types.SAFE)
    Platform.addPlatform(Platform.midRightZone, baseY - 50, Platform.types.ITEM)
    
    Platform.addPlatform(Platform.centerZone, baseY - 25, Platform.types.NORMAL)
end

function Platform.generateDashChallengePattern(baseY)
    -- Gaps que só passam com dash
    Platform.addPlatform(Platform.leftZone - 30, baseY, Platform.types.SAFE)
    Platform.addPlatform(Platform.rightZone + 30, baseY, Platform.types.ITEM) -- Recompensa por dash longo
    
    -- Bordas sempre ocupadas
    Platform.addPlatform(Platform.minX, baseY + 25, Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.maxX, baseY + 25, Platform.types.OBSTACLE)
    
    -- Plataforma central como alternativa
    Platform.addPlatform(Platform.centerZone, baseY + 40, Platform.types.NORMAL)
end

function Platform.generateComboPattern(baseY)
    -- Padrão que exige múltiplas habilidades
    Platform.addPlatform(Platform.minX, baseY, Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.maxX, baseY, Platform.types.OBSTACLE)
    
    -- Caminho complexo
    Platform.addPlatform(Platform.leftZone, baseY - 20, Platform.types.SAFE)
    Platform.addPlatform(Platform.centerZone, baseY + 15, Platform.types.ITEM) -- Dash necessário
    Platform.addPlatform(Platform.rightZone, baseY - 35, Platform.types.ITEM) -- Pulo duplo necessário
    Platform.addPlatform(Platform.centerZone + 40, baseY - 50, Platform.types.RISKY) -- Combo completo
    
    -- Linha de obstáculos para atravessar
    Platform.addPlatform(Platform.midLeftZone, baseY + 35, Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.centerZone, baseY + 35, Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.midRightZone, baseY + 35, Platform.types.OBSTACLE)
end

function Platform.draw()
    for _, platform in ipairs(Platform.platforms) do
        -- Desenha a plataforma base
        love.graphics.draw(Platform.sprite, platform.x, platform.y)
        
        -- Debug: desenha tipo da plataforma (remover depois)
        
        love.graphics.setColor(1, 1, 1, 0.8)
        if platform.type == Platform.types.ITEM then
            love.graphics.setColor(0, 1, 0, 0.8) -- Verde para item
        elseif platform.type == Platform.types.OBSTACLE then
            love.graphics.setColor(1, 0, 0, 0.8) -- Vermelho para obstáculo
        elseif platform.type == Platform.types.SAFE then
            love.graphics.setColor(0, 0, 1, 0.8) -- Azul para seguro
        elseif platform.type == Platform.types.RISKY then
            love.graphics.setColor(1, 1, 0, 0.8) -- Amarelo para arriscado
        end
        
        love.graphics.rectangle("line", platform.x, platform.y, platform.width, platform.height)
        love.graphics.setColor(1, 1, 1)
        
    end
end

function Platform.getCount()
    return #Platform.platforms
end

-- Função para obter plataformas de um tipo específico (útil para spawnar itens/obstáculos)
function Platform.getPlatformsByType(platformType)
    local filtered = {}
    for _, platform in ipairs(Platform.platforms) do
        if platform.type == platformType then
            table.insert(filtered, platform)
        end
    end
    return filtered
end

-- Função para verificar se uma posição está em gap de dash (útil para IA do dash)
function Platform.isInDashGap(x, y)
    for _, platform in ipairs(Platform.platforms) do
        local distance = math.abs(x - platform.x)
        if distance > Platform.minGapX and distance <= Platform.dashDistance then
            return true
        end
    end
    return false
end

return Platform