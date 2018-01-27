//
//  ExpandingMenuButton.swift
//
//  Created by monoqlo on 2015/07/21.
//  Copyright (c) 2015年 monoqlo All rights reserved.
//

import UIKit
import AudioToolbox

public struct AnimationOptions : OptionSet {
    public let rawValue: Int
    
    public static let MenuItemRotation = AnimationOptions(rawValue: 1)
    public static let MenuItemBound = AnimationOptions(rawValue: 2)
    public static let MenuItemMoving = AnimationOptions(rawValue: 4)
    public static let MenuItemFade = AnimationOptions(rawValue: 8)
    public static let MenuButtonRotation = AnimationOptions(rawValue: 16)
    
    public static let Default: AnimationOptions = [MenuItemRotation, MenuItemBound, MenuItemMoving, MenuButtonRotation]
    public static let All: AnimationOptions = [MenuItemRotation, MenuItemBound, MenuItemMoving, MenuItemFade, MenuButtonRotation]
    
    public init(rawValue: Int) { self.rawValue = rawValue }
}

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
    open var menuAnimationDuration: CFTimeInterval = 0.35
    open var menuItemMargin: CGFloat = 16.0
    
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
    
    open var bottomViewColor: UIColor = UIColor.black {
        didSet {
            bottomView.backgroundColor = bottomViewColor
        }
    }
    
    open var bottomViewAlpha: CGFloat = 0.618
    
    open var titleTappedActionEnabled: Bool = true
    
    open var expandingDirection: ExpandingDirection = .top
    open var menuTitleDirection: MenuTitleDirection = .left
    
    open var enabledExpandingAnimations: AnimationOptions = .Default
    open var enabledFoldingAnimations: AnimationOptions = .Default
    
    open var willPresentMenuItems: ((ExpandingMenuButton) -> Void)?
    open var didPresentMenuItems: ((ExpandingMenuButton) -> Void)?
    open var willDismissMenuItems: ((ExpandingMenuButton) -> Void)?
    open var didDismissMenuItems: ((ExpandingMenuButton) -> Void)?
    
    // MARK: Private Properties
    fileprivate var defaultCenterPoint: CGPoint = CGPoint.zero
    
    fileprivate var itemButtonImages: [UIImage] = []
    fileprivate var itemButtonHighlightedImages: [UIImage] = []
    
    fileprivate var centerImage: UIImage?
    fileprivate var centerHighlightedImage: UIImage?
    
    fileprivate var expandingSize: CGSize = UIScreen.main.bounds.size
    fileprivate var foldedSize: CGSize = CGSize.zero
    
    fileprivate var bottomView: UIView = UIView()
    fileprivate var centerButton: UIButton = UIButton()
    fileprivate var menuItems: [ExpandingMenuItem] = []
    
    fileprivate var foldSound: SystemSoundID = 0
    fileprivate var expandingSound: SystemSoundID = 0
    fileprivate var selectedSound: SystemSoundID = 0
    
    fileprivate var isExpanding: Bool = false
    fileprivate var isAnimating: Bool = false
    
    
    // MARK: - Initializer
    public init(frame: CGRect, centerImage: UIImage, centerHighlightedImage: UIImage) {
        super.init(frame: frame)
        
        func configureViewsLayoutWithButtonSize(_ centerButtonSize: CGSize) {
            // Configure menu button frame
            //
            foldedSize = centerButtonSize
            self.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: foldedSize.width, height: foldedSize.height);
            
            // Congifure center button
            //
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
            //
            bottomView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: expandingSize.width, height: expandingSize.height))
            bottomView.backgroundColor = bottomViewColor
            bottomView.alpha = 0.0
            
            // Make bottomView's touch can delay superView witch like UIScrollView scrolling
            //
            bottomView.isUserInteractionEnabled = true;
            let tapGesture = UIGestureRecognizer()
            tapGesture.delegate = self
            bottomView.addGestureRecognizer(tapGesture)
        }
        
        // Configure enter and highlighted center image
        //
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
    
    public convenience init(centerImage: UIImage, centerHighlightedImage: UIImage) {
        self.init(frame: CGRect.zero, centerImage: centerImage, centerHighlightedImage: centerHighlightedImage)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Configure Menu Items
    open func addMenuItems(_ menuItems: [ExpandingMenuItem]) {
        self.menuItems += menuItems
    }
    
    // MARK: - Menu Item Tapped Action
    open func menuItemTapped(_ item: ExpandingMenuItem) {
        willDismissMenuItems?(self)
        isAnimating = true
        
        let selectedIndex: Int = item.index
        
        if allowSounds {
            AudioServicesPlaySystemSound(selectedSound)
        }
        
        // Excute the explode animation when the item is seleted
        //
        UIView.animate(withDuration: 0.0618 * 5.0, animations: { () -> Void in
            item.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
            item.alpha = 0.0
        })
        
        // Excute the dismiss animation when the item is unselected
        //
        for (index, item) in menuItems.enumerated() {
            // Remove title button
            //
            if let titleButton = item.titleButton {
                UIView.animate(withDuration: 0.15, animations: { () -> Void in
                    titleButton.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        titleButton.removeFromSuperview()
                })
            }
            
            if index == selectedIndex {
                continue
            }
            
            UIView.animate(withDuration: 0.0618 * 2.0, animations: { () -> Void in
                item.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
            })
        }
        
        resizeToFoldedFrame { () -> Void in
            self.isAnimating = false
            self.didDismissMenuItems?(self)
        }
    }
    
    // MARK: - Center Button Action
    @objc fileprivate func centerButtonTapped() {
        if !isAnimating {
            if isExpanding {
                foldMenuItems()
            } else {
                expandMenuItems()
            }
        }
    }
    
    // MARK: - Configure Sounds
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
    
    // MARK: - Calculate The Distance From Center Button
    fileprivate func makeDistanceFromCenterButton(_ itemSize: CGSize, lastDistance: CGFloat, lastItemSize: CGSize) -> CGFloat {
        return lastDistance + itemSize.height / 2.0 + menuItemMargin + lastItemSize.height / 2.0
    }
    
    // MARK: - Caculate The Item's End Point
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
    fileprivate func foldMenuItems() {
        willDismissMenuItems?(self)
        isAnimating = true
        
        if allowSounds {
            AudioServicesPlaySystemSound(foldSound)
        }
        
        let currentAngle: CGFloat = 90.0
        
        var lastDistance: CGFloat = 0.0
        var lastItemSize: CGSize = centerButton.bounds.size
        
        for item in menuItems {
            let distance: CGFloat = makeDistanceFromCenterButton(item.bounds.size, lastDistance: lastDistance, lastItemSize: lastItemSize)
            lastDistance = distance
            lastItemSize = item.bounds.size
            let backwardPoint: CGPoint = makeEndPoint(distance + 5.0, angle: currentAngle / 180.0)
            
            let foldAnimation: CAAnimationGroup = makeFoldAnimation(startingPoint: item.center, backwardPoint: backwardPoint, endPoint: centerButton.center)
            
            item.layer.add(foldAnimation, forKey: "foldAnimation")
            item.center = centerButton.center
            
            // Remove title button
            //
            if let titleButton = item.titleButton {
                UIView.animate(withDuration: 0.15, animations: { () -> Void in
                    titleButton.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        titleButton.removeFromSuperview()
                })
            }
        }
        
        bringSubview(toFront: centerButton)
        
        // Resize the ExpandingMenuButton's frame to the foled frame and remove the item buttons
        //
        resizeToFoldedFrame {
            self.isAnimating = false
            self.didDismissMenuItems?(self)
        }
    }
    
    fileprivate func resizeToFoldedFrame(completion: (() -> Void)?) {
        if enabledFoldingAnimations.contains(.MenuButtonRotation) {
            UIView.animate(withDuration: 0.0618 * 3, delay: 0.0618 * 2, options: .curveEaseIn, animations: { () -> Void in
                self.centerButton.transform = CGAffineTransform(rotationAngle: 0.0)
                }, completion: nil)
        } else {
            centerButton.transform = CGAffineTransform(rotationAngle: 0.0)
        }
        
        UIView.animate(withDuration: 0.15, delay: 0.35, options: .curveLinear, animations: { () -> Void in
            self.bottomView.alpha = 0.0
            }, completion: { _ in
                // Remove the items from the superview
                //
                for item in self.menuItems {
                    item.removeFromSuperview()
                }
                
                self.frame = CGRect(x: 0.0, y: 0.0, width: self.foldedSize.width, height: self.foldedSize.height)
                self.center = self.defaultCenterPoint
                
                self.centerButton.center = CGPoint(x: self.frame.width / 2.0, y: self.frame.height / 2.0)
                
                self.bottomView.removeFromSuperview()
                
                completion?()
        })
        
        isExpanding = false
    }
    
    fileprivate func makeFoldAnimation(startingPoint: CGPoint, backwardPoint: CGPoint, endPoint: CGPoint) -> CAAnimationGroup {
        let animationDuration = menuAnimationDuration
        let animationGroup: CAAnimationGroup = CAAnimationGroup()
        animationGroup.animations = []
        animationGroup.duration = animationDuration
        
        // 1.Configure rotation animation
        //
        if enabledFoldingAnimations.contains(.MenuItemRotation) {
            let rotationAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.values = [0.0, Double.pi, Double.pi * 2.0]
            rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            rotationAnimation.duration = animationDuration
            
            animationGroup.animations?.append(rotationAnimation)
        }
        
        // 2.Configure moving animation
        //
        let movingAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
        
        // Create moving path
        //
        let path: CGMutablePath = CGMutablePath()
        
        if enabledFoldingAnimations.contains([.MenuItemMoving, .MenuItemBound]) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: backwardPoint.x, y: backwardPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.75, 1.0]
        } else if enabledFoldingAnimations.contains(.MenuItemMoving) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.75, 1.0]
        } else if enabledFoldingAnimations.contains(.MenuItemBound) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: backwardPoint.x, y: backwardPoint.y))
            path.addLine(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.3, 0.5, 1.0]
        } else if enabledFoldingAnimations.contains(.MenuItemFade) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
        }
        
        movingAnimation.path = path
        movingAnimation.duration = animationDuration
        
        animationGroup.animations?.append(movingAnimation)
        
        // 3.Configure fade animation
        //
        if enabledFoldingAnimations.contains(.MenuItemFade) {
            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [1.0, 0.0]
            fadeAnimation.keyTimes = [0.0, 0.75, 1.0]
            fadeAnimation.duration = animationDuration
            animationGroup.animations?.append(fadeAnimation)
        }
        
        return animationGroup
    }
    
    
    // MARK: - Expand Menu Items
    fileprivate func expandMenuItems() {
        willPresentMenuItems?(self)
        isAnimating = false
        
        if allowSounds {
            AudioServicesPlaySystemSound(expandingSound)
        }
        
        // Configure center button expanding
        //
        // 1. Copy the current center point and backup default center point
        //
        centerButton.center = center
        defaultCenterPoint = center
        
        // 2. Resize the frame
        //
        frame = CGRect(x: 0.0, y: 0.0, width: expandingSize.width, height: expandingSize.height)
        center = CGPoint(x: expandingSize.width / 2.0, y: expandingSize.height / 2.0)
        
        insertSubview(bottomView, belowSubview: centerButton)
        
        // 3. show bottom view alpha animation
        //
        UIView.animate(withDuration: 0.0618 * menuAnimationDuration, delay: 0.0, options: .curveEaseIn, animations: { () -> Void in
            self.bottomView.alpha = self.bottomViewAlpha
            }, completion: nil)
        
        // 4. center button rotation animation
        //
        if enabledExpandingAnimations.contains(.MenuButtonRotation) {
            UIView.animate(withDuration: 0.1575) {
                self.centerButton.transform = CGAffineTransform(rotationAngle: CGFloat(-0.5 * Float.pi))
            }
        } else {
            centerButton.transform = CGAffineTransform(rotationAngle: CGFloat(-0.5 * Float.pi))
        }
        
        // 5. expanding animation
        //
        let currentAngle: CGFloat = 90.0
        
        var lastDistance: CGFloat = 0.0
        var lastItemSize: CGSize = centerButton.bounds.size
        
        for (index, item) in menuItems.enumerated() {
            item.delegate = self
            item.index = index
            item.transform = CGAffineTransform(translationX: 1.0, y: 1.0)
            item.alpha = 1.0
            
            // 1. Add item to the view
            //
            item.center = centerButton.center
            
            insertSubview(item, belowSubview: centerButton)
            
            // 2. expand animation
            //
            let distance: CGFloat = makeDistanceFromCenterButton(item.bounds.size, lastDistance: lastDistance, lastItemSize: lastItemSize)
            lastDistance = distance
            lastItemSize = item.bounds.size
            let endPoint: CGPoint = makeEndPoint(distance, angle: currentAngle / 180.0)
            let farPoint: CGPoint = makeEndPoint(distance + 10.0, angle: currentAngle / 180.0)
            let nearPoint: CGPoint = makeEndPoint(distance - 5.0, angle: currentAngle / 180.0)
            
            let expandingAnimation: CAAnimationGroup = makeExpandingAnimation(startingPoint: item.center, farPoint: farPoint, nearPoint: nearPoint, endPoint: endPoint)
            
            item.layer.add(expandingAnimation, forKey: "expandingAnimation")
            item.center = endPoint
            
            // 3. Add Title Button
            //
            item.titleTappedActionEnabled = titleTappedActionEnabled
            
            if let titleButton = item.titleButton {
                titleButton.center = endPoint
                let margin: CGFloat = item.titleMargin
                
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
                
                UIView.animate(withDuration: 0.3) {
                    titleButton.alpha = 1.0
                }
            }
        }
        
        // Configure the expanding status
        //
        isExpanding = true
        isAnimating = false
        
        didPresentMenuItems?(self)
    }
    
    fileprivate func makeExpandingAnimation(startingPoint: CGPoint, farPoint: CGPoint, nearPoint: CGPoint, endPoint: CGPoint) -> CAAnimationGroup {
        let animationDuration = menuAnimationDuration - 0.5 // 0.3
        let animationGroup: CAAnimationGroup = CAAnimationGroup()
        animationGroup.animations = []
        animationGroup.duration = animationDuration
        
        // 1.Configure rotation animation
        //
        if enabledExpandingAnimations.contains(.MenuItemRotation) {
            let rotationAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.values = [0.0, -Double.pi, -Double.pi * 1.5, -Double.pi  * 2.0]
            rotationAnimation.duration = animationDuration
            rotationAnimation.keyTimes = [0.0, 0.3, 0.6, 1.0]
            
            animationGroup.animations?.append(rotationAnimation)
        }
        
        // 2.Configure moving animation
        //
        let movingAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
        
        // Create moving path
        //
        let path: CGMutablePath = CGMutablePath()
        
        if enabledExpandingAnimations.contains([.MenuItemMoving, .MenuItemBound]) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: farPoint.x, y: farPoint.y))
            path.addLine(to: CGPoint(x: nearPoint.x, y: nearPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.5, 0.7, 1.0]
        } else if enabledExpandingAnimations.contains(.MenuItemMoving) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.5, 1.0]
        } else if enabledExpandingAnimations.contains(.MenuItemBound) {
            path.move(to: CGPoint(x: farPoint.x, y: farPoint.y))
            path.addLine(to: CGPoint(x: nearPoint.x, y: nearPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.3, 0.5, 1.0]
        } else if enabledExpandingAnimations.contains(.MenuItemFade) {
            path.move(to: CGPoint(x: endPoint.x, y: endPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
        }
        
        movingAnimation.path = path
        movingAnimation.duration = animationDuration
        
        animationGroup.animations?.append(movingAnimation)
        
        // 3.Configure fade animation
        //
        if enabledExpandingAnimations.contains(.MenuItemFade) {
            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [0.0, 1.0]
            fadeAnimation.duration = animationDuration
            animationGroup.animations?.append(fadeAnimation)
        }
        
        return animationGroup
    }
    
    // MARK: - Touch Event
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Tap the bottom area, excute the fold animation
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
