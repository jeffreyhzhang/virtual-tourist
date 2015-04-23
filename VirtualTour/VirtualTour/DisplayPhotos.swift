//
//  DisplayPhotos.swift
//  VirtualTour
//
//  NSFetchedResultsController is designed for use with UITableView not CollectionView
//  No need to load items that aren't visible for performacne!
//
//  Created by Jeffrey Zhang on 4/18/15.
//
//  Copyright (c) 2015 Jeffrey. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class DisplayPhotos:  UIViewController, UICollectionViewDataSource ,NSFetchedResultsControllerDelegate {

    @IBOutlet weak var SmallMap: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var btnNewCollection: UIButton!
    var activityIndicator: UIActivityIndicatorView!
    
    var PinLatitude: Double!
    var PinLongitude: Double!
    var Photos2Display = [String]()
    var NumberofPhotosPerPage : Int!
    var StartPage: Int!
    var nbrofPhotoLoaded : Int!
    var imgDisplayWidth : CGFloat = 85.00
    
    
    // Core Data
    let context = CoreDataManager.sharedInstance().managedObjectContext!
    var _fetchedResultsController: NSFetchedResultsController? = nil
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnNewCollection.enabled = false
        
        // load photos for pin at PinLatitude, PinLongitude
        
        if ( self.fetchedResultsController.fetchedObjects!.count > 0) {
            for obj in self.fetchedResultsController.fetchedObjects!  {
                Photos2Display.append((obj as! Photo).photoUrl)
            }
        }else {
            Utilities.showAlert(self, title: "Alert", message: "No Photo @ this location!")
        }
  
        /////how many should we load...no need to laod too mant photos if not visible on screen yet
        // based on the size of the visible area, we calculate  photos to show per click
        // We have  nav. bar (44), top gap (5), btm gap  (5) and a button height (30)....what is left for height
        let TotalRows : Int = Int( (self.view.bounds.height -  64.0 - SmallMap.frame.height - 10  - 30 ) / (imgDisplayWidth + 5 ))
        let TotalColumns : Int = Int( (self.view.bounds.width - 10 ) /  (imgDisplayWidth + 5) )
        NumberofPhotosPerPage = TotalRows * TotalColumns
        
        StartPage = 1
        nbrofPhotoLoaded = 0

        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                //load Map
                var mypin = MKPointAnnotation()
                var formatter = NSNumberFormatter()
                formatter.maximumFractionDigits = 2
                formatter.minimumFractionDigits = 2
                mypin.title =   formatter.stringFromNumber(self.PinLatitude)
                mypin.subtitle = formatter.stringFromNumber(self.PinLongitude)
                mypin.coordinate = CLLocationCoordinate2DMake(self.PinLatitude, self.PinLongitude)
                
                self.SmallMap.addAnnotation(mypin)

            dispatch_async(dispatch_get_main_queue()) {
                // On the main queue (the main thread)
                // restore map cenetr and zoom level....center should be Pin location!
                WebUtilities.sharedInstance().restorePinState(self.SmallMap, pinlat: self.PinLatitude, pinLongi: self.PinLongitude)
            }
        })
 
    }

    
    override func viewDidAppear(animated: Bool) {
        // println(photoCollectionView.visibleCells().count)
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let total = self.fetchedResultsController.fetchedObjects!.count
        return total > NumberofPhotosPerPage ? NumberofPhotosPerPage : total
    }
    
    //display activity alert when loading is slow!
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! PhotoCell

        cell.imgVw!.contentMode = UIViewContentMode.ScaleToFill
        let idx = indexPath.row + ( StartPage - 1 ) * NumberofPhotosPerPage
   
        // if no more photo on last page...
        
        if(idx > self.fetchedResultsController.fetchedObjects!.count - 1) {
            cell.imgVw.image = nil
            return cell
        } else {
            
            let imageUrlString =  Photos2Display[idx]
         
            //display activity alert if loading
            
            cell.activityVw.alpha = 1
            cell.activityVw.startAnimating()
     
            
            WebUtilities.sharedInstance().getImg(imageUrlString, completionHandler: { (img) -> Void in
                if let cellimg = img {
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imgVw.image = cellimg
                        
                        self.nbrofPhotoLoaded = self.nbrofPhotoLoaded + 1
                        
                        // if all photos loaded on the page, enable New Collection button
                        
                        if(  self.nbrofPhotoLoaded  == self.photoCollectionView.visibleCells().count) {
                               self.btnNewCollection.enabled = true
                        }
                        cell.activityVw.stopAnimating()
                        cell.activityVw.alpha = 0
                    }
                } else {

                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imgVw.image = nil
                    }
                }
            })
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        //allow deletion
        //reset since we need reload after deletion
        
        self.nbrofPhotoLoaded  = 0
       
        var idx = indexPath.row + (StartPage - 1 ) * NumberofPhotosPerPage
        let imageUrlString =  Photos2Display[idx]
        println(imageUrlString)
        println(indexPath.row)
        
        var founMatch: Bool = false
        if ( self.fetchedResultsController.fetchedObjects?.count > 0) {
            for  object in  self.fetchedResultsController.fetchedObjects as! [Photo] {
               // println(object)
               // println(object.photoUrl )
                if(object.photoUrl == imageUrlString) {
                
                    context.deleteObject(object)
                    //is it deleted from the cache also???
                    
                    //remove from array
                    Photos2Display.removeAtIndex(idx)
                    
                    //remove from cache and device?
                    WebUtilities.Caches.imageCache.removeImagefromDevice(imageUrlString)
                    // save changes..or wait until exit?
                    context.save(nil)

                    
                    // found match, break out loop
                    founMatch = true
                    break
              }
            }
            //reload the collection data
            if(founMatch){
                dispatch_async(dispatch_get_main_queue()) {
                    self.photoCollectionView.reloadData()
                }
            }
        }
    }
    
    /*
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: imgDisplayWidth, height: imgDisplayWidth)
    }

    */
    
    // MARK: - Fetched results controller for Photo entity...ordered by title
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName(WebUtilities.Constants.PHOTO_Entity, inManagedObjectContext: context)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = WebUtilities.Constants.MaxPhotoCount
        
        //predicates
        let searchPinValue : Pin = WebUtilities.sharedInstance().hasPinInBBOX(PinLatitude, longitude : PinLongitude)!
        fetchRequest.predicate = NSPredicate(format: "( pin == %@)", searchPinValue)
    
        
        // Edit the sort key as appropriate.
        
        let sortDescriptor = NSSortDescriptor(key: WebUtilities.Constants.PHOTO_SORT_KEY, ascending: false)
        let sortDescriptors = [sortDescriptor]
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "CoreData4VT")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        var error: NSError? = nil
        if !_fetchedResultsController!.performFetch(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            println("Unresolved error \(error), \(error!.userInfo)")
            Utilities.showAlert(self, title: "Unresolved error ", message: "\(error!.userInfo)")
            // abort()
        }
        
        return _fetchedResultsController!
    }

    override func viewWillDisappear(animated: Bool) {
        //clear cache before exit
        NSFetchedResultsController.deleteCacheWithName("CoreData4VT")
        _fetchedResultsController = nil;
        StartPage = 0
    }
    @IBAction func btnNewSetofPhotos(sender: UIButton) {
        //random number between 1 and Pages or sequential
        // StartPage = Int(arc4random_uniform(UInt32(Pages)))
        
        nbrofPhotoLoaded = 0
        // total pages of photos...times of clicks for New Collection
        let total = self.fetchedResultsController.fetchedObjects!.count
        let Pages = total / NumberofPhotosPerPage
       
        var maxPages = Pages
        if(total > Pages * NumberofPhotosPerPage ){
            maxPages = Pages  + 1
        }

        StartPage = StartPage + 1
        if(StartPage > maxPages ){
            Utilities.showAlert(self, title: "Alert", message: "There is no more photos")
            btnNewCollection.enabled = false
            StartPage = 1
            return
        }
        //reload the collection data
        photoCollectionView.reloadData()
    }
  
    // any action I want to perform via delegates
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
       println(self.fetchedResultsController.fetchedObjects!.count)
    }
    
    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
                
                case .Delete:
                     println(self.fetchedResultsController.fetchedObjects!.count)
                default:
                    return
            }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        println(self.fetchedResultsController.fetchedObjects!.count)
    }

}
extension DisplayPhotos : UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

            return CGSize(width: 85, height: 85)
    }
 
    func collectionView( collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
            return 5
    }
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
            return 5
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
}
