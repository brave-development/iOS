//
//  AlertStage_2_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/11/29.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import MessageKit

class AlertStage_2_VC: UIViewController {

    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var blur: UIVisualEffectView!
    @IBOutlet weak var viewDetails: UIView!
    @IBOutlet weak var viewContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnBack.imageEdgeInsets = UIEdgeInsetsMake(10, 8, 6, 8)
        
        self.view.insertSubview(blur, at: 0)
        view.backgroundColor = UIColor.clear
        
        viewDetails.layer.shadowOffset = .zero
        viewDetails.layer.shadowRadius = 3
        viewDetails.layer.shadowOpacity = 0.4
        
        
        let vc = storyboard!.instantiateViewController(withIdentifier: "alert_Chat_VC") as! Alert_Chat_VC
        self.addChildViewController(vc)
        vc.view.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.size.width, height: self.viewContainer.frame.size.height)
        viewContainer.addSubview(vc.view)

        vc.didMove(toParentViewController: self)
        
        messagesController.loadExisting()
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
