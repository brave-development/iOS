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
	var timer: NSTimer?
	
    @IBOutlet weak var btnPanic: UIButton!
    @IBOutlet weak var background: UIImageView!
	@IBOutlet weak var txtDetails: UITextView!
	@IBOutlet weak var lblResponders: UILabel!
	@IBOutlet weak var lblRespondersLabel: UILabel!
	
	// Menu button
	
	@IBOutlet weak var viewMenuButton: UIVisualEffectView!
	
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
//		println(PFUser.currentUser())
		viewMenuButton.layer.cornerRadius = 0.5 * viewMenuButton.bounds.size.width
		viewMenuButton.clipsToBounds = true
		
		if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways) || (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse) {
//			locationPermission = true
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateActivePanics", name: "updatedActivePanics", object: nil)
		
		tapGesture = UITapGestureRecognizer(target: self, action: "resignKeyboard")
		
		txtDetails.backgroundColor = UIColor(white: 1, alpha: 0.2)
		txtDetails.layer.cornerRadius = 5
		txtDetails.delegate = self
		txtDetails.alpha = 0.0
		lblResponders.alpha = 0.0
		lblRespondersLabel.alpha = 0.0
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "pauseLocationUpdates:", name:"applicationDidEnterBackground", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "resumeLocationUpdates:", name:"applicationWillEnterForeground", object: nil)
        
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
		
		btnPanic.backgroundColor = UIColor(white: 0, alpha: 0.3)
        
        btnPanic.layer.cornerRadius = 0.5 * btnPanic.bounds.size.width
        btnPanic.layer.borderWidth = 2
        btnPanic.layer.borderColor = UIColor.greenColor().CGColor
    }
	
	@IBAction func menuButton(sender: AnyObject) {
		self.tabbarViewController.openSidebar(override: true)
	}
	
    @IBAction func panicPressed(sender: AnyObject) {
		tabbarViewController.closeSidebar()
		if tutorial.swipeToOpenMenu == true {
			if (btnPanic.titleLabel?.text == NSLocalizedString("activate", value: "Activate", comment: "Button title to activate the panic button")) {
				println("Location permission \(locationPermission)")
				if locationPermission == true {
					
					UIView.animateWithDuration(0.3, animations: {
						self.tabbarViewController.hideTabbar() })
					
					if global.panicConfirmation == true {
						
						var saveAlert = UIAlertController(title: NSLocalizedString("activate", value: "Activate", comment: "confirmation to activate the panic button"), message: NSLocalizedString("activate_confirmation_text", value: "Activate Panic and send notifications?", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
						saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
							self.activatePanic()
						}))
						saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in }))
						presentViewController(saveAlert, animated: true, completion: nil)
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
		PFAnalytics.trackEventInBackground("Activate_Panic", dimensions: nil, block: nil)
		UIApplication.sharedApplication().idleTimerDisabled = true
		
		UIView.animateWithDuration(0.3, animations: {
			self.viewMenuButton.alpha = 0.0
			}, completion: {
				(result) in
				self.viewMenuButton.hidden = true
		})
		
		background.addGestureRecognizer(tapGesture)
		panicHandler.panicIsActive = true
        tabbarViewController.panicIsActive = true
        manager.startUpdatingLocation()
        btnPanic.setTitle(NSLocalizedString("deactivate", value: "Deactivate", comment: ""), forState: UIControlState.Normal)
        btnPanic.layer.borderColor = UIColor.redColor().CGColor
        btnPanic.layer.shadowColor = UIColor.redColor().CGColor
		buttonGlow()
		timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "updateResponderCount", userInfo: nil, repeats: true)
		
		UIView.animateWithDuration(0.5, animations: {
			self.txtDetails.alpha = 1.0
			self.lblResponders.alpha = 1.0
			self.lblRespondersLabel.alpha = 1.0
		})
        
        if pendingPushNotifications == false {
            pendingPushNotifications = true
                if global.panicConfirmation == true {
                    sendNotification()
                } else {
                    let timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "sendNotification", userInfo: nil, repeats: false)
                }
        }
    }
    
    func deativatePanic() {
		UIApplication.sharedApplication().idleTimerDisabled = false
		background.removeGestureRecognizer(tapGesture)
		
		self.viewMenuButton.hidden = false
		UIView.animateWithDuration(0.3, animations: {
			self.viewMenuButton.alpha = 1.0
		})
		
		panicHandler.panicIsActive = false
        pendingPushNotifications = false
        tabbarViewController.panicIsActive = false
        global.getLocalHistory()
		
		timer?.invalidate()
		
        UIView.animateWithDuration(0.3, animations: {
            self.tabbarViewController.showTabbar() })
        panicHandler.endPanic()
        manager.stopUpdatingLocation()
        btnPanic.setTitle(NSLocalizedString("activate", value: "Activate", comment: "Button title to activate the panic button"), forState: UIControlState.Normal)
        btnPanic.layer.borderColor = UIColor.greenColor().CGColor
        btnPanic.layer.shadowColor = UIColor.greenColor().CGColor
		UIView.animateWithDuration(0.5, animations: {
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
			UIView.animateWithDuration(2, animations: {
				self.btnPanic.layer.shadowRadius = 8
				}, completion: {
					(result) in
					UIView.animateWithDuration(2, animations: {
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
    
    func sendNotification() {
		println("In sendNotificaion method")
		var dict = NSDictionary(dictionary: ["badge":"Increment"])
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
				println("Canceled Notifications")
			}
		} else {
			NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "sendNotification", userInfo: nil, repeats: false)
		}
    }
	
	func sendNotification(group: String?) {
		var push = PFPush()
		let userName = PFUser.currentUser()!["name"] as! String
		let userNumber = PFUser.currentUser()!["cellNumber"] as! String
		var tempQuery = PFInstallation.query()
		if group != nil {
			tempQuery!.whereKey("channels", equalTo: group!.formatGroupForChannel())
		} else {
			tempQuery!.whereKey("channels", equalTo: "panic_global")
		}
		tempQuery!.whereKey("installationId", notEqualTo: PFInstallation.currentInstallation().installationId)
		push.setQuery(tempQuery)
		push.expireAfterTimeInterval(18000) // 5 Hours
		let panicMessage = String(format: NSLocalizedString("panic_notification_message", value: "%@ needs help! Contact them on %@ or view their location in the app.", comment: ""), arguments: [userName, userNumber])
		push.setData(["alert" : panicMessage, "badge" : "Increment", "sound" : "default", "lat" : manager.location.coordinate.latitude, "long" : manager.location.coordinate.longitude])
		push.sendPushInBackgroundWithBlock({
			(result : Bool, error : NSError?) -> Void in
			if result == true {
				println("Push sent to group \(group?.formatGroupForChannel())")
			} else if error != nil {
				println(error)
			}
		})
	}
	
	func textViewDidEndEditing(textView: UITextView) {
		panicHandler.updateDetails(textView.text)
	}
	
	func resignKeyboard() {
		txtDetails.resignFirstResponder()
	}
	
	func updateActivePanics() {
		tabbarViewController.badge.autoBadgeSizeWithString("\(panicHandler.activePanicCount)")
		println("Updated panic count from Main")
	}
	
	override func viewWillDisappear(animated: Bool) {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "updatedActivePanics", object: nil)
		println("Main disappearing...")
	}
	
    // LOCATION FUNCTIONS *******************
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        panicHandler.updatePanic(manager.location)
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if global.didChangeAuthStatus(manager, status: status) == true {
			locationPermission = true
		} else {
			locationPermission = false
		}
    }
	
	func pauseLocationUpdates(notification: NSNotification) {
		println("PAUSED from NC")
		manager.stopUpdatingLocation()
	}
	
	func resumeLocationUpdates(notification: NSNotification) {
		println("RESUMED from NC")
		manager.startUpdatingLocation()
	}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
