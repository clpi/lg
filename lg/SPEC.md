# Dwarf Fortress Lie Game - Specification

## Project Overview
- **Project Name**: Deepslate
- **Type**: Colony simulation/management game (Dwarf Fortress-like)
- **Engine**: Love2D (Lua)
- **Core Functionality**: A roguelike colony simulation with procedural generation, complex entity systems, and deep emergent storytelling
- **Target Users**: Fans of complex simulation games, roguelike enthusiasts

## Visual & Rendering Specification

### Scene Setup
- **Camera**: Orthographic camera with zoom controls, smooth panning
- **View Modes**: 
  - Overworld map view (procedural terrain)
  - Underground fortress view (layered z-levels)
  - Entity detail view
- **Lighting**: Dynamic light system with temperature-based coloring, torch glow

### Materials & Effects
- **Tile Rendering**: Custom shader-based tiles with material properties
- **Fluid Simulation**: Simplified cellular automata for water/lava with viscous "goo" physics
- **Particles**: Dust, debris, blood, fire particles using instanced rendering
- **Post-Processing**: 
  - Vignette for depth
  - Color grading (warm underground tones)
  - Scanline effect for retro feel

### Color Palette
- **Primary**: Earthy browns, stone grays
- **Accent**: Molten orange/red for lava, crystal blue for water
- **UI**: Parchment/sepia tones with high contrast

### Graphics Style
- **ASCII-inspired**: Tile-based with procedural detail overlays
- **Pixel art**: Retro aesthetic with modern effects
- **Smooth animations**: All state changes interpolated

## Simulation Specification

### World Generation
- **Algorithm**: Multi-octave Perlin noise for terrain
- **Layers**: Surface, soil, stone, deep stone, magma
- **Biomes**: Multiple underground biomes with different resources
- **Caves**: Procedural cave systems using cellular automata

### Entity System
- **Dwarves**: Complex need系统, skills, personalities, relationships
- **Creatures**: Hostile mobs, tame animals, vermin
- **Buildings**: Multi-tile structures with custom layouts
- **Items**: Stackable items with material properties

### Resource Management
- **Needs**: Food, water, sleep, social, recreation, crafting
- **Skills**: Mining, crafting, farming, cooking, combat
- **Economy**: Workshop-based production chains
- **Weather**: Underground "weather" (water drippage, dust storms)

### Pathfinding
- **A* pathfinding**: For entity movement
- **Fluids**: Flow simulation for water/lava
- **Mining**: Material-dependent mining speeds

### Performance Targets
- **Tick Rate**: 10 updates/second base, variable
- **Entity Count**: Support 100+ dwarves, 1000+ items
- **Render**: 60 FPS with 500+ visible tiles

## Interaction Specification

### Controls
- **Mouse**: Select tiles, issue commands, drag-select
- **Keyboard**: 
  - Arrow keys: Pan camera
  - Q/E: Zoom
  - Space: Pause/Resume
  - Tab: Toggle view mode
  - Various hotkeys for tools

### UI Elements
- **Main View**: Central game view with HUD overlay
- **Side Panel**: Selected entity/building info
- **Bottom Bar**: Action buttons, status
- **Menus**: Overlay menus for save/load, settings

### Game Systems
- **Orders**: Queued commands for dwarves
- **Jobs**: Automatic job assignment based on needs/skills
- **Notifications**: Event log with categories
- **Stockpiles**: Categorized item storage

## Acceptance Criteria

1. **World Generation**: Procedural world with distinct layers and resources
2. **Entity AI**: Dwarves autonomously perform jobs based on needs
3. **Building**: Multi-tile building placement and construction
4. **Fluids**: Water/lava flow with "goo-like" viscous behavior
5. **Combat**: Simple combat system with injuries/death
6. **Save/Load**: Game state persistence
7. **Performance**: Maintains 60 FPS with moderate entity count
8. **UI**: Functional interface with all major systems accessible

## Technical Architecture

### File Structure
```
main.lua          - Entry point
conf.lua          - Love2D configuration
constants.lua     - Game constants
world/
  generator.lua   - World generation
  chunk.lua       - Chunk management
entities/
  dwarf.lua       - Dwarf class
  creature.lua    - Creature class
  item.lua        - Item class
systems/
  ai.lua          - AI system
  pathfinding.lua - Pathfinding
  fluids.lua      - Fluid simulation
rendering/
  camera.lua      - Camera system
  tileset.lua     - Tile rendering
  shaders.lua     - Shader management
ui/
  manager.lua     - UI management
  panels.lua      - UI panels
  hud.lua         - HUD elements