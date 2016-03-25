//
//  InitialViewController.swift
//  CarPlayer
//
//  Created by Peter Störmer on 27.02.15.
//  Copyright (c) 2015 Tempest Rock Studios. All rights reserved.
//

import Foundation
import UIKit

// ------------- Global variables -------------

// The singleton to save and load data from the disk:
var _savior = Savior()

// The controller is a global variable but used only once:
var _controller = MVC_Controller()

// Locator for coordinates and speed:
var _locator = Locator()

// A transition for a fancy animation between the actual music views:
let _rotatingTransition = TransitionManager_Rotating()

// A transition for the animation between the music views and the speed views:
let _slidingTransition = TransitionManager_Sliding()



//
// The class that handles the initially visible view.
//
class InitialViewController: UIViewController {

    // ----- Attributes -----

    var _backgroundImage: UIImageView!
    var _percentageLabel: UILabel!

    // The car icon and its movement and scaling transformation:
    var _carIcon: UIImageView!
    var _carIconTransformation: CGAffineTransform!

    var _previousLoadState: Double = 0

    // Timer that looks for the start conditions:
    var _waitToStartTimer: NSTimer!


    // ----- Methods -----

    //
    // This function is called whenever the app is started initially.
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        // DEBUG print("InitialViewController.viewDidLoad()")

        _backgroundImage = UIImageView(image: UIImage(named: MyBasics.nameOfImage_Launch))
        _backgroundImage.frame = CGRectMake(0.0, 0.0, CGFloat(MyBasics.screenWidth), CGFloat(MyBasics.screenHeight))
        view.addSubview(_backgroundImage)

        let titleLabel: UILabel = UILabel(frame: CGRectMake(0.0, 74.0, CGFloat(MyBasics.screenWidth), 125.0))
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.font = MyBasics.fontForHugeText
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.text = "Car Player"
        view.addSubview(titleLabel)

        let subTitleLabel: UILabel = UILabel(frame: CGRectMake(0.0, 318.0, CGFloat(MyBasics.screenWidth), 41.0))
        subTitleLabel.textColor = UIColor.lightGrayColor()
        subTitleLabel.font = MyBasics.fontForSmallText
        subTitleLabel.textAlignment = NSTextAlignment.Center
        subTitleLabel.text = "© 2014 - ∞  Tempest Rock Studios. All rights reserved."
        view.addSubview(subTitleLabel)

        _percentageLabel = UILabel(frame: CGRectMake(0.0, CGFloat(MyBasics.screenHeight)/2.0, CGFloat(MyBasics.screenWidth), 40.0))
        _percentageLabel.textColor = UIColor.whiteColor()
        _percentageLabel.font = MyBasics.fontForMediumText
        _percentageLabel.textAlignment = NSTextAlignment.Center
        view.addSubview(_percentageLabel)

        // Create the car icon in the middle of the map:
        _carIcon = UIImageView(image: UIImage(named: MyBasics.nameOfImage_CarIconFromBehind))
        _carIcon.frame = CGRectMake(CGFloat(MyBasics.screenWidth) - 1.7 * CGFloat(MyBasics.SpeedView_CarIcon_Width),
            CGFloat(MyBasics.screenHeight),
            MyBasics.SpeedView_CarIcon_Width, MyBasics.SpeedView_CarIcon_Height)
        _carIcon.alpha = 1.0
        _carIconTransformation = CGAffineTransformIdentity
        view.addSubview(_carIcon)

        // Start the checking timer:
        _waitToStartTimer = NSTimer.scheduledTimerWithTimeInterval(0.05,
                                                                   target: self,
                                                                   selector: #selector(InitialViewController.checkAllStartingConditions), userInfo: nil, repeats: true)
    }


    //
    // Checks whether or not all starting conditions have been reached. Switches to the main view if this is the case.
    //
    func checkAllStartingConditions() {

        // DEBUG print("InitialViewController.checkAllStartingConditions()")

        let loadState: Double = _controller.initialLoadState()
        _percentageLabel.text = "Loading music library: " + (Int(loadState*100.0)).description + "%"
        // DEBUG print("displaying \"\(_percentageLabel.text!)\"")

        if loadState != _previousLoadState {
                self._carIcon.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(1.0 - CGFloat(loadState), 1.0 - CGFloat(loadState)),
                    CGAffineTransformMakeTranslation(0.0, CGFloat(-loadState) * CGFloat(MyBasics.screenHeight) * 0.6))
        }

        if loadState == 1.0 {

            // DEBUG print("InitialViewController.checkAllStartingConditions(): Jumping to main view.")
            // Stop the timer:
            _waitToStartTimer.invalidate()

            // Jump to the main view:
            performSegueWithIdentifier(MyBasics.nameOfSegue_initialToMain, sender: self)

        }
        _previousLoadState = loadState
    }


    // This function is called shortly before a switch from this view to another.
    //
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        // DEBUG print("InitialViewController.prepareForSegue()")

        if segue.identifier == MyBasics.nameOfSegue_initialToMain {

            // this gets a reference to the screen that we're about to transition to
            let mainView = segue.destinationViewController as! MainViewController

            // Instead of using the default transition animation, we'll ask
            // the segue to use our custom TransitionManager object to manage the transition animation:
            mainView.transitioningDelegate = _rotatingTransition
        }
    }
}
