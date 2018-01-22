//
//  Sub_PFMessages.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/12/28.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import Parse
import MessageKit

class Sub_PFMessages: PFObject, PFSubclassing {
    @NSManaged var displayName: String!
    @NSManaged var user: PFUser!
    @NSManaged var alert: PFObject?
    @NSManaged var text: String!
    
    static func parseClassName() -> String {
        return "Messages"
    }
    
    override init() {
        super.init()
    }
    
    init(text: String, alert: PFObject?) {
        super.init()
        
        self.user = PFUser.current()!
        self.displayName = PFUser.current()!["name"] as! String
        self.text = text
        self.alert = alert
    }
    
    init(parseObject: PFObject) {
        super.init()
        
        self.text = parseObject["text"] as! String
        self.user = parseObject["user"] as! PFUser
        self.displayName = parseObject["name"] as! String
        self.alert = parseObject["alert"] as? PFObject
    }
    
    func toMessageType() -> MessageType {
        let senderId = user.objectId!
        let senderName = user["name"] as! String
        
        return Message(text: text, sender: Sender(id: senderId, displayName: senderName), messageId: self.objectId!, date: self.createdAt!)
    }
}
