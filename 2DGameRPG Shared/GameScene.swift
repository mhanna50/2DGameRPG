import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var coin: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var score = 0

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
        player.physicsBody?.isDynamic = false  // Prevent falling
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.coin
        player.physicsBody?.collisionBitMask = 0
        addChild(player)

        // Set up initial coin
        spawnCoin()

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
        let moveAction = SKAction.move(to: position, duration: 0.2)
        player.run(moveAction)
    }

    override func update(_ currentTime: TimeInterval) {
        // Keep the camera focused on the player
        camera?.position = player.position
    }

    func spawnCoin() {
        // Create a coin at a random position
        coin = SKSpriteNode(color: .yellow, size: CGSize(width: 30, height: 30))
        let randomX = CGFloat.random(in: -frame.width/2...frame.width/2)
        let randomY = CGFloat.random(in: -frame.height/2...frame.height/2)
        coin.position = CGPoint(x: randomX, y: randomY)
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.size)
        coin.physicsBody?.isDynamic = false
        coin.physicsBody?.categoryBitMask = PhysicsCategory.coin
        coin.physicsBody?.contactTestBitMask = PhysicsCategory.player
        coin.physicsBody?.collisionBitMask = 0
        addChild(coin)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        // Check if player collided with coin
        if (contact.bodyA.node == player && contact.bodyB.node == coin) || (contact.bodyB.node == player && contact.bodyA.node == coin) {
            coin.removeFromParent()
            updateScore()
            spawnCoin()
        }
    }

    func updateScore() {
        score += 1
        scoreLabel.text = "Score: \(score)"
    }
}


