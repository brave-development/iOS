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
		
		PFAnalytics.trackEventInBackground("Showed_Register", dimensions: nil, block: nil)
        containerView = self.childViewControllers[0] as! RegisterTableViewController
	}
    
    @IBAction func submit(sender: AnyObject) {
        if validation() == true {
            spinner.startAnimating()
            var user : PFUser = PFUser()
            user.username = containerView.txtUsername.text.lowercaseString
            user.password = containerView.txtPassword.text
            user["cellNumber"] = containerView.txtCellNumber.text
            user["name"] = containerView.txtName.text
            user["country"] = containerView.btnCountry.titleLabel?.text
			user["email"] = containerView.txtEmail.text
			user["numberOfGroups"] = 1
            user.signUpInBackgroundWithBlock {
				(succeeded: Bool, error: NSError?) -> Void in
                if (error != nil) {
					let unsuccessful = NSLocalizedString("unsuccessful", value: "Unsuccessful", comment: "")
                    if error!.code == 202 {
                        global.showAlert(unsuccessful, message: String(format: NSLocalizedString("username_already_taken", value: "Username %@ already taken", comment: ""), arguments: [self.containerView.txtUsername.text]))
							self.containerView.becomeFirstResponder()
					} else if error!.code == 125 {
						global.showAlert(unsuccessful, message: error!.localizedDescription)
					} else {
                        global.showAlert(unsuccessful, message: error!.localizedDescription)
                    }
                    println(error)
					self.spinner.stopAnimating()
                } else {
					tutorial.reset()
					self.spinner.stopAnimating()
					self.dismissViewControllerAnimated(true, completion: {
						global.shareGroup(NSLocalizedString("share_panic_whatsapp_text", value: "I just downloaded Panic! Help me make our community a safer place.\nGet the app here: http://goo.gl/M25QIw", comment: ""), viewController: nil)
					})
					
                }
            }
        }
    }
    
    func validation() -> Bool {
		let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
		let nameRegEx = "[A-Za-z.-[:blank:]]+"
		var emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
		var nameTest = NSPredicate(format: "SELF MATCHES %@", nameRegEx)
		
        var message = ""
		
		// Name
        if count(containerView.txtName.text.trim()) < 5 { message = NSLocalizedString("error_full_name", value: "Please fill in your full name\n", comment: "") }
		var result = nameTest.evaluateWithObject(containerView.txtName.text.trim())
		if result == false { message = message + NSLocalizedString("error_name_only_letters", value: "Your name can only contain letters\n", comment: "")  }
        if count(containerView.txtUsername.text.trim()) < 5 { message = message + NSLocalizedString("error_username_5_chars", value: "Username must be at least 5 characters\n", comment: "") }
		
		// Cell number
        if count(containerView.txtCellNumber.text.trim()) < 10 { message = message + NSLocalizedString("error_cell", value: "Please fill in your cell number\n", comment: "")  }
		
		// Email
		result = emailTest.evaluateWithObject(containerView.txtEmail.text.trim())
		if result == false {
			message = message + NSLocalizedString("error_email", value: "Please enter a valid email address\n", comment: "")
		}
		
		// Password
        if containerView.txtPassword.text.trim().isEmpty { message = message + NSLocalizedString("error_password", value: "Please fill in a password\n", comment: "") }
		
		// Password Confirm
        if containerView.txtConfirmPassword.text.trim().isEmpty { message = message + NSLocalizedString("error_password_confirm", value: "Please retype your password\n" , comment: "")}
        if !containerView.txtPassword.text.trim().isEmpty && !containerView.txtConfirmPassword.text.isEmpty {
            if containerView.txtPassword.text.trim() != containerView.txtConfirmPassword.text.trim() {
                message = message + NSLocalizedString("error_pass_dont_match", value: "Passwords do not match\n", comment: "")
            } else if count(containerView.txtPassword.text.trim()) < 6 {
                message = message + NSLocalizedString("error_pass_6_chars", value: "Password must be 6 or more characters\n", comment: "")
            }
        }
		
		// Country
        if containerView.countrySelected == false { message = message + NSLocalizedString("error_country", value: "Please select a country\n", comment: "") }
        
        if count(message) > 0 {
            global.showAlert("", message: message)
            return false
        }
        return true
    }
    
    func startLoading() {
        spinner.startAnimating()
        containerView.tblDetails.userInteractionEnabled = false
        btnSubmit.enabled = false
        btnCancel.enabled = false
    }
    
    func stopLoading() {
        spinner.stopAnimating()
        containerView.tblDetails.userInteractionEnabled = true
        btnSubmit.enabled = true
        btnCancel.enabled = true
    }
    
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
