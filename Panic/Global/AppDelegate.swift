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
import Firebase
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, FIRMessagingDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        configureParse(launchOptions: launchOptions)
        FIRApp.configure()
        
        //        testCrash()
        
        // Remote Notifications
        let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        FIRMessaging.messaging().remoteMessageDelegate = self
        
        // Get Countries
        DispatchQueue.main.async { global.getCountries() }
        
        // Persistant Settings
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
        
        if JSON(launchOptions)["lat"] != nil {
            global.notificationDictionary = JSON(launchOptions)
            global.openedViaNotification = true
        }
        
        return true
    }
    
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print(remoteMessage)
    }
    
    
    // =============
    // CONFIGURATIONS
    // =============
    
    
    func configureParse(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        let configuration = ParseClientConfiguration {
            $0.applicationId = "PANICING-TURTLE"
            $0.server = "https://panicing-turtle.herokuapp.com/parse"
        }
        Parse.initialize(with: configuration)
        PFAnalytics.trackAppOpenedWithLaunchOptions(inBackground: launchOptions, block: nil)
        
        PFInstallation.current()?.badge = 0
        PFInstallation.current()?.saveEventually(nil)
    }
    
    func testCrash() {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(10.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
            execute: { () -> Void in
                NSException(name: NSExceptionName.genericException, reason: "Everything is ok. This is just a test crash.", userInfo: nil).raise()
        });
    }
    
    
    // ===================
    // APP DELEGATE METHODS
    // ===================
    
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool { return true }
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) { UIApplication.shared.registerForRemoteNotifications() }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("Firebase InstanceID token: \(refreshedToken)")
            PFInstallation.current()?.setValue(refreshedToken, forKey: "firebaseID")
            PFInstallation.current()?.saveInBackground()
        }
        
        PFInstallation.current()?.setDeviceTokenFrom(deviceToken)
        PFInstallation.current()?.saveInBackground()
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) { print(error) }
    
    
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
    
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) { }
    func applicationWillResignActive(_ application: UIApplication) { }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if global.backgroundPanic == false && panicHandler.panicIsActive == true {
            print("PAUSE")
            panicHandler.pausePanic(true)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "applicationDidEnterBackground"), object: nil)
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        if global.backgroundPanic == false && panicHandler.panicIsActive == true {
            print("RESUME")
            panicHandler.resumePanic()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "applicationWillEnterForeground"), object: nil)
        } else if global.openedViaNotification == true {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "openedViaNotification"), object: nil)
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        PFInstallation.current()?.badge = 0
        PFInstallation.current()?.saveEventually(nil)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        global.victimInformation = [:]
        panicHandler.endPanic()
        if global.persistantSettings.object(forKey: "queryObjectId") != nil {
            global.persistantSettings.removeObject(forKey: "queryObjectId")
        }
    }
}

