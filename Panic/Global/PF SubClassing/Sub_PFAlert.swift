//
//  Sub_PFAlert.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/12/28.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import Parse

class Sub_PFAlert: PFObject, PFSubclassing {
    @NSManaged var user: PFUser!
    @NSManaged var details: String?
    @NSManaged var isActive: NSNumber!
    @NSManaged var responders: [String]!
    @NSManaged var location: PFGeoPoint!
    
    
    static func parseClassName() -> String {
        return "Panics"
    }
    
    init(text: String, user: PFUser, alert: PFObject?) {
        super.init()
    }
    
    override init() {
        super.init()
    }
    
    init(location: CLLocation) {
        super.init()
        self.user = PFUser.current()!
        self.isActive = true
        self.responders = []
        self.location = PFGeoPoint(location: location)
    }
    
    override func saveInBackground(block: PFBooleanResultBlock? = nil) {
        self["user"] = self.user
        self["location"] = self.location
        self["active"] = self.isActive
        self["responders"] = self.responders
        
        super.saveInBackground(block: block)
    }
}
