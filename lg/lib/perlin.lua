-- Perlin Noise Library
-- Implementation of classic Perlin noise algorithm

local Perlin = {}
Perlin.__index = Perlin

-- Permutation table
local p = {
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
    8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,
    35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,
    134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,
    55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,
    18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,
    226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,
    17,182,189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,
    167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,
    246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,
    14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,
    4,150,254,138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,
    156,180
}

-- Duplicate permutation table for overflow
local permutation = {}
for i = 0, 255 do
    permutation[i] = p[i + 1]
    permutation[256 + i] = p[i + 1]
end

-- Fade function for interpolation
local function fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

-- Linear interpolation
local function lerp(a, b, t)
    return a + t * (b - a)
end

-- Gradient function
local function grad(hash, x, y, z)
    local h = hash % 16
    
    if h < 8 then
        if h < 4 then
            if h == 0 then return x + y
            elseif h == 1 then return -x + y
            elseif h == 2 then return x - y
            else return -x - y end
        else
            if h == 4 then return x + z
            elseif h == 5 then return -x + z
            elseif h == 6 then return x - z
            else return -x - z end
        end
    else
        if h < 12 then
            if h == 8 then return y + z
            elseif h == 9 then return -y + z
            elseif h == 10 then return y - z
            else return -y - z end
        else
            if h == 12 then return y + x
            elseif h == 13 then return y - x
            elseif h == 14 then return -y + x
            else return -y - x end
        end
    end
    
    return 0
end

function Perlin:new(seed)
    local self = setmetatable({}, Perlin)
    self.seed = seed or os.time()
    
    -- Initialize permutation with seed
    math.randomseed(self.seed)
    
    -- Shuffle permutation based on seed
    for i = 256, 1, -1 do
        local j = math.random(1, i)
        permutation[i - 1] = permutation[j]
        permutation[256 + i - 1] = permutation[j]
    end
    
    return self
end

function Perlin:get(x, y, z)
    local X = math.floor(x) % 256
    local Y = math.floor(y) % 256
    local Z = math.floor(z or 0) % 256
    
    x = x - math.floor(x)
    y = y - math.floor(y)
    z = (z or 0) - math.floor(z)
    
    local u = fade(x)
    local v = fade(y)
    local w = fade(z)
    
    local A = permutation[X] + Y
    local AA = permutation[A] + Z
    local AB = permutation[A + 1] + Z
    local B = permutation[X + 1] + Y
    local BA = permutation[B] + Z
    local BB = permutation[B + 1] + Z
    
    return lerp(
        lerp(
            lerp(grad(permutation[AA], x, y, z), grad(permutation[BA], x - 1, y, z), u),
            lerp(grad(permutation[AB], x, y - 1, z), grad(permutation[BB], x - 1, y - 1, z), u),
            v
        ),
        lerp(
            lerp(grad(permutation[AA + 1], x, y, z - 1), grad(permutation[BA + 1], x - 1, y, z - 1), u),
            lerp(grad(permutation[AB + 1], x, y - 1, z - 1), grad(permutation[BB + 1], x - 1, y - 1, z - 1), u),
            v
        ),
        w
    )
end

-- Get noise in a specific range
function Perlin:getRange(x, y, z, minVal, maxVal)
    return self:get(x, y, z) * (maxVal - minVal) * 0.5 + (maxVal + minVal) * 0.5
end

-- Fractal Brownian Motion (fBm)
function Perlin:fbm(x, y, z, octaves, persistence)
    octaves = octaves or 6
    persistence = persistence or 0.5
    
    local total = 0
    local frequency = 1
    local amplitude = 1
    local maxValue = 0
    
    for i = 1, octaves do
        total = total + self:get(x * frequency, y * frequency, z * frequency) * amplitude
        maxValue = maxValue + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * 2
    end
    
    return total / maxValue
end

return Perlin