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
    var tapGesture: UITapGestureRecognizer!
    var timer: Timer?
    
    @IBOutlet weak var viewNeedle: UIView!
    @IBOutlet weak var spinnerNeedle: UIActivityIndicatorView!
    @IBOutlet weak var btnNeedle: UIButton!
    @IBOutlet weak var btnPanic: UIButton!
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var txtDetails: UITextView!
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateActivePanics), name: NSNotification.Name(rawValue: "updatedActivePanics"), object: nil)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
        
        txtDetails.backgroundColor = UIColor(white: 0, alpha: 0.2)
        txtDetails.layer.cornerRadius = 5
        txtDetails.delegate = self
        txtDetails.alpha = 0.0
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
        
        btnNeedle.layer.cornerRadius = btnNeedle.frame.size.height/2
        btnNeedle.layer.masksToBounds = true
        viewNeedle.layer.shadowOffset = CGSize(width: 0, height: 0)
        viewNeedle.layer.shadowRadius = 4
        viewNeedle.layer.shadowOpacity = 0.7
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
            if (btnPanic.titleLabel?.text == NSLocalizedString("activate", value: "Activate", comment: "Button title to activate the Panic button")) {
                
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
        
        background.addGestureRecognizer(tapGesture)
        panicHandler.panicIsActive = true
        mainViewController.panicIsActive = true
        manager.startUpdatingLocation()
        changeButtonStyle(to: .activate)
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(updateResponderCount), userInfo: nil, repeats: true)
        
        activateWithBetaChanges()
        
//        UIView.animate(withDuration: 0.5, animations: {
//            self.txtDetails.alpha = 1.0
//            self.lblResponders.alpha = 1.0
//            self.lblRespondersLabel.alpha = 1.0
//        })
        
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
        if global.isDESPilot {
            var inputTextField: UITextField?
            let codePrompt = UIAlertController(title: NSLocalizedString("enter_code_title", value: "Details", comment: ""), message: NSLocalizedString("enter_description_text", value: "Describe what's happening", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            
            codePrompt.addTextField(configurationHandler: {(textField: UITextField!) in
                textField.placeholder = NSLocalizedString("alert_details_placeholder", value: "Details", comment: "Placeholder for details")
                inputTextField = textField
            })
            
            codePrompt.addAction(UIAlertAction(title: NSLocalizedString("no_details", value: "No Details", comment: ""), style: UIAlertActionStyle.destructive, handler: nil))
            
            codePrompt.addAction(UIAlertAction(title: NSLocalizedString("submit", value: "Submit", comment: "Submitting the details"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
                if inputTextField!.text!.trim().characters.count > 0 {
                    panicHandler.updateDetails(inputTextField!.text!.trim())
                } else {
                    global.showAlert("", message: "Please enter some information or tap 'No Details'")
                }
            }))
            
            present(codePrompt, animated: true, completion: nil)
            
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                self.txtDetails.alpha = 1.0
                self.lblResponders.alpha = 1.0
                self.lblRespondersLabel.alpha = 1.0
            })
        }
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
            btnPanic.setTitle(NSLocalizedString("activate", value: "Activate", comment: "Button title to activate the Panic button"), for: UIControlState())
            break
            
        default: break
        }
    }
    
    func deativatePanic() {
        UIApplication.shared.isIdleTimerDisabled = false
        background.removeGestureRecognizer(tapGesture)
        
        self.viewMenuButton.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.viewMenuButton.alpha = 1.0
        })
        
        panicHandler.panicIsActive = false
        pendingPushNotifications = false
        mainViewController.panicIsActive = false
        global.getLocalHistory()
        
        timer?.invalidate()
        
        self.mainViewController.tabbarView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.3, animations: {
            self.mainViewController.showTabbar() })
        
        panicHandler.endPanic()
        manager.stopUpdatingLocation()
        changeButtonStyle(to: .deactivate)
        UIView.animate(withDuration: 0.5, animations: {
            self.txtDetails.alpha = 0.0
            self.lblResponders.alpha = 0.0
            self.lblRespondersLabel.alpha = 0.0
            self.lblResponders.text = "0"
            self.txtDetails.text = ""
        })
        txtDetails.resignFirstResponder()
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
        if panicHandler.panicIsActive == false || global.isDESPilot == false { return }
        
        if let accuracy = manager.location?.horizontalAccuracy {
            if accuracy < CLLocationAccuracy(100) {
                deativatePanic()
                return
            }
        }

        Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(manageAutoDeactivation), userInfo: nil, repeats: false)
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
    
    func resignKeyboard() {
        txtDetails.resignFirstResponder()
    }
    
    func updateActivePanics() {
        mainViewController.badge.autoBadgeSize(with: "\(panicHandler.activePanicCount)")
        mainViewController.badge.isHidden = panicHandler.activePanicCount == 0
        print("Updated Panic count from Main")
    }
    
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
