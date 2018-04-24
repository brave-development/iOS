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
import Alamofire
import SwiftyJSON

let alertHandler = AlertHandler()

class AlertHandler: NSObject {
    
    var currentAlert: Sub_PFAlert?
    
    func startAlert(drug: String, completionHandler handler: @escaping (Bool) -> Void) {
        
        Locator.currentPosition(accuracy: .block, timeout: Timeout.after(60), onSuccess: {
            location in
            print("Location found: \(location)")
            
            self.currentAlert = Sub_PFAlert(location: location)
            self.currentAlert?.details = drug
            self.currentAlert?.saveInBackground(block: {
                (success, error) in
                
                if success {
                    Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateCurrentAlert), userInfo: nil, repeats: false)
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
    
    func pause() {
        currentAlert?.active = false
        currentAlert?.saveInBackground()
    }
    
    func resume() {
        currentAlert?.active = true
        currentAlert?.saveInBackground()
    }
    
    func end() {
        currentAlert?.active = true
        currentAlert?.saveInBackground()
        currentAlert = nil
    }
    
    func updateDetails(details: String) {
        currentAlert!.details = details
        currentAlert!.saveInBackground(block: nil)
    }
    
    @objc func updateCurrentAlert() {
        currentAlert?.fetchInBackground(block: {
            alert, error in
            
            if self.currentAlert != nil {
                self.currentAlert = alert as! Sub_PFAlert
                
                Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateCurrentAlert), userInfo: nil, repeats: false)
            }
        })
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


extension AlertHandler {
    func addToAlertGroupTable() {
        var groups : [[String : Any]] = []
        
        for (_, group) in groupsHandler.joinedGroupsObject {
            groups.append(buildGroupPointer(objectId: group.objectId!))
        }
        
        let body : Parameters = [
            "groups" : groups,
            "panic" : [
                "__type": "Pointer",
                "className": "Alerts",
                "objectId": currentAlert!.objectId!
            ]
        ]
        
        PFCloud.callFunction(inBackground: "newAlertHook", withParameters: body) {
            response, _ in
            print(response)
        }
    }
    
    func buildGroupPointer(objectId : String) -> Parameters {
        return [
            "__type": "Pointer",
            "className": "Groups",
            "objectId": objectId
        ]
    }
}
