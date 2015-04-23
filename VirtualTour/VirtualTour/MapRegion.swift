//
//  MapRegion.swift
//  
//  Persistent Map cenetr and zoom level, so we can restore
//
//  This is the MapRegion Entity class (defined in xcdtatamodeld)
//  Created by Jeffrey Zhang on 4/18/15.
//
//

import Foundation
import CoreData

class MapRegion: NSManagedObject {

    @NSManaged var centerLatitude: Double
    @NSManaged var centerLongitude: Double
    @NSManaged var spanLatitude: Double
    @NSManaged var spanLogitude: Double

    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    // MARK: pass   initialization of MapRegion
    
    init( _ctrlatitude: Double, _ctrlongitude :Double, _spanLat: Double, _spanLongi :Double){
        // Core Data
        let context = CoreDataManager.sharedInstance().managedObjectContext!
        let entity =  NSEntityDescription.entityForName(WebUtilities.Constants.PIN_Entity, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        centerLatitude = _ctrlatitude
        centerLongitude = _ctrlongitude
        spanLatitude = _spanLat
        spanLogitude = _spanLongi
    }

}
