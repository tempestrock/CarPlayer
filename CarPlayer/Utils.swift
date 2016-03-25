//
//  Utils.swift
//  CarPlayer
//
//  Created by Peter Störmer on 23.12.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

import Foundation
import UIKit


extension UIView {

    //
    // Animates the item to shake by strongly shaking and returning to the original position.
    // Once the animation has finished, the completion function is called (if not nil).
    //
    class func animateStrongShake(itemToShake: UIView, completion: ((Bool) -> Void)?) {

        let durationForOneDirection: NSTimeInterval = 0.1
        let dampingForSwings: CGFloat = 0.3
        let dampingForEnd: CGFloat = 0.1
        let shakeWidth: CGFloat = 0.05

        UIView.animateWithDuration(
            durationForOneDirection,
            delay: 0.0,
            usingSpringWithDamping: dampingForSwings,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                itemToShake.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * shakeWidth)

            },
            completion: nil
        )

        UIView.animateWithDuration(
            durationForOneDirection,
            delay: durationForOneDirection,
            usingSpringWithDamping: dampingForSwings,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                itemToShake.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * (-1) * shakeWidth)

            },
            completion: nil
        )

        UIView.animateWithDuration(
            durationForOneDirection,
            delay: 2 * durationForOneDirection,
            usingSpringWithDamping: dampingForEnd,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                itemToShake.transform = CGAffineTransformMakeRotation(0.0)
                
            },
            completion: completion
        )
    }


    //
    // Animates the item to shrink by slightly shrinking and then returns to the original position.
    // Once the animation has finished, the completion function is called (if not nil).
    //
    class func animateSlightShrink(itemToShrink: UIView, completion: ((Bool) -> Void)?) {

        let shrinkingFactor: CGFloat = 0.025

        animateWithShrink(itemToShrink, shrinkingFactor: shrinkingFactor, completion: completion)
    }


    //
    // Animates the item to shrink tinily and then returns to the original position.
    // Once the animation has finished, the completion function is called (if not nil).
    //
    class func animateTinyShrink(itemToShrink: UIView, completion: ((Bool) -> Void)?) {

        let shrinkingFactor: CGFloat = 0.01

        animateWithShrink(itemToShrink, shrinkingFactor: shrinkingFactor, completion: completion)
    }
    
    
    //
    // Animates the item to shrink by the given shrinking factor and then returns to the original position.
    // Once the animation has finished, the completion function is called (if not nil).
    //
    class func animateWithShrink(itemToShrink: UIView, shrinkingFactor: CGFloat, completion: ((Bool) -> Void)?) {

        let durationForOneDirection: NSTimeInterval = 0.1
        let dampingForSwings: CGFloat = 0.3
        let dampingForEnd: CGFloat = 0.05

        UIView.animateWithDuration(
            durationForOneDirection,
            delay: 0.0,
            usingSpringWithDamping: dampingForSwings,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                itemToShrink.transform = CGAffineTransformMakeScale(1.0 - shrinkingFactor, 1.0 - shrinkingFactor)

            },
            completion: nil
        )

        UIView.animateWithDuration(
            durationForOneDirection,
            delay: durationForOneDirection,
            usingSpringWithDamping: dampingForSwings,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                itemToShrink.transform = CGAffineTransformMakeScale(1.0 + shrinkingFactor, 1.0 + shrinkingFactor)

            },
            completion: nil
        )

        UIView.animateWithDuration(
            durationForOneDirection,
            delay: 2 * durationForOneDirection,
            usingSpringWithDamping: dampingForEnd,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                itemToShrink.transform = CGAffineTransformMakeScale(1.0, 1.0)

            },
            completion: completion
        )
    }


    //
    // Animates the item to shrink tinily and then returns to the original position.
    // Once the animation has finished, the completion function is called (if not nil).
    //
    class func animateSlightGrowthInYDir(itemToGrow: UIView, completion: ((Bool) -> Void)?) {

        let growthFactor: CGFloat = 1.25

        animateWithGrowth(itemToGrow, growthFactorX: 0.0, growthFactorY: growthFactor, completion: completion)
    }
    
    
    //
    // Animates the item to grow by the given growth factors and then returns to the original position.
    // Once the animation has finished, the completion function is called (if not nil).
    //
    class func animateWithGrowth(itemToGrow: UIView, growthFactorX: CGFloat, growthFactorY: CGFloat, completion: ((Bool) -> Void)?) {

        let durationForOneDirection: NSTimeInterval = 0.1
        let dampingForSwings: CGFloat = 0.3
        let dampingForEnd: CGFloat = 0.05

        UIView.animateWithDuration(
            durationForOneDirection,
            delay: 0.0,
            usingSpringWithDamping: dampingForSwings,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                itemToGrow.transform = CGAffineTransformMakeScale(1.0 + growthFactorX, 1.0 + growthFactorY)

            },
            completion: nil
        )
/*
        UIView.animateWithDuration(
            durationForOneDirection,
            delay: durationForOneDirection,
            usingSpringWithDamping: dampingForSwings,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                itemToGrow.transform = CGAffineTransformMakeScale(1.0 - growthFactorX, 1.0 - growthFactorY)

            },
            completion: nil
        )
*/
        UIView.animateWithDuration(
            durationForOneDirection,
            delay: 2 * durationForOneDirection,
            usingSpringWithDamping: dampingForEnd,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                itemToGrow.transform = CGAffineTransformMakeScale(1.0, 1.0)
                
            },
            completion: completion
        )
    }


    //
    // Animates the item to move out by driving it to the left out of the screen.
    //
    class func animateMoveOutToLeft(itemToMoveOut: UIView, completion: ((Bool) -> Void)?) {

        let durationForOneDirection: NSTimeInterval = 0.2

        UIView.animateWithDuration(
            durationForOneDirection,
            delay: 0.0,
            options: UIViewAnimationOptions.CurveEaseIn,
            animations: {
                itemToMoveOut.transform = CGAffineTransformMakeTranslation(-1.0 * CGFloat(MyBasics.screenWidth), 0.0)

            },
            completion: completion
        )

    }


    //
    // Animates the display of a label that is too long to be displayed at once and needs to be shifted back and forth.
    //
    class func animateLongishLabel(
        labelToAnimate: UILabel, frameAroundLabel: CGRect,
        timeForAnimation: Double, timeToWaitForNextAnimation: Double,
        totalWidth: CGFloat) {

        // print("piep: \(timeForAnimation), \(timeToWaitForNextAnimation), \(frameAroundLabel), \(totalWidth)")

        // Move text to the left:
        UIView.animateWithDuration(
            timeForAnimation / 2.0,
            delay: timeToWaitForNextAnimation,
            options: [],
            animations: {

                labelToAnimate.frame = CGRect(x: frameAroundLabel.width * (-1.0) + totalWidth, y: 0,
                    width: frameAroundLabel.width,
                    height: frameAroundLabel.height)

            },
            completion: nil)


        // Move text to the right:
        UIView.animateWithDuration(
            timeForAnimation / 2.0,
            delay: timeForAnimation / 2.0 + 2 * timeToWaitForNextAnimation,
            options: [],
            animations: {

                labelToAnimate.frame = CGRect(x: 0, y: 0,
                    width: frameAroundLabel.width,
                    height: frameAroundLabel.height)
                
            },
            completion: nil)
    }


    //
    // Scrolls the given scrollView immediately to the given point in a smooth way.
    //
    class func slideSmoothlyToPosition(scrollView: UIScrollView, pointToSlideTo: CGPoint) {

        slideSmoothlyToPosition(scrollView, delay: 0.0, pointToSlideTo: pointToSlideTo)
        
    }
    

    //
    // Scrolls the given scrollView with the given delay to the given point in a smooth way.
    //
    class func slideSmoothlyToPosition(scrollView: UIScrollView, delay: Double, pointToSlideTo: CGPoint) {

        let durationForOneDirection: NSTimeInterval = 0.2
        UIView.animateWithDuration(
            durationForOneDirection,
            delay: delay,
            options: UIViewAnimationOptions.CurveEaseOut,
            animations: {
                scrollView.contentOffset = pointToSlideTo
            },
            completion: nil
        )
    }


/*
    //
    // Slides the given ui view to the given point.
    //
    class func slideSmoothlyToPosition(uiView: UIView, pointToSlideTo: CGPoint, completion: (((Bool) -> Void)?) = nil) {

        slideSmoothlyToPosition(UIView, delay: 0.0, frameToSlideTo: CGRectMake(point: , completion: completion)
    }

*/
    //
    // Jumps the given ui view to the given frame in a "springy" way.
    //
    class func slideSmoothlyToPosition(uiView: UIView, delay: Double, frameToSlideTo: CGRect, completion: (((Bool) -> Void)?) = nil) {

        let durationForOneDirection: NSTimeInterval = 0.2
        UIView.animateWithDuration(
            durationForOneDirection,
            delay: delay,
            options: UIViewAnimationOptions.CurveEaseOut,
            animations: {
                uiView.frame = frameToSlideTo
            },
            completion: completion
        )
    }
    //
    // Scrolls the given scrollView immediately to the given point in a "springy" way.
    //
    class func jumpSpringyToPosition(scrollView: UIScrollView, pointToJumpTo: CGPoint) {

        jumpSpringyToPosition(scrollView, delay: 0.0, pointToJumpTo: pointToJumpTo)

    }


    //
    // Scrolls the given scrollView with the given delay to the given point in a "springy" way.
    //
    class func jumpSpringyToPosition(scrollView: UIScrollView, delay: Double, pointToJumpTo: CGPoint) {

        let durationForOneDirection: NSTimeInterval = 0.6
        let dampingForEnd: CGFloat = 0.3
        let springVelocity: CGFloat = 0.0
        UIView.animateWithDuration(
            durationForOneDirection,
            delay: delay,
            usingSpringWithDamping: dampingForEnd,
            initialSpringVelocity: springVelocity,
            options: UIViewAnimationOptions.CurveEaseOut,
            animations: {
                scrollView.contentOffset = pointToJumpTo
            },
            completion: nil
        )
    }


    //
    // Jumps the given ui view to the given frame in a "springy" way.
    //
    class func jumpSpringyToPosition(uiView: UIView, delay: Double, frameToJumpTo: CGRect, completion: (((Bool) -> Void)?) = nil) {

        let durationForOneDirection: NSTimeInterval = 0.6
        let dampingForEnd: CGFloat = 0.3
        let springVelocity: CGFloat = 0.0
        UIView.animateWithDuration(
            durationForOneDirection,
            delay: delay,
            usingSpringWithDamping: dampingForEnd,
            initialSpringVelocity: springVelocity,
            options: UIViewAnimationOptions.CurveEaseOut,
            animations: {
                uiView.frame = frameToJumpTo
            },
            completion: completion
        )
    }
}


extension Double {

    //
    // Adds a formatting function to Double
    //
    func format(f: String) -> String {
        return NSString(format: "%\(f)f", self) as String
    }
}


extension Int {

    //
    // Adds a formatting function to Int
    //
    func format(f: String) -> String {
        return NSString(format: "%\(f)d", self) as String
    }
}


extension UIImage {

    //
    // Returns the pixel color of a UIImage at the given position.
    //
    func getPixelColor(pos: CGPoint) -> UIColor {

        var r: CGFloat
        var g: CGFloat
        var b: CGFloat
        var a: CGFloat

        (r, g, b, a) = getPixelColorValues(pos)

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }


    //
    // Returns the pixel color values of a UIImage at the given position.
    //
    func getPixelColorValues(pos: CGPoint) -> (CGFloat, CGFloat, CGFloat, CGFloat) {

        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4

        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)

        return (r, g, b, a)
    }
}



extension UIColor {
    
    //
    // Returns some strange self-created lightness factor that can be directly used for darkening the color.
    // The higher the value the lighter is the color.
    //
    func lightnessFactor() -> Double {

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        // Get the components of the color:
        getRed(&r, green: &g, blue: &b, alpha: &a)

        let product: CGFloat = r * g * b
        let twoValuesAreHigh: Bool = ((r * g > 0.8) || (r * b > 0.8) || (g * b > 0.8))

        // DEBUG print("UIColor.isLightColor(): product = \(product), twoValuesAreHigh: \(twoValuesAreHigh)")

        if product < 0.3 && twoValuesAreHigh {

            // Although the product is rather low we return a higher value because two of the r,g,b values are quite high
            // and one is very low. This means something like e.g. a very intense yellow:
            return 0.4
        }

        if product < 0.17 {
            return 0.0
        } else if product < 0.3 {
            return 0.2
        } else if product < 0.65 {
            return 0.4
        } else if product < 0.85 {
            return 0.6
        } else {
            return 0.8
        }
    }


    //
    // Returns a randomly generated dark color
    //
    class func randomDarkColor() -> UIColor {

        // Create three values between 0 and 0.5:
        let r: CGFloat = CGFloat(arc4random_uniform(1000)) / 2000.0
        let g: CGFloat = CGFloat(arc4random_uniform(1000)) / 2000.0
        let b: CGFloat = CGFloat(arc4random_uniform(1000)) / 2000.0

        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }


    //
    // Returns a nice dark-ish blue.
    //
    class func darkBlueColor() -> UIColor {

        let r: CGFloat = 0.0
        let g: CGFloat = 0.0
        let b: CGFloat = CGFloat(0.2)

        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
