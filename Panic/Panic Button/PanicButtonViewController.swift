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


class PanicButtonViewController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    enum PanicButtonStyle {
        case activate
        case deactivate
    }
    
    var mainViewController : MainViewController!
    var manager : CLLocationManager!
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
        
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways) || (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse) {
        }
        
//        NotificationCenter.default.addObserver(self, selector: #selector(updateActivePanics), name: NSNotification.Name(rawValue: "updatedActivePanics"), object: nil)
        
        lblResponders.alpha = 0.0
        lblRespondersLabel.alpha = 0.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(pauseLocationUpdates(_:)), name:NSNotification.Name(rawValue: "applicationDidEnterBackground"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeLocationUpdates(_:)), name:NSNotification.Name(rawValue: "applicationWillEnterForeground"), object: nil)
        
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        
        btnPanic.backgroundColor = UIColor(white: 0, alpha: 0.4)
        
        btnPanic.layer.cornerRadius = 0.5 * btnPanic.bounds.size.width
        btnPanic.layer.borderWidth = 2
        btnPanic.layer.borderColor = UIColor.green.cgColor
        
        if global.isDESPilot {
//            viewNeedle.isHidden = false
            btnNeedle.layer.cornerRadius = btnNeedle.frame.size.height/2
            btnNeedle.layer.masksToBounds = true
            viewNeedle.layer.shadowOffset = CGSize(width: 0, height: 0)
            viewNeedle.layer.shadowRadius = 4
            viewNeedle.layer.shadowOpacity = 0.7
        }
    }
    
    @IBAction func menuButton(_ sender: AnyObject) {
        self.mainViewController.openSidebar(true)
    }
    
    @IBAction func needleDropPressed(_ sender: Any) {
        if locationPermissionGranted() {
            btnNeedle.setImage(UIImage(), for: .normal)
            spinnerNeedle.startAnimating()
            self.btnNeedle.isEnabled = false
            let drop = PFObject(className: "Needles")
            
            drop["location"] = PFGeoPoint(location: manager.location)
            drop["user"] = PFUser.current()
            
            drop.saveInBackground {
                (success, error) in
                self.spinnerNeedle.stopAnimating()
                self.btnNeedle.setImage(UIImage(named: "needle"), for: .normal)
                self.btnNeedle.isEnabled = true
                if success {
                    self.view.makeToast("Needle position saved!", duration: 3, position: CSToastPositionCenter)
                } else {
                    self.view.makeToast("error!.localizedDescription", duration: 3, position: CSToastPositionCenter)
                }
            }
        }
    }
    
    @IBAction func panicPressed(_ sender: AnyObject) {
        mainViewController.closeSidebar()
        if tutorial.swipeToOpenMenu == true {
            if (btnPanic.titleLabel?.text == NSLocalizedString("activate", value: "Send Alert", comment: "Button title to activate the Panic button")) {
                
                if locationPermissionGranted() {
                    
                    if global.panicConfirmation == true {
                        
                        let saveAlert = UIAlertController(title: NSLocalizedString("activate", value: "Activate", comment: "confirmation to activate the Panic button"), message: NSLocalizedString("activate_confirmation_text", value: "Activate Brave and send notifications?", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                        saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
                            self.activatePanic()
                        }))
                        saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .default, handler: { (action: UIAlertAction!) in }))
                        present(saveAlert, animated: true, completion: nil)
                    } else {
                        activatePanic()
                    }
                }
            } else {
                deativatePanic()
            }
        }
    }
    
    func activatePanic() {
        PFAnalytics.trackEvent(inBackground: "Activate_Panic", dimensions: nil, block: nil)
        UIApplication.shared.isIdleTimerDisabled = true
        
        self.mainViewController.tabbarView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.3, animations: {
            self.mainViewController.hideTabbar()
        })
        
        UIView.animate(withDuration: 0.3, animations: {
            self.viewMenuButton.alpha = 0.0
        }, completion: {
            (result) in
            self.viewMenuButton.isHidden = true
        })
        
        panicHandler.panicIsActive = true
        mainViewController.panicIsActive = true
        manager.startUpdatingLocation()
        changeButtonStyle(to: .activate)
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(updateResponderCount), userInfo: nil, repeats: true)
        
        activateWithBetaChanges()
        
        if pendingPushNotifications == false {
            pendingPushNotifications = true
            if global.panicConfirmation == true || global.isDESPilot {
                prepareForSendNotification()
            } else {
                Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(prepareForSendNotification), userInfo: nil, repeats: false)
            }
        }
        
        manageAutoDeactivation()
    }
    
    func activateWithBetaChanges() {
//        if global.isDESPilot {
        
            let appearance = SCLAlertView.SCLAppearance(
                kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
                kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
                kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
                showCloseButton: false
            )
            
            // Initialize SCLAlertView using custom Appearance
            let alert = SCLAlertView(appearance: appearance)
            
            // Creat the subview
            let textView = SZTextView(frame: CGRect(x: 0, y: 0, width: 210, height: 100))
            textView.placeholder = "Tap here to type...\n\n\n\n\nYou have lots of space :)"
            
            // Add the subview to the alert's UI property
            alert.customSubview = textView
            
            alert.addButton("Submit") {
                print("Submitted details...")
                if textView.text!.trim().characters.count > 0 {
                    panicHandler.updateDetails(textView.text!.trim())
                    panicHandler.clearPanic()
                }
            }
            
            // Add Button with Duration Status and custom Colors
            alert.addButton("No Details", backgroundColor: UIColor.flatRed, textColor: UIColor.white) {
                panicHandler.clearPanic()
            }
            
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
            buttonGlow()
            break
            
        case .deactivate:
            btnPanic.layer.borderColor = UIColor.green.cgColor
            btnPanic.layer.shadowColor = UIColor.green.cgColor
            btnPanic.setTitle(NSLocalizedString("activate", value: "Send Alert", comment: "Button title to activate the Panic button"), for: UIControlState())
            break
            
        default: break
        }
    }
    
    func deativatePanic() {
        UIApplication.shared.isIdleTimerDisabled = false
        
        self.viewMenuButton.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.viewMenuButton.alpha = 1.0
        })
        
        panicHandler.panicIsActive = false
//        pendingPushNotifications = false
        mainViewController.panicIsActive = false
        global.getLocalHistory()
        
        self.mainViewController.tabbarView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.3, animations: {
            self.mainViewController.showTabbar() })
        
        panicHandler.endPanic()
        manager.stopUpdatingLocation()
        changeButtonStyle(to: .deactivate)
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
    
    func manageAutoDeactivation() {
        if panicHandler.panicIsActive == false { return }
        
        if panicHandler.updating == true {
            Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(manageAutoDeactivation), userInfo: nil, repeats: false)
            return
        }
        
        if let accuracy = manager.location?.horizontalAccuracy {
            if accuracy < CLLocationAccuracy(100) && panicHandler.queryObject != nil {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in
                    self.deativatePanic()
                })
                return
            } else {
                Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(manageAutoDeactivation), userInfo: nil, repeats: false)
            }
        } else {
            Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(manageAutoDeactivation), userInfo: nil, repeats: false)
        }
    }
    
    func updateResponderCount() {
        lblResponders.text = "\(panicHandler.responderCount)"
    }
    
    func prepareForSendNotification() {
        print("In sendNotificaion method")
        if manager.location != nil {
            if pendingPushNotifications == true {
                if allowAddToPushQue == true {
                    allowAddToPushQue = false
                    sendNotifications()
                }
                allowAddToPushQue = true
                pendingPushNotifications = false
            } else {
                print("Canceled Notifications")
            }
        } else {
            Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.prepareForSendNotification), userInfo: nil, repeats: false)
        }
    }
    
    func sendNotifications() {
        panicHandler.sendNotifications()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        panicHandler.updateDetails(textView.text)
    }
    
//    func updateActivePanics() {
//        mainViewController.badge.autoBadgeSize(with: "\(panicHandler.activePanicCount)")
//        mainViewController.badge.isHidden = panicHandler.activePanicCount == 0
//        print("Updated Panic count from Main")
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "updatedActivePanics"), object: nil)
        print("Main disappearing...")
    }
}


// =============
// LOCATION STUFF
// =============


extension PanicButtonViewController: CLLocationManagerDelegate {
    
    func locationPermissionGranted() -> Bool {
        print("Location permission \(locationPermission)")
        if locationPermission == true {
            return true
        } else {
            global.showAlert(NSLocalizedString("location_not_allowed_title", value: "Location Not Allowed", comment: ""), message: NSLocalizedString("location_not_allowed_text", value: "Please enable location services for Brave by going to Settings > Privacy > Location Services.", comment: ""))
            return false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        panicHandler.updatePanic(manager.location!)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if global.didChangeAuthStatus(manager, status: status) == true {
            locationPermission = true
        } else {
            locationPermission = false
        }
    }
    
    func pauseLocationUpdates(_ notification: Notification) {
        print("PAUSED from NC")
        manager.stopUpdatingLocation()
    }
    
    func resumeLocationUpdates(_ notification: Notification) {
        print("RESUMED from NC")
        manager.startUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
