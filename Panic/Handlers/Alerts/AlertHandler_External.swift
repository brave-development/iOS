//
//  AlertHandler_External.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/01/30.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

extension AlertHandler {

    func getActiveAlerts(completion: @escaping ([Sub_PFAlert])->Void) {
        let query = PFQuery(className: "Alerts")
        query.whereKey("active", equalTo: true)
        query.whereKeyExists("details")
        query.includeKey("user")
        
        query.findObjectsInBackground {
            objects, error in
            
            if error != nil || objects == nil {
                completion([])
                print(error)
                return
            }
            
            completion(objects! as! [Sub_PFAlert])
        }
    }
}
