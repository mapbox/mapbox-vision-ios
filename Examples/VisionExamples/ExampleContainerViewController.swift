import Foundation
import UIKit

final class ExampleContainerViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton!

    var exampleClass: UIViewController.Type?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let exampleClass = exampleClass  else {
            assertionFailure("Example class should be specified")
            return
        }

        let controller = exampleClass.init()
        embed(controller: controller)
    }

    private func embed(controller: UIViewController) {
        addChild(controller)
        view.insertSubview(controller.view, belowSubview: closeButton)
        controller.didMove(toParent: self)
    }

    @IBAction private func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
