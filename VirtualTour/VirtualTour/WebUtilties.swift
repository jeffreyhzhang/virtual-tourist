//
//  WebUtilties.swift
//
//
//
//  Based on my OnTheMap project
//
//  Copyright (c) 2015 Jarrod Parkes. All rights reserved.
//
//
import Foundation
import UIKit

class WebUtilities : NSObject {
    
    /* Shared session */
    var session: NSURLSession
    
    
    /* this is current or latest Pin dropped */
    var CurrentPin: Pin?
    
    // used for imageplacehoder
    var imgplacehdr: UIImage!
    
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    
    
    // MARK: - GET
  
    func taskForGETMethod(urlpath: String, parameters: [String : AnyObject]?, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
       
         var urlString = urlpath
         if (parameters != nil ) {
             var mutableParameters = parameters
            /* 2/3. Build the URL and configure the request */
            urlString = urlpath + WebUtilities.escapedParameters(mutableParameters!)
         }

        // print so you know where to clear the files and db store
        println(urlString)
        
       //this can cause exposion??? when you have space etc in search
        
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"

        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in

            /* 5/6. Parse the data and use the data (happens in completion handler) */
            if let error = downloadError {
                let newError = WebUtilities.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: downloadError)
            } else {
                WebUtilities.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
            }
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    
    // MARK: - Helpers
    // These functions are class level function or type method that are not tied to specifuc instances
    // like sticit method in struct...you can you it without an instacnes of the class as object!
    //
    /* Helper: Substitute the key for the value that is contained within the method name */
    class func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    /* Helper: Given a response with error, see if a status_message is returned, otherwise return the previous error */
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String : AnyObject] {
            
            if let errorMessage = parsedResult[WebUtilities.JSONResponseKeys.StatusMessage] as? String {
                
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                return NSError(domain: "Error", code: 1, userInfo: userInfo)
            }
        }
        
        return error
    }
    
    /* Helper: Given raw JSON, return a usable Foundation object */
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
            
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    /* Helper: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
           // let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* FIX: Replace spaces with '+' */
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
            /* Append it */
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    // MARK: - Shared Instance
    //
    //
    class func sharedInstance() -> WebUtilities {
        
        struct Singleton {
            static var sharedInstance = WebUtilities()
        }
        
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
}