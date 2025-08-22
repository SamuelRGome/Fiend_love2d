local Input = require("Engine.Input")
local Player = {}

function Player.load()
    Player.x = 250
    Player.y = 250

    Player.Sprite = love.graphics.newImage("Assets/PH_Fiend.png")
    Player.Width = Player.Sprite:getWidth()
    Player.Height = Player.Sprite:getHeight()

    world:addCollisionClass("Player")

    Player.collider = world:newRectangleCollider(
        Player.x + Player.Width/2,
        Player.y + Player.Height/2,
        Player.Width,
        Player.Height
    )
    Player.collider:setCollisionClass("Player")
    Player.collider:setType("dynamic")
    Player.collider:setFixedRotation(true)

    Player.onGround = false
end

-- Checa se o player está no chão
function Player.checkGround()
    local contacts = Player.collider:getContacts()
    for _, contact in ipairs(contacts) do
        local fixtureA, fixtureB = contact:getFixtures()
        local colliderA = fixtureA:getUserData()
        local colliderB = fixtureB:getUserData()

        if colliderA and colliderA.collision_class == "Platform" then
            return true
        elseif colliderB and colliderB.collision_class == "Platform" then
            return true
        end
    end
    return false
    
end

function Player.update(dt)
    -- Atualiza se está no chão
    Player.onGround = Player.checkGround()
    if Player.onGround == false then
        Player.collider:exit("Platform")
    end

    -- Movimento horizontal
    local dx = Input.dx * 200 * dt
    Player.collider:setX(Player.collider:getX() + dx)

    -- Atualiza posição do sprite
    Player.x = Player.collider:getX() - Player.Width/2
    Player.y = Player.collider:getY() - Player.Height/2

    -- Pulo
    if Input.isDown("up") and Player.onGround then
        Player.collider:applyLinearImpulse(0, -10)
    end
end

function Player.draw()
    love.graphics.draw(Player.Sprite, Player.x, Player.y)
end

return Player
