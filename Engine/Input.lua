local Input = {}

Input.dx, Input.dy = 0, 0
Input.joy = nil
Input.DEADZONE = 0.2

function Input.load()
    local joysticks = love.joystick.getJoysticks()
    Input.joy = joysticks[1]
end

function Input.update(dt)
    local dx, dy = 0, 0

    -- Teclado
    if love.keyboard.isDown("left")  then dx = dx - 1 end
    if love.keyboard.isDown("right") then dx = dx + 1 end
    if love.keyboard.isDown("up")    then dy = dy - 1 end
    if love.keyboard.isDown("down")  then dy = dy + 1 end

    -- Gamepad (analógico + dpad)
    if Input.joy then
        local ax = Input.joy:getGamepadAxis("leftx") or 0
        local ay = Input.joy:getGamepadAxis("lefty") or 0
        if math.abs(ax) > Input.DEADZONE then dx = dx + ax end
        if math.abs(ay) > Input.DEADZONE then dy = dy + ay end

        if Input.joy:isGamepadDown("dpleft")  then dx = dx - 1 end
        if Input.joy:isGamepadDown("dpright") then dx = dx + 1 end
        if Input.joy:isGamepadDown("dpup")    then dy = dy - 1 end
        if Input.joy:isGamepadDown("dpdown")  then dy = dy + 1 end
    end

    Input.dx, Input.dy = dx, dy
end

-- IMPORTANTE: expor isDown FORA do update
function Input.isDown(key)
    return love.keyboard.isDown(key)
end

return Input
