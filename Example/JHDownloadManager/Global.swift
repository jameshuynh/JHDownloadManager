//
//  Global.swift
//  JHDownloadManager
//
//  Created by James Huynh on 25/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

func UIColorFromRGB(rgbValue:Int64) -> UIColor {
    return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16)/255.0, green: CGFloat((rgbValue & 0xFF00) >> 8)/255.0, blue:CGFloat(rgbValue & 0xFF)/255.0, alpha:1.0)
}