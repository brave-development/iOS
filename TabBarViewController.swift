//
//  TabBarViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/01.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import MessageUI

class TabBarViewController: UIViewController, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate {
	
	// Controls
	
	@IBOutlet var tabbarView : UIView!
	@IBOutlet var placeholderView: UIView!
	@IBOutlet var tabBarButtons: Array<UIButton>!
	@IBOutlet weak var tabbarBottomLayout: NSLayoutConstraint!
	@IBOutlet weak var sidebarLeftLayout: NSLayoutConstraint!
	@IBOutlet weak var btnHome: UIButton!
	@IBOutlet var btnLogout : UIButton!
//	@IBOutlet weak var btnMenu: UIButton!
	@IBOutlet weak var viewSidebar: UIView!
	@IBOutlet weak var profilePic: UIImageView!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var btnGroups: UIButton!
	
	// Tutorial
	
	@IBOutlet weak var viewSwipeRight: UIVisualEffectView!
	@IBOutlet weak var imageSwipeRight: UIImageView!
	@IBOutlet weak var layoutLeftSwipeRight: NSLayoutConstraint!
	
	// Tutorial Panic Button
	
	@IBOutlet weak var viewTutorialPanic: UIVisualEffectView!
	@IBOutlet weak var btnPanic: UIButton!
	@IBOutlet weak var lblDescription: UILabel!
	var descriptionCount = 0
	
	// Variables
	
	var panicIsActive : Bool = false
	var sideBarIsOpen : Bool = false
	var currentViewController: UIViewController?
	var recognizer : UIScreenEdgePanGestureRecognizer!
	var amAtHome: Bool = true
	var tapRecognizer : UITapGestureRecognizer!
	var badge: CustomBadge!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		PFAnalytics.trackEventInBackground("Logged_in", dimensions: nil, block: nil)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "showMapBecauseOfNotification", name:"openedViaNotification", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handlePush", name:"showMapBecauseOfHandleNotification", object: nil)
		
		profilePic.layer.cornerRadius = 0.5 * profilePic.bounds.size.width
		profilePic.clipsToBounds = true
		
		tapRecognizer = UITapGestureRecognizer(target: self, action: "closeSidebar")
		recognizer = UIScreenEdgePanGestureRecognizer(target: self, action:Selector("openSidebarGesture"))
		let closeRecognizer = UISwipeGestureRecognizer(target: self, action: "closeSidebar")
		closeRecognizer.direction = UISwipeGestureRecognizerDirection.Left
		recognizer.edges = UIRectEdge.Left
		recognizer.delegate = self
		
		viewSwipeRight.userInteractionEnabled = false
		placeholderView.addGestureRecognizer(recognizer)
		placeholderView.addGestureRecognizer(tapRecognizer)
		placeholderView.addGestureRecognizer(closeRecognizer)
		
		badge = CustomBadge(string: "1000")
		badge.setTranslatesAutoresizingMaskIntoConstraints(false)
		badge.backgroundColor = UIColor.clearColor()
		self.tabbarView.addSubview(badge)
		
		// Naming relative to badge
		let leftConstraint = NSLayoutConstraint(item: badge, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: tabBarButtons[0], attribute: NSLayoutAttribute.Left, multiplier: 1, constant: -10)
		let bottomConstraint = NSLayoutConstraint(item: badge, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: tabBarButtons[0], attribute: NSLayoutAttribute.Top, multiplier: 1, constant: -badge.frame.height + 10)
		
		tabbarView.addConstraint(leftConstraint)
		tabbarView.addConstraint(bottomConstraint)
		
		panicHandler.getActivePanics()
	}
	
	override func viewDidAppear(animated: Bool) {
		
		if tutorial.swipeToOpenMenu == false {
			viewSwipeRight.hidden = false
			animateSwipeRight()
		}
		
		if tutorial.panic == false {
			setupTutorial()
		} else if global.persistantSettings.objectForKey("backgroundUpdatesNotice") == nil {
				global.showAlert("NEW: Background Updates", message: "Panic supports background location updates in emergencies. This simply means the app no longer needs to remain open and your phone awake for your location to be tracked.\nThis feature must be turned on from the settings menu within the app (via the side menu)")
			global.persistantSettings.setBool(true, forKey: "backgroundUpdatesNotice")
		}
		
		if PFUser.currentUser()!["name"] != nil {
			lblName.text = (PFUser.currentUser()!["name"] as! String)
		} else {
			lblName.text = "Panic User"
		}
		
		
		if groupsHandler.referalGroup != nil {
			global.showAlert(groupsHandler.referalType!, message: groupsHandler.referalGroup!)
			contacts(btnGroups)
		} else if tabBarButtons.count > 0 {
			if global.openedViaNotification == true {
				global.persistantSettings.setValue(global.notificationDictionary, forKey: "notifDict")
				println(global.notificationDictionary)
				performSegueWithIdentifier("customSegueMap", sender: tabBarButtons[0])
			} else {
				performSegueWithIdentifier("customSegueMain", sender: tabBarButtons[1])
			}
		}
		closeSidebar()
	}
	
	func showMapBecauseOfNotification() {
		home(btnHome)
		performSegueWithIdentifier("customSegueMap", sender: tabBarButtons[0])
	}
	
	@IBAction func home(sender: AnyObject) {
		amAtHome = true
		closeSidebar()
		
		// Showing swipeRight tutorial
		if tutorial.swipeToOpenMenu == false {
			viewSwipeRight.hidden = false
			animateSwipeRight()
		}
		
		// Show panic tutorial
		if tutorial.panic == false {
			setupTutorial()
		}
		performSegueWithIdentifier("customSegueMain", sender: tabBarButtons[1])
	}
	
	// Actually groups
	@IBAction func contacts(sender: AnyObject) {
		tutorial.groupsButton = true
		tutorial.save()
		amAtHome = false
		closeSidebar()
		performSegueWithIdentifier("customSegueGroups", sender: sender)
	}
	
	@IBAction func history(sender: AnyObject) {
		amAtHome = false
		closeSidebar()
		hideTabbar()
		performSegueWithIdentifier("customSegueHistory", sender: sender)
	}
	
	@IBAction func settings(sender: AnyObject) {
		amAtHome = false
		closeSidebar()
		hideTabbar()
		performSegueWithIdentifier("customSegueSettings", sender: sender)
	}
	
	@IBAction func publicHistory(sender: AnyObject) {
		amAtHome = false
		closeSidebar()
		hideTabbar()
		performSegueWithIdentifier("customSeguePublicHistory", sender: sender)
	}
	
	@IBAction func feedback(sender: AnyObject) {
		var mail = MFMailComposeViewController()
		if(MFMailComposeViewController.canSendMail()) {
			
			mail.mailComposeDelegate = self
			mail.setSubject("Panic - Feedback")
			mail.setToRecipients(["byron@panic-sec.org"])
			self.presentViewController(mail, animated: true, completion: nil)
		}
		else {
			global.showAlert("Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.")
		}
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
	
	func openSidebarGesture() {
		openSidebar()
	}
	
	func openSidebar(override : Bool = false) {
		if recognizer.state == UIGestureRecognizerState.Began || override == true {
			sideBarIsOpen = true
			if panicIsActive == false {
				self.sidebarLeftLayout.constant = 0
				tapRecognizer.enabled = true
				UIView.animateWithDuration(0.3, animations: {
					self.viewSidebar.layoutIfNeeded()
					self.hideTabbar()
					if self.amAtHome == true {
						tutorial.swipeToOpenMenu = true
						tutorial.save()
					}
				})
				if viewSwipeRight.hidden == false {
					UIView.animateWithDuration(0.5, animations: {
						self.viewSwipeRight.alpha = 0.0 }, completion: {
							(finished: Bool) -> Void in
							self.viewSwipeRight.hidden = true
							self.viewSwipeRight.alpha = 1.0
					})
				}
				if tutorial.groupsButton == false {
					if btnGroups.layer.animationForKey("shadowOpacity") == nil {
						animateGroupsButton()
					}
				}
			} else {
				global.showAlert("Not available", message: "Menus are unavailable while Panic is active")
			}
		}
	}
	
	func closeSidebar() {
		sideBarIsOpen = false
		self.sidebarLeftLayout.constant = -self.viewSidebar.frame.width - 1
		tapRecognizer.enabled = false
		UIView.animateWithDuration(0.3, animations: {
			self.viewSidebar.layoutIfNeeded()
			if (self.amAtHome == true) {
				self.showTabbar()
			}
		})
	}
	
	func showTabbar() {
		if panicIsActive == false {
			
			self.tabbarBottomLayout.constant = 0
			UIView.animateWithDuration(0.3, animations: {
				self.tabbarView.layoutIfNeeded()  })
		}
	}
	func hideTabbar() {
		
		self.tabbarBottomLayout.constant = -tabbarView.frame.height
		UIView.animateWithDuration(0.3, animations: {
			self.tabbarView.layoutIfNeeded() })
	}
	
	func handlePush() {
		let message = global.notificationDictionary!["aps"]!["alert"] as! String
		let alertController = UIAlertController(title: "Someone needs help", message: message, preferredStyle: .Alert)
		
		let cancelAction = UIAlertAction(title: "Dont respond", style: .Cancel) { (action) in
			global.notificationDictionary = [:]
			global.openedViaNotification = false
		}
		alertController.addAction(cancelAction)
		
		let destroyAction = UIAlertAction(title: "Respond", style: .Destructive) {
			(action) in
			global.openedViaNotification = true
			self.showMapBecauseOfNotification()
		}
		alertController.addAction(destroyAction)
		
		self.presentViewController(alertController, animated: true) {
			// ...
		}
	}
	
	func back() {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func shouldAutorotate() -> Bool {
		return true
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		
		let availableIdentifiers = ["customSegueMain", "customSegueMap", "customSegueGroups", "customSegueHistory", "customSegueSettings", "customSeguePublicHistory"]
		
		if(contains(availableIdentifiers, segue.identifier!)) {
			
			for btn in tabBarButtons {
				btn.titleLabel?.textColor = UIColor.grayColor()
			}
			
			let senderBtn = sender as! UIButton
			senderBtn.titleLabel?.textColor = UIColor.whiteColor()
			
			if (segue.identifier != "customSegueMain" && segue.identifier != "customSegueMap") {
				hideTabbar()
			}
		}
	}
	
	// Tutorial
	
	func animateSwipeRight() {
		layoutLeftSwipeRight.constant = 8
		imageSwipeRight.layoutIfNeeded()
		animateChange(imageSwipeRight, controlLayout: layoutLeftSwipeRight, number: self.view.bounds.width - imageSwipeRight.bounds.width - 8, duration: 2)
		if tutorial.swipeToOpenMenu == false {
		let timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "animateSwipeRight", userInfo: nil, repeats: false)
		}
	}
	
	func animateGroupsButton() {
		
		self.btnGroups.layer.shadowColor = UIColor.whiteColor().CGColor
		self.btnGroups.layer.shadowRadius = 6.0
		self.btnGroups.layer.shadowOffset = CGSizeZero
		self.btnGroups.layer.shadowOpacity = 0.0
		self.btnGroups.layer.opacity = 0.4
		
		var animateShadow = CABasicAnimation(keyPath: "shadowOpacity")
		animateShadow.fromValue = 0.0
		animateShadow.toValue = 1.0
		animateShadow.autoreverses = true
		animateShadow.duration = 0.5
		
		var animateButton = CABasicAnimation(keyPath: "opacity")
		animateButton.fromValue = 0.4
		animateButton.toValue = 1.0
		animateButton.autoreverses = true
		animateButton.duration = 0.5
		
		self.btnGroups.layer.addAnimation(animateShadow, forKey: "shadowOpacity")
		self.btnGroups.layer.addAnimation(animateButton, forKey: "opacity")
		if tutorial.groupsButton == false {
			let timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "animateGroupsButton", userInfo: nil, repeats: false)
		} else {
			self.btnGroups.layer.opacity = 1.0
		}
	}
	
	func animateChange(control : AnyObject, controlLayout : NSLayoutConstraint, number : CGFloat, duration : NSTimeInterval = 0.3) {
		controlLayout.constant = number
		UIView.animateWithDuration(duration, animations: {
			control.layoutIfNeeded()
		})
	}
	
	// Tutorial Panic
	
	func setupTutorial() {
		btnPanic.setTitle("Activate", forState: UIControlState.Normal)
		descriptionCount = 0
		lblDescription.text = "Tap the Panic button. For the duration of this tutorial, it will have no effect but once it's finished, the button is live."
		viewTutorialPanic.hidden = false
		btnPanic.layer.cornerRadius = 0.5 * btnPanic.bounds.size.width
		btnPanic.layer.borderWidth = 2
		btnPanic.layer.borderColor = UIColor.greenColor().CGColor
		
		btnPanic.layer.shadowOpacity = 1.0
		btnPanic.layer.shadowColor = UIColor.greenColor().CGColor
		btnPanic.layer.shadowRadius = 4.0
		btnPanic.layer.shadowOffset = CGSizeZero
	}
	
	@IBAction func panicPressed(sender: AnyObject) {
		if (btnPanic.titleLabel?.text == "Activate") {
			btnPanic.setTitle("Deactivate", forState: UIControlState.Normal)
			btnPanic.layer.borderColor = UIColor.redColor().CGColor
			btnPanic.layer.shadowColor = UIColor.redColor().CGColor
		} else {
			btnPanic.setTitle("Activate", forState: UIControlState.Normal)
			btnPanic.layer.borderColor = UIColor.greenColor().CGColor
			btnPanic.layer.shadowColor = UIColor.greenColor().CGColor
		}
		descriptionCount = descriptionCount + 1
		
		switch (descriptionCount) {
		case 1:
			animateTextChange("In this state, your position is made available for others to track live on the map. Notifications are also sent to people subscribed to the same groups you are, alerting them of your distress.")
			break;
			
		case 2:
			animateTextChange("When activating the Panic button, there is a 5 second time delay before notifications are sent out - in case of accidental activations. This delay can be disabled in Settings by choosing to have a confirmation each time it is activated.")
			break;
			
		case 3:
			animateTextChange("Tap one more time to finish")
			break;
			
		case 4:
			UIView.animateWithDuration(1.5, animations: {
				self.viewTutorialPanic.alpha = 0.0 }, completion: {
					(finished: Bool) -> Void in
					self.viewTutorialPanic.hidden = true
					self.viewTutorialPanic.alpha = 1.0
			})
			PFAnalytics.trackEventInBackground("Finished_Panic_Tut", dimensions: nil, block: nil)
			tutorial.panic = true
			tutorial.save()
			break;
			
		default:
			break;
		}
	}
	
	func animateTextChange(newString : String) {
		UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			self.lblDescription.alpha = 0.0
			}, completion: {
				(finished: Bool) -> Void in
				
				//Once the label is completely invisible, set the text and fade it back in
				self.lblDescription.text = newString
				
				// Fade in
				UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
					self.lblDescription.alpha = 1.0
					}, completion: nil)
		})
	}
}
