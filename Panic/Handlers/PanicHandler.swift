//
//  PanicHandler.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/09.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import Foundation
import Parse
import Alamofire

var panicHandler = PanicHandler()

class PanicHandler: UIViewController {
    
    let query : PFQuery = PFQuery(className: "Panics")
    var lastQueryObjectId : String? = nil
    var queryObject : PFObject!
    var updating = false
    var objectInUse = false // Set to true when beginPanic() is called and object is created successfully on server. Only updates locations if set to true.
    var panicIsActive = false
    var updateDetailsQuery: PFQuery<PFObject>?
    var updateResponderCountQuery: PFQuery<PFObject>?
    var responderCount = 0
    var timer: Timer?
    var getActivePanicsTimer : Timer?
    var activePanicCount = 0
    
    var respondingAlertObject: PFObject? = nil
    var respondingAlertObjectId: String? = nil
    
    func beginPanic (_ location : CLLocation) {
        if updating == false && queryObject == nil {
            print("BEGIN")
            updating = true
            panicIsActive = true
            queryObject = PFObject(className: "Panics")
            queryObject["user"] = PFUser.current()
            queryObject["location"] = PFGeoPoint(location: location)
            queryObject["active"] = true
            queryObject["responders"] = []
            
            queryObject.saveInBackground(block: {
                (result, error) in
                if result {
                    self.updating = false
                    self.objectInUse = true
                    self.lastQueryObjectId = self.queryObject.objectId
                    self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.getResponderCount), userInfo: nil, repeats: true)
                    
                    self.addToAlertGroupTable()
                } else if error != nil {
                    global.showAlert(NSLocalizedString("error_beginning_location_title", value: "Error beginning location", comment: ""), message: "\(error!.localizedDescription)\n" + NSLocalizedString("error_beginning_location_text", value: "Will try again in a few seconds", comment: ""))
                    self.updating = false
                }
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "objectCreated"), object: nil)
            })
        }
    }
    
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
            "user" : [
                "__type" : "Pointer",
                "className": "_User",
                "objectId": "NovecOw0Qt"
            ],
            "groups" : groups,
            "panic" : [
                "__type": "Pointer",
                "className": "Panics",
                "objectId": lastQueryObjectId
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
    
    func updatePanic (_ location : CLLocation) {
        
        if objectInUse == true {
            if queryObject != nil && updating == false {
                print("UPDATING")
                updating = true
                queryObject["location"] = PFGeoPoint(location: location)
                queryObject["active"] = true
                queryObject.saveInBackground(block: {
                    (result, error) in
                    print("updatePanic - saveInBackground")
                    self.updating = false
                    if error != nil {
                        global.showAlert(NSLocalizedString("error_updating_location_title", value: "Error updating location", comment: ""), message: "\(error!.localizedDescription)\n" + NSLocalizedString("error_updating_location_text", value: "Will try again in a few seconds", comment: ""))
                    }
                })
            }
        } else {
            beginPanic(location)
        }
    }
    
    func updateDetails(_ details: String) {
        if objectInUse == true {
            if queryObject != nil && updating == false {
                print("UPDATING details \(details)")
                updating = true
                queryObject["details"] = details
                queryObject.saveInBackground(block: {
                    (result, error) in
                    print("updatePanic details - saveInBackground")
                    if result == true {
                        self.updating = false
                    } else if error != nil {
                        global.showAlert(NSLocalizedString("error_updating_details_title", value: "Error updating details", comment: ""), message: "\(error!.localizedDescription)\n" + NSLocalizedString("error_updating_details_text", value: "Will try again in a few seconds", comment: ""))
                        self.updating = false
                    }
                })
            }
        }
    }
    
    func getResponderCount() {
        if updateResponderCountQuery == nil && lastQueryObjectId != nil{
            updateResponderCountQuery = PFQuery(className: "Panics")
            updateResponderCountQuery!.whereKey("objectId", equalTo: lastQueryObjectId!)
            updateResponderCountQuery!.getFirstObjectInBackground(block: {
                (object, error) in
                if object != nil {
                    self.responderCount = (object!["responders"] as! [String]).count
                    self.updateResponderCountQuery = nil
                } else {
                    print(error!)
                    print(self.queryObject.objectId!)
                    self.updateResponderCountQuery = nil
                }
            })
        }
    }
    
    func pausePanic (_ paused : Bool = false) {
        if objectInUse == true {
            print("PAUSING")
            global.persistantSettings.set(queryObject.objectId!, forKey: "queryObjectId")
            endPanic(paused)
        }
    }
    
    func resumePanic () {
        
        if global.persistantSettings.object(forKey: "queryObjectId") != nil {
            print("RESUMING")
            print(global.persistantSettings.object(forKey: "queryObjectId")!)
            queryObject = try! query.getObjectWithId(global.persistantSettings.object(forKey: "queryObjectId")! as! String)
            
            objectInUse = true
            timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(getResponderCount), userInfo: nil, repeats: true)
        }
    }
    
    func endPanic (_ paused : Bool = false) {
        print("END")
        if paused == false { panicIsActive = false }
        query.cancel()
        //        timer?.invalidate()
        if queryObject != nil {
            queryObject.saveInBackground(block: {
                (result, error) in
                if error == nil {
                    print("END RUN CORRECTLY")
                } else {
                    print("END DIDNT FINISH - \(error!.localizedDescription)")
                }
            })
        }
    }
    
    func clearPanic() {
        objectInUse = false
        queryObject = nil
    }
    
    func sendNotifications() {
        if lastQueryObjectId != nil {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "objectCreated"), object: nil)
            PFCloud.callFunction(inBackground: "pushFromId", withParameters: [
                "objectId" : lastQueryObjectId!,
                "installationId" : PFInstallation.current()!.objectId!
            ] ) {
                response, error in
                
                print(response)
            }
        } else {
            if panicIsActive == true {
                NotificationCenter.default.addObserver(self, selector: #selector(sendNotifications), name: NSNotification.Name(rawValue: "objectCreated"), object: nil)
            }
        }
    }
    
    // Get active panics, count them and show the number on the tabbar
    func getActivePanics(completion: @escaping ([PFObject])->Void) {
        var groups : [[String : Any]] = []
        
        for (_, group) in groupsHandler.joinedGroupsObject {
            groups.append(buildGroupPointer(objectId: group.objectId!))
        }
        
        PFCloud.callFunction(inBackground: "getActiveAlerts", withParameters: [ "groups" : groups ] ) {
            response, error in
            
            if let objects = response as? [PFObject] {
                var alerts : [PFObject] = []
                
                for object in objects {
                    (object["panic"] as! PFObject).setObject(object["user"], forKey: "user")
                    alerts.append(object["panic"] as! PFObject)
                }
                completion(alerts)
            } else {
                completion([])
            }
        }
        
//        print("Getting victims from mapViewController")
//        let queryPanics = PFQuery(className: "Panics")
//        queryPanics.whereKey("active", equalTo: true)
//        queryPanics.findObjectsInBackground(block: {
//            (objects, error) in
//            if objects != nil {
//                DispatchQueue.main.async(execute: {
//                    self.activePanicCount = objects!.count
//                    NotificationCenter.default.post(NSNotification(name: NSNotification.Name(rawValue: "updatedActivePanics"), object: nil) as Notification)
//                })
//            } else {
//                self.activePanicCount = 0
//            }
//            self.getActivePanicsTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.getActivePanics), userInfo: nil, repeats: false)
//        })
    }
}
