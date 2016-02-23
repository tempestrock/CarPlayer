//
//  LyricsViewController.swift
//  CarPlayer
//
//  Created by Peter Störmer on 18.12.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer


//
// A view controller to show the lyrics of a track in a modal view.
//
class LyricsViewController: ModalViewController, UITextViewDelegate {

    // ----- Attributes -----

    // The underlying close button:
    var _closeButtonOnScrollView: UIButton = UIButton(type: UIButtonType.Custom)

    // A scrollable text view:
    var _lyricsTextView = UITextView()

    // The real height of the content. Due to the fact that this is changing over time, we fix it once we have it in this attribute:
    var _realContentHeight: CGFloat = 0.0


    // A threshold between 0.0 and 1.0 that says when the scrolling starts, based on the relation between _secondsThatScrollingStartsAfterTrackStarts and
    // the current track's length:
    var _timeValWhenScrollingStarts: Double = 0.0

    // The maximum value between 0.0 and 1.0 that says when the scrolling ends, based on the relation between _secondsThatScrollingEndsBeforeTrackEnds and
    // the current track's length:
    var _timeValWhenScrollingEnds: Double = 0.0

    // The difference between _timeValWhenScrollingEnds and _timeValWhenScrollingStarts, i.e. the range between both values. This value, again, lies
    // between 0.0 and 1.0:
    var _timeRangeValForScrolling: Double = 0.0

    // A timer for the progress of the currently playing track:
    var _progressTimer: NSTimer!


    // ----- Constants ------

    // The number of seconds that a track has to play before the scrolling starts:
    let _secondsThatScrollingStartsAfterTrackStarts: Double = 38.0

    // The number of seconds that the scrolling ends before the track ends playing:
    let _secondsThatScrollingEndsBeforeTrackEnds: Double = 35.0

    // The frequency in seconds in which the scroll is activated:
    let _lyricsScrollFrequency: Double = 0.35

    // ----- Methods -----

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set notification handler for music changing in the background:
        _controller.setNotificationHandler(self, notificationFunctionName: "setLyricsText")

        // Create an underlying close button also on the scrollview:
        _closeButtonOnScrollView.addTarget(self, action: Selector("closeViewWithoutAction"), forControlEvents: .TouchUpInside)
        _lyricsTextView.addSubview(_closeButtonOnScrollView)

        // Set basic stuff for scrollview:
        _lyricsTextView.scrollEnabled = true

        _lyricsTextView.backgroundColor = UIColor.clearColor()
        _lyricsTextView.textColor = UIColor.whiteColor()
        _lyricsTextView.font = MyBasics.fontForSmallText

        // This is for making it non-editable:
        _lyricsTextView.delegate = self

        // DEBUG println(_controller.currentLyrics())

        view.addSubview(_lyricsTextView)

        setLyricsText()
    }


    //
    // Sets the lyrics text for the currently playing track.
    //
    func setLyricsText() {

        // DEBUG println("LyricsViewController.setLyricsText()")

        // Calculate some general values that are needed for scrolling afterwards. Explanations of the meanings see above.
        _timeValWhenScrollingStarts = _secondsThatScrollingStartsAfterTrackStarts / _controller.durationOfCurrentTrack()
        _timeValWhenScrollingEnds = 1.0 - (_secondsThatScrollingEndsBeforeTrackEnds / _controller.durationOfCurrentTrack())
        _timeRangeValForScrolling = _timeValWhenScrollingEnds - _timeValWhenScrollingStarts

        _lyricsTextView.text = _controller.currentLyrics()

        // The next lines are necessary due to the fact that the size of the lyricsTextView needs to be understood right from the beginning
        // in order to do the automatic scrolling correctly. If we didn't do this, the _lyricsTextView.contentSize.height would change
        // during the course of the playing track.
        _lyricsTextView.sizeToFit()
        _lyricsTextView.layoutIfNeeded()

        // This is the only time where we can fix the real content height. As soon as we re-set the frame of the _lyricsTextView corrently,
        // it will be used lazily again.
        _realContentHeight = _lyricsTextView.frame.height

        // Now we have re-adjust the rest:
        let heightOfCloseButton: CGFloat = (_realContentHeight > CGFloat(self.heightOfView) ? _realContentHeight : CGFloat(self.heightOfView))
        _closeButtonOnScrollView.frame = CGRectMake(CGFloat(xPosOfView), CGFloat(yPosOfView), CGFloat(widthOfView), heightOfCloseButton)
        _lyricsTextView.frame = CGRectMake(CGFloat(xPosOfView) + 10.0, CGFloat(yPosOfView) + 5.0, CGFloat(widthOfView) - 20.0, CGFloat(heightOfView) - 20.0)
        //DEBUG println("-------------")
        //DEBUG println("frame of button: \(_closeButtonOnScrollView.frame)")
        //DEBUG println("frame of lyricsTextView: \(_lyricsTextView.frame)")
        //DEBUG println("real content height: \(_realContentHeight)")
        //DEBUG println("-------------")

        // For the case that we previously showed some lyrics of a different track, rewind to the top:
        UIView.jumpSpringyToPosition(_lyricsTextView, pointToJumpTo: CGPoint(x: 0.0, y: 0.0))

        if _realContentHeight >= CGFloat(self.heightOfView) {

            // Set the progress timer in order to be able to update the lyrics position:
            _progressTimer = NSTimer.scheduledTimerWithTimeInterval(
                _lyricsScrollFrequency,
                target: self,
                selector: "updateLyricsPosition",
                userInfo: nil,
                repeats: true)
            // DEBUG println("Progress timer set.")

        } else {
            // DEBUG println("Lyrics are smaller than screen height => No scrolling necessary")
        }
    }


    //
    // Updates the position of the displayed lyrics depending on the track's progress.
    //
    func updateLyricsPosition() {

        // DEBUG println("LyricsViewController.updateLyricsPosition")

        // The current progress value is a value between 0.0 and 1.0, representing the progress of the playing track:
        let currentProgressValue: Double = _controller.progressOfCurrentlyPlayingTrack()

        // The position on the scroll view is the value that the scrollview need to jump to in order to
        // show the progress of the track. Initially, this is simply the product of the complete height and the progress value:
        var positionOnScrollView: CGFloat = 0.0

        // Calculate the position on the scroll view based on the progress of the track playing:
        calculatePositionOnScrollview(currentProgressValue, position: &positionOnScrollView)

        // Slide smoothly to the new position:
        UIView.slideSmoothlyToPosition(_lyricsTextView, pointToSlideTo: CGPoint(x: 0.0, y: positionOnScrollView))

        // Again we have to take care of the fact that the textView's contentSize may be layzily handled and have a height smaller than the final height value:
        if positionOnScrollView > _lyricsTextView.contentSize.height {

            // We really found a case where the size is not fully grown, yet.
            // This may happen if the track has played almost to the end and the user then start looking at the lyrics.

            // Set the height of the textView's content size manually:
            // DEBUG println("Content height not final, yet: \(positionOnScrollView) > \(_lyricsTextView.contentSize.height) => Setting height to \(_realContentHeight).")
            _lyricsTextView.contentSize.height = _realContentHeight

        } else {

            // Check whether we have come to an end:
            let maxPosition: CGFloat = _realContentHeight - CGFloat(self.heightOfView) + CGFloat(2 * self.yPosOfView)
            if positionOnScrollView >= maxPosition {

                // We can stop scrolling
                // DEBUG println("Maximum position reached.")
                stopAutomaticLyricsScrolling()
            }
        }
    }


    //
    // Calculates the y-position of the currently playing track in order to find a nice looking position.
    // currentlProgressValue has a value between 0.0 and 1.0.
    //
    func calculatePositionOnScrollview(currentProgressValue: Double, inout position: CGFloat) {

        if currentProgressValue < _timeValWhenScrollingStarts {

            // The progress is in the very beginnings. => Do not scroll, yet and stay at the top:
            position = 0.0
            return
        }

        // If we are still here, we are in scrolling mode.

        // Calculate the window height in the norm area between 0.0 and 1.0:
        let valOfWindowHeight: Double = Double(self.heightOfView) / Double(_realContentHeight)

        // The maximum value for the scrolling position to reach in the norm area is a window height before the end:
        let maxVal: Double = (1.0 - valOfWindowHeight) * 1.05

        // The position value, based on the norm area between 0.0. and 1.0:
        let positionVal: Double = ((currentProgressValue - _timeValWhenScrollingStarts) / _timeRangeValForScrolling) * maxVal

        // Calculate the position on the scroll view by taking the position in the norm area and looking at it in relation to the scrollview's height:
        position = CGFloat(positionVal) * _realContentHeight

        // DEBUG println("maxVal: \(maxVal), positionVal: \(positionVal), position: \(position)")
    }


    //
    // This function is called whenever the user is actually scrolling manually.
    // For the automatic lyrics scrolling this means that it is stopped.
    //
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {

        // DEBUG println("LyricsViewController.scrollViewDidEndDragging()")
        stopAutomaticLyricsScrolling()
    }


    //
    // Stops the automatic lyrics scrolling by stopping the timer for the updates.
    //
    func stopAutomaticLyricsScrolling() {

        if _progressTimer != nil {

            _progressTimer.invalidate()
            // DEBUG println("Automatic scrolling stopped")
        }
    }


    //
    // Closes the view without any further action.
    //
    override func closeViewWithoutAction() {

        // DEBUG println("LyricsViewController.closeViewWithoutAction()")

        // Stop the progress timer:
        stopAutomaticLyricsScrolling()

        super.closeViewWithoutAction()
    }


    //
    // We override this method in order to disable editing.
    //
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {

        return false
    }
}

