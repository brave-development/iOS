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
        txtPassword.delegate = self
        
        title = "Password"
    }
    
    @IBAction func next(_ sender: Any) {
            parentController.currentUser["password"] = txtPassword.text?.trim()
            PFUser.current()?["password"] = txtPassword.text?.trim()
            nextPage()
    }
    
    @IBAction func validate(_ sender: Any) {
        if validInput() {
            btnNext.showWithAnimation(animation: "zoomIn")
        } else {
            btnNext.hideWithDuration()
        }
    }
    
    func validInput() -> Bool {
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
        
        return validation.validate(txtPassword.text?.trim(), context: nil)
    }
}

extension Reg_Password_VC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if validInput() { btnNext.sendActions(for: .touchUpInside) }
        else {
            let toastCenter = CGPoint(x: txtPassword.center.x, y: txtPassword.center.y-60)
            view.makeToast("Required\nMin 6\nMax 30", duration: 5, position: NSValue(cgPoint: toastCenter))
        }
        return false
    }
}
