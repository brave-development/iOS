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
import SZTextView

class Reg_Done_VC: Reg_IndividualScreen_VC {

//    @IBOutlet weak var imgBackground: UIImageView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var layoutBackgroundLeft: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Final"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        btnNext.showWithAnimation(animation: "zoomIn")
    }
    
    @IBAction func next(_ sender: Any) {
        
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
    
    @IBAction func referalCode(_ sender: Any) {
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false
        )
        
        // Initialize SCLAlertView using custom Appearance
        let alert = SCLAlertView(appearance: appearance)
        
        // Creat the subview
        let textView = SZTextView(frame: CGRect(x: 0, y: 0, width: 210, height: 50))
        textView.placeholder = "Tap here to type..."
        
        // Add the subview to the alert's UI property
        alert.customSubview = textView
        
        alert.addButton("Submit") {
            print("Submitted details...")
            if textView.text!.trim().characters.count > 0 {
                self.parentController.currentUser["betaID"] = textView.text!.trim()
                PFUser.current()?["betaID"] = textView.text!.trim()
            }
        }
        
        // Add Button with Duration Status and custom Colors
        alert.addButton("Wait, nevermind", backgroundColor: UIColor.flatRed, textColor: UIColor.white) { }
        
        alert.showInfo("referral Code", subTitle: "")
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
            case 202, 203: SCLAlertView().showError("Well this is awkward...", subTitle: "Email address somehow already taken... Please contact support about this. It should not happen and is not your fault.\n(Unless you've already created an account...)")
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
            parentController.performManualScrolling(toIndex: parentController.getIndexOfViewControllerType(VCType: Reg_CellNumber_VC.classForCoder()))
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
