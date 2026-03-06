-- Deepslate Constants
-- All game constants and configuration values

-- Tile constants
TILE_SIZE = 8
CHUNK_SIZE = 16
VIEW_DISTANCE = 20

-- World generation
WORLD_WIDTH = 128
WORLD_HEIGHT = 128
WORLD_DEPTH = 10
SEA_LEVEL = 5
CAVE_THRESHOLD = 0.45

-- Entity constants
MAX_DWARVES = 50
MAX_CREATURES = 100
MAX_ITEMS = 500

-- Time constants
TICK_RATE = 10
TICK_TIME = 1 / TICK_RATE
DAY_LENGTH = 2400 -- ticks per day

-- Need thresholds
HUNGER_THRESHOLD = 0.3
THIRST_THRESHOLD = 0.25
SLEEP_THRESHOLD = 0.2
JOY_THRESHOLD = 0.15

-- Skill thresholds
SKILL_LEVELS = {
    NOVICE = 0,
    ADEQUATE = 50,
    COMPETENT = 100,
    SKILLED = 200,
    PROFICIENT = 350,
    TALENTED = 550,
    EXPERT = 800,
    PROFESSIONAL = 1100,
    MASTER = 1500,
    GRAND_MASTER = 2000
}

-- Tile types
TILE = {
    AIR = 0,
    SOIL = 1,
    CLAY = 2,
    STONE = 3,
    DEEP_STONE = 4,
    MAGMA = 5,
    WATER = 6,
    LAVA = 7,
    GRASS = 8,
    SAND = 9,
    ORE = 10,
    METAL = 11,
    GEMS = 12,
    COAL = 13,
    WOOD = 14,
    TREE = 15
}

-- Material colors (RGBA)
COLORS = {
    AIR = {0, 0, 0, 0},
    SOIL = {101, 67, 33, 255},
    CLAY = {139, 90, 43, 255},
    STONE = {105, 105, 105, 255},
    DEEP_STONE = {47, 47, 47, 255},
    MAGMA = {255, 69, 0, 255},
    WATER = {30, 144, 255, 200},
    LAVA = {255, 100, 0, 230},
    GRASS = {34, 139, 34, 255},
    SAND = {238, 214, 175, 255},
    COAL = {30, 30, 30, 255},
    GOLD = {255, 215, 0, 255},
    IRON = {192, 192, 192, 255},
    COPPER = {184, 115, 51, 255},
    GEMS = {75, 0, 130, 255},
    WOOD = {139, 69, 19, 255}
}

-- Fluid constants
FLUID = {
    WATER = {id = 1, viscosity = 0.3, flow_rate = 1},
    LAVA = {id = 2, viscosity = 0.8, flow_rate = 0.3},
    MAGMA = {id = 3, viscosity = 0.95, flow_rate = 0.1}
}

-- Building types
BUILDING = {
    FLOOR = 1,
    WALL = 2,
    DOOR = 3,
    RAMP = 4,
    STAIRS = 5,
    BED = 6,
    TABLE = 7,
    CHAIR = 8,
    FURNACE = 9,
    FORGE = 10,
    KITCHEN = 11,
    FARM = 12,
    WELL = 13,
    STOCKPILE = 14,
    WORKSHOPS = 15
}

-- Item categories
ITEM = {
    FOOD = 1,
    DRINK = 2,
    WEAPON = 3,
    ARMOR = 4,
    TOOL = 5,
    MATERIAL = 6,
    FURNITURE = 7,
    GEMS = 8,
    COINS = 9
}

-- Need types
NEED = {
    FOOD = 1,
    WATER = 2,
    SLEEP = 3,
    RECREATION = 4,
    SOCIAL = 5,
    EXERCISE = 6,
    SPIRITUAL = 7,
    JUSTICE = 8,
    COMFORT = 9
}

-- Dwarf personalities
PERSONALITY = {
    STOIC = 1,
    CHEERFUL = 2,
    GLOOMY = 3,
    FURIOUS = 4,
    PACIFIST = 5,
    AGGRESSIVE = 6,
    LAZY = 7,
    DILIGENT = 8,
    GREEDY = 9,
    GENEROUS = 10
}

-- Job priorities
PRIORITY = {
    CRITICAL = 1,
    HIGH = 2,
    MEDIUM = 3,
    LOW = 4,
    NONE = 5
}

-- UI colors
UI = {
    BACKGROUND = {40, 35, 30, 230},
    BORDER = {80, 70, 60, 255},
    TEXT = {220, 200, 170, 255},
    TEXT_DIM = {150, 130, 110, 255},
    HIGHLIGHT = {255, 200, 100, 255},
    DANGER = {200, 50, 50, 255},
    SUCCESS = {50, 180, 80, 255},
    WATER = {30, 144, 255, 255},
    LAVA = {255, 100, 0, 255}
}

-- Camera settings
CAMERA = {
    MIN_ZOOM = 0.25,
    MAX_ZOOM = 3.0,
    DEFAULT_ZOOM = 1.0,
    ZOOM_SPEED = 0.1,
    PAN_SPEED = 300
}

-- Pathfinding
PATHFINDING = {
    MAX_ITERATIONS = 500,
    DIAGONAL_COST = 1.414,
    STRAIGHT_COST = 1.0
}

-- File paths
PATHS = {
    SAVE_DIR = "saves/",
    SCREENSHOTS = "screenshots/",
    WORLD_GEN_SEED = "seed.dat"
}