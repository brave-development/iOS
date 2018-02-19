//
//  Alert_InputMessageBar.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/12/24.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import MessageKit
import ChameleonFramework

class Alert_InputMessageBar: MessageInputBar {
    
    init() {
        super.init(frame: .zero)
        build()
    }
    
    func build() {
        delegate = self

        isTranslucent = false
        backgroundColor = UIColor.clear
        separatorLine.isHidden = true
        inputTextView.textColor = UIColor.white
        inputTextView.backgroundColor = global.themeBlue
        inputTextView.placeholderTextColor = UIColor.white
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 36)
        inputTextView.layer.borderWidth = 0
        inputTextView.layer.cornerRadius = 10
        inputTextView.layer.masksToBounds = true
        inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        setRightStackViewWidthConstant(to: 36, animated: false)
        setStackViewItems([sendButton], forStack: .right, animated: true)
        sendButton.imageView?.contentMode = .scaleAspectFit
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 8, right: 2)
        sendButton.setSize(CGSize(width: 32, height: 32), animated: true)
        sendButton.image = #imageLiteral(resourceName: "plus.png")
        sendButton.title = nil
//        sendButton.imageView?.layer.cornerRadius = 0
//        sendButton.backgroundColor = .clear
        textViewPadding.right = -38
        textViewPadding.top = 20
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension Alert_InputMessageBar: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        messagesController.sendNew(text: inputBar.inputTextView.text)
        inputBar.inputTextView.text = ""
    }
}




