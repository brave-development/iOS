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

class GroupsViewController: UIViewController, UITableViewDelegate {
	
	var total : Int = 0
	var privateTotal : Int = 0
	var publicTotal : Int = 0
	
	var joinGroupIdHolder : [String] = []
	var timer : NSTimer?
	
	// Controls
	
	@IBOutlet weak var lblLoading: UILabel!
	@IBOutlet weak var lblPrivateTotal: UILabel!
	@IBOutlet weak var lblTotal: UILabel!
	@IBOutlet weak var lblPublicTotal: UILabel!
    @IBOutlet weak var tblGroups: UITableView!
	@IBOutlet weak var btnAdd: UIButton!
	@IBOutlet weak var lblDescription: UILabel!
	@IBOutlet weak var lblSlotsRemaining: UILabel!
	
	// Tutorial
	
	@IBOutlet weak var viewTutorial: UIVisualEffectView!
	@IBOutlet weak var imageTap: UIImageView!
	
	var slots = global.persistantSettings.integerForKey("numberOfGroups")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewDidAppear(animated: Bool) {
		checkForGroupDetails()
		if groupsHandler.gotGroupDetails {
			if groupsHandler.referalGroup != nil {
				if PFUser.currentUser()!["numberOfGroups"] as! Int == groupsHandler.joinedGroups.count {
					if checkIfAlreadyContainsGroup(groupsHandler.referalGroup!) == false {
						registerGroup()
					}
				} else {
					
				}
			}
		}
		
		if tutorial.addNewGroup == false {
			viewTutorial.hidden = false
			animateTutorial()
		}
	}
	
	func checkForGroupDetails() {
		println("Checked for group details")
		if groupsHandler.gotGroupDetails {
			lblLoading.hidden = true
			tblGroups.reloadData()
			tblGroups.hidden = false
			if timer != nil && tblGroups.hidden == false && lblLoading.hidden == true {
				timer!.invalidate() }
			updateHeaderNumbers()
		}  else {
			println("Start timer")
			println(groupsHandler.joinedGroupsObject)
			lblLoading.hidden = false
			timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "checkForGroupDetails", userInfo: nil, repeats: false)
		}
	}
	
	func updateHeaderNumbers() {
		privateTotal = 0
		publicTotal = 0
		total = 0
		
		for (id, group) in groupsHandler.joinedGroupsObject {
			var subsCount = 1
			if group["subscriberObjects"] != nil {
				subsCount = (group["subscriberObjects"] as? [String])!.count
			}
			if (group["public"] as? Bool) == true {
				if subsCount > 2 { publicTotal += 12 } // LOL
				publicTotal += subsCount
			} else {
				privateTotal += subsCount
			}
		}
		
		lblPrivateTotal.text = "\(privateTotal)"
		lblPublicTotal.text = "\(publicTotal)"
		lblTotal.text = "\(privateTotal + publicTotal)"
	}
    
    @IBAction func addGroup(sender: AnyObject) {
		tutorial.addNewGroup = true
		tutorial.save()
		println("Set addNewGroups to TRUE")
		if viewTutorial.hidden == false {
			UIView.animateWithDuration(0.5, animations: {
				self.viewTutorial.alpha = 0.0 }, completion: {
					(finished: Bool) -> Void in
					self.viewTutorial.hidden = true
			})
		}
		
		if PFUser.currentUser()!["numberOfGroups"] != nil {
			if PFUser.currentUser()!["numberOfGroups"] as! Int == groupsHandler.joinedGroups.count {
				handlePurchaseReferal()
			} else if PFUser.currentUser()!["numberOfGroups"] as! Int > groupsHandler.joinedGroups.count {
				var storyboard = UIStoryboard(name: "Main", bundle: nil)
				var vc: AddNewGroupViewController = storyboard.instantiateViewControllerWithIdentifier("addNewGroupViewController") as! AddNewGroupViewController
				self.presentViewController(vc, animated: true, completion: nil)
			}
		}
    }
	
	func handlePurchaseReferal() {
		var saveAlert = UIAlertController(title: "Purchase additional group slot", message: "You need to purchase extra group slots in order to join more groups", preferredStyle: UIAlertControllerStyle.Alert)
		saveAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
			PFPurchase.buyProduct("SoC.Panic.groupPurchaseConsumable", block: {
				(error: NSError!) -> Void in
				NSLog("%s", "IAP") ///====
				if error == nil {
					
					let data = ["CurrentNumber" : "\(self.slots)"]
					PFAnalytics.trackEventInBackground("Group_Purchases", dimensions: data, block: nil)
					
					NSLog("%s", "BOUGHT GROUP") /// =====
					println("BOUGHT ADD GROUP")
					++self.slots
					global.persistantSettings.setInteger(self.slots, forKey: "numberOfGroups")
					global.persistantSettings.synchronize()
					PFUser.currentUser()!["numberOfGroups"] = groupsHandler.joinedGroups.count + 1
					PFUser.currentUser()!.saveEventually(nil)
					
					if groupsHandler.referalGroup != nil {
						groupsHandler.shareGroup(groupsHandler.referalGroup!, viewController: self)
						self.registerGroup()
					}
					
				} else {
					NSLog("%s", "\(error)") /// ========
					if error.localizedDescription != "" {
						global.showAlert("Unsuccessful", message: error.localizedDescription)
					} else {
						global.showAlert("Unsuccessful", message: "Your purchase was unsuccessful. Please try again. No money has been debited from your account.")
					}
					println("FAILED PURCHASE -- \(error)")
				}
			})
		}))
		saveAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in }))
		presentViewController(saveAlert, animated: true, completion: nil)
	}
	
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
					global.showAlert("Successful", message: "You have joined the group \(name)")
					self.tblGroups.reloadData()
				})
			} else {
				global.showAlert("", message: "The group '\(groupsHandler.referalGroup)' does not exist. Check the spelling or use the New tab to create it")
			}
		})
	}
	
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if groupsHandler.gotGroupDetails {
			lblSlotsRemaining.text = "\(slots - groupsHandler.joinedGroups.count)"
			joinGroupIdHolder = []
			for (id, group) in groupsHandler.joinedGroupsObject {
				joinGroupIdHolder.append(id)
			}
			return groupsHandler.joinedGroups.count
		}
		return 0
        //return names.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let group = groupsHandler.joinedGroupsObject[joinGroupIdHolder[indexPath.row]]!
		var subsCount = (group["subscriberObjects"] as? [String])!.count
		
		var cell = tblGroups.dequeueReusableCellWithIdentifier("NewCell", forIndexPath: indexPath) as! GroupsTableViewCell
		cell.lblName.text = group["name"] as? String
		cell.lblCountry.text = group["country"] as? String
		cell.lblSubs.text = "\(subsCount)"
		
		if (group["public"] as? Bool) == true {
			if subsCount > 2 { subsCount += 12 }
			cell.lblSubs.text = "\(subsCount)"
			cell.viewBar.backgroundColor = UIColor(red: 40/255, green: 185/255, blue: 38/255, alpha: 1)
		} else {
//			privateTotal += subsCount
			cell.viewBar.backgroundColor = UIColor(red: 14/255, green: 142/255, blue: 181/255, alpha: 1)
		}
		
        return cell
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
		let group = groupsHandler.joinedGroupsObject[joinGroupIdHolder[indexPath.row]]!
        var shareRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Share", handler:{action, indexpath in
			groupsHandler.shareGroup(groupsHandler.joinedGroups[indexPath.row], viewController: self)
        });
		
        var deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:{action, indexpath in
			var deleteAlert = UIAlertController(title: "Delete", message: "Are you sure you want to leave this group?", preferredStyle: UIAlertControllerStyle.Alert)
			deleteAlert.addAction(UIAlertAction(title: "Yes", style: .Destructive, handler: { (action: UIAlertAction!) in
				println(groupsHandler.joinedGroups[indexPath.row])
				println(group["flatValue"] as! String)
				groupsHandler.removeGroup(groupsHandler.joinedGroups[find(groupsHandler.joinedGroups, group["name"] as! String)!])
				groupsHandler.joinedGroupsObject[group["flatValue"] as! String] = nil
				self.updateHeaderNumbers()
				self.tblGroups.reloadData()
				self.lblSlotsRemaining.text = "\(self.slots - groupsHandler.joinedGroups.count)"
			}))
			deleteAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in }))
			self.presentViewController(deleteAlert, animated: true, completion: nil)
        });
		
        return [shareRowAction, deleteRowAction];
    }
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let currentLabelValue = lblDescription.text
		
		// Fade out
		UIView.animateWithDuration(0.3, animations: {
			self.lblDescription.alpha = 0.0
			}, completion: {
				
				// Change text and fade in
				(finished: Bool) -> Void in
				self.lblDescription.text = "Swipe for more options"
				UIView.animateWithDuration(0.3, animations: {
				self.lblDescription.alpha = 1.0
					}, completion: {
						(finished: Bool) -> Void in
						
						// Fade out after 2 second delay
						UIView.animateWithDuration(0.3, delay: 2, options: nil, animations: {
							self.lblDescription.alpha = 0.0
							}, completion: {
								(finished: Bool) -> Void in
								self.lblDescription.text = currentLabelValue
								
								// Fade back in with original text
								UIView.animateWithDuration(0.3, animations: {
									self.lblDescription.alpha = 1.0
									})
						})
					})
		})
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 80
	}
	
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) { }
	
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
	
	func checkIfAlreadyContainsGroup(groupName : String) -> Bool {
		for channel in global.installation.channels as! [String] {
			if channel.formatGroupForFlatValue() == groupName.formatGroupForFlatValue() {
				return true
			}
		}
		return true
	}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
	
	// Tutorial
	
	func animateTutorial() {
		self.imageTap.layer.shadowColor = UIColor.whiteColor().CGColor
		self.imageTap.layer.shadowRadius = 5.0
		self.imageTap.layer.shadowOffset = CGSizeZero
		
		self.btnAdd.layer.shadowColor = UIColor.whiteColor().CGColor
		self.btnAdd.layer.shadowRadius = 5.0
		self.btnAdd.layer.shadowOffset = CGSizeZero
		
		var animate = CABasicAnimation(keyPath: "shadowOpacity")
		animate.fromValue = 0.0
		animate.toValue = 1.0
		animate.autoreverses = true
		animate.duration = 1
		
		self.imageTap.layer.addAnimation(animate, forKey: "shadowOpacity")
		self.btnAdd.layer.addAnimation(animate, forKey: "shadowOpacity")
		
		if tutorial.addNewGroup == false {
			let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "animateTutorial", userInfo: nil, repeats: false)
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		if timer != nil { timer!.invalidate() }
	}
}
