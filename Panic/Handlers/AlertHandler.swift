//
//  AlertHandler.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/01/18.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit

let alertHandler = AlertHandler()

class AlertHandler: NSObject {
    
    func startAlert() {
        
        locationHandler.getLocationWithAccuracy(accuracy: 100, timeout: 60, completionHandler: {
            latLongDictionary in
            
            print(latLongDictionary)
            
            })
        
    }

}
