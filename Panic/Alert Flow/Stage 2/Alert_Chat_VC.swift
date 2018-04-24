//
//  Alert_Chat_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/11/29.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import MessageKit
import Parse

class Alert_Chat_VC: MessagesViewController {
    
    var alert: Sub_PFAlert!
    var messagesController: MessagesController!

    override func viewDidLoad() {
        super.viewDidLoad()
        messagesController = MessagesController(alert: alert)
        
        view.backgroundColor = UIColor.clear
        messagesCollectionView.backgroundColor = UIColor.clear

        messagesCollectionView.messagesDataSource = self as! MessagesDataSource
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        if alert.isActive {
            messageInputBar = Alert_InputMessageBar(alert: alert, controller: messagesController)
            reloadInputViews()
            self.becomeFirstResponder()
        } else {
            messageInputBar.isHidden = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadMessages), name: NSNotification.Name(rawValue: "reloadMessages"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let when = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.becomeFirstResponder()
        }
    }
    
    func reloadMessages() {
        self.messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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


extension Alert_Chat_VC: MessagesDisplayDelegate {
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

