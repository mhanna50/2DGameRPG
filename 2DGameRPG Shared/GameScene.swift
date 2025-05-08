import AVFoundation
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var score = 0
    var enemy: SKSpriteNode!
    var gameOverLabel: SKLabelNode!
    var backgroundMusicPlayer: AVAudioPlayer?
    
    // Flag to track game over state
    var isGameOver = false
    
    // Track the last update time for spawn timing
    var lastUpdateTime: TimeInterval = 0.0
    var timeSinceLastSpawn: TimeInterval = 0.0
    var timeSinceLastEnemySpawn: TimeInterval = 0.0
    var spawnInterval: TimeInterval = 2.0  // Coins spawn every 2 seconds
    var enemySpawnInterval: TimeInterval = 5.0 // Spawn the new enemy every 5 seconds
        
    
    // Physics categories for collision detection
    struct PhysicsCategory {
        static let player: UInt32 = 0x1 << 0
        static let coin: UInt32 = 0x1 << 1
        static let enemy: UInt32 = 0x1 << 2
        static let specialEnemy: UInt32 = 0x1 << 3
        static let border: UInt32 = 0x1 << 4  // Add a new category for borders
    }

    override func didMove(to view: SKView) {
        // Play background music
        playBackgroundMusic(filename: "2DGameMusic.mp3")
        
        // Set up physics world
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        // Create a physics border for the entire scene
        let borderBody = SKPhysicsBody(edgeLoopFrom: frame)
        borderBody.categoryBitMask = PhysicsCategory.border
        borderBody.contactTestBitMask = PhysicsCategory.player
        borderBody.collisionBitMask = PhysicsCategory.player
        borderBody.isDynamic = false
        borderBody.restitution = 0  // Prevents bouncing off the walls
        self.physicsBody = borderBody
        
        // Create a visible border using SKShapeNode
        let borderNode = SKShapeNode(rect: frame)
        borderNode.strokeColor = .red
        borderNode.lineWidth = 5
        borderNode.zPosition = 10  // Make sure it's above other background elements
        addChild(borderNode)

        // Connect to the player node from the .sks file
        if let playerNode = childNode(withName: "player") as? SKSpriteNode {
            player = playerNode
            player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
            player.physicsBody?.isDynamic = true
            player.physicsBody?.allowsRotation = false  // Prevent the player from rotating on impact
            player.physicsBody?.categoryBitMask = PhysicsCategory.player
            player.physicsBody?.contactTestBitMask = PhysicsCategory.coin | PhysicsCategory.enemy | PhysicsCategory.specialEnemy | PhysicsCategory.border
            player.physicsBody?.collisionBitMask = PhysicsCategory.border | PhysicsCategory.enemy | PhysicsCategory.specialEnemy
            player.physicsBody?.friction = 0  // Optional: prevent the player from slowing down on contact
            player.physicsBody?.restitution = 0  // Prevent bouncing off walls
            player.physicsBody?.linearDamping = 0  // Ensure smooth movement
            player.zPosition = 1
        }

        // Connect to the score label from the .sks file
        if let labelNode = childNode(withName: "scoreLabel") as? SKLabelNode {
            scoreLabel = labelNode
            scoreLabel.text = "Score: \(score)"
        }

        // Set up camera
        let cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)

        // Set up game over label (hidden initially)
        gameOverLabel = SKLabelNode(fontNamed: "Arial")
        gameOverLabel.fontSize = 50
        gameOverLabel.text = "Game Over"
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverLabel.isHidden = true
        addChild(gameOverLabel)
        gameOverLabel.zPosition = 3
        gameOverLabel.name = "gameOverLabel"
    }


    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            return
        }
        
        if let touch = touches.first {
            let location = touch.location(in: self)
            movePlayerSmoothly(to: location)
        }
    }

    func movePlayerSmoothly(to targetPosition: CGPoint) {
        let moveSpeed: CGFloat = 200  // Adjust this to control the speed of movement
        let direction = targetPosition - player.position  // Get direction vector
        let distance = direction.length()  // Get the distance to the target
        
        if distance > 1 {
            // Normalize the direction vector
            let normalizedDirection = CGPoint(x: direction.x / distance, y: direction.y / distance)
            
            // Set the velocity directly on the physics body for better collision handling
            let velocity = CGVector(dx: normalizedDirection.x * moveSpeed, dy: normalizedDirection.y * moveSpeed)
            player.physicsBody?.velocity = velocity
        } else {
            // Stop the player if the target is reached
            player.physicsBody?.velocity = .zero
        }
    }


    override func update(_ currentTime: TimeInterval) {
        // Initialize lastUpdateTime on the first frame
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        // Calculate the time elapsed since the last frame
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update the time since the last coin spawn
        timeSinceLastSpawn += deltaTime
        timeSinceLastEnemySpawn += deltaTime
        
        // Spawn a new coin if the interval has passed
        if timeSinceLastSpawn >= spawnInterval {
            spawnCoinAroundPlayer()
            timeSinceLastSpawn = 0.0
        }
        // Spawn a new special enemy every 5 seconds
        if timeSinceLastEnemySpawn >= enemySpawnInterval {
            spawnSpecialEnemy()
            timeSinceLastEnemySpawn = 0.0
        }
        
        // Keep the camera focused on the player
        camera?.position = player.position
    }

    func spawnCoinAroundPlayer() {
        // Define the radius around the player where the coin will spawn
        let spawnRadius: CGFloat = 200.0
        
        // Calculate random position within the radius
        let angle = CGFloat.random(in: 0..<2 * .pi)
        let xOffset = spawnRadius * cos(angle)
        let yOffset = spawnRadius * sin(angle)
        
        // Create the coin and position it around the player
        let coin = SKSpriteNode(color: .yellow, size: CGSize(width: 30, height: 30))
        coin.position = CGPoint(x: player.position.x + xOffset, y: player.position.y + yOffset)
        coin.zPosition = 0  // Coins should be behind the player
        
        // Set up physics properties for the coin
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.size)
        coin.physicsBody?.isDynamic = false
        coin.physicsBody?.categoryBitMask = PhysicsCategory.coin
        coin.physicsBody?.contactTestBitMask = PhysicsCategory.player
        coin.physicsBody?.collisionBitMask = 0
        
        // Add the coin to the scene
        addChild(coin)
    }
    func spawnSpecialEnemy() {
            // Create a new special enemy that will spawn outside of the screen
            let spawnDirection: CGFloat = Bool.random() ? 1 : -1  // Randomly choose to spawn in front or behind
            
            let specialEnemy = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
            let spawnX = player.position.x + (spawnDirection * 600)  // Spawn away from the player
            specialEnemy.position = CGPoint(x: spawnX, y: player.position.y)
            
            // Add the enemy's physics properties
            specialEnemy.physicsBody = SKPhysicsBody(rectangleOf: specialEnemy.size)
            specialEnemy.physicsBody?.isDynamic = true
            specialEnemy.physicsBody?.categoryBitMask = PhysicsCategory.specialEnemy
            specialEnemy.physicsBody?.contactTestBitMask = PhysicsCategory.player
            specialEnemy.physicsBody?.collisionBitMask = 0
            
            // Add the enemy to the scene
            addChild(specialEnemy)
            
            // Set up the movement of the enemy towards the player
            let moveAction = SKAction.move(to: player.position, duration: 15)
            specialEnemy.run(moveAction)
            
            // Despawn after 15 seconds
            let removeAction = SKAction.removeFromParent()
            specialEnemy.run(SKAction.sequence([moveAction, removeAction]))
    }

    func didBegin(_ contact: SKPhysicsContact) {
        // Get the two bodies involved in the collision
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB

        // Check if the player collided with a coin
        if (firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.coin) ||
           (secondBody.categoryBitMask == PhysicsCategory.player && firstBody.categoryBitMask == PhysicsCategory.coin) {
            
            // Identify the coin node and remove it
            if firstBody.categoryBitMask == PhysicsCategory.coin {
                firstBody.node?.removeFromParent()
            } else if secondBody.categoryBitMask == PhysicsCategory.coin {
                secondBody.node?.removeFromParent()
            }
            run(SKAction.playSoundFileNamed("CoinSoundEffect.wav", waitForCompletion: false))
            // Update the score
            updateScore()
        }
        // Check if the player collided with the special enemy
        if (firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.specialEnemy) ||
            (secondBody.categoryBitMask == PhysicsCategory.player && firstBody.categoryBitMask == PhysicsCategory.specialEnemy) {
                    
                    // End the game by calling the game over function
            endGame()
        }
        
        // Check if the player collided with the enemy
        if (firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.enemy) ||
           (secondBody.categoryBitMask == PhysicsCategory.player && firstBody.categoryBitMask == PhysicsCategory.enemy) {
            
            // End the game by calling the game over function
            endGame()
        }
    }
    
    func playBackgroundMusic(filename: String) {
        if let url = Bundle.main.url(forResource: filename, withExtension: nil) {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.numberOfLoops = -1 // Plays repeatedly
                backgroundMusicPlayer?.prepareToPlay()
                backgroundMusicPlayer?.play()
            } catch {
                print("Could not load music file: \(error)")
            }
        }
    }

    func updateScore() {
        score += 1
        // Since the score label is a child of the player, you can find it like this:
        if let label = player.childNode(withName: "scoreLabel") as? SKLabelNode {
            label.text = "Score: \(score)"
        }
    }

    func endGame() {
        // Play sound effect
        run(SKAction.playSoundFileNamed("GameOverSoundEffect.wav", waitForCompletion: false))
        
        // Show the "Game Over" label
        gameOverLabel.isHidden = false
        
        // Attach the game over label to the player
        gameOverLabel.position = CGPoint(x: player.position.x, y: player.position.y + 50) // Adjust the position as needed
        
        // Disable player movement and any other actions
        player.removeAllActions()
        
        isGameOver = true
        
        // Optionally, stop the coin spawning or any other game mechanics
        isUserInteractionEnabled = false
    }
}

// Helper extensions for CGPoint to handle movement and directions
extension CGPoint {
    static func -(left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    func length() -> CGFloat {
        return sqrt(x * x + y * y)
    }
}

 
