//
//  Alert_Chat_MessageController.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/12/14.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import MessageKit
import Parse
import ChameleonFramework
import SwiftyJSON
import ParseLiveQuery

//let messagesController = MessagesController()

class MessagesController: NSObject {
    
    var initialCheck = false
    
    var alert: Sub_PFAlert!
    var messages: [MessageType] = []
    
    var subscription_messages: Subscription<PFObject>!
    let messagesQuery = Sub_PFMessages.query()!
    
    init(alert: Sub_PFAlert) {
        super.init()
//        if !initialCheck { loadExisting() }
        self.alert = alert
        loadExisting()
    }
    
    func loadExisting() {
        messagesQuery.cancel()
        messagesQuery.includeKey("user")
        messagesQuery.order(byAscending: "updatedAt")
        messagesQuery.whereKey("alert", equalTo: alert)
        messagesQuery.findObjectsInBackground { (messagesArray, error) in
            self.messages = []
            
            if messagesArray != nil {
                for message in messagesArray! {
                    let newMessage =  message as! Sub_PFMessages
                    self.messages.append(newMessage.toMessageType())
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadMessages"), object: nil)
                self.initialCheck = true
                self.addSubscriptions()
            } else if error != nil {
                print("OOPS.... \(error) ... sdjcnksdbnsjc")
            }
        }
    }
    
    func addSubscriptions() {
        subscription_messages = Client.shared.subscribe(messagesQuery).handle(Event.created) {
            _, message in
            
            (message as! Sub_PFMessages).user.fetchIfNeededInBackground(block: {
                user, error in
                
                self.recieveNew(messageObject: message as! Sub_PFMessages)
            })
        }
    }
    
    func sendNew(text: String) {
        let messageObject = Sub_PFMessages(text: text, alert: alert)
        
        messageObject.saveInBackground(block: {
            (success, error) in

            if success {
//                self.showNew(message: messageObject.toMessageType())
//                self.recieveNew(messageObject: messageObject)
            } else if error != nil {
                print("OOPS... \(error!)")
            } else {
                print("OOPS... No error... 9834nyr98nrucm3u4r0io3mc")
            }
        })
    }
    
    func fetchNewMessage(objectId: String) {
        let query = PFQuery(className: "Messages")
        query.includeKey("user")
        query.whereKey("objectId", equalTo: objectId)
        
        query.getFirstObjectInBackground(block: {
            (message, error) in
            if error != nil { print("Error fetching new message.... idkjvhiew874sercy8") }
            if message != nil { self.recieveNew(messageObject: message! as! Sub_PFMessages) }
        })
    }
    
    func recieveNew(messageObject: Sub_PFMessages) {
        if messageObject.user == PFUser.current() { return }
        
        let text = messageObject["text"] as! String
        let senderId = (messageObject["user"] as! PFObject).objectId
        let senderName = messageObject.user["name"] as! String
        let messageId = messageObject.objectId
        let date = messageObject.createdAt
        
        let message = Message(text: text, sender: Sender(id: senderId!, displayName: senderName), messageId: messageId!, date: date!)
        
        showNew(message: message)
    }
    
    func showNew(message: Message) {
        messages.append(message)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadMessages"), object: nil)
    }
}
