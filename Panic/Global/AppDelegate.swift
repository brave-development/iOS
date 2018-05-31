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
import UserNotifications
import FacebookCore
//import Alamofire
import NotificationBannerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        configureParse(launchOptions: launchOptions)
//        application.registerForRemoteNotifications()
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            // 1. Check if permission granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        
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
            global.setAlertNotification(false)
        } else {
            global.panicConfirmation = global.persistantSettings.bool(forKey: "panicConfirmation")
        }
        
        if global.persistantSettings.object(forKey: "backgroundAlert") != nil {
            global.backgroundAlert = global.persistantSettings.bool(forKey: "backgroundAlert")
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
    
    // =============
    // CONFIGURATIONS
    // =============
    
    
    func configureParse(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        let configuration = ParseClientConfiguration {
            $0.applicationId = "PILOT-PANICING-TURTLE"
            $0.server = "https://pilot-panicing-turtle.herokuapp.com/parse"
//            $0.server = "http://192.168.0.171:1337/parse"
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device PUSH TOKEN --  \(deviceTokenString)")
        
        PFInstallation.current()?.badge = 0
        PFInstallation.current()!.deviceToken = ""
        PFInstallation.current()!.deviceToken = deviceTokenString
        PFInstallation.current()!.saveInBackground()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // NEW
        let state = UIApplication.shared.applicationState
        
        switch state {
        case .background: break
            
        case .inactive:
            if !userInfo.isEmpty {
                let json = JSON(userInfo)
                
                switch json["gcm.notification.type"].stringValue {
                case "newMessage":
                    guard alertHandler.currentAlert != nil else { return }
                    self.openChat()
                case "newAlert": NotificationCenter.default.post(name: Notification.Name(rawValue: "showMapBecauseOfHandleNotification"), object: nil)
                default: return
                }
            }
            break
            
        case .active:
            guard alertHandler.currentAlert != nil else { return }
            guard let name = JSON(userInfo)["aps"]["alert"]["title"].string, let message = JSON(userInfo)["aps"]["alert"]["body"].string else { return }
            showNewMessagePrompt(name: name, message: message)
            break
        }
    }
    
    func showNewMessagePrompt(name: String, message: String) {
        let banner = NotificationBanner(title: name, subtitle: message, style: .success)
        banner.backgroundColor = UIColor.flatSkyBlue
        banner.autoDismiss = true
        banner.dismissOnTap = true
        banner.dismissOnSwipeUp = true
        banner.onTap = { self.openChat() }
        banner.show()
    }
    
    func openChat() {
        guard let topVc = UIApplication.shared.topMostViewController() else { return }
        let vc = topVc.storyboard!.instantiateViewController(withIdentifier: "alertStage_2_VC") as! AlertStage_2_VC
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        topVc.present(vc, animated: true, completion: nil)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) { }
    func applicationWillResignActive(_ application: UIApplication) { }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if global.backgroundAlert == false && alertHandler.currentAlert?.active == true {
            print("PAUSE")
            alertHandler.pause()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "applicationDidEnterBackground"), object: nil)
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        if global.backgroundAlert == false && alertHandler.currentAlert?.active == true {
            print("RESUME")
            alertHandler.resume()
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
    
//    func registrationScreenName(screen: Reg_IndividualScreen_VC)->String {
//
//        switch screen {
//            case is Reg_Name_VC: return "Name"
//            case is Reg_Email_VC: return "Email"
//            case is Reg_Password_VC: return "Password"
//            default: return "Something isn't right"
//        }
//
//    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        global.victimInformation = [:]
        alertHandler.end()
        if global.persistantSettings.object(forKey: "queryObjectId") != nil {
            global.persistantSettings.removeObject(forKey: "queryObjectId")
        }
    }
}

