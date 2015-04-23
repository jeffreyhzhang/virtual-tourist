//
//  Photo.swift
//  
//  This corresponds to Photo Entity defined in xcdtatamodeld
//
//  Created by Jeffrey Zhang on 4/18/15.
//
//

import UIKit
import CoreData

class Photo: NSManagedObject {

    @NSManaged var photoUrl: String
    @NSManaged var photoTitle: String
    @NSManaged var pin: Pin
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    

    
    /* Helper: Given an array of dictionaries, convert them to an array of Photo objects */

    init(dictionary: [String : AnyObject] ) {
        
        // Core Data
        let context = CoreDataManager.sharedInstance().managedObjectContext!
        let entity =  NSEntityDescription.entityForName(WebUtilities.Constants.PHOTO_Entity, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary....what about downloading  files
        photoUrl = dictionary[WebUtilities.JSONResponseKeys.FlickrUrlm] as! String
        photoTitle = dictionary[WebUtilities.JSONResponseKeys.FlickrTitle] as! String
 
            
        pin = WebUtilities.sharedInstance().CurrentPin!
    }

 
    
    //
    //  limit how many photos returned? 
    //  I don't need 4000 images downlaoded....I will allow only up to  MaxPhotoCount
    //
    static func photosFromResults(results: [String : AnyObject]) -> [Photo] {
        var photos = [Photo]()
          /*
            println(results["total"])
          */
        var iPhotoCount = 0
            if let allphotos =  results[WebUtilities.JSONResponseKeys.FlickrPhoto] as?  [[String : AnyObject]] {
                for  itm in allphotos {
                    
                    iPhotoCount = iPhotoCount + 1
                    if(iPhotoCount > WebUtilities.Constants.MaxPhotoCount){
                        break
                    }
                    //println( itm["url_m"])
                    photos.append(Photo(dictionary: itm))
                }
                //save to DB
                CoreDataManager.sharedInstance().saveContext()
            }
            return photos
    }
    
    var image: UIImage? {
        get {
            var imageURL = split(photoUrl) {$0 == "/"}
            return WebUtilities.Caches.imageCache.imageWithIdentifier(imageURL.last!)
        }
        
        set {
            var imageURL = split(photoUrl) {$0 == "/"}
            WebUtilities.Caches.imageCache.storeImage(image, withIdentifier: imageURL.last!)
        }
    }

}
