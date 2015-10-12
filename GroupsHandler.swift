//
//  GroupsHandler.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/06/11.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import Social

var groupsHandler : GroupsHandler = GroupsHandler()

class GroupsHandler: UIViewController {
	
	var joinedGroups : [String] = []
	var joinedGroupsObject: [String : PFObject] = [:]
	var nearbyGroups : [String] = []
	var nearbyGroupObjects : [String : PFObject] = [:]
	
	// Referals
	
	var referalType : String?
	var referalGroup : String?
	var referalMember : String?
	
	// Trackers
	
	var gotGroupDetails : Bool = false
	var gotNearbyGroupDetails : Bool = false
	var imagesFetched = false
	var purchaseRunning = false
	
	func getGroups() {
		let user = PFUser.currentUser()!
		if user["groups"] != nil {
			for group in user["groups"] as! [String] {
				if find(joinedGroups, group) == nil {
					joinedGroups.append(group)
				}
			}
		} else {
			joinedGroups = []
			gotGroupDetails = true
		}
		
		var groupFormatted : [String] = []
		for group in joinedGroups {
			groupFormatted.append(group.formatGroupForChannel())
		}
		updateGroups()
		getGroupDetails(nil)
		PFInstallation.currentInstallation().setObject([""], forKey: "channels")
		PFInstallation.currentInstallation().addUniqueObjectsFromArray(groupFormatted, forKey: "channels")
		PFInstallation.currentInstallation().saveInBackgroundWithBlock(nil)
	}
	
	func getNearbyGroups(location : CLLocation, refresh: Bool = false) {
		if nearbyGroupObjects.isEmpty || refresh == true {
			nearbyGroupObjects = [:]
			nearbyGroups = []
			gotNearbyGroupDetails = false
			let currentGroups = PFUser.currentUser()!["groups"] as! [String]
			var queryHistory = PFQuery(className: "Groups")
			queryHistory.whereKey("location", nearGeoPoint: PFGeoPoint(location: location), withinKilometers: 5000)
			queryHistory.whereKey("public", equalTo: true)
			queryHistory.whereKey("name", notContainedIn: currentGroups)
			queryHistory.limit = 2
			queryHistory.findObjectsInBackgroundWithBlock({
				(objects : [AnyObject]?, error : NSError?) -> Void in
				if error == nil {
					println(objects)
					self.nearbyGroups = []
					for objectRaw in objects! {
						let object = objectRaw as! PFObject
						self.nearbyGroups.append(object["flatValue"] as! String)
						self.nearbyGroupObjects[object["flatValue"] as! String] = object
					}
					NSNotificationCenter.defaultCenter().postNotificationName("gotNearbyGroups", object: nil)
				} else {
					println(error)
				}
				if self.nearbyGroups.count == self.nearbyGroupObjects.count {
					self.gotNearbyGroupDetails = true
				}
			})
			println(location)
		}
	}
	
	// Pass nil for all groups
	func getGroupDetails(groupName : String?) {
		self.gotGroupDetails = false
		var groupArray : [String] = []
		if groupName == nil {
			groupArray = joinedGroups
			if groupArray.isEmpty { gotGroupDetails = true }
		} else {
			groupArray = [groupName!]
			joinedGroups.append(groupName!)
		}
		
		for group in groupArray {
			var queryHistory = PFQuery(className: "Groups")
			queryHistory.whereKey("flatValue", equalTo: group.formatGroupForFlatValue())
			queryHistory.findObjectsInBackgroundWithBlock({
				(objects : [AnyObject]?, error : NSError?) -> Void in
				if error == nil {
					for objectRaw in objects! {
						let object = objectRaw as! PFObject
						object.addUniqueObject(PFUser.currentUser()!.objectId!, forKey: "subscriberObjects")
						object.saveInBackgroundWithBlock(nil)
						self.joinedGroupsObject[object["flatValue"] as! String] = object
					}
				} else {
					println(error)
				}
				if self.joinedGroups.count == self.joinedGroupsObject.count {
					self.gotGroupDetails = true
				}
			})
		}
	}
	
	func handlePurchase(parent: GroupsViewController) {
		var saveAlert = UIAlertController(title: "Purchase additional group slot", message: "You need to purchase extra group slots in order to join more groups", preferredStyle: UIAlertControllerStyle.Alert)
		saveAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
			NSNotificationCenter.defaultCenter().postNotificationName("purchaseStarted", object: nil)
			self.purchaseRunning = true
			global.showAlert("Please wait", message: "Processing your request. Please be patient.")
			PFPurchase.buyProduct("SoC.Panic.groupPurchaseConsumable", block: {
				(error: NSError!) -> Void in
				if error == nil {
					
//					PFAnalytics.trackEventInBackground("Group_Purchases", dimensions: nil, block: nil)
//					
					println("BOUGHT ADD GROUP")
					global.persistantSettings.synchronize()
					PFUser.currentUser()!["numberOfGroups"] = groupsHandler.joinedGroups.count + 1
					PFUser.currentUser()!.saveEventually(nil)
					NSNotificationCenter.defaultCenter().postNotificationName("purchaseSuccessful", object: nil)
//					if groupsHandler.referalGroup != nil {
//						groupsHandler.shareGroup(groupsHandler.referalGroup!, viewController: self)
//					}
				} else {
					NSNotificationCenter.defaultCenter().postNotificationName("purchaseFail", object: nil)
					if error.localizedDescription != "" {
						global.showAlert("Unsuccessful", message: error.localizedDescription)
					} else {
						global.showAlert("Unsuccessful", message: "Your purchase was unsuccessful. Please try again. No money has been debited from your account.")
					}
					println("FAILED PURCHASE -- \(error)")
				}
				NSNotificationCenter.defaultCenter().postNotificationName("purchaseEnded", object: nil)
				self.purchaseRunning = false
			})
		}))
		saveAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in }))
		parent.presentViewController(saveAlert, animated: true, completion: nil)
	}
	
	func addGroup(groupName : String) {
		if joinedGroups.count <= PFUser.currentUser()!["numberOfGroups"] as! Int {
			PFUser.currentUser()?.addUniqueObject(groupName, forKey: "groups")
			getGroupDetails(groupName)
			updateGroups(group: groupName, add: true)
			PFInstallation.currentInstallation().addUniqueObject(groupName.formatGroupForChannel(), forKey: "channels")
			PFInstallation.currentInstallation().saveInBackgroundWithBlock(nil)
			global.shareGroup("I just joined the group \(groupName) using Panic. Help me make our communities safer, as well as ourselves!", viewController: self)
		} else {
			
		}
	}
	
	func removeGroup(groupName : String) {
		println(groupName)
		joinedGroups.removeAtIndex(find(joinedGroups, groupName)!)
		joinedGroupsObject[groupName.formatGroupForFlatValue()] = nil
		updateGroups(group: groupName, add: false)
		println(PFInstallation.currentInstallation().objectForKey("channels"))
		println(groupName)
		PFInstallation.currentInstallation().saveInBackgroundWithBlock(nil)
		PFInstallation.currentInstallation().removeObject(groupName.formatGroupForChannel(), forKey: "channels")
		PFInstallation.currentInstallation().saveInBackgroundWithBlock(nil)
	}
	
	func updateGroups(group : String = "", add: Bool = true) {
		PFUser.currentUser()!["groups"] = joinedGroups
		PFUser.currentUser()!.saveInBackgroundWithBlock(nil)
		
		if group != "" {
			PFQuery(className: "Groups").whereKey("flatValue", equalTo: group.formatGroupForFlatValue()).getFirstObjectInBackgroundWithBlock({
				(object: PFObject?, error: NSError?) -> Void in
				if object != nil {
					if add == true {
						object!.addUniqueObject(PFUser.currentUser()!.objectId!, forKey: "subscriberObjects")
					} else {
						object!.removeObject(PFUser.currentUser()!.objectId!, forKey: "subscriberObjects")
					}
					if object!["subscriberObjects"] != nil {
						let count = (object!["subscriberObjects"] as! [String]).count
						object!["subscribers"] = count
					}
					object!.saveInBackgroundWithBlock(nil)
					object!.saveEventually(nil)
					NSNotificationCenter.defaultCenter().postNotificationName("gotNearbyGroups", object: nil)
				}
			})
		}
		
		global.persistantSettings.setObject(joinedGroups, forKey: "groups")
		global.persistantSettings.synchronize()
	}
	
//	func getShortLink(groupName : String) -> NSString {
//		let apiEndpoint = "http://tinyurl.com/api-create.php?url=\(groupName.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!)"
//		let shortURL = NSString(contentsOfURL: NSURL(string: apiEndpoint)!, encoding: NSASCIIStringEncoding, error: nil)
//		let pasteboard = UIPasteboard.generalPasteboard()
//		pasteboard.string = (shortURL as! String)
//		return shortURL!
//	}
	
	// CREATE GROUP
	func createGroup(groupObject: PFObject, parent: CreateGroupViewController) {
		if checkIfAlreadyContainsGroup(groupObject) == false {
			var error : NSErrorPointer?
			var query = PFQuery(className: "Groups")
			var queryAddNewGroupCheckFlat = PFQuery(className: "Groups")
			if checkIfGroupExists(groupObject) == false {
				groupObject.saveInBackgroundWithBlock({
					(result: Bool, error: NSError?) -> Void in
					if result == true {
						dispatch_async(dispatch_get_main_queue(), {
							let name = groupObject["name"] as! String
							global.showAlert("Successful", message: "Successfully created and joined the group \(name).")
							groupsHandler.addGroup(name)
							NSNotificationCenter.defaultCenter().postNotificationName("gotNearbyGroups", object: nil)
							parent.dismissViewControllerAnimated(true, completion: nil)
						})
					} else {
						global.showAlert("Oops", message: error!.localizedFailureReason!)
					}
				})
			}
		} else {
			global.showAlert("Hmm...", message: "You already belong to this group.")
		}
	}
	
	func checkIfAlreadyContainsGroup(group: PFObject) -> Bool {
		for channel in PFInstallation.currentInstallation().channels as! [String] {
			if (group["name"] as! String).formatGroupForFlatValue() == channel {
				return true
			}
		}
		return false
	}
	
	func checkIfGroupExists(group: PFObject) -> Bool {
		var query = PFQuery(className: "Groups")
		query.whereKey("flatValue", equalTo: (group["name"] as! String).formatGroupForFlatValue())
		let objects = query.findObjects()
		
		if objects != nil {
			if objects!.count == 0 {
				return false
			} else {
				let pfObject = objects!.first as! PFObject
				let name = pfObject["name"] as! String
				let country = pfObject["country"] as! String
				let privateGroup = pfObject["public"] as! Bool
				global.showAlert("Unsuccessful", message: "Group '\(name)' already exists in \(country)")
			}
		}
		return true
	}
	
	// Used to create a group with user = Panic
	func createGroup(groupName: String, country: String) {
		var query = PFQuery(className: "Groups")
		query.whereKey("flatValue", equalTo: groupName.formatGroupForFlatValue())
		query.findObjectsInBackgroundWithBlock({
			(object : [AnyObject]?, error : NSError?) -> Void in
			if object == nil {
				println("NO GROUP FOUND. CREATING - '\(groupName)'")
				var newGroupObject : PFObject = PFObject(className: "Groups")
				newGroupObject["name"] = groupName
				newGroupObject["flatValue"] = groupName.formatGroupForFlatValue()
				newGroupObject["country"] = country
				newGroupObject["admin"] = PFUser.objectWithoutDataWithObjectId("qP9SOINr4X")
				newGroupObject["public"] = true
				newGroupObject.saveInBackgroundWithBlock({
					(result: Bool, error: NSError?) -> Void in
					if result == true {
						println("GROUP CREATED")
					} else {
						println(error)
					}
					println(error)
				})
			} else {
				println("FOUND GROUP")
			}

		})
	}
}
