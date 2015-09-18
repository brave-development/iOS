//
//  MapViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/02.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Parse

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
	
	// Details
	@IBOutlet weak var viewDetails: UIVisualEffectView!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var lblContact: UILabel!
	@IBOutlet weak var lblDetails: UILabel!
	@IBOutlet weak var lblResponders: UILabel!
	@IBOutlet weak var lblTime: UILabel!
	@IBOutlet weak var lblAddress: UILabel!
	@IBOutlet weak var btnCall: UIButton!
	@IBOutlet weak var btnRespond: UIButton!
	@IBOutlet weak var btnCloseDetails: UIButton!
	
    var manager: CLLocationManager! = CLLocationManager()
    var locationPermission: Bool = false
    var centerMapLocation: dispatch_once_t = 0 // Predicate for dispatch once
    var locationPermissionDispatch: dispatch_once_t = 0
	var victimDetails : [String : PFObject] = [:]
    var timer : NSTimer!
	var detailsTimer: NSTimer!
    var queryPanicsIsActive = false
    var selectedVictim : PFObject?
    var viewIsActive = false
	var dateFormatter = NSDateFormatter()
    
    let queryPanics : PFQuery = PFQuery(className: "Panics")
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		PFAnalytics.trackEventInBackground("Map", dimensions: nil, block: nil)
		
		dateFormatter.locale = NSLocale.currentLocale()
        dateFormatter.dateFormat = "MMM dd, yyyy, HH:mm"
		
		viewDetails.hidden = true
		viewDetails.alpha = 0.0
		viewDetails.layer.shadowRadius = 5
		viewDetails.layer.shadowOpacity = 1
		viewDetails.layer.shadowOffset = CGSizeZero
		viewDetails.layer.cornerRadius = 5
		viewDetails.clipsToBounds = true
		
		self.lblAddress.text = ""
		self.lblDetails.text = ""
		
        manager.requestAlwaysAuthorization()
        
		if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways) || (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse) {
			locationPermission = true
		}
		
		var theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.5, 0.5)
		var theRegion: MKCoordinateRegion!
		if global.openedViaNotification == true {
			let lat = global.notificationDictionary!["lat"] as! Double
			let long = global.notificationDictionary!["long"] as! Double
			theRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(lat, long), theSpan)
			dispatch_once(&centerMapLocation, {
				global.notificationDictionary = [:]
				global.openedViaNotification = false
			}) // So the map doesnt focus on the user
		} else {
			theRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(-33.9206605, 18.424724), theSpan)
		}
		
		map.setRegion(theRegion, animated: true)
		map.showsUserLocation = true
        map.mapType = MKMapType.Standard
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        viewIsActive = true
        getVictims()
    }
    
	func setMapRegion(coords: CLLocationCoordinate2D) {
        if manager.location != nil {
            var theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
            var theRegion: MKCoordinateRegion = MKCoordinateRegionMake(manager.location.coordinate, theSpan)
            map.setRegion(theRegion, animated: true)
        }
    }
	
    func getVictims() {
		println("Getting victims from mapViewController")
		if queryPanicsIsActive == false {
			queryPanics.cancel()
			queryPanics.whereKey("active", equalTo: true)
			queryPanics.includeKey("user")
			queryPanics.findObjectsInBackgroundWithBlock({
				(objects : [AnyObject]?, error: NSError?) -> Void in
				self.queryPanicsIsActive = true
				if error == nil {
					self.victimDetails = [:]
					for object in objects! {
						let tempObject = object as! PFObject
						self.victimDetails[(tempObject["user"] as! PFUser)["name"] as! String] = (tempObject)
					}
					self.updateAnnotations()
				} else {
					if error!.localizedFailureReason != nil {
						global.showAlert("", message: error!.localizedFailureReason!)
					} else {
						global.showAlert("", message: "Could not get the list of Panics. Please check your internet connection and try again")
					}
				}
				self.queryPanicsIsActive = false
			})
		}
		
        // CHANGE TO 30 SECONDS BEFORE RELEASE.........
		
        if viewIsActive == true {
            timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "getVictims", userInfo: nil, repeats: false)
        } else if viewIsActive == false {
            manager.stopUpdatingLocation()
            manager.delegate = nil
            map.delegate = nil
            println("Disabled timer")
            timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "freeMem", userInfo: nil, repeats: false)
        }
        
        if global.queryUsersBusy == true {
            
        }
    }
    
    // Updating annotations
    func updateAnnotations() {
		var liveAnnotationIds: [String : AnnotationCustom] = [:]
        for (name, object) in victimDetails {
			var anno: AnnotationCustom!
			let id = (object as PFObject).objectId
			let location = CLLocationCoordinate2D(latitude: ((object as PFObject)["location"] as! PFGeoPoint).latitude, longitude: ((object as PFObject)["location"]as! PFGeoPoint).longitude)
			if (object as PFObject)["details"] != nil {
				let details = (object as PFObject)["details"] as! String
				anno = AnnotationCustom(coordinate: location, title: name, id: id!, object: (object as PFObject), details: details)
			} else {
				anno = AnnotationCustom(coordinate: location, title: name, id: id!, object: (object as PFObject))
			}
			liveAnnotationIds[id!] = anno
        }
		addAnnotations(liveAnnotationIds)
    }
	
	func addAnnotations(annotations: [String : AnnotationCustom]) {
		
		// Run through current annots on map
		var liveDict = annotations
		for currentAnnotation in map.annotations {
			if currentAnnotation is AnnotationCustom {
				let currentAnnotationCustom = currentAnnotation as! AnnotationCustom
				// If current annot is not found in live annots --> remove from map
				// Else --> remove from dictionary
				if liveDict[currentAnnotationCustom.id] == nil {
					map.removeAnnotation(currentAnnotationCustom)
				} else {
					// Sets coordinate of map annot, then remove from dictionary
					UIView.animateWithDuration(0.5, animations: {
						
						currentAnnotationCustom.setNewSubtitle(liveDict[currentAnnotationCustom.id]!.subtitle)
						currentAnnotationCustom.setNewCoordinate(liveDict[currentAnnotationCustom.id]!.coordinate)
						
						self.map.setCenterCoordinate(self.map.centerCoordinate, animated: false)
					})
					
					liveDict.removeValueForKey(currentAnnotationCustom.id)
				}
			}
		}
		
		for (id, anno) in liveDict {
			map.addAnnotation(anno)
		}
	}
	
    // When the user taps on an annotation
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!)
    {
        selectedVictim = victimDetails[view.annotation.title!]
    }
    
    // How to add annotations
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
    {
        if !annotation.isEqual(mapView.userLocation) {
			let anno = annotation as! AnnotationCustom
			var view: MKAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Standard")
            var btnViewRight: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
            btnViewRight.addTarget(self, action: "showDetailsView", forControlEvents: UIControlEvents.TouchUpInside)
			
			var btnViewLeft: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
            btnViewLeft.setImage(UIImage(named: "call"), forState: UIControlState.Normal)
			btnViewLeft.addTarget(self, action: "callVictim", forControlEvents: UIControlEvents.TouchUpInside)
			
			view.rightCalloutAccessoryView = btnViewRight
			view.leftCalloutAccessoryView = btnViewLeft
			
            view.image = UIImage(named: "panic")
            view.enabled = true
            view.canShowCallout = true
            view.centerOffset = CGPointMake(0, 0)
            return view
        } else {
            return nil
        }
    }
	
	func showDetailsView() {
		self.viewDetails.hidden = false
		populateDetails()
		UIView.animateWithDuration(0.5, animations: {
			self.viewDetails.alpha = 1.0
			})
	}
	
	func populateDetails() {
		let name = (selectedVictim!["user"] as! PFUser)["name"] as! String
		let victimInfo = (victimDetails[name]! as PFObject)["user"] as! PFUser
		let panicDetails = victimDetails[name]! as PFObject
		lblName.text = victimInfo["name"] as? String
		lblContact.text = victimInfo["cellNumber"] as? String
		
		detailsTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "getDetails", userInfo: nil, repeats: true)
		getDetails()
		
		if panicDetails["responders"] != nil {
			let numberOfResponders = (panicDetails["responders"] as! [PFUser]).count
			lblResponders.text = "\(numberOfResponders)"
		} else {
			lblResponders.text = "0"
		}
		
		lblTime.text = dateFormatter.stringFromDate(panicDetails.createdAt!)
		getAddress()
		
		if isResponding() == true {
			btnRespond.setTitle("Stop Responding", forState: UIControlState.Normal)
			btnRespond.backgroundColor = UIColor(red:0.91, green:0.3, blue:0.24, alpha:1)
		} else {
			btnRespond.setTitle("Respond", forState: UIControlState.Normal)
			btnRespond.backgroundColor = UIColor(red:0.18, green:0.8, blue:0.44, alpha:1)
		}
	}
	
	func getDetails() {
		let name = (selectedVictim!["user"] as! PFUser)["name"] as! String
		if victimDetails[name] != nil {
			let panicDetails = victimDetails[name]! as PFObject
			
			if panicDetails["details"] != nil {
				lblDetails.text = panicDetails["details"] as? String
			}
		} else {
			detailsTimer.invalidate()
			closeDetails(btnCloseDetails)
			selectedVictim = nil
		}
	}
	
	func isResponding() -> Bool {
		let responders = selectedVictim!["responders"] as! [String]
		let currentUserObjectId = PFUser.currentUser()!.objectId
		if find(responders, currentUserObjectId!) != nil {
			return true
		}
		return false
	}
	
	// Getting address
	func getAddress() {
		var geocode = CLGeocoder()
		let location = CLLocation(latitude: (selectedVictim?["location"] as! PFGeoPoint).latitude , longitude: (selectedVictim?["location"] as! PFGeoPoint).longitude)
		geocode.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
			if error != nil {
				println("Error in reverse geocode... \(error)")
			}
			
			if placemarks != nil {
				if placemarks.count > 0 {
					let pm = placemarks[0] as! CLPlacemark
					var address: [String] = []
					if pm.thoroughfare != nil { address.append(pm.thoroughfare as String) }
					if pm.subLocality != nil { address.append(pm.subLocality as String) }
					if pm.subAdministrativeArea != nil { address.append(pm.subAdministrativeArea as String) }
					if pm.country != nil { address.append(pm.country as String) }
					
					for element in address {
						self.lblAddress.text = "\(self.lblAddress.text!)\n\(element)"
					}
				}
			} else {
				println("Error in reverse geocode... placemarks = nil")
			}
		})
	}
	
	func callVictim() {
		call(btnCall)
	}
    
	@IBAction func call(sender: AnyObject) {
		let victimInfo = selectedVictim!["user"] as! PFUser
		let cell = victimInfo["cellNumber"] as? String
//		println(cell!)
		if cell != nil {
			var url = NSURL(string: "tel://\(cell!)")
			UIApplication.sharedApplication().openURL(url!)
		}
	}
	
	@IBAction func respond(sender: AnyObject) {
		if isResponding() == true {
			selectedVictim!.removeObjectsInArray([PFUser.currentUser()!.objectId!], forKey: "responders")
			btnRespond.setTitle("Respond", forState: UIControlState.Normal)
			btnRespond.backgroundColor = UIColor(red:0.18, green:0.8, blue:0.44, alpha:1)
		} else {
			selectedVictim!.addUniqueObject(PFUser.currentUser()!.objectId!, forKey: "responders")
			btnRespond.setTitle("Stop Responding", forState: UIControlState.Normal)
			btnRespond.backgroundColor = UIColor(red:0.91, green:0.3, blue:0.24, alpha:1)
		}
		
		selectedVictim!.saveInBackgroundWithBlock({
			(result: Bool, error: NSError?) -> Void in
			if result == true {
				println("done")
			} else if error != nil {
				global.showAlert("Error becoming a responder", message: "\(error!.localizedDescription)\nWill try again in a few seconds")
			}
		})

		// Add current user object to array... Use same way as adding channels to installation. "AddUnique" or something
	}
	
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
		if manager.location.horizontalAccuracy < 201 {
			dispatch_once(&centerMapLocation, {
					var theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.05, 0.05)
					var theRegion: MKCoordinateRegion = MKCoordinateRegionMake(manager.location.coordinate, theSpan)
					self.map.setRegion(theRegion, animated: true)
			})
		}
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
		if global.didChangeAuthStatus(manager, status: status) == true {
			locationAllowed()
		} else {
			 locationNotAllowed(false)
		}
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!)
    {
        println(error)
        dispatch_once(&locationPermissionDispatch, {
            if error.localizedFailureReason != nil{
                global.showAlert(error.localizedDescription, message: error.localizedFailureReason!)
            } else {
                println("didFailWithError - \(error)")
                global.showAlert("Location Error", message: "Location Services are unavailable at the moment.\n\nPossible reasons:\nInternet Connection\nIndoors\nLocation Permission")
            }
        })
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer!
    {
        var polylineRender: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRender.lineWidth = 5.0
        polylineRender.strokeColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.95)
        return polylineRender;
    }
    
    func locationAllowed() {
        println("Location Allowed!!")
        
        locationPermission = true
        locationPermissionDispatch = 0
        manager.startUpdatingLocation()
    }
    
    func locationNotAllowed(showMessage: Bool) {
        println("Location NOT Allowed!!")
        
        locationPermission = false
        manager.stopUpdatingLocation()
    }
	
	@IBAction func closeDetails(sender: AnyObject) {
		UIView.animateWithDuration(0.5, animations: {
			self.viewDetails.alpha = 0.0
			}, completion: {
				(result: Bool) -> Void in
				self.viewDetails.hidden = true
				self.detailsTimer.invalidate()
		})
	}
	
	func updateActivePanics() {
		//		if panicHandler.activePanicCount > 0 {
		//			tabbarViewController.badge.hidden = false
		//		} else {
		//			tabbarViewController.badge.hidden = true
		//		}
//		tabbarViewController.badge.autoBadgeSizeWithString("\(panicHandler.activePanicCount)")
		println("Updated panic count from Map")
	}
    
    func freeMem() {
        map.mapType = MKMapType.Hybrid
        map.removeFromSuperview()
        map = nil
        manager = nil
    }
    
    override func viewWillDisappear(animated: Bool) {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "updatedActivePanics", object: nil)
        viewIsActive = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        map.mapType = MKMapType.Hybrid
        map.mapType = MKMapType.Standard
    }
}
