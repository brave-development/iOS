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
    
    @IBOutlet weak var lblCenterText: UILabel?
    @IBOutlet weak var layoutCenterText: NSLayoutConstraint?
    
    var parentController: RegistrationController_VC {
        return self.parent as! RegistrationController_VC
    }
    
    var keyboardVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        btnNext.alpha = 0
        
        addShadow(imageView: imgIcon)
        
        for txtField in view.subviews {
            if txtField is UITextField {
                let field = txtField as! UITextField
                
                if let placeholder = field.placeholder {
                    field.attributedPlaceholder = NSAttributedString(string: placeholder, attributes:[NSForegroundColorAttributeName: UIColor.flatWhite.withAlphaComponent(0.5)])
                }
            }
        }
        
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
        
//        Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: {_ in
//            self.keyboardShown()
//        })
    }
    
    func addShadow(imageView: SpringImageView) {
        imageView.layer.shadowRadius = 4
        imageView.layer.shadowOpacity = 0.4
        imageView.layer.shadowOffset = CGSize(width: 0, height: 0)
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
        if keyboardVisible == false {
            self.keyboardVisible = true
            DispatchQueue.main.async(execute: {_ in
                
                self.imgIcon.animation = "zoomOut"
                self.imgIcon.animate()
                
                self.layoutCenterText?.constant = -UIScreen.main.bounds.height/2 + 150
                self.animateViews()
            })
        }
    }
    
    func keyboardHidden() {
        if keyboardVisible == true {
            self.keyboardVisible = false
            DispatchQueue.main.async {
                
                self.imgIcon.animation = "zoomIn"
                self.imgIcon.animate()
                
                self.layoutCenterText?.constant = 50
                self.animateViews()
            }
        }
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    
    // View Management
    func animateViews() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7, animations: {_ in
                self.view.layoutIfNeeded()
            })
        }
    }

    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}
