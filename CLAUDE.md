# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS Flappy Bird game built with Swift using SpriteKit framework. The project targets iOS 17.5+ and supports both iPhone and iPad devices.

## Development Commands

### Building
- **Build in Xcode**: Open `FlappyBird.xcodeproj` in Xcode and use Cmd+B to build
- **Run in Simulator**: Open project in Xcode and use Cmd+R to run in iOS Simulator
- **Archive for Distribution**: Product → Archive in Xcode

### Development Setup
- Requires Xcode 15.4+ 
- Swift 5.0
- iOS deployment target: 17.5+
- No external dependencies or package managers

## Code Architecture

### Core Components

**GameScene.swift** - Main game logic and physics
- Handles SpriteKit scene management with physics world setup (gravity: -5.0)
- Manages bird sprite with flapping animation using two bird textures
- Implements scrolling background with parallax (sky and ground layers)
- Pipe spawning system with random height positioning and 2-second intervals
- Collision detection using physics categories (bird, world, pipes, score)
- Score tracking and visual feedback systems
- Game reset functionality for restart after collision

**GameViewController.swift** - View controller bridge
- Connects UIKit to SpriteKit scene presentation
- Configures scene scaling (.aspectFill) and debugging options
- Manages interface orientations and status bar visibility

**AppDelegate.swift** - Standard iOS app lifecycle management

### Physics System
The game uses SpriteKit's physics engine with collision categories:
- `birdCategory` (1 << 0): The player bird
- `worldCategory` (1 << 1): Ground and collision boundaries  
- `pipeCategory` (1 << 2): Pipe obstacles
- `scoreCategory` (1 << 3): Invisible scoring trigger zones

### Asset Management
All game assets are managed through `Assets.xcassets`:
- Bird sprites: `bird-01.png`, `bird-02.png` (for flapping animation)
- Environment: `sky.png`, `land.png` (for scrolling background)
- Obstacles: `PipeUp.png`, `PipeDown.png`

### Game Flow
1. Scene initialization sets up physics, background scrolling, and bird
2. Touch input applies upward impulse to bird (30 units)
3. Continuous pipe spawning with collision detection
4. Score increments when bird passes through pipe gaps
5. Game over triggers red flash animation and enables restart
6. Reset functionality returns all elements to initial state