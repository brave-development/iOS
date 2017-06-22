//
//  MainViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/01.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import MessageUI
import CustomBadge
import SwiftyJSON

class MainViewController: UIViewController, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate {
	
	// Controls
	
	@IBOutlet var tabbarView : UIView!
	@IBOutlet var placeholderView: UIView!
	@IBOutlet var tabBarButtons: Array<UIButton>!
	@IBOutlet weak var tabbarBottomLayout: NSLayoutConstraint!
	@IBOutlet weak var sidebarLeftLayout: NSLayoutConstraint!
	@IBOutlet weak var btnHome: UIButton!
	@IBOutlet var btnLogout : UIButton!
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
		
		PFAnalytics.trackEvent(inBackground: "Logged_in", dimensions: nil, block: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.showMapBecauseOfNotification), name:NSNotification.Name(rawValue: "openedViaNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handlePush), name:NSNotification.Name(rawValue: "showMapBecauseOfHandleNotification"), object: nil)
		
		profilePic.layer.cornerRadius = 0.5 * profilePic.bounds.size.width
		profilePic.clipsToBounds = true
		
		tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MainViewController.closeSidebar))
		recognizer = UIScreenEdgePanGestureRecognizer(target: self, action:#selector(MainViewController.openSidebarGesture(_:)))
		let closeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(MainViewController.closeSidebar))
		closeRecognizer.direction = UISwipeGestureRecognizerDirection.left
		recognizer.edges = UIRectEdge.left
		recognizer.delegate = self
		
		viewSwipeRight.isUserInteractionEnabled = false
		placeholderView.addGestureRecognizer(recognizer)
		placeholderView.addGestureRecognizer(tapRecognizer)
		placeholderView.addGestureRecognizer(closeRecognizer)
		viewSidebar.addGestureRecognizer(closeRecognizer)
		
		badge = CustomBadge(string: "1000")
		badge.translatesAutoresizingMaskIntoConstraints = false
		badge.backgroundColor = UIColor.clear
		self.tabbarView.addSubview(badge)
		
		// Naming relative to badge
		let leftConstraint = NSLayoutConstraint(item: badge, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: tabBarButtons[0], attribute: NSLayoutAttribute.left, multiplier: 1, constant: -10)
		let bottomConstraint = NSLayoutConstraint(item: badge, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: tabBarButtons[0], attribute: NSLayoutAttribute.top, multiplier: 1, constant: -badge.frame.height + 10)
		
		tabbarView.addConstraint(leftConstraint)
		tabbarView.addConstraint(bottomConstraint)
		
		panicHandler.getActivePanics()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		if tutorial.swipeToOpenMenu == false {
			viewSwipeRight.isHidden = false
			animateSwipeRight()
		}
		
		if tutorial.panic == false {
			setupTutorial()
		} else if global.persistantSettings.object(forKey: "backgroundUpdatesNotice") == nil {
				// Startup notice goes here... shows only once
			global.persistantSettings.set(true, forKey: "backgroundUpdatesNotice")
		}
		
		if PFUser.current()!["name"] != nil {
			lblName.text = (PFUser.current()!["name"] as! String)
		} else {
			lblName.text = "Panic User"
		}
		
		
        if 1 == 2 { //groupsHandler.referalGroup != nil {
//			global.showAlert(groupsHandler.referalType!, message: groupsHandler.referalGroup!)
//			contacts(btnGroups)
		} else if tabBarButtons.count > 0 {
			if global.openedViaNotification == true {
				global.persistantSettings.setValue(global.notificationDictionary, forKey: "notifDict")
				print(global.notificationDictionary!)
				performSegue(withIdentifier: "customSegueMap", sender: tabBarButtons[0])
			} else {
				performSegue(withIdentifier: "customSegueMain", sender: tabBarButtons[1])
			}
		}
		closeSidebar()
	}
	
	func showMapBecauseOfNotification() {
		home(btnHome)
		performSegue(withIdentifier: "customSegueMap", sender: tabBarButtons[0])
	}
	
	@IBAction func home(_ sender: AnyObject) {
		amAtHome = true
		closeSidebar()
		
		// Showing swipeRight tutorial
		if tutorial.swipeToOpenMenu == false {
			viewSwipeRight.isHidden = false
			animateSwipeRight()
		}
		
		// Show panic tutorial
		if tutorial.panic == false {
			setupTutorial()
		}
		performSegue(withIdentifier: "customSegueMain", sender: tabBarButtons[1])
	}
	
	// Actually groups
	@IBAction func contacts(_ sender: AnyObject) {
		tutorial.groupsButton = true
		tutorial.save()
		amAtHome = false
		closeSidebar()
		performSegue(withIdentifier: "customSegueGroups", sender: sender)
	}
	
	@IBAction func history(_ sender: AnyObject) {
		amAtHome = false
		closeSidebar()
		hideTabbar()
		performSegue(withIdentifier: "customSegueHistory", sender: sender)
	}
	
	@IBAction func settings(_ sender: AnyObject) {
		amAtHome = false
		closeSidebar()
		hideTabbar()
		performSegue(withIdentifier: "customSegueSettings", sender: sender)
	}
	
	@IBAction func publicHistory(_ sender: AnyObject) {
		amAtHome = false
		closeSidebar()
		hideTabbar()
		performSegue(withIdentifier: "customSeguePublicHistory", sender: sender)
	}
	
	@IBAction func feedback(_ sender: AnyObject) {
		let mail = MFMailComposeViewController()
		if(MFMailComposeViewController.canSendMail()) {
			
			mail.mailComposeDelegate = self
			mail.setSubject("Panic - Feedback")
			mail.setToRecipients(["byron@panic-sec.org"])
			self.present(mail, animated: true, completion: nil)
		}
		else {
			global.showAlert(NSLocalizedString("error_email_title", value: "Could Not Send Email", comment: ""), message: NSLocalizedString("error_email_text", value: "Your device could not send e-mail.  Please check e-mail configuration and try again.", comment: ""))
		}
	}
	
	func openSidebarGesture(_ gesture: UIGestureRecognizer) {
		let point = gesture.location(in: self.view)
		if point.x <= viewSidebar.frame.width {
			switch (gesture.state) {
			case .ended:
				if point.x >= viewSidebar.frame.width/2 { openSidebar(true) }
				else { closeSidebar() }
				break
				
			default:
				self.sidebarLeftLayout.constant = point.x - viewSidebar.frame.width
				self.viewSidebar.layoutIfNeeded()
				self.view.layoutIfNeeded()
				break
			}
		} else {
			openSidebar(true)
		}
	}
	
	func openSidebar(_ override : Bool = false) {
		if recognizer.state == UIGestureRecognizerState.began || override == true {
			sideBarIsOpen = true
			if panicIsActive == false {
				self.sidebarLeftLayout.constant = 0
				tapRecognizer.isEnabled = true
				UIView.animate(withDuration: 0.3, animations: {
					self.viewSidebar.layoutIfNeeded()
					self.view.layoutIfNeeded()
					self.hideTabbar()
					if self.amAtHome == true {
						tutorial.swipeToOpenMenu = true
						tutorial.save()
					}
				})
				if viewSwipeRight.isHidden == false {
					UIView.animate(withDuration: 0.5, animations: {
						self.viewSwipeRight.alpha = 0.0 }, completion: {
							(finished: Bool) -> Void in
							self.viewSwipeRight.isHidden = true
							self.viewSwipeRight.alpha = 1.0
					})
				}
				if tutorial.groupsButton == false {
					if btnGroups.layer.animation(forKey: "shadowOpacity") == nil {
						animateGroupsButton()
					}
				}
			} else {
				global.showAlert("", message: NSLocalizedString("menu_not_available", value: "Menus are unavailable while an alert is active", comment: ""))
			}
		}
	}
	
	func closeSidebar() {
		sideBarIsOpen = false
		sidebarLeftLayout.constant = -viewSidebar.frame.width - 1
		tapRecognizer.isEnabled = false
		UIView.animate(withDuration: 0.3, animations: {
			self.viewSidebar.layoutIfNeeded()
			self.view.layoutIfNeeded()
			if (self.amAtHome == true) {
				self.showTabbar()
			}
		})
	}
	
	func showTabbar() {
		if panicIsActive == false {
			
			self.tabbarBottomLayout.constant = 0
			UIView.animate(withDuration: 0.3, animations: {
				self.tabbarView.layoutIfNeeded()  })
		}
	}
	func hideTabbar() {
		
		self.tabbarBottomLayout.constant = -tabbarView.frame.height-20
		UIView.animate(withDuration: 0.3, animations: {
			self.tabbarView.layoutIfNeeded() })
	}
	
	func handlePush() {
		let message = global.notificationDictionary?["aps"]["alert"].stringValue
		let alertController = UIAlertController(title: NSLocalizedString("someone_needs_help", value: "Someone needs help", comment: "Popup which shows when someone else activates and the current user is busy within the app"), message: message, preferredStyle: .alert)
		
		let cancelAction = UIAlertAction(title: NSLocalizedString("dont_respond", value: "Dont respond", comment: ""), style: .cancel) { (action) in
			global.notificationDictionary = [:]
			global.openedViaNotification = false
		}
		alertController.addAction(cancelAction)
		
		let destroyAction = UIAlertAction(title: NSLocalizedString("respond", value: "Respond", comment: ""), style: .destructive) {
			(action) in
			global.openedViaNotification = true
			self.showMapBecauseOfNotification()
		}
		alertController.addAction(destroyAction)
		
		self.present(alertController, animated: true) {
			// ...
		}
	}
	
	func back() {
		self.dismiss(animated: true, completion: nil)
	}
	
	override var shouldAutorotate : Bool {
		return true
	}
	
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		switch(result){
		case MFMailComposeResult.sent:
			print("Email sent")
			
		default:
			print("Whoops")
		}
		self.dismiss(animated: true, completion: nil)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		let availableIdentifiers = ["customSegueMain", "customSegueMap", "customSegueGroups", "customSegueHistory", "customSegueSettings", "customSeguePublicHistory"]
		
		if (availableIdentifiers.contains(segue.identifier!)) {
			
			for btn in tabBarButtons {
				btn.titleLabel?.textColor = UIColor.gray
			}
			
			let senderBtn = sender as! UIButton
			senderBtn.titleLabel?.textColor = UIColor.white
			
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
		_ = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(MainViewController.animateSwipeRight), userInfo: nil, repeats: false)
		}
	}
	
	func animateGroupsButton() {
		
		self.btnGroups.layer.shadowColor = UIColor.white.cgColor
		self.btnGroups.layer.shadowRadius = 6.0
		self.btnGroups.layer.shadowOffset = CGSize.zero
		self.btnGroups.layer.shadowOpacity = 0.0
		self.btnGroups.layer.opacity = 0.4
		
		let animateShadow = CABasicAnimation(keyPath: "shadowOpacity")
		animateShadow.fromValue = 0.0
		animateShadow.toValue = 1.0
		animateShadow.autoreverses = true
		animateShadow.duration = 0.5
		
		let animateButton = CABasicAnimation(keyPath: "opacity")
		animateButton.fromValue = 0.4
		animateButton.toValue = 1.0
		animateButton.autoreverses = true
		animateButton.duration = 0.5
		
		self.btnGroups.layer.add(animateShadow, forKey: "shadowOpacity")
		self.btnGroups.layer.add(animateButton, forKey: "opacity")
		if tutorial.groupsButton == false {
			_ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MainViewController.animateGroupsButton), userInfo: nil, repeats: false)
		} else {
			self.btnGroups.layer.opacity = 1.0
		}
	}
	
	func animateChange(_ control : AnyObject, controlLayout : NSLayoutConstraint, number : CGFloat, duration : TimeInterval = 0.3) {
		controlLayout.constant = number
		UIView.animate(withDuration: duration, animations: {
			control.layoutIfNeeded()
		})
	}
	
	// Tutorial Panic
	
	func setupTutorial() {
		btnPanic.setTitle("Activate", for: UIControlState())
		descriptionCount = 0
		lblDescription.text = NSLocalizedString("main_tut_1", value: "Tap the Activate button. For the duration of this tutorial, it will have no effect but once it's finished, the button is live.", comment: "First part of main tutorial")
		viewTutorialPanic.isHidden = false
		btnPanic.layer.cornerRadius = 0.5 * btnPanic.bounds.size.width
		btnPanic.layer.borderWidth = 2
		btnPanic.layer.borderColor = UIColor.green.cgColor
		
		btnPanic.layer.shadowOpacity = 1.0
		btnPanic.layer.shadowColor = UIColor.green.cgColor
		btnPanic.layer.shadowRadius = 4.0
		btnPanic.layer.shadowOffset = CGSize.zero
	}
	
	@IBAction func panicPressed(_ sender: AnyObject) {
		if (btnPanic.titleLabel?.text == "Activate") {
			btnPanic.setTitle("Deactivate", for: UIControlState())
			btnPanic.layer.borderColor = UIColor.red.cgColor
			btnPanic.layer.shadowColor = UIColor.red.cgColor
		} else {
			btnPanic.setTitle("Activate", for: UIControlState())
			btnPanic.layer.borderColor = UIColor.green.cgColor
			btnPanic.layer.shadowColor = UIColor.green.cgColor
		}
		descriptionCount = descriptionCount + 1
		
		switch (descriptionCount) {
		case 1:
			animateTextChange(NSLocalizedString("main_tut_2", value: "Your position would now be made available for others to track live on the map. Notifications are also sent to people subscribed to the same groups you are, alerting them of your distress.", comment: ""))
			break;
			
		case 2:
			animateTextChange(NSLocalizedString("main_tut_3", value: "When activating the Brave button, there is a 5 second delay before notifications are sent out - in case of accidental activations. This delay can be disabled in Settings.", comment: ""))
			break;
			
		case 3:
			animateTextChange(NSLocalizedString("main_tut_4", value: "Tap one more time to finish", comment: ""))
			break;
			
		case 4:
			UIView.animate(withDuration: 1.5, animations: {
				self.viewTutorialPanic.alpha = 0.0 }, completion: {
					(finished: Bool) -> Void in
					self.viewTutorialPanic.isHidden = true
					self.viewTutorialPanic.alpha = 1.0
			})
			PFAnalytics.trackEvent(inBackground: "Finished_Panic_Tut", dimensions: nil, block: nil)
			tutorial.panic = true
			tutorial.save()
			break;
			
		default:
			break;
		}
	}
	
	func animateTextChange(_ newString : String) {
		UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
			self.lblDescription.alpha = 0.0
			}, completion: {
				(finished: Bool) -> Void in
				
				//Once the label is completely invisible, set the text and fade it back in
				self.lblDescription.text = newString
				
				// Fade in
				UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
					self.lblDescription.alpha = 1.0
					}, completion: nil)
		})
	}
}
