//
//  Reg_CellNumber_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/08/10.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import SwiftValidate

class Reg_CellNumber_VC: Reg_IndividualScreen_VC {
    
    @IBOutlet weak var txtNumber: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtNumber.delegate = self
        
        title = "Cellphone Number"
    }
    
    @IBAction func next(_ sender: Any) {
        parentController.currentUser["cellNumber"] = txtNumber.text?.trim()
        PFUser.current()?["cellNumber"] = txtNumber.text?.trim()
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
            <~~ ValidatorNumeric()
            <~~ ValidatorStrLen() {
                $0.minLength = 6
                $0.maxLength = 15
        }
        
        return validation.validate(txtNumber.text?.trim(), context: nil)
    }
}

extension Reg_CellNumber_VC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if validInput() { btnNext.sendActions(for: .touchUpInside) }
        else {
            let toastCenter = CGPoint(x: txtNumber.center.x, y: txtNumber.center.y-70)
            view.makeToast("Required\nOnly numbers\nMin 6\nMax 15", duration: 5, position: NSValue(cgPoint: toastCenter))
        }
        return false
    }
}

