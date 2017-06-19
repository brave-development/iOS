//
//  SettingsTableViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/13.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
//import Parse
import MessageUI
import CoreLocation
import FacebookCore
import ParseFacebookUtilsV4
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class SettingsTableViewController: UITableViewController, UITextFieldDelegate, countryDelegate, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtCell: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtPasswordConfirm: UITextField!
    @IBOutlet weak var viewPasswordConfirm: UIView!
    @IBOutlet weak var switchPanicConfirmation: UISwitch!
	@IBOutlet weak var switchBackgroundUpdate: UISwitch!
    @IBOutlet weak var switchAllowNotifications: UISwitch!
    @IBOutlet weak var btnCountry: UIButton!
    
    var mainViewController : MainViewController!
    var changed = false
    var currentlySelectedTextFieldValue = ""
    var newPassword : String?
	var mail: MFMailComposeViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        let user = PFUser.current()!
        
        if user["country"] != nil {
            btnCountry.setTitle((user["country"] as! String), for: UIControlState())
        }
        txtName.text = user["name"] as! String
        txtCell.text = user["cellNumber"] as! String
        if user["email"] != nil {
            txtEmail.text = user["email"] as! String
        }
        btnCountry.setTitle((user["country"] as! String), for: UIControlState())
        txtPassword.text = ""
        txtPassword.text = ""
        txtPasswordConfirm.isEnabled = false
        
        if global.panicConfirmation == true {
            switchPanicConfirmation.isOn = true
        }
		if global.backgroundPanic == true {
			switchBackgroundUpdate.isOn = true
		}
        if let allowNotifications = (PFInstallation.current()!["allowNotifications"] as? Bool) {
            switchAllowNotifications.isOn = allowNotifications
        } else {
            switchAllowNotifications.isOn = true
            PFInstallation.current()?.setValue(true, forKey: "allowNotifications")
            PFInstallation.current()?.saveInBackground()
        }
    }
    
	override func viewDidAppear(_ animated: Bool) {
		if PFUser.current()!["country"] != nil {
			if btnCountry.titleLabel?.text != (PFUser.current()!["country"] as! String) {
				changed = true
			}
		}
	}
	
    func didSelectCountry(_ country: String) {
        print("Got selected country")
        btnCountry.setTitle(country, for: UIControlState())
        if country != PFUser.current()!["country"] as! String {
            changed = true
        }       
    }
    
    @IBAction func showCountriesViewController (_ sender: AnyObject) {
        var storyboard = UIStoryboard(name: "Main", bundle: nil)
        var vc: CountriesViewController = storyboard.instantiateViewController(withIdentifier: "countriesViewController") as! CountriesViewController
        vc.delegate = self
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        self.present(vc, animated: true, completion: nil)
    }

    @IBAction func panicConfirmation(_ sender: AnyObject) {
        if switchPanicConfirmation.isOn == true {
            global.setPanicNotification(true)
        } else {
            global.setPanicNotification(false)
        }
    }
	
	@IBAction func backgroundUpdates(_ sender: AnyObject) {
		if switchBackgroundUpdate.isOn == true {
			if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways {
				global.setBackgroundUpdate(true)
			} else {
				global.showAlert("Oops", message:NSLocalizedString("location_not_allowed", value: "To use this feature, you will need to grant Panic permission to use your location in the background. To do this, go to iPhone Settings > Privacy > Location Services > Panic > 'Always'", comment: "") )
			}
		} else {
			global.setBackgroundUpdate(false)
		}
	}
    
    @IBAction func allowNotifications(_ sender: AnyObject) {
        changed = true
    }
    
    // Show popup with information about panicConfirmation
    @IBAction func showInfoPanicConfirmation(_ sender: AnyObject) {
        global.showAlert(NSLocalizedString("confirmation_info_title", value: "Panic Confirmation", comment: ""), message: NSLocalizedString("confirmation_info_text", value: "Enabling this will remove the 5 second delay before sending notifications, however you will have to manually select 'Yes' each time you activate Panic.", comment: ""))
    }
	
	@IBAction func showInfoBackgroundUpdate(_ sender: AnyObject) {
		global.showAlert(NSLocalizedString("background_update_info_title", value: "Background Update", comment: ""), message: NSLocalizedString("background_update_info_text", value: "Enabling background updates will let Panic continue to broadcast your location, even when the app is in the background and/or your iPhone is asleep, during activation.\n\nThis is disabled by default as it can be heavy on battery, can use more data then expected if left on for an extended period of time and because of the way iPhone handles background apps, can be unreliable (although rarely)", comment: ""))
	}
	
    @IBAction func showNotificationsInformation(_ sender: Any) {
        global.showAlert(NSLocalizedString("allow_notifications_info_title", value: "Allow Notifications", comment: ""), message: NSLocalizedString("allow_notifications_info_text", value: "Allowing notifications means this device will recieve a notification when someone activates the panic button. If you disable this, you will not be notified when someone needs help.\n\nPlease keep in mind how you might feel when you're in need of help and someone has this deactivated.", comment: ""))
    }
    
	@IBAction func reportBug(_ sender: AnyObject) {
		mail = MFMailComposeViewController()
		if(MFMailComposeViewController.canSendMail()) {
			
			mail.mailComposeDelegate = self
			mail.setSubject("Panic - Bug")
			mail.setToRecipients(["byroncoetsee@gmail.com"])
			mail.setMessageBody("I am having the following issues with the Panic app: ", isHTML: true)
			self.present(mail, animated: true, completion: nil)
		}
		else {
			global.showAlert(NSLocalizedString("error_could_not_send_email_title", value: "Could Not Send Email", comment: ""), message: NSLocalizedString("error_could_not_send_email_text", value: "Your device could not send e-mail.  Please check e-mail configuration and try again.", comment: ""))
		}
	}
	
	@IBAction func reportUser(_ sender: AnyObject) {
		global.showAlert(NSLocalizedString("report_user_title", value: "Report a user", comment: ""), message:NSLocalizedString("report_user_text", value: "To report a user, go to Public History, tap on the Panic associated to that user and use the report button there.", comment: "") )
	}
	
	func mailComposeController(_ controller: MFMailComposeViewController!, didFinishWith result: MFMailComposeResult, error: Error!) {
		switch(result){
		case MFMailComposeResult.sent:
			print("Email sent")
			
		default:
			print("Whoops")
		}
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func tutorialReset(_ sender: AnyObject) {
		tutorial.reset()
		global.showAlert("", message: NSLocalizedString("tutorials_reset_text", value: "Tutorials have been re-enabled. Go back to the main Home screen to view them as you did the first time the app was opened.", comment: ""))
	}
	
	@IBAction func logout(_ sender: AnyObject) {
		global.showAlert("Note", message: NSLocalizedString("logout_message", value: "Logging out disables any Panic notifications. You will not be notified when someone activates their Panic button.\n\nOn the other hand, closing the app with the home button, or even the app switcher, logs you out in a way that you still receive notifications.", comment: ""))
		if global.persistantSettings.object(forKey: "groups") != nil {
			global.persistantSettings.removeObject(forKey: "groups")
		}
		PFUser.logOut()
//        PFFacebookUtils.facebookLoginManager().logOut()
//        FBSDKLoginManager.init().logOut()
		PFInstallation.current()?.setObject(["", "logged_out"], forKey: "channels")
		PFInstallation.current()?.saveInBackground(block: nil)
		self.mainViewController.back()
	}
	
    @IBAction func deleteAccount(_ sender: AnyObject) {
        var saveAlert = UIAlertController(title: NSLocalizedString("delete_account_confirmation_1_title", value: "Confirmation", comment: ""), message: NSLocalizedString("delete_account_confirmation_1_text", value: "Are you sure you want to delete your account?\n\nThis will remove all your details, free up your username, remove all Panic history and you will have to reregister if you want to use this app again.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
            var saveAlert = UIAlertController(title: NSLocalizedString("delete_account_confirmation_2_title", value: "Final Confirmation", comment: ""), message: NSLocalizedString("delete_account_confirmation_2_text", value: "Permenently delete account?", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
                
                let queryDeleteAccount = PFQuery(className: "Panics")
                queryDeleteAccount.whereKey("user", equalTo: PFUser.current()!)
                queryDeleteAccount.findObjectsInBackground(block: {
					(objects, error) in
					if objects != nil {
						if objects!.count > 0 {
							PFObject.deleteAll(inBackground: objects!, block: {
								(result, error) in
								if result == true {
									PFUser.current()!.deleteInBackground(block: nil)
									if PFUser.current() != nil { PFUser.logOut() }
									self.mainViewController.back()
									global.showAlert("", message: "Thanks for using Panic. Goodbye.")
								}
							})
						}
					}
				})
            }))
            saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
            }))
            self.present(saveAlert, animated: true, completion: nil)
        }))
        saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
        }))
        self.present(saveAlert, animated: true, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == txtPassword {
            txtPasswordConfirm.isEnabled = true
        }
        currentlySelectedTextFieldValue = textField.text!
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if validateTextField(textField) == true {
            if textField.text != currentlySelectedTextFieldValue {
                changed = true
            }
        } else {
            textField.text = currentlySelectedTextFieldValue
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField != txtPassword {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func validateTextField(_ textField : UITextField) -> Bool {
        switch (textField) {
        case txtName:
            if txtName.text?.characters.count < 5 {
                global.showAlert("", message: NSLocalizedString("error_name_5_chars", value: "Your name cannot be less than 5 characters. Please fill in your full name.", comment: ""))
                return false
            }
            break;
        
        case txtCell:
            if txtCell.text?.characters.count < 10 {
                global.showAlert("Note", message: NSLocalizedString("number_change_warning", value: "Setting your mobile number incorrectly will prevent others from contacting you in an emergency", comment: ""))
            }
            return true
            
        case txtEmail:
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
            var emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            let result = emailTest.evaluate(with: txtEmail.text)
            if result == false {
                global.showAlert("", message: NSLocalizedString("email_address_invalid", value: "Invalid email address", comment: ""))
            }
            return result
            
        case txtPassword:
            if txtPassword.text!.isEmpty || txtPassword.text?.characters.count < 6 {
                if txtPassword.text?.characters.count != 0 {
                    global.showAlert("", message: NSLocalizedString("password_6_chars", value: "Password must be 6 or more characters", comment: ""))
                }
                txtPasswordConfirm.text = ""
                txtPasswordConfirm.isEnabled = false
                return false
            }
            txtPasswordConfirm.isEnabled = true
            return true
            
        case txtPasswordConfirm:
            if txtPassword.text != txtPasswordConfirm.text {
                global.showAlert("", message: NSLocalizedString("pass_dont_match", value: "Passwords do not match", comment: "") )
                return false
            }
            newPassword = txtPasswordConfirm.text
            return true
            
        default:
            return true
        }
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if changed == true {
            let saveAlert = UIAlertController(title: NSLocalizedString("save", value: "Save", comment: ""), message: NSLocalizedString("save_changes_confirmation_text", value: "Do you want to save changes?", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            
            // YES
            saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
                PFInstallation.current()?.setValue(self.switchAllowNotifications.isOn, forKey: "allowNotifications")
                PFInstallation.current()?.saveInBackground()
                
                let user = PFUser.current()!
                if self.newPassword != nil { user.password = self.newPassword! }
                user["name"] = self.txtName.text
                user["cellNumber"] = self.txtCell.text
                user["country"] = self.btnCountry.titleLabel?.text
                if !self.txtEmail.text!.isEmpty { user["email"] = self.txtEmail.text }
                user.saveInBackground(block: {
                    (result, error) in
                    if result == true {
                        global.showAlert("", message: NSLocalizedString("settings_updated", value: "Settings updated", comment: ""))
                    } else if error?.localizedDescription != nil {
                        global.showAlert("", message: error!.localizedDescription)
                    } else {
                        global.showAlert("", message: NSLocalizedString("error_updating_settings", value: "There was an error updating you settings", comment: ""))
                    }
                })
            }))
            
            // NO
            saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .default, handler: { (action: UIAlertAction!) in }))
            
            // PRESENT
            present(saveAlert, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
