//
//  BasicViewController.swift
//  CarPlayer
//
//  Created by Peter Störmer on 04.02.15.
//  Copyright (c) 2015 Tempest Rock Studios. All rights reserved.
//

import UIKit

class BasicViewController: UIViewController {

    // ----- Attributes ----------------

    // A main scrollview that all basic view controllers have:
    var _scrollView: UIScrollView = UIScrollView()

    // For the letter line: the position of the scroll view per letter ("A", "B", ... "Z"):
    var _letterToPos: [ Character: CGFloat ] = [ Character: CGFloat ]()


    // ----- Methods ----------------

    required init?(coder aDecoder: NSCoder) {

        // Call superclass initializer:
        super.init(coder: aDecoder)

    } // init


    //
    // The initializing function that is called as soon as the view has finished loading
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        // DEBUG print("BasicViewController.viewDidLoad()")

        InitializeScrollView()
    }


    //
    // Initializes the standard scroll view.
    //
    func InitializeScrollView() {

        _scrollView.scrollEnabled = true
        _scrollView.frame = CGRect(origin: CGPoint(x: 0, y: 0),
            size: CGSize(width: CGFloat(MyBasics.screenWidth),
                height: CGFloat(MyBasics.ArtWork_YPos + MyBasics.ArtWork_Height + MyBasics.ArtWork_LabelHeight)))
        _scrollView.contentOffset = CGPoint(x: 0, y: 0)
        view.addSubview(_scrollView)
    }


    //
    // Creates the nice line of letters at the bottom of the screen.
    //
    func createLetterLine() {

        let numOfLetters = _letterToPos.count                           // number of letters
        let widthOfLetterLine = MyBasics.screenWidth * 95 / 100         // width of the complete letter line
        let xStep = widthOfLetterLine / numOfLetters                    // x step per letter

        // DEBUG print("numOfLetters: \(numOfLetters), xStep: \(xStep)")

        let heightOfEntry = 35;     // HARDCODED

        let yPos: Int = MyBasics.screenHeight - heightOfEntry           // y position of the letters
        var xPos: Int = (MyBasics.screenWidth - widthOfLetterLine) / 2  // Starting x position

        var sortedLetterKeys : Array<Character>
        sortedLetterKeys = Array(_letterToPos.keys).sort(<)

        for letter in sortedLetterKeys {

            //DEBUG print("letter: \(letter) at pos \(xPos)")

            // Make a button:
            let button = UIButton(type: UIButtonType.System)
            button.frame = CGRect(x: xPos, y: yPos, width: xStep-1, height: heightOfEntry)
            button.backgroundColor = UIColor.blackColor()
            button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            button.setTitle("\(letter)", forState: UIControlState.Normal)
            button.titleLabel!.font = MyBasics.fontForSmallText
            button.addTarget(self, action: #selector(BasicViewController.letterPressed(_:)), forControlEvents: .TouchDown)

            self.view.addSubview(button)

            xPos += xStep
        }
    }


    //
    // Handles the case that a letter of the letter line is pressed.
    //
    func letterPressed(sender: UIButton!) {

        // Get letter out of the button title:

        let letter = Array((sender.currentTitle!).characters)[0] as Character
        var newPosInScrollView = _letterToPos[letter]!

        // The maximum x value that is allowed in order not to go too far to the right (e.g. for X, Y, Z letters):
        let maxX: CGFloat = _scrollView.contentSize.width - CGFloat(MyBasics.screenWidth)

        // Avoid going too far right:
        if newPosInScrollView > maxX {

            newPosInScrollView = maxX
        }

        // Find out about the current position:
        let curPosInScrollView: CGFloat = CGFloat(_scrollView.contentOffset.x)

        // In order not to jump too far in the animation, we jump to approx. one screenwidth from the target away.
        // Only the "last mile" is animated then.

        // Calculate the difference between the new and the current position. Positive values mean "jump to the right":
        let difference = newPosInScrollView - curPosInScrollView

        // Set the jump size that shall be animated:
        let jumpSize: CGFloat = 1.5 * CGFloat(MyBasics.screenWidth)

        // Calculate the intermediate position which is the position which we jump to without animation:
        var intermediatePos: CGFloat = 0.0

        if (difference > 0) && (difference > jumpSize) {

            intermediatePos = newPosInScrollView - jumpSize

        } else if (difference < 0) && (difference * (-1) > jumpSize) {

            intermediatePos = newPosInScrollView + jumpSize
        }

        if intermediatePos > 0 {

            // The jump would be too large to be animated completely => jump to the intermediate position without animation:
            _scrollView.contentOffset = CGPoint(x: intermediatePos, y: 0.0)
        }
        
        // Now do the rest animatedly:
        UIView.jumpSpringyToPosition(_scrollView, pointToJumpTo: CGPoint(x: newPosInScrollView, y: 0.0))
    }
}
