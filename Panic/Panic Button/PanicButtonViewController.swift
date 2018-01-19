//
//  MainViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/11/30.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import CoreLocation
import Toast
import SCLAlertView
import SZTextView
import ChameleonFramework
import SwiftLocation


class PanicButtonViewController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    enum PanicButtonStyle {
        case activate
        case deactivate
    }
    
    var mainViewController : MainViewController!
//    var manager : CLLocationManager!
    var pushQuery : PFQuery = PFInstallation.query()!
    var pendingPushNotifications = false // Tracks the button status. Dont send push if Panic isnt active.
    var allowAddToPushQue = true // Tracks if a push has been sent. Should not allow another push to be queued if false.
    var locationPermission = false
    var timer: Timer?
    
    @IBOutlet weak var viewNeedle: UIView!
    @IBOutlet weak var spinnerNeedle: UIActivityIndicatorView!
    @IBOutlet weak var btnNeedle: UIButton!
    @IBOutlet weak var btnPanic: UIButton!
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var lblResponders: UILabel!
    @IBOutlet weak var lblRespondersLabel: UILabel!
    
    // Menu button
    
    @IBOutlet weak var viewMenuButton: UIVisualEffectView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewMenuButton.layer.cornerRadius = 0.5 * viewMenuButton.bounds.size.width
        viewMenuButton.clipsToBounds = true
        
        lblResponders.alpha = 0.0
        lblRespondersLabel.alpha = 0.0
        
        btnPanic.backgroundColor = UIColor(white: 0, alpha: 0.4)
        
        btnPanic.layer.cornerRadius = 0.5 * btnPanic.bounds.size.width
        btnPanic.layer.borderWidth = 2
        btnPanic.layer.borderColor = UIColor.green.cgColor
        
        if global.isChatPilot {
            styleChatButton()
        }
    }
    
    func styleChatButton() {
        btnNeedle.layer.cornerRadius = btnNeedle.frame.size.height/2
        btnNeedle.layer.masksToBounds = true
        viewNeedle.layer.shadowOffset = CGSize(width: 0, height: 0)
        viewNeedle.layer.shadowRadius = 4
        viewNeedle.layer.shadowOpacity = 0.7
        
        if alertHandler.currentAlert != nil {
            viewNeedle.isHidden = false
        }
    }
    
    @IBAction func menuButton(_ sender: AnyObject) {
        self.mainViewController.openSidebar(true)
    }
    
    @IBAction func needleDropPressed(_ sender: Any) {
        if global.isChatPilot {
            let vc = storyboard!.instantiateViewController(withIdentifier: "alertStage_2_VC") as! AlertStage_2_VC
            //            let vc = storyboard!.instantiateViewController(withIdentifier: "alert_Chat_VC") as! Alert_Chat_VC
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overCurrentContext
            self.present(vc, animated: true, completion: nil)
            
            return
        }
        
        btnNeedle.setImage(UIImage(), for: .normal)
        btnNeedle.isEnabled = false
        spinnerNeedle.startAnimating()
        
        Locator.currentPosition(accuracy: .room, timeout: Timeout.after(60), onSuccess: {
            location in
            let needle = Sub_PFNeedle(location: location)
            needle.saveInBackground(block: {
                (success, error) in
                self.spinnerNeedle.stopAnimating()
                self.btnNeedle.setImage(UIImage(named: "needle"), for: .normal)
                self.btnNeedle.isEnabled = true
                if success {
                    self.view.makeToast("Needle position saved!", duration: 3, position: CSToastPositionCenter)
                } else {
                    self.view.makeToast("error!.localizedDescription", duration: 3, position: CSToastPositionCenter)
                }
            })
        }) {
            (error, location) in
            self.spinnerNeedle.stopAnimating()
            self.btnNeedle.setImage(UIImage(named: "needle"), for: .normal)
            self.btnNeedle.isEnabled = true
            self.view.makeToast("Something went wrong...\n\n\(error.localizedDescription)", duration: 5, position: CSToastPositionCenter)
        }
    }
    
    @IBAction func panicPressed(_ sender: AnyObject) {
        mainViewController.closeSidebar()
        if btnPanic.tag == 0 {
            locationHandler.isLocationEnabled(completionHandler: {
                isEnabled in
                
                if isEnabled {
                    if global.panicConfirmation == true {
                        self.showActivationConfirmation()
                    } else {
                        self.activateAlert()
                    }
                } else {
                    global.showAlert(NSLocalizedString("location_not_allowed_title", value: "Location Not Allowed", comment: ""), message: NSLocalizedString("location_not_allowed_text", value: "Please enable location services for Brave by going to Settings > Privacy > Location Services.", comment: ""))
                }
            })
            
        } else {
            deativate_UIChanges()
        }
    }
    
    func showActivationConfirmation() {
        let saveAlert = UIAlertController(title: NSLocalizedString("activate", value: "Activate", comment: "confirmation to activate the Panic button"), message: NSLocalizedString("activate_confirmation_text", value: "Activate Brave and send notifications?", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
            self.activateAlert()
        }))
        saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .default, handler: { (action: UIAlertAction!) in }))
        self.present(saveAlert, animated: true, completion: nil)
    }
    
    func activateAlert() {
        activate_UIChanges()
        alertHandler.startAlert {
            success in
            
            if success {
                self.showDetailsInput()
                self.viewNeedle.isHidden = false
                
                self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateResponderCount), userInfo: nil, repeats: true)
                
                if self.pendingPushNotifications == false {
                    self.pendingPushNotifications = true
                    if global.panicConfirmation == true || global.isDESPilot {
                        self.prepareForSendNotification()
                    } else {
                        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.prepareForSendNotification), userInfo: nil, repeats: false)
                    }
                }
                self.deativate_UIChanges()
                print("ALERT SENT")
            } else {
                self.deativate_UIChanges()
                print("ALERT DIDN'T SEND")
            }
        }
    }
    
    func activate_UIChanges() {
        UIApplication.shared.isIdleTimerDisabled = true
        mainViewController.tabbarView.isUserInteractionEnabled = false
        self.changeButtonStyle(to: .activate)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.mainViewController.hideTabbar()
            self.viewMenuButton.alpha = 0.0
        }, completion: { _ in
            self.viewMenuButton.isHidden = true
        })
    }
    
    func deativate_UIChanges() {
        UIApplication.shared.isIdleTimerDisabled = false
        
        self.viewMenuButton.isHidden = false
        
        mainViewController.tabbarView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.3, animations: {
            self.viewMenuButton.alpha = 1.0
            self.mainViewController.showTabbar()
        })
        
        changeButtonStyle(to: .deactivate)
        
        global.getLocalHistory()
    }
    
    func showDetailsInput() {
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false
        )
        
        let alert = SCLAlertView(appearance: appearance)
        
        let textView = SZTextView(frame: CGRect(x: 0, y: 0, width: 210, height: 100))
        textView.placeholder = "Tap here to type...\n\n\n\n\nYou have lots of space :)"
        
        alert.customSubview = textView
        
        alert.addButton("Submit") {
            print("Submitted details...")
            if textView.text!.trim().characters.count > 0 {
                alertHandler.updateDetails(details: textView.text!.trim())
            }
        }
        
        alert.addButton("No Details", backgroundColor: UIColor.flatRed, textColor: UIColor.white) { }
        alert.showInfo("Details about the event", subTitle: "")
        
        UIView.animate(withDuration: 0.5, animations: {
            self.lblResponders.alpha = 1.0
            self.lblRespondersLabel.alpha = 1.0
        })
    }
    
    func changeButtonStyle(to style: PanicButtonStyle) {
        switch style {
        case .activate:
            btnPanic.setTitle(NSLocalizedString("deactivate", value: "Cancel", comment: ""), for: UIControlState())
            btnPanic.layer.borderColor = UIColor.red.cgColor
            btnPanic.layer.shadowColor = UIColor.red.cgColor
            btnPanic.tag = 1
            buttonGlow()
            break
            
        case .deactivate:
            btnPanic.layer.borderColor = UIColor.green.cgColor
            btnPanic.layer.shadowColor = UIColor.green.cgColor
            btnPanic.setTitle(NSLocalizedString("activate", value: "Overdose Alert", comment: "Button title to activate the Panic button"), for: UIControlState())
            btnPanic.tag = 0
            break
        }
    }
    
    func buttonGlow() {
        if panicHandler.panicIsActive == true {
            self.btnPanic.layer.shadowRadius = 20
            UIView.animate(withDuration: 2, animations: {
                self.btnPanic.layer.shadowRadius = 8
            }, completion: {
                (result) in
                UIView.animate(withDuration: 2, animations: {
                    self.btnPanic.layer.shadowRadius = 4
                }, completion: {
                    (result) in
                    self.buttonGlow()
                })
            })
        }
    }
    
    func updateResponderCount() {
        lblResponders.text = "\(panicHandler.responderCount)"
    }
    
    func prepareForSendNotification() {
        print("In sendNotificaion method")
        if pendingPushNotifications == true {
            if allowAddToPushQue == true {
                allowAddToPushQue = false
                alertHandler.sendPushNotification()
            }
            allowAddToPushQue = true
            pendingPushNotifications = false
        } else {
            print("Canceled Notifications")
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        panicHandler.updateDetails(textView.text)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "updatedActivePanics"), object: nil)
        print("Main disappearing...")
    }
}

