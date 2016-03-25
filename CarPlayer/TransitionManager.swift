//
//  TransitionManager.swift
//  Transitions between views
//

import UIKit

class TransitionManager_Rotating: TransitionManager_Base  {
    
    //
    // Animates a rotation from one view controller to another.
    //
    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        // DEBUG print("TransitionManager_Rotating.animateTransition()")
        
        // Get reference to our fromView, toView and the container view that we should perform the transition in:
        let container = transitionContext.containerView()
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        
        // set up from 2D transforms that we'll use in the animation:
        let π : CGFloat = 3.14159265359
        let offScreenDown = CGAffineTransformMakeRotation(π/2)
        let offScreenUp = CGAffineTransformMakeRotation(-π/2)
        
        // Prepare the toView for the animation, depending on whether we are presenting or dismissing:
        toView.transform = self.presenting ? offScreenDown : offScreenUp
        
        // set the anchor point so that rotations happen from the top-left corner
        toView.layer.anchorPoint = CGPoint(x: 0, y: 0)
        fromView.layer.anchorPoint = CGPoint(x: 0, y: 0)
        
        // updating the anchor point also moves the position to we have to move the center position to the top-left to compensate
        toView.layer.position = CGPoint(x :0, y: 0)
        fromView.layer.position = CGPoint(x: 0, y: 0)
        
        // add the both views to our view controller
        container!.addSubview(toView)
        container!.addSubview(fromView)
        
        // Get the duration of the animation:
        let duration = self.transitionDuration(transitionContext)
        
        // Perform the animation:
        UIView.animateWithDuration(

            duration,
            delay: 0.0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.8,
            options: [],
            animations: {
            
                // slide fromView off either the left or right edge of the screen
                // depending if we're presenting or dismissing this view
                fromView.transform = self.presenting ? offScreenUp : offScreenDown
                toView.transform = CGAffineTransformIdentity
            
            },
            completion: { finished in
                
                // tell our transitionContext object that we've finished animating
                transitionContext.completeTransition(true)
            }
        )
    }
}


//
// A manager for vertical sliding transitions. Use the "DirectionToStartWith" to define whether the initial animation goes up or down.
//
class TransitionManager_Sliding: TransitionManager_Base {

    // An enum to define the initial animation direction
    enum DirectionToStartWith {

        case Up
        case Down
    }

    // The direction to us when animating the presentation. The dismissal is in the respective opposite direction
    private var _directionToStartWith: DirectionToStartWith = .Down


    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        // get reference to our fromView, toView and the container view that we should perform the transition in
        let container = transitionContext.containerView()
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!

        // set up from 2D transforms that we'll use in the animation
        let offScreenDown = CGAffineTransformMakeTranslation(0, container!.frame.height)
        let offScreenUp = CGAffineTransformMakeTranslation(0, -container!.frame.height)

        // start the toView to the right of the screen
        if _directionToStartWith == DirectionToStartWith.Up {
            toView.transform = self.presenting ? offScreenDown : offScreenUp
        } else {
            toView.transform = self.presenting ? offScreenUp : offScreenDown
        }

        // add the both views to our view controller
        container!.addSubview(toView)
        container!.addSubview(fromView)

        // Get the duration of the animation:
        let duration = self.transitionDuration(transitionContext)

        // Perform the animation:
        UIView.animateWithDuration(

            duration,
            delay: 0.0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.8,
            options: [],
            animations: {

                // Depending on the two aspects "direction to start with" and "presentation or dismissal" we set the fromview's transformation:
                if self._directionToStartWith == DirectionToStartWith.Up {
                    fromView.transform = self.presenting ? offScreenUp : offScreenDown
                } else {
                    fromView.transform = self.presenting ? offScreenDown : offScreenUp
                }

                toView.transform = CGAffineTransformIdentity

            },
            completion: { finished in

                // tell our transitionContext object that we've finished animating
                transitionContext.completeTransition(true)
            }
        )
    }


    //
    // Sets the direction of swiping for the presentation. The direction back (dismissal) is always the respective opposite direction.
    //
    func setDirectionToStartWith(direction: DirectionToStartWith) {

        _directionToStartWith = direction
    }
}


//
// The base class of all transition managers
//
class TransitionManager_Base: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate  {

    // --------- attributes ---------

    // A flag to define whether we are in the presenting or in the dismissing part of the animation:
    private var presenting = true


    // --------- methods ---------

    //
    // Empty animation. Needs to be implemented by derived class.
    //
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        assert(false, "TransitionManager_Base.animateTransition(): Missing implementation in derived class")
    }


    //
    // Returns how many seconds the transiton animation will take.
    //
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {

        return 0.75
    }


    //
    // Returns the animator when presenting a viewcontroller.
    // Remmeber that an animator (or animation controller) is any object that aheres to the UIViewControllerAnimatedTransitioning protocol
    //
    func animationControllerForPresentedController(
        presented: UIViewController,
        presentingController presenting: UIViewController,
        sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        // DEBUG print("TransitionManager_Base.animationControllerForPresentedController()")

        // These methods are the perfect place to set our `presenting` flag to either true or false - voila!
        self.presenting = true
        return self
    }


    //
    // Returns the animator used when dismissing from a view controller.
    //
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        // DEBUG print("TransitionManager_Base.animationControllerForDismissedController()")

        self.presenting = false
        return self
    }
}
