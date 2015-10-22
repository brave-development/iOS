//
//  AppDelegate.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/11/30.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import ParseCrashReporting

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
	
	func crash() {
		NSException(name: NSGenericException, reason: "Everything is ok. This is just a test crash.", userInfo: nil).raise()
	}

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		ParseCrashReporting.enable()
        Parse.setApplicationId("cBZmGCzXfaQAyxqnTh6eF2kIqCUnSm1ET8wYL5O7", clientKey:"rno7DabpDMU293yi2TF4S3jKOlrZX2P27EW70C3G")
        PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)
		println(PFInstallation.currentInstallation())
		
		dispatch_after(
			dispatch_time(DISPATCH_TIME_NOW, Int64(10.0 * Double(NSEC_PER_SEC))),
			dispatch_get_main_queue(),
			{ () -> Void in
//				self.crash()
		});
		
		PFPurchase.addObserverForProduct("SoC.Panic.groupPurchaseConsumable", block: {
			(transaction: SKPaymentTransaction!) -> Void in
			println("PURCHASED FROM APPDELEGATE")
		})
		
        let populateCountries: dispatch_queue_t = dispatch_queue_create("populateCountries", nil)
        
        dispatch_async(populateCountries, {
            global.getCountries()
        })
		
		if global.persistantSettings.objectForKey("numberOfGroups") == nil {
			global.persistantSettings.setInteger(1, forKey: "numberOfGroups")
		}
		
		if global.persistantSettings.objectForKey("queryObjectId") != nil {
			println("Cleared persistance from didFinishLaunchingWithOptions")
			global.persistantSettings.removeObjectForKey("queryObjectId")
		}
        
        if global.persistantSettings.objectForKey("panicConfirmation") == nil {
            global.setPanicNotification(false)
        } else {
            global.panicConfirmation = global.persistantSettings.boolForKey("panicConfirmation")
        }
		
		if global.persistantSettings.objectForKey("backgroundPanic") != nil {
			global.backgroundPanic = global.persistantSettings.boolForKey("backgroundPanic")
		}
		
		PFInstallation.currentInstallation().badge = 0
		PFInstallation.currentInstallation().saveEventually(nil)
		
		var notiType = UIUserNotificationType.Badge | UIUserNotificationType.Sound | UIUserNotificationType.Alert
        
        var notiSettings:UIUserNotificationSettings = UIUserNotificationSettings(forTypes:notiType, categories: nil)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notiSettings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
		
		if launchOptions != nil {
			if launchOptions!["UIApplicationLaunchOptionsRemoteNotificationKey"] == nil {
				println("Got nothing")
			} else {
				println("Got notif - \(launchOptions)")
				if launchOptions!["UIApplicationLaunchOptionsRemoteNotificationKey"]!["lat"] != nil {
					global.notificationDictionary = launchOptions!["UIApplicationLaunchOptionsRemoteNotificationKey"] as? NSDictionary
					global.openedViaNotification = true
				}
			}
		} else {
			println("Launch options empty")
		}
        return true
    }
	
	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
		//
		let queryArray = split(url.query!) {$0 == "&"} // Split into type, group, member
		let type = split(queryArray[0]) {$0 == "="} // Split into "type" and "privateGroup"
		groupsHandler.referalType = type[1]
		
		if groupsHandler.referalType == "privateGroup" || groupsHandler.referalType == "publicGroup"{
			groupsHandler.referalGroup = queryArray[1]
		}
		return true
	}
	
	func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
		UIApplication.sharedApplication().registerForRemoteNotifications()
	}
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
		global.persistantSettings.setObject(deviceToken, forKey: "deviceToken")
        PFInstallation.currentInstallation().setDeviceTokenFromData(deviceToken)
		PFInstallation.currentInstallation().saveInBackgroundWithBlock(nil)
    }
	
	func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
		println(error)
	}
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
		if (panicHandler.panicIsActive == false && !userInfo.isEmpty) {
			if ( application.applicationState == UIApplicationState.Inactive || application.applicationState == UIApplicationState.Background  )
			{
				//opened from a push notification when the app was on background
				println("Got notif userInfo - \(userInfo)")
				if userInfo["lat"] != nil {
					println("Should open map")
					global.notificationDictionary = userInfo
					global.openedViaNotification = true
					NSNotificationCenter.defaultCenter().postNotificationName("showMapBecauseOfHandleNotification", object: nil)
				}
			} else {
				global.notificationDictionary = userInfo
				NSNotificationCenter.defaultCenter().postNotificationName("showMapBecauseOfHandleNotification", object: nil)
			}
		}
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
    }

    func applicationWillResignActive(application: UIApplication) {
//        println("applicationWillResignActive")
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
		if global.backgroundPanic == false && panicHandler.panicIsActive == true {
			println("PAUSE")
			panicHandler.pausePanic(paused: true)
			NSNotificationCenter.defaultCenter().postNotificationName("applicationDidEnterBackground", object: nil)
		}
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
		if global.backgroundPanic == false && panicHandler.panicIsActive == true {
			println("RESUME")
			panicHandler.resumePanic()
			NSNotificationCenter.defaultCenter().postNotificationName("applicationWillEnterForeground", object: nil)
		} else if global.openedViaNotification == true {
			NSNotificationCenter.defaultCenter().postNotificationName("openedViaNotification", object: nil)
		}
		
		
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
		PFInstallation.currentInstallation().badge = 0
		PFInstallation.currentInstallation().saveEventually(nil)
//        println("applicationDidBecomeActive")
        
    }

	func applicationWillTerminate(application: UIApplication) {
		
		global.victimInformation = [:]
		panicHandler.endPanic()
		if global.persistantSettings.objectForKey("queryObjectId") != nil {
			global.persistantSettings.removeObjectForKey("queryObjectId")
		}
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
}

