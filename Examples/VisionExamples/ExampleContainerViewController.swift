//
//  ExampleTableViewController.swift
//  VisionExample
//
//  Copyright © 2019 Mapbox. All rights reserved.
//

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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
