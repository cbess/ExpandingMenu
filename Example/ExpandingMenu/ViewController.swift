//
//  ViewController.swift
//  ExpandingMenu
//
//  Created by monoqlo on 09/20/2015.
//  Copyright (c) 2015 monoqlo. All rights reserved.
//

import UIKit
import ExpandingMenu

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configureExpandingMenuButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    fileprivate func configureExpandingMenuButton() {
        let menuButtonSize: CGSize = CGSize(width: 40, height: 40)
        let menuButton = ExpandingMenuButton(frame: CGRect(origin: CGPoint.zero, size: menuButtonSize), centerImage: #imageLiteral(resourceName: "chooser-button-tab"), centerHighlightedImage: #imageLiteral(resourceName: "chooser-button-tab-highlighted"))
        menuButton.center = CGPoint(x: self.view.bounds.width - 32.0, y: self.view.bounds.height - 72.0)
        menuButton.expandingDirection = .left
        menuButton.menuItemMargin = 5
        menuButton.menuAnimationDuration = 0.2
        menuButton.allowSounds = false
        self.view.addSubview(menuButton)
        
        func showAlert(_ title: String) {
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        let item1 = ExpandingMenuItem(size: menuButtonSize, image: #imageLiteral(resourceName: "chooser-moment-icon-music")) {
            showAlert("Music")
        }
        
        let item2 = ExpandingMenuItem(size: menuButtonSize, image: #imageLiteral(resourceName: "chooser-moment-icon-place")) { () -> Void in
            showAlert("Place")
        }
        
        let item3 = ExpandingMenuItem(size: menuButtonSize, image: #imageLiteral(resourceName: "chooser-moment-icon-camera")) { () -> Void in
            showAlert("Camera")
        }
        
        let item4 = ExpandingMenuItem(size: menuButtonSize, image: #imageLiteral(resourceName: "chooser-moment-icon-thought")) { () -> Void in
            showAlert("Thought")
        }
        
        let item5 = ExpandingMenuItem(size: menuButtonSize, image: #imageLiteral(resourceName: "chooser-moment-icon-sleep")) { () -> Void in
            showAlert("Sleep")
        }
        
        menuButton.addMenuItems([item1, item2, item3, item4, item5])
        
        menuButton.willPresentMenuItems = { (menu) -> Void in
            print("MenuItems will present.")
        }
        
        menuButton.didDismissMenuItems = { (menu) -> Void in
            print("MenuItems dismissed.")
        }
    }
}

