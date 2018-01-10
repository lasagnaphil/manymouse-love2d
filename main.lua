local ManyMouse = require("manymouse")
require("struct")

local printf = function(s,...) return io.write(s:format(...)) end

local tempDt = 0

local mouseMgr = ManyMouse.createMouseManager(love.graphics.getWidth(), love.graphics.getHeight())

mouseMgr:setTickListener(function() return tempDt end)
mouseMgr:addEventListener(function(ev) 
    if ev.type == ManyMouse.Event.RELMOTION then
        printf("Mouse %d moved!\n", ev.device)
    elseif ev.type == ManyMouse.Event.BUTTON then
        if ev.value == ManyMouse.Value.PRESSED then
            printf("Mouse %d pressed!\n", ev.device)
        elseif ev.value == ManyMouse.Value.RELEASED then
            printf("Mouse %d released!\n", ev.device)
        end
    end
end)

function love.init()
end

function love.update(dt)
    tempDt = dt
    mouseMgr:updateMice()
end

function love.draw()
    if mouseMgr.availableMice ~= 0 then
        for i=1, mouseMgr.availableMice do
            local mouse = mouseMgr:getMouse(i)
            love.graphics.circle("fill", mouse.x, mouse.y, 5)
        end
    end
end

function love.keypressed(k)
    if k == 'escape' then
        love.event.quit()
    end
end
