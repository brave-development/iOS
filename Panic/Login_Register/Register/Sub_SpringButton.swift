//
//  Sub_SpringButton.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/07/26.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import Spring

class Sub_SpringButton: SpringButton {
    
    func hideWithDuration(duration: Double = 0.6) {
        if alpha == 1 {
            UIView.animate(withDuration: duration, animations: {
                self.alpha = 0
            })
        }
    }
    
    func showWithAnimation(fadeDuration: Double = 0.5, animationDuration: CGFloat = 1, animation: String) {
        if alpha == 0 {
            UIView.animate(withDuration: fadeDuration, animations: {
                self.alpha = 1
            })
            self.animation = animation
            duration = animationDuration
            animate()
        }
    }
    
}
