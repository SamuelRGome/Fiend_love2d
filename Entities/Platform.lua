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
    
    -- Sistema de segurança SUPER AGRESSIVO
    Platform.lastPlayerCollisionY = 0
    Platform.lastPlayerX = 320 -- Centro da tela inicialmente
    Platform.maxFallWithoutPlatform = 180 -- REDUZIDO drasticamente
    Platform.emergencySpawnDistance = 120 -- Spawn muito mais próximo
    Platform.lastEmergencySpawn = 0
    Platform.trajectoryCheckDistance = 200 -- Distância para verificar trajetória
    Platform.emergencyPlatformWidth = 150 -- Largura da "rede de segurança"
    
    -- Configurações de espaçamento (considerando dash e pulo duplo)
    Platform.minGapX = Platform.width + 20
    Platform.minGapY = 250
    Platform.dashDistance = 80
    Platform.doubleJumpHeight = 60
    
    -- Zonas da tela CORRIGIDAS para 640px
    Platform.screenWidth = 640
    Platform.minX = 15
    Platform.maxX = Platform.screenWidth - Platform.width - 15
    Platform.availableWidth = Platform.maxX - Platform.minX
    
    -- Divisão em 7 zonas para cobertura total
    Platform.zoneWidth = Platform.availableWidth / 7
    Platform.zones = {}
    for i = 0, 6 do
        Platform.zones[i + 1] = Platform.minX + (Platform.zoneWidth * i)
    end
    
    -- Contador para garantir distribuição equilibrada
    Platform.zoneUsageCount = {}
    for i = 1, #Platform.zones do
        Platform.zoneUsageCount[i] = 0
    end
    
    -- Tipos de plataforma
    Platform.types = {
        NORMAL = "normal",
        ITEM = "item",
        OBSTACLE = "obstacle", 
        SAFE = "safe",
        RISKY = "risky",
        EMERGENCY = "emergency" -- Novo tipo para plataformas de emergência
    }
    
    Platform.createInitialPlatforms()
end

-- Sistema de detecção de trajetória em tempo real
function Platform.checkPlayerTrajectory(playerX, playerY)
    -- Define área cônica de verificação baseada na posição do jogador
    local coneWidth = Platform.emergencyPlatformWidth
    local coneStartX = playerX - (coneWidth / 2)
    local coneEndX = playerX + (coneWidth / 2)
    local checkStartY = playerY + 50 -- Começa a verificar um pouco abaixo
    local checkEndY = playerY + Platform.trajectoryCheckDistance
    
    -- Conta quantas plataformas existem na trajetória
    local platformsInPath = 0
    for _, platform in ipairs(Platform.platforms) do
        -- Verifica se a plataforma está na área cônica
        if platform.y >= checkStartY and platform.y <= checkEndY then
            local platformCenterX = platform.x + (Platform.width / 2)
            if platformCenterX >= coneStartX and platformCenterX <= coneEndX then
                platformsInPath = platformsInPath + 1
            end
        end
    end
    
    return platformsInPath == 0 -- Retorna true se não há plataformas na trajetória
end

function Platform.update(playerY, playerX, dt, hasCollidedThisFrame)
    -- Sempre atualiza a posição X do jogador
    Platform.lastPlayerX = playerX
    
    -- Atualiza sistema de segurança
    if hasCollidedThisFrame then
        Platform.lastPlayerCollisionY = playerY
    end
    
    -- SISTEMA 1: Verificação de trajetória (mais importante)
    if Platform.checkPlayerTrajectory(playerX, playerY) then
        local fallDistance = playerY - Platform.lastPlayerCollisionY
        
        -- Se está caindo sem plataforma na trajetória E já caiu um pouco, spawn FORA DA TELA
        if fallDistance > 100 then -- Muito mais sensível
            Platform.spawnTrajectoryPlatformOffscreen(playerX, playerY)
        end
    end
    
    -- SISTEMA 2: Verificação de distância (backup)
    Platform.checkEmergencySpawn(playerY, playerX)
    
    -- SISTEMA 3: Verificação regional (preventiva)
    Platform.preventiveRegionalCheck(playerX, playerY)
    
    Platform.removeFarPlatforms(playerY)
    Platform.generateNewPlatforms(playerY)
end

-- NOVO: Spawn direcionado FORA DA TELA para parecer natural
function Platform.spawnTrajectoryPlatformOffscreen(playerX, playerY)
    local screenHeight = 480
    local visibleBottom = playerY + (screenHeight * 0.6) -- Só spawna além de 60% da tela visível
    local spawnY = math.max(visibleBottom, playerY + Platform.emergencySpawnDistance)
    
    -- Evita spawns muito próximos
    if spawnY <= Platform.lastEmergencySpawn + 80 then
        return
    end
    
    -- Calcula posição baseada na trajetória mas com mais variação natural
    local targetX = playerX + math.random(-50, 50) -- Variação maior para parecer natural
    
    -- Garante que está dentro dos limites
    targetX = math.max(Platform.minX, math.min(targetX, Platform.maxX))
    
    -- Tenta spawn direto
    if not Platform.checkOverlap(targetX, spawnY) then
        if Platform.addPlatform(targetX, spawnY, Platform.types.NORMAL) then -- NORMAL em vez de EMERGENCY
            Platform.lastEmergencySpawn = spawnY
            
            -- Adiciona 1 plataforma próxima de forma mais sutil
            Platform.spawnSubtleBackup(targetX, spawnY)
        end
    end
end

-- NOVO: Backup mais sutil e natural
function Platform.spawnSubtleBackup(centerX, centerY)
    -- Só 1 plataforma de backup, posicionada mais naturalmente
    local backupOffsets = {
        {x = -120, y = 25},
        {x = 120, y = 25},
        {x = -80, y = -20},
        {x = 80, y = -20}
    }
    
    local selectedOffset = backupOffsets[math.random(#backupOffsets)]
    local x = centerX + selectedOffset.x + math.random(-20, 20)
    local y = centerY + selectedOffset.y + math.random(-10, 10)
    
    if x >= Platform.minX and x <= Platform.maxX then
        if not Platform.checkOverlap(x, y) then
            Platform.addPlatform(x, y, Platform.types.NORMAL) -- NORMAL para parecer parte do jogo
        end
    end
end

-- NOVO: Verificação preventiva por região - mais sutil
function Platform.preventiveRegionalCheck(playerX, playerY)
    -- Só verifica regiões FORA da visão do jogador
    local screenHeight = 480
    local offscreenY = playerY + (screenHeight * 0.8) -- Bem fora da tela
    
    local regionRadius = 120
    local regionMinX = playerX - regionRadius
    local regionMaxX = playerX + regionRadius
    
    local platformsInFutureRegion = 0
    for _, platform in ipairs(Platform.platforms) do
        if platform.y >= offscreenY and platform.y <= offscreenY + 200 then
            if platform.x >= regionMinX and platform.x <= regionMaxX then
                platformsInFutureRegion = platformsInFutureRegion + 1
            end
        end
    end
    
    -- Se tem menos de 1 plataforma na região futura, spawna preventivamente
    if platformsInFutureRegion < 1 then
        local preventiveY = offscreenY + math.random(50, 100)
        local preventiveX = playerX + math.random(-100, 100) -- Mais variação
        preventiveX = math.max(Platform.minX, math.min(preventiveX, Platform.maxX))
        
        if not Platform.checkOverlap(preventiveX, preventiveY) then
            Platform.addPlatform(preventiveX, preventiveY, Platform.types.NORMAL)
        end
    end
end

function Platform.removeFarPlatforms(playerY)
    local removeDistance = 700
    
    for i = #Platform.platforms, 1, -1 do
        local platform = Platform.platforms[i]
        
        if platform.y < playerY - removeDistance then
            world:remove(platform)
            table.remove(Platform.platforms, i)
        end
    end
end

-- Sistema de segurança original - agora mais sutil
function Platform.checkEmergencySpawn(playerY, playerX)
    local fallDistance = playerY - Platform.lastPlayerCollisionY
    
    if fallDistance > Platform.maxFallWithoutPlatform then
        local screenHeight = 480
        local offscreenY = playerY + (screenHeight * 0.7) -- Bem fora da tela
        
        if offscreenY > Platform.lastEmergencySpawn + 100 then
            Platform.spawnSubtleEmergencyPlatform(playerX, offscreenY)
            Platform.lastEmergencySpawn = offscreenY
        end
    end
end

function Platform.spawnSubtleEmergencyPlatform(playerX, emergencyY)
    -- Spawn mais distribuído e natural
    local targetX = playerX + math.random(-100, 100) -- Mais variação
    targetX = math.max(Platform.minX, math.min(targetX, Platform.maxX))
    
    local attempts = 0
    while Platform.checkOverlap(targetX, emergencyY) and attempts < 8 do
        targetX = math.random(Platform.minX, Platform.maxX)
        attempts = attempts + 1
    end
    
    -- Spawn como plataforma NORMAL
    if Platform.addPlatform(targetX, emergencyY, Platform.types.NORMAL) then
        -- Adiciona backup sutil
        Platform.spawnSubtleBackup(targetX, emergencyY)
    end
end

-- Função para selecionar zona balanceada
function Platform.selectBalancedZone()
    local minUsage = math.huge
    local leastUsedZones = {}
    
    for i = 1, #Platform.zones do
        if Platform.zoneUsageCount[i] < minUsage then
            minUsage = Platform.zoneUsageCount[i]
            leastUsedZones = {i}
        elseif Platform.zoneUsageCount[i] == minUsage then
            table.insert(leastUsedZones, i)
        end
    end
    
    local selectedIndex = leastUsedZones[math.random(#leastUsedZones)]
    Platform.zoneUsageCount[selectedIndex] = Platform.zoneUsageCount[selectedIndex] + 1
    
    -- Reset dos contadores
    local totalUsage = 0
    for _, count in pairs(Platform.zoneUsageCount) do
        totalUsage = totalUsage + count
    end
    
    if totalUsage >= 20 then
        for i = 1, #Platform.zones do
            Platform.zoneUsageCount[i] = 0
        end
    end
    
    return Platform.zones[selectedIndex]
end

function Platform.selectMultipleZones(count)
    local selectedZones = {}
    local availableIndices = {}
    
    for i = 1, #Platform.zones do
        table.insert(availableIndices, i)
    end
    
    for i = 1, math.min(count, #availableIndices) do
        local randomIndex = math.random(#availableIndices)
        local zoneIndex = availableIndices[randomIndex]
        table.insert(selectedZones, Platform.zones[zoneIndex])
        table.remove(availableIndices, randomIndex)
    end
    
    return selectedZones
end

function Platform.createInitialPlatforms()
    Platform.addPlatform(320 - Platform.width/2, 350, Platform.types.SAFE) -- Centro da tela
    
    for i = 1, 8 do
        local baseY = 350 + (i * Platform.spawnDistance)
        
        if i == 1 then
            Platform.generateTutorialPattern(baseY)
        elseif i % 3 == 0 then
            Platform.generateRiskRewardPattern(baseY)
        elseif i % 2 == 0 then
            Platform.generateSkillTestPattern(baseY)
        else
            Platform.generateStrategicPattern(baseY)
        end
    end
    
    Platform.lastSpawnY = 350 + (8 * Platform.spawnDistance)
    Platform.lastPlayerCollisionY = 350 -- Inicia o sistema de segurança
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

function Platform.generateNewPlatforms(playerY)
    local screenHeight = 480 -- Altura da tela do handheld
    local generateAhead = playerY + screenHeight + Platform.screenBuffer
    
    while Platform.lastSpawnY < generateAhead do
        Platform.lastSpawnY = Platform.lastSpawnY + Platform.spawnDistance
        
        local yVariation = math.random(-10, 10)
        local baseY = Platform.lastSpawnY + yVariation
        
        -- Verificação de densidade regional mais agressiva
        local platformsInRegion = Platform.countPlatformsInRegion(baseY - 150, baseY + 150)
        if platformsInRegion < 4 then -- Aumentado de 3 para 4
            Platform.forceRegionalSpawn(baseY)
        end
        
        -- Padrões normais
        local patternType = math.random(1, 100)
        
        if patternType <= 25 then
            Platform.generateRiskRewardPattern(baseY)
        elseif patternType <= 45 then
            Platform.generateSkillTestPattern(baseY)
        elseif patternType <= 60 then
            Platform.generateStrategicPattern(baseY)
        elseif patternType <= 75 then
            Platform.generateTraversalPattern(baseY)
        elseif patternType <= 85 then
            Platform.generateVerticalChallengePattern(baseY)
        elseif patternType <= 95 then
            Platform.generateDashChallengePattern(baseY)
        else
            Platform.generateComboPattern(baseY)
        end
    end
end

function Platform.countPlatformsInRegion(minY, maxY)
    local count = 0
    for _, platform in ipairs(Platform.platforms) do
        if platform.y >= minY and platform.y <= maxY then
            count = count + 1
        end
    end
    return count
end

function Platform.forceRegionalSpawn(baseY)
    local forcedZones = Platform.selectMultipleZones(4) -- Aumentado para 4 zonas
    
    for i, zone in ipairs(forcedZones) do
        local yOffset = (i - 2) * 30 -- Espalha verticalmente
        if not Platform.checkOverlap(zone, baseY + yOffset) then
            Platform.addPlatform(zone, baseY + yOffset, Platform.types.NORMAL)
        end
    end
end

-- Padrões de geração (simplificados para economizar espaço)
function Platform.generateTutorialPattern(baseY)
    local zones = Platform.selectMultipleZones(3)
    Platform.addPlatform(zones[1], baseY, Platform.types.SAFE)
    Platform.addPlatform(zones[2], baseY, Platform.types.ITEM)
    Platform.addPlatform(zones[3], baseY, Platform.types.SAFE)
end

function Platform.generateRiskRewardPattern(baseY)
    local zones = Platform.selectMultipleZones(5)
    Platform.addPlatform(zones[1], baseY + math.random(-10, 10), Platform.types.OBSTACLE)
    Platform.addPlatform(zones[5], baseY + math.random(-10, 10), Platform.types.OBSTACLE)
    Platform.addPlatform(zones[2], baseY - 20, Platform.types.SAFE)
    Platform.addPlatform(zones[3], baseY + 5, Platform.types.ITEM)
    Platform.addPlatform(zones[4], baseY - 20, Platform.types.SAFE)
    
    if math.random() < 0.3 then
        local extraZone = Platform.selectBalancedZone()
        Platform.addPlatform(extraZone, baseY + 30, Platform.types.RISKY)
    end
end

function Platform.generateSkillTestPattern(baseY)
    local skillType = math.random(1, 3)
    local zones = Platform.selectMultipleZones(6)
    
    if skillType == 1 then
        Platform.addPlatform(zones[1], baseY, Platform.types.SAFE)
        Platform.addPlatform(zones[4], baseY, Platform.types.ITEM)
        Platform.addPlatform(zones[2], baseY + 20, Platform.types.OBSTACLE)
        Platform.addPlatform(zones[5], baseY + 20, Platform.types.OBSTACLE)
    elseif skillType == 2 then
        Platform.addPlatform(zones[3], baseY + 40, Platform.types.SAFE)
        Platform.addPlatform(zones[2], baseY - 15, Platform.types.ITEM)
        Platform.addPlatform(zones[4], baseY - 15, Platform.types.ITEM)
        Platform.addPlatform(zones[1], baseY + 60, Platform.types.OBSTACLE)
        Platform.addPlatform(zones[5], baseY + 60, Platform.types.OBSTACLE)
    else
        for i = 1, 4 do
            local platformType = (i == 2) and Platform.types.ITEM or Platform.types.OBSTACLE
            Platform.addPlatform(zones[i], baseY, platformType)
        end
        Platform.addPlatform(zones[3], baseY - 30, Platform.types.SAFE)
    end
end

function Platform.generateStrategicPattern(baseY)
    local zones = Platform.selectMultipleZones(7)
    Platform.addPlatform(zones[1], baseY, Platform.types.OBSTACLE)
    Platform.addPlatform(zones[7], baseY, Platform.types.OBSTACLE)
    Platform.addPlatform(zones[2], baseY - 35, Platform.types.SAFE)
    Platform.addPlatform(zones[6], baseY - 35, Platform.types.SAFE)
    Platform.addPlatform(zones[3], baseY - 15, Platform.types.NORMAL)
    Platform.addPlatform(zones[5], baseY - 15, Platform.types.ITEM)
    Platform.addPlatform(zones[4], baseY + 20, Platform.types.RISKY)
end

function Platform.generateTraversalPattern(baseY)
    local zones = Platform.selectMultipleZones(6)
    
    for i = 1, 6 do
        local platformType = (i % 2 == 0) and Platform.types.ITEM or Platform.types.OBSTACLE
        Platform.addPlatform(zones[i], baseY, platformType)
    end
    
    local alternativeZone = Platform.selectBalancedZone()
    Platform.addPlatform(alternativeZone, baseY - 40, Platform.types.SAFE)
    Platform.addPlatform(alternativeZone + 60, baseY + 40, Platform.types.SAFE)
end

function Platform.generateVerticalChallengePattern(baseY)
    local zones = Platform.selectMultipleZones(6)
    Platform.addPlatform(zones[1], baseY + 30, Platform.types.OBSTACLE)
    Platform.addPlatform(zones[6], baseY + 30, Platform.types.OBSTACLE)
    Platform.addPlatform(zones[2], baseY, Platform.types.SAFE)
    Platform.addPlatform(zones[2], baseY - 50, Platform.types.ITEM)
    Platform.addPlatform(zones[5], baseY, Platform.types.SAFE)
    Platform.addPlatform(zones[5], baseY - 50, Platform.types.ITEM)
    Platform.addPlatform(zones[3] + 25, baseY - 25, Platform.types.NORMAL)
end

function Platform.generateDashChallengePattern(baseY)
    local zones = Platform.selectMultipleZones(5)
    Platform.addPlatform(zones[1], baseY, Platform.types.SAFE)
    Platform.addPlatform(zones[4], baseY, Platform.types.ITEM)
    Platform.addPlatform(Platform.minX, baseY + 25, Platform.types.OBSTACLE)
    Platform.addPlatform(Platform.maxX, baseY + 25, Platform.types.OBSTACLE)
    Platform.addPlatform(zones[3], baseY + 40, Platform.types.NORMAL)
end

function Platform.generateComboPattern(baseY)
    local zones = Platform.selectMultipleZones(7)
    Platform.addPlatform(zones[1], baseY, Platform.types.OBSTACLE)
    Platform.addPlatform(zones[7], baseY, Platform.types.OBSTACLE)
    Platform.addPlatform(zones[2], baseY - 20, Platform.types.SAFE)
    Platform.addPlatform(zones[4], baseY + 15, Platform.types.ITEM)
    Platform.addPlatform(zones[6], baseY - 35, Platform.types.ITEM)
    Platform.addPlatform(zones[5], baseY - 50, Platform.types.RISKY)
    
    for i = 3, 5 do
        Platform.addPlatform(zones[i], baseY + 35, Platform.types.OBSTACLE)
    end
end

function Platform.draw()
    for _, platform in ipairs(Platform.platforms) do
        love.graphics.draw(Platform.sprite, platform.x, platform.y)
        
        -- Debug visual
        love.graphics.setColor(1, 1, 1, 0.8)
        if platform.type == Platform.types.ITEM then
            love.graphics.setColor(0, 1, 0, 0.8)
        elseif platform.type == Platform.types.OBSTACLE then
            love.graphics.setColor(1, 0, 0, 0.8)
        elseif platform.type == Platform.types.SAFE then
            love.graphics.setColor(0, 0, 1, 0.8)
        elseif platform.type == Platform.types.RISKY then
            love.graphics.setColor(1, 1, 0, 0.8)
        -- Removido debug visual para EMERGENCY - agora são NORMAL
        end
        
        love.graphics.rectangle("line", platform.x, platform.y, platform.width, platform.height)
        love.graphics.setColor(1, 1, 1)
    end
end

function Platform.getCount()
    return #Platform.platforms
end

function Platform.getPlatformsByType(platformType)
    local filtered = {}
    for _, platform in ipairs(Platform.platforms) do
        if platform.type == platformType then
            table.insert(filtered, platform)
        end
    end
    return filtered
end

function Platform.isInDashGap(x, y)
    for _, platform in ipairs(Platform.platforms) do
        local distance = math.abs(x - platform.x)
        if distance > Platform.minGapX and distance <= Platform.dashDistance then
            return true
        end
    end
    return false
end

function Platform.onPlayerCollision(playerY)
    Platform.lastPlayerCollisionY = playerY
end

function Platform.isPlayerInDangerousGap(playerX, playerY)
    local fallDistance = playerY - Platform.lastPlayerCollisionY
    return fallDistance > Platform.maxFallWithoutPlatform * 0.6 -- Alerta mais cedo
end

function Platform.debugZones()
    love.graphics.setColor(1, 1, 1, 0.3)
    for i, zone in ipairs(Platform.zones) do
        love.graphics.line(zone, 0, zone, love.graphics.getHeight())
        love.graphics.print("Z" .. i, zone, 10)
    end
    love.graphics.setColor(1, 1, 1)
end

return Platform