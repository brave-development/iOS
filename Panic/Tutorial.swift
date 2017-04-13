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
		print("Loading tutorial settings")
		if global.persistantSettings.object(forKey: "Panic") != nil {
			panic = global.persistantSettings.bool(forKey: "Panic")
		}
		
		if global.persistantSettings.object(forKey: "swipeToOpenMenu") != nil {
			swipeToOpenMenu = global.persistantSettings.object(forKey: "swipeToOpenMenu") as! Bool
		}

		if global.persistantSettings.object(forKey: "groupsButton") != nil {
			groupsButton = global.persistantSettings.bool(forKey: "groupsButton")
		}

		if global.persistantSettings.object(forKey: "addNewGroup") != nil {
			addNewGroup = global.persistantSettings.bool(forKey: "addNewGroup")
		}
		
		if global.persistantSettings.object(forKey: "addNewGroupView") != nil {
			addNewGroupView = global.persistantSettings.bool(forKey: "addNewGroupView")
		}

		if global.persistantSettings.object(forKey: "publicHistory") != nil {
			publicHistory = global.persistantSettings.object(forKey: "publicHistory") as! Bool
		}
		
		if global.persistantSettings.object(forKey: "localHistory") != nil {
			localHistory = global.persistantSettings.object(forKey: "localHistory") as! Bool
		}
		
		// Notices
		
	}
	
	func save() {
		global.persistantSettings.set(panic, forKey: "Panic")
		global.persistantSettings.set(swipeToOpenMenu, forKey: "swipeToOpenMenu")
		global.persistantSettings.set(groupsButton, forKey: "groupsButton")
		global.persistantSettings.set(addNewGroup, forKey: "addNewGroup")
		global.persistantSettings.set(addNewGroupView, forKey: "addNewGroupView")
		global.persistantSettings.set(publicHistory, forKey: "publicHistory")
		global.persistantSettings.set(localHistory, forKey: "localHistory")
		
		global.persistantSettings.synchronize()
	}
	
	func reset() {
		print("Resetting tutorial settings")
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
