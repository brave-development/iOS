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
import Parse

class Reg_Password_VC: Reg_IndividualScreen_VC {
    
    @IBOutlet weak var txtPassword: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func next(_ sender: Any) {
            parentController.currentUser["password"] = txtPassword.text?.trim()
            PFUser.current()?["password"] = txtPassword.text?.trim()
            nextPage()
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
}
