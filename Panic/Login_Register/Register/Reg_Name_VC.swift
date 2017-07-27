//
//  Reg_Name_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/07/27.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import SwiftValidate

class Reg_Name_VC: Reg_IndividualScreen_VC {
    
    @IBOutlet weak var txtName: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func next(_ sender: Any) {
        parentController.currentUser["name"] = txtName.text?.trim().lowercased()
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
                $0.pattern = "[A-Za-z.-[:blank:]]+"
        }
        
        if validation.validate(txtName.text?.trim(), context: nil) {
            btnNext.showWithAnimation(animation: "zoomIn")
        } else {
            btnNext.hideWithDuration()
        }
    }
}
