//
//  ImageCache.swift
//  VirtualTour
//
//  Based on FavoriteActors project in Udacity Class
//  Copyright (c) 2015 Jeffrey. All rights reserved.
//

import UIKit
import CoreData

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    // MARK: - Retrieving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForImg(identifier!)
        var data: NSData?
        
        // First try the memory cache
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
        // Next Try the hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    // MARK: - Saving images to local device
    
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForImg(identifier)
        
        // If the image is nil, remove images from the cache
        if image == nil {
            inMemoryCache.removeObjectForKey(path)
            //why remove from file if it is nil???
           // NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
            return
        }
        
        // Otherwise, keep the image in memory
        inMemoryCache.setObject(image!, forKey: path)
        
        // And in documents directory
        let data = UIImagePNGRepresentation(image!)
        data.writeToFile(path, atomically: true)
    }
    
    // MARK: - local file (not DB)
    
    func pathForImg(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        
        var imgloc = split(identifier) {$0 == "/"}
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(imgloc.last!)
        
        return fullURL.path!
    }
    
    // MARK: deleet image from disk
    
    func removeImagefromDevice(identifier: String)  {
        
        let fileManager: NSFileManager = NSFileManager.defaultManager();
        let filePath =  pathForImg(identifier)
        
        inMemoryCache.removeObjectForKey(identifier)
        
        var error: NSError?
        fileManager.removeItemAtPath(filePath, error: &error)
        if ( error != nil) {
              NSLog("Could not delete file -:%@ ", error!.localizedDescription);
        }
    }
    
}