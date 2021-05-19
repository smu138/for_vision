//MIT License
//
//Copyright (c) 2017 John Sundell
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

import Foundation
import UIKit


public extension UIView {
    func animate(_ animations: [Animation]) {
        // Exit condition: once all animations have been performed, we can return
        guard !animations.isEmpty else {
            return
        }

        // Remove the first animation from the queue
        var animations = animations
        let animation = animations.removeFirst()

        // Perform the animation by calling its closure
        UIView.animate(withDuration: animation.duration, animations: {
            animation.closure(self)
        }, completion: { _ in
            // Recursively call the method, to perform each animation in sequence
            self.animate(animations)
        })
    }
}

public extension UIView {
    func animate(withSpring animations: [Animation], completion: @escaping () -> ()) {
        // Exit condition: once all animations have been performed, we can return
        guard !animations.isEmpty else {
            completion()
            return
        }
        
        // Remove the first animation from the queue
        var animations = animations
        let animation = animations.removeFirst()

        // Perform the animation by calling its closure
        UIView.animate(
            withDuration: animation.duration,
            delay: 0.0,
            usingSpringWithDamping: 0.3,
            initialSpringVelocity: 6.0,
            options: UIView.AnimationOptions.curveEaseInOut,
            animations: { [unowned self] in
                animation.closure(self)
            },
            completion: { _ in
                // Recursively call the method, to perform each animation in sequence
                self.animate(withSpring: animations, completion: completion)
           }
        )

    }
}

public extension UIView {
    func animate(inParallel animations: [Animation]) {
        for animation in animations {
            UIView.animate(withDuration: animation.duration) {
                animation.closure(self)
            }
        }
    }
}
