//
//  CountriesViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/15.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import CoreLocation

protocol countryDelegate {
    func didSelectCountry(country : String)
}


class CountriesViewController: UIViewController, UITableViewDelegate, CLLocationManagerDelegate {

    var manager = CLLocationManager()
    var foundCountryTracker = false
    var delegate : countryDelegate?
    
    @IBOutlet weak var tblCountries: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return global.countries.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "standard")
        cell.textLabel?.text = global.countries[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.didSelectCountry(global.countries[indexPath.row])
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func getCountry(location : CLLocation) {
        println("Getting country")
        if foundCountryTracker == false {
            println("foundCountry == false")
            foundCountryTracker = true
            var geocode = CLGeocoder()
            geocode.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    self.foundCountryTracker = false
                    println("Error in reverse geocode... \(error)")
                }
                
                if placemarks != nil {
                    if placemarks.count > 0 {
                        self.foundCountryTracker = true
                        let pm = placemarks[0] as! CLPlacemark
						if pm.subLocality != nil {
							groupsHandler.createGroup(pm.subLocality, country: pm.country)
						} else if pm.subAdministrativeArea != nil {
							groupsHandler.createGroup(pm.subAdministrativeArea, country: pm.country)
						}
							if let position = NSIndexPath(forRow: find(global.countries, pm.country)!, inSection: 0) {
                            if self.tblCountries != nil {
                                self.tblCountries.scrollToRowAtIndexPath(position, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                            }
                        }
                    }
                } else {
                    self.foundCountryTracker = false
                    println("Error in reverse geocode... placemarks = nil")
                }
            })
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("Updated location... Accuracy = \(manager.location.horizontalAccuracy)")
//        if manager.location.horizontalAccuracy < 3000 {
            getCountry(manager.location)
            manager.stopUpdatingLocation()
//        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
    }
    
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
