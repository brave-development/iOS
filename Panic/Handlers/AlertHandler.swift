//
//  AlertHandler.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/01/18.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import SwiftLocation
import Parse

let alertHandler = AlertHandler()

class AlertHandler: NSObject {
    
    var currentAlert: Sub_PFAlert?
    
    func startAlert(completionHandler handler: @escaping (Bool) -> Void) {
        
        Locator.currentPosition(accuracy: .room, timeout: Timeout.after(60), onSuccess: {
            location in
            print("Location found: \(location)")
            
            self.currentAlert = Sub_PFAlert(location: location)
            self.currentAlert?.saveInBackground(block: {
                (success, error) in
                
                if success {
                    handler(true)
                } else {
                    self.currentAlert = nil
                    handler(false)
                }
            })
        }) {
            (error, location) in
            print("Failed to get location: \(error)")
            handler(false)
        }
    }
    
    func updateDetails(details: String) {
        currentAlert!.details = details
        currentAlert!.saveInBackground(block: nil)
    }
    
    func sendPushNotification() {
        PFCloud.callFunction(inBackground: "pushFromId", withParameters: [
            "objectId" : currentAlert!.objectId,
            "installationId" : PFInstallation.current()!.objectId!
        ] ) {
            response, error in
            print(response)
        }
    }
}
