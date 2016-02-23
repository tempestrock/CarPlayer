//
//  ModalViewController.swift
//  CarPlayer
//
//  Created by Peter Störmer on 22.12.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

import Foundation
import UIKit


//
// Some basics for a modal view.
//
class ModalViewController: UIViewController {

    // Dimensions:
    var widthOfView: Int {
        get {
            return MyBasics.screenWidth * 90 / 100
        }
    }

    var heightOfView: Int {
        get {
            return MyBasics.screenHeight * 90 / 100
        }
    }

    var xPosOfView: Int {
        get {
            return (MyBasics.screenWidth - widthOfView) / 2
        }
    }

    var yPosOfView: Int {
        get {
            return (MyBasics.screenHeight - heightOfView) / 2
        }
    }


    //
    // Paint the basic stuff, i.e. the black opaque box and an underlying close button.
    // 
    override func viewDidLoad() {
        super.viewDidLoad()

        paintBasics(view)
        
    }


    //
    // Paints a "close" button and the underlying black rectangle.
    //
    func paintBasics(view: UIView) {

        // Create an underlying button that closes the view without further action:
        let closeButton = UIButton(type: UIButtonType.Custom)
        closeButton.frame = CGRectMake(0.0, 0.0, CGFloat(MyBasics.screenWidth), CGFloat(MyBasics.screenHeight))
        closeButton.addTarget(self, action: Selector("closeViewWithoutAction"), forControlEvents: .TouchUpInside)
        view.addSubview(closeButton)

        // Create white, opaque background rectangle:
        let imageSize = CGSize(width: widthOfView, height: heightOfView)
        let image = drawBlackOpaqueBox(imageSize)

        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: xPosOfView, y: yPosOfView), size: imageSize))
        imageView.image = image
        view.addSubview(imageView)
    }


    //
    // Draws the black but slightly opaque box as the background.
    //
    func drawBlackOpaqueBox(size: CGSize) -> UIImage {
        // Setup our context
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let context = UIGraphicsGetCurrentContext()

        // Setup complete, do drawing here
        CGContextSetLineWidth(context, 0.0)
        CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextSetAlpha(context, 0.8)
        CGContextFillRect(context, bounds)

        // Drawing complete, retrieve the finished image and cleanup
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    
    //
    // Closes the view without any further action.
    //
    func closeViewWithoutAction() {

        dismissViewControllerAnimated(true, completion: nil)
    }

}