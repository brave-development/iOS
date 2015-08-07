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
	
	// Referals
	
	var referalType : String?
	var referalGroup : String?
	var referalMember : String?
	
	// Trackers
	
	var gotGroupDetails : Bool = false
	
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
	
	// Pass nil for all groups
	func getGroupDetails(groupName : String?, remove : Bool = false) {
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
	
	func addGroup(groupName : String) {
		PFUser.currentUser()?.addUniqueObject(groupName, forKey: "groups")
		getGroupDetails(groupName)
		updateGroups(group: groupName, add: true)
		PFInstallation.currentInstallation().addUniqueObject(groupName.formatGroupForChannel(), forKey: "channels")
		PFInstallation.currentInstallation().saveInBackgroundWithBlock(nil)
		shareGroup(groupName, viewController: self)
	}
	
	func removeGroup(groupName : String) {
		println(groupName)
		PFUser.currentUser()?.removeObject(groupName, forKey: "groups")
		joinedGroups.removeAtIndex(find(joinedGroups, groupName)!)
		joinedGroupsObject[groupName.formatGroupForFlatValue()] = nil
		updateGroups(group: groupName, add: false)
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
				}
			})
		}
		
		global.persistantSettings.setObject(joinedGroups, forKey: "groups")
		global.persistantSettings.synchronize()
	}
	
	func getShortLink(groupName : String) -> NSString {
		let apiEndpoint = "http://tinyurl.com/api-create.php?url=\(groupName.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!)"
		let shortURL = NSString(contentsOfURL: NSURL(string: apiEndpoint)!, encoding: NSASCIIStringEncoding, error: nil)
		let pasteboard = UIPasteboard.generalPasteboard()
		pasteboard.string = (shortURL as! String)
		return shortURL!
	}
	
	func shareGroup(groupName : String, viewController : UIViewController) {
		let shareGroup: dispatch_queue_t = dispatch_queue_create("shareGroup", nil)
		dispatch_async(shareGroup, {
			dispatch_async(dispatch_get_main_queue(), {
				var topController = UIApplication.sharedApplication().keyWindow?.rootViewController
				if topController != nil {
					while topController!.presentedViewController != nil {
						topController = topController!.presentedViewController
					}
				} else { topController = viewController }
				
				if topController != nil {
					var saveAlert = UIAlertController(title: "Share", message: "Share this so others can join the group as well", preferredStyle: UIAlertControllerStyle.Alert)
					saveAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
						var shareAlert = UIAlertController(title: "Post to", message: "", preferredStyle: UIAlertControllerStyle.Alert)
						shareAlert.addAction(UIAlertAction(title: "Facebook", style: .Default, handler: { (action: UIAlertAction!) in
							
							if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
								var facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
								facebookSheet.setInitialText("Join my group '\(groupName)' on Panic! \nGet the app here: https://goo.gl/niOHXx")
								topController!.presentViewController(facebookSheet, animated: true, completion: nil)
							} else {
								var alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
								alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
								topController!.presentViewController(alert, animated: true, completion: nil)
							}
						}))
						
						shareAlert.addAction(UIAlertAction(title: "Twitter", style: .Default, handler: { (action: UIAlertAction!) in
							if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter){
								var twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
								twitterSheet.setInitialText("Join my group '\(groupName)' on Panic! \nGet the app here: https://goo.gl/niOHXx")
								topController!.presentViewController(twitterSheet, animated: true, completion: nil)
							} else {
								var alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.Alert)
								alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
								topController!.presentViewController(alert, animated: true, completion: nil)
							}
						}))
						shareAlert.addAction(UIAlertAction(title: "Cancel", style: .Destructive, handler: { (action: UIAlertAction!) in
						}))
						topController!.presentViewController(shareAlert, animated: true, completion: nil)
					}))
					saveAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in }))
					topController!.presentViewController(saveAlert, animated: true, completion: nil)
				} else {
					global.showAlert("Hmm..", message: "Something went wrong. The link to your group has been copied to the clipboard - paste it in an SMS or anywhere else you would like to share it")
				}
			})})
	}
	
	// Used to create a group with user = Panic
	func createGroup(groupName: String, country: String) {
		var query = PFQuery(className: "Groups")
		query.whereKey("flatValue", equalTo: groupName.formatGroupForFlatValue())
		query.findObjectsInBackgroundWithBlock({
			(object : [AnyObject]?, error : NSError?) -> Void in
			if object != nil {
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
