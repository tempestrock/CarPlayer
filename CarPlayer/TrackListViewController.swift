//
//  TrackListViewController.swift
//  CarPlayer
//
//  Created by Peter Störmer on 18.12.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer


//
// A view controller to show the list of tracks in a modal view.
//
class TracklistViewController: ModalViewController {

    var scrollView: UIScrollView!
    var _initialSetup: Bool = true

    
    override func viewDidLoad() {

        super.viewDidLoad() // Paints the black background rectangle

        // Set notification handler for music changing in the background. The complete track list is re-painted
        _controller.setNotificationHandler(self, notificationFunctionName: "createTrackList")

        createTrackList()
    }


    //
    // Creates the complete track list.
    //
    func createTrackList() {

        // DEBUG println("TrackListViewController.createTrackList()")

        // Set some hard-coded limit for the number of tracks to be shown:
        let maxNum = MyBasics.TrackListView_MaxNumberOfTracks

        // Find out whether we are creating the tracklist for the first time:
        _initialSetup = (scrollView == nil)

        if _initialSetup {

            // This is the initial setup of the scroll view.

            scrollView = UIScrollView()

            // Create an underlying close button also on the scrollview:
            let closeButtonOnScrollView = UIButton(type: UIButtonType.Custom)
            var ySizeOfButton = CGFloat(_controller.currentPlaylist().count * yPosOfView * 2 + yPosOfView)
            if ySizeOfButton < CGFloat(heightOfView) - 20.0 {
                ySizeOfButton = CGFloat(heightOfView) - 20.0
            }
            closeButtonOnScrollView.addTarget(self, action: Selector("closeViewWithoutAction"), forControlEvents: .TouchUpInside)
            closeButtonOnScrollView.frame = CGRectMake(CGFloat(xPosOfView) + 10.0, CGFloat(yPosOfView) + 5.0, CGFloat(widthOfView) - 20.0, ySizeOfButton)
            scrollView.addSubview(closeButtonOnScrollView)

            // Set basic stuff for scrollview:
            scrollView.scrollEnabled = true
            scrollView.frame = CGRectMake(CGFloat(xPosOfView), CGFloat(yPosOfView) + 5.0,
                CGFloat(widthOfView) - 20.0, CGFloat(heightOfView) - 20.0)
        }

        // Variable to keep the y position of the now playing item:
        var yPosOfNowPlayingItem: CGFloat = -1.0

        // Fill the scrollview with track names:
        var curYPos: Int = 0
        var counter: Int = 1
        for track in _controller.currentPlaylist() {

            // Set the text color depending on whether we show the name of the currently playing item or not:
            var labelTextColor: UIColor
            if track == _controller.nowPlayingItem() {

                labelTextColor = UIColor.darkGrayColor()
                yPosOfNowPlayingItem = CGFloat(curYPos)

            } else {

                labelTextColor = UIColor.whiteColor()
            }

            // Make a label for the counter:
            let number = UILabel()
            number.text = counter.description
            number.font = MyBasics.fontForMediumText
            number.textColor = labelTextColor
            number.textAlignment = NSTextAlignment.Right
            number.frame = CGRect(x: 0.0, y: CGFloat(curYPos) + 7.5, width: CGFloat(60), height: CGFloat(2 * yPosOfView))
            scrollView.addSubview(number)

            // Make a small album artwork for an easier identification if an artwork exists:
            if (track.artwork != nil) {

                let sizeOfArtistImage = CGSize(width: MyBasics.TrackListView_ArtistImage_Width, height: MyBasics.TrackListView_ArtistImage_Height)
                let albumCoverImage: UIImageView = UIImageView()
                albumCoverImage.image = track.artwork!.imageWithSize(sizeOfArtistImage)
                albumCoverImage.frame = CGRectMake(70, CGFloat(curYPos) + 10,
                    CGFloat(MyBasics.TrackListView_ArtistImage_Width), CGFloat(MyBasics.TrackListView_ArtistImage_Height))
                scrollView.addSubview(albumCoverImage)
            }

            // Make a button for the actual track title:
            let button = UIButtonWithFeatures(type: UIButtonType.Custom)
            button.setTitle(track.title!, forState: .Normal)
            button.titleLabel!.font = MyBasics.fontForMediumText
            button.setTitleColor(labelTextColor, forState: UIControlState.Normal)
            button.titleLabel!.textAlignment = NSTextAlignment.Left
            button.frame = CGRect(x: 110, y: curYPos, width: widthOfView, height: heightOfView)  // width and height are just dummies due to following "sizeToFit"
            button.sizeToFit()
            button.addTarget(self, action: Selector("trackNameTapped:"), forControlEvents: UIControlEvents.TouchUpInside)
            button.setMediaItem(track)
            scrollView.addSubview(button)

            // Increase y position:
            curYPos += 2 * yPosOfView
            counter += 1

            if counter > maxNum {
                break
            }
        }

        if _initialSetup {

            scrollView.contentSize = CGSizeMake(CGFloat(widthOfView) - 20.0, CGFloat(curYPos + yPosOfView));
            scrollView.contentOffset = CGPoint(x: 0, y: 0)
        }

        view.addSubview(scrollView)

        // Tweak the y-position of the currently playing item in order to find a nice looking position:
        tweakYPosOfNowPlayingItem(curYPos, scrollView: scrollView, yPosOfNowPlayingItem: &yPosOfNowPlayingItem)

        // Force jumping to the new y position into a different runloop.
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {

            self.jumpToPosition(yPosOfNowPlayingItem)
        }
    }


    //
    // Tweaks the y-position of the currently playing item in order to find a nice looking position.
    //
    func tweakYPosOfNowPlayingItem(totalHeightOfScrollView: Int, scrollView: UIScrollView, inout yPosOfNowPlayingItem: CGFloat) {

        let minVal: CGFloat = 80.0
        let maxVal: CGFloat = scrollView.contentSize.height - CGFloat(self.heightOfView) + CGFloat(self.yPosOfView / 2)

        // DEBUG println("yPosOfNowPlayingItem: \(yPosOfNowPlayingItem), maxVal: \(maxVal)")

        if totalHeightOfScrollView < self.heightOfView {

            // The list is smaller than the screen height. => Set the scroll position to the top:
            // DEBUG println("list is smaller than screen height")
            yPosOfNowPlayingItem = 0

            return
        }

        if yPosOfNowPlayingItem < minVal {

            // This track is among the first ones or not on the list (if it is -1). => Move to the top:
            yPosOfNowPlayingItem = 0
            // DEBUG println("track is one of the first tracks => moving yPos to the top")

            return
        }

        yPosOfNowPlayingItem -= minVal
        // DEBUG println("track is in mid range => moving yPos up by \(minVal) to \(yPosOfNowPlayingItem)")

        if yPosOfNowPlayingItem >= maxVal {

            // DEBUG println("yPos too high -> setting yPos to \(maxVal)")
            yPosOfNowPlayingItem = maxVal
        }
    }


    //
    // Jumps the scroll view to the position of the currently playing track.
    //
    func jumpToPosition(yPosOfNowPlayingItem: CGFloat) {

        UIView.jumpSpringyToPosition(scrollView, pointToJumpTo: CGPoint(x: 0.0, y: yPosOfNowPlayingItem))
    }


    //
    // This function is called whenever a track name has been tapped on.
    // The chosen track is found out, the music player is switched to that track, and the modal view closes.
    //
    func trackNameTapped(sender: UIButtonWithFeatures) {

      //  var trackName: String = sender.mediaItem().title!
        // DEBUG println("New track title: \"\(trackName)\"")

        // Set the chosen track:
        _controller.setTrack(sender.mediaItem())

        // Close this view:
//        dismissViewControllerAnimated(true, completion: nil)  // Feature: We do not close the view! :)
    }
}
