//
//  LocationHandler.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/08/29.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import BBLocationManager
import Parse
import Alamofire

let locationHandler = LocationHandler()

class LocationHandler: NSObject, BBLocationManagerDelegate {
    
    let manager = BBLocationManager()
    
    override init() {
        super.init()
        
        manager.delegate = self
        manager.getSingificantLocationChange(withDelegate: self)
    }
    
    /**
     *   Gives an BBFenceInfo Object of the Fence which just added
     */
    public func bbLocationManagerDidAddFence(_ fenceInfo: BBFenceInfo!) {  }
    
    
    /**
     *   Gives an BBFenceInfo Object of the Fence which just failed to monitor
     */
    public func bbLocationManagerDidFailedFence(_ fenceInfo: BBFenceInfo!) {  }
    
    
    /**
     *   Gives an BBFenceInfo Object of a Fence just entered
     */
    public func bbLocationManagerDidEnterFence(_ fenceInfo: BBFenceInfo!) {  }
    
    
    /**
     *   Gives an BBFenceInfo Object of a Exited Fence
     */
    public func bbLocationManagerDidExitFence(_ fenceInfo: BBFenceInfo!) {  }
    
    
    /**
     *   Gives an Location Dictionary using keys BB_LATITUDE, BB_LONGITUDE, BB_ALTITUDE
     */
    public func bbLocationManagerDidUpdateLocation(_ latLongAltitudeDictionary: [AnyHashable : Any]!) {
        let lat = latLongAltitudeDictionary["latitude"] as! Double
        let long = latLongAltitudeDictionary["longitude"] as! Double
        
        print(lat)
        print(long)
        
        let location = PFGeoPoint(latitude: lat, longitude: long)
        
        if PFUser.current() != nil {
            PFUser.current()?.setValue(location, forKey: "lastLocation")
            PFUser.current()?.saveInBackground()
            PFUser.current()?.saveEventually()
        }
        
//        let parameters: Parameters = latLongAltitudeDictionary as! Parameters
//        
//        Alamofire.request("https://requestb.in/1n91z3d1", method: .post, parameters: parameters)
    }
    
    
    /**
     *   Gives an Dictionary using current geocode or adress information with BB_ADDRESS_* keys
     */
    public func bbLocationManagerDidUpdateGeocodeAdress(_ addressDictionary: [AnyHashable : Any]!) {  }

}
