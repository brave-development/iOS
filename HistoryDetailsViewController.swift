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
	var locationPermissionDispatch: dispatch_once_t = 0
	var timer : NSTimer!
	var viewIsActive = false
	var locationPermission: Bool = false
	let dateFormatter = NSDateFormatter()
	var mail: MFMailComposeViewController!
	var togglingDetails = false
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		dateFormatter.locale = NSLocale.currentLocale()
		let detailsGesture = UISwipeGestureRecognizer(target: self, action: "executeToggleDetails")
		detailsGesture.direction = UISwipeGestureRecognizerDirection.Down
		viewBlur.addGestureRecognizer(detailsGesture)
    }
	
	override func viewDidAppear(animated: Bool) {
		dateFormatter.dateFormat = "MMM dd, yyyy"
		lblDate.text = dateFormatter.stringFromDate(placemarkObject.createdAt! as NSDate)
		
		executeToggleDetails() 
		
		dateFormatter.dateFormat = "HH:mm"
		lblTimes.text = "\(dateFormatter.stringFromDate(placemarkObject.createdAt! as NSDate)) - \(dateFormatter.stringFromDate(placemarkObject.updatedAt! as NSDate))"
		let userObject : PFUser = placemarkObject["user"] as! PFUser
		lblName.text = (userObject["name"] as! String)
		lblContact.text = (userObject["cellNumber"] as! String)
		let PFLocation = placemarkObject["location"] as! PFGeoPoint
		let location = CLLocation(latitude: PFLocation.latitude, longitude: PFLocation.longitude)
		
		if userObject["name"] as! String == PFUser.currentUser()!["name"] as! String {
			btnReport.hidden = true
		}
		
		// Adding annotation
		let anno = MKPointAnnotation()
		anno.coordinate = CLLocationCoordinate2DMake(PFLocation.latitude, PFLocation.longitude)
		anno.title = (userObject["name"] as! String) // Name
		anno.subtitle = dateFormatter.stringFromDate(placemarkObject.createdAt! as NSDate) // Cell
		map.addAnnotation(anno)
		
		// Getting address
		var geocode = CLGeocoder()
		geocode.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
			if error != nil {
				println("Error in reverse geocode... \(error)")
			}
			
			if placemarks != nil {
				if placemarks.count > 0 {
					let pm = placemarks[0] as! CLPlacemark
					self.lblSuburb.text = pm.locality
//					self.lblCity.text = pm.subAdministrativeArea
					self.lblCountry.text = pm.country
				}
			} else {
				println("Error in reverse geocode... placemarks = nil")
			}
		})
		
		// Centering and moving map
		var theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
		var theRegion: MKCoordinateRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(PFLocation.latitude, PFLocation.longitude), theSpan)
		map.setRegion(theRegion, animated: true)
	}
	
	// **
	@IBAction func toggleDetails(sender: AnyObject) {
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
			UIView.animateWithDuration(1, animations: {
				self.viewBlur.layoutIfNeeded()
				self.btnToggleDetails.layer.addAnimation(rotateAnimation, forKey: nil);
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
	
	@IBAction func report(sender: AnyObject) {
		mail = MFMailComposeViewController()
		if(MFMailComposeViewController.canSendMail()) {
			let currentUser = PFUser.currentUser()!["name"] as! String
			mail.mailComposeDelegate = self
			mail.setSubject("Panic - Report User")
			mail.setToRecipients(["byroncoetsee@gmail.com"])
			mail.setMessageBody("Your username: \(currentUser).<br/>Their username: \(lblName.text!).<br/>Date: \(lblDate.text!)<br/>Time: \(lblTimes.text!)<br/>Their Contact: \(lblContact.text!)<br/><br/>" +
				"Reason: ", isHTML: true)
			self.presentViewController(mail, animated: true, completion: nil)
		}
		else {
			global.showAlert("Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.")
		}
	}
	
	func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
		switch(result.value){
		case MFMailComposeResultSent.value:
			println("Email sent")
			
		default:
			println("Whoops")
		}
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func findMe(sender: AnyObject) {
		if manager.location != nil {
			var theSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
			var theRegion: MKCoordinateRegion = MKCoordinateRegionMake(manager.location.coordinate, theSpan)
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
	
	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
	{
		
	}
	
	func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)
	{
		if (status == CLAuthorizationStatus.AuthorizedAlways) || (status == CLAuthorizationStatus.AuthorizedWhenInUse) {
			locationAllowed()
		} else if status == CLAuthorizationStatus.Denied {
			locationNotAllowed(true)
		}
	}
	
	func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!)
	{
		println(error)
		dispatch_once(&locationPermissionDispatch, {
			if error.localizedFailureReason != nil{
				global.showAlert(error.localizedDescription, message: error.localizedFailureReason!)
			} else {
				println("didFailWithError")
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
		//        btnMe.hidden = false
		//        findMe(btnMe)
		locationPermissionDispatch = 0
		manager.startUpdatingLocation()
	}
	
	func locationNotAllowed(showMessage: Bool) {
		println("Location NOT Allowed!!")
		
		locationPermission = false
		//        btnMe.hidden = true
		manager.stopUpdatingLocation()
		if showMessage {
			dispatch_once(&locationPermissionDispatch, {
				//                println("didChangeAuthorizationStatus")
				global.showAlert("Location Authorization", message: "To use this feature properly, please enable Location Services for this app in Settings > Privacy > Location")
			})
		}
	}
	
	func freeMem() {
		//        println("Memory freed")
//		if map != nil {
			map.mapType = MKMapType.Hybrid
			map.removeFromSuperview()
//		}
		map = nil
		manager = nil
	}
	
	override func viewWillDisappear(animated: Bool) {
//		if viewIsActive == false {
//			manager.stopUpdatingLocation()
//			manager.delegate = nil
//			map.delegate = nil
//			println("Disabled timer")
//			timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "freeMem", userInfo: nil, repeats: false)
//		}
//		viewIsActive = false
	}


	@IBAction func back(sender: AnyObject) {
		manager.stopUpdatingLocation()
		manager.delegate = nil
		map.delegate = nil
		println("Disabled timer")
		timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "freeMem", userInfo: nil, repeats: false)
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
