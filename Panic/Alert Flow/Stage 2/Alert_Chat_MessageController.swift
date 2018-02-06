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

let messagesController = MessagesController()

class MessagesController: NSObject {
    
    var initialCheck = false
    
    var messages: [MessageType] = []
    
    override init() {
        super.init()
//        if !initialCheck { loadExisting() }
        loadExisting()
    }
    
    func loadExisting() {
        let query = PFQuery(className: "Messages")
        query.includeKey("user")
        query.order(byAscending: "updatedAt")
        query.whereKey("alert", equalTo: alertHandler.currentAlert)
        query.findObjectsInBackground { (messagesArray, error) in
            self.messages = []
            
            if messagesArray != nil {
                for message in messagesArray! {
                    let newMessage =  message as! Sub_PFMessages
                    self.messages.append(newMessage.toMessageType())
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadMessages"), object: nil)
                self.initialCheck = true
            } else if error != nil {
                print("OOPS.... \(error) ... sdjcnksdbnsjc")
            }
        }
    }
    
    func sendNew(text: String) {
        let messageObject = Sub_PFMessages(text: text, alert: alertHandler.currentAlert)
        
        messageObject.saveInBackground(block: {
            (success, error) in

            if success {
                self.showNew(message: messageObject.toMessageType())
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
        let senderName = (messageObject["user"] as! PFObject)["name"] as! String
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


// =============
// DELEGATES AND STUFF
// =============

extension Alert_Chat_VC: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: PFUser.current()!.objectId!, displayName: PFUser.current()!["name"] as! String)
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messagesController.messages.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messagesController.messages[indexPath.section]
    }
    
//    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        let dateString = formatter.string(from: message.sentDate)
//        return NSAttributedString(string: dateString, attributes: [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .caption2)])
//    }
}


extension Alert_Chat_VC: MessagesDisplayDelegate, TextMessageDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor.white : global.themeBlue
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .blue
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubble
    }
    
    func messageHeaderView(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageHeaderView {
        let header = messagesCollectionView.dequeueReusableHeaderView(MessageDateHeaderView.self, for: indexPath)
        return header
    }
}

extension Alert_Chat_VC: MessagesLayoutDelegate {
    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 0, left: 45, bottom: 0, right: 20)
        } else {
            return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 45)
        }
    }
    
    func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        } else {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        }
    }
    
    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        } else {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        }
    }
    
    func avatarAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarAlignment {
        return .messageCenter
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 40, height: 40)
    }
    
    func avatar(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Avatar {
        let initials = message.sender.displayName.trim().components(separatedBy: " ").reduce("") { ($0 == "" ? "" : "\($0.characters.first!)") + "\($1.characters.first!)" }
        return Avatar(image: nil, initals: initials)
    }
}
