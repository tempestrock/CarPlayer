//
//  MyBasics.swift
//  CarPlayer
//
//  Created by Peter Störmer on 29.11.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

import Foundation
import UIKit



//
// A class for basic constants. A collection of global constants.
//
class MyBasics {

    // ------------- Names of view controllers ---------------

    class var nameOfInitialView: String {
        get {
            return "InitialViewController"
        }
    }

    class var nameOfMainView: String {
        get {
            return "MainViewController"
        }
    }

    class var nameOfAlbumView: String {
        get {
            return "AlbumViewController"
        }
    }

    class var nameOfPlayerView: String {
        get {
            return "PlayerViewController"
        }
    }

    class var nameOfSpeedView: String {
        get {
            return "SpeedViewController"
        }
    }


    // ------------- Names of image files ---------------

    class var nameOfImage_Launch: String {
        get {
            return "Launchpicture.jpg"
        }
    }

    class var nameOfImage_CarIcon: String {
        get {
            return "CarIcon.png"
        }
    }
    
    class var nameOfImage_CarIconFromBehind: String {
        get {
            return "CarIconFromBehind.png"
        }
    }

    

    // ------------- Names of segues ---------------

    class var nameOfSegue_initialToMain: String {
        get {
            return "initialToMainSegue"
        }
    }

    class var nameOfSegue_mainToAlbum: String {
        get {
            return "mainToAlbumSegue"
        }
    }

    class var nameOfSegue_mainToPlayer: String {
        get {
            return "mainToPlayerSegue"
        }
    }

    class var nameOfSegue_mainToSpeed: String {
        get {
            return "mainToSpeedSegue"
        }
    }

    class var nameOfSegue_albumToPlayer: String {
        get {
            return "albumToPlayerSegue"
        }
    }

    class var nameOfSegue_playerToSpeed: String {
        get {
            return "playerToSpeedSegue"
        }
    }


    // ------------- Fonts ---------------

    class var fontForHugeText: UIFont {
        get {
            return UIFont(name: "AvenirNext-UltraLight", size: 70)!
        }
    }

    class var fontForLargeText: UIFont {
        get {
            return UIFont(name: "AvenirNext-UltraLight", size: 50)!
        }

    }

    class var fontForMediumText: UIFont {
        get {
            return UIFont(name: "AvenirNext-UltraLight", size: 30)!
        }

    }

    class var fontForMediumBoldText: UIFont {
        get {
            return UIFont(name: "AvenirNext-Medium", size: 23)!
        }

    }
    
    class var fontForSmallText: UIFont {
        get {
            return UIFont(name: "AvenirNext-Medium", size: 19)!
        }
    }

    class var fontForSmallThinText: UIFont {
        get {
            return UIFont(name: "AvenirNext-UltraLight", size: 19)!
        }
    }

    class var fontForVerySmallText: UIFont {
        get {
            return UIFont(name: "AvenirNext-Medium", size: 14)!
        }
    }


    // ------------- Limits ---------------

    // The maximum number of tracks shown in the track list:
    class var TrackListView_MaxNumberOfTracks: Int {
        get {
            return 400
        }
    }
    
    // ------------- Times ---------------

    // The time in seconds for one animation back and forth.
    class var PlayerView_TimeForAnimation: Double {
        get {
            return 10.0
        }
    }

    class var SpeedView_TimeForAnimation: Double {
        get {
            return PlayerView_TimeForAnimation
        }
    }

    // The time in seconds before the next animation starts.
    class var PlayerView_TimeForToWaitForNextAnimation: Double {
        get {
            return 2.0
        }
    }

    class var SpeedView_TimeForToWaitForNextAnimation: Double {
        get {
            return PlayerView_TimeForToWaitForNextAnimation
        }
    }


    // ------------- Constants for screen positions and sizes ---------------

    class var screenWidth: Int {
        get {
            return 1334 / 2
        }
    }

    class var screenHeight: Int {
        get {
            return 750 / 2
        }
    }

    class var ArtWork_InitialXPos: Int {
        get {
            return 10
        }
    }

    class var ArtWork_YPos: Int {
        get {
            return 0
        }
    }
    
    class var ArtWork_Width: Int {
        get {
            return 290
        }
    }

    class var ArtWork_Height: Int {
        get {
            return 290
        }
    }

    class var ArtWork_LabelHeight: Int {
        get {
            return 20
        }
    }

    class var PlayerView_ArtistLabel_XPos: CGFloat {
        get {
            return 220.0
        }
    }

    class func PlayerView_ArtistLabel_YPos(displayMode: Int) -> CGFloat {

        switch displayMode {

        case 0: // off
            return PlayerView_ProgressBar_YPos(displayMode) - 100.0
        case 1: // speed only
            return PlayerView_ProgressBar_YPos(displayMode) - 100.0
        case 2: // all
            return PlayerView_ProgressBar_YPos(displayMode) - 78.0
        default:
            assert(false, "MyBasics.PlayerView_ArtistLabel_YPos(): displayMode \(displayMode) unknown")
            return 0.0
        }
    }

    class var PlayerView_ArtistLabel_Width: CGFloat {
        get {
            return CGFloat(screenWidth) * 0.64
        }
    }

    class var PlayerView_ArtistLabel_Height: CGFloat {
        get {
            return 70.0
        }
    }

    class func PlayerView_FrameForArtistLabel(displayMode: Int) -> CGRect {

        return CGRect(
            origin: CGPoint(x: PlayerView_ArtistLabel_XPos, y: PlayerView_ArtistLabel_YPos(displayMode)),
            size: CGSize(width: PlayerView_ArtistLabel_Width, height: PlayerView_ArtistLabel_Height))
    }
    
    class func PlayerView_LeftPositionOfArtistLabel(displayMode: Int) -> CGPoint {

        return CGPoint(x: PlayerView_ArtistLabel_XPos, y: PlayerView_ArtistLabel_YPos(displayMode))

    }

    class func PlayerView_RightPositionOfArtistLabel(displayMode: Int) -> CGPoint {

        return CGPoint(
            x: PlayerView_ArtistLabel_XPos + PlayerView_ArtistLabel_Width,
            y: PlayerView_ArtistLabel_YPos(displayMode)
        )
    }
    
    class func PlayerView_ProgressBar_XPos(displayMode: Int) -> CGFloat {

        switch displayMode {

        case 0: // off
            return 17.0
        case 1: // speed only
            return 17.0
        case 2: // all
            return PlayerView_ArtistLabel_XPos
        default:
            assert(false, "MyBasics.PlayerView_ProgressBar_XPos(): displayMode \(displayMode) unknown")
            return 0.0
        }
    }

    class func PlayerView_ProgressBar_YPos(displayMode: Int) -> CGFloat {

        switch displayMode {

        case 0: // off
            return PlayerView_TrackTitleLabel_YPos(displayMode) - 25.0
        case 1: // speed only
            return PlayerView_TrackTitleLabel_YPos(displayMode) - 25.0
        case 2: // all
            return PlayerView_TrackTitleLabel_YPos(displayMode) - 10.0
        default:
            assert(false, "MyBasics.PlayerView_ProgressBar_YPos(): displayMode \(displayMode) unknown")
            return 0.0
        }
    }

    class func PlayerView_ProgressBar_Width(displayMode: Int) -> CGFloat {

        switch displayMode {

        case 0: // off
            return CGFloat(screenWidth) - 2 * PlayerView_ProgressBar_XPos(displayMode)
        case 1: // speed only
            return CGFloat(screenWidth) - 2 * PlayerView_ProgressBar_XPos(displayMode)
        case 2: // all
            return PlayerView_ArtistLabel_Width
        default:
            assert(false, "MyBasics.PlayerView_ProgressBar_Width(): displayMode \(displayMode) unknown")
            return 0.0
        }
    }

    class var PlayerView_ProgressBar_Height: CGFloat {
        get {
            return 2.0
        }
    }

    class func PlayerView_FrameForProgressBar(displayMode: Int) -> CGRect {

        return CGRect(
            origin: CGPoint(x: PlayerView_ProgressBar_XPos(displayMode), y: PlayerView_ProgressBar_YPos(displayMode)),
            size: CGSize(width: PlayerView_ProgressBar_Width(displayMode), height: PlayerView_ProgressBar_Height)
        )
    }
    
    class func PlayerView_TrackTitleLabel_XPos(displayMode: Int) -> CGFloat {

        switch displayMode {

        case 0: // off
            return 30.0
        case 1: // speed only
            return PlayerView_ArtistLabel_XPos
        case 2: // all
            return PlayerView_ArtistLabel_XPos
        default:
            assert(false, "MyBasics.PlayerView_TrackTitleLabel_XPos(): displayMode \(displayMode) unknown")
            return 0.0
        }
    }

    class func PlayerView_TrackTitleLabel_YPos(displayMode: Int) -> CGFloat {

        switch displayMode {

        case 0: // off
            return 280.0
        case 1: // speed only
            return 280.0
        case 2: // allç
            return 175.0
        default:
            assert(false, "MyBasics.PlayerView_TrackTitleLabel_YPos(): displayMode \(displayMode) unknown")
            return 0.0
        }
    }

    class func PlayerView_TrackTitleLabel_Width(displayMode: Int) -> CGFloat {

        switch displayMode {

        case 0: // off
            return PlayerView_ArtistLabel_Width + 190
        case 1: // speed only
            return PlayerView_ArtistLabel_Width
        case 2: // all
            return PlayerView_ArtistLabel_Width
        default:
            assert(false, "MyBasics.PlayerView_TrackTitleLabel_Width(): displayMode \(displayMode) unknown")
            return 0.0
        }
    }

    class var PlayerView_TrackTitleLabel_Height: CGFloat {
        get {
            return 70.0
        }
    }

    class func PlayerView_LeftPositionOfTrackTitle(displayMode: Int) -> CGPoint {

        return CGPoint(x: PlayerView_TrackTitleLabel_XPos(displayMode), y: PlayerView_TrackTitleLabel_YPos(displayMode))

    }

    class func PlayerView_RightPositionOfTrackTitle(displayMode: Int) -> CGPoint {

        return CGPoint(
            x: PlayerView_TrackTitleLabel_XPos(displayMode) + PlayerView_TrackTitleLabel_Width(displayMode),
            y: PlayerView_TrackTitleLabel_YPos(displayMode)
        )
    }

    class func PlayerView_SizeForTrackTitle(displayMode: Int) -> CGSize {

        return CGSize(width: PlayerView_TrackTitleLabel_Width(displayMode), height: PlayerView_TrackTitleLabel_Height)
    }

    class func PlayerView_FrameForTrackTitle(displayMode: Int) -> CGRect {

        return CGRect(
            origin: CGPoint(x: PlayerView_TrackTitleLabel_XPos(displayMode), y: PlayerView_TrackTitleLabel_YPos(displayMode)),
            size: PlayerView_SizeForTrackTitle(displayMode)
        )
    }
    
    class var PlayerView_ArtistImage_Width: CGFloat {
        get {
            return 200.0
        }
    }

    class var PlayerView_ArtistImage_Height: CGFloat {
        get {
            return 200.0
        }
    }

    class var PlayerView_speed_yPos: CGFloat {
        get {
            return 280.0-25.0
        }
    }

    class func PlayerView_SliderButtons_YPos(displayMode: Int) -> CGFloat {

        return PlayerView_ProgressBar_YPos(displayMode)
    }

    class func PlayerView_SliderButtons_XStartPos(displayMode: Int) -> CGFloat {

        return PlayerView_ProgressBar_XPos(displayMode)
    }

    class func PlayerView_SliderButtons_SliderWidth(displayMode: Int) -> CGFloat {

        return PlayerView_ProgressBar_Width(displayMode)
    }

    class var PlayerView_SliderButtons_ButtonHeight: CGFloat {
        get {
            return 60.0
        }
    }

    class var PlayerView_AlbumLabel_XPos: CGFloat {
        get {
            return 0.0
        }
    }

    class var PlayerView_AlbumLabel_YPos: CGFloat {
        get {
            return PlayerView_ArtistImage_Height
        }
    }

    class var PlayerView_AlbumLabel_Width: CGFloat {
        get {
            return PlayerView_ArtistImage_Width
        }
    }

    class var PlayerView_AlbumLabel_Height: CGFloat {
        get {
            return 40.0
        }
    }

    class var PlayerView_FrameForAlbumLabel: CGRect {
        get {
            return CGRect(
                origin: CGPoint(x: PlayerView_AlbumLabel_XPos, y: PlayerView_AlbumLabel_YPos),
                size: CGSize(width: PlayerView_AlbumLabel_Width, height: PlayerView_AlbumLabel_Height))
        }
    }

    class var SpeedView_speed_yPos: CGFloat {
        get {
            return 50.0
        }
    }

    class var SpeedView_CarIcon_Height: CGFloat {
        get {
            return 42.0
        }
    }

    class var SpeedView_CarIcon_Width: CGFloat {
        get {
            return SpeedView_CarIcon_Height * (2.0/3.0)
        }
    }

    class var SpeedView_Map_XPos: CGFloat {
        get {
            return CGFloat(screenWidth) * (7.0/18.0)
        }
    }

    class var SpeedView_Map_Width: CGFloat {
        get {
            return CGFloat(screenWidth) - SpeedView_Map_XPos
        }
    }

    class var SpeedView_Map_Height: CGFloat {
        get {
            return SpeedView_TrackInfoLabel_YPos - 10.0
        }
    }

    class var SpeedView_Info_Width: CGFloat {
        get {
            return SpeedView_Map_XPos
        }
    }

    class var SpeedView_TrackInfoLabel_XPos: CGFloat {
        get {
            return 10.0
        }
    }

    class var SpeedView_TrackInfoLabel_YPos: CGFloat {
        get {
            return CGFloat(screenHeight) - 7 - SpeedView_TrackInfoLabel_Height
        }
    }

    class var SpeedView_TrackInfoLabel_Width: CGFloat {
        get {
            return CGFloat(screenWidth) - 2 * SpeedView_TrackInfoLabel_XPos
        }
    }

    class var SpeedView_TrackInfoLabel_Height: CGFloat {
        get {
            return 25.0
        }
    }
    
    class var TrackListView_ArtistImage_Width: CGFloat {
        get {
            return 32.0
        }
    }

    class var TrackListView_ArtistImage_Height: CGFloat {
        get {
            return 32.0
        }
    }
    

}
