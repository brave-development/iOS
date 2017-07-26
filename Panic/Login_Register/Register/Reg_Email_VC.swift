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

class Reg_Email_VC: Reg_IndividualScreen_VC {

//    @IBOutlet weak var imgIcon: SpringImageView!
    @IBOutlet weak var txtEmail: UITextField!
//    @IBOutlet weak var btnNext: Sub_SpringButton!
    
    @IBOutlet weak var layoutTextCenter: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = UIColor.clear
//        btnNext.alpha = 0
//        
//        imgIcon.layer.shadowRadius = 4
//        imgIcon.layer.shadowOpacity = 0.4
//        imgIcon.layer.shadowOffset = CGSize(width: 0, height: 0)
//        
//        let tapDismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
//        view.addGestureRecognizer(tapDismissKeyboard)
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        Timer.scheduledTimer(withTimeInterval: 7, repeats: true, block: {_ in
//            if !self.txtEmail.isEditing {
//                self.imgIcon.animation = "swing"
//                self.imgIcon.duration = 1
//                self.imgIcon.animate()
//            }
//        })
//    }
    
    @IBAction func next(_ sender: Any) {
//        if let parent = self.parent as? RegistrationController_VC {
        parentController.currentUser["email"] = txtEmail.text?.trim().lowercased()
        nextPage()
//            dismissKeyboard()
//            parent.nextPage()
//        }
    }

    @IBAction func back(_ sender: Any) {
        previousPage()
//        if let parent = self.parent as? RegistrationController_VC {
//            parent.previousPage()
//        }
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
    
//    @IBAction func keyboardShowen(_ sender: Any) {
//        imgIcon.alpha = 0
//        
//        layoutCenter.constant = -UIScreen.main.bounds.height/2 + 150
//        animateViews()
//    }
//    
//    @IBAction func keyboardHidden(_ sender: Any) {
//        imgIcon.alpha = 1
//        
//        layoutCenter.constant = 50
//        animateViews()
//    }
    
//    func animateViews() {
//        UIView.animate(withDuration: 0.5, animations: {_ in
//            for view in self.view.subviews {
//                view.layoutIfNeeded()
//            }
//        })
//    }
//    
//    func dismissKeyboard() {
//        txtEmail.resignFirstResponder()
//    }
}


