//
//  ExpandingMenuButtonItem.swift
//
//  Created by monoqlo on 2015/07/17.
//  Copyright (c) 2015年 monoqlo All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
open class ExpandingMenuItem: UIView {
    
    open var title: String? {
        get {
            return titleButton?.titleLabel?.text
        }
        
        set {
            if let title = newValue {
                if let titleButton = titleButton {
                    titleButton.setTitle(title, for: .normal)
                } else {
                    titleButton = createTitleButton(title, titleColor: titleColor)
                }
                
                titleButton?.sizeToFit()
            } else {
                titleButton = nil
            }
        }
    }
    
    open var titleMargin: CGFloat = 8.0
    
    open var titleColor: UIColor? {
        get {
            return titleButton?.titleColor(for: .normal)
        }
        
        set {
            titleButton?.setTitleColor(newValue, for: .normal)
        }
    }
    
    var titleTappedActionEnabled: Bool = true {
        didSet {
            titleButton?.isUserInteractionEnabled = titleTappedActionEnabled
        }
    }
    
    var index: Int = 0
    weak var delegate: ExpandingMenuButton?
    fileprivate(set) var titleButton:UIButton?
    fileprivate var frontImageView: UIImageView
    fileprivate var tappedAction: (() -> Void)?
    
    // MARK: - Initializer
    public init(size: CGSize?, title: String? = nil, titleColor: UIColor? = nil, image: UIImage, highlightedImage: UIImage?, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        
        // Initialize properties
        //
        frontImageView = UIImageView(image: image, highlightedImage: highlightedImage)
        tappedAction = itemTapped
        
        // Configure frame
        //
        var itemFrame: CGRect = .zero
        if let itemSize = size, itemSize != CGSize.zero {
            itemFrame.size = itemSize
        } else {
            if let bgImage = backgroundImage, backgroundHighlightedImage != nil {
                itemFrame.size = bgImage.size
            } else {
                itemFrame.size = image.size
            }
        }
        
        super.init(frame: itemFrame)
        
        // Configure base button
        //
        let baseButton = UIButton()
        if let backgroundImage = backgroundImage {
            baseButton.setImage(backgroundImage, for: .normal)
            baseButton.setImage(backgroundHighlightedImage, for: .highlighted)
        } else {
            baseButton.frame = itemFrame
        }
        
        baseButton.translatesAutoresizingMaskIntoConstraints = false
        baseButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        addSubview(baseButton)
        
        addConstraints([
            NSLayoutConstraint(item: baseButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: baseButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: baseButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: baseButton, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
            ])
        
        // Configure front images
        //
        frontImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(frontImageView)
        
        addConstraints([
            NSLayoutConstraint(item: frontImageView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: frontImageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: frontImageView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: frontImageView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
            ])
        
        // Configure title button
        //
        if let title = title {
            titleButton = createTitleButton(title, titleColor: titleColor)
        }
    }
    
    public convenience init(image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: nil, title: nil, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    public convenience init(title: String, titleColor: UIColor? = nil, image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: nil, title: title, titleColor: titleColor, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    public convenience init(size: CGSize, image: UIImage, highlightedImage: UIImage? = nil, backgroundImage: UIImage? = nil, backgroundHighlightedImage: UIImage? = nil, itemTapped: (() -> Void)?) {
        self.init(size: size, title: nil, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        frontImageView = UIImageView()
        
        super.init(coder: aDecoder)
    }
    
    // MARK: - Title Button
    fileprivate func createTitleButton(_ title: String, titleColor: UIColor? = nil) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        
        return button
    }
    
    // MARK: - Tapped Action
    func tapped() {
        delegate?.menuItemTapped(self)
        tappedAction?()
    }
}
