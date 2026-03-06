-- Dwarf Entity Class
-- Represents a dwarf in the colony

local Dwarf = {}
Dwarf.__index = Dwarf

function Dwarf.new(name, x, y, z)
    local self = setmetatable({}, Dwarf)
    
    -- Basic properties
    self.id = love.math.random(10000, 99999)
    self.name = name or Dwarf:generateName()
    self.profession = "NONE"
    
    -- Position
    self.x = x or 1
    self.y = y or 1
    self.z = z or 1
    
    -- Movement
    self.targetX = self.x
    self.targetY = self.y
    self.targetZ = self.z
    self.path = {}
    self.moving = false
    self.moveSpeed = 1.0
    
    -- State
    self.state = "IDLE" -- IDLE, WORKING, SLEEPING, EATING, DRINKING, PATHFINDING, COMBAT, FLEEING
    self.job = nil
    self.jobProgress = 0
    
    -- Needs (0.0 - 1.0, where 1.0 is fully satisfied)
    self.needs = {
        food = 0.8,
        water = 0.8,
        sleep = 0.9,
        recreation = 0.7,
        social = 0.6,
        comfort = 0.7,
        spiritual = 0.5
    }
    
    -- Skills (0 - 2000+)
    self.skills = {
        mining = 0,
        masonry = 0,
        woodworking = 0,
        carpentry = 0,
        smelting = 0,
        forging = 0,
        cooking = 0,
        farming = 0,
        animal = 0,
        cooking = 0,
        fishing = 0,
        hunting = 0,
        weapons = 0,
        armor = 0,
        diplomatic = 0,
        pedagogy = 0
    }
    
    -- Personality
    self.personality = Dwarf:generatePersonality()
    
    -- Health
    self.health = 100
    self.maxHealth = 100
    self.energy = 100
    self.blood = 100
    
    -- Status effects
    self.statusEffects = {}
    
    -- Inventory
    self.inventory = {}
    self.maxInventory = 10
    
    -- Equipment
    self.equipment = {
        weapon = nil,
        armor = nil,
        tool = nil
    }
    
    -- Social
    self.relationships = {}
    self.squad = nil
    
    -- Work
    self.workHistory = {}
    self.totalWork = 0
    
    -- Timers
    self.stateTimer = 0
    self.interactionTimer = 0
    
    return self
end

function Dwarf:generateName()
    local prefixes = {
        "Borin", "Dorin", "Kili", "Thorin", "Balin", "Dwalin", 
        "Gimli", "Glor", "Ori", "Nori", "Dori", "Norbi",
        "Bombur", "Bofur", "Bifur", "Durin", "Thrain", "Thror"
    }
    
    local suffixes = {
        "in", "ur", "ar", "or", "ir", "el", "ol",
        "i", "o", "a", "dis", "li", "ri", "ki"
    }
    
    local nicknameParts = {
        "Iron", "Stone", "Gold", "Silver", "Copper", "Coal",
        "Forge", "Hammer", "Anvil", "Ax", "Pick", "Barrel",
        "Beard", "Battle", "Brew", "Mead", "Ale", "Deep"
    }
    
    local name = prefixes[love.math.random(#prefixes)] .. suffixes[love.math.random(#suffixes)]
    
    if love.math.random() > 0.5 then
        name = name .. " " .. nicknameParts[love.math.random(#nicknameParts)]
    end
    
    return name
end

function Dwarf:generatePersonality()
    local personalities = {"STOIC", "CHEERFUL", "GLOOMY", "FURIOUS", "PACIFIST", 
                          "AGGRESSIVE", "LAZY", "DILIGENT", "GREEDY", "GENEROUS"}
    
    return {
        trait = personalities[love.math.random(#personalities)],
        boldness = love.math.random(),
        greed = love.math.random(),
        generosity = love.math.random(),
        empathy = love.math.random(),
        laziness = love.math.random(),
        agressiveness = love.math.random()
    }
end

function Dwarf:update(dt, world)
    self.stateTimer = self.stateTimer + dt
    
    -- Update needs over time
    self:updateNeeds(dt)
    
    -- Check state transitions
    if self.state == "IDLE" then
        self:evaluateState(world)
    elseif self.state == "WORKING" then
        self:doWork(dt, world)
    elseif self.state == "PATHFINDING" then
        self:followPath(dt, world)
    elseif self.state == "SLEEPING" then
        self:sleepUpdate(dt)
    elseif self.state == "EATING" or self.state == "DRINKING" then
        self:consumeUpdate(dt)
    end
    
    -- Update equipment appearance
    self:updateEquipment()
end

function Dwarf:updateNeeds(dt)
    -- Needs decay over time (scaled by personality)
    local decayRate = 0.01 * dt
    
    self.needs.food = math.max(0, self.needs.food - decayRate * 1.5)
    self.needs.water = math.max(0, self.needs.water - decayRate * 2.0)
    self.needs.sleep = math.max(0, self.needs.sleep - decayRate * 0.5)
    self.needs.recreation = math.max(0, self.needs.recreation - decayRate * 0.3)
    self.needs.social = math.max(0, self.needs.social - decayRate * 0.4)
    self.needs.comfort = math.max(0, self.needs.comfort - decayRate * 0.2)
    self.needs.spiritual = math.max(0, self.needs.spiritual - decayRate * 0.1)
end

function Dwarf:evaluateState(world)
    -- Critical needs check (highest priority)
    if self.needs.food < HUNGER_THRESHOLD then
        self:findFood(world)
        return
    end
    
    if self.needs.water < THIRST_THRESHOLD then
        self:findWater(world)
        return
    end
    
    if self.needs.sleep < SLEEP_THRESHOLD then
        self:findBed(world)
        return
    end
    
    -- Job assignment
    if self.job then
        self:assignJob(world)
    else
        -- Look for available jobs
        self:findJob(world)
    end
end

function Dwarf:findFood(world)
    -- Look for food items nearby or go to kitchen/farm
    local foodItems = world:findItemsInRange(self.x, self.y, self.z, 5, ITEM.FOOD)
    
    if #foodItems > 0 then
        self:moveToItem(foodItems[1], world)
        self.state = "PATHFINDING"
    else
        -- Go to farm or kitchen
        local farm = world:findBuildingInRange(self.x, self.y, self.z, 10, BUILDING.FARM)
        if farm then
            self:setTarget(farm.x, farm.y, farm.z)
            self.state = "PATHFINDING"
        end
    end
end

function Dwarf:findWater(world)
    -- Look for water source
    local well = world:findBuildingInRange(self.x, self.y, self.z, 10, BUILDING.WELL)
    if well then
        self:setTarget(well.x, well.y, well.z)
        self.state = "PATHFINDING"
    else
        -- Look for water tiles
        local waterTile = world:findFluidInRange(self.x, self.y, self.z, 5, 1)
        if waterTile then
            self:setTarget(waterTile.x, waterTile.y, waterTile.z)
            self.state = "PATHFINDING"
        end
    end
end

function Dwarf:findBed(world)
    local bed = world:findBuildingInRange(self.x, self.y, self.z, 10, BUILDING.BED)
    if bed then
        self:setTarget(bed.x, bed.y, bed.z)
        self.state = "PATHFINDING"
    else
        -- Sleep on floor
        self.state = "SLEEPING"
        self.stateTimer = 0
    end
end

function Dwarf:findJob(world)
    -- Get available jobs from world
    local jobs = world:getJobs()
    
    if #jobs > 0 then
        -- Filter jobs by skill
        local bestJob = nil
        local bestSkill = -1
        
        for _, job in ipairs(jobs) do
            local skillValue = self.skills[job.skill] or 0
            if skillValue > bestSkill then
                bestSkill = skillValue
                bestJob = job
            end
        end
        
        if bestJob then
            self.job = bestJob
            self:assignJob(world)
        end
    end
end

function Dwarf:assignJob(world)
    if not self.job then return end
    
    -- Go to job site
    self:setTarget(self.job.x, self.job.y, self.job.z)
    self.state = "PATHFINDING"
    
    -- Will start working when at location
end

function Dwarf:doWork(dt, world)
    if not self.job then
        self.state = "IDLE"
        return
    end
    
    -- Check if at job location
    local dist = math.abs(self.x - self.job.x) + math.abs(self.y - self.job.y) + math.abs(self.z - self.job.z)
    
    if dist > 1 then
        self.state = "PATHFINDING"
        return
    end
    
    -- Do work
    local workRate = 1.0 + (self.skills[self.job.skill] or 0) / 1000
    self.jobProgress = self.jobProgress + dt * workRate
    
    -- Skill gain
    self.skills[self.job.skill] = (self.skills[self.job.skill] or 0) + dt * 0.1
    self.totalWork = self.totalWork + dt
    
    -- Check if job complete
    if self.jobProgress >= self.job.duration then
        world:completeJob(self.job, self)
        self.job = nil
        self.jobProgress = 0
        self.state = "IDLE"
        
        -- Boost needs slightly from work
        self.needs.recreation = math.min(1, self.needs.recreation + 0.1)
    end
end

function Dwarf:followPath(dt, world)
    if #self.path > 0 then
        local nextPos = self.path[1]
        
        -- Move towards next position
        local dx = nextPos.x - self.x
        local dy = nextPos.y - self.y
        local dz = nextPos.z - self.z
        
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
        
        if dist < 0.1 then
            -- Reached waypoint
            table.remove(self.path, 1)
            self.x = nextPos.x
            self.y = nextPos.y
            self.z = nextPos.z
        else
            -- Move
            local moveAmount = self.moveSpeed * dt
            self.x = self.x + (dx / dist) * moveAmount
            self.y = self.y + (dy / dist) * moveAmount
            self.z = self.z + (dz / dist) * moveAmount
        end
    else
        -- Path complete - check what to do next
        self.moving = false
        
        if self.job then
            self.state = "WORKING"
        elseif self.needs.food < HUNGER_THRESHOLD then
            self.state = "EATING"
            self.stateTimer = 0
        elseif self.needs.water < THIRST_THRESHOLD then
            self.state = "DRINKING"
            self.stateTimer = 0
        else
            self.state = "IDLE"
        end
    end
end

function Dwarf:setTarget(x, y, z)
    self.targetX = x
    self.targetY = y
    self.targetZ = z
    
    -- Pathfinding will be done by the world system
    self.moving = true
end

function Dwarf:moveToItem(item, world)
    self:setTarget(item.x, item.y, item.z)
    self.targetItem = item
end

function Dwarf:sleepUpdate(dt)
    self.needs.sleep = math.min(1, self.needs.sleep + dt * 0.5)
    self.energy = math.min(100, self.energy + dt * 20)
    
    if self.needs.sleep > 0.9 or self.energy > 90 then
        self.state = "IDLE"
    end
end

function Dwarf:consumeUpdate(dt)
    self.stateTimer = self.stateTimer + dt
    
    if self.stateTimer > 2 then
        if self.state == "EATING" then
            self.needs.food = math.min(1, self.needs.food + 0.4)
        elseif self.state == "DRINKING" then
            self.needs.water = math.min(1, self.needs.water + 0.5)
        end
        
        self.state = "IDLE"
    end
end

function Dwarf:updateEquipment()
    -- Update visual based on equipment
end

function Dwarf:takeDamage(amount, damageType)
    self.health = self.health - amount
    
    if damageType == "blood_loss" then
        self.blood = math.max(0, self.blood - amount * 0.5)
    end
    
    if self.health <= 0 then
        self:die()
    end
end

function Dwarf:die()
    self.state = "DEAD"
    -- Drop inventory
    -- Create body
end

function Dwarf:getDisplayColor()
    if self.state == "SLEEPING" then
        return {0.3, 0.3, 0.5}
    elseif self.state == "WORKING" then
        return {0.8, 0.6, 0.3}
    elseif self.state == "COMBAT" then
        return {0.9, 0.2, 0.2}
    elseif self.health < 50 then
        return {0.6, 0.3, 0.3}
    else
        return {0.9, 0.8, 0.7}
    end
end

return Dwarf