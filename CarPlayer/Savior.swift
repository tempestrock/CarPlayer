//
//  Savior.swift
//  CarPlayer
//
//  Created by Peter Störmer on 19.02.15.
//  Copyright (c) 2015 Tempest Rock Studios. All rights reserved.
//

import CoreData         // For saving and loading data


//
// A class to save and load data from the "disk".
// (See also the data model in file "CarPlayer.xcdatamodeld".)
//
class Savior {

    //
    // Saves the given speed display mode to the disk.
    //
    func saveSpeedDisplayMode(valueOfDisplayMode: Int) {

        saveInt("SpeedDisplayMode", valueToSave: valueOfDisplayMode)
    }


    //
    // Saves the given map type to the disk.
    //
    func saveMapType(mapType: SpeedViewController.MapType) {

        saveInt("MapType", valueToSave: mapType.rawValue)
    }
    
    
    //
    // Saves the given integer under the given entity to the disk.
    //
    func saveInt(entityName: String, valueToSave: Int) {

        // Get the managed object context of the app:
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!

        // Get the relevant entity for the speed display mode (see file "CarPlayer.xcdatamodeld" for the data model):
        let entity =  NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedContext)

        // Prepare the object tot be saved:
        let displayMode = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)

        // Store the object in the RAM:
        displayMode.setValue(valueToSave, forKey: "value")

        // Store the object on the disk:
        do {
            try managedContext.save()

        } catch {
            print("Savior.saveInt(): Could not save integer")

        }
    }


    //
    // Loads the last speed display mode from the disk.
    //
    func loadSpeedDisplayMode(inout valueOfDisplayMode: Int) {

        loadInt("SpeedDisplayMode", valueToLoad: &valueOfDisplayMode)
    }


    //
    // Loads the last map type from the disk.
    //
    func loadMapType(inout mapType: SpeedViewController.MapType) {

        var loadedValue: Int = 0
        loadInt("MapType", valueToLoad: &loadedValue)
        mapType = SpeedViewController.MapType(rawValue: loadedValue)!
    }
    
    
    //
    // Loads the last integer value of the given entity from the disk.
    //
    func loadInt(entityName: String, inout valueToLoad: Int) {

        // Get the managed object context of the app:
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!

        // Create a fetch request:
        let fetchRequest = NSFetchRequest(entityName: entityName)

        // Fetch the data:
   //     let error: NSError?
        var fetchedResults: [AnyObject]!
        do {
            try fetchedResults = managedContext.executeFetchRequest(fetchRequest) as [AnyObject]?
        } catch {

            print("Savior.loadInt(): Could not load Int")
        }

        if let results = fetchedResults {

            let numOfResults: Int = results.count
            // DEBUG println("Number of results: \(numOfResults)")

            if numOfResults > 0 {

                // Get the latest value:
                let val: Int = results[numOfResults-1].valueForKey("value") as! Int
                // DEBUG println("Savior.loadInt(): Loaded value \"\(val)\".")

                valueToLoad = val

            } else {

                print("Savior.loadInt(): Could not load Int: no results.", terminator: "")
            }
        }
    }
}

