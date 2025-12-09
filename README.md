# shadowprotocol
🔹 “Shadow Protocol – un top-down shooter multiplayer dove la sopravvivenza dipende da ciò che riesci a vedere nell’oscurità.”

🔹 “Un’esperienza co-op e PvP in cui droni e nemici si nascondono dietro la fog-of-war: esplora, sopravvivi e conquista la città sommersa dalle ombre.”

🎮 Nome del gioco

“Shadow Protocol”

Evoca l’idea di un’operazione segreta.

Richiama sia la fog-of-war (ombre, ignoto) che il multiplayer cooperativo (protocollo, missione condivisa).

🌍 World Setting – Bozza
Ambientazione

Un futuro prossimo, anno 2147. Le grandi metropoli sono diventate zone di guerra cibernetica: la luce è rarefatta, interi quartieri sono immersi nell’oscurità per via di blackout mirati.
Corporazioni rivali combattono tramite squadre d’élite armate e dotate di visori limitati, costrette a muoversi nell’ombra.

Premessa narrativa

Tu e gli altri giocatori siete agenti mercenari assoldati da fazioni rivali per controllare aree urbane strategiche.
Il problema?
L’energia elettrica è scarsa e le vostre attrezzature illuminano solo un cono visivo ristretto: il resto della mappa resta nell’ombra, popolato da droni difettosi e nemici invisibili fino all’ultimo.

Obiettivi di gioco

Co-op: sopravvivere a ondate di droni e squadre nemiche mentre mappate l’area.

PvP: conquistare nodi energetici nascosti sotto la fog-of-war prima della fazione avversaria.

Atmosfera

Minimalista ma tesa: luci al neon, ombre profonde, rumori metallici in lontananza.

Ogni proiettile e lampo di luce diventa fondamentale per rivelare il pericolo.

---

## 🛠️ Technologies

- **Game Engine**: Godot 4.x
- **Programming Language**: GDScript
- **Graphics**: 2D sprites and animations
- **Audio**: Custom sound effects and UI audio management
- **Version Control**: Git/GitHub
- **Additional Tools**: 
  - Kanban Tasks Plugin for project management
  - Custom autoload singletons for game state management

---

## ✨ Features

### Core Gameplay
- **Top-down shooter mechanics** with 360-degree movement and aiming
- **Multiple weapon types**: Handgun, rifle, shotgun, knife with unique behaviors
- **Enemy AI system**: Zombies with spawn animations, attack patterns, and cooldowns
- **Health and damage system** for both player and enemies
- **Projectile physics**: Bullets and pellets with proper collision detection

### UI & Menu System
- **Main menu** with navigation to game, settings, credits, and highscores
- **Settings menu** with customizable options
- **Game over screen** with score tracking
- **Highscore system** to track player performance
- **In-game UI** for health, ammo, and game state display

### Visual & Audio
- **Custom sprite animations** for characters, weapons, and enemies
- **Dynamic weapon switching** with visual feedback
- **UI audio feedback** for menu interactions
- **Sound effects** for shooting, impacts, and game events
- **Custom crosshair system** with multiple designs
- **Random zombie color modulation** for visual variety

### Architecture
- **Entity system**: Base class for player and enemies with shared functionality
- **Weapon system**: Modular weapon resources with customizable properties
- **Game Manager**: Centralized game state and event management
- **Settings Manager**: Persistent settings across game sessions
- **UI Audio Manager**: Consistent audio feedback throughout menus

---

## 📚 What I Learned

### Game Development Fundamentals
- **Scene architecture**: Organizing game objects and scenes in Godot
- **Node inheritance**: Using extends and class_name for code reusability
- **Signal system**: Event-driven programming for decoupled game logic
- **Physics processing**: Implementing smooth movement and collision detection

### GDScript & Programming Patterns
- **Object-oriented design**: Creating base classes (Entity, Projectile) and extending them
- **Autoload singletons**: Managing global game state and settings
- **Resource system**: Using Godot resources for weapon configurations
- **Animation control**: Synchronizing animations with game logic

### Game Design
- **Combat balance**: Tuning weapon stats, enemy health, and attack cooldowns
- **Player feedback**: Visual and audio cues for player actions
- **UI/UX design**: Creating intuitive menu navigation and in-game interfaces
- **Difficulty progression**: Balancing enemy spawning and player capabilities

### Problem Solving
- **Animation state management**: Preventing animation conflicts during attacks
- **Projectile spawning**: Calculating proper spawn positions and rotations
- **Visual variety**: Implementing random modulation for enemy distinctiveness
- **Code organization**: Structuring scripts for maintainability and scalability

---

## 🚀 What Could Be Improved

### Gameplay Enhancements
- **Multiplayer implementation**: Adding co-op and PvP functionality as described in the world setting
- **Fog-of-war system**: Implementing limited vision mechanics central to the game concept
- **Drone enemies**: Adding the mentioned malfunctioning drones and varied enemy types
- **Level progression**: Multiple maps and increasing difficulty waves
- **Power-ups and pickups**: Health packs, ammo drops, and temporary buffs
- **Environmental hazards**: Obstacles, destructible objects, and interactive elements

### Technical Improvements
- **Object pooling**: Reusing projectile and enemy instances for better performance
- **Save/load system**: Proper game state persistence beyond settings
- **Particle effects**: Adding visual polish for muzzle flashes, impacts, and deaths
- **Sound design**: More varied sound effects and background music
- **Mobile support**: Touch controls and UI scaling for different devices
- **Networking**: Implementing the multiplayer features described in the concept

### Code Quality
- **Configuration files**: Externalizing balance values to JSON/resource files
- **Unit testing**: Adding tests for critical game logic
- **Documentation**: More comprehensive code comments and design documentation
- **Error handling**: More robust error checking and edge case handling
- **Performance optimization**: Profiling and optimizing critical game loops

### Content
- **More weapons**: Expand weapon variety with special abilities
- **Boss enemies**: Challenging unique enemies with special mechanics
- **Story mode**: Narrative elements connecting the 2147 cyberpunk setting
- **Achievements**: Track player milestones and unlock conditions
- **Customization**: Character skins, weapon skins, and visual options

---

## 🎮 How to Run

### Prerequisites
- **Godot Engine 4.x** (Download from [godotengine.org](https://godotengine.org/download))
- Windows, macOS, or Linux operating system

### Running the Project

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Hisukurifu24/Shadow-Protocol.git
   cd Shadow-Protocol
   ```

2. **Open in Godot**:
   - Launch Godot Engine
   - Click "Import" on the project manager
   - Navigate to the cloned repository folder
   - Select the `project.godot` file
   - Click "Import & Edit"

3. **Run the game**:
   - Press `F5` or click the "Play" button in the top-right corner
   - The main menu will appear
   - Navigate to "Play" to start the game

### Controls
- **WASD**: Move character
- **Mouse**: Aim
- **Left Click**: Shoot
- **Number Keys (1-4)**: Switch weapons
- **ESC**: Pause/Menu

### Building for Distribution

1. **Configure export presets**:
   - Go to `Project > Export`
   - Select your target platform (Windows, macOS, Linux, Web)
   - Configure export settings

2. **Export the game**:
   - Click "Export Project"
   - Choose output location
   - Export as executable or web build

### Development Mode
- **Debug mode**: Run with `F6` to start from the current scene
- **Remote debug**: Enable in `Debug > Deploy with Remote Debug`
- **Performance monitor**: Toggle with `Debug > Visible Collision Shapes`
