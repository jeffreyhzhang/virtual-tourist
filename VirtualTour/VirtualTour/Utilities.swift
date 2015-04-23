//
//  Utilities.swift
//
//
//
//  I put some common utility func here so every viewcontroller can use
//
//
//  Basedon my OnTheMap Projetcs
//
//  Created by Jeffrey Zhang on 3/28/15.
//  Copyright (c) 2015 Jeffrey. All rights reserved.
//

import Foundation
import UIKit;
import SystemConfiguration


public class Utilities {
    
    
    //generic alert...with callback function when OK'd
    class func showAlert( who : UIViewController, title: String, message : String) {
        let myAlert = UIAlertController()
        myAlert.title = title
        myAlert.message = message
    
        let myaction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            
        myAlert.addAction(myaction)
        who.presentViewController(myAlert, animated:true , completion:nil)
    }
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
        }
        
        var flags: SCNetworkReachabilityFlags = 0
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
            return false
        }
        
        let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return (isReachable && !needsConnection) ? true : false
    }
    
    // another way to check...try to get to google.com
    // since google is the most reliable site there is
    // if you cannot get to it...then network issue.
    //
    class func isNetworkAvialable(urlforTest: String?)->Bool{
        
        var Status:Bool = false
        var myurl =  urlforTest!.isEmpty ? "http://google.com/" : urlforTest!
        let url = NSURL(string: myurl)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "HEAD"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0
        
        var response: NSURLResponse?
        
        var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: nil) as NSData?
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                Status = true
            }
        }
        
        return Status
    }
}