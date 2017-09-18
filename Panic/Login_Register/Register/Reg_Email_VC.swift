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
        txtEmail.delegate = self
    }
    
    @IBAction func next(_ sender: Any) {
        parentController.currentUser["email"] = txtEmail.text?.trim().lowercased()
        PFUser.current()?["email"] = txtEmail.text?.trim().lowercased()
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
                $0.minLength = 5
                $0.maxLength = 25
            }
            <~~ ValidatorRegex() {
                $0.pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        }
        
        if validation.validate(txtEmail.text?.trim(), context: nil) {
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
                $0.maxLength = 50
            }
            <~~ ValidatorRegex() {
                $0.pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        }
        
        return validation.validate(txtEmail.text?.trim(), context: nil)
    }
}

extension Reg_Email_VC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if validInput() { btnNext.sendActions(for: .touchUpInside) }
        else {
            let toastCenter = CGPoint(x: txtEmail.center.x, y: txtEmail.center.y-70)
            view.makeToast("Required\nMust be a valid address\nMin 6\nMax 25", duration: 5, position: NSValue(cgPoint: toastCenter))
        }
        return false
    }
}

