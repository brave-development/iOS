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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        messagesCollectionView.backgroundColor = UIColor.clear

        messagesCollectionView.messagesDataSource = self as! MessagesDataSource
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar = Alert_InputMessageBar()
        reloadInputViews()
        self.becomeFirstResponder()
        
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
