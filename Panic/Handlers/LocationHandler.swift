//
//  LocationHandler.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/08/29.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
//import BBLocationManager
import Parse
import Alamofire
import SwiftLocation

let locationHandler = LocationHandler()

class LocationHandler: NSObject {
    
    func isLocationEnabled(completionHandler handler:@escaping (Bool) -> Void) {
        switch Locator.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            handler(true)
            break
        case .denied, .restricted:
            handler(false)
            break
        case .notDetermined:
            Locator.events.listen {
                newStatus in
                if newStatus == .authorizedAlways || newStatus == .authorizedWhenInUse {
                    handler(true)
                } else {
                    handler(false)
                }
            }
            Locator.requestAuthorizationIfNeeded(.always)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
//    public func bbLocationManagerDidUpdateLocation(_ latLongAltitudeDictionary: [AnyHashable : Any]!) {
//        let lat = latLongAltitudeDictionary["latitude"] as! Double
//        let long = latLongAltitudeDictionary["longitude"] as! Double
//
//        print(lat)
//        print(long)
//
//        let location = PFGeoPoint(latitude: lat, longitude: long)
//
//        if PFUser.current() != nil {
//            PFUser.current()?.setValue(location, forKey: "lastLocation")
//            PFUser.current()?.saveInBackground()
//            PFUser.current()?.saveEventually()
//        }
    
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didUpdateLocation"), object: nil, userInfo: latLongAltitudeDictionary)
        
//        let parameters: Parameters = latLongAltitudeDictionary as! Parameters
//        
//        Alamofire.request("https://requestb.in/1n91z3d1", method: .post, parameters: parameters)
//    }
}
