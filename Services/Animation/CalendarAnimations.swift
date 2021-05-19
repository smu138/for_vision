//
//  CalendarAnimations.swift
//
//  Created by Admin on 30.06.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import UIKit

public extension Animation {
    
    static func popupOnCenter (
        duration: TimeInterval = 0.3,
        widthConstraint: NSLayoutConstraint,
        widthValue: CGFloat,
        heightConstraint: NSLayoutConstraint,
        heightValue: CGFloat
    ) -> Animation {

        widthConstraint.constant = widthValue
        heightConstraint.constant = heightValue
        
        return Animation(duration: duration, closure: { (uiView) in
            uiView.layoutIfNeeded()
        })
    }

    static func moveToTop (
        duration: TimeInterval = 0.3,
        centerYAnchor: NSLayoutConstraint,
        centerConstantValue: CGFloat
    ) -> Animation {
        
        centerYAnchor.constant = centerConstantValue
        
        return Animation(duration: duration) { (uiView) in
            uiView.layoutIfNeeded()
        }
    }
    
    static func show (duration: TimeInterval = 0.3, viewToHide: UIView) -> Animation {
        return Animation(duration: duration) { (uiView) in
            viewToHide.alpha = 1
        }
    }
    
    static func hide (duration: TimeInterval = 0.3, viewToHide: UIView) -> Animation {
        return Animation(duration: duration) { (uiView) in
            viewToHide.alpha = 0
        }
    }

}
