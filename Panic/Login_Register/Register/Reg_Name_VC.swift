//
//  Reg_Name_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/07/27.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import SwiftValidate
import Parse
import Toast

class Reg_Name_VC: Reg_IndividualScreen_VC {
    
    @IBOutlet weak var txtName: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        txtName.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        txtName.becomeFirstResponder()
    }
    
    @IBAction func next(_ sender: Any) {
        parentController.currentUser["name"] = txtName.text?.trim()
        PFUser.current()?["name"] = txtName.text?.trim()
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
                $0.minLength = 3
                $0.maxLength = 25
            }
            <~~ ValidatorRegex() {
                $0.pattern = "[A-Za-z.-[:blank:]]+"
        }
        
        return validation.validate(txtName.text?.trim(), context: nil)
    }
}

extension Reg_Name_VC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if validInput() { btnNext.sendActions(for: .touchUpInside) }
        else {
            let toastCenter = CGPoint(x: txtName.center.x, y: txtName.center.y-70)
            view.makeToast("Required\nOnly A-Z letters\nMin 5\nMax 25", duration: 5, position: NSValue(cgPoint: toastCenter))
        }
        return false
    }
}
