//
//  Reg_Password_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/07/21.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import ChameleonFramework
import Spring
import SwiftValidate

class Reg_Password_VC: UIViewController {
    
    @IBOutlet weak var imgIcon: SpringImageView!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnNext: Sub_SpringButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        btnNext.alpha = 0
        
        imgIcon.layer.shadowRadius = 4
        imgIcon.layer.shadowOpacity = 0.4
        imgIcon.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Timer.scheduledTimer(withTimeInterval: 7, repeats: true, block: {_ in
            self.imgIcon.animation = "swing"
            self.imgIcon.duration = 1
            self.imgIcon.animate()
        })
    }
    
    @IBAction func next(_ sender: Any) {
        if let parent = self.parent as? RegistrationController_VC {
            parent.currentUser["password"] = txtPassword.text?.trim().lowercased()
            parent.nextPage()
        }
    }
    
    @IBAction func back(_ sender: Any) {
        if let parent = self.parent as? RegistrationController_VC {
            parent.previousPage()
        }
    }
    
    @IBAction func validate(_ sender: Any) {
        let validation = ValidatorChain() {
                $0.stopOnFirstError = true
                $0.stopOnException = true
            }
            <~~ ValidatorRequired()
            <~~ ValidatorEmpty()
            <~~ ValidatorStrLen() {
                $0.minLength = 6
                $0.maxLength = 30
        }
        
        if validation.validate(txtPassword.text?.trim(), context: nil) {
            btnNext.showWithAnimation(animation: "zoomIn")
        } else {
            btnNext.hideWithDuration()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
