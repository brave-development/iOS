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
import SwiftyJSON

var global : Global = Global()

extension String {
	func stripCharactersInSet(_ chars: [Character]) -> String {
		var finalString = self
		for char in chars {
			finalString = finalString.replacingOccurrences(of: String(char), with: "")
		}
		return finalString
//		return String(filter(self) {find(chars, $0) == nil})
	}
	
	func formatGroupForChannel() -> String {
		return self.lowercased().capitalized.stripCharactersInSet([" "])
	}
	
	func formatGroupForFlatValue() -> String {
		return self.lowercased().stripCharactersInSet([" ", "_", "-", ",", "\"", ".", "/", "!", "?", "#", "(", ")", "&"])
	}
	
	func trim() -> String {
		return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
}

class Global: UIViewController {
	
	var victimInformation : [String : [String]] = [:]
	var persistantSettings : UserDefaults = UserDefaults.standard
	var panicHistoryLocal : [PFObject] = []
	var panicHistoryPublic : [PFObject] = []
	let queryUsers = PFUser.query()
	var queryUsersBusy = false
	var countries : [String] = []
	var appIsInBackground = false
	var panicConfirmation = false
	var backgroundPanic = false
	var openedViaNotification = false
    var notificationDictionary : JSON?
	let dateFormatter = DateFormatter()
	
	var privateHistoryFetched : Bool = false
	var publicHistoryFetched : Bool = false
	
	//
	
	func getUserInformation() -> Bool {
		
		if PFUser.current() != nil {
			PFUser.current()!.fetchInBackground(block: {
				(object, error) in
				if error != nil {
					print("getUserInformation - \(error!)")
				} else {
					global.getLocalHistory()
					groupsHandler.getGroups()
					global.persistantSettings.set(PFUser.current()!["numberOfGroups"] as! Int, forKey: "numberOfGroups")
					if PFUser.current()!["username"] as! String == "byroncoetsee" {
						PFInstallation.current()?.addUniqueObject("panic_global", forKey: "channels")
					}
					PFInstallation.current()?.saveInBackground(block: nil)
				}
			})
			
			if checkInternetConnectivity() == false {
				showAlert("No internet", message: "Although you have been logged in, an internet connection cannot be established. Please note this will have negative effects on the Panic system. If you activate Panic, it will continue to try connect, but success cannot be guaranteed")
			}
			tutorial.load()
			return true
		}
		tutorial.reset()
		return false
	}
	
	func getVictimInformation(_ victims : [PFUser : PFGeoPoint]) {
		for (name, _) in victims {
			if self.victimInformation[name.objectId!] == nil && queryUsersBusy == false {
				queryUsersBusy = true
				queryUsers!.getObjectInBackground(withId: name.objectId!, block: {
					(userObject, error) in
					if userObject != nil {
						let victimUsername = userObject!["username"] as! String
						let victimName = userObject!["name"] as! String
						let victimCell = userObject!["cellNumber"] as! String
						self.victimInformation[name.objectId!] = [victimUsername, victimName, victimCell]
					}
					self.queryUsersBusy = false
				})
			}
//            else if queryUsersBusy == true { }
		}
	}
	
	func getLocalHistory() {
		panicHistoryLocal = []
		let queryHistory = PFQuery(className: "Panics")
		queryHistory.whereKey("user", equalTo: PFUser.current()!)
		queryHistory.order(byDescending: "createdAt")
		queryHistory.limit = 50
		queryHistory.findObjectsInBackground(block: {
			(objects, error) in
			if error == nil {
				for objectRaw in objects! {
					let object = objectRaw 
					object["user"] = PFUser.current()
					self.panicHistoryLocal.append(object)
				}
			} else {
				print(error!)
			}
			self.privateHistoryFetched = true
//			NSNotificationCenter.defaultCenter().postNotificationName("gotPublicHistory", object: nil)
			print("DONE getting local history")
		})
	}
	
	func getPublicHistory() {
		let queryHistory = PFQuery(className: "Panics")
		queryHistory.order(byDescending: "createdAt")
		queryHistory.limit = 20
		queryHistory.includeKey("user")
		queryHistory.findObjectsInBackground(block: {
			(objects, error) in
			if error == nil {
				self.panicHistoryPublic = []
				for objectRaw in objects! {
					let object = JSON(objectRaw)
					// check for no user - delete record. means user no longer exists.
					if object["user"]["name"].exists() {
						global.panicHistoryPublic.append(objectRaw)
					}
				}
			} else {
				print(error!)
			}
			self.publicHistoryFetched = true
//			NSNotificationCenter.defaultCenter().postNotificationName("gotPublicHistory", object: nil)
			print("DONE getting public history")
		})
	}
	
	func setPanicNotification(_ enabled : Bool) {
		if enabled == true {
			panicConfirmation = true
		} else {
			panicConfirmation = false
		}
		persistantSettings.set(panicConfirmation, forKey: "panicConfirmation")
		persistantSettings.synchronize()
	}
	
	func setBackgroundUpdate(_ enabled : Bool) {
		if enabled == true {
			backgroundPanic = true
		} else {
			backgroundPanic = false
		}
		persistantSettings.set(backgroundPanic, forKey: "backgroundPanic")
		persistantSettings.synchronize()
	}
	
	func getCountries() {
		do {
			let bundle : String = Bundle.main.path(forResource: "Countries", ofType: "txt")!
			let content = try String(contentsOfFile: bundle, encoding: String.Encoding.utf8)
			let countriesRaw: [String] = content.components(separatedBy: "\n")
			for country in countriesRaw {
				if !country.isEmpty {
					countries.append(country)
				}
			}
			countries.sort() // sorted{ $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending }
			print("Done getting countries")
		} catch {
			print("Error getting countries ____ sdjnvksdnvksdjvnsdv")
		}
	}
	
	func checkInternetConnectivity() -> Bool{
		var zeroAddress = sockaddr_in()
		zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
		zeroAddress.sin_family = sa_family_t(AF_INET)
		
		guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
		}) else {
			return false
		}
		
		var flags : SCNetworkReachabilityFlags = []
		if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
			return false
		}
		
		let isReachable = flags.contains(.reachable)
		let needsConnection = flags.contains(.connectionRequired)
		return (isReachable && !needsConnection)
	}

	func showAlert(_ title: String, message: String)
	{
		let alert: UIAlertView = UIAlertView()
		alert.addButton(withTitle: "OK")
		alert.title = title
		alert.message = message
		alert.show()
	}
	
	func shareGroup(_ text : String, viewController : UIViewController?) {
//		NSNotificationCenter.defaultCenter().postNotificationName("didJoinGroup", object: nil)
		var topController = UIApplication.shared.keyWindow?.rootViewController
		if topController != nil {
			while topController!.presentedViewController != nil {
				topController = topController!.presentedViewController
			}
		} else { topController = viewController } //shareToWhatsapp()
		
		if topController != nil {
			let shareAlert = UIAlertController(title: NSLocalizedString("share_title", value: "Let others know", comment: ""), message: NSLocalizedString("share_text", value: "The more people that join your communities and groups, the safer you all become... ", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
			
			//WHATSAPP
			shareAlert.addAction(UIAlertAction(title: "Whatsapp", style: .default, handler: { (action: UIAlertAction!) in
				global.shareToWhatsapp(text)
			}))
			
			//FACEBOOK
			shareAlert.addAction(UIAlertAction(title: "Facebook", style: .default, handler: { (action: UIAlertAction!) in
				if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook){
					let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
					facebookSheet.setInitialText(text)
					topController!.present(facebookSheet, animated: true, completion: nil)
				} else {
					let alert = UIAlertController(title: "Accounts", message: NSLocalizedString("facebook_share_login", value: "Please login to a Facebook account to share.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
					alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
					topController!.present(alert, animated: true, completion: nil)
				}
			}))
			
			//TWITTER
			shareAlert.addAction(UIAlertAction(title: "Twitter", style: .default, handler: { (action: UIAlertAction!) in
				if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter){
					let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
					twitterSheet.setInitialText(text)
					topController!.present(twitterSheet, animated: true, completion: nil)
				} else {
					let alert = UIAlertController(title: "Accounts", message: NSLocalizedString("twitter_share_login", value: "Please login to a Twitter account to share.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
					alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
					topController!.present(alert, animated: true, completion: nil)
				}
			}))
			shareAlert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .destructive, handler: { (action: UIAlertAction!) in
			}))
			topController!.present(shareAlert, animated: true, completion: nil)
		} else {
			global.showAlert("Hmm..", message: "Something went wrong... Awkward")
		}
	}
	
	func shareToWhatsapp(_ message: String) {
		let whatsappUrlString = "whatsapp://send?text=\(message)"
		let whatsappUrl = URL(string: whatsappUrlString.addingPercentEscapes(using: String.Encoding.utf8)!)
		
		if UIApplication.shared.canOpenURL(whatsappUrl!) {
			UIApplication.shared.openURL(whatsappUrl!)
		} else {
			global.showAlert(NSLocalizedString("whatsapp_not_installed", value: "Whatsapp not installed", comment: ""), message: "")
		}
	}
	
	func didChangeAuthStatus(_ manager: CLLocationManager, status: CLAuthorizationStatus) -> Bool {
		if status != CLAuthorizationStatus.notDetermined {
			if (status == CLAuthorizationStatus.authorizedAlways) || (status == CLAuthorizationStatus.authorizedWhenInUse) {
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
		return Int(UIDevice.current.systemVersion.components(separatedBy: ".")[0])!
	}
	
	// TUTORIAL STUFF
	
	func showTutorialView() -> UIVisualEffectView {
		let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.dark)
		let blurView = UIVisualEffectView(effect: darkBlur)
		blurView.frame = self.view.bounds
		return blurView
	}
}