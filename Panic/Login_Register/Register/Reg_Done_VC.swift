//
//  Reg_Done_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/07/21.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import ChameleonFramework
import Parse
import SCLAlertView

class Reg_Done_VC: Reg_IndividualScreen_VC {

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        btnNext.alpha = 1
    }
    
    @IBAction func next(_ sender: Any) {
        parentController.currentUser["cellNumber"] = "0729299399"
        PFUser.current()?["cellNumber"] = "09238409834"
        
        parentController.currentUser["numberOfGroups"] = 10
        PFUser.current()?["numberOfGroups"] = 10
        
        parentController.currentUser["country"] = ""
        PFUser.current()?["country"] = ""
        
        parentController.currentUser["groups"] = []
        PFUser.current()?["groups"] = []
        
        parentController.currentUser["username"] = parentController.currentUser["email"]
        PFUser.current()?["username"] = PFUser.current()?["email"]
        
        if checkForCompletion() {
            if PFUser.current() == nil {
                signUp()
            } else {
                signUpSocial()
            }
        }
    }
    
    func signUpSocial() {
        spinner.startAnimating()
        PFUser.current()?.saveInBackground(block: {
            success, error in
            self.spinner.stopAnimating()
            
            if success {
                self.finish()
            } else if error != nil {
                self.handleSignupError(error: error!)
                self.spinner.stopAnimating()
            }
        })
    }
    
    func signUp() {
        spinner.startAnimating()
        parentController.currentUser.signUpInBackground {
            succeeded, error in
            if error != nil {
                self.handleSignupError(error: error!)
                self.spinner.stopAnimating()
            } else {
                self.finish()
            }
        }
    }
    
    func handleSignupError(error: Error) {
        let unsuccessful = NSLocalizedString("unsuccessful", value: "Oh no...", comment: "")
        
        switch (error as NSError).code {
            case 125: SCLAlertView().showError("Email address is invalid", subTitle: "Please use a different email address")
            case 202: SCLAlertView().showError("Well this is awkward...", subTitle: "Username somehow already taken... Please contact support about this. It should not happen and is not your fault.")
            case 203: SCLAlertView().showError("Email address already taken", subTitle: "Please use a different email address")
            default: SCLAlertView().showError(unsuccessful, subTitle: error.localizedDescription)
        }
        
        print(error)
    }
    
    func checkForCompletion() -> Bool {
        if parentController.currentUser["name"] == nil {
            parentController.performManualScrolling(toIndex: parentController.getIndexOfViewControllerType(VCType: Reg_Name_VC.classForCoder()))
            return false
        }
        
        if parentController.currentUser["email"] == nil {
            parentController.performManualScrolling(toIndex: parentController.getIndexOfViewControllerType(VCType: Reg_Email_VC.classForCoder()))
            return false
        }
        
        if parentController.currentUser["password"] == nil {
            parentController.performManualScrolling(toIndex: parentController.getIndexOfViewControllerType(VCType: Reg_Password_VC.classForCoder()))
            return false
        }
        
        if parentController.currentUser["cellNumber"] == nil {
            parentController.performManualScrolling(toIndex: parentController.getIndexOfViewControllerType(VCType: Reg_Email_VC.classForCoder()))
            return false
        }
        
//        if parentController.currentUser["betaID"] == nil {
//            parentController.performManualScrolling(toIndex: parentController.getIndexOfViewControllerType(VCType: Reg_Email_VC.classForCoder()))
//            return false
//        }
        
        return true
    }
    
    func finish() {
        tutorial.reset()
        self.spinner.stopAnimating()
        self.dismiss(animated: true)
    }
}
