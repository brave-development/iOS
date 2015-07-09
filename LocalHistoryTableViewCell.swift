//
//  LocalHistoryTableViewCell.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/06/19.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

class LocalHistoryTableViewCell: UITableViewCell {
	
	@IBOutlet weak var lblDuration: UILabel!
	@IBOutlet weak var lblArea: UILabel!
	@IBOutlet weak var lblLowerInformation: UILabel!
	@IBOutlet weak var imgLowerInformation: UIImageView!
	
	@IBOutlet weak var lblTimeHour: UILabel!
	@IBOutlet weak var lblTimeMinute: UILabel!
	@IBOutlet weak var lblTimeAmPm: UILabel!
	@IBOutlet weak var lblDateDay: UILabel!
	@IBOutlet weak var lblDateMonth: UILabel!
	
	@IBOutlet weak var imgLocation: UIImageView!
	
	var type = "local"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
	
	func setup(object : PFObject) {
		
		let dateStarted = object.createdAt
		let dateEnded = object.updatedAt
		let location = object["location"] as! PFGeoPoint
		
		global.dateFormatter.dateFormat = "dd MMMM yyyy"
		let components = NSCalendar.currentCalendar().components(.CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitMonth | .CalendarUnitDay | NSCalendarUnit.CalendarUnitMonth, fromDate: dateStarted!)
		
		let startTimeString = global.dateFormatter.stringFromDate(dateStarted!)
		let endTimeString = global.dateFormatter.stringFromDate(dateEnded!)
		
		var duration : String!
		
		if round(abs(dateEnded!.timeIntervalSinceDate(dateStarted!))) < 60 {
			duration = "1 Minute or less"
		} else if round(abs(dateEnded!.timeIntervalSinceDate(dateStarted!))) < 3600{
			let tempDurationString = NSString(format: "%.0f", round(abs(dateEnded!.timeIntervalSinceDate(dateStarted!)/60)))
			duration = "\(tempDurationString) Minutes "
		} else {
			let hours = round(abs(dateEnded!.timeIntervalSinceDate(dateStarted!)/60/60))
			let minutes = round(abs(dateEnded!.timeIntervalSinceDate(dateStarted!)/60) - abs(hours * 60))
			let tempDurationString = NSString(format: "%.0f", hours)
			let tempDurationStringMins = NSString(format: "%.0f", abs(minutes))
			duration = "\(tempDurationString) Hours \(tempDurationStringMins) Minutes"
		}
		
		lblDuration.text = duration
		lblTimeHour.text = "\(components.hour)"
		if components.minute < 10 {
			lblTimeMinute.text = "0\(components.minute)"
		} else {
			lblTimeMinute.text = "\(components.minute)"
		}
		
		if components.hour < 12 {
			lblTimeAmPm.text = "AM"
		} else {
			lblTimeAmPm.text = "PM"
		}
		
		lblDateDay.text = "\(components.day)"
		lblDateMonth.text = "\(global.dateFormatter.monthSymbols[components.month - 1] as! String)"
		
		if type == "public" {
			imgLocation.image = UIImage(named: "UserIcon")
			imgLowerInformation.image = UIImage(named: "WriteIcon")
			lblArea.text = object["user"]!["name"]! as? String
			if object["details"] != nil {
				lblLowerInformation.text = object["details"] as? String
			} else {
				lblLowerInformation.text = ""
			}
		} else if type == "group" {
			lblArea.text = "Group Name"
		} else {
			imgLocation.image = UIImage(named: "Location")
			imgLowerInformation.image = UIImage(named: "RespondersIcon")
			if object["responders"] != nil {
				let responders = object["responders"]! as! [String]
				lblLowerInformation.text = "\(responders.count)"
			} else {
				lblLowerInformation.text = "0"
			}
			if object["location"] != nil {
				let location = CLLocationCoordinate2D(latitude: (object["location"] as! PFGeoPoint).latitude, longitude: (object["location"]as! PFGeoPoint).longitude)
				lblArea.text = "\(round(location.latitude * 100)/100), \(round(location.longitude * 100)/100)"
			} else {
				lblArea.text = "Not available"
			}
		}
	}

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
