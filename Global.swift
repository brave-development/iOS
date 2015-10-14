//
//  Global.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/11/30.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import SystemConfiguration
import Social

var global : Global = Global()

extension String {
	func stripCharactersInSet(chars: [Character]) -> String {
		return String(filter(self) {find(chars, $0) == nil})
	}
	
	func formatGroupForChannel() -> String {
		return self.lowercaseString.capitalizedString.stripCharactersInSet([" "])
	}
	
	func formatGroupForFlatValue() -> String {
		return self.lowercaseString.stripCharactersInSet([" ", "_", "-", ",", "\"", ".", "/", "!", "?", "#", "(", ")", "&"])
	}
	
	func trim() -> String {
		return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
	}
}

class Global: UIViewController {
	
	var victimInformation : [String : [String]] = [:]
	var persistantSettings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
	var panicHistoryLocal : [PFObject] = []
	var panicHistoryPublic : [PFObject] = []
	let queryUsers = PFUser.query()
	var queryUsersBusy = false
	var countries : [String] = []
	var appIsInBackground = false
	var panicConfirmation = false
	var backgroundPanic = false
	var openedViaNotification = false
	var notificationDictionary: NSDictionary?
	let dateFormatter = NSDateFormatter()
	
	var privateHistoryFetched : Bool = false
	var publicHistoryFetched : Bool = false
	
	//
	
	func getUserInformation() -> Bool {
		
		if PFUser.currentUser() != nil {
			PFUser.currentUser()!.fetchInBackgroundWithBlock({
				(object : PFObject?, error : NSError?) -> Void in
				if error != nil {
					println("getUserInformation - \(error)")
				} else {
					global.getLocalHistory()
					groupsHandler.getGroups()
					global.persistantSettings.setInteger(PFUser.currentUser()!["numberOfGroups"] as! Int, forKey: "numberOfGroups")
					if PFUser.currentUser()!["username"] as! String == "byroncoetsee" {
						PFInstallation.currentInstallation().addUniqueObject("panic_global", forKey: "channels")
					}
					PFInstallation.currentInstallation().saveInBackgroundWithBlock(nil)
				}
			})
			
			if checkInternetConnectivity() == false {
				showAlert("No internet", message: "Although you have been logged in, an internet connection cannot be established. Please note this will have negative effects on the panic system. If you activate Panic, it will continue to try connect, but success cannot be guaranteed")
			}
			tutorial.load()
			return true
		}
		tutorial.reset()
		return false
	}
	
	func getVictimInformation(victims : [PFUser : PFGeoPoint]) {
		for (name, location) in victims {
			if self.victimInformation[name.objectId!] == nil && queryUsersBusy == false {
				queryUsersBusy = true
				queryUsers!.getObjectInBackgroundWithId(name.objectId!, block: {
					(userObject : PFObject?, error : NSError?) -> Void in
					if userObject != nil {
						let victimUsername = userObject!["username"] as! String
						let victimName = userObject!["name"] as! String
						let victimCell = userObject!["cellNumber"] as! String
						self.victimInformation[name.objectId!] = [victimUsername, victimName, victimCell]
					}
					self.queryUsersBusy = false
				})
			} else if queryUsersBusy == true {
				
			}
		}
	}
	
	func getLocalHistory() {
		panicHistoryLocal = []
		var queryHistory = PFQuery(className: "Panics")
		queryHistory.whereKey("user", equalTo: PFUser.currentUser()!)
		queryHistory.orderByDescending("createdAt")
		queryHistory.limit = 50
		queryHistory.findObjectsInBackgroundWithBlock({
			(objects : [AnyObject]?, error : NSError?) -> Void in
			if error == nil {
				for objectRaw in objects! {
					let object = objectRaw as! PFObject
					object["user"] = PFUser.currentUser()
					self.panicHistoryLocal.append(object)
				}
			} else {
				println(error)
			}
			self.privateHistoryFetched = true
//			NSNotificationCenter.defaultCenter().postNotificationName("gotPublicHistory", object: nil)
			println("DONE getting local history")
		})
	}
	
	func getPublicHistory() {
		var queryHistory = PFQuery(className: "Panics")
		queryHistory.orderByDescending("createdAt")
		queryHistory.limit = 20
		queryHistory.includeKey("user")
		queryHistory.findObjectsInBackgroundWithBlock({
			(objects : [AnyObject]?, error : NSError?) -> Void in
			if error == nil {
				self.panicHistoryPublic = []
				for objectRaw in objects! {
					let object = objectRaw as! PFObject
					// check for no user - delete record. means user no longer exists.
					if object["user"]!["name"] != nil {
						global.panicHistoryPublic.append(object)
					}
				}
			} else {
				println(error)
			}
			self.publicHistoryFetched = true
//			NSNotificationCenter.defaultCenter().postNotificationName("gotPublicHistory", object: nil)
			println("DONE getting public history")
		})
	}
	
	func setPanicNotification(enabled : Bool) {
		if enabled == true {
			panicConfirmation = true
		} else {
			panicConfirmation = false
		}
		persistantSettings.setObject(panicConfirmation, forKey: "panicConfirmation")
		persistantSettings.synchronize()
	}
	
	func setBackgroundUpdate(enabled : Bool) {
		if enabled == true {
			backgroundPanic = true
		} else {
			backgroundPanic = false
		}
		persistantSettings.setObject(backgroundPanic, forKey: "backgroundPanic")
		persistantSettings.synchronize()
	}
	
	func getCountries() {
		var bundle : String = NSBundle.mainBundle().pathForResource("Countries", ofType: "txt")!
		var content = String(contentsOfFile: bundle, encoding: NSUTF8StringEncoding, error: nil)!
		var countriesRaw: [String] = content.componentsSeparatedByString("\n")
		for country in countriesRaw {
			if !country.isEmpty {
				countries.append(country)
			}
		}
		countries = countries.sorted{ $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending }
		println("Done getting countries")
	}
	
	func checkInternetConnectivity() -> Bool{
		var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
		zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
		zeroAddress.sin_family = sa_family_t(AF_INET)
		
		let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
			SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
		}
		
		var flags: SCNetworkReachabilityFlags = 0
		if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
			return false
		}
		
		let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
		let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
		
		return (isReachable && !needsConnection) ? true : false
	}
	
	func showAlert(title: String, message: String)
	{
		var alert: UIAlertView = UIAlertView()
		alert.addButtonWithTitle("OK")
		alert.title = title
		alert.message = message
		alert.show()
	}
	
	func shareGroup(text : String, viewController : UIViewController?) {
//		NSNotificationCenter.defaultCenter().postNotificationName("didJoinGroup", object: nil)
		var topController = UIApplication.sharedApplication().keyWindow?.rootViewController
		if topController != nil {
			while topController!.presentedViewController != nil {
				topController = topController!.presentedViewController
			}
		} else { topController = viewController } //shareToWhatsapp()
		
		if topController != nil {
			var shareAlert = UIAlertController(title: NSLocalizedString("share_title", value: "Let others know", comment: ""), message: NSLocalizedString("share_text", value: "The more people that join your communities and groups, the safer you all become... ", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
			
			//WHATSAPP
			shareAlert.addAction(UIAlertAction(title: "Whatsapp", style: .Default, handler: { (action: UIAlertAction!) in
				global.shareToWhatsapp(text)
			}))
			
			//FACEBOOK
			shareAlert.addAction(UIAlertAction(title: "Facebook", style: .Default, handler: { (action: UIAlertAction!) in
				if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
					var facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
					facebookSheet.setInitialText(text)
					topController!.presentViewController(facebookSheet, animated: true, completion: nil)
				} else {
					var alert = UIAlertController(title: "Accounts", message: NSLocalizedString("facebook_share_login", value: "Please login to a Facebook account to share.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
					alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
					topController!.presentViewController(alert, animated: true, completion: nil)
				}
			}))
			
			//TWITTER
			shareAlert.addAction(UIAlertAction(title: "Twitter", style: .Default, handler: { (action: UIAlertAction!) in
				if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter){
					var twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
					twitterSheet.setInitialText(text)
					topController!.presentViewController(twitterSheet, animated: true, completion: nil)
				} else {
					var alert = UIAlertController(title: "Accounts", message: NSLocalizedString("twitter_share_login", value: "Please login to a Twitter account to share.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
					alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
					topController!.presentViewController(alert, animated: true, completion: nil)
				}
			}))
			shareAlert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .Destructive, handler: { (action: UIAlertAction!) in
			}))
			topController!.presentViewController(shareAlert, animated: true, completion: nil)
		} else {
			global.showAlert("Hmm..", message: "Something went wrong... Awkward")
		}
	}
	
	func shareToWhatsapp(message: String) {
		let whatsappUrlString = "whatsapp://send?text=\(message)"
		let whatsappUrl = NSURL(string: whatsappUrlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
		
		if UIApplication.sharedApplication().canOpenURL(whatsappUrl!) {
			UIApplication.sharedApplication().openURL(whatsappUrl!)
		} else {
			global.showAlert(NSLocalizedString("whatsapp_not_installed", value: "Whatsapp not installed", comment: ""), message: "")
		}
	}
	
	func didChangeAuthStatus(manager: CLLocationManager, status: CLAuthorizationStatus) -> Bool {
		if status != CLAuthorizationStatus.NotDetermined {
			if (status == CLAuthorizationStatus.AuthorizedAlways) || (status == CLAuthorizationStatus.AuthorizedWhenInUse) {
				return true
			} else {
				global.showAlert(NSLocalizedString("location_not_allowed_title", value: "Location Not Allowed", comment: ""), message: NSLocalizedString("location_not_aloowed_text", value: "Please enable location services for Panic by going to Settings > Privacy > Location Services.\nWithout location services, no one will be able to respond to your emergency.", comment: ""))
				return false
			}
		}
		return false
	}
	
	func getSystemVersion() -> Int
	{
		return UIDevice.currentDevice().systemVersion.componentsSeparatedByString(".")[0].toInt()!
	}
	
	// TUTORIAL STUFF
	
	func showTutorialView() -> UIVisualEffectView {
		let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
		var blurView = UIVisualEffectView(effect: darkBlur)
		blurView.frame = self.view.bounds
		return blurView
	}
}
