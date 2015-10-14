//
//  ViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/11/30.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import CoreLocation

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var viewTextFields: UIView!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var btnRegister: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
	@IBOutlet weak var viewDarken: UIView!
    
    var selectedTextField : UITextField!
    @IBOutlet weak var bottomLayout : NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		PFAnalytics.trackEventInBackground("Showed_Login", dimensions: nil, block: nil)
		
        txtUsername.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        txtPassword.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        txtUsername.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("username", value: "Username", comment: ""),
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        txtPassword.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("password", value: "Password", comment: ""),
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
    }
    
    override func viewDidAppear(animated: Bool) {
		viewDarken.backgroundColor = UIColor.clearColor()
		let layer = drawing.gradient(viewDarken, colours: [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor])
		viewDarken.layer.insertSublayer(layer, atIndex: 0)
		
		println("DEVICE TOKEN: \(PFInstallation.currentInstallation().deviceToken)")
        var user = PFUser.currentUser()
        if user != nil {
            startLoading()
            manageLogin()
            stopLoading()
        } else {
			println(PFInstallation.currentInstallation().objectId)
			if PFInstallation.currentInstallation().objectId == nil {
				println("Creating new installation and adding groups... \(PFInstallation.currentInstallation())")
				PFInstallation.currentInstallation().saveInBackgroundWithBlock({
					(result: Bool, error: NSError?) -> Void in
					if result == true {
						PFInstallation.currentInstallation().setObject(["", "not_logged_in"], forKey: "channels")
						PFInstallation.currentInstallation().badge = 0
						PFInstallation.currentInstallation().saveInBackgroundWithBlock(nil)
						PFInstallation.currentInstallation().saveEventually(nil)
						println("Created new installation and added groups... \(PFInstallation.currentInstallation())")
					}
				})
			}
            spinner.stopAnimating()
        }
    }
    
    func foundCountry() {
        println("foundCountry delegate run")
//        manager.stopUpdatingLocation()
    }
    
    @IBAction func login(sender: AnyObject) {
//        spinner.startAnimating()
        startLoading()
        var user = PFUser()
        PFUser.logInWithUsernameInBackground(txtUsername.text.lowercaseString.trim(), password: txtPassword.text.trim(), block: {
			(user: PFUser?, error: NSError?) -> Void in
            if (error != nil) {
                println(error)
				let unsuccessful = NSLocalizedString("unsuccessful", value: "Unsuccessful", comment: "")
                switch error!.code {
                case 100:
                    global.showAlert(unsuccessful, message: NSLocalizedString("error_network_connection", value: "The network connection was lost", comment: ""))
                    self.btnLogin.enabled = true
                    self.btnRegister.enabled = true
                    break
                case 101:
                    global.showAlert(unsuccessful, message: NSLocalizedString("error_invalid_login", value: "Invalid login credentials", comment: ""))
                    self.btnLogin.enabled = true
                    self.btnRegister.enabled = true
                    break
                default:
                    if error?.localizedDescription != nil {
                        global.showAlert(unsuccessful, message: error!.localizedDescription)
                    } else {
                        global.showAlert(unsuccessful, message: "Dunno, brah")
                    }
                    self.btnLogin.enabled = true
                    self.btnRegister.enabled = true
                    break
                }
            } else {
                self.manageLogin()
            }
            self.stopLoading()
        })
    }
    
    @IBAction func register(sender: AnyObject) {
        var storyboard = UIStoryboard(name: "Main", bundle: nil)
        var vc: RegisterViewController = storyboard.instantiateViewControllerWithIdentifier("registerViewController") as! RegisterViewController
        vc.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.presentViewController(vc, animated: true, completion: nil)
    }
	
	@IBAction func resetPassword(sender: AnyObject) {
		var alert = UIAlertController(title: NSLocalizedString("reset_password_title", value: "Reset Password", comment: ""), message: NSLocalizedString("reset_password_text", value: "Enter the email address associated with the account. You will receive an email with reset instructions", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
		alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
			textField.placeholder = NSLocalizedString("email", value: "Email:", comment: "")
			textField.keyboardType = UIKeyboardType.EmailAddress
		})
		alert.addAction(UIAlertAction(title: NSLocalizedString("reset", value: "Reset", comment: ""), style: UIAlertActionStyle.Destructive, handler: {
			_ in
			PFUser.requestPasswordResetForEmailInBackground((alert.textFields?.first as! UITextField).text, block: {
				(result: Bool, error: NSError?) -> Void in
				if result == true {
					global.showAlert(NSLocalizedString("email_sent_title", value: "Email sent", comment: ""), message: NSLocalizedString("email_sent_text", value: "An email has been sent to the email address you supplied with password reset instructions", comment: ""))
				} else if error!.code == 125 {
					global.showAlert("Oops", message: NSLocalizedString("email_address_not_found", value: "Email address not found", comment: ""))
				}
			})
		}))
		alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: UIAlertActionStyle.Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
    func manageLogin() {
        if global.getUserInformation() == true {
            var storyboard = UIStoryboard(name: "Main", bundle: nil)
            var vc: TabBarViewController = storyboard.instantiateViewControllerWithIdentifier("mainViewController") as! TabBarViewController
            vc.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            self.presentViewController(vc, animated: true, completion: nil)
		}
    }
    
    func startLoading () {
        spinner.startAnimating()
        println("Started spinner")
        txtUsername.enabled = false
        txtPassword.enabled = false
        self.btnLogin.enabled = false
        self.btnRegister.enabled = false
    }
    
    func stopLoading () {
        self.btnLogin.enabled = true
        self.btnRegister.enabled = true
        self.txtUsername.enabled = true
        self.txtPassword.enabled = true
        self.spinner.stopAnimating()
    }

    
    @IBAction func hideKeyboard(sender: AnyObject) {
        if selectedTextField != nil {
            selectedTextField.resignFirstResponder()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
		if textField == txtPassword {
			login(btnLogin)
		} else {
			txtPassword.becomeFirstResponder()
		}
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        animateTextField(textField, up: true)
        selectedTextField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        animateTextField(textField, up: false)
    }
    
    func animateTextField(textField : UITextField, up : Bool)
    {
        if (up == true) {
            self.bottomLayout.constant = 230
        } else {
            self.bottomLayout.constant = 160
        }
        UIView.animateWithDuration(0.3, animations: {
            self.viewTextFields.layoutIfNeeded()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

