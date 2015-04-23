//
//   Helper.swift
//
//
//  Created by Jeffrey Zhangon 4/3/15.
//  Based  on My OnTheMap project
//
//  To avoid many-to-many mapping for Pin and Photo, I check to see the Pin
//  is close enough to existing Pin ( fall in BBOX).
//  Not sure how CoreData handles manay to many mapping. In reality, we should have 
//  a relational database  or multi-dimensional DB already defined....not sqlite.
//
//  Copyright (c) 2015 Jeffrey. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// MARK: - Convenient Resource Methods

extension WebUtilities {
    
    //
    // MARK: - GET Convenience Methods
    //
    func getPhotos(completionHandler: (result: [Photo]?, error: NSError?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}) */
        
        let parameters = [
             ParameterKeys.Method: Constants.METHOD_NAME,
             ParameterKeys.API_Key: Constants.APIKEY,
             ParameterKeys.BBox: createBBoxString(CurrentPin!.latitude,longitude: CurrentPin!.longitude ),
             ParameterKeys.Safe_Search: Constants.SAFE_SEARCH,
             ParameterKeys.Extras: Constants.EXTRAS,
             ParameterKeys.Format: Constants.DATA_FORMAT,
             ParameterKeys.NoJSONCallback: Constants.NO_JSON_CALLBACK,
             ParameterKeys.PerPage: Constants.PHOT_PER_PAGE
        ]

        
        var mutableurl : String = UrlPaths.BASE_URL
 
        /* 2. Make the request */
            taskForGETMethod( mutableurl, parameters: parameters,  completionHandler:  { JSONResult, error in
      
            /* 3. Send the desired value(s) to completion handler */
                
            if let error = error  {
                completionHandler(result: nil, error: error)
            } else {
                // [[String : AnyObject]]  vs  NSDictionary
                /*  This is what we get back.
                {
                photos =     [{
                    page = 1;
                    pages = 2040;
                    perpage = 250;
                    photo =    ( {},....{}, {} );
                    total = 509823;
                }];
                stat = ok;
                }
                */

                if let parsedResults = JSONResult as? NSDictionary {

                    println( parsedResults.valueForKey("stat") )

                    if let results = parsedResults.valueForKey(WebUtilities.JSONResponseKeys.FlickrPhotos) as? [String : AnyObject] {
 
                        let photos = Photo.photosFromResults(results)
                        
                        completionHandler(result: photos, error: nil)
                    } else {
                        completionHandler(result: nil, error: NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getPhotos"]))
                    }
                }
            }
        })
    }
    
    func createBBoxString(latitude :Double, longitude : Double) -> String {
        
        let bottom_left_lon = max(longitude - Constants.BOUNDING_BOX_HALF_WIDTH, Constants.LON_MIN)
        let bottom_left_lat = max(latitude - Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MIN)
        let top_right_lon = min(longitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LON_MAX)
        let top_right_lat = min(latitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    
    // MARK: hasPinInBBOX
    //       If already has a pin nearby in BBOX, no need to place a new pin
    //       either delete and add new or just return with no action
    
    func hasPinInBBOX(latitude :Double, longitude : Double) -> Pin?{
        
        let contxt = CoreDataManager.sharedInstance().managedObjectContext!
        let entityDescription = NSEntityDescription.entityForName(WebUtilities.Constants.PIN_Entity, inManagedObjectContext: contxt)
        
        let request = NSFetchRequest()
        request.entity = entityDescription

        var error: NSError?
        var objects = contxt.executeFetchRequest(request, error: &error)
        if(error != nil){
            return nil
        }
        if let results = objects  as? [Pin] {
            //loop all existing pins to see if any one is within BBOX
            for pin in results {
                let bottom_left_lon = max(pin.longitude - Constants.BOUNDING_BOX_HALF_WIDTH, Constants.LON_MIN)
                let bottom_left_lat = max(pin.latitude - Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MIN)
                let top_right_lon = min(pin.longitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LON_MAX)
                let top_right_lat = min(pin.latitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MAX)
                if ( latitude <= top_right_lat &&
                     latitude >= bottom_left_lat &&
                     longitude <= top_right_lon &&
                     longitude >= bottom_left_lon ) {
                   return pin
                }
            }
        }
        return nil
    }
    
    // add pin and persisten to sqllite
    func addPin2Store(lat: Double, long: Double) {
        
        let context = CoreDataManager.sharedInstance().managedObjectContext!

        
        let entityDescription =  NSEntityDescription.entityForName(WebUtilities.Constants.PIN_Entity,  inManagedObjectContext: context)
        var _currentPin = Pin(entity: entityDescription!, insertIntoManagedObjectContext: context)
        _currentPin.latitude =  lat
        _currentPin.longitude = long
        WebUtilities.sharedInstance().CurrentPin = _currentPin
        
        var error: NSError?
        context.save(&error)
        
        if let err = error {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            var newVC = mainStoryboard.instantiateViewControllerWithIdentifier("MapVC") as!  MapVC

            Utilities.showAlert(newVC, title: "Error", message: err.localizedFailureReason!)
        }
    }
    
    // Save MapState to CoreData
    
    func SaveMapState(MyMap: MKMapView){
        
        let context = CoreDataManager.sharedInstance().managedObjectContext!
        var error: NSError?
        
        //if already has data, wipe it out first before saving.
        
        if let result = CoreDataManager.sharedInstance().searchStoredObject(WebUtilities.Constants.MAPREGION_Entity, searchNameValue: nil)  as? MapRegion {
                context.deleteObject( result )
                context.save(&error)
        }
        
        
        if(error == nil ) {
            // if none, then get the current region and save
            var region = MyMap.region
            
            let entityDescription =  NSEntityDescription.entityForName(WebUtilities.Constants.MAPREGION_Entity,  inManagedObjectContext: context)
            
            let mapregion = MapRegion(entity: entityDescription!, insertIntoManagedObjectContext: context)
            mapregion.centerLatitude = region.center.latitude
            mapregion.centerLongitude  = region.center.longitude
            mapregion.spanLogitude = region.span.longitudeDelta as Double
            mapregion.spanLatitude = region.span.latitudeDelta as Double
            context.save(&error)
            
            if let err = error {
                println(err.localizedFailureReason)
            }
        }
    }
    
    
    func restoreMapState(MyMap: MKMapView){
        
        // if we have Pins already, load the map center and zoom level (region)
        let myMapState = CoreDataManager.sharedInstance().searchStoredObject(WebUtilities.Constants.MAPREGION_Entity, searchNameValue: nil)  as! MapRegion
        var region = MKCoordinateRegion()
        region.center.latitude     = myMapState.centerLatitude
        region.center.longitude    = myMapState.centerLongitude
        region.span.latitudeDelta  = myMapState.spanLatitude
        region.span.longitudeDelta = myMapState.spanLogitude

        //this will trigger zoom event when reset region.
        MyMap.setRegion(region, animated: true)
    }

    
    
    func restorePinState(MyMap: MKMapView, pinlat: Double, pinLongi: Double){
        
    // if we have Pins already, load the map center and zoom level (region)
        let myMapState = CoreDataManager.sharedInstance().searchStoredObject(WebUtilities.Constants.MAPREGION_Entity, searchNameValue: nil)  as! MapRegion
        var region = MKCoordinateRegion()
        region.center.latitude     = pinlat
        region.center.longitude    = pinLongi
        region.span.latitudeDelta  = myMapState.spanLatitude
        region.span.longitudeDelta = myMapState.spanLogitude
        
        //this will trigger zoom event when reset region.
         MyMap.setRegion(region, animated: true)
    }
    
    
    
    //save image in background.... no need callback
    func saveImage(imageUrlString: String) {

        let url = NSURL(string: imageUrlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            let img = UIImage(data: data)
            
            var imageURL = split(imageUrlString) {$0 == "/"}
            WebUtilities.Caches.imageCache.storeImage(img!, withIdentifier: imageURL.last!)
        }
        
        task.resume()
    }
    
    // MARK : get image from URL....if nil, should re-download???
    func getImg(imageUrlString: String,  completionHandler: (img: UIImage?)   -> Void) {
        if ( !imageUrlString.isEmpty) {
            let img = WebUtilities.Caches.imageCache.imageWithIdentifier(imageUrlString)
            if(img == nil) {
             //should try again to download...
             //maybe still downloading/saving to disk, maybe no network connectivity
                   downloadImg(imageUrlString){ img in
                    completionHandler(img: img)
                }
                return
            }
            completionHandler(img: img)
        }
    }
    
 
    func downloadImg(imageUrlString: String,  completionHandler: (img: UIImage?)   -> Void) {
        let url = NSURL(string: imageUrlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            let img = UIImage(data: data)
            completionHandler(img: img)
        }
        
        /* 7. Start the request */
        task.resume()
    }

}
