//
//  Reg_IndividualScreen_VCViewController.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/07/26.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import Spring
import SwiftValidate
import ChameleonFramework

class Reg_IndividualScreen_VC: UIViewController {
    
    @IBOutlet weak var imgIcon: SpringImageView!
    @IBOutlet weak var btnNext: Sub_SpringButton!
    @IBOutlet weak var layoutCenterText: NSLayoutConstraint!
    
    var parentController: RegistrationController_VC {
        return self.parent as! RegistrationController_VC
    }
    
    var keyboardVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
//        parentController = self.parent as! RegistrationController_VC
        view.backgroundColor = UIColor.clear
        btnNext.alpha = 0
        
        imgIcon.layer.shadowRadius = 4
        imgIcon.layer.shadowOpacity = 0.4
        imgIcon.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        let tapDismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapDismissKeyboard)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShown), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHidden), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        Timer.scheduledTimer(withTimeInterval: 7, repeats: true, block: {_ in
            if !self.keyboardVisible {
                self.imgIcon.animation = "swing"
                self.imgIcon.duration = 1
                self.imgIcon.animate()
            }
        })
    }
    
    func nextPage() {
        dismissKeyboard()
        parentController.nextPage()
    }
    
    func previousPage() {
        parentController.previousPage()
    }
    
    
    // Keyboard
    func keyboardShown() {
        imgIcon.alpha = 0
        keyboardVisible = true
        
        layoutCenterText.constant = -UIScreen.main.bounds.height/2 + 150
        animateViews()
    }
    
    func keyboardHidden() {
        imgIcon.alpha = 1
        keyboardVisible = false
        
        layoutCenterText.constant = 50
        animateViews()
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    
    // View Management
    func animateViews() {
        UIView.animate(withDuration: 0.5, animations: {_ in
            for view in self.view.subviews {
                view.layoutIfNeeded()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
