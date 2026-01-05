-- something idk

-- Variables ( Assetto specific)
local sim = ac.getSim()
local appWindow = ac.accessAppWindow("IMGUI_LUA_RexDino App_test")
local fpsWindow = ac.accessAppWindow("IMGUI_LUA_RexDino App_test_fps")

-- window start sizes


-- Local variables
local timer = 0
local lowfps = 10001

-- Tables

local fps = {
    frametime           = 0,
    framerate           = 0,
    roundFPS            = 0,
    roundFPSdecimals    = 0,
    lowestFPS           = 10000,
    lowestFPSround      = 10000,
    lowestFPSdecimals   = 0,
    infoCount           = 0,
    winX                = 225,
    winY                = 50,
    winXtoY             = 0,
    winXtoY2            = 0,
}

local rectLerp = {
    mousePos    = vec2(0, 0),
    windowPos   = vec2(0, 0),
    winMouse    = vec2(0, 0),
    current     = vec2(100, 100),
    target      = vec2(100, 100),
    speed       = 5,
}

local infoStats = {
    roundFPS = 0,
    lowestFPSround = 0,
}

-- Debug
--[[
ac.debug("apps: ", ac.getAppWindows())
ac.debug("fps: ", tostring(fps.roundFPS))
ac.debug("low fps: ", tostring(fps.lowestFPSround))
]]--




-- Arrays
local activeStats = { true, true}

-- Fps window settings
for i = 1, #activeStats do
    if activeStats[i] then
        fps.infoCount = fps.infoCount + 1
    end
    if i == 1 and activeStats[i-1] then
        table.remove(infoStats, i-1)
    elseif i == 2 and activeStats[i-1] then
        table.remove(infoStats, i-1)
    end
end

fps.winXtoY2 = fps.winX / fps.winY
fps.winY = fps.winY * fps.infoCount
fps.winXtoY = fps.winXtoY2 / fps.infoCount
fps.winX = fps.winY * fps.winXtoY
fpsWindow:resize(vec2(fps.winX, fps.winY)):move(vec2(0, 250))

-- Within vec2 range
---@param pos vec2
---@param range1 vec2
---@param range2 vec2
local function vec2Range(pos, range1, range2)
    if pos.x > range1.x and pos.x < range2.x and
       pos.y > range1.y and pos.y < range2.y
    then
        return true
    end
    return false
end



-- Updates per frame
function script.update(dt)
    fps.framerate = sim.fps

    fps.roundFPS = math.round(fps.framerate, fps.roundFPSdecimals)
    fps.lowestFPSround = math.round(fps.lowestFPS, fps.roundFPSdecimals)
 
    --[[ Updating debug
    ac.debug("fps: ", tostring(fps.roundFPS))
    local lowDebug = (fps.lowestFPSround < 10000) and fps.lowestFPSround or fps.roundFPS
    ac.debug("low fps: ", tostring(lowDebug))
    ]]--

    if not fpsWindow:visible() then fps.lowestFPS = 10001 end

    timer = timer + dt
    if timer > 1 then
        if fps.lowestFPS > fps.framerate and fps.framerate >= 1 then
            fps.lowestFPS = fps.framerate
        end
    end
    
    -- Updating table
    infoStats.roundFPS = fps.roundFPS
    infoStats.lowestFPSround = fps.lowestFPSround

    fps.frametime = fps.frametime + 1
end




-- Fps window
function script.windowFPS(dt)
    ui.drawRectFilled(vec2(0, 0), fpsWindow:size(), rgbm(0, 0, 0, 0.4), 5, 7)

    local textSize = ((fpsWindow:size().y / (20 * fps.infoCount)) * 13)
    ui.dwriteDrawText("FPS: "..infoStats.roundFPS, textSize, vec2(10, ((fpsWindow:size().y - ((fpsWindow:size().y / (20 * fps.infoCount)) * 13))/35)), rgbm(1, 1, 1, 1))

    local lowDisplay = (infoStats.lowestFPSround < 10000) and infoStats.lowestFPSround or infoStats.roundFPS
    ui.dwriteDrawText("FPS Low: "..lowDisplay, textSize, vec2(10, ((fpsWindow:size().y - textSize)/35)+((fpsWindow:size().y / fps.infoCount))), rgbm(1, 1, 1, 1))

    -- Check for resize
    if fps.frametime % fps.roundFPS == 0 then
        if (fpsWindow:size().y * fps.winXtoY ) ~= fpsWindow:size().x and fpsWindow:size().x == fps.winX then
            fpsWindow:resize(vec2(fpsWindow:size().y * fps.winXtoY, fpsWindow:size().y))
        elseif fps.winX ~= fpsWindow:size().x then
            fpsWindow:resize(vec2(fpsWindow:size().x, fpsWindow:size().x / fps.winXtoY))
        end

        fps.winX = fpsWindow:size().x
        fps.winY = fpsWindow:size().y
    end
end




-- Main window
function script.windowMain(dt)
    rectLerp.mousePos = ui.mousePos()
    ui.dwriteDrawText(tostring(rectLerp.mousePos), 17, vec2(110, 50), rgbm(1, 1, 1, 1))
    rectLerp.windowPos = ui.windowPos() --appWindow:position()
    ui.dwriteDrawText(tostring(rectLerp.windowPos), 17, vec2(110, 30), rgbm(1, 1, 1, 1))
    rectLerp.winMouse = ui.mouseLocalPos()
    ui.dwriteDrawText(tostring(rectLerp.winMouse), 17, vec2(110, 70), rgbm(1, 1, 1, 1))


    local rectMin = vec2(0, 0)
    local rectMax = rectLerp.current

    if vec2Range(rectLerp.winMouse, rectMin, rectMax) and ui.mouseDown(0) then
        rectLerp.target = vec2(200, 100)
    else
        rectLerp.target = vec2(100, 100)
    end

    rectLerp.current.x = math.lerp(rectLerp.current.x, rectLerp.target.x, dt * rectLerp.speed)
    rectLerp.current.y = math.lerp(rectLerp.current.y, rectLerp.target.y, dt * rectLerp.speed)

    ui.drawRectFilled(rectMin, rectMax, rgbm(1, 0, 0, 1))

    if  fps.lowestFPSround < 10000 then
        -- lowfps = ui.dwriteDrawText(tostring(fps.lowestFPSround), 17, vec2(10, 50), rgbm(1, 1, 1, 1)) -- optimisation 
        if lowfps ~= fps.lowestFPSround then
            lowfps = ui.dwriteDrawText(""..fps.lowestFPSround, 17, vec2(10, 50), rgbm(1, 1, 1, 1))
        end
    end

    ui.dwriteDrawText("test", 17, vec2(10, 80), rgbm(1, 1, 1, 1))
    
end

-- 3D rendering
--[[
function script.Draw3D(dt)
    -- Draw something with the render. functions
end
]]--