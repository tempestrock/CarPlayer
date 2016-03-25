//
//  ViewController.swift
//  CarPlayer
//
//  Created by Peter Störmer on 21.11.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

import UIKit
import MediaPlayer


class MainViewController: BasicViewController, UIScrollViewDelegate  {

    required init?(coder aDecoder: NSCoder) {

        // Call superclass initializer:
        super.init(coder: aDecoder)
        
    } // init


    //
    // The initializing function that is called as soon as the view has finished loading
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        // DEBUG print("MainViewController.viewDidLoad()")

        // Tell the controller about this:
        _controller.setCurrentlyVisibleView(self)

        view.backgroundColor = UIColor.blackColor()

        // Set a notification for the case that the app is closed an opened later:
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(MainViewController.handleApplicationDidBecomeActiveNotification(_:)),
            name: UIApplicationDidBecomeActiveNotification, // name: UIApplicationWillEnterForegroundNotification,
            object: nil)

        // Create the actual main view.
        createMainView()

        // Just for debugging:
        // DEBUG let wakeyTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "sayHi", userInfo: nil, repeats: true)
    }


    //
    // DEBUG function
    //
    func sayHi() {

        print("Still awake!")

    }

    //
    // Creates all the stuff that is necessary for the nice main view.
    //
    func createMainView() {

        // Create the two main parts of the view, i.e., the scrollview and the letter line:
        createScrollview()
        createLetterLine()
    }


    //
    // This handler is called whenever this view becomes visible.
    //
    override func viewDidAppear(animated: Bool) {

        // DEBUG print("MainViewController.viewDidAppear()")

        // Tell the controller about this:
        _controller.setCurrentlyVisibleView(self)
    }
    
    
    //
    // Handles a notification of the app being (re-)opened.
    //
    func handleApplicationDidBecomeActiveNotification(notification: NSNotification) {

        // DEBUG print("MainViewController.handleApplicationDidBecomeActiveNotification()")

        _controller.checkIfMusicIsPlaying()
        checkWhetherToJumpToPlayerView()
    }

    
    //
    // Checks whether the view should jump directly to the player view.
    // This function is called whenever the app is started or restarted.
    //
    func checkWhetherToJumpToPlayerView() {

        // DEBUG print("MainViewController.checkWhetherToJumpToPlayerView()")

        if _controller.musicPlayerIsPlaying() {

            let visbileViewTitle = _controller.currentlyVisibleView().title!

            // Find out whether or not we're already in the player view:
            if visbileViewTitle == MyBasics.nameOfPlayerView {

                // We are at the right place already.
                return
            }

            // Store in the contoller the information that a direct jump to the player is intended:
            _controller.setFlagOfDirectJump()

            if visbileViewTitle == MyBasics.nameOfMainView {

                // Switch over to the player view using the respective segue:
                performSegueWithIdentifier(MyBasics.nameOfSegue_mainToPlayer, sender: self)

            } else {

                if visbileViewTitle == MyBasics.nameOfAlbumView {

                    // Tell the album view controller to switch to the player view (this often doesn't work):
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let albumView = storyboard.instantiateViewControllerWithIdentifier(MyBasics.nameOfAlbumView) as! AlbumViewController
                    albumView.performSegueWithIdentifier(MyBasics.nameOfSegue_albumToPlayer, sender: albumView)

                } else {

                    print("MainViewController.checkWhetherToJumpToPlayerView(): Unknown visible view \"\(visbileViewTitle)\".")

                }

            }
        } else {

            // DEBUG print("--> Nope.")
        }
    }


    //
    // Creates the scrollview with all the artist buttons on it.
    //
    func createScrollview() {

        // DEBUG print("MainViewController.createScrollview(): Starting")

        let widthOfEntry = MyBasics.ArtWork_Width
        let heightOfEntry = MyBasics.ArtWork_Height
        let heightOfLabel = MyBasics.ArtWork_LabelHeight
        let yPos = MyBasics.ArtWork_YPos
        var xPos = MyBasics.ArtWork_InitialXPos
        let xGap = MyBasics.ArtWork_InitialXPos
        
        var previousLetter: Character = "Z"

        for artistShortName in _controller.sortedArtistShortNames() {

            // DEBUG print("artistShortName: \"\(artistShortName)\".")
            // Get the long version of the short artist name:
            let artistLongName = _controller.longArtistName(artistShortName)

            // Get the first letter out of the artist name:
            let firstLetter = Array(artistShortName.characters)[0] as Character
            if firstLetter != previousLetter {
                
                // The found letter is different to the on of the previous artist name.
                // --> Store the position of the found letter.
                _letterToPos[firstLetter] = CGFloat(xPos-10)

                // DEBUG let tmp = _letterToPos[firstLetter]
                // DEBUG print("Setting pos of \(firstLetter) to \(tmp)")
                
                previousLetter = firstLetter
            }
            
            // Make a button:
//            let button = UIButtonWithFeatures.buttonWithType(UIButtonType.System)
            let button = UIButtonWithFeatures(type: UIButtonType.System)
            button.frame = CGRect(x: xPos, y: yPos, width: widthOfEntry, height: heightOfEntry)

            let albumArtwork: MPMediaItemArtwork?? = _controller.artwork(artistLongName)

            if (albumArtwork != nil) && (albumArtwork! != nil) {

                // An image for the artist does exist.

                let sizeOfArtistImage = CGSize(width: albumArtwork!!.imageCropRect.width,
                                               height: albumArtwork!!.imageCropRect.height)
     //           var uiImage = albumArtwork!.imageWithSize(sizeOfArtistImage)
                button.setBackgroundImage(albumArtwork!!.imageWithSize(sizeOfArtistImage), forState: .Normal)
                button.setBackgroundImage(albumArtwork!!.imageWithSize(sizeOfArtistImage), forState: .Highlighted)

            } else {

                // Create some colorful button as no artwork exists.

                button.backgroundColor = UIColor.randomDarkColor()
                button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                button.titleLabel!.font = MyBasics.fontForHugeText
                button.setTitle(">", forState: UIControlState.Normal)
            }

            // Create the caption to be used under the button:
            let numberOfAlbums = _controller.numberOfAlbumsForArtist(artistLongName)
            let numberOfTracks = _controller.numberOfTracksForArtist(artistLongName)
            let artistCaption = artistLongName + " (" +
                ((numberOfAlbums > 1) ? (numberOfAlbums.description + ", ") : "") +
                numberOfTracks.description + ")"
            // DEBUG print("\(artistCaption)")

            // Create a label underneath the button that shows the artist name and the number of albums:
            let artistLabel = UILabel()
            artistLabel.text = artistCaption
            artistLabel.frame = CGRect(x: xPos, y: yPos + heightOfEntry, width: widthOfEntry, height: heightOfLabel)
            artistLabel.textAlignment = NSTextAlignment.Center
            artistLabel.textColor = UIColor.whiteColor()
            artistLabel.font = MyBasics.fontForVerySmallText
            _scrollView.addSubview(artistLabel)

            button.setArtistName(artistLongName)
            button.addTarget(self, action: #selector(MainViewController.buttonPressed(_:)), forControlEvents: .TouchUpInside)

            _scrollView.addSubview(button)
            
            xPos += (widthOfEntry + xGap)

            // Adjust the size of the scroll view:
            _scrollView.contentSize = CGSizeMake(CGFloat(xPos), CGFloat(heightOfEntry/2))
        }
        
        // Scroll to some random place initially:
        let initialXPos = Int(arc4random_uniform(UInt32(xPos - MyBasics.screenWidth)))
        _scrollView.contentOffset = CGPoint(x: initialXPos, y: 0)

        // DEBUG print("MainViewController.createScrollview(): Finished")
    }


    //
    // Handles the event of an artist name tapped.
    //
    func buttonPressed(button: UIButtonWithFeatures!) {
        
        _controller.setCurrentArtist(button.artistName())

        // Animate the pressed button and switch over to the album view:
        UIView.animateSlightShrink(
            button,
            completion: { finished in
                // Switch over to the album view:
                self.performSegueWithIdentifier(MyBasics.nameOfSegue_mainToAlbum, sender: self)
        })
    }


    //
    // This function is called shortly before a switch from this view to another.
    //
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        // DEBUG print("MainViewController.prepareForSegue()")

        if segue.identifier == MyBasics.nameOfSegue_mainToAlbum {

            // DEBUG print("MainView --> AlbumView")

            // this gets a reference to the screen that we're about to transition to
            let albumView = segue.destinationViewController as! AlbumViewController

            // Instead of using the default transition animation, we'll ask
            // the segue to use our custom TransitionManager object to manage the transition animation:
            albumView.transitioningDelegate = _rotatingTransition

        } else if segue.identifier == MyBasics.nameOfSegue_mainToPlayer {

            // DEBUG print("MainView --> PlayerView")

            // this gets a reference to the screen that we're about to transition to
            let playerView = segue.destinationViewController as! PlayerViewController

            // Instead of using the default transition animation, we'll ask
            // the segue to use our custom TransitionManager object to manage the transition animation:
            playerView.transitioningDelegate = _rotatingTransition

        } else if segue.identifier == MyBasics.nameOfSegue_mainToSpeed {

            // We are switching to the speed view.
            // Tell the speed view which background color to take and keep the background color setter in mind for later updates:
            let speedView = segue.destinationViewController as! SpeedViewController
            speedView.setBackgroundColor(UIColor.darkBlueColor())

            // Animate the transition from this view to the speed view and tell the speed view which swipe leads back to this view:
            _slidingTransition.setDirectionToStartWith(TransitionManager_Sliding.DirectionToStartWith.Down)
            speedView.setDirectionToSwipeBack(SpeedViewController.DirectionToSwipeBack.Up)
            speedView.transitioningDelegate = _slidingTransition
        }
    }


    //
    // This handler is called when the user has swiped up on the main view.
    // If music is currently playing, this leady to the PlayerViewController.
    //
    @IBAction func userHasSwipedUp(sender: UISwipeGestureRecognizer) {

        if !_controller.nowPlayingItemExists() {

            // Nothing to be done here.
            return
        }

        // Store in the contoller the information that a direct jump to the player is intended:
        _controller.setFlagOfDirectJump()

        // Switch over to the player view:
        performSegueWithIdentifier(MyBasics.nameOfSegue_mainToPlayer, sender: self)
    }


    //
    // Handles the user's down-swiping and switches to the speed view.
    //
    @IBAction func userHasSwipedDown(sender: UISwipeGestureRecognizer) {

        // Switch over to the speed view:
        performSegueWithIdentifier(MyBasics.nameOfSegue_mainToSpeed, sender: self)
    }


    //
    // This handler is called whenever someone is getting back to this view ("Exit")
    //
    @IBAction func unwindToViewController (sender: UIStoryboardSegue){

  //      print("MainViewController.unwindToViewController()")

    }
    
    

    //
    // Handles the users pinching which changes the brightness of the screen.
    //
    @IBAction func userHasPinched(sender: UIPinchGestureRecognizer) {

        _controller.setBrightness(sender.scale)

    }
}
