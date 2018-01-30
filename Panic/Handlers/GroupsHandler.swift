//
//  GroupsHandler_2.swift
//  Panic (Pty) Ltd
//
//  Created by Byron Coetsee on 2017/06/22.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

let groupsHandler = GroupsHandler()

class GroupsHandler: UIViewController {
    
    var joinedGroupsObject: [String : PFObject] = [:]
    var nearbyGroupObjects : [String : PFObject] = [:]
    
    var purchaseRunning = false
    
    func getGroups() {
        var groupFormatted: [String] = []
        
        let user = PFUser.current()!
        for group in user["groups"] as! [String] {
            
            joinedGroupsObject[group] = PFObject(className: "Groups")
            groupFormatted.append(group.formatGroupForChannel())
        }
        
        getGroupDetails()
        PFInstallation.current()?.setObject([""], forKey: "channels")
        PFInstallation.current()?.addUniqueObjects(from: groupFormatted, forKey: "channels")
        PFInstallation.current()?.saveInBackground(block: nil)
    }
    
    // Pass nil for all groups
    func getGroupDetails() {
        
        for group in joinedGroupsObject.keys {
            let query = PFQuery(className: "Groups")
            query.whereKey("flatValue", equalTo: group.formatGroupForFlatValue())
            
            query.getFirstObjectInBackground(block: {
                (object, error) in
                
                if object != nil {
                    self.joinedGroupsObject[group] = object!
                    
                    // Making sure the user is a subscriber of the group object
                    object!.addUniqueObject(PFUser.current()!.objectId!, forKey: "subscriberObjects")
                    object?.saveInBackground()
                }
            })
        }
    }
    
    // Adding a group
    func addGroup(group : PFObject) {
        let groupName = group["name"] as! String
        
        if joinedGroupsObject.count <= PFUser.current()!["numberOfGroups"] as! Int {
            joinedGroupsObject[groupName] = group
            
            group.addUniqueObject(PFUser.current()!.objectId!, forKey: "subscriberObjects")
            
            let count = (group["subscriberObjects"] as! [String]).count
            group["subscribers"] = count
            group.saveInBackground()
            
            global.shareGroup(String(format: NSLocalizedString("share_joined_group", value: "I just joined the group %@ using Brave. Help me make our communities safer, as well as ourselves!", comment: ""), arguments: [groupName]), viewController: self)
            
            saveGroupChanges()
        }
    }
    
    // Adding the user to a beta group
    func addBetaGroup(objectId: String) {
        
        let query = PFQuery(className: "Groups")
        query.getObjectInBackground(withId: objectId, block: {
            (result, error) -> Void in
            if error == nil {
                if result != nil {
                    let group = result! as PFObject
                    let groupName = group["name"] as! String
                    
                    self.joinedGroupsObject[groupName] = group
                    
                    group.addUniqueObject(PFUser.current()!.objectId!, forKey: "subscriberObjects")
                    let count = (group["subscriberObjects"] as! [String]).count
                    group["subscribers"] = count
                    group.saveInBackground()

                    self.saveGroupChanges()
                }
            }
        })
    }
    
    // Remove a group
    func removeGroup(group : PFObject) {
        let groupName = group["name"] as! String
        
        joinedGroupsObject[groupName] = nil
        
        group.remove(PFUser.current()!.objectId!, forKey: "subscriberObjects")
        
        let count = (group["subscriberObjects"] as! [String]).count
        group["subscribers"] = count
        group.saveInBackground()
        
        saveGroupChanges()
    }
    
    // Updates and saves any changes to groups in the current User object and Installation object
    func saveGroupChanges() {
        
        // Clearing arrays - thus taking care of deletions
        PFUser.current()!["groups"] = []
        PFInstallation.current()!["channels"] = []
        for group in joinedGroupsObject.keys {
            PFUser.current()!.addUniqueObject(group, forKey: "groups")
            PFInstallation.current()?.addUniqueObject(group.formatGroupForChannel(), forKey: "channels")
        }
        
        PFUser.current()!.saveInBackground()
        PFInstallation.current()!.saveInBackground()
    }
    
    // Checks if all the groups details have finished being retrieved
    func groupsFetchFinished() -> Bool {
        for (_, object) in joinedGroupsObject {
            if object.objectId == nil {
                return false
            }
        }
        
        for (_, object) in nearbyGroupObjects {
            if object.objectId == nil {
                return false
            }
        }
        
        return true
    }
    
    // Need to clean up...
    // Checks the DB to see if a group with the same name already exists
    func checkIfGroupExists(_ group: PFObject) -> Bool {
        let query = PFQuery(className: "Groups")
        query.whereKey("flatValue", equalTo: (group["name"] as! String).formatGroupForFlatValue())
        let objects = try! query.findObjects()
        
        if objects != nil {
            if objects.count == 0 {
                return false
            } else {
                let pfObject = objects.first!
                let name = pfObject["name"] as! String
                let country = pfObject["country"] as! String
                
                global.showAlert(NSLocalizedString("unsuccessful", value: "Unsuccessful", comment: ""), message: String(format: NSLocalizedString("group_already_exists", value: "Group '%@' already exists in %@", comment: ""), arguments: [name, country]))
            }
        }
        return true
    }
    
    // Addes a new group to the DB or returns false if it's there already
    func createNewGroup(group: PFObject, completion: @escaping (_ success: Bool, _ object: PFObject) -> Void) {
        let query = PFQuery(className: "Groups")
        query.whereKey("flatValue", equalTo: (group["name"] as! String).formatGroupForFlatValue())
        
        do {
            try query.getFirstObject()
            
            // Found another group with same name
            completion(false, group)
        } catch {
            group.saveInBackground(block: {
                success, error in
                completion(success, group)
            })
        }
    }
    
    // Creates a new group for an area
    func createNewAreaGroup(name: String, country: String) {
        let query = PFQuery(className: "Groups")
        query.whereKey("flatValue", equalTo: name.formatGroupForFlatValue())
        query.findObjectsInBackground(block: {
            (object, error) in
            if object == nil {
                print("NO GROUP FOUND. CREATING - '\(name)'")
                let newGroupObject : PFObject = PFObject(className: "Groups")
                newGroupObject["name"] = name
                newGroupObject["flatValue"] = name.formatGroupForFlatValue()
                newGroupObject["country"] = country
                newGroupObject["admin"] = PFUser.init(withoutDataWithObjectId: "GX2qQyNGm7")
                newGroupObject["public"] = true
                newGroupObject.saveInBackground(block: {
                    (result, error) in
                    if result == true {
                        print("GROUP CREATED")
                    } else {
                        print(error!)
                    }
                    print(error!)
                })
            } else {
                print("FOUND GROUP")
            }
        })
    }

}
