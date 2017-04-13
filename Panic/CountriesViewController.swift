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
    func didSelectCountry(_ country : String)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return global.countries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "standard")
        cell.textLabel?.text = global.countries[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectCountry(global.countries[indexPath.row])
        self.dismiss(animated: true, completion: nil)
    }
    
    func getCountry(_ location : CLLocation) {
        print("Getting country")
        if foundCountryTracker == false {
            print("foundCountry == false")
            foundCountryTracker = true
            let geocode = CLGeocoder()
            geocode.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    self.foundCountryTracker = false
                    print("Error in reverse geocode... \(error)")
                }
                
                if placemarks != nil {
                    if placemarks!.count > 0 {
                        self.foundCountryTracker = true
                        let pm = placemarks![0] 
						if pm.subLocality != nil {
							groupsHandler.createGroup(pm.subLocality!, country: pm.country!)
						} else if pm.subAdministrativeArea != nil {
							groupsHandler.createGroup(pm.subAdministrativeArea!, country: pm.country!)
						}
						let position = IndexPath(row: global.countries.index(of: pm.country!)!, section: 0)
							if self.tblCountries != nil {
								self.tblCountries.scrollToRow(at: position, at: UITableViewScrollPosition.middle, animated: true)
							}
						
                    }
                } else {
                    self.foundCountryTracker = false
                    print("Error in reverse geocode... placemarks = nil")
                }
            })
        }
    }
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		print("Updated location... Accuracy = \(manager.location!.horizontalAccuracy)")
        if manager.location!.horizontalAccuracy < 5001 {
            getCountry(manager.location!)
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
    
    @IBAction func back(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
