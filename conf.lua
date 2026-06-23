function love.conf(t)
    t.window.title = "BINGO"
    t.window.icon = "BINGO.png"
    t.window.vsync = 1
    t.window.height = 800
    t.window.width = 1200
    t.window.fullscreen=false
    t.window.borderless=true

    t.modules.data = false
    t.modules.system = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.thread = false
    t.modules.touch = false
    t.modules.video = false
end