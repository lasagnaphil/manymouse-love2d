local ffi = require("ffi")
local bit = require("bit")
require("struct")

local printf = function(s,...) return io.write(s:format(...)) end

ffi.cdef [[
typedef enum
{
    MANYMOUSE_EVENT_ABSMOTION = 0,
    MANYMOUSE_EVENT_RELMOTION,
    MANYMOUSE_EVENT_BUTTON,
    MANYMOUSE_EVENT_SCROLL,
    MANYMOUSE_EVENT_DISCONNECT,
    MANYMOUSE_EVENT_MAX
} ManyMouseEventType;

typedef struct
{
    ManyMouseEventType type;
    unsigned int device;
    unsigned int item;
    int value;
    int minval;
    int maxval;
} ManyMouseEvent;

int ManyMouse_Init(void);
const char *ManyMouse_DriverName(void);
void ManyMouse_Quit(void);
const char *ManyMouse_DeviceName(unsigned int index);
int ManyMouse_PollEvent(ManyMouseEvent *event);
]]

local mmlib = ffi.load("./libmanymouse.so")

ManyMouse = {}

ManyMouse.Event = {
    ABSMOTION = 0,
    RELMOTION = 1,
    BUTTON = 2,
    SCROLL = 3,
    DISCONNECT = 4,
    MAX = 5
}


function ManyMouse.init()
    return mmlib.ManyMouse_Init()
end

function ManyMouse.driverName()
    local res = mmlib.ManyMouse_DriverName()
    print(res)
    return ffi.string(res)
end

function ManyMouse.quit()
    return mmlib.ManyMouse_Quit()
end

function ManyMouse.deviceName(idx)
    local res = mmlib.ManyMouse_DeviceName(idx - 1)
    return ffi.string(res)
end

function ManyMouse.pollEvent()
    local cevent = ffi.new("ManyMouseEvent[1]")
    local res = mmlib.ManyMouse_PollEvent(cevent)
    if res == 0 then 
        return nil 
    else
        return cevent[0]
    end
end

-- CLI Mouse test
-- Call this function to test functionality via the terminal.

function testCLI()
    local event
    local availableMice = ManyMouse.init()

    if availableMice < 0 then
        print("Error intiailizing ManyMouse!")
        ManyMouse.quit()
        return 2
    end

    print("ManyMouse driver: " .. ManyMouse.driverName())

    if availableMice == 0 then
        print("No mice detected!")
        ManyMouse.quit()
        return 1
    end

    for i = 1,availableMice do
        print("#" .. i .. ": " .. ManyMouse.deviceName(i))
    end
    print("")

    print("Use your mice, CTRL-C to exit.")

    while true do
        event = ManyMouse.pollEvent()
        if event and event.device ~= 0 then
            if event.type == ManyMouse.Event.RELMOTION then
                printf("Mouse #%d relative motion %s %d\n", event.device, (event.item == 0 and "X" or "Y"), event.value)
            elseif event.type == ManyMouse.Event.ABSMOTION then
                printf("Mouse #%d absolute motion %s %d\n", event.device, (event.item == 0 and "X" or "Y"), event.value)
            elseif event.type == ManyMouse.Event.BUTTON then
                printf("Mouse #%d button %d %s\n", event.device, event.item, (event.value and "down" or "up"))
            elseif event.type == ManyMouse.Event.SCROLL then
                local wheel, direction
                if event.item == 0 then 
                    wheel = "vertical" 
                    direction = (event.value > 0) and "up" or "down"
                else 
                    wheel = "horizontal" 
                    direction = (event.value > 0) and "right" or "left"
                end
                printf("Mouse $%d wheel %s %s\n", event.device, wheel, direction)
            elseif event.type == ManyMouse.Event.DISCONNECT then
                printf("Mouse #%d disconnect\n", event,device)
            else
                printf("Mouse #%d unhandled event type %d\n", event.device, event.type)
            end
            event = ManyMouse.pollEvent()
        end
    end

    ManyMouse.quit()
    return 0
end


-- Mouse Manager
-- A wrapper around manymouse library to make it easier to use.

struct.Mouse {
    connected = false,
    x = 0,
    y = 0,
    name = "",
    buttons = 0,
    scrollUpTick = 0,
    scrollDownTick = 0,
    scrollLeftTick = 0,
    scrollRightTick = 0,
}

struct.MouseEvent {
    type = 0,
    device = 0,
    item = 0,
    value = 0,
    minval = 0,
    maxval = 0,
}

-- enum for Event::item
ManyMouse.Button = {
    LEFT = 0,
    RIGHT = 1,
}

-- enum for Event::value
ManyMouse.Value = {
    X = 0,
    Y = 1,
    RELEASED = 0,
    PRESSED = 1,
}

local MouseManager = {
    MAX_MICE = 32,
    availableMice = 0,
    tickListener = function() return 0 end,
    eventListeners = {},
    mice = {},
    screenWidth = 640,
    screenHeight = 480
}

function ManyMouse.createMouseManager(screenWidth, screenHeight)
    MouseManager:init(screenWidth, screenHeight)
    return MouseManager
end

function MouseManager:setTickListener(fun)
    self.tickListener = fun
end

function MouseManager:addEventListener(fun)
    self.eventListeners[#self.eventListeners + 1] = fun
end

function MouseManager:_callEventListeners(ev)
    --[[
    local event = MouseEvent {
        type = ev.type,
        device = ev.device,
        item = ev.item,
        value = ev.value,
        minval = ev.minval,
        maxval = ev.maxval
    }
    for _, f in ipairs(self.eventListeners) do
        f(event)
    end
    ]]--
    for _, f in ipairs(self.eventListeners) do
        f(ev)
    end
end

function MouseManager:init(screenWidth, screenHeight)
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    for i=1,32 do
        self.mice[i] = Mouse {
            x = screenWidth/2,
            y = screenHeight/2
        }
    end

    self.availableMice = ManyMouse.init()
    if self.availableMice < 0 then
        print("Error initializing ManyMouse!\n")
        return
    end

    printf("ManyMouse driver: %s\n", ManyMouse.driverName())

    if self.availableMice == 0 then
        print("No mice detected!\n")
        return
    end

    if self.availableMice > MouseManager.MAX_MICE then
        print("Clamping to first " .. self.availableMice .. " mice.\n")
        self.availableMice = MAX_MICE
    end

    for i=1, self.availableMice do
        self.mice[i].name = ManyMouse.deviceName(i)
    end

    for i=1, self.availableMice do
        print("#" .. i .. ": " .. self.mice[i].name .. "\n")
    end

end

function MouseManager:updateWindowSize(screenWidth, screenHeight)
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
end

function MouseManager:getMouse(idx)
    if idx > self.availableMice then
        error("Mouse index is greater than number of available mice", 2)
    elseif idx < 1 then
        error("Mouse index is smaller than 1", 2)
    end

    return self.mice[idx]
end

function MouseManager:updateMice(screenWidth, screenHeight)
    while true do
        local event = ManyMouse.pollEvent()
        if event == nil then break end
        if event.device < self.availableMice then
            local mouse = self.mice[event.device + 1]
            self:_callEventListeners(event)
            if event.type == ManyMouse.Event.RELMOTION then
                if event.item == ManyMouse.Value.X then
                    mouse.x = mouse.x + event.value
                elseif event.item == ManyMouse.Value.Y then
                    mouse.y = mouse.y + event.value
                end
            elseif event.type == ManyMouse.Event.ABSMOTION then
                local val = event.value - event.minval
                local maxval = event.maxval - event.minval
                if event.item == ManyMouse.Value.X then
                    mouse.x = (val / maxval) * self.screenWidth
                elseif event.item == ManyMouse.Value.Y then
                    mouse.y = (val / maxval) * self.screenHeight
                end
            elseif event.type == ManyMouse.Event.BUTTON then
                if event.item < 32 then
                    if event.value then
                        mouse.buttons = bit.bor(mouse.buttons, bit.lshift(event.item, 1))
                    else
                        mouse.buttons = bit.band(mouse.buttons, bit.bnot(bit.lshift(event.item, 1)))
                    end
                end
            elseif event.type == ManyMouse.Event.SCROLL then
                if event.item == 0 then
                    if event.value < 0 then
                        mouse.scrollDownTick = self.tickListener()
                    else
                        mouse.scrollUpTick = self.tickListener()
                    end
                elseif event.item == 1 then
                    if event.value < 0 then
                        mouse.scrollLeftTick = self.tickListener()
                    else
                        mouse.scrollRightTick = self.tickListener()
                    end
                end
            elseif event.type == ManyMouse.Event.DISCONNECT then
                mouse.connected = false
            end
        end
    end
end

return ManyMouse
