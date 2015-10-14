//
//  GroupsViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/02.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import Social
import CoreLocation
//import VCFloatingActionButton

class GroupsViewController: UIViewController, UITableViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate, floatMenuDelegate {
	
	var total : Int = 0
	var privateTotal : Int = 0
	var publicTotal : Int = 0
	
	var joinGroupIdHolder : [String] = []
	var nearbyGroupIdHolder : [String] = []
	var timer : NSTimer?
	
	// Notification Bar
	
	@IBOutlet weak var viewNotificationBar: UIView!
	@IBOutlet weak var lblMessage: UILabel!
	@IBOutlet weak var spinnerNotification: UIActivityIndicatorView!
	@IBOutlet weak var layoutNotificationTop: NSLayoutConstraint!
	
	
	// Controls
	
	@IBOutlet weak var lblLoading: UILabel!
	@IBOutlet weak var tblGroups: UITableView!
	@IBOutlet weak var spinner: UIActivityIndicatorView!
	
	// Tutorial
	
	@IBOutlet weak var viewTutorial: UIVisualEffectView!
	@IBOutlet weak var viewBar: UIView!
	@IBOutlet weak var imageTap: UIImageView!
	
	var slots = global.persistantSettings.integerForKey("numberOfGroups")
	var purchaseRunning = false
	var manager: CLLocationManager!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewTutorial.hidden = true
		
		let buttonRect = CGRectMake(self.view.frame.width - 100, self.view.frame.height - 100, 65, 65)
		let floatingButton = VCFloatingActionButton(frame: buttonRect, normalImage: UIImage(named: "plus"), andPressedImage: UIImage(named: "cross"), withScrollview: tblGroups)
		floatingButton.normalImageView.frame = CGRectMake(floatingButton.normalImageView.frame.width/2 - 10, floatingButton.normalImageView.frame.height/2 - 10, 20, 20)
		floatingButton.pressedImageView.frame = CGRectMake(floatingButton.pressedImageView.frame.width/2 - 10, floatingButton.pressedImageView.frame.height/2 - 10, 20, 20)
		floatingButton.layer.cornerRadius  = 0.5 * floatingButton.frame.width
		floatingButton.layer.shadowColor = UIColor.blackColor().CGColor
		floatingButton.layer.shadowOffset = CGSizeZero
		floatingButton.layer.shadowOpacity = 0.6
		floatingButton.layer.shadowRadius = 3
		floatingButton.backgroundColor = UIColor.redColor()
		floatingButton.delegate = self
		floatingButton.hideWhileScrolling = true
		
		let optionsImages: [String] = ["create", "privateGroup", "RespondersIcon"]
		let optionsTitles = [NSLocalizedString("group_create", value: "Create your own", comment: ""), NSLocalizedString("group_join_private", value: "Join Private Group", comment: ""), NSLocalizedString("group_join_public", value: "Join a Community", comment: "")]
		floatingButton.labelArray = optionsTitles
		floatingButton.imageArray = optionsImages
		
		self.view.addSubview(floatingButton)
		
		layoutNotificationTop.constant = -viewNotificationBar.frame.height
		viewNotificationBar.layoutIfNeeded()
		
		tblGroups.layer.shadowOffset = CGSizeZero
		tblGroups.layer.shadowRadius = 10
		tblGroups.layer.shadowOpacity = 1
		
		manager = CLLocationManager()
		manager.desiredAccuracy = kCLLocationAccuracyBest
		manager.delegate = self
		manager.startUpdatingLocation()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "checkForGroupDetails", name: "gotNearbyGroups", object: nil)
	}
	
	override func viewDidAppear(animated: Bool) {
		checkForGroupDetails()
		if groupsHandler.gotGroupDetails {
			if groupsHandler.referalGroup != nil {
				if PFUser.currentUser()!["numberOfGroups"] as! Int == groupsHandler.joinedGroups.count {
					if checkIfAlreadyContainsGroup(groupsHandler.referalGroup!) == false {
						registerGroup()
					}
				}
			}
		}
	}
	
	func checkForGroupDetails() {
		println("Checked for group details")
		showNotificationBar()
		populateDataSource()
		if groupsHandler.gotGroupDetails {
			tblGroups.reloadData()
			lblLoading.hidden = true
			tblGroups.hidden = false
		}
		
		if groupsHandler.gotGroupDetails == false || groupsHandler.gotNearbyGroupDetails == false {
			NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "checkForGroupDetails", userInfo: nil, repeats: false)
		} else {
			hideNotificationBar()
		}
	}
	
//	func addGroup() {
//		tutorial.addNewGroup = true
//		tutorial.save()
//		println("Set addNewGroups to TRUE")
//		if viewTutorial.hidden == false {
//			UIView.animateWithDuration(0.5, animations: {
//				self.viewTutorial.alpha = 0.0 }, completion: {
//					(finished: Bool) -> Void in
//					self.viewTutorial.hidden = true
//			})
//		}
//		
//		if PFUser.currentUser()!["numberOfGroups"] != nil {
//			if PFUser.currentUser()!["numberOfGroups"] as! Int == tblGroups.numberOfRowsInSection(0) {
//				groupsHandler.handlePurchase(self)
//			} else if PFUser.currentUser()!["numberOfGroups"] as! Int > groupsHandler.joinedGroups.count {
//				var storyboard = UIStoryboard(name: "Main", bundle: nil)
//				var vc: AddNewGroupViewController = storyboard.instantiateViewControllerWithIdentifier("addNewGroupViewController") as! AddNewGroupViewController
//				self.presentViewController(vc, animated: true, completion: nil)
//			}
//		}
//	}
	
	func registerGroup() {
		var query = PFQuery(className: "Groups")
		query.whereKey("flatValue", equalTo: groupsHandler.referalGroup!.formatGroupForFlatValue())
		query.findObjectsInBackgroundWithBlock({
			(object : [AnyObject]?, error : NSError?) -> Void in
			if object!.count > 0 {
				let pfObject = object![0] as! PFObject
				dispatch_async(dispatch_get_main_queue(), {
					let name = pfObject["name"] as! String
					groupsHandler.addGroup(name)
					groupsHandler.joinedGroupsObject[pfObject["flatValue"] as! String] = pfObject
					global.showAlert(NSLocalizedString("successful", value: "Successful", comment: ""), message: String(format: NSLocalizedString("joined_group_text", value: "You have joined the group %@", comment: ""), arguments: [name]))
					self.tblGroups.reloadData()
				})
			} else {
				global.showAlert("", message: String(format: NSLocalizedString("group_not_exist_text", value: "The group '%@' does not exist. Check the spelling or use the New tab to create it", comment: ""), arguments: [groupsHandler.referalGroup!]))
			}
		})
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if groupsHandler.nearbyGroups.count == 0 { return 1 }
		return 2
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		var view = UIView(frame: CGRectMake(0, 0, tblGroups.frame.width, 40))
		let label = UILabel(frame: view.bounds)
		label.textAlignment = NSTextAlignment.Center
		label.font = UIFont(name: "Arial", size: 11)
		view.backgroundColor = UIColor(white: 1, alpha: 0.95)
		
		if section == 0 {
			label.text = NSLocalizedString("your_groups", value: "YOUR GROUPS", comment: "Heading for section showing the users subscribed groups")
		} else {
			label.text = NSLocalizedString("nearby", value: "NEARBY", comment: "Heading showing the groups nearby to the user")
		}
		view.addSubview(label)
		return view
	}
	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 40
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0{
			if joinGroupIdHolder.count == 0 { return 1 }
			return joinGroupIdHolder.count
		} else {
			return nearbyGroupIdHolder.count
		}
	}
	
	func populateDataSource() {
		joinGroupIdHolder = []
		for (id, group) in groupsHandler.joinedGroupsObject {
			joinGroupIdHolder.append(id)
		}
		
		nearbyGroupIdHolder = []
		for (id, group) in groupsHandler.nearbyGroupObjects {
			nearbyGroupIdHolder.append(id)
		}
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		if joinGroupIdHolder.count == 0 && indexPath.section == 0 {
			let cellNoGroups = tblGroups.dequeueReusableCellWithIdentifier("noGroups", forIndexPath: indexPath) as! UITableViewCell
			return cellNoGroups
		}
		
		var group: PFObject!
		var cell = tblGroups.dequeueReusableCellWithIdentifier("newCell", forIndexPath: indexPath) as! GroupsTableViewCell
		
		if indexPath.section == 0 {
			group = groupsHandler.joinedGroupsObject[joinGroupIdHolder[indexPath.row]]!
		} else {
			group = groupsHandler.nearbyGroupObjects[nearbyGroupIdHolder[indexPath.row]]!
		}
		var subsCount: Int!
		if group["subscriberObjects"] != nil {
			subsCount = (group["subscriberObjects"] as? [String])!.count
		} else {
			subsCount = 0
		}
		cell.object = group
		cell.subsCount = subsCount
		cell.parent = self
		cell.setup()
		
		return cell
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		for cell in tblGroups.visibleCells() {
			if cell is GroupsTableViewCell && cell.frame.size.height != 60 {
				(cell as! GroupsTableViewCell).offset(tblGroups.contentOffset.y)
			}
		}
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if joinGroupIdHolder.count == 0 && indexPath.section == 0 { return 60 }
		return 260
	}
	
	func didSelectMenuOptionAtIndex(row: Int) {
		switch(row) {
		case 0:
			//create
			let vc = storyboard?.instantiateViewControllerWithIdentifier("createNewGroupViewController") as! CreateGroupViewController
//			self.definesPresentationContext = true
			vc.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
			self.presentViewController(vc, animated: true, completion: nil)
//			addGroup()
			break
			
		case 1:
			//join private
			var inputTextField: UITextField?
			let codePrompt = UIAlertController(title: NSLocalizedString("enter_code_title", value: "Enter Code", comment: ""), message: NSLocalizedString("enter_code_text", value: "Enter the code given to you by another group member", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
			codePrompt.addAction(UIAlertAction(title: NSLocalizedString("join", value: "Join", comment: "Join a group"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
				self.showNotificationBar(text: NSLocalizedString("trying_to_join_group", value: "Trying to join group...", comment: ""))
				let query = PFQuery(className: "Groups")
				query.getObjectInBackgroundWithId(inputTextField!.text, block: {
					(result, error) -> Void in
					if error == nil {
						if result != nil {
							let group = result! as PFObject
							groupsHandler.addGroup(group["name"] as! String)
							dispatch_async(dispatch_get_main_queue(), { self.hideNotificationBar() })
						}
					} else {
						if error!.code == 101 {
							global.showAlert(NSLocalizedString("error_no_group_found_title", value: "No group found", comment: ""), message: NSLocalizedString("error_no_group_found_text", value: "No group with that code has been found. Codes are case sensitive.", comment: ""))
						} else {
							println(error)
						}
					}
				})
			}))
			codePrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
				textField.placeholder = NSLocalizedString("group_code", value: "Group Code", comment: "Placeholder asking the user to enter the group code")
				inputTextField = textField
			})
			
			codePrompt.addAction(UIAlertAction(title: NSLocalizedString("help", value: "Help", comment: ""), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
				global.showAlert(NSLocalizedString("join_private_group_help_title", value: "Joining a Private Group", comment: ""), message: NSLocalizedString("join_private_group_help_text", value: "Someone needs to share the groups private code with you in order for you to join. This code can be found by either tapping the small lock in the group or by tapping the (•••) button and selecting 'share'.", comment: ""))
			}))
			
			codePrompt.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: UIAlertActionStyle.Destructive, handler: nil))
			presentViewController(codePrompt, animated: true, completion: nil)
			break
			
		case 2:
			let vc = storyboard?.instantiateViewControllerWithIdentifier("addPublicGroupViewController") as! AddPublicGroupViewController
			vc.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
			vc.parent = self
			self.presentViewController(vc, animated: true, completion: nil)
			break
			
		default:
			break
		}
	}
	
	func checkIfAlreadyContainsGroup(groupName : String) -> Bool {
		for channel in PFInstallation.currentInstallation().channels as! [String] {
			if channel.formatGroupForFlatValue() == groupName.formatGroupForFlatValue() {
				return true
			}
		}
		return true
	}
	
	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
		if manager.location.horizontalAccuracy < 1001 {
			groupsHandler.getNearbyGroups(manager.location)
			manager.stopUpdatingLocation()
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		
	}
	
	// Notification bar
	
	func showNotificationBar(text: String = "") {
		layoutNotificationTop.constant = 0
		lblMessage.text = text
		if text == "" { spinnerNotification.startAnimating() }
		UIView.animateWithDuration(0.5, animations: {
			self.viewNotificationBar.layoutIfNeeded()
			self.tblGroups.layoutIfNeeded()
		})
	}
	
	func hideNotificationBar() {
		layoutNotificationTop.constant = -viewNotificationBar.frame.height + 20
		spinnerNotification.stopAnimating()
		UIView.animateWithDuration(0.5, animations: {
			self.viewNotificationBar.layoutIfNeeded()
			self.tblGroups.layoutIfNeeded()
		})
	}
	
	// Tutorial
	
	func animateTutorial() {
		let gesture = UITapGestureRecognizer(target: self, action: "addGroup")
		
		self.imageTap.layer.shadowColor = UIColor.whiteColor().CGColor
		self.imageTap.layer.shadowRadius = 5.0
		self.imageTap.layer.shadowOffset = CGSizeZero
		
		var animate = CABasicAnimation(keyPath: "shadowOpacity")
		animate.fromValue = 0.0
		animate.toValue = 1.0
		animate.autoreverses = true
		animate.duration = 1
		
		self.imageTap.layer.addAnimation(animate, forKey: "shadowOpacity")
		
		if tutorial.addNewGroup == false {
			let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "animateTutorial", userInfo: nil, repeats: false)
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		if timer != nil { timer!.invalidate() }
	}
}
