//
//  SettingsTableViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/13.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import MessageUI
import CoreLocation

class SettingsTableViewController: UITableViewController, UITextFieldDelegate, countryDelegate, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtCell: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtPasswordConfirm: UITextField!
    @IBOutlet weak var viewPasswordConfirm: UIView!
    @IBOutlet weak var switchPanicConfirmation: UISwitch!
	@IBOutlet weak var switchBackgroundUpdate: UISwitch!
    @IBOutlet weak var btnCountry: UIButton!
    
    var tabbarViewController : TabBarViewController!
    var changed = false
    var currentlySelectedTextFieldValue = ""
    var newPassword : String?
	var mail: MFMailComposeViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        
        let user = PFUser.currentUser()!
        
        if user["country"] != nil {
            btnCountry.setTitle((user["country"] as! String), forState: UIControlState.Normal)
        }
        txtName.text = user["name"] as! String
        txtCell.text = user["cellNumber"] as! String
        if user["email"] != nil {
            txtEmail.text = user["email"] as! String
        }
        btnCountry.setTitle((user["country"] as! String), forState: UIControlState.Normal)
        txtPassword.text = ""
        txtPassword.text = ""
        txtPasswordConfirm.enabled = false
        
        if global.panicConfirmation == true {
            switchPanicConfirmation.on = true
        }
		if global.backgroundPanic == true {
			switchBackgroundUpdate.on = true
		}
    }
    
	override func viewDidAppear(animated: Bool) {
		if PFUser.currentUser()!["country"] != nil {
			if btnCountry.titleLabel?.text != (PFUser.currentUser()!["country"] as! String) {
				changed = true
			}
		}
	}
	
    func didSelectCountry(country: String) {
        println("Got selected country")
        btnCountry.setTitle(country, forState: UIControlState.Normal)
        if country != PFUser.currentUser()!["country"] as! String {
            changed = true
        }       
    }
    
    @IBAction func showCountriesViewController (sender: AnyObject) {
        var storyboard = UIStoryboard(name: "Main", bundle: nil)
        var vc: CountriesViewController = storyboard.instantiateViewControllerWithIdentifier("countriesViewController") as! CountriesViewController
        vc.delegate = self
        vc.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.presentViewController(vc, animated: true, completion: nil)
    }

    @IBAction func panicConfirmation(sender: AnyObject) {
        if switchPanicConfirmation.on == true {
            global.setPanicNotification(true)
        } else {
            global.setPanicNotification(false)
        }
    }
	
	@IBAction func backgroundUpdates(sender: AnyObject) {
		if switchBackgroundUpdate.on == true {
			if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways {
				global.setBackgroundUpdate(true)
			} else {
				global.showAlert("Oops", message: "To use this feature, you will need to grant Panic permission to use your location in the background. To do this, go to iPhone Settings > Privacy > Location Services > Panic > 'Always'")
			}
		} else {
			global.setBackgroundUpdate(false)
		}
	}
    
    // Show popup with information about panicConfirmation
    @IBAction func showInfoPanicConfirmation(sender: AnyObject) {
        global.showAlert("Panic Confirmation", message: "Enabling this will remove the 5 second delay before sending notifications, however you will have to manually select 'Yes' each time you activate Panic.")
    }
	
	@IBAction func showInfoBackgroundUpdate(sender: AnyObject) {
//		global.showAlert("Coming Soon!", message: "Enabling background updates will let Panic continue to broadcast your location, even when the app is closed and your iPhone is asleep.\n\nThis is disabled by default as it is very heavy on battery, can use a lot of data if left on for an extended period of time and because of the way iPhone handles background apps, can be unreliable (although rarely).\n\nThis feature will be implemented in the next update.")
		global.showAlert("Background Update", message: "Enabling background updates will let Panic continue to broadcast your location, even when the app is in the background and/or your iPhone is asleep, during activation.\n\nThis is disabled by default as it can be heavy on battery, can use more data then expected if left on for an extended period of time and because of the way iPhone handles background apps, can be unreliable (although rarely)")
	}
	
	@IBAction func reportBug(sender: AnyObject) {
		mail = MFMailComposeViewController()
		if(MFMailComposeViewController.canSendMail()) {
			
			mail.mailComposeDelegate = self
			mail.setSubject("Panic - Bug")
			mail.setToRecipients(["byroncoetsee@gmail.com"])
			mail.setMessageBody("I am having the following issues with the Panic app: ", isHTML: true)
			self.presentViewController(mail, animated: true, completion: nil)
		}
		else {
			global.showAlert("Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.")
		}
	}
	
	@IBAction func reportUser(sender: AnyObject) {
		global.showAlert("Report a user", message: "To report a user, go to Public History, tap on the Panic associated to that user and use the report button there.")
	}
	
	func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
		switch(result.value){
		case MFMailComposeResultSent.value:
			println("Email sent")
			
		default:
			println("Whoops")
		}
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func tutorialReset(sender: AnyObject) {
		tutorial.reset()
		global.showAlert("", message: "Tutorials have been re-enabled. Go back to the main Home screen to view them as you did the first time the app was opened.")
	}
	
	@IBAction func logout(sender: AnyObject) {
		global.showAlert("Note", message: "Logging out disables any Panic notifications. You will not be notified when someone activates their Panic button.\n\nOn the other hand, closing the app with the home button, or even the app switcher, logs you out in a way that you still receive notifications.")
		if global.persistantSettings.objectForKey("groups") != nil {
			global.persistantSettings.removeObjectForKey("groups")
		}
		PFUser.logOut()
		PFInstallation.currentInstallation().setObject(["", "logged_out"], forKey: "channels")
		PFInstallation.currentInstallation().saveInBackgroundWithBlock(nil)
		self.tabbarViewController.back()
	}
	
    @IBAction func deleteAccount(sender: AnyObject) {
        var saveAlert = UIAlertController(title: "Confirmation", message: "Are you sure you want to delete your account?\n\nThis will remove all your details, free up your username, remove all Panic history and you will have to reregister if you want to use this app again.", preferredStyle: UIAlertControllerStyle.Alert)
        saveAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
            var saveAlert = UIAlertController(title: "Final Confirmation", message: "Permenently delete account?", preferredStyle: UIAlertControllerStyle.Alert)
            saveAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
                
                var queryDeleteAccount = PFQuery(className: "Panics")
                queryDeleteAccount.whereKey("user", equalTo: PFUser.currentUser()!)
                queryDeleteAccount.findObjectsInBackgroundWithBlock({
					(objects : [AnyObject]?, error : NSError?) -> Void in
					if objects != nil {
						if objects!.count > 0 {
							PFObject.deleteAllInBackground(objects!, block: {
								(result : Bool, error : NSError?) -> Void in
								if result == true {
									PFUser.currentUser()!.deleteInBackgroundWithBlock(nil)
									if PFUser.currentUser() != nil { PFUser.logOut() }
									self.tabbarViewController.back()
									global.showAlert("", message: "Thanks for using Panic. Goodbye.")
								}
							})
						}
					}
				})
            }))
            saveAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in
            }))
            self.presentViewController(saveAlert, animated: true, completion: nil)
        }))
        saveAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in
        }))
        self.presentViewController(saveAlert, animated: true, completion: nil)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField == txtPassword {
            txtPasswordConfirm.enabled = true
        }
        currentlySelectedTextFieldValue = textField.text
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if validateTextField(textField) == true {
            if textField.text != currentlySelectedTextFieldValue {
                changed = true
            }
        } else {
            textField.text = currentlySelectedTextFieldValue
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField != txtPassword {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func validateTextField(textField : UITextField) -> Bool {
        switch (textField) {
        case txtName:
            if count(txtName.text) < 5 {
                global.showAlert("", message: "Your name cannot be less than 5 characters. Please fill in your full name.")
                return false
            }
            break;
        
        case txtCell:
            if count(txtCell.text) < 10 {
                global.showAlert("Note", message: "Setting your mobile number incorrectly will prevent others from contacting you in an emergency")
            }
            return true
            
        case txtEmail:
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
            var emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            let result = emailTest.evaluateWithObject(txtEmail.text)
            if result == false {
                global.showAlert("", message: "Invalid email address")
            }
            return result
            
        case txtPassword:
            if txtPassword.text.isEmpty || count(txtPassword.text) < 6 {
                if count(txtPassword.text) != 0 {
                    global.showAlert("", message: "Password must be 6 or more characters")
                }
                txtPasswordConfirm.text = ""
                txtPasswordConfirm.enabled = false
                return false
            }
            txtPasswordConfirm.enabled = true
            return true
            
        case txtPasswordConfirm:
            if txtPassword.text != txtPasswordConfirm.text {
                global.showAlert("", message: "Passwords do not match")
                return false
            }
            newPassword = txtPasswordConfirm.text
            return true
            
        default:
            return true
        }
        return true
    }
    
    override func viewWillDisappear(animated: Bool) {
        if changed == true {
            var saveAlert = UIAlertController(title: "Save?", message: "Do you want to save changes?", preferredStyle: UIAlertControllerStyle.Alert)
            saveAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
                var user = PFUser.currentUser()!
                if self.newPassword != nil { user.password = self.newPassword! }
                user["name"] = self.txtName.text
                user["cellNumber"] = self.txtCell.text
                user["country"] = self.btnCountry.titleLabel?.text
                if !self.txtEmail.text.isEmpty { user["email"] = self.txtEmail.text }
                user.saveInBackgroundWithBlock({
                    (result : Bool, error : NSError?) -> Void in
                    if result == true {
                        global.showAlert("", message: "Settings updated")
                    } else if error?.localizedDescription != nil {
                        global.showAlert("", message: error!.localizedDescription)
                    } else {
                        global.showAlert("", message: "There was an error updating you settings")
                    }
                })
            }))
            
            saveAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in
//                global.showAlert("", message: "Not Saved")
            }))
            presentViewController(saveAlert, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
