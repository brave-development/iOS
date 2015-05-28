//
//  Tutorial.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/25.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import Foundation

var tutorial : Tutorial = Tutorial()

class Tutorial {
	
	var swipeToOpenMenu = false
	var groupsButton = false
	var addNewGroup = false
	var addNewGroupView = false
	var publicHistory = false
	var localHistory = false
	var panic = false
	
	func load() {
		println("Loading tutorial settings")
		if global.persistantSettings.objectForKey("panic") != nil {
			panic = global.persistantSettings.boolForKey("panic")
		}
		
		if global.persistantSettings.objectForKey("swipeToOpenMenu") != nil {
			swipeToOpenMenu = global.persistantSettings.objectForKey("swipeToOpenMenu") as! Bool
		}

		if global.persistantSettings.objectForKey("groupsButton") != nil {
			groupsButton = global.persistantSettings.boolForKey("groupsButton")
		}

		if global.persistantSettings.objectForKey("addNewGroup") != nil {
			addNewGroup = global.persistantSettings.boolForKey("addNewGroup")
		}
		
		if global.persistantSettings.objectForKey("addNewGroupView") != nil {
			addNewGroupView = global.persistantSettings.boolForKey("addNewGroupView")
		}

		if global.persistantSettings.objectForKey("publicHistory") != nil {
			publicHistory = global.persistantSettings.objectForKey("publicHistory") as! Bool
		}
		
		if global.persistantSettings.objectForKey("localHistory") != nil {
			localHistory = global.persistantSettings.objectForKey("localHistory") as! Bool
		}
		
		// Notices
		
	}
	
	func save() {
		global.persistantSettings.setObject(panic, forKey: "panic")
		global.persistantSettings.setObject(swipeToOpenMenu, forKey: "swipeToOpenMenu")
		global.persistantSettings.setObject(groupsButton, forKey: "groupsButton")
		global.persistantSettings.setObject(addNewGroup, forKey: "addNewGroup")
		global.persistantSettings.setObject(addNewGroupView, forKey: "addNewGroupView")
		global.persistantSettings.setObject(publicHistory, forKey: "publicHistory")
		global.persistantSettings.setObject(localHistory, forKey: "localHistory")
		
		global.persistantSettings.synchronize()
	}
	
	func reset() {
		println("Resetting tutorial settings")
		panic = false
		swipeToOpenMenu = false
		groupsButton = false
		addNewGroup = false
		addNewGroupView = false
		publicHistory = false
		localHistory = false
		save()
	}
}
