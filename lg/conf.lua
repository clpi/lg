-- Deepslate Configuration
function love.conf(t)
    t.title = "Deepslate"
    t.author = "Deepslate Team"
    t.version = "0.1.0"
    
    t.window.title = "Deepslate - Dwarf Fortress Lie"
    t.window.width = 1280
    t.window.height = 720
    t.window.vsync = true
    t.window.fullscreen = false
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    
    t.console = true
    t.identity = "deepslate"
    
    t.modules.audio = true
    t.modules.event = true
    t.modules.filesystem = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
    
    t.externalstorage = false
    t.gammacorrect = false
end