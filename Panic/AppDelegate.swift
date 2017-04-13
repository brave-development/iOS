//
//  AppDelegate.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/11/30.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
	
	func crash() {
		NSException(name: NSExceptionName.genericException, reason: "Everything is ok. This is just a test crash.", userInfo: nil).raise()
	}

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
//		ParseCrashReporting.enable()
        Parse.setApplicationId("cBZmGCzXfaQAyxqnTh6eF2kIqCUnSm1ET8wYL5O7", clientKey:"rno7DabpDMU293yi2TF4S3jKOlrZX2P27EW70C3G")
        PFAnalytics.trackAppOpenedWithLaunchOptions(inBackground: launchOptions, block: nil)
		print(PFInstallation.current())
		
		DispatchQueue.main.asyncAfter(
			deadline: DispatchTime.now() + Double(Int64(10.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
			execute: { () -> Void in
//				self.crash()
		});
		
		PFPurchase.addObserver(forProduct: "SoC.Panic.groupPurchaseConsumable", block: {
			(transaction: SKPaymentTransaction!) -> Void in
			print("PURCHASED FROM APPDELEGATE")
		})
		
        let populateCountries: DispatchQueue = DispatchQueue(label: "populateCountries", attributes: [])
        
        populateCountries.async(execute: {
            global.getCountries()
        })
		
		if global.persistantSettings.object(forKey: "numberOfGroups") == nil {
			global.persistantSettings.set(1, forKey: "numberOfGroups")
		}
		
		if global.persistantSettings.object(forKey: "queryObjectId") != nil {
			print("Cleared persistance from didFinishLaunchingWithOptions")
			global.persistantSettings.removeObject(forKey: "queryObjectId")
		}
        
        if global.persistantSettings.object(forKey: "panicConfirmation") == nil {
            global.setPanicNotification(false)
        } else {
            global.panicConfirmation = global.persistantSettings.bool(forKey: "panicConfirmation")
        }
		
		if global.persistantSettings.object(forKey: "backgroundPanic") != nil {
			global.backgroundPanic = global.persistantSettings.bool(forKey: "backgroundPanic")
		}
        
		PFInstallation.current()?.badge = 0
		PFInstallation.current()?.saveEventually(nil)
        
        let notiSettings:UIUserNotificationSettings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
        
        UIApplication.shared.registerUserNotificationSettings(notiSettings)
        UIApplication.shared.registerForRemoteNotifications()
		
//		if launchOptions != nil {
//			if launchOptions![UIApplicationLaunchOptionsKey.remoteNotification] == nil {
//				print("Got nothing")
//			} else {
//				print("Got notif - \(launchOptions)")
//				if launchOptions![UIApplicationLaunchOptionsKey.remoteNotification] as NSDictionary= nil {
//					global.notificationDictionary = launchOptions!["UIApplicationLaunchOptionsRemoteNotificationKey"] as? NSDictionary
//					global.openedViaNotification = true
//				}
//			}
//		} else {
//			print("Launch options empty")
//		}
        
        let remoteNotif = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary
        
        if remoteNotif?["lat"] != nil {
            global.notificationDictionary = JSON(remoteNotif)
            global.openedViaNotification = true
        } else {
            print("Launch options empty")
        }
        return true
    }
	
	func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
		//
//		let queryArray = split(url.query!) {$0 == "&"} // Split into type, group, member
//		let type = split(queryArray[0]) {$0 == "="} // Split into "type" and "privateGroup"
//		groupsHandler.referalType = type[1]
//		
//		if groupsHandler.referalType == "privateGroup" || groupsHandler.referalType == "publicGroup"{
//			groupsHandler.referalGroup = queryArray[1]
//		}
		return true
	}
	
	func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
		UIApplication.shared.registerForRemoteNotifications()
	}
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		global.persistantSettings.set(deviceToken, forKey: "deviceToken")
        PFInstallation.current()?.setDeviceTokenFrom(deviceToken)
		PFInstallation.current()?.saveInBackground(block: nil)
    }
	
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print(error)
	}
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
		if (panicHandler.panicIsActive == false && !userInfo.isEmpty) {
			if ( application.applicationState == UIApplicationState.inactive || application.applicationState == UIApplicationState.background  )
			{
				//opened from a push notification when the app was on background
				print("Got notif userInfo - \(userInfo)")
				if userInfo["lat"] != nil {
					print("Should open map")
					global.notificationDictionary = JSON(userInfo)// as NSDictionary
					global.openedViaNotification = true
					NotificationCenter.default.post(name: Notification.Name(rawValue: "showMapBecauseOfHandleNotification"), object: nil)
				}
			} else {
				global.notificationDictionary = JSON(userInfo)// as NSDictionary
				NotificationCenter.default.post(name: Notification.Name(rawValue: "showMapBecauseOfHandleNotification"), object: nil)
			}
		}
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
    }

    func applicationWillResignActive(_ application: UIApplication) {
//        print("applicationWillResignActive")
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
		if global.backgroundPanic == false && panicHandler.panicIsActive == true {
			print("PAUSE")
			panicHandler.pausePanic(true)
			NotificationCenter.default.post(name: Notification.Name(rawValue: "applicationDidEnterBackground"), object: nil)
		}
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
		if global.backgroundPanic == false && panicHandler.panicIsActive == true {
			print("RESUME")
			panicHandler.resumePanic()
			NotificationCenter.default.post(name: Notification.Name(rawValue: "applicationWillEnterForeground"), object: nil)
		} else if global.openedViaNotification == true {
			NotificationCenter.default.post(name: Notification.Name(rawValue: "openedViaNotification"), object: nil)
		}
		
		
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
		PFInstallation.current()?.badge = 0
		PFInstallation.current()?.saveEventually(nil)
//        print("applicationDidBecomeActive")
        
    }

	func applicationWillTerminate(_ application: UIApplication) {
		
		global.victimInformation = [:]
		panicHandler.endPanic()
		if global.persistantSettings.object(forKey: "queryObjectId") != nil {
			global.persistantSettings.removeObject(forKey: "queryObjectId")
		}
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
}

