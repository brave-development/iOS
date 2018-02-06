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

    func getActivePanics(completion: @escaping ([Sub_PFAlert])->Void) {
        var groups : [[String : Any]] = []
        
        for (_, group) in groupsHandler.joinedGroupsObject {
            if let groupObjectId = group.objectId {
                groups.append(buildGroupPointer(objectId: groupObjectId))
            }
        }
        
        if groups.count > 0 {
            PFCloud.callFunction(inBackground: "getActiveAlerts", withParameters: [ "groups" : groups ] ) {
                response, error in
                
                if let objects = response as? [PFObject] {
                    var alerts : [Sub_PFAlert] = []
                    
                    for object in objects {
                        (object["panic"] as! Sub_PFAlert).setObject(object["user"], forKey: "user")
                        alerts.append(object["panic"] as! Sub_PFAlert)
                    }
                    completion(alerts)
                } else {
                    completion([])
                }
            }
        } else if groups.count != groupsHandler.joinedGroupsObject.count {
            completion([])
        }
    }
}
