//
//  AnnotationCustom.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/03/16.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit
import MapKit
import Parse

class AnnotationCustom: NSObject, MKAnnotation {

	var coordinate: CLLocationCoordinate2D
	var title: String!
	var subtitle: String!
	var id: String!
	var object: PFObject!
	
	init(coordinate: CLLocationCoordinate2D, title: String, id: String, object: PFObject, details: String = "") {
		self.coordinate = coordinate
		self.title = title
		self.subtitle = details
		self.id = id
		self.object = object
	}
	
	func setNewCoordinate(_ newCoordinate: CLLocationCoordinate2D) {
		coordinate = newCoordinate
	}
	
	func setNewSubtitle(_ newSubtitle: String) {
		self.setValue(newSubtitle, forKey: "subtitle")
	}
}
