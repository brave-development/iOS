//
//  History_Cell.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/03/26.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import SwiftLocation
import MapKit

class History_Cell: UICollectionViewCell {
    
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblDateTime: UILabel!
    @IBOutlet weak var lblDetails: UILabel!
    
    var alert: Sub_PFAlert!
    var formatter = DateFormatter()
    
    func setup(alert: Sub_PFAlert) {
        self.alert = alert
        setupUI()
        
        lblName.text = (alert.user["name"] as? String) ?? "Anonymous"
        
        let dateTime = getDateTime()
        lblDateTime.text = "•    \(dateTime.date)    •    \(dateTime.time)    •"
        
        lblDetails.text = alert.details ?? "No details"
        
        fetchAddress()
    }
    
    func setupUI() {
        backgroundColor = UIColor.clear
        
        viewContainer.layer.cornerRadius = 20
        viewContainer.clipsToBounds = true
        
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOffset = .zero
        contentView.layer.shadowOpacity = 0.6
    }
    
    func fetchAddress() {
        Locator.location(fromCoordinates: CLLocationCoordinate2D(latitude: alert.location.latitude, longitude: alert.location.longitude), onSuccess: {
            place in
            print(place)
            
            self.lblAddress.text = "\(place[0].name ?? ""), \(place[0].city ?? ""), \(place[0].country ?? "")"
        }, onFail: {
            error in
            print(error.localizedDescription)
            self.lblAddress.text = "Couldn't find address"
        })
    }
    
    func setHighlight(highlighted: Bool) {
        if highlighted {
            alpha = 1
        } else {
            alpha = 0.7
        }
    }
    
    func getDateTime() -> (date: String, time: String) {
        formatter.dateFormat = "d MMM"
        let date = formatter.string(from: alert.createdAt!)
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: alert.createdAt!)
        return (date, time)
    }
}
