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
    
    func startAlert(completionHandler handler: @escaping (Bool) -> Void) {
        
        Locator.currentPosition(accuracy: .block, timeout: Timeout.after(60), onSuccess: {
            location in
            print("Location found: \(location)")
            
            self.currentAlert = Sub_PFAlert(location: location)
            self.currentAlert?.saveInBackground(block: {
                (success, error) in
                
                if success {
                    self.addToAlertGroupTable()
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
        
        let url = "https://panicing-turtle.herokuapp.com/parse/functions/newAlertHook"
        
        let headers : HTTPHeaders = [
            "X-Parse-Application-Id" : "PANICING-TURTLE",
            "X-Parse-REST-API-Key" : "PANICINGTURTLE3847TR386TB281XN1NY7YNXM",
            "Content-Type" : "application/json"
        ]
        
        let body : Parameters = [
            "groups" : groups,
            "panic" : [
                "__type": "Pointer",
                "className": "Panics",
                "objectId": currentAlert!.objectId!
            ]
        ]
        
        Alamofire.request(url ,method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers).responseJSON {
            response in
            
            print("Finished update kjbdvksdbv")
            debugPrint(response)
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
