//
//  PhotoCell.swift
//  VirtualTour
//
//  Built in Activity alert, so we can display when needed, as image is downloading
//
//  Created by Jeffrey Zhang on 4/19/15.
//  Copyright (c) 2015 Jeffrey. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell: UICollectionViewCell {
    @IBOutlet weak var imgVw: UIImageView!
    
    @IBOutlet weak var activityVw: UIActivityIndicatorView!
}
