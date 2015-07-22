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
	
	func didChangeAuthStatus(manager: CLLocationManager, status: CLAuthorizationStatus) -> Bool {
		if status != CLAuthorizationStatus.NotDetermined {
			if (status == CLAuthorizationStatus.AuthorizedAlways) || (status == CLAuthorizationStatus.AuthorizedWhenInUse) {
				return true
			} else {
				global.showAlert("Location Not Allowed", message: "Please enable location services for Panic by going to Settings > Privacy > Location Services.\nWithout location services, no one will be able to respond to your emergency.")
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
