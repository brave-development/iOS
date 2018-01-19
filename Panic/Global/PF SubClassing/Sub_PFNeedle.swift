//
//  Sub_PFNeedle.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/12/28.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import Parse

class Sub_PFNeedle: PFObject, PFSubclassing {
    @NSManaged var user: PFUser!
    @NSManaged var location: PFGeoPoint!
    
    
    static func parseClassName() -> String {
        return "Needles"
    }
    
    override init() {
        super.init()
    }
    
    init(location: CLLocation) {
        super.init()
        self.user = PFUser.current()!
        self.location = PFGeoPoint(location: location)
    }
    
    override func saveInBackground(block: PFBooleanResultBlock? = nil) {
        self["user"] = self.user
        self["location"] = self.location
        
        super.saveInBackground(block: block)
    }
}

