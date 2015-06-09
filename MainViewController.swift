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
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		println(PFUser.currentUser())
		
		if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways) || (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse) {
//			locationPermission = true
		}
		
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
        
        btnPanic.layer.cornerRadius = 0.5 * btnPanic.bounds.size.width
        btnPanic.layer.borderWidth = 2
        btnPanic.layer.borderColor = UIColor.greenColor().CGColor
        
        btnPanic.layer.shadowOpacity = 1.0
        btnPanic.layer.shadowColor = UIColor.greenColor().CGColor
        btnPanic.layer.shadowRadius = 4.0
        btnPanic.layer.shadowOffset = CGSizeZero
    }
    
    @IBAction func panicPressed(sender: AnyObject) {
		tabbarViewController.closeSidebar()
		if tutorial.swipeToOpenMenu == true {
			if (btnPanic.titleLabel?.text == "Activate") {
				println("Location permission \(locationPermission)")
				if locationPermission == true {
					
					UIView.animateWithDuration(0.3, animations: {
						self.tabbarViewController.hideTabbar() })
					
					if global.panicConfirmation == true {
						
						var saveAlert = UIAlertController(title: "Activate?", message: "Activate Panic and send notifications?", preferredStyle: UIAlertControllerStyle.Alert)
						saveAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
							self.activatePanic()
						}))
						saveAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in }))
						presentViewController(saveAlert, animated: true, completion: nil)
					} else {
						activatePanic()
					}
				} else {
					global.showAlert("Location Not Allowed", message: "Please enable location services for Panic by going to Settings > Privacy > Location Services.")
				}
			} else {
				deativatePanic()
			}
		}
	}
	
    func activatePanic() {
		PFAnalytics.trackEventInBackground("Activate_Panic", dimensions: nil, block: nil)
		UIApplication.sharedApplication().idleTimerDisabled = true
		
		background.addGestureRecognizer(tapGesture)
		panicHandler.panicIsActive = true
        tabbarViewController.panicIsActive = true
        manager.startUpdatingLocation()
        btnPanic.setTitle("Deactivate", forState: UIControlState.Normal)
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
		panicHandler.panicIsActive = false
        pendingPushNotifications = false
        tabbarViewController.panicIsActive = false
        global.getLocalHistory()
		
		timer?.invalidate()
		
        UIView.animateWithDuration(0.3, animations: {
            self.tabbarViewController.showTabbar() })
        panicHandler.endPanic()
        manager.stopUpdatingLocation()
        btnPanic.setTitle("Activate", forState: UIControlState.Normal)
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
					for group in global.joinedGroups {
						var push = PFPush()
						let userName = PFUser.currentUser()!["name"] as! String
						let userNumber = PFUser.currentUser()!["cellNumber"] as! String
						var tempQuery = PFInstallation.query()
						tempQuery!.whereKey("channels", equalTo: group.formatGroupForChannel())
						tempQuery!.whereKey("installationId", notEqualTo: PFInstallation.currentInstallation().installationId)
						push.setQuery(tempQuery)
						push.expireAfterTimeInterval(18000) // 5 Hours
						push.setData(["alert" : "\(userName) needs help! Contact them on \(userNumber) or view their location in the app.", "badge" : "Increment", "sound" : "default", "lat" : manager.location.coordinate.latitude, "long" : manager.location.coordinate.longitude])
						push.sendPushInBackgroundWithBlock({
							(result : Bool, error : NSError?) -> Void in
							if result == true {
								println("Push sent to group \(group.formatGroupForChannel())")
							} else if error != nil {
								println(error)
							}
						})
					}
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
	
	func textViewDidEndEditing(textView: UITextView) {
		panicHandler.updateDetails(textView.text)
	}
	
	func resignKeyboard() {
		txtDetails.resignFirstResponder()
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
