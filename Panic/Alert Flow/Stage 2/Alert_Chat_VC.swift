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
    let textInputBar = ALTextInputBar()

    override func viewDidLoad() {
        super.viewDidLoad()

        messagesCollectionView.messagesDataSource = self as! MessagesDataSource
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        loadFakeMessage()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let when = DispatchTime.now() + .seconds(3)
        DispatchQueue.main.asyncAfter(deadline: when) {
            let newMessage = Message(text: "Hello tester Sender", sender: Sender(id: "0001", displayName: "Steven"), messageId: "\(Int(arc4random_uniform(UInt32(100))))", date: self.dateAddingRandomTime())
            self.messages.append(newMessage)
            self.messagesCollectionView.reloadData()
        }
    }
    
    func loadFakeMessage() {
        let newMessage = Message(text: "Hello tester Sender", sender: Sender(id: "0001", displayName: "Steven"), messageId: "\(Int(arc4random_uniform(UInt32(100))))", date: dateAddingRandomTime())
        let newMessage2 = Message(text: "Hello tester Paul", sender: Sender(id: "0002", displayName: "Paul"), messageId: "\(Int(arc4random_uniform(UInt32(100))))", date: dateAddingRandomTime())
        let newMessage3 = Message(text: "Hello tester Luise", sender: Sender(id: "0003", displayName: "Luise"), messageId: "\(Int(arc4random_uniform(UInt32(100))))", date: dateAddingRandomTime())
        messages.append(newMessage)
        messages.append(newMessage2)
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
    
    override var inputAccessoryView: UIView? {
        get {
            return textInputBar
        }
    }
    
    // Another ingredient in the magic sauce
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
