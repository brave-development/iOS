//
//  AlertStage_2_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/11/29.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import MessageKit
import SCLAlertView
import Parse

class AlertStage_2_VC: UIViewController {

    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnAdminOptions: UIButton!
    @IBOutlet weak var blur: UIVisualEffectView!
    @IBOutlet weak var viewDetails: UIView!
    @IBOutlet weak var viewContainer: UIView!
    
    var alert: Sub_PFAlert!
    var chatController: Alert_Chat_VC!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnBack.imageEdgeInsets = UIEdgeInsetsMake(10, 8, 6, 8)
        
        self.view.insertSubview(blur, at: 0)
        view.backgroundColor = UIColor.clear
        
        viewDetails.layer.shadowOffset = .zero
        viewDetails.layer.shadowRadius = 3
        viewDetails.layer.shadowOpacity = 0.4
        
        chatController = storyboard!.instantiateViewController(withIdentifier: "alert_Chat_VC") as! Alert_Chat_VC
        chatController.alert = alert
        self.addChildViewController(chatController)
        chatController.view.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.size.width, height: self.viewContainer.frame.size.height)
        viewContainer.addSubview(chatController.view)

        chatController.didMove(toParentViewController: self)
        
        guard let isAdmin = PFUser.current()?["admin"] as? Bool else { return }
        
        btnAdminOptions.isHidden = !isAdmin || !alert.isActive
    }
    
    @IBAction func more(_ sender: Any) {
        let alert = SCLAlertView()
        alert.addButton("Resolve alert") {
            self.alert.active = false
            self.alert.saveInBackground()

            SCLAlertView().showInfo("Resolved", subTitle: "This alert has been marked as Resolved")
            self.btnBack.sendActions(for: .touchUpInside)
        }

        alert.addButton("Call Alerter") {
            guard let alerterNumber = (self.alert["user"] as! PFObject)["cellNumber"] as? String else {
                SCLAlertView().showInfo("Hmm", subTitle: "The alerters number doesn't seem to be valid... Try message them in the chat.")
                return
            }
            guard let number = URL(string: "tel://\(alerterNumber)") else { return }
            UIApplication.shared.open(number)
        }
        
        chatController.messageInputBar.isHidden = true
        chatController.messageInputBar.resignFirstResponder()
        alert.showNotice("Admin Options", subTitle: "").setDismissBlock {
            self.chatController.messageInputBar.isHidden = false
        }
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
