//
//  HistoryDetailsViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/20.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import MapKit
import MessageUI

class HistoryDetailsViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate {
    
    

    
    // Dispatch Once Tokens
    var do_locationPermissionDispatch = 0
    var do_locationError = 0

	@IBOutlet weak var lblDate: UILabel!
	@IBOutlet weak var lblTimes: UILabel!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var lblContact: UILabel!
	@IBOutlet weak var lblSuburb: UILabel!
//	@IBOutlet weak var lblCity: UILabel!
	@IBOutlet weak var lblCountry: UILabel!
	@IBOutlet weak var map: MKMapView!
	@IBOutlet weak var btnReport: UIButton!
	@IBOutlet weak var viewBlur: UIVisualEffectView!
	@IBOutlet weak var btnToggleDetails: UIButton!
	@IBOutlet weak var blurBottomLayout: NSLayoutConstraint!
	
	var manager: CLLocationManager! = CLLocationManager()
	var placemarkObject : PFObject!
	var locationPermissionDispatch: Int = 0
	var timer : Timer!
	var viewIsActive = false
	var locationPermission: Bool = false
	let dateFormatter = DateFormatter()
	var mail: MFMailComposeViewController!
	var togglingDetails = false
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		dateFormatter.locale = Locale.current
		let detailsGesture = UISwipeGestureRecognizer(target: self, action: #selector(executeToggleDetails))
		detailsGesture.direction = UISwipeGestureRecognizerDirection.down
		viewBlur.addGestureRecognizer(detailsGesture)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		dateFormatter.dateFormat = "MMM dd, yyyy"
		lblDate.text = dateFormatter.string(from: placemarkObject.createdAt! as Date)
		
		executeToggleDetails() 
		
		dateFormatter.dateFormat = "HH:mm"
		lblTimes.text = "\(dateFormatter.string(from: placemarkObject.createdAt! as Date)) - \(dateFormatter.string(from: placemarkObject.updatedAt! as Date))"
		let userObject : PFUser = placemarkObject["user"] as! PFUser
		lblName.text = (userObject["name"] as! String)
		lblContact.text = (userObject["cellNumber"] as! String)
		let PFLocation = placemarkObject["location"] as! PFGeoPoint
		let location = CLLocation(latitude: PFLocation.latitude, longitude: PFLocation.longitude)
		
		if userObject["name"] as! String == PFUser.current()!["name"] as! String {
			btnReport.isHidden = true
		}
		
		// Adding annotation
		let anno = MKPointAnnotation()
		anno.coordinate = CLLocationCoordinate2DMake(PFLocation.latitude, PFLocation.longitude)
		anno.title = (userObject["name"] as! String) // Name
		anno.subtitle = dateFormatter.string(from: placemarkObject.createdAt! as Date) // Cell
		map.addAnnotation(anno)
		
		// Getting address
		let geocode = CLGeocoder()
		geocode.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
			if error != nil {
				print("Error in reverse geocode... \(error)")
			}
			
			if placemarks != nil {
				if placemarks!.count > 0 {
					let pm = placemarks![0] 
					self.lblSuburb.text = pm.locality
//					self.lblCity.text = pm.subAdministrativeArea
					self.lblCountry.text = pm.country
				}
			} else {
				print("Error in reverse geocode... placemarks = nil")
			}
		})
		
		// Centering and moving map
		let theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
		let theRegion: MKCoordinateRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(PFLocation.latitude, PFLocation.longitude), theSpan)
		map.setRegion(theRegion, animated: true)
	}
	
	// **
	@IBAction func toggleDetails(_ sender: AnyObject) {
		executeToggleDetails()
	}
	
	func executeToggleDetails() {
		if togglingDetails == false{
			togglingDetails = true
			let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
			rotateAnimation.duration = 1
			if blurBottomLayout.constant != -viewBlur.frame.height + 25 {
				blurBottomLayout.constant = -viewBlur.frame.height + 25
				rotateAnimation.fromValue = 0.0
				rotateAnimation.toValue = CGFloat(M_PI)
			} else {
				blurBottomLayout.constant = 0
				rotateAnimation.fromValue = CGFloat(M_PI)
				rotateAnimation.toValue = 0.0
			}
			UIView.animate(withDuration: 1, animations: {
				self.viewBlur.layoutIfNeeded()
				self.btnToggleDetails.layer.add(rotateAnimation, forKey: nil);
				}, completion: {
					(result: Bool) -> Void in
					self.togglingDetails = false
					if self.blurBottomLayout.constant != -self.viewBlur.frame.height + 25 {
						self.btnToggleDetails.imageView?.image = UIImage(named: "down_arrow")
					} else {
						self.btnToggleDetails.imageView?.image = UIImage(named: "up_arrow")
					}
			})
		}
	}
	// **
	
	@IBAction func report(_ sender: AnyObject) {
		mail = MFMailComposeViewController()
		if(MFMailComposeViewController.canSendMail()) {
			let currentUser = PFUser.current()!["name"] as! String
			mail.mailComposeDelegate = self
			mail.setSubject("Panic - Report User")
			mail.setToRecipients(["byroncoetsee@gmail.com"])
			mail.setMessageBody("Your username: \(currentUser).<br/>Their username: \(lblName.text!).<br/>Date: \(lblDate.text!)<br/>Time: \(lblTimes.text!)<br/>Their Contact: \(lblContact.text!)<br/><br/>" +
				"Reason: ", isHTML: true)
			self.present(mail, animated: true, completion: nil)
		}
		else {
			global.showAlert("Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.")
		}
	}
	

	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		switch(result){
		case MFMailComposeResult.sent:
			print("Email sent")
			
		default:
			print("Whoops")
		}
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func findMe(_ sender: AnyObject) {
		if manager.location != nil {
			let theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
			let theRegion: MKCoordinateRegion = MKCoordinateRegionMake(manager.location!.coordinate, theSpan)
			map.setRegion(theRegion, animated: true)
		}
	}
	
//	func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
//	{
//		if !annotation.isEqual(mapView.userLocation) {
//			var view: MKAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Standard")
//			
//			var btnViewRight: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
//			btnViewRight.addTarget(self, action: "callVictim", forControlEvents: UIControlEvents.TouchUpInside)
//			btnViewRight.setImage(UIImage(named: "call"), forState: UIControlState.Normal)
//			
//			if view.annotation.subtitle? != nil {
//				if view.annotation.subtitle? != "Loading name..." {
//					view.rightCalloutAccessoryView = btnViewRight
//				}
//			}
//			
//			view.image = UIImage(named: "panic")
//			
//			view.enabled = true
//			view.canShowCallout = true
//			view.centerOffset = CGPointMake(0, 0)
//			return view
//		} else {
//			return nil
//		}
	// remove this line... literally
//	}
	
//	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//		
//	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
	{
		if (status == CLAuthorizationStatus.authorizedAlways) || (status == CLAuthorizationStatus.authorizedWhenInUse) {
			locationAllowed()
		} else if status == CLAuthorizationStatus.denied {
			locationNotAllowed(true)
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print(error)
        if do_locationError == 0 {
            global.showAlert("Something went wrong", message: error.localizedDescription)
            do_locationError = 1
        }
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
	{
		let polylineRender: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
		polylineRender.lineWidth = 5.0
		polylineRender.strokeColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.95)
		return polylineRender;
	}
	
	
	func locationAllowed() {
		print("Location Allowed!!")
		
		locationPermission = true
		//        btnMe.hidden = false
		//        findMe(btnMe)
		locationPermissionDispatch = 0
		manager.startUpdatingLocation()
	}
	
	func locationNotAllowed(_ showMessage: Bool) {
		print("Location NOT Allowed!!")
		
		locationPermission = false
		//        btnMe.hidden = true
		manager.stopUpdatingLocation()
		if showMessage {
			// Migrator FIXME: multiple dispatch_once calls using the same dispatch_once_t token cannot be automatically migrated
            if do_locationPermissionDispatch == 0 {
				global.showAlert("Location Authorization", message: "To use this feature properly, please enable Location Services for this app in Settings > Privacy > Location")
                do_locationPermissionDispatch = 1
			}
		}
	}
	
	func freeMem() {
		//        print("Memory freed")
//		if map != nil {
			map.mapType = MKMapType.hybrid
			map.removeFromSuperview()
//		}
		map = nil
		manager = nil
	}
	
	override func viewWillDisappear(_ animated: Bool) {
//		if viewIsActive == false {
//			manager.stopUpdatingLocation()
//			manager.delegate = nil
//			map.delegate = nil
//			print("Disabled timer")
//			timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "freeMem", userInfo: nil, repeats: false)
//		}
//		viewIsActive = false
	}


	@IBAction func back(_ sender: AnyObject) {
		manager.stopUpdatingLocation()
		manager.delegate = nil
		map.delegate = nil
		print("Disabled timer")
		timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(freeMem), userInfo: nil, repeats: false)
		self.dismiss(animated: true, completion: nil)
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
