//
//  SpeedViewController.swift
//  CarPlayer
//
//  Created by Peter Störmer on 30.12.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

import Foundation
import UIKit


class SpeedViewController: UIViewController, GMSMapViewDelegate /* necessary for the display of addresses */ {

    // ----- Enums ----------------

    // An enum to define the "swipe back gesture":
    enum DirectionToSwipeBack {

        case Up
        case Down
    }

    // The kinds of maps that can be chosen:
    enum MapType: Int {

        case Normal = 0
        case Hybid
        case Satellite
        case Terrain
    }
    let MapTypeCount: Int = 4

    // The zoom levels for the maps:
    enum ZoomLevel: Float {

        case fastAutobahn = 11.0
        case standardAutobahn = 12.0
        case countrystreet = 13.0
        case seventierCountrystreet = 14.0
        case innenCity = 15.0
        case thirtierZone = 16.25
        case spielstreet = 16.75
    }


    // ----- Attributes ----------------

    // The two gestures to get out of the speed view again:
    @IBOutlet weak var _swipeGestureDown: UISwipeGestureRecognizer!
    @IBOutlet weak var _swipeGestureUp: UISwipeGestureRecognizer!

    // Speed display:
    var _mapView: GMSMapView!
    var _addressLabel: UILabel!
    var _speedLabel: UILabel!
    var _longLabel: UILabel!
    var _latLabel: UILabel!
    var _altLabel: UILabel!

    // The car icon and its current transformation (rotation and scale):
    var _carIcon: UIImageView!
    var _carIconTransformation: CGAffineTransform!
    var _carIconCurrentRotation: CGAffineTransform!
    var _carIconCurrentScale: CGAffineTransform!

    // The current type of map:
    var _currentMapType: MapType! = MapType.Normal

    // A flag that says whether or not the user is currently scaling the map themselves:
    var _manualMapScaling: Bool = false

    // The current speed that is used to define the scale of the map:
    var _currentSpeed: Int = -1

    // The current course that is needed for the rotation of the car icon:
    var _currentCourse: Double = -1

    // Timer to watch the progress of a song playing:
    var _progressTimer: NSTimer!

    // The progress bar at the bottom of the page:
    @IBOutlet weak var _progressBar: UIProgressView!

    // Label and container for the animation of the track information (i.e. artist, album, and track name):
    var _trackInfoLabel: UILabel!
    var _trackInfoContainerView: UIView!
    var _trackInfoLabelStartingFrame: CGRect!
    var _trackInfoTextMoveTimer: NSTimer = NSTimer()


    // DEBUG variables:
    // DBUG var _tmpZoomLabel: UILabel! = UILabel()
    var _tmpSpeedDirection: Int = 1


    // ----- Methods ----------------

    //
    // This function is called whenever the user reaches the speed view.
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        // DEBUG print("SpeedViewController.viewDidLoad()")

        // Create some test calls:
        //DEBUG NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "createTestData", userInfo: nil, repeats: true)

        // Set notification handler for music changing in the background:
        _controller.setNotificationHandler(self,
                                           notificationFunctionName: #selector(SpeedViewController.receivedNotificationOfChange(_:)))

        // Set the progress timer to update the progress bar:
        _progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self,
                                                                selector: #selector(SpeedViewController.progressTimerFired),
                                                                userInfo: nil, repeats: true)

        // Set some parameters for the map:
        setMapSpecifics()

        // Create the speed display:
        createSpeedDisplay()

        // It may be that the locator takes some time before it actually calls the notifier function for the first time.
        // In that time, default text is displayed:
        showDefaultValues()

        // Print out the track information (artist, album, track name):
        setTrackInfo()
    }


    //
    // Creates test data for the location and calls the according functions.
    //
    func createTestData() {

        // Test data:
//        var speed: Int = _currentSpeed + (Int(arc4random_uniform(15)) * _tmpSpeedDirection)
        var speed: Int = _currentSpeed + (9 * _tmpSpeedDirection)
        let course: Double = Double(arc4random_uniform(360))
        let coord = CLLocationCoordinate2D(latitude: 50.93, longitude: 6.955)

        // Check if the speed change needs a change in direction:
        if speed > 160 {
            if _tmpSpeedDirection > 0 {
                _tmpSpeedDirection = -1
                print("Starting to slow down.")
            }
        } else if speed < 0 {
            speed = 1
            _tmpSpeedDirection = 1
            print("Starting to speed up.")
        }

        newCoordinatesArrived(speed, lat: "050° 55.8' N", long: "006° 57.3' E", alt: "54 m", courseStr: course.description, course: course, coord: coord)
    }


    //
    // This function gets called whenever the progress timer fires.
    //
    func progressTimerFired() {

        // DEBUG print("SpeedViewController.progressTimerFired()")

        // Show current playback progress:
        _progressBar.progress = Float(_controller.currentPlaybackTime() / _controller.nowPlayingItem().playbackDuration)
    }


    //
    // Receives notifications of the form MPMusicPlayerControllerPlaybackStateDidChangeNotification
    //
    func receivedNotificationOfChange(notification: NSNotification) {

        // DEBUG print("SpeedViewController.receivedNotificationOfChange()")
        setTrackInfo()
    }
    

    //
    // Creates the map and sets some map specific parameters.
    //
    func setMapSpecifics() {

        // --- The map ---

        // Create the map:
        _mapView = GMSMapView(frame: CGRectMake(MyBasics.SpeedView_Map_XPos, 0.0, MyBasics.SpeedView_Map_Width, MyBasics.SpeedView_Map_Height))

        // Initially enable a light blue dot where the user is located:
        _mapView.myLocationEnabled = true

        // Disable a button on the map that centers the user’s location when tapped:
        _mapView.settings.myLocationButton = false

        // Disable user interaction:
        _mapView.settings.scrollGestures = false
        _mapView.settings.zoomGestures = false
        _mapView.settings.tiltGestures = false
        _mapView.settings.rotateGestures = false

        // Set the initial map type:
        _savior.loadMapType(&_currentMapType!)
        switchMapToMapType(_currentMapType)

        // Declare the map view controller the delegate of the map view. This invokes the calls to the function "mapView()" below.
        _mapView.delegate = self

        // Initially zoom to "extremely near":
        _mapView.animateToZoom(ZoomLevel.innenCity.rawValue)

        // Add the map to the view:
        view.addSubview(_mapView)

        // --- Car icon ---

        // Create the car icon in the middle of the map:
        _carIcon = UIImageView(image: UIImage(named: MyBasics.nameOfImage_CarIcon))
        _carIcon.frame = CGRectMake(MyBasics.SpeedView_Map_XPos + MyBasics.SpeedView_Map_Width/2.0 - MyBasics.SpeedView_CarIcon_Width/2.0,
            MyBasics.SpeedView_Map_Height/2.0 - MyBasics.SpeedView_CarIcon_Height/2.0,
            MyBasics.SpeedView_CarIcon_Width, MyBasics.SpeedView_CarIcon_Height)
        _carIcon.alpha = 0.0
        view.addSubview(_carIcon)

        // Start with an initial car icon transformation that does nothing:
        _carIconTransformation = CGAffineTransformIdentity
        _carIconCurrentRotation = CGAffineTransformIdentity
        _carIconCurrentScale = CGAffineTransformIdentity

        // --- Address label ---

        // Create the address label
        _addressLabel = UILabel(frame: CGRectMake(MyBasics.SpeedView_Map_XPos, MyBasics.SpeedView_Map_Height - 30.0, MyBasics.SpeedView_Map_Width, 30.0))
        _addressLabel.textAlignment = NSTextAlignment.Center
        _addressLabel.font = MyBasics.fontForMediumBoldText
        _addressLabel.textColor = UIColor.whiteColor()

        // Do not initially show the address label (and its gray background):
        _addressLabel.alpha = 0.0

        // Add the address label to the view:
        view.addSubview(_addressLabel)


        // Tell the locator to call the "newCoordinatesArrived" function as soon as new coordinates have arrived:
        _locator.setNotifierFunction(newCoordinatesArrived)

/*
        // --------- TEMP -------------
        _tmpZoomLabel = UILabel(frame: CGRectMake(5.0, 5.0, 100.0, 35.0))
        _tmpZoomLabel.font = MyBasics.fontForMediumText
        _tmpZoomLabel.textColor = UIColor.whiteColor()
        view.addSubview(_tmpZoomLabel)
*/
    }


    //
    // Creates the actual labels on the speed display.
    //
    func createSpeedDisplay() {

  //      let fullWidth: CGFloat = CGFloat(MyBasics.screenWidth)

        let yPosGap: CGFloat = CGFloat(MyBasics.screenHeight) / 5
        let labelHeight = yPosGap

        // Speed label:
        _speedLabel = UILabel()
        _speedLabel.frame = CGRectMake(0, MyBasics.SpeedView_speed_yPos, MyBasics.SpeedView_Info_Width, labelHeight)
        _speedLabel.font = MyBasics.fontForHugeText
        _speedLabel.textAlignment = NSTextAlignment.Center
        _speedLabel.textColor = UIColor.whiteColor()
        view.addSubview(_speedLabel)

        // Altitude:
        _altLabel = UILabel()
        _altLabel.frame = CGRectMake(0, CGFloat(MyBasics.screenHeight/2) - 0.5 * labelHeight, MyBasics.SpeedView_Info_Width, labelHeight)
        _altLabel.font = MyBasics.fontForMediumText
        _altLabel.textAlignment = NSTextAlignment.Center
        _altLabel.textColor = UIColor.whiteColor()
        view.addSubview(_altLabel)

        // Longitude and latitude labels:
        _latLabel = UILabel()
        _latLabel.frame = CGRectMake(0, MyBasics.SpeedView_Map_Height - 1.6 * labelHeight, MyBasics.SpeedView_Info_Width, labelHeight)
        _latLabel.font = MyBasics.fontForMediumText
        _latLabel.textAlignment = NSTextAlignment.Center
        _latLabel.textColor = UIColor.whiteColor()
        view.addSubview(_latLabel)
        _longLabel = UILabel()
        _longLabel.frame = CGRectMake(0, MyBasics.SpeedView_Map_Height - labelHeight, MyBasics.SpeedView_Info_Width, labelHeight)
        _longLabel.font = MyBasics.fontForMediumText
        _longLabel.textAlignment = NSTextAlignment.Center
        _longLabel.textColor = UIColor.whiteColor()
        view.addSubview(_longLabel)
    }


    //
    // Shows initial default values for the case that the locator has not called the notifier function, yet.
    //
    func showDefaultValues() {

        _speedLabel.text = Locator.defaultSpeedString
        _latLabel.text = _locator.defaultLatitude()
        _longLabel.text = _locator.defaultLongitude()
        _altLabel.text = _locator.defaultAltitude()
        _carIcon.alpha = 0.0    // invisible
    }


    //
    // Sets the track information, i.e. the currently playing artist, album, track data.
    //
    func setTrackInfo() {

        if !_controller.nowPlayingItemExists() || !_controller.musicPlayerIsPlaying() {

            // Nothing to show
            _progressBar.alpha = 0.0

            return
        }

        let nowPlayingItem = _controller.nowPlayingItem()

        // If the text move timer is still running, stop it:
        stopTextMoveTimer()

        // Reset the artist and the song title label in order to get rid of previous animations
        // and create new animation containers:
        createLabelContainerForAnimation()

        // Set the actual text of the label:
        _trackInfoLabel.text = nowPlayingItem.artist! + ": " + nowPlayingItem.title! + " (" + nowPlayingItem.albumTitle! + ")"
        _progressBar.alpha = 1.0

        // Embed the track info label into the previously built container in order to animate the text if is too long to be displayed at once:
        createLabelAnimation(_trackInfoLabel,
            width: MyBasics.SpeedView_TrackInfoLabel_Width, height: MyBasics.SpeedView_TrackInfoLabel_Height,
            startingFrame: &_trackInfoLabelStartingFrame,
            timerFuncToCall: #selector(SpeedViewController.trackInfoTextMoveTimerFired),
            animationFunction: trackInfoTextMoveTimerFired,
            timer: &_trackInfoTextMoveTimer
        )
    }


    //
    // Creates a container for the animated label of the track info (artist, album and the song title).
    // A possibly existing previous label is deleted.
    //
    func createLabelContainerForAnimation() {

        // Create the container to put the track info label into:
        _trackInfoContainerView = UIView(frame: CGRect(origin: CGPointMake(MyBasics.SpeedView_TrackInfoLabel_XPos, MyBasics.SpeedView_TrackInfoLabel_YPos),
            size: CGSizeMake(MyBasics.SpeedView_TrackInfoLabel_Width, MyBasics.SpeedView_TrackInfoLabel_Height)))
        _trackInfoContainerView.clipsToBounds = true
        view.addSubview(_trackInfoContainerView)

        // Erase a possible previous version of the track info label:
        if _trackInfoLabel != nil {

            _trackInfoLabel.text = ""
        }

        // Create the track info label itself and place it into the container:
        _trackInfoLabel = UILabel()
        _trackInfoContainerView.addSubview(_trackInfoLabel)
    }


    //
    // Creates a nice label that is moving back and forth if it is too long to be displayed at once.
    //
    func createLabelAnimation(
        labelToAnimate: UILabel,
        width: CGFloat, height: CGFloat,
        inout startingFrame: CGRect!,
        timerFuncToCall: Selector,
        animationFunction: (Void) -> Void,
        inout timer: NSTimer) {

            // Set fonts and sizes for the label:
            labelToAnimate.font = MyBasics.fontForSmallThinText
            labelToAnimate.textColor = UIColor.whiteColor()
            labelToAnimate.sizeToFit()
            startingFrame = labelToAnimate.frame

            // Only do the animation if the text does not fit into the container:
            if startingFrame.width > width {

                timer = NSTimer.scheduledTimerWithTimeInterval(MyBasics.SpeedView_TimeForToWaitForNextAnimation,
                    target: self, selector: timerFuncToCall, userInfo: nil, repeats: false)

                // DEBUG print("\(timer.description) started.")

            } else {

                // The artist label fits into the space => Just do some alignment:
                labelToAnimate.frame = CGRect(x: 0, y: 0, width: width, height: startingFrame.height)
                labelToAnimate.textAlignment = NSTextAlignment.Center
            }
    }
    
    
    //
    // This method is called when the timer for the animation of the track info label is fired.
    //
    func trackInfoTextMoveTimerFired() {

        // DEBUG print("SpeedViewController.trackInfoTextMoveTimerFired()")

        _trackInfoTextMoveTimer = NSTimer.scheduledTimerWithTimeInterval(MyBasics.SpeedView_TimeForAnimation + MyBasics.SpeedView_TimeForToWaitForNextAnimation * 2,
            target: self, selector: #selector(SpeedViewController.trackInfoTextMoveTimerFired), userInfo: nil, repeats: false)

        UIView.animateLongishLabel(_trackInfoLabel, frameAroundLabel: _trackInfoLabelStartingFrame,
            timeForAnimation: MyBasics.SpeedView_TimeForAnimation, timeToWaitForNextAnimation: MyBasics.SpeedView_TimeForToWaitForNextAnimation,
            totalWidth: MyBasics.SpeedView_TrackInfoLabel_Width)
    }


    //
    // Returns the adequate zoom for the map depending on the given speed.
    //
    func mapZoom(speed: Int) -> ZoomLevel {

        switch speed {

            case 3...25: return ZoomLevel.spielstreet
            case 25...42: return ZoomLevel.thirtierZone
            case 43...62: return ZoomLevel.innenCity
            case 63...82: return ZoomLevel.seventierCountrystreet
            case 83...112: return ZoomLevel.countrystreet
            case 113...142: return ZoomLevel.standardAutobahn
            case 143...300: return ZoomLevel.fastAutobahn
            default: return ZoomLevel.innenCity
        }
    }


    //
    // Returns the adequate zoom for the car "arrow" depending on the given map zoom.
    //
    func carZoom(mapZoom: ZoomLevel) -> Float {

        switch mapZoom {

            case ZoomLevel.spielstreet: return 1.0
            case ZoomLevel.thirtierZone: return 0.85
            case ZoomLevel.innenCity: return 0.75
            case ZoomLevel.seventierCountrystreet: return 0.62
            case ZoomLevel.countrystreet: return 0.575
            case ZoomLevel.standardAutobahn: return 0.55
            case ZoomLevel.fastAutobahn: return 0.51
        }
    }


    //
    // Updates the map's "camera" position based on the user's location.
    //
    func newCoordinatesArrived(speed: Int, lat: String, long: String, alt: String, courseStr: String, course: Double, coord: CLLocationCoordinate2D) {

        // Update the various lavels on the view:
        _speedLabel.text = (speed != Locator.defaultSpeed ? speed.description : Locator.defaultSpeedString)
        _latLabel.text = lat
        _longLabel.text = long
        _altLabel.text = alt

        // Rotate the car icon according to the given course:
        rotateCarIcon(course)

        // Move the map to the new coordinates:
        _mapView.animateToLocation(coord)

        // Update speed variables:
        let previousSpeed: Int = _currentSpeed
        _currentSpeed = speed

        if previousSpeed == _currentSpeed {

            // No zooming necessary => Leave.
            return
        }

        let previousMapZoom: ZoomLevel = mapZoom(previousSpeed)
        let currentMapZoom: ZoomLevel = mapZoom(_currentSpeed)

        if previousMapZoom == currentMapZoom {

            // No zooming necessary => Leave.
            return
        }

        _mapView.animateToZoom(currentMapZoom.rawValue)
        // DEBUG _tmpZoomLabel.text = _mapView.camera.zoom.description

        // Adjust the car icon size according to the new zoom:
    //    let previousCarZoom: Float = carZoom(previousMapZoom)
        let currentCarZoom: Float = carZoom(currentMapZoom)
     //   let carZoomChange: CGFloat = CGFloat(currentCarZoom / previousCarZoom)
        // DEBUG print("car zooms: \(previousCarZoom) -> \(currentCarZoom) => \(carZoomChange)")
        
        UIView.animateWithDuration(0.4,
            animations: {
/*                self._carIcon.transform = CGAffineTransformScale(self._carIconTransformation, carZoomChange, carZoomChange)
                self._carIconTransformation = self._carIcon.transform
*/
                self._carIconCurrentScale = CGAffineTransformMakeScale(CGFloat(currentCarZoom), CGFloat(currentCarZoom))
                self._carIcon.transform = CGAffineTransformConcat(self._carIconCurrentScale, self._carIconCurrentRotation)
        })
    }


    //
    // Rotates the car icon according to the given course.
    //
    func rotateCarIcon(course: Double) {

        if course == _currentCourse {

            // Nothing to do => Leave:
            return
        }
        
        // Set previous and current courses:
        var previousCourse: Double = _currentCourse
        _currentCourse = course

        if _currentCourse >= 0 {

            // Make the car icon visible:
            _carIcon.alpha = 1.0

            if previousCourse < 0 {
                previousCourse = 0
            }

            // We have to find out the difference between the new and the previous course:
     //       var courseChange: Double = _currentCourse - previousCourse
            // DEBUG print("courses: \(previousCourse) -> \(_currentCourse) => \(courseChange)")

            UIView.animateWithDuration(0.5,
                animations: {

/*
                    self._carIcon.transform = CGAffineTransformRotate(self._carIconTransformation, 2*CGFloat(M_PI) * (CGFloat(courseChange)/360))
                    self._carIconTransformation = self._carIcon.transform
*/
                    self._carIconCurrentRotation = CGAffineTransformMakeRotation(2*CGFloat(M_PI) * (CGFloat(self._currentCourse)/360))
                    self._carIcon.transform = CGAffineTransformConcat(self._carIconCurrentScale, self._carIconCurrentRotation)

            })

            // Disable drawing a light blue dot where the user is located:
            _mapView.myLocationEnabled = false

        } else {

            // Invalid course => make arrow invisible
            _carIcon.alpha = 0.0

            // Enable a light blue dot where the user is located:
            _mapView.myLocationEnabled = true
        }
    }
    
    
    //
    // This function gets called each time the map stops moving and settles in a new position.
    //
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {

        // Find out about the address we just landed:
        reverseGeocodeCoordinate(position.target)
    }


    //
    // Rewrites the address for the given geo location.
    //
    func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D) {

        // Create a GMSGeocoder object to turn a latitude and longitude coordinate into a street address:
        let geocoder = GMSGeocoder()

        // Ask the geocoder to reverse-geocode the coordinate passed to the method.
        // It then verifies there is an address in the response of type GMSAddress. This is a model class for addresses returned by the GMSGeocoder:
        geocoder.reverseGeocodeCoordinate(coordinate) { response , error in

            if let address = response?.firstResult() {

                // Set the text of the address to the address returned by the geocoder:
                let lines = address.lines as! [String]
                if lines.count > 0 {

                    // We do have an address.
                    let firstLine: String = lines[0]

                    if !firstLine.hasPrefix("Salisbury") && firstLine != "" {

                        // The address is really reasonable.
                        // DEBUG print("address found: \"\(lines[0])\"")
                        self._addressLabel.text = firstLine
               //         let labelHeight = self._addressLabel.intrinsicContentSize().height
                        self._addressLabel.alpha = 1.0

                    } else {

                        // The address is the default of London or the address is unknown.
                        self._addressLabel.alpha = 0.0
                    }

                } else {

                    // Nothing to be shown.
                    self._addressLabel.alpha = 0.0
                }
            }
        }
    }


    //
    // Switches the map's type to the given map type.
    //
    func switchMapToMapType(mapType: MapType) {

        switch mapType {

            case .Normal: _mapView.mapType = kGMSTypeNormal
            case .Hybid: _mapView.mapType = kGMSTypeHybrid
            case .Satellite: _mapView.mapType = kGMSTypeSatellite
            case .Terrain: _mapView.mapType = kGMSTypeTerrain
        }

        // Save the new map type to the disk:
        _savior.saveMapType(mapType)
    }


    //
    // Switches the map to the next map type.
    //
    @IBAction func userHasSwipedLeft(sender: UISwipeGestureRecognizer) {

        // Increment the current map type:
        _currentMapType = MapType(rawValue: (_currentMapType.hashValue + 1) % MapTypeCount)!
        switchMapToMapType(_currentMapType)
    }

    
    //
    // Switches the map to the previous map type.
    //
    @IBAction func userHasSwipedRight(sender: UISwipeGestureRecognizer) {

        // Decrement the current map type:
        _currentMapType = MapType(rawValue: (_currentMapType.hashValue + MapTypeCount - 1) % MapTypeCount)!
        switchMapToMapType(_currentMapType)
    }


    //
    // This function is called shortly before we switch back to one of the calling views.
    //
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        // DEBUG print("SpeedViewController.prepareForSegue()")
        // DEBUG print("SpeedView --> \(segue.destinationViewController.title!!)")

        stopAllTimers()
    }


    //
    // Stops all running timers.
    //
    func stopAllTimers() {

        if _progressTimer.valid {
            _progressTimer.invalidate()
            // DEBUG print("SpeedViewController.stopAllTimers(): _progressTimer stopped.")
        }

        stopTextMoveTimer()
    }


    //
    // Stops the track info text move timer:
    //
    func stopTextMoveTimer() {

        if _trackInfoTextMoveTimer.valid {
            _trackInfoTextMoveTimer.invalidate()
            // DEBUG print("SpeedViewController.stopAllTimers(): _trackInfoTextMoveTimer stopped.")
        }
    }


    //
    // Sets the background color.
    //
    func setBackgroundColor(backgroundColor: UIColor) {

        view.backgroundColor = backgroundColor
        _addressLabel.backgroundColor = backgroundColor.colorWithAlphaComponent(0.75)
    }


    //
    // Sets the direction of the "swipe back gesture".
    //
    func setDirectionToSwipeBack(direction: DirectionToSwipeBack) {

        // Set one gesture to enabled and the other to disabled, depending on the direction back:
        _swipeGestureUp.enabled = (direction == DirectionToSwipeBack.Up)
        _swipeGestureDown.enabled = !_swipeGestureUp.enabled
    }


    //
    // Handles the users pinching which changes the brightness of the screen.
    //
    @IBAction func userHasPinched(sender: UIPinchGestureRecognizer) {

        _controller.setBrightness(sender.scale)
    }
}
