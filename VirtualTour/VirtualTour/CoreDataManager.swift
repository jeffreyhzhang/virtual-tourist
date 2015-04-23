//
//  CoreDataManager.swift
//  VirtualTour
//
//  CoreData management utility
//
//  Created by Jeffrey Zhang on 4/18/15.
//  Copyright (c) 2015 Jeffrey. All rights reserved.
//

import Foundation
import CoreData

private let SQLITE_FILE_NAME = "VirtualTour.sqlite"
private let MY_DOMAIN_NAME =  "JeffZhangATT"

class CoreDataManager : NSObject {
    
    // MARK: - Shared Instance...Singleton

    class func sharedInstance() -> CoreDataManager {
        
        struct Singleton {
            static var sharedInstance = CoreDataManager()
        }
        
        return Singleton.sharedInstance
    }

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.ATT.JZ.VirtualTour" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("VirtualTour", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        
     println(url)
        
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: MY_DOMAIN_NAME , code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
    // MARK: - getStoredObject for entity with predicate via searchName/value
    //        this is for small data...not dynamcially changing array/set/collection
    //        not used for table/collection, where we use NSFetchedResultsController
    //
    //        pass array...mutiple conditions: key/values pair....return only one entity
    //
    func searchStoredObject(entityName :String, searchNameValue: [String:NSManagedObject]?) -> NSManagedObject?{
        
        let contxt =  managedObjectContext!
        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: contxt)
        
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        //search criteria....multiple
        if( searchNameValue != nil) {
            var predicates = [NSPredicate]()
            for (searchName,searchValue) in searchNameValue! {
                if(!searchName.isEmpty && count(searchName) >= 0){
                    let pred = NSPredicate(format: "(" + searchName + " = %@)", searchValue)
                    predicates.append(pred)
                }
            }
            //combine all search conditions into one
            let pred = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: predicates)
            request.predicate = pred
        }
        var error: NSError?
        
        var objects = contxt.executeFetchRequest(request, error: &error)
        
        if let results = objects {
            
            if results.count > 0 {
                let match = results[0] as! NSManagedObject
                return match
            }
        }
        return nil
    }
}
