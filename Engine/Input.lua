local input = {}

input.dx = 0
input.dy = 0
input.speed = 200
input.joy = nil

function input.load()
    local joysticks = love.joystick.getJoysticks()
    input.joy = joysticks[1]

    -- Movimento por teclado (setas)
    function input.isDown(button)
        return love.keyboard.isDown(button)
    end
    
end

function input.update(dt)
    local dx, dy = 0, 0

    

    -- Movimento por analógico esquerdo
    if input.joy then
        local axisX = input.joy:getGamepadAxis("leftx")
        local axisY = input.joy:getGamepadAxis("lefty")

        -- Deadzone
        if math.abs(axisX) > 0.2 then dx = dx + axisX end
        if math.abs(axisY) > 0.2 then dy = dy + axisY end
    end

    input.dx = dx
    input.dy = dy
end

return input