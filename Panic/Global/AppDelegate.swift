//
//  AppDelegate.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/11/30.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
//import ParseFacebookUtilsV4
import SwiftyJSON
import Firebase
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FacebookCore
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        configureParse(launchOptions: launchOptions)
        FirebaseApp.configure()
        
        //        testCrash()
        
        application.registerForRemoteNotifications()
        Messaging.messaging().remoteMessageDelegate = self
        
        // Facebook
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)
        
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
        
        // Launch background significant location updates
        if launchOptions?[UIApplicationLaunchOptionsKey.location] != nil {
            locationHandler
        }
        
        return true
    }
    
    func application(received remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage)
    }
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase InstanceID token: \(fcmToken)")
        PFInstallation.current()?.setValue(fcmToken, forKey: "firebaseID")
        PFInstallation.current()?.saveInBackground()
    }
    
    
    // =============
    // CONFIGURATIONS
    // =============
    
    
    func configureParse(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        let configuration = ParseClientConfiguration {
            $0.applicationId = "PANICING-TURTLE"
            $0.server = "https://panicing-turtle.herokuapp.com/parse"
//            $0.server = "http://192.168.8.102:1337/parse"
        }
        Parse.initialize(with: configuration)
        PFAnalytics.trackAppOpenedWithLaunchOptions(inBackground: launchOptions, block: nil)
        PFUser.enableRevocableSessionInBackground()
        
        Sub_PFMessages.registerSubclass()
        Sub_PFAlert.registerSubclass()
        Sub_PFNeedle.registerSubclass()
        
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
    
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application,
                                                                     open: url,
                                                                     sourceApplication: sourceApplication,
                                                                     annotation: annotation)
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PFInstallation.current()?.setDeviceTokenFrom(deviceToken)
        PFInstallation.current()?.saveInBackground()
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) { print(error) }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // NEW
        
        if !userInfo.isEmpty {
            let json = JSON(userInfo)
            
            switch json["gcm.notification.type"].stringValue {
            case "newMessage":
                //                messagesController.fetchNewMessage(objectId: json["gcm.notification.id"].stringValue)
                guard alertHandler.currentAlert != nil else { return }
                guard let topVc = UIApplication.shared.topMostViewController() else { return }
                let vc = topVc.storyboard!.instantiateViewController(withIdentifier: "alertStage_2_VC") as! AlertStage_2_VC
                vc.modalTransitionStyle = .crossDissolve
                vc.modalPresentationStyle = .overCurrentContext
                topVc.present(vc, animated: true, completion: nil)
            case "newAlert": NotificationCenter.default.post(name: Notification.Name(rawValue: "showMapBecauseOfHandleNotification"), object: nil)
            default: return
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
        FBSDKAppEvents.activateApp()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        global.victimInformation = [:]
        panicHandler.endPanic()
        if global.persistantSettings.object(forKey: "queryObjectId") != nil {
            global.persistantSettings.removeObject(forKey: "queryObjectId")
        }
    }
}

