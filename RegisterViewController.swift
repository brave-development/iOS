//
//  RegisterViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/11/30.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

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
                    if error!.code == 202 {
                        global.showAlert("Unsuccessful", message: "Username \(self.containerView.txtUsername.text) already taken")
                        self.containerView.becomeFirstResponder()
                    } else {
                        global.showAlert("Unsuccessful", message: error!.description)
                    }
                    println(error)
					self.spinner.stopAnimating()
                } else {
					tutorial.reset()
                    global.showAlert("Important", message: "Welcome " + self.containerView.txtName.text + ". You have been signed in and you will remain signed in, even if you close the app. To sign out, you can use the logout button in the main menu.\n\nIt is important to add groups (using the main menu) as soon as possible so people are notified if you use the Panic button.")
					self.spinner.stopAnimating()
                    self.dismissViewControllerAnimated(true, completion: nil)
                    
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
        if count(containerView.txtName.text.trim()) < 5 { message = "Please fill in your full name\n" }
		var result = nameTest.evaluateWithObject(containerView.txtName.text.trim())
		if result == false { message = message + "Your name can only contain letters\n" }
        if count(containerView.txtUsername.text.trim()) < 5 { message = message + "Username must be at least 5 characters\n" }
		
		// Cell number
        if count(containerView.txtCellNumber.text.trim()) < 10 { message = message + "Please fill in your cell number\n" }
		
		// Email
		result = emailTest.evaluateWithObject(containerView.txtEmail.text.trim())
		if result == false {
			message = message + "Please enter a valid email address\n"
		}
		
		// Password
        if containerView.txtPassword.text.trim().isEmpty { message = message + "Please fill in a password\n" }
		
		// Password Confirm
        if containerView.txtConfirmPassword.text.trim().isEmpty { message = message + "Please retype your password\n" }
        if !containerView.txtPassword.text.trim().isEmpty && !containerView.txtConfirmPassword.text.isEmpty {
            if containerView.txtPassword.text.trim() != containerView.txtConfirmPassword.text.trim() {
                message = message + "Passwords do not match\n"
            } else if count(containerView.txtPassword.text.trim()) < 6 {
                message = message + "Password must be 6 or more characters\n"
            }
        }
		
		// Country
        if containerView.countrySelected == false { message = message + "Please select a country\n" }
        
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
