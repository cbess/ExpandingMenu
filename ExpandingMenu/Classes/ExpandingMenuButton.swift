//
//  ExpandingMenuButton.swift
//
//  Created by monoqlo on 2015/07/21.
//  Copyright (c) 2015年 monoqlo All rights reserved.
//

import UIKit
import AudioToolbox

public struct AnimationOptions: OptionSet {
    public let rawValue: Int
    
    public static let menuItemRotation = AnimationOptions(rawValue: 1)
    public static let menuItemBound = AnimationOptions(rawValue: 2)
    public static let menuItemMoving = AnimationOptions(rawValue: 4)
    public static let menuItemFade = AnimationOptions(rawValue: 8)
    public static let menuButtonRotation = AnimationOptions(rawValue: 16)
    
    public static let normal: AnimationOptions = [menuItemRotation, menuItemBound, menuItemMoving, menuButtonRotation]
    public static let all: AnimationOptions = [menuItemRotation, menuItemBound, menuItemMoving, menuItemFade, menuButtonRotation]
    
    public init(rawValue: Int) { self.rawValue = rawValue }
}

@available(iOS 10.0, *)
open class ExpandingMenuButton: UIView, UIGestureRecognizerDelegate {
    
    public enum ExpandingDirection {
        case top
        case bottom
        case left
    }
    
    public enum MenuTitleDirection {
        case left
        case right
    }
    
    // MARK: Public Properties
    
    /// The duration of the fold and expand animations. Defaults to 0.25.
    public var menuAnimationDuration: CFTimeInterval = 0.25
    
    /// The space between each menu item. Defaults to 16.
    public var menuItemMargin: CGFloat = 16
    
    open var allowSounds: Bool = true {
        didSet {
            configureSounds()
        }
    }
    
    open var expandingSoundPath: String = Bundle(url: Bundle(for: ExpandingMenuButton.classForCoder()).url(forResource: "ExpandingMenu", withExtension: "bundle")!)?.path(forResource: "expanding", ofType: "caf") ?? "" {
        didSet {
            configureSounds()
        }
    }
    
    open var foldSoundPath: String = Bundle(url: Bundle(for: ExpandingMenuButton.classForCoder()).url(forResource: "ExpandingMenu", withExtension: "bundle")!)?.path(forResource: "fold", ofType: "caf") ?? "" {
        didSet {
            configureSounds()
        }
    }
    
    open var selectedSoundPath: String = Bundle(url: Bundle(for: ExpandingMenuButton.classForCoder()).url(forResource: "ExpandingMenu", withExtension: "bundle")!)?.path(forResource: "selected", ofType: "caf") ?? "" {
        didSet {
            configureSounds()
        }
    }
    
    public var bottomViewBlurEffectStyle: UIBlurEffect.Style = .regular
    
    public var titleTappedActionEnabled: Bool = true
    
    public var expandingDirection: ExpandingDirection = .top
    public var menuTitleDirection: MenuTitleDirection = .left
    
    public var enabledExpandingAnimations = ExpandingMenu.AnimationOptions.normal
    public var enabledFoldingAnimations = ExpandingMenu.AnimationOptions.normal
    
    /// Indicates if the button is expanded/presented
    public fileprivate(set) var isExpanded: Bool = false
    
    public var willPresentMenuItems: ((ExpandingMenuButton) -> Void)?
    public var didPresentMenuItems: ((ExpandingMenuButton) -> Void)?
    public var willDismissMenuItems: ((ExpandingMenuButton) -> Void)?
    public var didDismissMenuItems: ((ExpandingMenuButton) -> Void)?
    
    // MARK: Private Properties
    
    fileprivate var defaultCenterPoint: CGPoint = .zero
    
    fileprivate var itemButtonImages: [UIImage] = []
    fileprivate var itemButtonHighlightedImages: [UIImage] = []
    
    fileprivate var centerImage: UIImage?
    fileprivate var centerHighlightedImage: UIImage?
    
    fileprivate var expandingSize: CGSize {
        return superview?.bounds.size ?? UIScreen.main.bounds.size
    }
    fileprivate var foldedSize: CGSize = .zero
    
    fileprivate var bottomView = UIVisualEffectView()
    fileprivate var centerButton = UIButton()
    fileprivate var menuItems: [ExpandingMenuItem] = []
    
    fileprivate var foldSound: SystemSoundID = 0
    fileprivate var expandingSound: SystemSoundID = 0
    fileprivate var selectedSound: SystemSoundID = 0
    
    fileprivate var isAnimating: Bool = false
    
    open override var intrinsicContentSize: CGSize {
        return centerButton.bounds.size
    }
    
    // MARK: - Initializer
    
    public init(frame: CGRect, centerImage: UIImage, centerHighlightedImage: UIImage? = nil) {
        super.init(frame: frame)
        
        func configureViewsLayoutWithButtonSize(_ centerButtonSize: CGSize) {
            // Configure menu button frame
            foldedSize = centerButtonSize
            self.frame = CGRect(origin: frame.origin, size: foldedSize)
            
            // Configure center button
            centerButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: centerButtonSize.width, height: centerButtonSize.height))
            centerButton.setImage(centerImage, for: .normal)
            centerButton.setImage(centerHighlightedImage, for: .highlighted)
            centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchDown)
            centerButton.center = CGPoint(x: frame.width / 2.0, y: frame.height / 2.0)
            centerButton.contentHorizontalAlignment = .fill
            centerButton.contentVerticalAlignment = .fill
            centerButton.imageView?.contentMode = .scaleAspectFit
            addSubview(centerButton)
            
            // Configure bottom view
            bottomView.frame = CGRect(x: 0.0, y: 0.0, width: expandingSize.width, height: expandingSize.height)
            bottomView.effect = UIBlurEffect(style: bottomViewBlurEffectStyle)
            
            // Make bottomView's touch can delay superView witch like UIScrollView scrolling
            bottomView.isUserInteractionEnabled = true;
            let tapGesture = UIGestureRecognizer()
            tapGesture.delegate = self
            bottomView.addGestureRecognizer(tapGesture)
        }
        
        // Configure enter and highlighted center image
        self.centerImage = centerImage
        self.centerHighlightedImage = centerHighlightedImage
        
        if frame == CGRect.zero {
            configureViewsLayoutWithButtonSize(self.centerImage?.size ?? CGSize.zero)
        } else {
            configureViewsLayoutWithButtonSize(frame.size)
            defaultCenterPoint = center
        }
        
        configureSounds()
    }
    
    public convenience init(centerImage: UIImage, centerHighlightedImage: UIImage? = nil) {
        self.init(frame: CGRect.zero, centerImage: centerImage, centerHighlightedImage: centerHighlightedImage)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Configure Menu Items
    
    open func addMenuItems(_ menuItems: [ExpandingMenuItem]) {
        self.menuItems += menuItems
    }
    
    open func addMenuItem(_ menuItem: ExpandingMenuItem) {
        menuItems.append(menuItem)
    }
    
    // MARK: - Menu Item Tapped Action
    
    open func menuItemTapped(_ item: ExpandingMenuItem) {
        willDismissMenuItems?(self)
        isAnimating = true
        
        let selectedIndex: Int = item.index
        
        if allowSounds {
            AudioServicesPlaySystemSound(selectedSound)
        }
        
        // explode animation when the item is selected
        UIView.animate(withDuration: 0.0618 * 5.0) {
            item.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
            item.alpha = 0.0
        }
        
        // dismiss animation when the item is unselected
        for (index, item) in menuItems.enumerated() {
            // Remove title button
            if let titleButton = item.titleButton {
                UIView.animate(withDuration: menuAnimationDuration, animations: { () -> Void in
                    titleButton.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        titleButton.removeFromSuperview()
                })
            }
            
            if index == selectedIndex {
                continue
            }
            
            UIView.animate(withDuration: menuAnimationDuration) {
                item.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
            }
        }
        
        resizeToFoldedFrame(animated: true) {
            self.didFold()
        }
    }
    
    @objc fileprivate func centerButtonTapped() {
        if !isAnimating {
            if isExpanded {
                foldMenuItems()
            } else {
                expandMenuItems()
            }
        }
    }
    
    fileprivate func configureSounds() {
        if allowSounds {
            let expandingSoundUrl = URL(fileURLWithPath: expandingSoundPath)
            AudioServicesCreateSystemSoundID(expandingSoundUrl as CFURL, &expandingSound)
            
            let foldSoundUrl = URL(fileURLWithPath: foldSoundPath)
            AudioServicesCreateSystemSoundID(foldSoundUrl as CFURL, &foldSound)
            
            let selectedSoundUrl = URL(fileURLWithPath: selectedSoundPath)
            AudioServicesCreateSystemSoundID(selectedSoundUrl as CFURL, &selectedSound)
        } else {
            AudioServicesDisposeSystemSoundID(expandingSound)
            AudioServicesDisposeSystemSoundID(foldSound)
            AudioServicesDisposeSystemSoundID(selectedSound)
        }
    }
    
    /// Calculate The Distance From Center Button
    fileprivate func makeDistanceFromCenterButton(_ itemSize: CGSize, lastDistance: CGFloat, lastItemSize: CGSize) -> CGFloat {
        return lastDistance + itemSize.height / 2.0 + menuItemMargin + lastItemSize.height / 2.0
    }
    
    /// Calculate The Item's End Point
    fileprivate func makeEndPoint(_ itemExpandRadius: CGFloat, angle: CGFloat) -> CGPoint {
        switch expandingDirection {
        case .top:
            return CGPoint(
                x: centerButton.center.x + CGFloat(cosf((Float(angle) + 1.0) * Float.pi)) * itemExpandRadius,
                y: centerButton.center.y + CGFloat(sinf((Float(angle) + 1.0) * Float.pi)) * itemExpandRadius
            )
        case .bottom:
            return CGPoint(
                x: centerButton.center.x + CGFloat(cosf(Float(angle) * Float.pi)) * itemExpandRadius,
                y: centerButton.center.y + CGFloat(sinf(Float(angle) * Float.pi)) * itemExpandRadius
            )
        case .left:
            return CGPoint(
                x: centerButton.center.x + CGFloat(cosf((Float(90) + 1.0) * Float.pi)) * itemExpandRadius,
                y: centerButton.center.y + CGFloat(sinf((Float(90) + 1.0) * Float.pi)) * itemExpandRadius
            )
        }
    }
    
    // MARK: - Fold Menu Items
    
    fileprivate func foldMenuItems(animated: Bool = true) {
        willDismissMenuItems?(self)
        isAnimating = true
        
        if allowSounds {
            AudioServicesPlaySystemSound(foldSound)
        }
        
        let currentAngle: CGFloat = 90.0
        var lastDistance: CGFloat = 0.0
        var lastItemSize = centerButton.bounds.size
        
        for item in menuItems {
            let distance = makeDistanceFromCenterButton(item.bounds.size, lastDistance: lastDistance, lastItemSize: lastItemSize)
            lastDistance = distance
            lastItemSize = item.bounds.size
            let backwardPoint = makeEndPoint(distance + 5.0, angle: currentAngle / 180.0)
            
            if animated {
                let foldAnimation = makeFoldAnimation(startingPoint: item.center, backwardPoint: backwardPoint, endPoint: centerButton.center)
                
                item.layer.add(foldAnimation, forKey: "foldAnimation")
                
                // ensure that the item opacity remains after the animation is complete
                if enabledFoldingAnimations.contains(.menuItemFade) {
                    item.alpha = 0
                }
            }
            
            item.center = centerButton.center
            
            // Remove title button
            if let titleButton = item.titleButton {
                if animated {
                    UIView.animate(withDuration: 0.15, animations: { () -> Void in
                        titleButton.alpha = 0.0
                        }, completion: { (finished) -> Void in
                            titleButton.removeFromSuperview()
                    })
                } else {
                    titleButton.removeFromSuperview()
                }
            }
        }
        
        bringSubviewToFront(centerButton)
        
        // Resize the ExpandingMenuButton's frame to the folded frame and remove the item buttons
        resizeToFoldedFrame(animated: animated) {
            self.didFold()
        }
    }
    
    fileprivate func resizeToFoldedFrame(animated: Bool, completion: (() -> Void)?) {
        if animated, enabledFoldingAnimations.contains(.menuButtonRotation) {
            UIView.animate(withDuration: menuAnimationDuration, delay: 0, options: .curveEaseIn, animations: { () -> Void in
                self.centerButton.transform = CGAffineTransform(rotationAngle: 0.0)
                }, completion: nil)
        } else {
            centerButton.transform = CGAffineTransform(rotationAngle: 0.0)
        }
        
        let didComplete = { (finished: Bool) in
            // Remove the items from the superview
            for item in self.menuItems {
                item.removeFromSuperview()
            }
            
            // resize the view to the folded state
            self.frame = CGRect(x: 0.0, y: 0.0, width: self.foldedSize.width, height: self.foldedSize.height)
            self.center = self.defaultCenterPoint
            self.centerButton.center = CGPoint(x: self.frame.width / 2.0, y: self.frame.height / 2.0)
            
            self.bottomView.removeFromSuperview()
            
            completion?()
        }
        
        // hide bottom view
        if animated {
            UIView.animate(withDuration: menuAnimationDuration, delay: menuAnimationDuration * 0.5, options: .curveLinear, animations: { () -> Void in
                self.bottomView.effect = nil
                }, completion: didComplete)
        } else {
            didComplete(true)
        }
    }
    
    fileprivate func makeFoldAnimation(startingPoint: CGPoint, backwardPoint: CGPoint, endPoint: CGPoint) -> CAAnimationGroup {
        let animationDuration = menuAnimationDuration * 0.9 // make it close a bit faster, than opening
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = []
        animationGroup.duration = animationDuration
        
        // Configure rotation animation
        if enabledFoldingAnimations.contains(.menuItemRotation) {
            let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.values = [0.0, Double.pi, Double.pi * 2.0]
            rotationAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            rotationAnimation.duration = animationDuration
            
            animationGroup.animations?.append(rotationAnimation)
        }
        
        // Configure moving animation
        let movingAnimation = CAKeyframeAnimation(keyPath: "position")
        let path = CGMutablePath()
        
        if enabledFoldingAnimations.contains([.menuItemMoving, .menuItemBound]) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: backwardPoint.x, y: backwardPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.75, 1.0]
        } else if enabledFoldingAnimations.contains(.menuItemMoving) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.75, 1.0]
        } else if enabledFoldingAnimations.contains(.menuItemBound) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: backwardPoint.x, y: backwardPoint.y))
            path.addLine(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.3, 0.5, 1.0]
        } else if enabledFoldingAnimations.contains(.menuItemFade) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
        }
        
        movingAnimation.path = path
        movingAnimation.duration = animationDuration
        
        animationGroup.animations?.append(movingAnimation)
        
        // Configure fade animation
        if enabledFoldingAnimations.contains(.menuItemFade) {
            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [1.0, 0.25, 0.1, 0.0]
            fadeAnimation.keyTimes = [0.0, 0.5, 0.75, 1.0]
            fadeAnimation.duration = animationDuration
            animationGroup.animations?.append(fadeAnimation)
        }
        
        return animationGroup
    }
    
    private func didFold() {
        isAnimating = false
        isExpanded = false
        didDismissMenuItems?(self)
    }

    // MARK: - Expand Menu Items
    
    fileprivate func expandMenuItems(animated: Bool = true) {
        willPresentMenuItems?(self)
        isAnimating = true
        
        if allowSounds {
            AudioServicesPlaySystemSound(expandingSound)
        }
        
        // Configure center button expanding
        // Copy the current center point and backup default center point
        centerButton.center = center
        defaultCenterPoint = center
        
        // Resize the frame
        frame = CGRect(origin: .zero, size: expandingSize)
        center = CGPoint(x: expandingSize.width / 2.0, y: expandingSize.height / 2.0)
        bottomView.frame = frame
        
        insertSubview(bottomView, belowSubview: centerButton)
        
        // center button rotation animation
        if animated, enabledExpandingAnimations.contains(.menuButtonRotation) {
            UIView.animate(withDuration: menuAnimationDuration) {
                self.centerButton.transform = CGAffineTransform(rotationAngle: CGFloat(-0.5 * Float.pi))
            }
        }
        
        // expanding animation
        let currentAngle: CGFloat = 90.0
        
        var lastDistance: CGFloat = 0.0
        var lastItemSize = centerButton.bounds.size
        
        for (index, item) in menuItems.enumerated() {
            item.delegate = self
            item.index = index
            item.transform = CGAffineTransform(translationX: 1.0, y: 1.0)
            item.alpha = 1.0
            
            // Add item to the view
            item.center = centerButton.center
            
            insertSubview(item, belowSubview: centerButton)
            
            let distance: CGFloat = makeDistanceFromCenterButton(item.bounds.size, lastDistance: lastDistance, lastItemSize: lastItemSize)
            lastDistance = distance
            lastItemSize = item.bounds.size
            let endPoint = makeEndPoint(distance, angle: currentAngle / 180.0)
            let farPoint = makeEndPoint(distance + 10.0, angle: currentAngle / 180.0)
            let nearPoint = makeEndPoint(distance - 5.0, angle: currentAngle / 180.0)
            
            if animated {
                // expand animation
                let expandingAnimation = makeExpandingAnimation(startingPoint: item.center, farPoint: farPoint, nearPoint: nearPoint, endPoint: endPoint)
                
                item.layer.add(expandingAnimation, forKey: "expandingAnimation")
            }
            
            item.center = endPoint
            item.titleTappedActionEnabled = titleTappedActionEnabled
            
            // Add Title Button
            if let titleButton = item.titleButton {
                titleButton.center = endPoint
                let margin = item.titleMargin
                
                let originX: CGFloat
                
                switch menuTitleDirection {
                case .left:
                    originX = endPoint.x - item.bounds.width / 2.0 - margin - titleButton.bounds.width
                case .right:
                    originX = endPoint.x + item.bounds.width / 2.0 + margin;
                }
                
                var titleButtonFrame: CGRect = titleButton.frame
                titleButtonFrame.origin.x = originX
                titleButton.frame = titleButtonFrame
                titleButton.alpha = 0.0
                
                insertSubview(titleButton, belowSubview: centerButton)
                
                if animated {
                    UIView.animate(withDuration: 0.3) {
                        titleButton.alpha = 1.0
                    }
                } else {
                    titleButton.alpha = 1
                }
            }
        }
        
        if animated {
            // show bottom view alpha animation
            UIView.animate(withDuration: menuAnimationDuration, delay: 0.0, options: .curveEaseIn, animations: { () -> Void in
                self.bottomView.effect = UIBlurEffect(style: self.bottomViewBlurEffectStyle)
            }, completion: { _ in
                self.didExpand()
            })
        } else {
            bottomView.effect = UIBlurEffect(style: self.bottomViewBlurEffectStyle)
            didExpand()
        }
    }
    
    fileprivate func makeExpandingAnimation(startingPoint: CGPoint, farPoint: CGPoint, nearPoint: CGPoint, endPoint: CGPoint) -> CAAnimationGroup {
        let animationDuration = menuAnimationDuration
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = []
        animationGroup.duration = animationDuration
        
        // Configure rotation animation
        if enabledExpandingAnimations.contains(.menuItemRotation) {
            let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.values = [0.0, -Double.pi, -Double.pi * 1.5, -Double.pi  * 2.0]
            rotationAnimation.duration = animationDuration
            rotationAnimation.keyTimes = [0.0, 0.3, 0.6, 1.0]
            
            animationGroup.animations?.append(rotationAnimation)
        }
        
        // Configure moving animation
        let movingAnimation = CAKeyframeAnimation(keyPath: "position")
        let path = CGMutablePath()
        
        if enabledExpandingAnimations.contains([.menuItemMoving, .menuItemBound]) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: farPoint.x, y: farPoint.y))
            path.addLine(to: CGPoint(x: nearPoint.x, y: nearPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.5, 0.7, 1.0]
        } else if enabledExpandingAnimations.contains(.menuItemMoving) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.5, 1.0]
        } else if enabledExpandingAnimations.contains(.menuItemBound) {
            path.move(to: CGPoint(x: farPoint.x, y: farPoint.y))
            path.addLine(to: CGPoint(x: nearPoint.x, y: nearPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.3, 0.5, 1.0]
        } else if enabledExpandingAnimations.contains(.menuItemFade) {
            path.move(to: CGPoint(x: endPoint.x, y: endPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
        }
        
        movingAnimation.path = path
        movingAnimation.duration = animationDuration
        
        animationGroup.animations?.append(movingAnimation)
        
        // Configure fade animation
        if enabledExpandingAnimations.contains(.menuItemFade) {
            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [0.0, 1.0]
            fadeAnimation.duration = animationDuration
            animationGroup.animations?.append(fadeAnimation)
        }
        
        return animationGroup
    }
    
    private func didExpand() {
        isAnimating = false
        isExpanded = true
        didPresentMenuItems?(self)
    }
    
    // MARK: - Misc
    
    /// Expands the menu items to present them
    public func presentMenuItems(animated: Bool = true) {
        if !isAnimating && !isExpanded {
            expandMenuItems(animated: animated)
        }
    }
    
    /// Folds the menu items to dismiss them
    public func dismissMenuItems(animated: Bool = true) {
        if !isAnimating && isExpanded {
            foldMenuItems(animated: animated)
        }
    }
    
    // MARK: - Touch Event
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Tap the bottom area, exec the fold animation
        foldMenuItems()
    }
    
    // MARK: - UIGestureRecognizer Delegate
    
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
