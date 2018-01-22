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
    @NSManaged var active: NSNumber!
    @NSManaged var responders: [String]!
    @NSManaged var location: PFGeoPoint!
    
    
    static func parseClassName() -> String {
        return "Panics"
    }
    
    override init() {
        super.init()
    }
    
    init(parseObject: PFObject) {
        super.init()
        self.objectId = parseObject.objectId!
        
        self.user = parseObject["user"] as! PFUser
        self.location = parseObject["location"] as! PFGeoPoint
        self.active = parseObject["active"] as! NSNumber
        self.responders = parseObject["responders"] as! [String]
    }
    
    init(location: CLLocation) {
        super.init()
        self.user = PFUser.current()!
        self.active = true
        self.responders = []
        self.location = PFGeoPoint(location: location)
    }
    
    func addResponder() {
        if !self.responders.contains(PFUser.current()!.objectId!) {
            self.responders.append(PFUser.current()!.objectId!)
            self.saveInBackground()
        }
    }
    
    func removeResponder() {
        if let index = self.responders.index(of: PFUser.current()!.objectId!) {
            self.responders.remove(at: index)
            self.saveInBackground()
        }
    }
    
    override func saveInBackground(block: PFBooleanResultBlock? = nil) {
        self["user"] = self.user
        self["location"] = self.location
        self["active"] = self.active
        self["responders"] = self.responders
        
        super.saveInBackground(block: block)
        
//        super.saveInBackground { (success, error) in
//            print(self.objectId)
//        }
    }
}
