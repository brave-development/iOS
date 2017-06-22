//
//  GroupsHandler_2.swift
//  Panic (Pty) Ltd
//
//  Created by Byron Coetsee on 2017/06/22.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

let groupsHandler_2 = GroupsHandler_2()

class GroupsHandler_2: UIViewController {
    
    var joinedGroupsObject: [String : PFObject] = [:]
    var nearbyGroupObjects : [String : PFObject] = [:]
    
    
    func getGroups() {
        var groupFormatted: [String] = []
        
        let user = PFUser.current()!
        for group in user["groups"] as! [String] {
            
            joinedGroupsObject[group] = PFObject()
            groupFormatted.append(group.formatGroupForChannel())
        }
        
        getGroupDetails(groupName: nil)
        PFInstallation.current()?.setObject([""], forKey: "channels")
        PFInstallation.current()?.addUniqueObjects(from: groupFormatted, forKey: "channels")
        PFInstallation.current()?.saveInBackground(block: nil)
    }
    
    // Pass nil for all groups
    func getGroupDetails(groupName : String?) {
        
        for group in joinedGroupsObject.keys {
            let query = PFQuery(className: "Groups")
            query.whereKey("flatValue", equalTo: group.formatGroupForFlatValue())
            
            query.getFirstObjectInBackground(block: {
                (object, error) in
                
                if object != nil {
                    self.joinedGroupsObject[group] = object!
                    
                    // Making sure the user is a subscriber of the group object
                    object!.addUniqueObject(PFUser.current()!.objectId!, forKey: "subscriberObjects")
                }
            })
        }
    }
    
    // Adding a group
    func addGroup(group : PFObject, silentAdd: Bool = false) {
        let groupName = group["name"] as! String
        
        if joinedGroupsObject.count <= PFUser.current()!["numberOfGroups"] as! Int {
            joinedGroupsObject[groupName] = group
            
            group.addUniqueObject(PFUser.current()!.objectId!, forKey: "subscriberObjects")
            
            let count = (group["subscriberObjects"] as! [String]).count
            group["subscribers"] = count
            group.saveInBackground()
            
            if silentAdd == false {
                global.shareGroup(String(format: NSLocalizedString("share_joined_group", value: "I just joined the group %@ using Panic. Help me make our communities safer, as well as ourselves!", comment: ""), arguments: [groupName]), viewController: self)
            }
            
            saveGroupChanges()
        }
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
        
        global.persistantSettings.set(joinedGroupsObject.keys, forKey: "groups")
        global.persistantSettings.synchronize()
    }
    
    // Used to create a group with user = Panic
    func createGroup(_ groupName: String, country: String) {
        let query = PFQuery(className: "Groups")
        query.whereKey("flatValue", equalTo: groupName.formatGroupForFlatValue())
        query.findObjectsInBackground(block: {
            (object, error) in
            if object == nil {
                print("NO GROUP FOUND. CREATING - '\(groupName)'")
                let newGroupObject : PFObject = PFObject(className: "Groups")
                newGroupObject["name"] = groupName
                newGroupObject["flatValue"] = groupName.formatGroupForFlatValue()
                newGroupObject["country"] = country
                newGroupObject["admin"] = PFUser.init(withoutDataWithObjectId: "qP9SOINr4X")
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
