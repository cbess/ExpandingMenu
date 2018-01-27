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

    fileprivate func configureExpandingMenuButton() {
        var menuButtonSize: CGSize = CGSize(width: 55, height: 55)
        let menuButton = ExpandingMenuButton(frame: CGRect(origin: CGPoint.zero, size: menuButtonSize), centerImage: #imageLiteral(resourceName: "chooser-button-tab"), centerHighlightedImage: #imageLiteral(resourceName: "chooser-button-tab-highlighted"))
        menuButton.center = CGPoint(x: view.bounds.width - 32.0, y: view.bounds.height - 72.0)
        menuButton.expandingDirection = .left
        menuButton.menuItemMargin = 5
        menuButton.menuAnimationDuration = 0.2
        menuButton.allowSounds = false
        menuButton.enabledExpandingAnimations = [.MenuItemMoving, .MenuItemRotation]
        menuButton.enabledFoldingAnimations = [.MenuItemMoving, .MenuItemFade]
        view.addSubview(menuButton)
        
        func showAlert(_ title: String) {
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
        menuButtonSize.width -= 5
        menuButtonSize.height -= 5
        
        let item1 = ExpandingMenuItem(size: menuButtonSize, image: #imageLiteral(resourceName: "chooser-moment-icon-music")) {
            showAlert("Music")
        }
        
        let item2 = ExpandingMenuItem(size: menuButtonSize, image: #imageLiteral(resourceName: "chooser-moment-icon-place")) {
            showAlert("Place")
        }
        
        let item3 = ExpandingMenuItem(size: menuButtonSize, image: #imageLiteral(resourceName: "chooser-moment-icon-camera")) {
            showAlert("Camera")
        }
        
        let item4 = ExpandingMenuItem(size: menuButtonSize, image: #imageLiteral(resourceName: "chooser-moment-icon-thought")) {
            showAlert("Thought")
        }
        
//        let item5 = ExpandingMenuItem(size: menuButtonSize, image: #imageLiteral(resourceName: "chooser-moment-icon-sleep")) {
//            showAlert("Sleep")
//        }
        
        menuButton.addMenuItems([item1, item2, item3, item4])
        
        menuButton.willPresentMenuItems = { (menu) -> Void in
            print("MenuItems will present.")
        }
        
        menuButton.didDismissMenuItems = { (menu) -> Void in
            print("MenuItems dismissed.")
        }
    }
}

