//
//  PlayerViewController.swift
//  CarPlayer
//
//  Created by Peter Störmer on 27.11.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

import UIKit
import MediaPlayer
import CoreLocation


/*

func handleTap(gesture: UITapGestureRecognizer) {
let tapLocation = gesture.locationInView(bug.superview)
if bug.layer.presentationLayer().frame.contains(tapLocation) {
print("Bug tapped!")
// add bug-squashing code here
} else {
print("Bug not tapped!")
}
}

*/

//
// The PlayerViewController is the view that shows the "standard" playing of a song (the one without the map).
//
class PlayerViewController: UIViewController, UIGestureRecognizerDelegate {

    // ----- Attributes -----

    @IBOutlet weak var _mainTapButton: UIButton!
    @IBOutlet weak var _albumCoverImage: UIImageView!
    @IBOutlet weak var _indexIndicator: UILabel!
    @IBOutlet weak var _trackListButton: UIButton!
    @IBOutlet weak var _lyricsButton: UIButton!

    // Speed display:
    var _speedLabel: UILabel!
    var _longLabel: UILabel!
    var _latLabel: UILabel!
    var _altLabel: UILabel!
    var _courseLabel: UILabel!
    var _courseArrow: UIImageView!
    var _crossLines: UIImageView!

    // A timer for the animation of longish labels:
    var _animationTimer: NSTimer! = nil

    // All you need for the artist label:
    var _artistLabel: UILabel!
    var _artistContainerView: UIView!
    var _artistLabelStartingFrame: CGRect!
    var _artistLabelNeedsAnimation: Bool = false
    var _speedDisplayModeButton: UIButton! = UIButton()

    // All you need for the album label:
    var _albumLabel: UILabel!
    var _albumContainerView: UIView!
    var _albumLabelStartingFrame: CGRect!
    var _albumLabelNeedsAnimation: Bool = false

    // The progress bar to watch the progress of a track playing and its timer for the updates:
    var _progressBar: UIProgressView!
    var _progressTimer: NSTimer

    // An array of buttons above the progress bar to switch manually to some place inside the track:
    var _sliderButton: [UIButtonWithFeatures]! = nil
    
    // Container for the animation of the track title:
    var _trackTitleLabel: UILabel!
    var _trackTitleContainerView: UIView!
    var _trackTitleLabelStartingFrame: CGRect!
    var _trackTitleLabelNeedsAnimation: Bool = false

    // A flag that says whether the user has switched the track by panning the track title:
    var _userSwitchedTrack: Bool

    // The previous translation factor during panning. Used to realize whether the panning stopped:
    var _previousTranslation: CGFloat

    // A function to call in order to set the background color of the speed view (if that view is active)
    var _speedViewBackgroundColorNotification: ((UIColor) -> Void)? = nil


    // ----- Constants -----

    // z positions of view elements:
    let _zPosition_ArtistLabel: CGFloat = 0
    let _zPosition_TrackTitleLabel: CGFloat = 0
    let _zPosition_ProgressBar: CGFloat = 0
    let _zPosition_SliderButtons: CGFloat = 1000


    // ----- Methods -----

    //
    // Initializing function.
    //
    required init?(coder aDecoder: NSCoder) {
        
        _progressTimer = NSTimer()
        _userSwitchedTrack = false
        _previousTranslation = 0.0

        // Call superclass initializer:
        super.init(coder: aDecoder)

    } // init


    //
    // This function is called whenever the user reaches the player view.
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        // DEBUG print("PlayerViewController.viewDidLoad()")

        // Tell the locator who to call:
        _locator.setNotifierFunction(self.updateSpeedDisplay)

        // Set notification handler for music changing in the background:
        _controller.setNotificationHandler(self,
                                           notificationFunctionName: #selector(PlayerViewController.updateDisplayedInformation))

        // Set the progress timer to update the progress bar:
        _progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self,
                                                                selector: #selector(PlayerViewController.updateProgressBar),
                                                                userInfo: nil, repeats: true)

        // Create the speed display:
        createSpeedDisplay()

        if !_controller.thisWasADirectJump() && !_controller.albumAndArtistWerePreviouslySelected() {

            // The user intends to play a newly selected album.
            // Create the actual playlist that shall be played by the music player:
            _controller.createPlayListOfCurrentArtistAndAlbumIDs()

            // Start playing:
            _controller.playMusic()

        } else {

            // This was a direct jump to this view without selecting a new album.
            // Reset the according flag:
            _controller.resetFlagOfDirectJump()

        }

        // Create an initial progress bar:
        _progressBar = UIProgressView()
        view.addSubview(_progressBar)

        // Update the player directly without waiting for a notification in order to get around artifacts at first sight of the player view:
        updateDisplayedInformation()
    }


    //
    // This handler is called whenever this view becomes visible.
    //
    override func viewDidAppear(animated: Bool) {

        // Tell the controller about this:
        _controller.setCurrentlyVisibleView(self)
    }
    
    
    //
    // Updates all displayed information on the player view.
    //
    func updateDisplayedInformation() {

        // DEBUG print("PlayerViewController.updateDisplayedInformation()")

        // Set labels and enable or disable some buttons:
        setLabelsAndButtons()

        // Create a nicely colored background:
        createBackGround()

        // Set the buttons' positions according to the currently set speed display mode:
        createSliderButtons()
        updateSliderButtons()

        // Set the timer that animates longish labels if it is not already running:
        resetAnimationTimer()
    }


    //
    // Sets the basic labels and buttons on the view.
    //
    func setLabelsAndButtons() {

     //   var nowPlayingItem = _controller.nowPlayingItem()

        // Reset and create the artist name display:
        createArtistDisplay()

        // Reset some flags and values:
        _userSwitchedTrack = false
        _previousTranslation = 0.0

        // Reset and create the track title display:
        createTrackTitleDisplay()
        finalizePositionOfTrackTitle()

        // Show the artist and the track title in an animated fashion:
        showArtistAndTrackTitle()

        // Create all the album label stuff:
        createAlbumDisplay()

        // Take care of the index indicator in the top right corner:
        if _controller.currentNumberOfTracksIsKnown() {

            // Add the number of tracks:
            _indexIndicator.text = (_controller.indexOfNowPlayingItem()).description + " / " + (_controller.currentNumberOfTracks()).description

            // Enable the button for the track list:
            _trackListButton.hidden = false


        } else {

            // We have no track information => Do not show the track list indicators and button:
            _indexIndicator.text = ""
            _trackListButton.hidden = true
        }

        // Set the parameters for the progress bar:
        _progressBar.frame = MyBasics.PlayerView_FrameForProgressBar(_controller.speedDisplayMode())
        _progressBar.trackTintColor = UIColor.darkGrayColor()
        _progressBar.tintColor = UIColor.whiteColor()
        _progressBar.alpha = 0.8
        _progressBar.layer.zPosition = _zPosition_ProgressBar
        updateProgressBar()
    }


    //
    // Creates everything that has to do with displaying the artist name. If a former artist label existed, this is deleted first.
    //
    func createArtistDisplay() {

        let nowPlayingItem = _controller.nowPlayingItem()

        // Erase a possible previous version of the artist label:
        if _artistLabel != nil {

            _artistLabel.text = ""
        }

        // Create the artist label itself and place it into the container:
        _artistLabel = UILabel()
        _artistLabel.text = nowPlayingItem.artist
        _artistLabel.font = MyBasics.fontForLargeText
        _artistLabel.textColor = UIColor.whiteColor()
        _artistLabel.layer.zPosition = _zPosition_ArtistLabel
        _artistLabel.sizeToFit()
        _artistLabelStartingFrame = _artistLabel.frame

        // Embed the artist label into a container in order to animate the text if is too long to be displayed at once:
        // Create the container to put the artist label into:
        _artistContainerView = UIView(frame: MyBasics.PlayerView_FrameForArtistLabel(_controller.speedDisplayMode()))
        _artistContainerView.clipsToBounds = true
        _artistContainerView.alpha = 0.0
        _artistContainerView.layer.zPosition = _zPosition_ArtistLabel

        // Assign views:
        _artistContainerView.addSubview(_artistLabel)
        view.addSubview(_artistContainerView)

        // Only do the animation if the text does not fit into the container:
        if _artistLabelStartingFrame.width > MyBasics.PlayerView_ArtistLabel_Width {

            // Add this label to the list of to-be-animated labels:
            _artistLabelNeedsAnimation = true

        } else {

            // The artist label fits into the space => Just do some alignment:
            _artistLabel.frame = CGRect(x: 0, y: 0, width: MyBasics.PlayerView_ArtistLabel_Width, height: _artistLabelStartingFrame.height)
            _artistLabel.textAlignment = NSTextAlignment.Right
            _artistLabelNeedsAnimation = false
        }

        // Buttons to switch between display modes:
        _speedDisplayModeButton.frame = _artistLabel.frame
        // DEBUG _speedDisplayModeButton.backgroundColor = UIColor.blackColor()
        // DEBUG _speedDisplayModeButton.alpha = 0.5
        _speedDisplayModeButton.addTarget(self,
                                          action: #selector(PlayerViewController.speedButtonTapped),
                                          forControlEvents: .TouchUpInside)
        _speedDisplayModeButton.layer.zPosition = _zPosition_SliderButtons
        _artistContainerView.addSubview(_speedDisplayModeButton)
    }


    //
    // Creates everything that has to do with displaying the track title. If a former track title label existed, this is deleted first.
    //
    func createTrackTitleDisplay() {

        // DEBUG print("PlayerViewController.createTrackTitleDisplay()")

        let nowPlayingItem = _controller.nowPlayingItem()

        // Erase a possible previous version of the track title label:
        if _trackTitleLabel != nil {

            _trackTitleLabel.text = ""
        }

        // Create the track title label itself and place it into the container:
        _trackTitleLabel = UILabel()
        _trackTitleLabel.text = nowPlayingItem.title
        _trackTitleLabel.font = MyBasics.fontForLargeText
        _trackTitleLabel.textColor = UIColor.whiteColor()
        _trackTitleLabel.layer.zPosition = _zPosition_TrackTitleLabel

        _trackTitleLabel.sizeToFit()
        _trackTitleLabelStartingFrame = _trackTitleLabel.frame

        // Create the container to put the artist label into:
        if _trackTitleContainerView == nil {
            _trackTitleContainerView = UIView()
            view.addSubview(_trackTitleContainerView)
        }

        // Hide the title initially:
        _trackTitleContainerView.alpha = 0.0
        _trackTitleContainerView.clipsToBounds = true
        _trackTitleContainerView.layer.zPosition = _zPosition_TrackTitleLabel
        _trackTitleContainerView.addSubview(_trackTitleLabel)

        // Only do the animation if the text does not fit into the container:
        if _trackTitleLabelStartingFrame.width > MyBasics.PlayerView_TrackTitleLabel_Width(_controller.speedDisplayMode()) {

            // The text is too large to fit into the container.
            // Add this label to the list of to-be-animated labels:
            _trackTitleLabelNeedsAnimation = true

        } else {

            // The artist label fits into the space => Just do some alignment:
            _trackTitleLabel.frame = CGRect(x: 0, y: 0,
                width: MyBasics.PlayerView_TrackTitleLabel_Width(_controller.speedDisplayMode()),
                height: _trackTitleLabelStartingFrame.height)
            _trackTitleLabel.textAlignment = NSTextAlignment.Right

            _trackTitleLabelNeedsAnimation = false
        }
    }


    //
    // Sets the track title container's final position and size.
    //
    func finalizePositionOfTrackTitle() {

        _trackTitleContainerView.frame = MyBasics.PlayerView_FrameForTrackTitle(_controller.speedDisplayMode())

        // Add the pan gesture recognizer for the switching to the next track if we have more than one track:
        if !_controller.currentNumberOfTracksIsKnown() || _controller.currentNumberOfTracks() > 1 {

            let panGesture = UIPanGestureRecognizer(target: self,
                                                    action: #selector(PlayerViewController.trackTitleLabelPanned(_:)))
            panGesture.delegate = self
            _trackTitleContainerView.addGestureRecognizer(panGesture)
        }
    }


    //
    // Shows the artist and the track title by a quick animation.
    //
    func showArtistAndTrackTitle() {

        // Show both titles slowly:
        let durationForOneDirection: NSTimeInterval = 0.6
        UIView.animateWithDuration(
            durationForOneDirection,
            delay: 0.0,
            options: UIViewAnimationOptions.CurveEaseOut,
            animations: {
                self._artistContainerView.alpha = 1.0
                self._trackTitleContainerView.alpha = 1.0
            },
            completion: nil
        )
    }


    //
    // Creates the album label and the container around it.
    //
    func createAlbumDisplay() {

        // DEBUG print("PlayerViewController.createAlbumDisplay()")

        let nowPlayingItem = _controller.nowPlayingItem()

        // Erase a possible previous version of the album label:
        if _albumLabel != nil {

            _albumLabel.text = ""
        }

        // Create the album label itself and place it into the container:
        _albumLabel = UILabel()
        _albumLabel.text = nowPlayingItem.albumTitle
        _albumLabel.font = MyBasics.fontForSmallText
        _albumLabel.textColor = UIColor.whiteColor()
        _albumLabel.sizeToFit()
        _albumLabelStartingFrame = _albumLabel.frame

        // Embed the album label into a container in order to animate the text if is too long to be displayed at once:
        // Create the container to put the album label into:
        _albumContainerView = UIView(frame: MyBasics.PlayerView_FrameForAlbumLabel)
        _albumContainerView.clipsToBounds = true

        // Assign views:
        _albumContainerView.addSubview(_albumLabel)
        view.addSubview(_albumContainerView)

        // Only do the animation if the text does not fit into the container:
        if _albumLabelStartingFrame.width > MyBasics.PlayerView_AlbumLabel_Width {

            // Add this label to the list of to-be-animated labels:
            _albumLabelNeedsAnimation = true

        } else {

            // The album label fits into the space => Just do some alignment:
            _albumLabel.frame = CGRect(x: 0, y: 0, width: MyBasics.PlayerView_AlbumLabel_Width, height: _albumLabelStartingFrame.height)
            _albumLabel.textAlignment = NSTextAlignment.Center
            _albumLabelNeedsAnimation = false
        }
    }


    //
    // Updates the progress bar according to the current playback time in relation to the complete time of the current track.
    //
    func updateProgressBar() {

        // DEBUG print("PlayerViewController.updateProgressBar()")
        // DEBUG _controller.printMusicPlayerPlaybackState(addInfo: "updateProgressBar()")

        // Show current playback progress:
        _progressBar.progress = Float(_controller.progressOfCurrentlyPlayingTrack())
    }
    

    //
    // This method is called when the timer for the animation of the longish labels is fired.
    //
    func animationTimerFired() {

        // DEBUG print("PlayerViewController.animationTimerFired()")

        // Reset the timer that animates longish labels if it is not already running:
        _animationTimer = NSTimer.scheduledTimerWithTimeInterval(
            MyBasics.PlayerView_TimeForAnimation + MyBasics.PlayerView_TimeForToWaitForNextAnimation * 2,
            target: self,
            selector: #selector(PlayerViewController.animationTimerFired),
            userInfo: nil,
            repeats: false)

        if _artistLabelNeedsAnimation {

            UIView.animateLongishLabel(
                _artistLabel,
                frameAroundLabel: _artistLabelStartingFrame,
                timeForAnimation: MyBasics.PlayerView_TimeForAnimation,
                timeToWaitForNextAnimation: MyBasics.PlayerView_TimeForToWaitForNextAnimation,
                totalWidth: MyBasics.PlayerView_ArtistLabel_Width
            )
        }

        if _trackTitleLabelNeedsAnimation {

            UIView.animateLongishLabel(
                _trackTitleLabel,
                frameAroundLabel: _trackTitleLabelStartingFrame,
                timeForAnimation: MyBasics.PlayerView_TimeForAnimation,
                timeToWaitForNextAnimation: MyBasics.PlayerView_TimeForToWaitForNextAnimation,
                totalWidth: MyBasics.PlayerView_TrackTitleLabel_Width(_controller.speedDisplayMode())
            )
        }

        if _albumLabelNeedsAnimation {

            UIView.animateLongishLabel(
                _albumLabel,
                frameAroundLabel: _albumLabelStartingFrame,
                timeForAnimation: MyBasics.PlayerView_TimeForAnimation,
                timeToWaitForNextAnimation: MyBasics.PlayerView_TimeForToWaitForNextAnimation,
                totalWidth: MyBasics.PlayerView_AlbumLabel_Width
            )
        }
    }


    //
    // Creates a nice background that takes into account the average color of the artwork of the track.
    //
    func createBackGround() {

        let nowPlayingItem = _controller.nowPlayingItem()

        if nowPlayingItem.artwork == nil {

            // No artwork => Set black background color and leave:
            view.backgroundColor = UIColor.randomDarkColor()
            return
        }

        // We have an artwork.

        // Set the artist image in the top left corner:
        let sizeOfArtistImage = CGSize(width: MyBasics.PlayerView_ArtistImage_Width, height: MyBasics.PlayerView_ArtistImage_Height)
        _albumCoverImage.image = nowPlayingItem.artwork!.imageWithSize(sizeOfArtistImage)

        // Create a background color that is similar to the average of the artwork color.
        let sizeOfView = CGSize(width: MyBasics.screenWidth, height: MyBasics.screenHeight)
        let artworkImage: UIImage? = nowPlayingItem.artwork!.imageWithSize(sizeOfView)

        // Setup context with the given size:
        let onePixelSize = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(onePixelSize)
 //       let context = UIGraphicsGetCurrentContext()

        // Scale the artwork image down to one pixel, thereby generating an average color over the whole image:
        artworkImage!.drawInRect(CGRectMake(0, 0, 1, 1))

        // Drawing complete, retrieve the finished image and cleanup
        let imageWithOneColor: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Find out the newly generated color:
        let backColor = imageWithOneColor.getPixelColor(CGPointMake(0, 0))

        // Get the "lightness factor" out of the current background color:
        let lightnessFactor = backColor.lightnessFactor()
        // DEBUG print("color = \(backColor), lightnessFactor = \(lightnessFactor)")

        if lightnessFactor > 0.0 {

            // The new color is too light for the background, yet. Darken it a bit.

            // Create a Core Image context
            let params: [ String : AnyObject ] = [ kCIContextUseSoftwareRenderer : true ]
            let ciContext = CIContext(options: params)
            
            // Darken the image:
            let inputCiImage = CIImage(image: imageWithOneColor)
            let darkenFilter = CIFilter(name: "CIColorControls")
            darkenFilter!.setValue(inputCiImage, forKey: kCIInputImageKey)
            darkenFilter!.setValue(-1.0 * lightnessFactor, forKey: kCIInputBrightnessKey) //  kCIInputSaturationKey
            let darkenedImageData = darkenFilter!.valueForKey(kCIOutputImageKey) as! CIImage
            let darkenedImageRef = ciContext.createCGImage(darkenedImageData, fromRect: darkenedImageData.extent)

            let finalImageForBackground = UIImage(CGImage: darkenedImageRef)

            // Now the background color is dark enough to be used.
            view.backgroundColor = UIColor(patternImage: finalImageForBackground)

        } else {

            // The background color is dark enough to be directly used.
            view.backgroundColor = UIColor(patternImage: imageWithOneColor)
        }

        // Also update the speed view's background if it is currently active:
        if _speedViewBackgroundColorNotification != nil {

            _speedViewBackgroundColorNotification!(view.backgroundColor!)
        }
    }


    //
    // Creates those buttons that lie above the progress bar in order for the user to advance in the track.
    //
    func createSliderButtons() {

        // DEBUG print("PlayerViewController.createSliderButtons()")

        // Define the number of slider buttons:
        let numberOfButtons: Int = 50

        // Remove possibly previously existing buttons (this is necessary due to a bug somewhere):
        if _sliderButton != nil {

            // DEBUG print("  Removing previous buttons.")
            // Remove previous buttons first:
            for button in _sliderButton {
                button.removeFromSuperview()
            }
        }

        // Initialize the array of buttons:
        _sliderButton = [UIButtonWithFeatures]()

        for index in 0 ..< numberOfButtons {

            // Create a new button:
            let button = UIButtonWithFeatures(type: UIButtonType.Custom)
            // DEBUG button.backgroundColor = UIColor.blackColor()
            // DEBUG button.alpha = 0.5
            button.addTarget(self, action: #selector(PlayerViewController.sliderButtonTapped(_:)), forControlEvents: .TouchDown)
            button.setPosition(Double(index) / Double(numberOfButtons))
            button.layer.zPosition = _zPosition_SliderButtons

            // Add the new button to the array of slider buttons:
            _sliderButton.append(button)

            // Add the new button to the view:
            view.addSubview(button)
        }
    }


    //
    // Repositions the slider buttons according the the current speed display mode.
    //
    func updateSliderButtons() {

        // DEBUG print("PlayerViewController.updateSliderButtons() with speed display mode \(_controller.speedDisplayMode())")

        let xStartPos: CGFloat = MyBasics.PlayerView_SliderButtons_XStartPos(_controller.speedDisplayMode())
        let yPos: CGFloat = MyBasics.PlayerView_SliderButtons_YPos(_controller.speedDisplayMode())
        let sliderWidth: CGFloat = MyBasics.PlayerView_SliderButtons_SliderWidth(_controller.speedDisplayMode())
        let buttonHeight: CGFloat = MyBasics.PlayerView_SliderButtons_ButtonHeight
        let numberOfButtons: Int = _sliderButton.count
        let buttonWidth: CGFloat = sliderWidth / CGFloat(numberOfButtons)

        var index: Int = 0
        for button in _sliderButton {

            // Calculate x position of the button:
            let xPos: CGFloat = xStartPos + (sliderWidth * CGFloat(index) / CGFloat(numberOfButtons))
            button.frame = CGRect(x: xPos, y: yPos - buttonHeight/2, width: buttonWidth, height: buttonHeight)
            index += 1
        }
    }


    //
    // Resets the timer for the animation of longish labels.
    //
    func resetAnimationTimer() {

        stopAnimationTimer()
        _animationTimer = NSTimer.scheduledTimerWithTimeInterval(
            MyBasics.PlayerView_TimeForToWaitForNextAnimation,
            target: self,
            selector: #selector(PlayerViewController.animationTimerFired),
            userInfo: nil,
            repeats: false)

    }


    //
    // Handles the panning events for the switch to the previous or the next track.
    //
    func trackTitleLabelPanned(recognizer: UIPanGestureRecognizer) {

        // Ignore the panning events if we are already in the switching process:
        if _userSwitchedTrack {

            return
        }

        // Get the translation data from the recognizer, i.e. the position of the panning finger in x direction:
        var translation: CGFloat = recognizer.translationInView(self.view).x
        // DEBUG print("translation: \(translation)")

        // We know that the view we are looking at is the track title:
        let pannedView = recognizer.view!

        if translation == _previousTranslation {

            // DEBUG print("panning stopped -> back to normal size")
            // This is the signal that the user stopped panning.
            // => Scale the title back to the normal size:
            UIView.animateWithDuration(
                0.4,
                delay: 0.0,
                options: UIViewAnimationOptions.CurveEaseOut,
                animations: {
                    pannedView.alpha = 1.0
                    self._artistContainerView.alpha = 1.0
                },
                completion: nil
            )

            // Reset the "previous translation" memory:
            _previousTranslation = 0.0

            return
        }

        // Store the translation value for later comparison:
        _previousTranslation = translation

        // Define the panning direction:
        let skippingDirection: MusicSkippingDirection = (translation < 0 ? .Next : .Previous)

        if skippingDirection == MusicSkippingDirection.Previous {

            // This is a panning to the right.
            // Make the translation value negative:
            translation = -translation
        }

        // Define the scale factor for the actual scaling:
        let scaleFactor: CGFloat = 1.0 + translation / CGFloat(MyBasics.PlayerView_ArtistLabel_Width / 2)
        // DEBUG print("scaleFactor: \(scaleFactor)")

        // Scale the track title to the necessary format:
        pannedView.alpha = scaleFactor
        _artistContainerView.alpha = scaleFactor

        // Define the threshold that needs to be reached in order to start the switch to the next track:
        let scaleThreshold: CGFloat = 0.2

        if scaleFactor < scaleThreshold {

            // DEBUG print("threshold reached")
            // We have reached a threshold that says that the user really wants to switch the track.
            _userSwitchedTrack = true

            // Now do the rest animatedly:
            let durationForOneDirection: NSTimeInterval = 0.5
            UIView.animateWithDuration(
                durationForOneDirection,
                delay: 0.0,
                options: UIViewAnimationOptions.CurveEaseOut,
                animations: {
                    pannedView.alpha = 0.0
                    self._artistContainerView.alpha = 0.0
                },
                completion: { finished in

                    self.stopAnimationTimer()
                    if skippingDirection == MusicSkippingDirection.Next {
                        _controller.skipToNextItem()
                    } else {
                        _controller.skipToPreviousItem()
                    }
                }
            )
        }
    }
    
    
    //
    // Creates the "speed display" that shows the whole navigation stuff at the bottom of the page.
    //
    func createSpeedDisplay() {

    //    let fullWidth: CGFloat = CGFloat(MyBasics.screenWidth)
        let speedLabelWidth: CGFloat = MyBasics.PlayerView_ArtistImage_Width

        let xPosGap: CGFloat = CGFloat(MyBasics.PlayerView_ArtistLabel_Width) / 4
        let labelWidth: CGFloat = xPosGap
        let labelHeight: CGFloat = CGFloat(MyBasics.screenHeight) - MyBasics.PlayerView_speed_yPos

        // Speed label:
        _speedLabel = UILabel()
        _speedLabel.frame = CGRectMake(0, MyBasics.PlayerView_speed_yPos, speedLabelWidth, labelHeight)
        _speedLabel.font = MyBasics.fontForLargeText
        _speedLabel.textAlignment = NSTextAlignment.Center
        _speedLabel.textColor = UIColor.whiteColor()
        view.addSubview(_speedLabel)

        var curXPos: CGFloat = MyBasics.PlayerView_ArtistLabel_XPos

        // Longitude and latitude labels:
        _latLabel = UILabel()
        _latLabel.frame = CGRectMake(curXPos, MyBasics.PlayerView_speed_yPos, 2*labelWidth, labelHeight / 2)
        _latLabel.font = MyBasics.fontForMediumText
        _latLabel.textColor = UIColor.whiteColor()
        view.addSubview(_latLabel)
        _longLabel = UILabel()
        _longLabel.frame = CGRectMake(curXPos, MyBasics.PlayerView_speed_yPos + labelHeight/2, 2*labelWidth, labelHeight / 2)
        _longLabel.font = MyBasics.fontForMediumText
        _longLabel.textColor = UIColor.whiteColor()
        view.addSubview(_longLabel)
        curXPos += (2*xPosGap)

        // Altitude:
        _altLabel = UILabel()
        _altLabel.frame = CGRectMake(curXPos, MyBasics.PlayerView_speed_yPos, labelWidth, labelHeight)
        _altLabel.font = MyBasics.fontForMediumText
        _altLabel.textAlignment = NSTextAlignment.Center
        _altLabel.textColor = UIColor.whiteColor()
        view.addSubview(_altLabel)
        curXPos += xPosGap

        // Course:
        _courseLabel = UILabel()
        _courseLabel.frame = CGRectMake(curXPos-2, CGFloat(MyBasics.screenHeight) - (labelHeight * 3/4) + 5, labelWidth, labelHeight)
        _courseLabel.font = MyBasics.fontForSmallThinText
        _courseLabel.textAlignment = NSTextAlignment.Center
        _courseLabel.textColor = UIColor.whiteColor()
        view.addSubview(_courseLabel)

        _courseArrow = UIImageView(image: UIImage(named: "arrow.png"))
        _courseArrow.frame = CGRectMake(curXPos+20, MyBasics.PlayerView_speed_yPos+15, labelHeight / 2, labelHeight / 2)
        _courseArrow.alpha = 0.0
        _crossLines = UIImageView(image: UIImage(named: "crosslines.png"))
        _crossLines.frame = CGRectMake(curXPos+20, MyBasics.PlayerView_speed_yPos+15, labelHeight / 2, labelHeight / 2)
        _crossLines.alpha = 0.0
        view.addSubview(_courseArrow)
        view.addSubview(_crossLines)
    }


    //
    // Handles the case that the speed button has been tapped by the user.
    // Switched the view mode of the speed display.
    //
    func speedButtonTapped() {

        // Advance the speed display mode:
        _controller.advanceSpeedDisplayMode()

        moveLabels()

        // Set some initial values before the updates from the locator arrive:
        switch _controller.speedDisplayMode() {

        case 0: // of
            _speedLabel.text = ""
            _latLabel.text = ""
            _longLabel.text = ""
            _altLabel.text = ""
            _courseLabel.text = ""
            _courseArrow.alpha = 0.0    // invisible
            _crossLines.alpha = 0.0     // invisible

        case 1: // speed only
            _speedLabel.text = Locator.defaultSpeedString
            _latLabel.text = ""
            _longLabel.text = ""
            _altLabel.text = ""
            _courseLabel.text = ""
            _courseArrow.alpha = 0.0    // invisible
            _crossLines.alpha = 0.0     // invisible

        case 2: // all
            _latLabel.text = _locator.defaultLatitude()
            _longLabel.text = _locator.defaultLongitude()
            _altLabel.text = _locator.defaultAltitude()
            _courseLabel.text = _locator.defaultCourse()
            _courseArrow.alpha = 0.0    // invisible
            _crossLines.alpha = 1.0     // visible

        default:
            assert(false, "PlayerViewController.speedButtonTapped(): Reached illegal value \(_controller.speedDisplayMode())")
        }
    }

    
    //
    // Moves the labels to the currently reasonable position, depending on the speedDisplayMode.
    //
    func moveLabels() {

        // DEBUG print("PlayerViewController.moveLabels()")

        let delayForArtist: [Double] = [ 0.1, 0.0, 0.0 ]
        let delayForProgressBar: Double = 0.05
        let delayForTrackTitle: [Double] = [ 0.0, 0.0, 0.1 ]

        // Re-create the label animation for the track title label:
        createTrackTitleDisplay()

        // Show the artist and the track title in an animated fashion:
        showArtistAndTrackTitle()

        UIView.jumpSpringyToPosition(_artistContainerView, delay: delayForArtist[_controller.speedDisplayMode()],
            frameToJumpTo: MyBasics.PlayerView_FrameForArtistLabel(_controller.speedDisplayMode()))

        UIView.jumpSpringyToPosition(_progressBar, delay: delayForProgressBar, frameToJumpTo: MyBasics.PlayerView_FrameForProgressBar(_controller.speedDisplayMode()))

        UIView.jumpSpringyToPosition(
            _trackTitleContainerView, delay: delayForTrackTitle[_controller.speedDisplayMode()],
            frameToJumpTo: MyBasics.PlayerView_FrameForTrackTitle(_controller.speedDisplayMode()),
            completion: { finished in

                self.finalizePositionOfTrackTitle()
            }
        )

        // Update also the slider buttons above the progress bar:
        createSliderButtons()
        updateSliderButtons()

        if (_trackTitleLabelNeedsAnimation && !_albumLabelNeedsAnimation && !_artistLabelNeedsAnimation) {

            // The track title label is the only animated label.
            // => Start the animation after this move immediately:
            resetAnimationTimer()            
        }
    }

    
    //
    // Is called when the locator has new data.
    //
    func updateSpeedDisplay(speed: Int, lat: String, long: String, alt: String, courseStr: String, course: Double, _: CLLocationCoordinate2D) {

        switch _controller.speedDisplayMode() {

        case 0:
            _speedLabel.text = ""
            _latLabel.text = ""
            _longLabel.text = ""
            _altLabel.text = ""
            _courseLabel.text = ""
            _courseArrow.alpha = 0.0    // invisible
            _crossLines.alpha = 0.0     // invisible

        case 1:
            _speedLabel.text = (speed != Locator.defaultSpeed ? speed.description : Locator.defaultSpeedString)
            _latLabel.text = ""
            _longLabel.text = ""
            _altLabel.text = ""
            _courseLabel.text = ""
            _courseArrow.alpha = 0.0    // invisible
            _crossLines.alpha = 0.0     // invisible

        case 2:
            _speedLabel.text = (speed != Locator.defaultSpeed ? speed.description : Locator.defaultSpeedString)
            _latLabel.text = lat
            _longLabel.text = long
            _altLabel.text = alt
            _courseLabel.text = courseStr
            _crossLines.alpha = 1.0     // visible
            if course >= 0 {
                _courseArrow.alpha = 1.0
                UIView.animateWithDuration(0.5,
                    animations: {
                        self._courseArrow.transform = CGAffineTransformMakeRotation(2*CGFloat(M_PI) * (CGFloat(course)/360))
                })
            } else {

                // Invalid course => make arrow invisible
                _courseArrow.alpha = 0.0
            }

        default:
            assert(true, "PlayerViewController.updateSpeedDisplay(): Reached illegal value \(_controller.speedDisplayMode())")

        }
    }


    //
    // Handles the event of the button above the album image being tapped.
    // Opens a modal view and show the complete list of tracks in the playlist.
    //
    @IBAction func trackListButtonTapped(sender: UIButton) {

        let tracklistView = TracklistViewController()
        tracklistView.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        tracklistView.modalTransitionStyle = UIModalTransitionStyle.CoverVertical

        UIView.animateSlightShrink(
            _indexIndicator,
            completion: { finished in
                self.presentViewController(tracklistView, animated: true, completion: nil)
        })
    }


    // 
    // Handles the event of the lyrics button above the album image being tapped.
    // Opens a modal view showing the lyrics if they exist.
    //
    @IBAction func lyricsButtonTapped(sender: UIButton) {

        let lyricsView = LyricsViewController()
        lyricsView.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        lyricsView.modalTransitionStyle = UIModalTransitionStyle.CoverVertical

        UIView.animateSlightShrink(
            _albumCoverImage,
            completion: { finished in
                self.presentViewController(lyricsView, animated: true, completion: nil)
        })
    }


    //
    // Handles the event of a slider button being tapped.
    // Skips the track to the button's position.
    //
    func sliderButtonTapped(sender: UIButtonWithFeatures) {

        // DEBUG print("PlayerViewController.sliderButtonTapped()")
        // DEBUG print("  Sender's position: \(sender.position())")

        // Animate the new progress bar:
        UIView.animateSlightGrowthInYDir(
            _progressBar,
            completion: { finished in

                // Set the current track to the defined position.
                // The parameter must be between 0.0 and 1.0.
                _controller.setCurrentTrackPosition(sender.position())
            }
        )

    }

    //
    // Handles the button event which starts and pauses the player.
    //
    @IBAction func startAndPauseButtonTapped(sender: UIButton) {

        UIView.animateTinyShrink(self.view, completion: nil)
        _controller.togglePlaying()
    }


    //
    // This method is called when we are coming back from the speed view.
    //
    @IBAction func unwindToViewController (sender: UIStoryboardSegue){

        // DEBUG print("PlayerViewController.unwindToViewController()")

        // Tell the locator again to call our notifier function as this was changed by the speed view:
        _locator.setNotifierFunction(self.updateSpeedDisplay)

        // Deactivate the background color notification:
        _speedViewBackgroundColorNotification = nil
    }


    //
    // This handler switches over to the speed view whenever the user swipes up.
    //
    @IBAction func userHasSwipedUp(sender: UISwipeGestureRecognizer) {

        // DEBUG print("PlayerViewController.userHasSwipedUp()")

        performSegueWithIdentifier(MyBasics.nameOfSegue_playerToSpeed, sender: self)
    }


    //
    // This function is called shortly before we switch back to one of the calling views.
    //
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        // DEBUG print("PlayerViewController.prepareForSegue()")
        // DEBUG print("PlayerView --> \(segue.destinationViewController.title!!)")

        if segue.destinationViewController.title! != MyBasics.nameOfSpeedView {

            // This is a seque that either goes to the album or the main view.
            // We do not need the running timers anymore:
            // DEBUG print("PlayerViewController.prepareForSegue(): stopping all timers.")
            stopAllTimers()

        } else {

            // We are switching to the speed view.
            // Tell the speed view which background color to take and keep the background color setter in mind for later updates:
            let speedView = segue.destinationViewController as! SpeedViewController
            _speedViewBackgroundColorNotification = speedView.setBackgroundColor
            _speedViewBackgroundColorNotification!(view.backgroundColor!)

            // Animate the transition from this view to the speed view and tell the speed view which swipe leads back to this view:
            _slidingTransition.setDirectionToStartWith(TransitionManager_Sliding.DirectionToStartWith.Up)
            speedView.setDirectionToSwipeBack(SpeedViewController.DirectionToSwipeBack.Down)
            speedView.transitioningDelegate = _slidingTransition
        }
    }


    //
    // Handles the users pinching which changes the brightness of the screen.
    //
    @IBAction func userHasPinched(sender: UIPinchGestureRecognizer) {

        // DEBUG print("PlayerControllerView.userHasPinched()")
        _controller.setBrightness(sender.scale)
        
    }


    //
    // Stops all running timers.
    //
    func stopAllTimers() {

        if _progressTimer.valid {
            _progressTimer.invalidate()
            // DEBUG print("_progressTimer stopped.")
        }

        stopAnimationTimer()
    }


    //
    // Stops the timer for the text animation.
    //
    func stopAnimationTimer() {

        if (_animationTimer != nil) && _animationTimer.valid {
            _animationTimer.invalidate()
            _animationTimer = nil
            // DEBUG print("Animation timer stopped.")
        }
    }
}
