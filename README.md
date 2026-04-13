<div align="center">
  <h1>🎮 Super Coin World 🎮</h1>
  <p><b>[Project under development...]</b></p>
  
  ![Roblox](https://img.shields.io/badge/Roblox-Studio-000000?style=for-the-badge&logo=roblox&logoColor=white)
  ![Lua](https://img.shields.io/badge/Lua-Language-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
  ![Rojo](https://img.shields.io/badge/Rojo-Sync-FF4B4B?style=for-the-badge)
  <br/>
  [![CI](https://github.com/thegamerbay/super-coin-world/actions/workflows/ci.yml/badge.svg)](https://github.com/thegamerbay/super-coin-world/actions/workflows/ci.yml)
  [![Release](https://img.shields.io/github/v/release/thegamerbay/super-coin-world)](https://github.com/thegamerbay/super-coin-world/releases)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
</div>

<br/>

**Super Coin World** is a custom 3D platformer game inside of Roblox featuring innovative spherical, gravity-defying mechanics. Players can traverse fully 3D planetary biomes, run completely upside-down without falling off, and collect dynamically scattered coins across lush forests, icy wastelands, and massive desert dunes. 

This repository demonstrates advanced client-server architecture, custom gravity simulation, and an elegant synchronization process between your local IDE (VS Code) and Roblox Studio using **Rojo**, strict package management using **Wally**, and toolchain management using **Aftman**.

---

## 🌌 Gameplay Features
* **Spherical Gravity Controller**: Utilizing EgoMoose's Wallstick concepts, characters completely align their normal vector to whichever planet's gravitational pull is strongest, allowing for seamless spherical orbiting.
* **Procedural Biome Generation**: Instead of a flat baseplate, the world initiates multiple planets (`Planet_Start`, `Planet_Ice`, `Planet_Sand`) with spherical coordinate algorithms dynamically spawning trees and resources perfectly aligned to each surface.
* **Persistent Leaderboards**: Global tracking of coin collectors powered by `DataStoreService`, dynamically displayed on tilting in-game SurfaceGuis that naturally align with planetary curvature.

---

## 🛠️ Tech Stack & Tooling

This project uses modern Roblox development standards:
* **[Rojo](https://rojo.space/)**: Syncs external files into Roblox Studio.
* **[Aftman](https://github.com/LPGhatguy/aftman)**: Cross-platform toolchain manager for Roblox CLI tools (Rojo, Wally, Selene).
* **[Wally](https://wally.run/)**: The package manager for Roblox. We use it to pull our testing framework, **TestEZ**, and memory management toolkit, **Trove**.
* **[Selene](https://kampfkarren.github.io/selene/)**: A blazing fast linter crafted specifically for Luau and Roblox standard libraries.
* **[GitHub Actions](https://github.com/features/actions)**: Automated CI/CD pipelines checking code quality. We use the **Roblox Open Cloud Luau Execution API** to run our TestEZ test suites directly on Roblox servers.

---

## ⚡ Setup Guide

### Step 1: Getting the Project & Tools
1. Clone the repository: `git clone https://github.com/thegamerbay/super-coin-world.git`
2. Open the folder in VS Code.
3. Install the tools using Aftman:
   ```bash
   aftman install
   ```
4. Install Roblox library dependencies using Wally:
   ```bash
   wally install
   ```

### Step 2: Running Rojo
1. Install the official **Rojo** extension by `evaera` in VS Code.
2. Open the VS Code Command Palette (`Ctrl+Shift+P`) and choose `Rojo: Start server`.

### Step 3: Connecting Roblox Studio
1. Open up an empty modern **Baseplate** in Roblox Studio.
2. Under the **Plugins** tab, click **Rojo** and then **Connect**.
3. *Magic!* Your scripts and Wally packages instantiate perfectly into `ServerScriptService` and `ReplicatedStorage`.

### 🔍 Linting Locally
To run the Selene linter locally before pushing code:
```bash
selene src
```

---

## 🙏 Credits & Acknowledgements

This project relies on the incredible open-source contributions of the Roblox developer community. We extend our deepest gratitude to:
* **[EgoMoose / Rbx-Wallstick](https://github.com/EgoMoose/Rbx-Wallstick)** - The core physics logic powering our entire planetary gravity system! EgoMoose's Wallstick controller elegantly replaces default Roblox physics, allowing our characters to dynamically align their gravity vectors and experience true spherical planet exploration.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute this project as you see fit.
