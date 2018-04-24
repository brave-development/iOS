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
import ParseLiveQuery

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var do_centerMapLocation = 0
    var do_locationError = 0
    var do_openNotificationPin = 0
    
    @IBOutlet weak var map: MKMapView!
	
	// Details
	@IBOutlet weak var viewDetails: UIVisualEffectView!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var lblContact: UILabel!
	@IBOutlet weak var lblDetails: UILabel!
	@IBOutlet weak var lblResponders: UILabel!
	@IBOutlet weak var lblTime: UILabel!
	@IBOutlet weak var lblAddress: UILabel!
	@IBOutlet weak var btnChat: UIButton!
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
    var queryAlertsIsActive = false
    var selectedVictim : PFObject?
    var viewIsActive = false
	var dateFormatter = DateFormatter()
    
    let queryAlerts : PFQuery = PFQuery(className: "Alerts")
    var subscription_victim_added : Subscription<PFObject>!
    var subscription_victim_updated : Subscription<PFObject>!
    var subscription_victim_removed : Subscription<PFObject>!
    var subscription_victim_entered : Subscription<PFObject>!
    var subscription_victim_left : Subscription<PFObject>!
    
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
		
		let theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.3, 0.3)
		var theRegion: MKCoordinateRegion!
		if global.openedViaNotification == true {
			let lat = global.notificationDictionary!["lat"].doubleValue
			let long = global.notificationDictionary!["lng"].doubleValue
			theRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(lat, long), theSpan)
            
            if do_centerMapLocation == 0 {
                map.setRegion(theRegion, animated: true)
                do_centerMapLocation = 1
            }
            
            do_openNotificationPin = 1
            global.openedViaNotification = false
            
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
    
    func addSubscriptions() {
        let query = PFQuery(className: "Alerts")
        query.includeKey("user")
        query.whereKeyExists("details")
//        query.includeKey("panic")
//        query.includeKey("group")
//        query.whereKeyExists("group")
//        query.whereKeyExists("user")
//        query.whereKeyExists("panic")
//        query.whereKey("active", equalTo: true)
//        query.whereKey("group", containedIn: groupsHandler.joinedGroupsObject.map {$0.value.pointer()})
        
        subscription_victim_added = Client.shared.subscribe(query).handle(Event.created) { _, alert in self.handleVictimUpdate(alert: alert as! Sub_PFAlert) }
        subscription_victim_updated = Client.shared.subscribe(query).handle(Event.updated) { _, alert in self.handleVictimUpdate(alert: alert as! Sub_PFAlert) }
        subscription_victim_removed = Client.shared.subscribe(query).handle(Event.deleted) { _, alert in self.handleVictimUpdate(alert: alert as! Sub_PFAlert) }
        subscription_victim_entered = Client.shared.subscribe(query).handle(Event.entered) { _, alert in self.handleVictimUpdate(alert: alert as! Sub_PFAlert) }
        subscription_victim_left = Client.shared.subscribe(query).handle(Event.left) { _, alert in self.handleVictimUpdate(alert: alert as! Sub_PFAlert) }
    }
    
    func handleVictimUpdate(alert: Sub_PFAlert) {
        
        func update() {
            DispatchQueue.main.async {
                self.updateAnnotations()
                
                guard let tabbar = global.mainTabbar as? Main_Tabbar_NC else { return }
                tabbar.updateTabbarAlertCount(alerts: self.victimDetails.map {$0.value} as! [Sub_PFAlert])
            }
        }
        
        if !alert.isActive {
            self.victimDetails[alert.objectId!] = nil
            update()
        } else {
            let query = Sub_PFAlert.query()!.whereKey("objectId", equalTo: alert.objectId!)
            query.includeKey("user")
            query.getFirstObjectInBackground(block: {
                panic, error in
                
                if panic != nil {
                    self.victimDetails[panic!.objectId!] = panic
                    update()
                }
            })
        }
    }
	
    func getVictims() {
        print("Getting victims from mapViewController") 
        alertHandler.getActiveAlerts(completion: {
            objects in
            
            self.victimDetails = [:]
            objects.forEach{ self.victimDetails[$0.objectId!] = $0 }
            self.updateAnnotations()
            self.addSubscriptions()
                
            if let tabbar = global.mainTabbar as? Main_Tabbar_NC {
                tabbar.updateTabbarAlertCount(alerts: objects)
            }
            
            guard groupsHandler.joinedGroupsObject.first?.value.objectId != nil else {
                self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.getVictims), userInfo: nil, repeats: false)
                return
            }
            print("Victim subscription added")
        })
    }
    
    // Updating annotations
    func updateAnnotations() {
        var liveAnnotationIds: [String : AnnotationCustom] = [:]
        for (id, object) in victimDetails {
            let alert = object as! Sub_PFAlert
            var anno: AnnotationCustom!
            let location = CLLocationCoordinate2D(latitude: alert.location.latitude, longitude: alert.location.longitude)
            if let details = alert.details {
                anno = AnnotationCustom(coordinate: location, title: alert.user["name"] as! String, id: id, object: alert, details: details)
            } else {
                anno = AnnotationCustom(coordinate: location, title: alert.user["name"] as! String, id: id, object: alert)
            }
            liveAnnotationIds[id] = anno
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
            
            if do_openNotificationPin == 1 {
                if anno.id == global.notificationDictionary?["objectId"].string {
                    map.selectAnnotation(anno as MKAnnotation, animated: false)
                    showDetailsView()
                    do_openNotificationPin = 0
                }
            }
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
			
//            let btnViewLeft: UIButton = UIButton(type: UIButtonType.detailDisclosure)
//            btnViewLeft.setImage(UIImage(named: "call"), for: UIControlState())
//            btnViewLeft.addTarget(self, action: #selector(callVictim), for: UIControlEvents.touchUpInside)
			
			view.rightCalloutAccessoryView = btnViewRight
//            view.leftCalloutAccessoryView = btnViewLeft
			
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
//            global.showAlert("Something went wrong", message: error.localizedDescription)
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
    
    func freeMem() {
        map.mapType = MKMapType.hybrid
        map.removeFromSuperview()
        map = nil
        manager = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "updatedActiveAlerts"), object: nil)
        viewIsActive = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        map.mapType = MKMapType.hybrid
        map.mapType = MKMapType.standard
    }
}
