//
//  RegisterViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/11/30.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import Social

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var textBoxContainer: UIView!
    
    @IBOutlet weak var lblWelcome: UILabel!
    @IBOutlet weak var btnSubmit: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var bottomLayout : NSLayoutConstraint!
    
    var containerView : RegisterTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		PFAnalytics.trackEvent(inBackground: "Showed_Register", dimensions: nil, block: nil)
        containerView = self.childViewControllers[0] as! RegisterTableViewController
	}
    
    @IBAction func submit(_ sender: AnyObject) {
        if auth.validation(containerView: containerView) == true {
            spinner.startAnimating()
            
        }
    }
    
//    func validation() -> Bool {
//		let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
//		let nameRegEx = "[A-Za-z.-[:blank:]]+"
//		let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
//		let nameTest = NSPredicate(format: "SELF MATCHES %@", nameRegEx)
//		
//        var message = ""
//		
//		// Name
//        if containerView.txtName.text!.trim().characters.count < 5 { message = NSLocalizedString("error_full_name", value: "Please fill in your full name\n", comment: "") }
//		var result = nameTest.evaluate(with: containerView.txtName.text!.trim())
//		if result == false { message = message + NSLocalizedString("error_name_only_letters", value: "Your name can only contain letters\n", comment: "")  }
//        if containerView.txtUsername.text!.trim().characters.count < 5 { message = message + NSLocalizedString("error_username_5_chars", value: "Username must be at least 5 characters\n", comment: "") }
//		
//		// Cell number
//        if containerView.txtCellNumber.text!.trim().characters.count < 10 { message = message + NSLocalizedString("error_cell", value: "Please fill in your cell number\n", comment: "")  }
//		
//		// Email
//		result = emailTest.evaluate(with: containerView.txtEmail.text!.trim())
//		if result == false {
//			message = message + NSLocalizedString("error_email", value: "Please enter a valid email address\n", comment: "")
//		}
//		
//		// Password
//        if containerView.txtPassword.text!.trim().isEmpty { message = message + NSLocalizedString("error_password", value: "Please fill in a password\n", comment: "") }
//		
//		// Password Confirm
//        if containerView.txtConfirmPassword.text!.trim().isEmpty { message = message + NSLocalizedString("error_password_confirm", value: "Please retype your password\n" , comment: "")}
//        if !containerView.txtPassword.text!.trim().isEmpty && !containerView.txtConfirmPassword.text!.isEmpty {
//            if containerView.txtPassword.text!.trim() != containerView.txtConfirmPassword.text!.trim() {
//                message = message + NSLocalizedString("error_pass_dont_match", value: "Passwords do not match\n", comment: "")
//            } else if containerView.txtPassword.text!.trim().characters.count < 6 {
//                message = message + NSLocalizedString("error_pass_6_chars", value: "Password must be 6 or more characters\n", comment: "")
//            }
//        }
//		
//		// Country
//        if containerView.countrySelected == false { message = message + NSLocalizedString("error_country", value: "Please select a country\n", comment: "") }
//        
//        if message.characters.count > 0 {
//            global.showAlert("", message: message)
//            return false
//        }
//        return true
//    }
    
    func startLoading() {
        spinner.startAnimating()
        containerView.tblDetails.isUserInteractionEnabled = false
        btnSubmit.isEnabled = false
        btnCancel.isEnabled = false
    }
    
    func stopLoading() {
        spinner.stopAnimating()
        containerView.tblDetails.isUserInteractionEnabled = true
        btnSubmit.isEnabled = true
        btnCancel.isEnabled = true
    }
    
    @IBAction func back(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
