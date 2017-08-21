//
//  Reg_Permissions_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/07/26.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import Spring
import SCLAlertView
import CoreLocation
import UserNotifications

class Reg_Permissions_VC: Reg_IndividualScreen_VC {
    
    @IBOutlet weak var viewTopContainer: UIView!
    
    @IBOutlet weak var imgNotificationsIcon: SpringImageView!
    
    @IBOutlet weak var imgLocationStatus: SpringImageView!
    @IBOutlet weak var imgNotificationStatus: SpringImageView!
    
    let manager = CLLocationManager()
    
    var notificationPermissionsRequested = false
    var locationPermissionsRequested = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewTopContainer.backgroundColor = self.view.backgroundColor
        
        addShadow(imageView: imgNotificationsIcon)
        addShadow(imageView: imgLocationStatus)
        addShadow(imageView: imgNotificationStatus)
        
        imgIcon.isUserInteractionEnabled = true
        imgNotificationsIcon.isUserInteractionEnabled = true
        
        manager.delegate = self
        
        let tapNotif = UITapGestureRecognizer(target: self, action: #selector(tappedNotification))
        imgNotificationsIcon.addGestureRecognizer(tapNotif)
        
        let tapLocation = UITapGestureRecognizer(target: self, action: #selector(tappedLocation))
        imgIcon.addGestureRecognizer(tapLocation)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: {_ in
            if !self.keyboardVisible {
                self.imgNotificationsIcon.animation = "swing"
                self.imgNotificationsIcon.duration = 1
                self.imgNotificationsIcon.animate()
            }
        })
    }
    
    @IBAction func next(_ sender: Any) {
        nextPage()
    }
    
    func validate() {
        if notificationPermissionsRequested && locationPermissionsRequested {
            btnNext.showWithAnimation(animation: "zoomIn")
            btnNext.sendActions(for: .touchUpInside)
        }
    }
}


// =========
// Notifications
// =========


extension Reg_Permissions_VC: UNUserNotificationCenterDelegate {
    
    func tappedNotification() {
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        
        let alertView = SCLAlertView(appearance: alertAppearance)
        
        alertView.addButton("Allow", target:self, selector: #selector(requestNotifications))
        alertView.addButton("Not now") {
            self.disallowNotifications()
        }
        alertView.showInfo("Allow Notifications", subTitle: "When others need your help and you are within helping distance, we will notify you so you can respond to the request for an Urgent Act of Kindness.")
        
        notificationPermissionsRequested = true
        validate()
    }
    
    func requestNotifications() {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in
            if error == nil {
                if success == true {
                    print("Permission granted")
                    self.allowNotifications()
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("Permission denied")
                    self.disallowNotifications()
                }
            }
        }
    }
    
    func disallowNotifications() {
        DispatchQueue.main.async {
            SCLAlertView().showWarning("That's a pity", subTitle: "When someone needs your help and you are within helping distance, you've chosen not to show an Act of Kindness.")
            self.imgNotificationStatus.image = UIImage(named: "cross")
        }
//        validate()
    }
    
    func allowNotifications() {
        DispatchQueue.main.async {
            self.imgNotificationStatus.image = UIImage(named: "checkmark")
        }
//        validate()
    }
}


// =========
// Location
// =========


extension Reg_Permissions_VC: CLLocationManagerDelegate {
    
    func tappedLocation() {
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        
        let alertView = SCLAlertView(appearance: alertAppearance)
        
        alertView.addButton("Allow", target:self, selector: #selector(requestLocation))
        alertView.addButton("Not now") {
            self.disallowLocation()
        }
        alertView.showInfo("Allow Notifications", subTitle: "When others need your help and you are within helping distance, we will notify you so you can respond to the request for an Urgent Act of Kindness.")
        
        locationPermissionsRequested = true
        validate()
    }
    
    func disallowLocation() {
        SCLAlertView().showWarning("That's a pity", subTitle: "Brave is heavily reliant on your location to function. When you are in need of an Urgent Act of Kindness, your request will not have a location and people won't recieve any alerts.")
        imgLocationStatus.image = UIImage(named: "cross")
//        validate()
    }
    
    func allowLocation() {
        imgLocationStatus.image = UIImage(named: "checkmark")
//        validate()
    }
    
    func requestLocation() {
        
        switch CLLocationManager.authorizationStatus() {
            
        case .authorizedAlways, .authorizedWhenInUse:
            allowLocation()
            
        case .denied, .restricted:
            SCLAlertView().showWarning("That's a pity", subTitle: "Brave is heavily reliant on your location to function. You've already denied Brave permission to use your location in the past. This means when you are in need of an Urgent Act of Kindness, your request will not have a location and people won't recieve any alerts.\n\nYou can enable location permissions again throug the Settings app.")
            
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .authorizedAlways:
            allowLocation()
        default:
            disallowLocation()
        }
    }
    
}
