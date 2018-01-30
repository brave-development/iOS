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
    
    var mainViewController : MainViewController?
//    var manager : CLLocationManager!
    var pushQuery : PFQuery = PFInstallation.query()!
    var pendingPushNotifications = false // Tracks the button status. Dont send push if Panic isnt active.
    var allowAddToPushQue = true // Tracks if a push has been sent. Should not allow another push to be queued if false.
    var locationPermission = false
    var timer: Timer?
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var viewChat: UIView!
    @IBOutlet weak var btnMenu: UIButton!
    @IBOutlet weak var btnChat: UIButton!
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
        
        styleButton(button: btnChat, shadowView: viewChat)
        
        if alertHandler.currentAlert != nil {
            viewChat.isHidden = false
        } else {
            viewChat.isHidden = true
        }
        
        if global.isChatPilot { viewMenuButton.isHidden = true }
    }
    
    func styleButton(button: UIButton, shadowView: UIView? = nil) {
        button.layer.cornerRadius = button.frame.size.height/2
        button.layer.masksToBounds = true
        shadowView?.layer.shadowOffset = .zero
        shadowView?.layer.shadowRadius = 4
        shadowView?.layer.shadowOpacity = 0.7
    }
    
    @IBAction func menuButton(_ sender: AnyObject) {
        self.mainViewController?.openSidebar(true)
    }
    
    @IBAction func openChat(_ sender: Any) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "alertStage_2_VC") as! AlertStage_2_VC
        //            let vc = storyboard!.instantiateViewController(withIdentifier: "alert_Chat_VC") as! Alert_Chat_VC
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func panicPressed(_ sender: AnyObject) {
        mainViewController?.closeSidebar()
        if btnPanic.tag == 0 {
            locationHandler.isLocationEnabled(completionHandler: {
                isEnabled in
                
                if isEnabled {
                    if global.panicConfirmation {
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
                self.viewChat.isHidden = false
                
                self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateResponderCount), userInfo: nil, repeats: true)
                
                if self.pendingPushNotifications == false {
                    self.pendingPushNotifications = true
                    if global.panicConfirmation == true {
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
        mainViewController?.tabbarView.isUserInteractionEnabled = false
        changeButtonStyle(to: .activate)
        spinner.startAnimating()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.mainViewController?.hideTabbar()
            self.viewMenuButton.alpha = 0.0
        }, completion: { _ in
            self.viewMenuButton.isHidden = true
        })
        
        Timer.scheduledTimer(withTimeInterval: 4, repeats: false) {_ in
            if self.spinner.isAnimating {
                self.view.makeToast("Waiting for better GPS accuracy...")
            }
        }
    }
    
    func deativate_UIChanges() {
        UIApplication.shared.isIdleTimerDisabled = false
        spinner.stopAnimating()
        
        if !global.isChatPilot { viewMenuButton.isHidden = false }
        
        mainViewController?.tabbarView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.3, animations: {
            self.viewMenuButton.alpha = 1.0
            self.mainViewController?.showTabbar()
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
            break
            
        case .deactivate:
            btnPanic.layer.borderColor = UIColor.green.cgColor
            btnPanic.layer.shadowColor = UIColor.green.cgColor
            btnPanic.setTitle(NSLocalizedString("activate", value: "Overdose Alert", comment: "Button title to activate the Panic button"), for: UIControlState())
            btnPanic.tag = 0
            break
        }
    }
    
    func updateResponderCount() {
        if let count = alertHandler.currentAlert?.responders.count {
            lblResponders.text = "\(count)"
            global.mainTabbar?.viewControllers?[2].tabBarItem.badgeValue = "\(count)"
        } else {
            global.mainTabbar?.viewControllers?[2].tabBarItem.badgeValue = nil
        }
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

