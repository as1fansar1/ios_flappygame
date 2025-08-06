import SpriteKit
import GameplayKit

struct HighScore: Codable {
    let name: String
    let score: Int
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bird: SKSpriteNode!
    var skyColor: SKColor!
    var pipeTextureUp: SKTexture!
    var pipeTextureDown: SKTexture!
    var movePipesAndRemove: SKAction!
    var moving: SKNode!
    var pipes: SKNode!
    var canRestart = Bool()
    var scoreLabelNode: SKLabelNode!
    var score = NSInteger()
    var highScores: [HighScore] = []
    var gameOverLabel: SKLabelNode!
    var scoreboardBackground: SKSpriteNode!
    var isShowingScoreboard = false
    var isEnteringName = false
    var currentNameInput = ""
    var nameInputLabel: SKLabelNode!
    var namePromptLabel: SKLabelNode!
    var gameSpeedMultiplier: CGFloat = 1.0
    
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    override func didMove(to view: SKView) {
        canRestart = false
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        self.physicsWorld.contactDelegate = self
        
        skyColor = SKColor(red: 113.0/255.0, green: 197.0/255.0, blue: 207.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        moving = SKNode()
        self.addChild(moving)
        pipes = SKNode()
        moving.addChild(pipes)
        
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest
        
        let moveGroundSprite = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGroundSprite = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite, resetGroundSprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( groundTexture.size().width * 2 )) {
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPoint(x: CGFloat(i) * sprite.size.width, y: sprite.size.height / 2)
            sprite.run(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        let skyTexture = SKTexture(imageNamed: "sky")
        skyTexture.filteringMode = .nearest
        
        let moveSkySprite = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.1 * skyTexture.size().width * 2.0))
        let resetSkySprite = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveSkySpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkySprite, resetSkySprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( skyTexture.size().width * 2 )) {
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPoint(x: CGFloat(i) * sprite.size.width, y: sprite.size.height / 2 + groundTexture.size().height * 2.0)
            sprite.run(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest
        
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTextureUp.size().width)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(0.01 * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
        
        let spawn = SKAction.run(spawnPipes)
        let delay = SKAction.wait(forDuration: TimeInterval(3.0))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever)
        
        let birdTexture1 = SKTexture(imageNamed: "bird-01")
        birdTexture1.filteringMode = .nearest
        let birdTexture2 = SKTexture(imageNamed: "bird-02")
        birdTexture2.filteringMode = .nearest
        
        let animation = SKAction.animate(with: [birdTexture1, birdTexture2], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(animation)
        
        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(1.5)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y: self.frame.size.height * 0.6)
        bird.run(flap)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        
        self.addChild(bird)
        
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2.0))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        scoreLabelNode.position = CGPoint(x: self.frame.midX, y: self.frame.size.height / 8)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(score)
        self.addChild(scoreLabelNode)
        
        loadHighScores()
    }
    
    func spawnPipes() {
        let pipePair = SKNode()
        pipePair.position = CGPoint(x: self.frame.size.width + pipeTextureUp.size().width * 2, y: 0)
        pipePair.zPosition = -10
        
        let height = UInt32(self.frame.size.height / 4)
        let y = Double(arc4random_uniform(height) + height)
        
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(1.5)
        pipeDown.position = CGPoint(x: 0.0, y: y + Double(pipeDown.size.height) + 100.0)
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
        pipeDown.physicsBody?.isDynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(1.5)
        pipeUp.position = CGPoint(x: 0.0, y: y - 100.0)
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
        pipeUp.physicsBody?.isDynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeUp)
        
        let contactNode = SKNode()
        contactNode.position = CGPoint(x: pipeDown.size.width + bird.size.width / 2, y: self.frame.midY)
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipeUp.size.width, height: self.frame.size.height))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
        pipePair.run(movePipesAndRemove)
        pipes.addChild(pipePair)
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
                score += 1
                scoreLabelNode.text = String(score)
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: TimeInterval(0.1)), SKAction.scale(to: 1.0, duration: TimeInterval(0.1))]))
                
                // Increase speed every 8 points
                if score % 8 == 0 {
                    increaseGameSpeed()
                }
            } else {
                moving.speed = 0
                bird.physicsBody?.collisionBitMask = worldCategory
                bird.run(SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.physicsBody!.velocity.dy) * 0.00003, duration: 1), completion: { self.bird.speed = 0 })
                
                self.removeAction(forKey: "flash")
                self.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
                    self.backgroundColor = SKColor.red
                }), SKAction.wait(forDuration: TimeInterval(0.05)), SKAction.run({
                    self.backgroundColor = self.skyColor
                }), SKAction.wait(forDuration: TimeInterval(0.05))]), count:4), SKAction.run({
                    if self.isHighScore(self.score) {
                        self.promptForName()
                    } else {
                        self.showGameOver()
                    }
                })]), withKey: "flash")
            }
        }
    }
    
    func resetScene() {
        bird.position = CGPoint(x: self.frame.size.width / 2.5, y: self.frame.midY)
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        pipes.removeAllChildren()
        
        canRestart = false
        moving.speed = 1
        score = 0
        scoreLabelNode.text = String(score)
        
        hideScoreboard()
        hideGameOver()
        
        // Reset game speed
        gameSpeedMultiplier = 1.0
        moving.speed = gameSpeedMultiplier
    }
    
    func increaseGameSpeed() {
        gameSpeedMultiplier *= 1.25 // Increase by 25%
        moving.speed = gameSpeedMultiplier
    }
    
    // MARK: - Scoreboard Methods
    func loadHighScores() {
        if let data = UserDefaults.standard.data(forKey: "highScores"),
           let decodedScores = try? JSONDecoder().decode([HighScore].self, from: data) {
            highScores = decodedScores
        }
    }
    
    func saveHighScores() {
        if let encodedData = try? JSONEncoder().encode(highScores) {
            UserDefaults.standard.set(encodedData, forKey: "highScores")
        }
    }
    
    func isHighScore(_ score: Int) -> Bool {
        return highScores.count < 5 || score > (highScores.last?.score ?? 0)
    }
    
    func addHighScore(name: String, score: Int) {
        let newScore = HighScore(name: name, score: score)
        highScores.append(newScore)
        highScores.sort { $0.score > $1.score }
        if highScores.count > 5 {
            highScores = Array(highScores.prefix(5))
        }
        saveHighScores()
    }
    
    func showGameOver() {
        gameOverLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = SKColor.red
        gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        gameOverLabel.zPosition = 200
        self.addChild(gameOverLabel)
        
        let waitAction = SKAction.wait(forDuration: 5.0)
        let showScoreboardAction = SKAction.run {
            self.showScoreboard()
        }
        self.run(SKAction.sequence([waitAction, showScoreboardAction]))
    }
    
    func hideGameOver() {
        gameOverLabel?.removeFromParent()
        gameOverLabel = nil
    }
    
    func showScoreboard() {
        isShowingScoreboard = true
        
        scoreboardBackground = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.8), size: self.frame.size)
        scoreboardBackground.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        scoreboardBackground.zPosition = 150
        self.addChild(scoreboardBackground)
        
        let titleLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        titleLabel.text = "HIGH SCORES"
        titleLabel.fontSize = 32
        titleLabel.fontColor = SKColor.yellow
        titleLabel.position = CGPoint(x: 0, y: self.frame.size.height * 0.3)
        titleLabel.zPosition = 151
        scoreboardBackground.addChild(titleLabel)
        
        for (index, highScore) in highScores.enumerated() {
            let scoreLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
            scoreLabel.text = "\(index + 1). \(highScore.name) - \(highScore.score)"
            scoreLabel.fontSize = 20
            scoreLabel.fontColor = SKColor.white
            scoreLabel.position = CGPoint(x: 0, y: self.frame.size.height * 0.2 - CGFloat(index * 30))
            scoreLabel.zPosition = 151
            scoreboardBackground.addChild(scoreLabel)
        }
        
        let instructionLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        instructionLabel.text = "Tap to continue"
        instructionLabel.fontSize = 16
        instructionLabel.fontColor = SKColor.gray
        instructionLabel.position = CGPoint(x: 0, y: -self.frame.size.height * 0.3)
        instructionLabel.zPosition = 151
        scoreboardBackground.addChild(instructionLabel)
    }
    
    func hideScoreboard() {
        scoreboardBackground?.removeFromParent()
        scoreboardBackground = nil
        isShowingScoreboard = false
    }
    
    func promptForName() {
        isEnteringName = true
        currentNameInput = ""
        
        scoreboardBackground = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.8), size: self.frame.size)
        scoreboardBackground.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        scoreboardBackground.zPosition = 150
        self.addChild(scoreboardBackground)
        
        namePromptLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        namePromptLabel.text = "NEW HIGH SCORE!"
        namePromptLabel.fontSize = 24
        namePromptLabel.fontColor = SKColor.yellow
        namePromptLabel.position = CGPoint(x: 0, y: 120)
        namePromptLabel.zPosition = 151
        scoreboardBackground.addChild(namePromptLabel)
        
        let scoreLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: 0, y: 80)
        scoreLabel.zPosition = 151
        scoreboardBackground.addChild(scoreLabel)
        
        let instructionLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        instructionLabel.text = "Tap letters to spell your name:"
        instructionLabel.fontSize = 16
        instructionLabel.fontColor = SKColor.white
        instructionLabel.position = CGPoint(x: 0, y: 40)
        instructionLabel.zPosition = 151
        scoreboardBackground.addChild(instructionLabel)
        
        nameInputLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        nameInputLabel.text = "_"
        nameInputLabel.fontSize = 24
        nameInputLabel.fontColor = SKColor.green
        nameInputLabel.position = CGPoint(x: 0, y: 0)
        nameInputLabel.zPosition = 151
        scoreboardBackground.addChild(nameInputLabel)
        
        // Create virtual keyboard
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lettersPerRow = 9
        let buttonSize: CGFloat = 30
        let spacing: CGFloat = 35
        
        for (index, letter) in letters.enumerated() {
            let row = index / lettersPerRow
            let col = index % lettersPerRow
            
            let letterButton = SKLabelNode(fontNamed: "MarkerFelt-Wide")
            letterButton.text = String(letter)
            letterButton.fontSize = 18
            letterButton.fontColor = SKColor.cyan
            letterButton.name = "letter_\(letter)"
            
            let xPos = CGFloat(col - lettersPerRow/2) * spacing
            let yPos = -60 - CGFloat(row) * 35
            letterButton.position = CGPoint(x: xPos, y: yPos)
            letterButton.zPosition = 151
            scoreboardBackground.addChild(letterButton)
        }
        
        // Add DELETE and DONE buttons
        let deleteButton = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        deleteButton.text = "DEL"
        deleteButton.fontSize = 18
        deleteButton.fontColor = SKColor.red
        deleteButton.name = "delete"
        deleteButton.position = CGPoint(x: -80, y: -165)
        deleteButton.zPosition = 151
        scoreboardBackground.addChild(deleteButton)
        
        let doneButton = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        doneButton.text = "DONE"
        doneButton.fontSize = 18
        doneButton.fontColor = SKColor.green
        doneButton.name = "done"
        doneButton.position = CGPoint(x: 80, y: -165)
        doneButton.zPosition = 151
        scoreboardBackground.addChild(doneButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isEnteringName {
            for touch in touches {
                let location = touch.location(in: scoreboardBackground)
                let touchedNode = scoreboardBackground.atPoint(location)
                
                if let nodeName = touchedNode.name {
                    if nodeName.hasPrefix("letter_") && currentNameInput.count < 6 {
                        let letter = String(nodeName.dropFirst(7))
                        currentNameInput += letter
                        nameInputLabel.text = currentNameInput + (currentNameInput.count < 6 ? "_" : "")
                    } else if nodeName == "delete" && !currentNameInput.isEmpty {
                        currentNameInput = String(currentNameInput.dropLast())
                        nameInputLabel.text = currentNameInput + "_"
                    } else if nodeName == "done" {
                        if currentNameInput.isEmpty {
                            currentNameInput = "PLAYER"
                        }
                        addHighScore(name: currentNameInput, score: score)
                        hideScoreboard()
                        isEnteringName = false
                        showScoreboard()
                    }
                }
            }
        } else if isShowingScoreboard {
            hideScoreboard()
            canRestart = true
        } else if moving.speed > 0 {
            for _ in touches {
                bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50))
            }
        } else if canRestart {
            self.resetScene()
        }
    }
}