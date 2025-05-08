import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.view as? SKView {
            if let scene = SKScene(fileNamed: "GameScene") {
                scene.scaleMode = .resizeFill
                view.presentScene(scene)
            }

            view.ignoresSiblingOrder = true
            view.showsFPS = false
            view.showsNodeCount = false
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

