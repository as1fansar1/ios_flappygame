## v1.1.0 – Gameplay polish and start screen

- Difficulty ramp
  - Game speed increases every 3 points (multiplies `moving.speed` by 1.25)
  - Pipe gap shrinks every 3 points with a safe minimum (configurable)

- Haptics
  - Light impact on flap
  - Selection tick on score
  - Extra impact on each speed-up
  - Elongated Core Haptics effect on death (falls back gracefully if not supported)
  - Success notification when achieving a high score

- Sound effects (requires adding clips to the bundle)
  - `flap.wav`, `score.wav`, `hit.wav`, `highscore.wav`

- Start screen & UX
  - Bird starts centered with physics paused; first tap starts the game
  - Start prompt: “Click here to start the game” (black, pulsing)
  - Bottom credits shown as two lines while idle:
    - “Made with <3”
    - “by Asif Ansari”
  - When the game starts, credits hide and the score label returns

- Background ambiance on start screen
  - Gentle bird bobbing animation
  - Soft, floating particle field behind the scene

- Maintenance
  - Removed an unused `buttonSize` variable warning

Notes
- Haptics require a real device to feel; simulators do not vibrate.
- Sound effects need to be included in the app target to play.

