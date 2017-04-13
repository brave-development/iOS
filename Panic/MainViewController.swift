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

protocol testDelegate {
    func test()
}

class MainViewController: UIViewController, UIGestureRecognizerDelegate, CLLocationManagerDelegate, UITextViewDelegate {
    
    var delegate: testDelegate?
    
//    var testString = ""
	
    var tabbarViewController : TabBarViewController!
    var manager : CLLocationManager!
    var pushQuery : PFQuery = PFInstallation.query()!
    var pendingPushNotifications = false // Tracks the button status. Dont send push if Panic isnt active.
    var allowAddToPushQue = true // Tracks if a push has been sent. Should not allow another push to be qued if false.
	var locationPermission = false
	var tapGesture: UITapGestureRecognizer!
	var timer: Timer?
	
    @IBOutlet weak var btnPanic: UIButton!
    @IBOutlet weak var background: UIImageView!
	@IBOutlet weak var txtDetails: UITextView!
	@IBOutlet weak var lblResponders: UILabel!
	@IBOutlet weak var lblRespondersLabel: UILabel!
	
	// Menu button
	
	@IBOutlet weak var viewMenuButton: UIVisualEffectView!
	
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
//		print(PFUser.currentUser())
		viewMenuButton.layer.cornerRadius = 0.5 * viewMenuButton.bounds.size.width
		viewMenuButton.clipsToBounds = true
		
		if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways) || (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse) {
//			locationPermission = true
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateActivePanics), name: NSNotification.Name(rawValue: "updatedActivePanics"), object: nil)
		
		tapGesture = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
		
		txtDetails.backgroundColor = UIColor(white: 1, alpha: 0.2)
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
		
		btnPanic.backgroundColor = UIColor(white: 0, alpha: 0.3)
        
        btnPanic.layer.cornerRadius = 0.5 * btnPanic.bounds.size.width
        btnPanic.layer.borderWidth = 2
        btnPanic.layer.borderColor = UIColor.green.cgColor
    }
	
	@IBAction func menuButton(_ sender: AnyObject) {
		self.tabbarViewController.openSidebar(true)
	}
	
    @IBAction func panicPressed(_ sender: AnyObject) {
		tabbarViewController.closeSidebar()
		if tutorial.swipeToOpenMenu == true {
			if (btnPanic.titleLabel?.text == NSLocalizedString("activate", value: "Activate", comment: "Button title to activate the Panic button")) {
				print("Location permission \(locationPermission)")
				if locationPermission == true {
					
					UIView.animate(withDuration: 0.3, animations: {
						self.tabbarViewController.hideTabbar() })
					
					if global.panicConfirmation == true {
						
						let saveAlert = UIAlertController(title: NSLocalizedString("activate", value: "Activate", comment: "confirmation to activate the Panic button"), message: NSLocalizedString("activate_confirmation_text", value: "Activate Panic and send notifications?", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
						saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
							self.activatePanic()
						}))
						saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .default, handler: { (action: UIAlertAction!) in }))
						present(saveAlert, animated: true, completion: nil)
					} else {
						activatePanic()
					}
				} else {
					global.showAlert(NSLocalizedString("location_not_allowed_title", value: "Location Not Allowed", comment: ""), message: NSLocalizedString("location_not_allowed_text", value: "Please enable location services for Panic by going to Settings > Privacy > Location Services.", comment: ""))
				}
			} else {
				deativatePanic()
			}
		}
	}
	
    func activatePanic() {
		PFAnalytics.trackEvent(inBackground: "Activate_Panic", dimensions: nil, block: nil)
		UIApplication.shared.isIdleTimerDisabled = true
		
		UIView.animate(withDuration: 0.3, animations: {
			self.viewMenuButton.alpha = 0.0
			}, completion: {
				(result) in
				self.viewMenuButton.isHidden = true
		})
		
		background.addGestureRecognizer(tapGesture)
		panicHandler.panicIsActive = true
        tabbarViewController.panicIsActive = true
        manager.startUpdatingLocation()
        btnPanic.setTitle(NSLocalizedString("deactivate", value: "Deactivate", comment: ""), for: UIControlState())
        btnPanic.layer.borderColor = UIColor.red.cgColor
        btnPanic.layer.shadowColor = UIColor.red.cgColor
		buttonGlow()
		timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(updateResponderCount), userInfo: nil, repeats: true)
		
		UIView.animate(withDuration: 0.5, animations: {
			self.txtDetails.alpha = 1.0
			self.lblResponders.alpha = 1.0
			self.lblRespondersLabel.alpha = 1.0
		})
        
        if pendingPushNotifications == false {
            pendingPushNotifications = true
                if global.panicConfirmation == true {
                    prepareForSendNotification()
                } else {
                    Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(prepareForSendNotification), userInfo: nil, repeats: false)
                }
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
        tabbarViewController.panicIsActive = false
        global.getLocalHistory()
		
		timer?.invalidate()
		
        UIView.animate(withDuration: 0.3, animations: {
            self.tabbarViewController.showTabbar() })
        panicHandler.endPanic()
        manager.stopUpdatingLocation()
        btnPanic.setTitle(NSLocalizedString("activate", value: "Activate", comment: "Button title to activate the Panic button"), for: UIControlState())
        btnPanic.layer.borderColor = UIColor.green.cgColor
        btnPanic.layer.shadowColor = UIColor.green.cgColor
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
	
	func updateResponderCount() {
		lblResponders.text = "\(panicHandler.responderCount)"
	}
    
    func prepareForSendNotification() {
		print("In sendNotificaion method")
//		var dict = NSDictionary(dictionary: ["badge":"Increment"])
		if manager.location != nil {
			if pendingPushNotifications == true {
				if allowAddToPushQue == true {
					allowAddToPushQue = false
					for group in groupsHandler.joinedGroups {
						sendNotification(group)
					}
					sendNotification(nil)
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
	
	func sendNotification(_ group: String?) {
		let push = PFPush()
		let userName = PFUser.current()!["name"] as! String
		let userNumber = PFUser.current()!["cellNumber"] as! String
		let tempQuery = PFInstallation.query()
		if group != nil {
			tempQuery!.whereKey("channels", equalTo: group!.formatGroupForChannel())
		} else {
			tempQuery!.whereKey("channels", equalTo: "panic_global")
		}
		tempQuery!.whereKey("installationId", notEqualTo: PFInstallation.current()!.installationId)
		push.setQuery(tempQuery as! PFQuery<PFInstallation>)
		push.expire(afterTimeInterval: 18000) // 5 Hours
		let panicMessage = String(format: NSLocalizedString("panic_notification_message", value: "%@ needs help! Contact them on %@ or view their location in the app.", comment: ""), arguments: [userName, userNumber])
		push.setData(["alert" : panicMessage, "badge" : "Increment", "sound" : "default", "lat" : manager.location!.coordinate.latitude, "long" : manager.location!.coordinate.longitude])
		push.sendInBackground(block: {
			(result, error) in
			if result == true {
				print("Push sent to group \(group!.formatGroupForChannel())")
			} else if error != nil {
				print(error!)
			}
		})
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		panicHandler.updateDetails(textView.text)
	}
	
	func resignKeyboard() {
		txtDetails.resignFirstResponder()
	}
	
	func updateActivePanics() {
		tabbarViewController.badge.autoBadgeSize(with: "\(panicHandler.activePanicCount)")
		print("Updated Panic count from Main")
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "updatedActivePanics"), object: nil)
		print("Main disappearing...")
	}
	
    // LOCATION FUNCTIONS *******************
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        panicHandler.updatePanic(manager.location!)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
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
