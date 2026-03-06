-- World Generator
-- Procedural world generation using Perlin noise and cellular automata

local Perlin = require("lib.perlin")

local WorldGenerator = {}
WorldGenerator.__index = WorldGenerator

-- Seed for random generation
local seed = os.time()

function WorldGenerator.new(seed_val)
    local self = setmetatable({}, WorldGenerator)
    self.seed = seed_val or seed
    self.perlin = Perlin:new(self.seed)
    return self
end

function WorldGenerator:noise2D(x, y, octaves, persistence, scale)
    octaves = octaves or 4
    persistence = persistence or 0.5
    scale = scale or 0.05
    
    local total = 0
    local frequency = scale
    local amplitude = 1
    local maxValue = 0
    
    for i = 1, octaves do
        total = total + self.perlin:get(x * frequency, y * frequency) * amplitude
        maxValue = maxValue + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * 2
    end
    
    return total / maxValue
end

function WorldGenerator:noise3D(x, y, z, octaves, persistence, scale)
    octaves = octaves or 4
    persistence = persistence or 0.5
    scale = scale or 0.05
    
    local total = 0
    local frequency = scale
    local amplitude = 1
    local maxValue = 0
    
    for i = 1, octaves do
        total = total + self.perlin:get(x * frequency, y * frequency, z * frequency) * amplitude
        maxValue = maxValue + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * 2
    end
    
    return total / maxValue
end

function WorldGenerator:generateWorld(width, height, depth)
    local world = {
        width = width,
        height = height,
        depth = depth,
        tiles = {},
        fluids = {},
        buildings = {},
        seeds = {},
        caves = {}
    }
    
    -- Initialize tile arrays
    for z = 0, depth - 1 do
        world.tiles[z] = {}
        world.fluids[z] = {}
        world.buildings[z] = {}
        
        for x = 1, width do
            world.tiles[z][x] = {}
            world.fluids[z][x] = {}
            world.buildings[z][x] = {}
            
            for y = 1, height do
                world.tiles[z][x][y] = TILE.AIR
                world.fluids[z][x][y] = 0
                world.buildings[z][x][y] = nil
            end
        end
    end
    
    -- Generate terrain layers
    self:generateTerrain(world)
    
    -- Generate caves
    self:generateCaves(world)
    
    -- Generate ores and resources
    self:generateResources(world)
    
    -- Generate water
    self:generateWater(world)
    
    return world
end

function WorldGenerator:generateTerrain(world)
    local width = world.width
    local height = world.height
    local depth = world.depth
    
    for x = 1, width do
        for y = 1, height do
            -- Surface height using noise
            local surfaceNoise = self:noise2D(x, y, 6, 0.5, 0.03)
            local surfaceHeight = math.floor((surfaceNoise + 1) * 0.5 * 8) + 3
            
            -- Generate layers from surface down
            for z = 0, depth - 1 do
                local tile = TILE.AIR
                
                if z < surfaceHeight - 2 then
                    -- Deep stone
                    local deepNoise = self:noise3D(x, y, z, 3, 0.5, 0.1)
                    if deepNoise > 0.3 then
                        tile = TILE.DEEP_STONE
                    else
                        tile = TILE.STONE
                    end
                elseif z < surfaceHeight then
                    -- Stone layer
                    tile = TILE.STONE
                elseif z == surfaceHeight then
                    -- Soil or surface
                    local soilNoise = self:noise2D(x, y, 2, 0.5, 0.1)
                    if soilNoise > 0.2 then
                        tile = TILE.SOIL
                    else
                        tile = TILE.GRASS
                    end
                else
                    -- Above surface - air
                    tile = TILE.AIR
                end
                
                -- Add sand near water level
                if z == SEA_LEVEL - 1 and tile == TILE.AIR then
                    local sandNoise = self:noise2D(x, y, 2, 0.5, 0.15)
                    if sandNoise > 0.3 then
                        tile = TILE.SAND
                    end
                end
                
                world.tiles[z][x][y] = tile
            end
        end
    end
end

function WorldGenerator:generateCaves(world)
    local width = world.width
    local height = world.height
    local depth = world.depth
    
    -- Use cellular automata for cave generation
    -- Start with random noise
    local caveMap = {}
    for z = 1, depth - 2 do
        caveMap[z] = {}
        for x = 1, width do
            caveMap[z][x] = {}
            for y = 1, height do
                local caveNoise = self:noise3D(x, y, z, 3, 0.5, 0.08)
                caveMap[z][x][y] = caveNoise > CAVE_THRESHOLD
            end
        end
    end
    
    -- Smooth with cellular automata
    for iteration = 1, 5 do
        caveMap = self:smoothCaves(caveMap, world)
    end
    
    -- Apply caves to world
    for z = 1, depth - 2 do
        for x = 1, width do
            for y = 1, height do
                if caveMap[z][x][y] then
                    -- Don't remove surface grass
                    if world.tiles[z][x][y] ~= TILE.GRASS then
                        world.tiles[z][x][y] = TILE.AIR
                    end
                end
            end
        end
    end
end

function WorldGenerator:smoothCaves(caveMap, world)
    local depth = world.depth
    local width = world.width
    local height = world.height
    
    local newMap = {}
    
    for z = 1, depth - 2 do
        newMap[z] = {}
        for x = 2, width - 1 do
            newMap[z][x] = {}
            for y = 2, height - 1 do
                local neighbors = 0
                
                -- Count neighbors in 3x3x3 area
                for dz = -1, 1 do
                    for dx = -1, 1 do
                        for dy = -1, 1 do
                            if dz ~= 0 or dx ~= 0 or dy ~= 0 then
                                local nz = z + dz
                                local nx = x + dx
                                local ny = y + dy
                                
                                if nz > 0 and nz < depth - 1 and 
                                   nx > 1 and nx < width and 
                                   ny > 1 and ny < height then
                                    if caveMap[nz][nx][ny] then
                                        neighbors = neighbors + 1
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- Apply cellular automata rules
                if caveMap[z][x][y] then
                    newMap[z][x][y] = neighbors >= 4
                else
                    newMap[z][x][y] = neighbors >= 5
                end
            end
        end
    end
    
    return newMap
end

function WorldGenerator:generateResources(world)
    local width = world.width
    local height = world.height
    local depth = world.depth
    
    -- Generate different ore types based on depth
    for x = 1, width do
        for y = 1, height do
            for z = 1, depth - 1 do
                if world.tiles[z][x][y] == TILE.STONE or 
                   world.tiles[z][x][y] == TILE.DEEP_STONE then
                    
                    local oreNoise = self:noise3D(x, y, z * 0.5, 4, 0.5, 0.12)
                    local depthFactor = z / depth
                    
                    -- Coal - common, shallow
                    if oreNoise > 0.5 and depthFactor < 0.6 then
                        world.tiles[z][x][y] = TILE.COAL
                    -- Iron - moderate depth
                    elseif oreNoise > 0.6 and depthFactor > 0.2 and depthFactor < 0.7 then
                        world.tiles[z][x][y] = TILE.ORE
                    -- Gems - deep
                    elseif oreNoise > 0.7 and depthFactor > 0.4 then
                        world.tiles[z][x][y] = TILE.GEMS
                    end
                end
            end
        end
    end
    
    -- Generate magma at the bottom
    for x = 1, width do
        for y = 1, height do
            local magmaNoise = self:noise2D(x, y, 3, 0.5, 0.1)
            if magmaNoise > 0.3 then
                world.tiles[depth - 1][x][y] = TILE.MAGMA
            end
        end
    end
end

function WorldGenerator:generateWater(world)
    local width = world.width
    local height = world.height
    local depth = world.depth
    
    -- Create underground rivers
    for z = 2, 5 do
        local riverNoise = self:noise2D(0, z, 2, 0.5, 0.08)
        
        if riverNoise > 0.2 then
            -- Generate a river path
            local riverY = math.floor((riverNoise + 1) * 0.5 * height)
            
            for x = 1, width do
                local riverWidth = 1 + math.floor(self:noise2D(x, z, 2, 0.5, 0.1) * 2)
                
                for dy = -riverWidth, riverWidth do
                    local y = riverY + dy
                    if y > 1 and y < height then
                        if world.tiles[z][x][y] == TILE.AIR then
                            world.fluids[z][x][y] = 1 -- Water
                        end
                    end
                end
            end
        end
    end
    
    -- Surface water (ocean)
    for x = 1, width do
        for y = 1, height do
            local oceanNoise = self:noise2D(x, y, 2, 0.5, 0.02)
            
            if oceanNoise < -0.2 then
                for z = 0, SEA_LEVEL - 1 do
                    if world.tiles[z][x][y] == TILE.AIR then
                        world.fluids[z][x][y] = 1
                    end
                end
            end
        end
    end
end

return WorldGenerator