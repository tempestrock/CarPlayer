//
//  Locator.swift
//  Locator
//
//  Created by Peter Störmer on 01.12.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

//  KEEP IN MIND: In order for location services to work, add one or both of the following entries to Info.plist by simply adding
//                them to the "Information Property List", having type "String" and getting no additional value:
//      NSLocationWhenInUseUsageDescription
//      NSLocationAlwaysUsageDescription


import Foundation
import CoreLocation


class Locator: CLLocationManager, CLLocationManagerDelegate {

    var _locationManager: CLLocationManager!
    var _seenError : Bool = false
    var _locationStatus : NSString = "Not Started"

    // Function to call in the case of new data:
    var _notifierFunction : ((Int, String, String, String, String, Double, CLLocationCoordinate2D) -> (Void))?

    // Use ',' instead of '." in decimal numbers:
    var _useGermanDecimals : Bool

    // Location Manager helper stuff
    override init() {

        _useGermanDecimals = false

        super.init()

        _seenError = false

        _locationManager = CLLocationManager()
        _locationManager.delegate = self

        // Choose the accuracy according to the battery state of the device:
        if (UIDevice.currentDevice().batteryState == UIDeviceBatteryState.Charging) ||
            (UIDevice.currentDevice().batteryState == UIDeviceBatteryState.Full) {

                // We can spend some more battery. ;)
                _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation

        } else {

            _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        }

        _locationManager.requestAlwaysAuthorization()
        _notifierFunction = nil
    }


    //
    // Returns the currently used accuracy (which depends on the battery state).
    //
    func currentlyUsedAccuracy() -> CLLocationAccuracy {

        return _locationManager.desiredAccuracy

    }


    //
    // Sets the notification function that shall be called as soon as new data is available.
    //
    func setNotifierFunction(funcToCall: (Int, String, String, String, String, Double, CLLocationCoordinate2D) -> Void) {

        _notifierFunction = funcToCall
    }


    //
    // Sets the flag whether German decimals (taking a ',' instead of a '.') shall be used and printed out.
    //
    func setUseGermanDecimals(use: Bool) {

        _useGermanDecimals = use

    }


    //
    // Location Manager Delegate stuff
    //
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {

        _locationManager.stopUpdatingLocation()
        if !_seenError {
            _seenError = true
            print(error)
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if _notifierFunction == nil {

            return
        }

        let locationArray: NSArray = locations as NSArray
        let locationObj: CLLocation = locationArray.lastObject as! CLLocation
        let speed: Double = locationObj.speed           // in meters per second
        let coord: CLLocationCoordinate2D = locationObj.coordinate

        let speedAsInt: Int = (speed > 0 ? Int(speed * 3.6) : Locator.defaultSpeed)           // km/h

        // Also the string-based variant of the notifier function is about to be called.

        let altitude = locationObj.altitude     // in meters
        let course: Double = locationObj.course

        let latString = getNiceLatStringFromCoord(coord.latitude)
        let longString = getNiceLongStringFromCoord(coord.longitude)
        let altString = (getI18NedDecimalString(altitude.format(".0")) + " m")
        let courseString = (course >= 0 ? (getI18NedDecimalString(course.format(".0")) + "°") : defaultCourse())

        // Call the notification function that has been provided initially
        _notifierFunction!(speedAsInt, latString, longString, altString, courseString, course, coord)

            /*
            println("Coord:    \(latString), \(longString)")
            println("Speed:    \(speedString)")
            println("Altitude: \(altString)")
            println("Course:   \(courseString)")
            */
    }

    func getNiceLatStringFromCoord(coord: Double) -> String {

        return getNiceStringFromCoord(coord, posChar: "N", negChar: "S")

    }

    func getNiceLongStringFromCoord(coord: Double) -> String {

        return getNiceStringFromCoord(coord, posChar: "E", negChar: "W")

    }

    //
    // Makes something like "053°50,32'N" out of "53.853453"
    //
    func getNiceStringFromCoord(coord: Double, posChar: Character, negChar: Character) -> String {

        //      println("Coord: \(coord)")

        let separatorChar = (_useGermanDecimals ? "," : ".")

        var localCoord = coord
        var finalChar: Character

        if localCoord < 0 {
            finalChar = negChar
            localCoord = localCoord * (-1)
        } else {
            finalChar = posChar
        }

        var resultStr: String
        resultStr = ""

        // Get the part of the coordinate that is left of the ".":
        let intPartOfCoord = Int(localCoord)

        // Make "008" from "8":
        resultStr = intPartOfCoord.format("03")

        // Remove the integer part from the coordinate
        localCoord = localCoord - Double(intPartOfCoord)

        // Make the "minutes" part out of the number right of the ".":
        localCoord = localCoord * 60

        let intPartOfMinutes = Int(localCoord)
        resultStr = resultStr + "° " + intPartOfMinutes.format("02") + separatorChar

        // Remove the "minutes" part from the coordinate
        localCoord = localCoord - Double(intPartOfMinutes)

        // Shift three digits further out:
        localCoord = localCoord * 10

        // Get these two digits alone:
        let intPartOfSeconds = Int(localCoord)

        resultStr = resultStr + intPartOfSeconds.format("01") + "' "

        // Append "N", "S", "E", or "W":
        resultStr.append(finalChar)

        //     println(" --> " + resultStr)

        return resultStr

    }

    //
    // Returns a decimal string that has a ',' instead of a '.' if the localization is wanted.
    //
    func getI18NedDecimalString (str: String) -> String {

        if _useGermanDecimals {
            let newString = str.stringByReplacingOccurrencesOfString(".", withString: ",", options: NSStringCompareOptions.LiteralSearch, range: nil)
            return newString
        } else {
            return str
        }

    }


    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {

        var shouldIAllow = false

        switch status {
        case CLAuthorizationStatus.Restricted:
            _locationStatus = "Restricted Access to location"
        case CLAuthorizationStatus.Denied:
            _locationStatus = "User denied access to location"
        case CLAuthorizationStatus.NotDetermined:
            _locationStatus = "Status not determined"
        default:
            _locationStatus = "Allowed to location Access"
            shouldIAllow = true
        }
        NSNotificationCenter.defaultCenter().postNotificationName("LabelHasbeenUpdated", object: nil)
        if shouldIAllow {
            //DEBUG                NSLog("Location to Allowed")

            // Start location services
            _locationManager.startUpdatingLocation()
            //                _locationManager.startUpdatingHeading()

        } else {
            NSLog("Denied access: \(_locationStatus)")
        }
    }


    //
    // Returns a default string for an "empty" speed.
    //
    class var defaultSpeedString: String {
        get {
            return "--"
        }
    }


    //
    // Returns a default value for an "empty" speed.
    //
    class var defaultSpeed: Int {
        get {
            return -1
        }
    }
    

    //
    // Returns a default string for an "empty" latitude.
    //
    func defaultLatitude() -> String {

        return "---° --" + (_useGermanDecimals ? "," : ".") + "-' N"
    }


    //
    // Returns a default string for an "empty" longitude.
    //
    func defaultLongitude() -> String {

        return "---° --" + (_useGermanDecimals ? "," : ".") + "-' E"
    }


    //
    // Returns a default string for an "empty" altitude.
    //
    func defaultAltitude() -> String {

        return "-- m"
    }


    //
    // Returns a default string for an "empty" course.
    //
    func defaultCourse() -> String {

        return "---°"
    }
}
