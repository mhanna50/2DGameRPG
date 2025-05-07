import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var score = 0
    var enemy: SKSpriteNode!
    var gameOverLabel: SKLabelNode!
    
    // Track the last update time for spawn timing
    var lastUpdateTime: TimeInterval = 0.0
    var timeSinceLastSpawn: TimeInterval = 0.0
    var spawnInterval: TimeInterval = 2.0  // Coins spawn every 2 seconds
    
    // Physics categories for collision detection
    struct PhysicsCategory {
        static let player: UInt32 = 0x1 << 0
        static let coin: UInt32 = 0x1 << 1
        static let enemy: UInt32 = 0x1 << 2
    }

    override func didMove(to view: SKView) {
        // Set up physics world
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        // Connect to the player node from the .sks file
        if let playerNode = childNode(withName: "player") as? SKSpriteNode {
            player = playerNode
            player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
            player.physicsBody?.isDynamic = true
            player.physicsBody?.categoryBitMask = PhysicsCategory.player
            player.physicsBody?.contactTestBitMask = PhysicsCategory.coin | PhysicsCategory.enemy
            player.physicsBody?.collisionBitMask = 0
            player.zPosition = 1
        }

        // Connect to the score label from the .sks file
        if let labelNode = childNode(withName: "scoreLabel") as? SKLabelNode {
            scoreLabel = labelNode
            scoreLabel.text = "Score: \(score)"
        }
        
        // Set up enemy node from .sks file
        if let enemyNode = childNode(withName: "enemy") as? SKSpriteNode {
            enemy = enemyNode
            enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
            enemy.physicsBody?.isDynamic = false  // The enemy is stationary
            enemy.physicsBody?.categoryBitMask = PhysicsCategory.enemy
            enemy.physicsBody?.contactTestBitMask = PhysicsCategory.player
            enemy.physicsBody?.collisionBitMask = 0
            enemy.zPosition = 2
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
        gameOverLabel.isHidden = true  // Hide initially
        addChild(gameOverLabel)

        // Attach the game over label to the player so it follows the player
        gameOverLabel.zPosition = 3  // Make sure it's above the player
        gameOverLabel.name = "gameOverLabel"
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            movePlayerSmoothly(to: location)
        }
    }

    func movePlayerSmoothly(to targetPosition: CGPoint) {
        let moveSpeed: CGFloat = 200  // Adjust this to control the speed of movement
        let direction = targetPosition - player.position  // Get direction vector
        let distance = direction.length()  // Get the distance to the target
        
        if distance > 1 {  // If not already at the target position
            let moveDuration = distance / moveSpeed  // Calculate the duration based on distance and speed
            let moveAction = SKAction.move(to: targetPosition, duration: moveDuration)
            player.run(moveAction)
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
        
        // Spawn a new coin if the interval has passed
        if timeSinceLastSpawn >= spawnInterval {
            spawnCoinAroundPlayer()
            timeSinceLastSpawn = 0.0
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
            
            // Update the score
            updateScore()
        }
        
        // Check if the player collided with the enemy
        if (firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.enemy) ||
           (secondBody.categoryBitMask == PhysicsCategory.player && firstBody.categoryBitMask == PhysicsCategory.enemy) {
            
            // End the game by calling the game over function
            endGame()
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
        // Show the "Game Over" label
        gameOverLabel.isHidden = false
        
        // Attach the game over label to the player
        gameOverLabel.position = CGPoint(x: player.position.x, y: player.position.y + 50) // Adjust the position as needed
        
        // Disable player movement and any other actions
        player.removeAllActions()
        
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

