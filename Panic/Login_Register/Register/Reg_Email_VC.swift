//
//  Reg_Email_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/07/21.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import ChameleonFramework
import SwiftValidate
import Spring
import Parse

class Reg_Email_VC: Reg_IndividualScreen_VC {

    @IBOutlet weak var txtEmail: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func next(_ sender: Any) {
        parentController.currentUser["email"] = txtEmail.text?.trim().lowercased()
        PFUser.current()?["email"] = txtEmail.text?.trim().lowercased()
        nextPage()
    }
    
    @IBAction func validate(_ sender: Any) {
        let validation = ValidatorEmail()
        
        do {
            if try validation.validate(txtEmail.text?.trim(), context: [:]) {
                btnNext.showWithAnimation(animation: "zoomIn")
            } else {
                btnNext.hideWithDuration()
            }
        } catch {
            btnNext.hideWithDuration()
        }
    }
}


