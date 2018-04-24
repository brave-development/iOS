//
//  Sub_PFAlertGroup.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/02/19.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

class Sub_PFAlertGroup: PFObject, PFSubclassing {
    @NSManaged var user: PFUser!
    @NSManaged var group: PFObject
    @NSManaged var panic: Sub_PFAlert!
    
    var active : Bool! {
        get { return self["active"] != nil ? self["active"] as! Bool : false }
        set(newStatus){ self["active"] = newStatus as NSNumber }
    }
    
    static func parseClassName() -> String {
        return "AlertGroup"
    }
}
