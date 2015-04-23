//
//  Pin.swift
//  
//  This is the Pin Entity class (defined in xcdtatamodeld)
//  Created by JeffreyLee on 4/18/15.
//
//

import Foundation
import CoreData

class Pin: NSManagedObject {

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
     
    
    // MARK: initialization of Pin with  lat and longi
    
    init( _latitude: Double, _longitude :Double){
        // Core Data
        let context = CoreDataManager.sharedInstance().managedObjectContext!
        let entity =  NSEntityDescription.entityForName(WebUtilities.Constants.PIN_Entity, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

       longitude = _longitude
       latitude = _latitude
    }
    
   
}
