//
//  PanicHandler.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/09.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import Foundation
import Parse

var panicHandler = PanicHandler()

class PanicHandler: UIViewController {
    
    let query : PFQuery = PFQuery(className: "Panics")
    var queryObject : PFObject!
    var updating = false
    var objectInUse = false // Set to true when beginPanic() is called and object is created successfully on server. Only updates locations if set to true.
	var panicIsActive = false
	var updateDetailsQuery: PFQuery?
	var updateResponderCountQuery: PFQuery?
	var responderCount = 0
	var timer: NSTimer?
	var getActivePanicsTimer : NSTimer?
	var activePanicCount = 0
    
    func beginPanic (location : CLLocation) {
        if updating == false && queryObject == nil {
            println("BEGIN")
            updating = true
			panicIsActive = true //
            queryObject = PFObject(className: "Panics")
            queryObject["user"] = PFUser.currentUser()
            queryObject["location"] = PFGeoPoint(location: location)
            queryObject["active"] = true
			queryObject["responders"] = []
			println(queryObject.objectId)
            
            queryObject.saveInBackgroundWithBlock({ (result: Bool, error: NSError?) -> Void in
                if result == true
				{
                    self.updating = false
                    self.objectInUse = true
					self.timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "getResponderCount", userInfo: nil, repeats: true)
                } else if error != nil {
                    global.showAlert(NSLocalizedString("error_beginning_location_title", value: "Error beginning location", comment: ""), message: "\(error!.localizedDescription)\n" + NSLocalizedString("error_beginning_location_text", value: "Will try again in a few seconds", comment: ""))
                    self.updating = false
                }
            })
        }
    }
    
    func updatePanic (location : CLLocation) {
        
        if objectInUse == true {
            if queryObject != nil && updating == false {
                println("UPDATING")
                updating = true
                queryObject["location"] = PFGeoPoint(location: location)
                queryObject["active"] = true
                queryObject.saveInBackgroundWithBlock({
                    (result: Bool, error: NSError?) -> Void in
                    println("updatePanic - saveInBackground")
                    if result == true {
                        self.updating = false
                    } else if error != nil {
                        global.showAlert(NSLocalizedString("error_updating_location_title", value: "Error updating location", comment: ""), message: "\(error!.localizedDescription)\n" + NSLocalizedString("error_updating_location_text", value: "Will try again in a few seconds", comment: ""))
                        self.updating = false
                    }
                })
            }
        } else {
            beginPanic(location)
        }
    }
	
	func updateDetails(details: String) {
		if objectInUse == true {
			if queryObject != nil && updating == false {
				println("UPDATING details \(details)")
				updating = true
				queryObject["details"] = details
				queryObject.saveInBackgroundWithBlock({
					(result: Bool, error: NSError?) -> Void in
					println("updatePanic details - saveInBackground")
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
		if updateResponderCountQuery == nil && queryObject != nil{
			updateResponderCountQuery = PFQuery(className: "Panics")
			updateResponderCountQuery!.whereKey("objectId", equalTo: queryObject.objectId!)
			updateResponderCountQuery!.getFirstObjectInBackgroundWithBlock({
				(object: PFObject?, error: NSError?) -> Void in
				if object != nil {
					self.responderCount = (object!["responders"] as! [String]).count
					self.updateResponderCountQuery = nil
				} else {
					println(error)
					println(self.queryObject.objectId)
					self.updateResponderCountQuery = nil
				}
			})
		}
	}
	
	func pausePanic (paused : Bool = false) {
        if objectInUse == true {
            println("PAUSING")
            global.persistantSettings.setObject(queryObject.objectId!, forKey: "queryObjectId")
            endPanic(paused: paused)
        }
    }
    
    func resumePanic () {
        
        if global.persistantSettings.objectForKey("queryObjectId") != nil {
            println("RESUMING")
            println(global.persistantSettings.objectForKey("queryObjectId")!)
            queryObject = query.getObjectWithId(global.persistantSettings.objectForKey("queryObjectId")! as! String)
            objectInUse = true
			timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "getResponderCount", userInfo: nil, repeats: true)
        }
    }
    
	func endPanic (paused : Bool = false) {
        println("END")
		if paused == false { panicIsActive = false }
        query.cancel()
		timer?.invalidate()
        if queryObject != nil {
            queryObject["active"] = false
            queryObject.saveInBackgroundWithBlock({
                (result: Bool, error: NSError?) -> Void in
                if result == true {
                    println("END RUN CORRECTLY")
                } else {
                    println("END DIDNT FINISH - \(error!.localizedDescription)")
                }
            })
        }
        objectInUse = false
        queryObject = nil
    }
	
	// Get active panics, count them and show the number on the tabbar
	func getActivePanics() {
		println("Getting victims from mapViewController")
		var queryPanics = PFQuery(className: "Panics")
		queryPanics.whereKey("active", equalTo: true)
		queryPanics.findObjectsInBackgroundWithBlock({
			(objects : [AnyObject]?, error: NSError?) -> Void in
			if objects != nil {
				dispatch_async(dispatch_get_main_queue(), {
					self.activePanicCount = objects!.count
					NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "updatedActivePanics", object: nil))
//					println(objects)
				})
			} else {
				self.activePanicCount = 0
			}
//			println(self)
			self.getActivePanicsTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "getActivePanics", userInfo: nil, repeats: false)
		})
	}
}
