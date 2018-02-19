//
//  Message.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/11/29.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import MessageKit
import CoreLocation
import Parse

struct Message: MessageType {
    
    var messageId: String
    var sender: Sender
    var sentDate: Date
    var data: MessageData
    
    init(data: MessageData, sender: Sender, messageId: String, date: Date) {
        self.data = data
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
    }
    
    init(text: String, sender: Sender, messageId: String, date: Date) {
//        let oldText = NSMutableAttributedString(string: "\(sender.displayName)\n\(text)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18)])
        let oldText = NSMutableAttributedString(string: "\(text)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18)])
//        oldText.addAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 9)], range: NSRange(location: 0, length: sender.displayName.length))
        
        if sender.id == PFUser.current()!.objectId {
            oldText.addAttributes([NSForegroundColorAttributeName : UIColor.flatBlack], range: NSRange(location: 0, length: oldText.length))
        } else {
            oldText.addAttributes([NSForegroundColorAttributeName : UIColor.white], range: NSRange(location: 0, length: oldText.length))
        }
        
        self.init(data: .attributedText(oldText), sender: sender, messageId: messageId, date: date)
    }
    
    init(attributedText: NSAttributedString, sender: Sender, messageId: String, date: Date) {
        self.init(data: .attributedText(attributedText), sender: sender, messageId: messageId, date: date)
    }
    
    init(image: UIImage, sender: Sender, messageId: String, date: Date) {
        self.init(data: .photo(image), sender: sender, messageId: messageId, date: date)
    }
    
    init(thumbnail: UIImage, sender: Sender, messageId: String, date: Date) {
        let url = URL(fileURLWithPath: "")
        self.init(data: .video(file: url, thumbnail: thumbnail), sender: sender, messageId: messageId, date: date)
    }
    
    init(location: CLLocation, sender: Sender, messageId: String, date: Date) {
        self.init(data: .location(location), sender: sender, messageId: messageId, date: date)
    }
    
    init(emoji: String, sender: Sender, messageId: String, date: Date) {
        self.init(data: .emoji(emoji), sender: sender, messageId: messageId, date: date)
    }
    
}
