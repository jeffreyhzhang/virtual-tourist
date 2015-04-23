//
//  MapVC.swift
//  VirtualTour
//
//  Allow Long Press to drop pin
//  immediately call flickr api to get up to MaxPhotoCount images.
//  I store imahe URL and title in DB store, and downlaod image to local file immediately
//  ImageCache is used to save img to file, cache for easy retrival and saving.
//
//  I save Map cenetr and zoom level when the app igoes into background.
//  One interesting finding about Pin 9MKAnnotation)  on map is that once you tap on Pin and navigate to Photo album
//  then Navigate Back to this controller, you tap on the Pin gain, it will not respond...Mapview delegate is not called
//  so the view I created for you to tap the pin is not there anymore. But the callout seems always working. I can tap it
//  and nivate to photo album and nivigate back, and click/tap on  callout, it still works.
//  That is why I have tboth here. Suppose I have only one Pin, once I am back from Album, I can go to album again!
//
//  Created by JeffreyLee on 4/18/15.
//  Copyright (c) 2015 Jeffrey. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapVC:  UIViewController, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var MyMap: MKMapView!
    // Core Data
    let context = CoreDataManager.sharedInstance().managedObjectContext!
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MyMap.mapType = MKMapType.Standard
        MyMap.delegate = self
        
        if ( self.fetchedResultsController.fetchedObjects?.count > 0) {
            
            //load all  map pins
            for  object in  self.fetchedResultsController.fetchedObjects as! [Pin] {
                let mypin = MKPointAnnotation()
                let formatter = NSNumberFormatter()
                formatter.maximumFractionDigits = 2
                formatter.minimumFractionDigits = 2
                mypin.title =   formatter.stringFromNumber(object.latitude)
                mypin.subtitle = formatter.stringFromNumber(object.longitude)
                mypin.coordinate = CLLocationCoordinate2DMake(object.latitude, object.longitude)
                MyMap.addAnnotation(mypin)
            }
            
            // restore map cenetr and zoom level
            
            WebUtilities.sharedInstance().restoreMapState(MyMap)
        } 
    }
    
    //allow mutiple gesture recognizer
    func gestureRecognizer(UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
            return true
    }

    func gestureRecognizerShouldBegin(_gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    

    
    // MARK: drop pin for longpress
    //       First check if there is already PIN nearby within BBOX
    
    @IBAction func handleLongPress(recognizer:UILongPressGestureRecognizer) {

        if !Utilities.isConnectedToNetwork() {
            Utilities.showAlert(self, title: "Service not available", message: "Cannot connect to network")
            return
        }
        
        if(recognizer.state == UIGestureRecognizerState.Began){
            
            let tapPoint :CGPoint = recognizer.locationInView(MyMap)
            let tapMapCoordinate = MyMap.convertPoint(tapPoint, toCoordinateFromView: MyMap)
            addPinOnMap(tapMapCoordinate )
        }
    }
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        //if drag ends
        if recognizer.state == UIGestureRecognizerState.Ended {
            println("End drag!")
        }
    }

    // add pin  and  save to store
    func addPinOnMap(tapMapCoordinate: CLLocationCoordinate2D ) {

        let lat = (tapMapCoordinate.latitude as NSNumber).doubleValue
        let long = (tapMapCoordinate.longitude as NSNumber).doubleValue
        
        if (WebUtilities.sharedInstance().hasPinInBBOX(lat, longitude : long) != nil) {
            Utilities.showAlert(self, title: "Error", message: "There is already a pin within range!")
            return
        }
        
        var mypin = MKPointAnnotation()
        
        var formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        mypin.title =   formatter.stringFromNumber(lat)
        mypin.subtitle = formatter.stringFromNumber(long)
        mypin.coordinate = tapMapCoordinate
        MyMap.addAnnotation(mypin)

       //Add to store
        WebUtilities.sharedInstance().addPin2Store(lat,long: long)
        
        //save mapstate...in case you immediately go to photo album
        WebUtilities.sharedInstance().SaveMapState(MyMap)
        
        //store photo URL in DB and download img to filesystem
        WebUtilities.sharedInstance().getPhotos() { (results, error) in
            if(error == nil) {
                for photo in results! {
                    //download image to file....
                    WebUtilities.sharedInstance().saveImage(photo.photoUrl)
                }
            }
         }
    }
    

    //MARK :  MapView delegate...so we can load images from flickr
    func mapView(mapView: MKMapView!,  viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {

            if (annotation is MKUserLocation) {
                return nil
            }
            
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView {
                    //only here when drag map (delegate) etc
                    dequeuedView.annotation = annotation
                    view = dequeuedView

            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                view.userInteractionEnabled = true
                
                // above allow you click once...i.e. userInteractionEnabled is false once cliciked?
                
                //the following three add callout allow click multiple times
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIView
                // if you have a custom img instead of Pin
                // view.image =  UIImage(named:"imgplaceholder")

            }
            return view
    }
    
    //click on right callout btn...
    func mapView(mapView: MKMapView!, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl){
       showPhotos(annotationView)
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!)
    {
       showPhotos(view)
    }
    
    func showPhotos(view: MKAnnotationView!){
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var newVC = mainStoryboard.instantiateViewControllerWithIdentifier("ShowPhotos") as!  DisplayPhotos
        let lat = (view.annotation.title!  as NSString).doubleValue
        let long = (view.annotation.subtitle! as  NSString).doubleValue
        newVC.PinLatitude = lat
        newVC.PinLongitude = long
        
        navigationController?.navigationBarHidden = false
        
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    //when zoom changes or move the map, we need save it?....for testing
    func mapView( mapView: MKMapView!, regionDidChangeAnimated animated: Bool){
          //println("Saving state...zooom")
    }
    
    override func viewWillAppear(animated: Bool) {

        //set UIPanGestureRecognizer so we can click the same pin again when Back from photo album display
        
        //I need be notified UIApplicationWillEnterForegroundNotification
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "enterbkgrnd:",
            name: UIApplicationDidEnterBackgroundNotification,
            object: nil)
        
        //hide topnavbar
        navigationController?.navigationBarHidden = true
    }
    
    func  enterbkgrnd( sender: AnyObject ){
        
         WebUtilities.sharedInstance().SaveMapState(MyMap)
    }
    
    // save Map zoom level before closing app
    override func viewWillDisappear(animated: Bool) {

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
  
    // MARK: - Fetched results controller for Pin entity
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName(WebUtilities.Constants.PIN_Entity, inManagedObjectContext: context)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = WebUtilities.Constants.MaxPhotoCount
        
        // Edit the sort key as appropriate.
        
        let sortDescriptor = NSSortDescriptor(key: WebUtilities.Constants.PIN_SORT_KEY, ascending: false)
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
    
}

