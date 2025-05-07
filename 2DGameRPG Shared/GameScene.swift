import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var score = 0
    
    // Track the last update time for spawn timing
    var lastUpdateTime: TimeInterval = 0.0
    var timeSinceLastSpawn: TimeInterval = 0.0
    var spawnInterval: TimeInterval = 2.0  // Coins spawn every 2 seconds
    
    // Physics categories for collision detection
    struct PhysicsCategory {
        static let player: UInt32 = 0x1 << 0
        static let coin: UInt32 = 0x1 << 1
    }

    override func didMove(to view: SKView) {
        // Disable world gravity
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        // Set up player
        player = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true  // Allow it to move
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.coin
        player.physicsBody?.collisionBitMask = 0
        player.zPosition = 1  // Ensure the player is in front of the coins
        addChild(player)

        // Set up score label
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel.fontSize = 30
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        scoreLabel.text = "Score: \(score)"
        addChild(scoreLabel)

        // Set up camera
        let cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Move player based on touch location
        if let touch = touches.first {
            let location = touch.location(in: self)
            movePlayer(to: location)
        }
    }

    func movePlayer(to position: CGPoint) {
        // Calculate the distance from the player to the target position
        let distance = player.position.distance(to: position)
        
        // Set a base duration based on the distance to ensure movement time is proportional
        let duration = TimeInterval(distance / 500) // 500 is a speed factor you can adjust
        
        // Create a move action with ease in/out
        let moveAction = SKAction.move(to: position, duration: duration)
        moveAction.timingMode = .easeInEaseOut // Smooth easing
        
        // Run the action to move the player
        player.run(moveAction)
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
    }

    func updateScore() {
        score += 1
        scoreLabel.text = "Score: \(score)"
    }
}

extension CGPoint {
    // Helper method to calculate the distance between two points
    func distance(to point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}

