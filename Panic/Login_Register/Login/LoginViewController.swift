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
import FacebookCore
import FacebookLogin
import SwiftyJSON

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
		
		PFAnalytics.trackEvent(inBackground: "Showed_Login", dimensions: nil, block: nil)
		
        txtUsername.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        txtPassword.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        txtUsername.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("username", value: "Username", comment: ""),
            attributes:[NSForegroundColorAttributeName: UIColor.white])
        txtPassword.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("password", value: "Password", comment: ""),
            attributes:[NSForegroundColorAttributeName: UIColor.white])
        
        // Adding Facebook login button
        let loginButton = LoginButton(readPermissions: [ .publicProfile, .email ])
        loginButton.center = view.center
        loginButton.delegate = self
        
        view.addSubview(loginButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
		viewDarken.backgroundColor = UIColor.clear
		let layer = drawing.gradient(viewDarken, colours: [UIColor.clear.cgColor, UIColor.black.cgColor])
		viewDarken.layer.insertSublayer(layer, at: 0)
		
//		print("DEVICE TOKEN: \(PFInstallation.current()?.deviceToken)")
        let user = PFUser.current()
        if user != nil {
            startLoading()
            manageLogin()
            stopLoading()
        } else {
			if PFInstallation.current()?.objectId == nil {
				PFInstallation.current()?.saveInBackground(block: {
					(result, error) in
					if result == true {
						PFInstallation.current()?.setObject(["", "not_logged_in"], forKey: "channels")
						PFInstallation.current()?.badge = 0
						PFInstallation.current()?.saveInBackground(block: nil)
						PFInstallation.current()?.saveEventually(nil)
						print("Created new installation and added groups... \(PFInstallation.current()!)")
					}
				})
			}
            spinner.stopAnimating()
        }
    }
    
    func foundCountry() {
        print("foundCountry delegate run")
//        manager.stopUpdatingLocation()
    }
    
    @IBAction func login(_ sender: AnyObject) {
        startLoading()
        
    }
    
    @IBAction func register(_ sender: AnyObject) {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc: RegisterViewController = storyboard.instantiateViewController(withIdentifier: "registerViewController") as! RegisterViewController
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        self.present(vc, animated: true, completion: nil)
    }
	
	@IBAction func resetPassword(_ sender: AnyObject) {
		let alert = UIAlertController(title: NSLocalizedString("reset_password_title", value: "Reset Password", comment: ""), message: NSLocalizedString("reset_password_text", value: "Enter the email address associated with the account. You will receive an email with reset instructions", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
		alert.addTextField(configurationHandler: {(textField: UITextField!) in
			textField.placeholder = NSLocalizedString("email", value: "Email:", comment: "")
			textField.keyboardType = UIKeyboardType.emailAddress
		})
		alert.addAction(UIAlertAction(title: NSLocalizedString("reset", value: "Reset", comment: ""), style: UIAlertActionStyle.destructive, handler: {
			_ in
			PFUser.requestPasswordResetForEmail(inBackground: (alert.textFields!.first! as UITextField).text!, block: {
				(result, error) in
				if error == nil {
					global.showAlert(NSLocalizedString("email_sent_title", value: "Email sent", comment: ""), message: NSLocalizedString("email_sent_text", value: "An email has been sent to the email address you supplied with password reset instructions", comment: ""))
                } else {
                    if (error! as NSError).code == 125 { global.showAlert("Oops", message: NSLocalizedString("email_address_not_found", value: "Email address not found", comment: "")) }
				}
			})
		}))
		alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: UIAlertActionStyle.default, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}
	
    func manageLogin() {
        if global.getUserInformation() == true {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc: MainViewController = storyboard.instantiateViewController(withIdentifier: "mainViewController") as! MainViewController
            vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            self.present(vc, animated: true, completion: nil)
		}
    }
    
    func startLoading () {
        spinner.startAnimating()
        print("Started spinner")
        txtUsername.isEnabled = false
        txtPassword.isEnabled = false
        self.btnLogin.isEnabled = false
        self.btnRegister.isEnabled = false
    }
    
    func stopLoading () {
        self.btnLogin.isEnabled = true
        self.btnRegister.isEnabled = true
        self.txtUsername.isEnabled = true
        self.txtPassword.isEnabled = true
        self.spinner.stopAnimating()
    }

    
    @IBAction func hideKeyboard(_ sender: AnyObject) {
        if selectedTextField != nil {
            selectedTextField.resignFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
		if textField == txtPassword {
			login(btnLogin)
		} else {
			txtPassword.becomeFirstResponder()
		}
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        animateTextField(textField, up: true)
        selectedTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        animateTextField(textField, up: false)
    }
    
    func animateTextField(_ textField : UITextField, up : Bool)
    {
        if up == true {
            self.bottomLayout.constant = 270
        } else {
            self.bottomLayout.constant = 160
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.viewTextFields.layoutIfNeeded()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension LoginViewController: LoginButtonDelegate {
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        switch result {
        case .failed(let error):
            print(error)
        case .cancelled:
            print("Cancelled")
        case .success(let _, let _, let _):
            print("Logged In")
            facebookLogin()
        }
    }
    
    func facebookLogin() {
        if let accessToken = AccessToken.current {
            let params = ["fields":"name,email"]
            let graphRequest = GraphRequest(graphPath: "me", parameters: params)
            graphRequest.start { (urlResponse, requestResult) in
                switch requestResult {
                case .failed(let error):
                    print(error)
                case .success(let graphResponse):
                    if let responseDictionary = graphResponse.dictionaryValue {
                        UserDefaults.standard.set(responseDictionary, forKey: "userInfo")
                        
                        let json = JSON(responseDictionary)
                    }
                    LoginManager.init().logOut()
                }
            }
        } else {
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {  }
}

