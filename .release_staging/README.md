# LunarLander3D

LunarLander3D is a custom, high-fidelity 3D Reinforcement Learning environment built on top of [Gymnasium](https://gymnasium.farama.org/) and simulated using [PyBullet](https://pybullet.org/). It extends the classic 2D Lunar Lander into a fully 3D world with 6 Degrees of Freedom (6-DoF), realistic rigid-body physics, and complex control challenges.

## 🚀 Features
- **Full 3D Physics:** 6-DoF rigid body dynamics with gravity ($g = -1.62 \, m/s^2$).
- **Realistic Actuators:** Main thruster for vertical lift and RCS (Reaction Control System) thrusters for pitch, roll, yaw, and lateral translations.
- **Multiple Control Baselines:** Includes three distinct conventional control strategies (V1, V2, V3) ranging from classical PID to advanced rigid-body trajectory tracking.

## 🛠️ Installation

Clone the repository and install the required dependencies:

```bash
git clone https://github.com/fitranurmayadi/LunarLander3d.git
cd LunarLander3d
pip install -r requirements.txt
```

*Note: It is highly recommended to use a virtual environment (e.g., `python -m venv venv`)*.

## 🎮 Usage & Mission Testing

The repository provides three conventional baseline controllers. You can run them to observe different flight characteristics and control theories in action.

```bash
python mission_v1_classic.py
python mission_v2_direct.py
python mission_v3_trajectory.py
```

### Shared Command-Line Arguments
All mission scripts share the same standardized arguments for easy testing:
- `--episodes N`: Run N consecutive episodes (default: 1).
- `--fixed`: Run the "Compass Test" (Spawns the lander in 4 distinct quadrants: SW, NW, SE, NE at 1km altitude).
- `--spawn X Y Z`: Set a custom spawn coordinate. Example: `--spawn 500 -500 1000`
- `--orient R P Y`: Set a custom initial orientation (Roll, Pitch, Yaw) in degrees. Example: `--orient 45 0 90`
- `--no-render`: Run in headless mode without the PyBullet GUI (useful for fast testing).

**Output Reports:**
After an episode finishes, a comprehensive performance chart is automatically generated and saved in the `reports/` folder.

---

## 🧠 Theory and Control Techniques

### Mission V1: Classic Decoupled PID
**Concept:**
This controller uses a Finite State Machine (FSM) combined with decoupled PID controllers. It separates horizontal movement from vertical movement. To move laterally, it calculates the required horizontal velocity, feeds it into a PID loop, and translates the output into a **Target Pitch/Roll angle**.

**Pros:**
- Highly stable and easy to tune.
- "Safe" flight envelope; the lander always prefers leveling out before descending.

**Cons:**
- Inefficient and slow trajectory.
- Stops at invisible "waypoints" before proceeding to the next state, causing a robotic, step-by-step flight path.

### Mission V2: Direct Vectoring
**Concept:**
Unlike V1, V2 blends transit and landing phases. It uses **Direct Thrust Vectoring** where the horizontal error is mapped directly to a tilted thrust vector. The controller continuously updates its orientation to point the thrust vector opposite to the velocity vector while simultaneously aiming for the landing pad.

**Pros:**
- Smooth, continuous, and cinematic flight path.
- Much faster transit time compared to V1.

**Cons:**
- Strongly coupled dynamics (pitching to move laterally inherently reduces vertical lift).
- Difficult to tune the safety envelope to prevent the lander from tumbling at high speeds.

### Mission V3: High-Precision Trajectory Mastery
**Concept:**
This is the most advanced controller. It abandons simple error-based PID in favor of **Rigid-Body Dynamics Tracking**. 
1. It pre-calculates a smooth 3D mathematical curve (e.g., using polynomial splines) from the start position to the target.
2. It calculates the exact **Reference Position, Velocity, and Acceleration** at every millisecond $t$.
3. It converts the reference acceleration vector directly into a required Body Frame orientation matrix using Feed-Forward terms.

**Pros:**
- Extremely precise (centimeter-level accuracy).
- Obeys kinematic constraints perfectly (no sudden jerks).

**Cons:**
- Computationally heavy.
- Very sensitive to simulation step-size variations ($dt$). If PyBullet stutters, the trajectory tracking error diverges rapidly.
