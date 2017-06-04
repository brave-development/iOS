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
		let user = PFUser.current()!
		if user["groups"] != nil {
			for group in user["groups"] as! [String] {
				if joinedGroups.index(of: group) == nil {
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
		PFInstallation.current()?.setObject([""], forKey: "channels")
		PFInstallation.current()?.addUniqueObjects(from: groupFormatted, forKey: "channels")
		PFInstallation.current()?.saveInBackground(block: nil)
	}
	
	func getNearbyGroups(_ location : CLLocation, refresh: Bool = false) {
		if nearbyGroupObjects.isEmpty || refresh == true {
			nearbyGroupObjects = [:]
			nearbyGroups = []
			gotNearbyGroupDetails = false
			let currentGroups = PFUser.current()!["groups"] as! [String]
			let queryHistory = PFQuery(className: "Groups")
			queryHistory.whereKey("location", nearGeoPoint: PFGeoPoint(location: location), withinKilometers: 5000)
			queryHistory.whereKey("public", equalTo: true)
			queryHistory.whereKey("name", notContainedIn: currentGroups)
			queryHistory.limit = 2
			queryHistory.findObjectsInBackground(block: {
				(objects, error) in
				if error == nil {
					print(objects!)
					self.nearbyGroups = []
					for objectRaw in objects! {
						let object = objectRaw 
						self.nearbyGroups.append(object["flatValue"] as! String)
						self.nearbyGroupObjects[object["flatValue"] as! String] = object
					}
					NotificationCenter.default.post(name: NSNotification.Name(rawValue: "gotNearbyGroups"), object: nil)
				} else {
					print(error!)
				}
				if self.nearbyGroups.count == self.nearbyGroupObjects.count {
					self.gotNearbyGroupDetails = true
				}
			})
			print(location)
		}
	}
	
	// Pass nil for all groups
	func getGroupDetails(_ groupName : String?) {
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
			let queryHistory = PFQuery(className: "Groups")
			queryHistory.whereKey("flatValue", equalTo: group.formatGroupForFlatValue())
			queryHistory.findObjectsInBackground(block: {
				(objects, error) in
				if error == nil {
					for objectRaw in objects! {
						let object = objectRaw 
						object.addUniqueObject(PFUser.current()!.objectId!, forKey: "subscriberObjects")
						object.saveInBackground(block: nil)
						self.joinedGroupsObject[object["flatValue"] as! String] = object
					}
				} else {
					print(error!)
				}
				if self.joinedGroups.count == self.joinedGroupsObject.count {
					self.gotGroupDetails = true
				}
			})
		}
	}
	
	func handlePurchase(_ parent: GroupsViewController) {
		let saveAlert = UIAlertController(title: "Purchase additional group slot", message: "You need to purchase extra group slots in order to join more groups", preferredStyle: UIAlertControllerStyle.alert)
		saveAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
			NotificationCenter.default.post(name: Notification.Name(rawValue: "purchaseStarted"), object: nil)
			self.purchaseRunning = true
			global.showAlert(NSLocalizedString("please_wait_title", value: "Please wait", comment: ""), message: NSLocalizedString("please_wait_text", value: "Processing your request. Please be patient.", comment: ""))
			PFPurchase.buyProduct("SoC.Panic.groupPurchaseConsumable", block: {
				(error) in
				if error == nil {
					
					PFAnalytics.trackEvent(inBackground: "Group_Purchases", dimensions: nil, block: nil)
//
					print("BOUGHT ADD GROUP")
					global.persistantSettings.synchronize()
					PFUser.current()!["numberOfGroups"] = groupsHandler.joinedGroups.count + 1
					PFUser.current()!.saveEventually(nil)
					NotificationCenter.default.post(name: NSNotification.Name(rawValue: "purchaseSuccessful"), object: nil)
//					if groupsHandler.referalGroup != nil {
//						groupsHandler.shareGroup(groupsHandler.referalGroup!, viewController: self)
//					}
				} else {
					NotificationCenter.default.post(name: NSNotification.Name(rawValue: "purchaseFail"), object: nil)
					if error?.localizedDescription != "" {
						global.showAlert(NSLocalizedString("unsuccessful", value: "Unsuccessful", comment: ""), message: (error?.localizedDescription)!)
					} else {
						global.showAlert(NSLocalizedString("unsuccessful", value: "Unsuccessful", comment: ""), message: NSLocalizedString("error_purchase_text", value: "Your purchase was unsuccessful. Please try again. No money has been debited from your account.", comment: ""))
					}
					print("FAILED PURCHASE -- \(error!)")
				}
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "purchaseEnded"), object: nil)
				self.purchaseRunning = false
			})
		}))
		saveAlert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in }))
		parent.present(saveAlert, animated: true, completion: nil)
	}
	
	func addGroup(_ groupName : String) {
		if joinedGroups.count <= PFUser.current()!["numberOfGroups"] as! Int {
			PFUser.current()?.addUniqueObject(groupName, forKey: "groups")
			getGroupDetails(groupName)
			updateGroups(groupName, add: true)
			PFInstallation.current()?.addUniqueObject(groupName.formatGroupForChannel(), forKey: "channels")
			PFInstallation.current()?.saveInBackground(block: nil)
			global.shareGroup(String(format: NSLocalizedString("share_joined_group", value: "I just joined the group %@ using Panic. Help me make our communities safer, as well as ourselves!", comment: ""), arguments: [groupName]), viewController: self)
		} else {
			
		}
	}
	
	func removeGroup(_ groupName : String) {
		print(groupName)
		joinedGroups.remove(at: joinedGroups.index(of: groupName)!)
		joinedGroupsObject[groupName.formatGroupForFlatValue()] = nil
		updateGroups(groupName, add: false)
//		print(PFInstallation.current()?.object(forKey: "channels"))
		print(groupName)
		PFInstallation.current()?.saveInBackground(block: nil)
		PFInstallation.current()?.remove(groupName.formatGroupForChannel(), forKey: "channels")
		PFInstallation.current()?.saveInBackground(block: nil)
	}
	
	func updateGroups(_ group : String = "", add: Bool = true) {
		PFUser.current()!["groups"] = joinedGroups
		PFUser.current()!.saveInBackground(block: nil)
		
		if group != "" {
			PFQuery(className: "Groups").whereKey("flatValue", equalTo: group.formatGroupForFlatValue()).getFirstObjectInBackground(block: {
				(object, error) in
				if object != nil {
					if add == true {
						object!.addUniqueObject(PFUser.current()!.objectId!, forKey: "subscriberObjects")
					} else {
						object!.remove(PFUser.current()!.objectId!, forKey: "subscriberObjects")
					}
					if object!["subscriberObjects"] != nil {
						let count = (object!["subscriberObjects"] as! [String]).count
						object!["subscribers"] = count
					}
					object!.saveInBackground(block: nil)
					object!.saveEventually(nil)
					NotificationCenter.default.post(name: Notification.Name(rawValue: "gotNearbyGroups"), object: nil)
				}
			})
		}
		
		global.persistantSettings.set(joinedGroups, forKey: "groups")
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
	func createGroup(_ groupObject: PFObject, parent: CreateGroupViewController) {
		if checkIfAlreadyContainsGroup(groupObject) == false {
			var error : NSErrorPointer?
			var query = PFQuery(className: "Groups")
			var queryAddNewGroupCheckFlat = PFQuery(className: "Groups")
			if checkIfGroupExists(groupObject) == false {
				groupObject.saveInBackground(block: {
					(result, error) in
					if result == true {
						DispatchQueue.main.async(execute: {
							let name = groupObject["name"] as! String
							global.showAlert(NSLocalizedString("successful", value: "Successful", comment: ""), message: String(format: NSLocalizedString("joined_group_text", value: "Successfully created and joined the group %@.", comment: ""), arguments: [name]))
							groupsHandler.addGroup(name)
//							NotificationCenter.default.post(name: Notification.Name(rawValue: "gotNearbyGroups"), object: nil)
//							parent.dismiss(animated: true, completion: nil)
                            parent.uploadFinished()
						})
					} else {
						global.showAlert("Oops", message: error!.localizedDescription)
					}
				})
			}
		} else {
			global.showAlert("Hmm...", message: NSLocalizedString("already_joined_group", value: "You already belong to this group.", comment: ""))
		}
	}
	
	func checkIfAlreadyContainsGroup(_ group: PFObject) -> Bool {
		for channel in (PFInstallation.current()?.channels!)! {
			if (group["name"] as! String).formatGroupForFlatValue() == channel {
				return true
			}
		}
		return false
	}
	
	func checkIfGroupExists(_ group: PFObject) -> Bool {
		let query = PFQuery(className: "Groups")
		query.whereKey("flatValue", equalTo: (group["name"] as! String).formatGroupForFlatValue())
		let objects = try! query.findObjects()
		
		if objects != nil {
			if objects.count == 0 {
				return false
			} else {
				let pfObject = objects.first!
				let name = pfObject["name"] as! String
				let country = pfObject["country"] as! String
//				let privateGroup = pfObject["public"] as! Bool
				global.showAlert(NSLocalizedString("unsuccessful", value: "Unsuccessful", comment: ""), message: String(format: NSLocalizedString("group_already_exists", value: "Group '%@' already exists in %@", comment: ""), arguments: [name, country]))
			}
		}
		return true
	}
	
	// Used to create a group with user = Panic
	func createGroup(_ groupName: String, country: String) {
		let query = PFQuery(className: "Groups")
		query.whereKey("flatValue", equalTo: groupName.formatGroupForFlatValue())
		query.findObjectsInBackground(block: {
			(object, error) in
			if object == nil {
				print("NO GROUP FOUND. CREATING - '\(groupName)'")
				let newGroupObject : PFObject = PFObject(className: "Groups")
				newGroupObject["name"] = groupName
				newGroupObject["flatValue"] = groupName.formatGroupForFlatValue()
				newGroupObject["country"] = country
                newGroupObject["admin"] = PFUser.init(withoutDataWithObjectId: "qP9SOINr4X")
				newGroupObject["public"] = true
				newGroupObject.saveInBackground(block: {
					(result, error) in
					if result == true {
						print("GROUP CREATED")
					} else {
						print(error!)
					}
					print(error!)
				})
			} else {
				print("FOUND GROUP")
			}

		})
	}
}
