-- Deepslate - Dwarf Fortress Lie Game
-- Main entry point

-- Load dependencies
require("constants")
local WorldGenerator = require("world.generator")
local Dwarf = require("entities.dwarf")

-- Global game state
local Game = {
    running = true,
    paused = false,
    tick = 0,
    tickTimer = 0,
    time = 0, -- In-game time in ticks
    
    -- World
    world = nil,
    generator = nil,
    
    -- Entities
    dwarves = {},
    creatures = {},
    items = {},
    
    -- Camera
    camera = {
        x = 0,
        y = 0,
        z = 1, -- Z-level
        zoom = 1,
        targetZoom = 1
    },
    
    -- Selection
    selectedTile = nil,
    selectedEntity = nil,
    
    -- UI
    showUI = true,
    currentMenu = nil,
    
    -- Pathfinding cache
    pathCache = {},
    
    -- Events
    events = {}
}

-- Initialize game
function Game:init()
    print("Initializing Deepslate...")
    
    -- Generate world
    self.generator = WorldGenerator:new(os.time())
    self.world = self.generator:generateWorld(WORLD_WIDTH, WORLD_HEIGHT, WORLD_DEPTH)
    
    -- Find spawn location
    local spawnX, spawnY, spawnZ = self:findSpawnLocation()
    
    -- Create initial dwarves
    for i = 1, 7 do
        local dwarf = Dwarf:new(nil, spawnX + i, spawnY, spawnZ)
        table.insert(self.dwarves, dwarf)
    end
    
    -- Initialize camera
    self.camera.x = (spawnX - WORLD_WIDTH / 2) * TILE_SIZE
    self.camera.y = (spawnY - WORLD_HEIGHT / 2) * TILE_SIZE
    self.camera.z = spawnZ
    
    print("World generated with seed: " .. self.generator.seed)
    print("Dwarves created: " .. #self.dwarves)
    print("Initialization complete!")
end

function Game:findSpawnLocation()
    local depth = WORLD_DEPTH - 1
    
    -- Find a suitable spawn point
    for z = 2, depth - 2 do
        for x = 10, WORLD_WIDTH - 10 do
            for y = 10, WORLD_HEIGHT - 10 do
                if self.world.tiles[z][x][y] == TILE.AIR and 
                   self.world.tiles[z-1][x][y] ~= TILE.AIR then
                    return x, y, z
                end
            end
        end
    end
    
    -- Fallback
    return math.floor(WORLD_WIDTH / 2), math.floor(WORLD_HEIGHT / 2), 3
end

-- Main update loop
function Game:update(dt)
    if self.paused then return end
    
    -- Update time
    self.time = self.time + dt * 60 -- 60 ticks per second
    
    -- Tick system
    self.tickTimer = self.tickTimer + dt
    if self.tickTimer >= TICK_TIME then
        self.tickTimer = self.tickTimer - TICK_TIME
        self.tick = self.tick + 1
        self:tick()
    end
    
    -- Smooth camera zoom
    self.camera.zoom = self.camera.zoom + (self.camera.targetZoom - self.camera.zoom) * 0.1
    
    -- Update entities
    self:updateEntities(dt)
    
    -- Update fluids
    self:updateFluids(dt)
end

-- Tick update (runs at TICK_RATE)
function Game:tick()
    -- Update dwarves
    for _, dwarf in ipairs(self.dwarves) do
        if dwarf.state ~= "DEAD" then
            dwarf:update(TICK_TIME, self)
        end
    end
    
    -- Spawn jobs if needed
    self:manageJobs()
end

function Game:updateEntities(dt)
    for _, dwarf in ipairs(self.dwarves) do
        if dwarf.state ~= "DEAD" then
            dwarf:update(dt, self)
        end
    end
end

function Game:updateFluids(dt)
    -- Simplified fluid simulation
    local world = self.world
    local depth = world.depth
    
    for z = 0, depth - 1 do
        for x = 2, world.width - 1 do
            for y = 2, world.height - 1 do
                local fluid = world.fluids[z][x][y]
                
                if fluid > 0 then
                    -- Flow to lower positions
                    local flowAmount = fluid * 0.3 * FLUID.WATER.viscosity
                    
                    -- Check down
                    if z > 0 and world.tiles[z-1][x][y] == TILE.AIR then
                        if world.fluids[z-1][x][y] < 10 then
                            world.fluids[z-1][x][y] = world.fluids[z-1][x][y] + flowAmount
                            world.fluids[z][x][y] = world.fluids[z][x][y] - flowAmount * 0.5
                        end
                    end
                    
                    -- Flow sideways (goo-like behavior)
                    if flowAmount > 0.1 then
                        local dirs = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}
                        for _, dir in ipairs(dirs) do
                            local nx, ny = x + dir[1], y + dir[2]
                            if nx > 1 and nx < world.width and ny > 1 and ny < world.height then
                                if world.tiles[z][nx][ny] == TILE.AIR and 
                                   world.fluids[z][nx][y] < 10 then
                                    world.fluids[z][nx][ny] = world.fluids[z][nx][ny] + flowAmount * 0.3
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function Game:manageJobs()
    -- Auto-generate jobs if none exist
    local jobCount = 0
    for _, dwarf in ipairs(self.dwarves) do
        if dwarf.job then jobCount = jobCount + 1 end
    end
    
    if jobCount < #self.dwarves * 0.5 then
        -- Generate some mining jobs
        self:generateMiningJobs(2)
    end
end

function Game:generateMiningJobs(count)
    local jobsGenerated = 0
    
    for x = 5, WORLD_WIDTH - 5 do
        for y = 5, WORLD_HEIGHT - 5 do
            for z = 2, WORLD_DEPTH - 2 do
                if jobsGenerated >= count then return end
                
                local tile = self.world.tiles[z][x][y]
                if tile == TILE.STONE or tile == TILE.COAL or tile == TILE.ORE then
                    -- Check if adjacent to air (minable)
                    local canMine = false
                    local dirs = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}
                    for _, dir in ipairs(dirs) do
                        local nx, ny = x + dir[1], y + dir[2]
                        if self.world.tiles[z][nx][ny] == TILE.AIR then
                            canMine = true
                            break
                        end
                    end
                    
                    if canMine then
                        local job = {
                            id = self.tick .. "_" .. x .. "_" .. y .. "_" .. z,
                            type = "MINE",
                            x = x,
                            y = y,
                            z = z,
                            skill = "mining",
                            duration = 10,
                            priority = PRIORITY.MEDIUM
                        }
                        self:addJob(job)
                        jobsGenerated = jobsGenerated + 1
                        return
                    end
                end
            end
        end
    end
end

function Game:addJob(job)
    self.jobs = self.jobs or {}
    table.insert(self.jobs, job)
end

function Game:getJobs()
    return self.jobs or {}
end

function Game:completeJob(job, dwarf)
    -- Remove job
    for i, j in ipairs(self.jobs or {}) do
        if j.id == job.id then
            table.remove(self.jobs, i)
            break
        end
    end
    
    -- Apply job effect
    if job.type == "MINE" then
        self.world.tiles[job.z][job.x][job.y] = TILE.AIR
    end
end

-- World query methods
function Game:findItemsInRange(x, y, z, range, itemType)
    local items = {}
    for _, item in ipairs(self.items) do
        local dist = math.abs(item.x - x) + math.abs(item.y - y) + math.abs(item.z - z)
        if dist <= range then
            if not itemType or item.type == itemType then
                table.insert(items, item)
            end
        end
    end
    return items
end

function Game:findBuildingInRange(x, y, z, range, buildingType)
    -- Simplified - would search through buildings
    return nil
end

function Game:findFluidInRange(x, y, z, range, fluidType)
    for dz = -range, range do
        for dx = -range, range do
            for dy = -range, range do
                local nx, ny, nz = x + dx, y + dy, z + dz
                if nz >= 0 and nz < self.world.depth and 
                   nx > 0 and nx <= self.world.width and 
                   ny > 0 and ny <= self.world.height then
                    if self.world.fluids[nz][nx][ny] > 0 then
                        return {x = nx, y = ny, z = nz}
                    end
                end
            end
        end
    end
    return nil
end

-- Rendering
function Game:render()
    -- Clear screen
    love.graphics.setBackgroundColor(10, 8, 6)
    
    -- Apply camera transform
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    love.graphics.scale(self.camera.zoom)
    love.graphics.translate(-self.camera.x, -self.camera.y)
    
    -- Render world
    self:renderWorld()
    
    -- Render entities
    self:renderEntities()
    
    -- Render selection
    self:renderSelection()
    
    love.graphics.pop()
    
    -- Render UI
    if self.showUI then
        self:renderUI()
    end
end

function Game:renderWorld()
    local camX = math.floor(self.camera.x / TILE_SIZE)
    local camY = math.floor(self.camera.y / TILE_SIZE)
    local viewW = math.ceil(love.graphics.getWidth() / TILE_SIZE / self.camera.zoom) + 2
    local viewH = math.ceil(love.graphics.getHeight() / TILE_SIZE / self.camera.zoom) + 2
    
    local startX = math.max(1, camX - viewW)
    local endX = math.min(WORLD_WIDTH, camX + viewW)
    local startY = math.max(1, camY - viewH)
    local endY = math.min(WORLD_HEIGHT, camY + viewH)
    
    local currentZ = self.camera.z
    
    for x = startX, endX do
        for y = startY, endY do
            local tile = self.world.tiles[currentZ][x][y]
            local fluid = self.world.fluids[currentZ][x][y]
            
            local drawX = x * TILE_SIZE
            local drawY = y * TILE_SIZE
            
            -- Render tile
            if tile ~= TILE.AIR then
                local color = COLORS.STONE
                if tile == TILE.GRASS then color = COLORS.GRASS
                elseif tile == TILE.SOIL then color = COLORS.SOIL
                elseif tile == TILE.STONE then color = COLORS.STONE
                elseif tile == TILE.DEEP_STONE then color = COLORS.DEEP_STONE
                elseif tile == TILE.MAGMA then color = COLORS.MAGMA
                elseif tile == TILE.COAL then color = COLORS.COAL
                elseif tile == TILE.ORE then color = COLORS.IRON
                elseif tile == TILE.GEMS then color = COLORS.GEMS
                elseif tile == TILE.SAND then color = COLORS.SAND
                end
                
                love.graphics.setColor(color[1] / 255, color[2] / 255, color[3] / 255, (color[4] or 255) / 255)
                love.graphics.rectangle("fill", drawX, drawY, TILE_SIZE, TILE_SIZE)
                
                -- Add some detail
                love.graphics.setColor(0, 0, 0, 30)
                love.graphics.rectangle("line", drawX, drawY, TILE_SIZE, TILE_SIZE)
            end
            
            -- Render fluid
            if fluid > 0 then
                local alpha = math.min(fluid / 5, 1) * 0.7
                love.graphics.setColor(30/255, 144/255, 255/255, alpha)
                love.graphics.rectangle("fill", drawX, drawY, TILE_SIZE, TILE_SIZE)
            end
        end
    end
end

function Game:renderEntities()
    local currentZ = self.camera.z
    
    for _, dwarf in ipairs(self.dwarves) do
        if math.floor(dwarf.z + 0.5) == currentZ then
            local color = dwarf:getDisplayColor()
            love.graphics.setColor(color[1], color[2], color[3], 1)
            
            local drawX = dwarf.x * TILE_SIZE
            local drawY = dwarf.y * TILE_SIZE
            
            -- Draw dwarf as a circle
            love.graphics.circle("fill", drawX + TILE_SIZE/2, drawY + TILE_SIZE/2, TILE_SIZE/2 - 1)
            
            -- Draw selection highlight
            if self.selectedEntity == dwarf then
                love.graphics.setColor(1, 1, 0, 0.5)
                love.graphics.rectangle("line", drawX - 2, drawY - 2, TILE_SIZE + 4, TILE_SIZE + 4)
            end
        end
    end
end

function Game:renderSelection()
    if self.selectedTile then
        local x, y, z = self.selectedTile.x, self.selectedTile.y, self.selectedTile.z
        local drawX = x * TILE_SIZE
        local drawY = y * TILE_SIZE
        
        love.graphics.setColor(1, 1, 0, 0.3)
        love.graphics.rectangle("fill", drawX, drawY, TILE_SIZE, TILE_SIZE)
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.rectangle("line", drawX, drawY, TILE_SIZE, TILE_SIZE)
    end
end

function Game:renderUI()
    -- Render HUD
    love.graphics.setColor(UI.BACKGROUND[1] / 255, UI.BACKGROUND[2] / 255, UI.BACKGROUND[3] / 255, UI.BACKGROUND[4] / 255)
    love.graphics.rectangle("fill", 10, 10, 250, 180)
    
    love.graphics.setColor(UI.BORDER[1] / 255, UI.BORDER[2] / 255, UI.BORDER[3] / 255, UI.BORDER[4] / 255)
    love.graphics.rectangle("line", 10, 10, 250, 180)
    
    -- Title
    love.graphics.setColor(UI.TEXT[1] / 255, UI.TEXT[2] / 255, UI.TEXT[3] / 255, UI.TEXT[4] / 255)
    love.graphics.setNewFont(14)
    love.graphics.print("DEEPSLATE", 20, 20)
    
    -- Game stats
    love.graphics.setNewFont(10)
    love.graphics.print("Time: " .. self.time, 20, 45)
    love.graphics.print("Tick: " .. self.tick, 20, 60)
    love.graphics.print("Dwarves: " .. #self.dwarves, 20, 75)
    love.graphics.print("Z-Level: " .. self.camera.z, 20, 90)
    
    -- Selected entity info
    if self.selectedEntity then
        love.graphics.print("Selected: " .. self.selectedEntity.name, 20, 110)
        love.graphics.print("State: " .. self.selectedEntity.state, 20, 125)
        
        -- Show needs
        local needsY = 140
        for need, value in pairs(self.selectedEntity.needs) do
            love.graphics.print(need .. ": " .. string.format("%.1f", value * 100) .. "%", 20, needsY)
            needsY = needsY + 12
        end
    end
    
    -- Controls help
    love.graphics.setColor(UI.TEXT_DIM[1] / 255, UI.TEXT_DIM[2] / 255, UI.TEXT_DIM[3] / 255, UI.TEXT_DIM[4] / 255)
    love.graphics.print("WASD/Arrows: Pan camera", 20, love.graphics.getHeight() - 60)
    love.graphics.print("Q/E: Zoom in/out", 20, love.graphics.getHeight() - 45)
    love.graphics.print("Z/X: Change Z-level", 20, love.graphics.getHeight() - 30)
    love.graphics.print("Space: Pause", 20, love.graphics.getHeight() - 15)
end

-- Input handling
function Game:handleInput()
    local panSpeed = CAMERA.PAN_SPEED / self.camera.zoom
    
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        self.camera.y = self.camera.y - panSpeed * 0.016
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        self.camera.y = self.camera.y + panSpeed * 0.016
    end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        self.camera.x = self.camera.x - panSpeed * 0.016
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        self.camera.x = self.camera.x + panSpeed * 0.016
    end
    
    -- Zoom
    if love.keyboard.isDown("q") then
        self.camera.targetZoom = math.max(CAMERA.MIN_ZOOM, self.camera.targetZoom - CAMERA.ZOOM_SPEED * 0.016)
    end
    if love.keyboard.isDown("e") then
        self.camera.targetZoom = math.min(CAMERA.MAX_ZOOM, self.camera.targetZoom + CAMERA.ZOOM_SPEED * 0.016)
    end
    
    -- Z-level change
    if love.keyboard.isJustPressed("z") then
        self.camera.z = math.max(0, self.camera.z - 1)
    end
    if love.keyboard.isJustPressed("x") then
        self.camera.z = math.min(WORLD_DEPTH - 1, self.camera.z + 1)
    end
end

-- Mouse handling
function Game:mouseToWorld(mx, my)
    local wx = (mx - love.graphics.getWidth() / 2) / self.camera.zoom + self.camera.x
    local wy = (my - love.graphics.getHeight() / 2) / self.camera.zoom + self.camera.y
    
    local tileX = math.floor(wx / TILE_SIZE + 0.5)
    local tileY = math.floor(wy / TILE_SIZE + 0.5)
    
    return tileX, tileY, self.camera.z
end

function Game:mousepressed(mx, my, button)
    local tileX, tileY, tileZ = self:mouseToWorld(mx, my)
    
    if tileX >= 1 and tileX <= WORLD_WIDTH and 
       tileY >= 1 and tileY <= WORLD_HEIGHT then
        self.selectedTile = {x = tileX, y = tileY, z = tileZ}
        
        -- Check for entity selection
        self.selectedEntity = nil
        for _, dwarf in ipairs(self.dwarves) do
            local dwarfTileX = math.floor(dwarf.x + 0.5)
            local dwarfTileY = math.floor(dwarf.y + 0.5)
            local dwarfTileZ = math.floor(dwarf.z + 0.5)
            
            if dwarfTileX == tileX and dwarfTileY == tileY and dwarfTileZ == tileZ then
                self.selectedEntity = dwarf
                break
            end
        end
    end
end

function Game:keypressed(key)
    if key == "space" then
        self.paused = not self.paused
    end
    if key == "escape" then
        self.running = false
    end
    if key == "f" then
        self.showUI = not self.showUI
    end
end

-- Love2D callbacks
function love.load()
    Game:init()
end

function love.update(dt)
    if Game.running then
        Game:handleInput()
        Game:update(dt)
    end
end

function love.draw()
    if Game.running then
        Game:render()
    end
end

function love.mousepressed(x, y, button)
    Game:mousepressed(x, y, button)
end

function love.keypressed(key)
    Game:keypressed(key)
end

function love.quit()
    print("Thanks for playing Deepslate!")
end