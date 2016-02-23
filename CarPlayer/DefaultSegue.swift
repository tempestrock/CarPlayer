//
//  DefaultSegue.swift
//  CarPlayer
//
//  Created by Peter Störmer on 28.01.15.
//  Copyright (c) 2015 Tempest Rock Studios. All rights reserved.
//

import UIKit

//
// A default segue class that does not do anything important.
// It's mainly necessary to get rid of the warning that a custom segue needs a custom segue class.
//
class DefaultSegue: UIStoryboardSegue {

    override func perform() {

        let sourceViewController: UIViewController = self.sourceViewController 
        let destinationViewController: UIViewController = self.destinationViewController 
        sourceViewController.view.addSubview(destinationViewController.view)
        destinationViewController.view.removeFromSuperview()
      //  destinationViewController.view.removeFromSuperview()

        // Force presentViewController() into a different runloop.
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.001 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {
            sourceViewController.presentViewController(destinationViewController, animated: true, completion: nil)
        }
    }
}
