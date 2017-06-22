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
    
    var do_centerMapLocation = 0
    var do_locationError = 0
    
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
	@IBOutlet weak var btnMapType: UIButton!
	
    var manager: CLLocationManager! = CLLocationManager()
    var locationPermission: Bool = false
    var centerMapLocation: Int = 0 // Predicate for dispatch once
    var locationPermissionDispatch: Int = 0
	var victimDetails : [String : PFObject] = [:]
    var timer : Timer!
	var detailsTimer: Timer!
    var queryPanicsIsActive = false
    var selectedVictim : PFObject?
    var viewIsActive = false
	var dateFormatter = DateFormatter()
    
    let queryPanics : PFQuery = PFQuery(className: "Panics")
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		PFAnalytics.trackEvent(inBackground: "Map", dimensions: nil, block: nil)
		
		dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "MMM dd, yyyy, HH:mm"
		
		viewDetails.isHidden = true
		viewDetails.alpha = 0.0
		viewDetails.layer.shadowRadius = 5
		viewDetails.layer.shadowOpacity = 1
		viewDetails.layer.shadowOffset = CGSize.zero
		viewDetails.layer.cornerRadius = 5
		viewDetails.clipsToBounds = true
		
		self.lblAddress.text = ""
		self.lblDetails.text = ""
		
        manager.requestAlwaysAuthorization()
        
		if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways) || (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse) {
			locationPermission = true
		}
		
		let theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.5, 0.5)
		var theRegion: MKCoordinateRegion!
		if global.openedViaNotification == true {
			let lat = global.notificationDictionary!["lat"].doubleValue
			let long = global.notificationDictionary!["lng"].doubleValue
			theRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(lat, long), theSpan)
            
            if do_centerMapLocation == 0 {
                map.setRegion(theRegion, animated: true)
                do_centerMapLocation = 1
            }
            
		} else {
			theRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(-33.9206605, 18.424724), theSpan)
		}
		
		map.setRegion(theRegion, animated: true)
		map.showsUserLocation = true
		
		if global.persistantSettings.object(forKey: "mapType") != nil {
			switch (global.persistantSettings.object(forKey: "mapType") as! String) {
			case "standard":
				map.mapType = MKMapType.standard
				break
				
			case "satellite":
				map.mapType = MKMapType.satellite
				break
				
			case "hybrid":
				map.mapType = MKMapType.hybrid
				break
				
			default:
				break
			}
		}
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        viewIsActive = true
		
		btnMapType.layer.cornerRadius = btnMapType.frame.size.height * 0.5
		btnMapType.layer.shadowOffset = CGSize.zero
		btnMapType.layer.shadowRadius = 4
		btnMapType.layer.shadowOpacity = 0.7
		
        getVictims()
    }
    
	func setMapRegion(_ coords: CLLocationCoordinate2D) {
        if manager.location != nil {
            let theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
            let theRegion: MKCoordinateRegion = MKCoordinateRegionMake(manager.location!.coordinate, theSpan)
            map.setRegion(theRegion, animated: true)
        }
    }
	
    func getVictims() {
		print("Getting victims from mapViewController")
		if queryPanicsIsActive == false {
			queryPanics.cancel()
			queryPanics.whereKey("active", equalTo: true)
			queryPanics.includeKey("user")
			queryPanics.findObjectsInBackground(block: {
				(objects, error) in
				self.queryPanicsIsActive = true
				if error == nil {
					self.victimDetails = [:]
					for object in objects! {
//						let tempObject = object 
//						self.victimDetails[(tempObject["user"] as! PFUser)["name"] as! String] = (tempObject)
                        self.victimDetails[object.objectId!] = object
					}
					self.updateAnnotations()
				} else {
                    global.showAlert("Could not get the list of Panics", message: NSLocalizedString("could_not_get_panic_history", value: "Could not get the list of Panics. Please check your internet connection and try again", comment: ""))
				}
				self.queryPanicsIsActive = false
			})
		}
		
        // CHANGE TO 30 SECONDS BEFORE RELEASE.........
		
        if viewIsActive == true {
            timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(getVictims), userInfo: nil, repeats: false)
        } else if viewIsActive == false {
            manager.stopUpdatingLocation()
            manager.delegate = nil
            map.delegate = nil
            print("Disabled timer")
            timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(freeMem), userInfo: nil, repeats: false)
        }
    }
    
    // Updating annotations
    func updateAnnotations() {
		var liveAnnotationIds: [String : AnnotationCustom] = [:]
        for (name, object) in victimDetails {
            if (object as PFObject)["user"] != nil {
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
        }
		addAnnotations(liveAnnotationIds)
    }
	
	func addAnnotations(_ annotations: [String : AnnotationCustom]) {
		
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
					UIView.animate(withDuration: 0.5, animations: {
						
						currentAnnotationCustom.setNewSubtitle(liveDict[currentAnnotationCustom.id]!.subtitle)
						currentAnnotationCustom.setNewCoordinate(liveDict[currentAnnotationCustom.id]!.coordinate)
						
						self.map.setCenter(self.map.centerCoordinate, animated: false)
					})
					
					liveDict.removeValue(forKey: currentAnnotationCustom.id)
				}
			}
		}
		
		for (_, anno) in liveDict {
			map.addAnnotation(anno)
		}
	}
	
    // When the user taps on an annotation
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let objectId = (view.annotation as? AnnotationCustom)?.object.objectId! {
            selectedVictim = victimDetails[objectId]
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !annotation.isEqual(mapView.userLocation) {
			let view: MKAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Standard")
			let btnViewRight: UIButton = UIButton(type: UIButtonType.detailDisclosure)
            btnViewRight.addTarget(self, action: #selector(showDetailsView), for: UIControlEvents.touchUpInside)
			
			let btnViewLeft: UIButton = UIButton(type: UIButtonType.detailDisclosure)
            btnViewLeft.setImage(UIImage(named: "call"), for: UIControlState())
			btnViewLeft.addTarget(self, action: #selector(callVictim), for: UIControlEvents.touchUpInside)
			
			view.rightCalloutAccessoryView = btnViewRight
			view.leftCalloutAccessoryView = btnViewLeft
			
            view.image = UIImage(named: "mapPin")
            view.isEnabled = true
            view.canShowCallout = true
            view.centerOffset = CGPoint(x: 0, y: -20)
			view.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
			
            return view
        } else {
            return nil
        }
    }
	
	@IBAction func changeMapType(_ sender: AnyObject) {
		let mapOptions = UIAlertController(title: "Map type", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
		
		let standard = UIAlertAction(title: "Standard", style: .default) { (_) in
			self.map.mapType = MKMapType.standard
			global.persistantSettings.set("standard", forKey: "mapType")
		}
		
		let sat = UIAlertAction(title: "Satellite", style: .default) { (_) in
			self.map.mapType = MKMapType.satellite
			global.persistantSettings.set("satellite", forKey: "mapType")
		}
		
		let hybrid = UIAlertAction(title: "Hybrid", style: .default) { (_) in
			self.map.mapType = MKMapType.hybrid
			global.persistantSettings.set("hybrid", forKey: "mapType")
		}
		global.persistantSettings.synchronize()
		
		mapOptions.addAction(standard)
		mapOptions.addAction(sat)
		mapOptions.addAction(hybrid)
		mapOptions.addAction( UIAlertAction(title: "Cancel", style: .cancel) { (_) in } )
		
		mapOptions.popoverPresentationController?.sourceView = self.btnMapType
		self.present(mapOptions, animated: true, completion: nil)
	}
	
	func showDetailsView() {
		self.viewDetails.isHidden = false
		populateDetails()
		UIView.animate(withDuration: 0.5, animations: {
			self.viewDetails.alpha = 1.0
			})
	}
	
	func populateDetails() {
        let objectId = selectedVictim!.objectId!
        let panicDetails = victimDetails[objectId]! as PFObject
        
        let victimInfo = (victimDetails[objectId]! as PFObject)["user"] as! PFUser
		lblName.text = victimInfo["name"] as? String
		lblContact.text = victimInfo["cellNumber"] as? String
		
		detailsTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(getDetails), userInfo: nil, repeats: true)
		getDetails()
		
		if panicDetails["responders"] != nil {
			let numberOfResponders = (panicDetails["responders"] as! [PFUser]).count
			lblResponders.text = "\(numberOfResponders)"
		} else {
			lblResponders.text = "0"
		}
		
		lblTime.text = dateFormatter.string(from: panicDetails.createdAt!)
		getAddress()
		
		if isResponding() == true {
			btnRespond.setTitle(NSLocalizedString("stop_responding", value: "Stop Responding", comment: ""), for: UIControlState())
			btnRespond.backgroundColor = UIColor(red:0.91, green:0.3, blue:0.24, alpha:1)
		} else {
			btnRespond.setTitle(NSLocalizedString("respond", value: "Respond", comment: ""), for: UIControlState())
			btnRespond.backgroundColor = UIColor(red:0.18, green:0.8, blue:0.44, alpha:1)
		}
	}
	
	func getDetails() {
		if let panicDetails = victimDetails[selectedVictim!.objectId!] as? PFObject {
			if panicDetails["details"] != nil {
				lblDetails.text = panicDetails["details"] as? String
            } else {
                lblDetails.text = "No details"
            }
		} else {
			detailsTimer.invalidate()
			closeDetails(btnCloseDetails)
			selectedVictim = nil
		}
	}
	
	func isResponding() -> Bool {
		let responders = selectedVictim!["responders"] as! [String]
		let currentUserObjectId = PFUser.current()!.objectId
		if responders.index(of: currentUserObjectId!) != nil {
			return true
		}
		return false
	}
	
	// Getting address
	func getAddress() {
		let geocode = CLGeocoder()
		let location = CLLocation(latitude: (selectedVictim?["location"] as! PFGeoPoint).latitude , longitude: (selectedVictim?["location"] as! PFGeoPoint).longitude)
		geocode.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
			if error != nil {
				print("Error in reverse geocode... \(error!)")
			}
			
			if placemarks != nil {
				if placemarks!.count > 0 {
					let pm = placemarks![0]
					var address: [String] = []
					if pm.thoroughfare != nil { address.append(pm.thoroughfare! as String) }
					if pm.subLocality != nil { address.append(pm.subLocality! as String) }
					if pm.subAdministrativeArea != nil { address.append(pm.subAdministrativeArea! as String) }
					if pm.country != nil { address.append(pm.country! as String) }
					
					for element in address {
						self.lblAddress.text = "\(self.lblAddress.text!)\n\(element)"
					}
				}
			} else {
				print("Error in reverse geocode... placemarks = nil")
			}
		})
	}
	
	func callVictim() {
		call(btnCall)
	}
    
	@IBAction func call(_ sender: AnyObject) {
		let victimInfo = selectedVictim!["user"] as! PFUser
		let cell = victimInfo["cellNumber"] as? String
//		print(cell!)
		if cell != nil {
			let url = URL(string: "tel://\(cell!)")
			UIApplication.shared.openURL(url!)
		}
	}
	
	@IBAction func respond(_ sender: AnyObject) {
		if isResponding() == true {
			selectedVictim!.removeObjects(in: [PFUser.current()!.objectId!], forKey: "responders")
			btnRespond.setTitle(NSLocalizedString("respond", value: "Respond", comment: ""), for: UIControlState())
			btnRespond.backgroundColor = UIColor(red:0.18, green:0.8, blue:0.44, alpha:1)
		} else {
			selectedVictim!.addUniqueObject(PFUser.current()!.objectId!, forKey: "responders")
			btnRespond.setTitle(NSLocalizedString("stop_responding", value: "Stop Responding", comment: ""), for: UIControlState())
			btnRespond.backgroundColor = UIColor(red:0.91, green:0.3, blue:0.24, alpha:1)
		}
		
		selectedVictim!.saveInBackground(block: {
			(result, error) in
			if result == true {
				print("done")
			} else if error != nil {
				global.showAlert("", message: String(format: NSLocalizedString("error_becoming_a_responder", value: "%@\nWill try again in a few seconds.", comment: ""), arguments: [error!.localizedDescription]))
			}
		})

		// Add current user object to array... Use same way as adding channels to installation. "AddUnique" or something
	}
	
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
		if manager.location!.horizontalAccuracy < 201 {
			// Migrator FIXME: multiple dispatch_once calls using the same dispatch_once_t token cannot be automatically migrated
            if do_centerMapLocation == 0 {
					let theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.05, 0.05)
					let theRegion: MKCoordinateRegion = MKCoordinateRegionMake(manager.location!.coordinate, theSpan)
					self.map.setRegion(theRegion, animated: true)
                do_centerMapLocation = 1
			}
		}
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
		if global.didChangeAuthStatus(manager, status: status) == true {
			locationAllowed()
		} else {
			 locationNotAllowed(false)
		}
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        if do_locationError == 0 {
            global.showAlert("Something went wrong", message: error.localizedDescription)
            do_locationError = 1
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRender: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRender.lineWidth = 5.0
        polylineRender.strokeColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.95)
        return polylineRender;
    }
    
    func locationAllowed() {
        print("Location Allowed!!")
        
        locationPermission = true
        locationPermissionDispatch = 0
        manager.startUpdatingLocation()
    }
    
    func locationNotAllowed(_ showMessage: Bool) {
        print("Location NOT Allowed!!")
        
        locationPermission = false
        manager.stopUpdatingLocation()
    }
	
	@IBAction func closeDetails(_ sender: AnyObject) {
		UIView.animate(withDuration: 0.5, animations: {
			self.viewDetails.alpha = 0.0
			}, completion: {
				(result: Bool) -> Void in
				self.viewDetails.isHidden = true
				self.detailsTimer.invalidate()
		})
	}
    
    func freeMem() {
        map.mapType = MKMapType.hybrid
        map.removeFromSuperview()
        map = nil
        manager = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "updatedActivePanics"), object: nil)
        viewIsActive = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        map.mapType = MKMapType.hybrid
        map.mapType = MKMapType.standard
    }
}
