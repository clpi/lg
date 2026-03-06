-- Fluid Shader
-- Creates goo-like viscous fluid effect

local fluidShader = nil

local shaderCode = [[
    uniform float time;
    uniform float viscosity;
    uniform vec4 fluidColor;
    uniform sampler2D noiseTexture;
    
    // Simple noise function
    float hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
    }
    
    float noise(vec2 p) {
        vec2 i = floor(p);
        vec2 f = fract(p);
        f = f * f * (3.0 - 2.0 * f);
        
        float a = hash(i);
        float b = hash(i + vec2(1.0, 0.0));
        float c = hash(i + vec2(0.0, 1.0));
        float d = hash(i + vec2(1.0, 1.0));
        
        return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
    }
    
    float fbm(vec2 p) {
        float value = 0.0;
        float amplitude = 0.5;
        
        for(int i = 0; i < 4; i++) {
            value += amplitude * noise(p);
            p *= 2.0;
            amplitude *= 0.5;
        }
        
        return value;
    }
    
    vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords) {
        // Create wavy goo effect
        vec2 uv = tex_coords;
        
        // Distort based on viscosity
        float distortAmount = viscosity * 0.1;
        uv.x += sin(uv.y * 10.0 + time) * distortAmount;
        uv.y += cos(uv.x * 10.0 + time) * distortAmount;
        
        // Add noise for organic look
        float n = fbm(uv * 5.0 + time * 0.5);
        
        // Edge detection for gooey look
        float edge = smoothstep(0.3, 0.5, n);
        
        // Color with depth
        vec4 col = fluidColor;
        col.a *= 0.7 + n * 0.3;
        
        // Add highlight on edges
        col.rgb += vec3(0.2) * edge;
        
        return col;
    }
]]

function loadFluidShader()
    if fluidShader == nil then
        fluidShader = love.graphics.newShader(shaderCode)
    end
    return fluidShader
end

function updateFluidShader(time, viscosity, r, g, b, a)
    if fluidShader then
        fluidShader:send("time", time)
        fluidShader:send("viscosity", viscosity)
        fluidShader:send("fluidColor", {r, g, b, a})
    end
end

return {
    load = loadFluidShader,
    update = updateFluidShader
}