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
	
	// Controls
	
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
		tblGroups.reloadData()
		if global.joinedGroups.count == 0 && global.referalGroup == nil { tutorial.addNewGroup = false }
		
		if global.referalGroup != nil {
			if PFUser.currentUser()!["numberOfGroups"] as! Int == global.joinedGroups.count {
				if checkIfAlreadyContainsGroup(global.referalGroup!) == false {
					handlePurchaseReferal()
				}
			} else {
				registerGroup()
			}
		}
		
		if tutorial.addNewGroup == false {
			viewTutorial.hidden = false
			animateTutorial()
		}
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
			if PFUser.currentUser()!["numberOfGroups"] as! Int == global.joinedGroups.count {
				handlePurchaseReferal()
			} else if PFUser.currentUser()!["numberOfGroups"] as! Int > global.joinedGroups.count {
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
					global.shareGroup(global.referalGroup!, viewController: self)
					global.persistantSettings.setInteger(self.slots, forKey: "numberOfGroups")
					global.persistantSettings.synchronize()
					PFUser.currentUser()!["numberOfGroups"] = global.joinedGroups.count + 1
					PFUser.currentUser()!.saveEventually(nil)
					
					self.registerGroup()
					
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
		query.whereKey("flatValue", equalTo: global.referalGroup!.formatGroupForFlatValue())
		query.findObjectsInBackgroundWithBlock({
			(object : [AnyObject]?, error : NSError?) -> Void in
			if object!.count > 0 {
				let pfObject = object![0] as! PFObject
				dispatch_async(dispatch_get_main_queue(), {
					let name = pfObject["name"] as! String
					global.addGroup(name)
					global.showAlert("Successful", message: "You have joined the group \(name)")
					self.tblGroups.reloadData()
				})
			} else {
				global.showAlert("", message: "The group '\(global.referalGroup)' does not exist. Check the spelling or use the New tab to create it")
			}
		})
	}
	
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		lblSlotsRemaining.text = "\(slots - global.joinedGroups.count)"
        return global.joinedGroups.count
        //return names.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "standard")
        cell.backgroundColor = UIColor.clearColor()
		cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.font = UIFont(name: "Heiti SC light", size: 16)
        cell.textLabel?.text = global.joinedGroups[indexPath.row]
        
        return cell
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
		
        var shareRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Share", handler:{action, indexpath in
			global.shareGroup(global.joinedGroups[indexPath.row], viewController: self)
        });
        
        shareRowAction.backgroundColor = UIColor.orangeColor()
        
        var deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:{action, indexpath in
			var deleteAlert = UIAlertController(title: "Delete", message: "Are you sure you want to leave this group?", preferredStyle: UIAlertControllerStyle.Alert)
			deleteAlert.addAction(UIAlertAction(title: "Yes", style: .Destructive, handler: { (action: UIAlertAction!) in
				global.removeGroup(global.joinedGroups[indexPath.row])
				self.tblGroups.reloadData()
				self.lblSlotsRemaining.text = "\(self.slots - global.joinedGroups.count)"
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
}
