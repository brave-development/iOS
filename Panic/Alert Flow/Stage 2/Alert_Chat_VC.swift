//
//  Alert_Chat_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/11/29.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import MessageKit

class Alert_Chat_VC: MessagesViewController {
    
    var messages: [MessageType] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        loadFakeMessage()
        loadFakeMessage()
        loadFakeMessage()
        loadFakeMessage()
        
    }
    
    func loadFakeMessage() {
        let newMessage = Message(text: "Hello tester", sender: Sender(id: "0001", displayName: "Steven"), messageId: "\(Int(arc4random_uniform(UInt32(100))))", date: dateAddingRandomTime())
        let newMessage2 = Message(text: "Hello tester Paul", sender: Sender(id: "0002", displayName: "Paul"), messageId: "\(Int(arc4random_uniform(UInt32(100))))", date: dateAddingRandomTime())
        let newMessage3 = Message(text: "Hello tester Luise", sender: Sender(id: "0003", displayName: "Luise"), messageId: "\(Int(arc4random_uniform(UInt32(100))))", date: dateAddingRandomTime())
        messages.append(newMessage)
        messages.append(newMessage2)
        messages.append(newMessage3)
    }
    
    func dateAddingRandomTime() -> Date {
        var now = Date()
        let randomNumber = Int(arc4random_uniform(UInt32(10)))
        if randomNumber % 2 == 0 {
            let date = Calendar.current.date(byAdding: .hour, value: randomNumber, to: now)!
            now = date
            return date
        } else {
            let randomMinute = Int(arc4random_uniform(UInt32(59)))
            let date = Calendar.current.date(byAdding: .minute, value: randomMinute, to: now)!
            now = date
            return date
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension Alert_Chat_VC: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: "0001", displayName: "Steven")
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return 4
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
}


extension Alert_Chat_VC: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
        //        let configurationClosure = { (view: MessageContainerView) in}
        //        return .custom(configurationClosure)
    }
}

extension Alert_Chat_VC: MessagesLayoutDelegate {
//    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
//        if isFromCurrentSender(message: message) {
//            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)
//        } else {
//            return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
//        }
//    }
    
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
    
//    func avatarAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarAlignment {
//        return .messageBottom
//    }
    
//    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
//
//        return CGSize(width: messagesCollectionView.bounds.width, height: 10)
//    }
}
