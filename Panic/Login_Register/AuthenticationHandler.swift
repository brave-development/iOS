//
//  AuthenticationHandler.swift
//  Panic
//
//  Created by Byron Coetsee on 2017/06/04.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import SwiftyJSON

let auth = AuthenticationHandler()

class AuthenticationHandler: NSObject {
    
    func registerFromApp(containerView: RegisterTableViewController) {
        let user : PFUser = PFUser()
        user.username = containerView.txtUsername.text?.lowercased()
        user.password = containerView.txtPassword.text
        user["cellNumber"] = containerView.txtCellNumber.text
        user["name"] = containerView.txtName.text
        user["country"] = containerView.btnCountry.titleLabel?.text
        user["email"] = containerView.txtEmail.text
        user["numberOfGroups"] = 1
        registerNewUser(user: user)
    }
    
    func registerFromFacebook(userDetails: JSON) {
        
        let user : PFUser = PFUser()
        user.username = userDetails["email"].stringValue
        user.password = containerView.txtPassword.text
        user["cellNumber"] = containerView.txtCellNumber.text
        user["name"] = containerView.txtName.text
        user["country"] = containerView.btnCountry.titleLabel?.text
        user["email"] = containerView.txtEmail.text
        user["numberOfGroups"] = 1
        registerNewUser(user: user)
    }
    
    private func registerNewUser(user: PFUser) {
        user.signUpInBackground {
            (succeeded, error) in
            if (error != nil) {
                let unsuccessful = NSLocalizedString("unsuccessful", value: "Unsuccessful", comment: "")
                if (error! as NSError).code == 202 {
                    global.showAlert(unsuccessful, message: String(format: NSLocalizedString("username_already_taken", value: "Username %@ already taken", comment: ""), arguments: [self.containerView.txtUsername.text!]))
                    self.containerView.becomeFirstResponder()
                } else if (error! as NSError).code == 125 {
                    global.showAlert(unsuccessful, message: error!.localizedDescription)
                } else {
                    global.showAlert(unsuccessful, message: error!.localizedDescription)
                }
                print(error!)
                self.spinner.stopAnimating()
            } else {
                tutorial.reset()
                self.spinner.stopAnimating()
                self.dismiss(animated: true, completion: {
                    global.shareGroup(NSLocalizedString("share_panic_whatsapp_text", value: "I just downloaded Panic! Help me make our community a safer place.\nGet the app here: http://goo.gl/M25QIw", comment: ""), viewController: nil)
                })
                
            }
        }
    }
    
    private func login(username: String, password: String) {
        PFUser.logInWithUsername(inBackground: username, password: password, block: {
            (user, error) in
            print(user)
            if (error != nil) {
                print(error!)
                let unsuccessful = NSLocalizedString("unsuccessful", value: "Unsuccessful", comment: "")
                switch (error! as NSError).code {
                case 100:
                    global.showAlert(unsuccessful, message: NSLocalizedString("error_network_connection", value: "The network connection was lost", comment: ""))
                    self.btnLogin.isEnabled = true
                    self.btnRegister.isEnabled = true
                    break
                case 101:
                    global.showAlert(unsuccessful, message: NSLocalizedString("error_invalid_login", value: "Invalid login credentials", comment: ""))
                    self.btnLogin.isEnabled = true
                    self.btnRegister.isEnabled = true
                    break
                default:
                    if error?.localizedDescription != nil {
                        global.showAlert(unsuccessful, message: error!.localizedDescription)
                    } else {
                        global.showAlert(unsuccessful, message: "Dunno, brah")
                    }
                    self.btnLogin.isEnabled = true
                    self.btnRegister.isEnabled = true
                    break
                }
            } else {
                self.manageLogin()
            }
//            self.stopLoading()
        })
    }
    
    func validation(containerView: RegisterTableViewController) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let nameRegEx = "[A-Za-z.-[:blank:]]+"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let nameTest = NSPredicate(format: "SELF MATCHES %@", nameRegEx)
        
        var message = ""
        
        // Name
        if containerView.txtName.text!.trim().characters.count < 5 { message = NSLocalizedString("error_full_name", value: "Please fill in your full name\n", comment: "") }
        var result = nameTest.evaluate(with: containerView.txtName.text!.trim())
        if result == false { message = message + NSLocalizedString("error_name_only_letters", value: "Your name can only contain letters\n", comment: "")  }
        if containerView.txtUsername.text!.trim().characters.count < 5 { message = message + NSLocalizedString("error_username_5_chars", value: "Username must be at least 5 characters\n", comment: "") }
        
        // Cell number
        if containerView.txtCellNumber.text!.trim().characters.count < 10 { message = message + NSLocalizedString("error_cell", value: "Please fill in your cell number\n", comment: "")  }
        
        // Email
        result = emailTest.evaluate(with: containerView.txtEmail.text!.trim())
        if result == false {
            message = message + NSLocalizedString("error_email", value: "Please enter a valid email address\n", comment: "")
        }
        
        // Password
        if containerView.txtPassword.text!.trim().isEmpty { message = message + NSLocalizedString("error_password", value: "Please fill in a password\n", comment: "") }
        
        // Password Confirm
        if containerView.txtConfirmPassword.text!.trim().isEmpty { message = message + NSLocalizedString("error_password_confirm", value: "Please retype your password\n" , comment: "")}
        if !containerView.txtPassword.text!.trim().isEmpty && !containerView.txtConfirmPassword.text!.isEmpty {
            if containerView.txtPassword.text!.trim() != containerView.txtConfirmPassword.text!.trim() {
                message = message + NSLocalizedString("error_pass_dont_match", value: "Passwords do not match\n", comment: "")
            } else if containerView.txtPassword.text!.trim().characters.count < 6 {
                message = message + NSLocalizedString("error_pass_6_chars", value: "Password must be 6 or more characters\n", comment: "")
            }
        }
        
        // Country
        if containerView.countrySelected == false { message = message + NSLocalizedString("error_country", value: "Please select a country\n", comment: "") }
        
        if message.characters.count > 0 {
            global.showAlert("", message: message)
            return false
        }
        return true
    }

}
