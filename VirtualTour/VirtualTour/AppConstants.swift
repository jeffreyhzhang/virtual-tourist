import Foundation
//
//  AppConstants.swift
//
//
//  All constants used in this project: flickr API
//
//  Created by Jeffrey Zhang
//  Concept based on my OnTheMap project
//
//  Copyright (c) 2015 Jeffrey Zhang. All rights reserved.
//

extension WebUtilities {
    
    // MARK: - Constants
    struct Constants {
        static let APIKEY : String = "ce190e05b11ca689a9c1fac8c9de619d"
        /* if BBOx too big, one photo may have many pins....end up with Many-to-many relationship*/
        static let BOUNDING_BOX_HALF_WIDTH = 0.005
        static let BOUNDING_BOX_HALF_HEIGHT = 0.005
        
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        static let METHOD_NAME = "flickr.photos.search"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        
        static let PIN_SORT_KEY =  "latitude"
        static let PHOTO_SORT_KEY =  "photoTitle"
        
        static let PIN_Entity = "Pin"
        static let PHOTO_Entity = "Photo"
        static let MAPREGION_Entity = "MapRegion"
        
        static let PHOT_PER_PAGE = "30"
        static let MaxPhotoCount = 30  //maximun I will download
      }
    
    // MARK: - UrlPaths..RESTful svc
    struct UrlPaths {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
    }
    
    
    // MARK: - Parameter Keys
    struct ParameterKeys {
         static let Method = "method"
         static let API_Key = "api_key"
         static let BBox = "bbox"
         static let Safe_Search = "safe_search"
         static let Extras = "extras"
         static let Format = "format"
         static let NoJSONCallback = "nojsoncallback"
         static let PerPage = "per_page"
    }
    
    // MARK: - JSON Response Keys
    struct JSONResponseKeys {
        
        // MARK: General
        static let StatusMessage = "error"
        static let StatusCode = "status code"
        
        // MARK: Photo
        static let FlickrTitle = "title"
        static let FlickrUrlm = "url_m"
        static let FlickrPhotos = "photos"
        static let FlickrPages = "pages"
        static let FlickrTotal = "total"
        static let FlickrPhoto = "photo"
        
        // this is for holding all results from JSON returned from request
        static let PhotoResults = "photos"
    }
}