//
//  LocalHistoryViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/10.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

class LocalHistoryViewController: UIViewController, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tblHistory: UITableView!
	
	// Tutorial
	
	@IBOutlet weak var viewTutorial: UIView!
	@IBOutlet weak var imageTap: UIView!
    
    var records : [String : [AnyObject]]!
    let dateFormatter = NSDateFormatter()
	
	var segControl : HMSegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.locale = NSLocale.currentLocale()
		let timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "reloadTable", userInfo: nil, repeats: false)
    }
	
	override func viewDidAppear(animated: Bool) {
		
		// Showing tutorial screen
		if tutorial.localHistory == false {
			let tapRecognizer = UITapGestureRecognizer(target: self, action: "closeTutorial")
			tapRecognizer.delegate = self
			viewTutorial.addGestureRecognizer(tapRecognizer)
			viewTutorial.hidden = false
			animateTutorial()
		}
		
		if tblHistory.indexPathForSelectedRow() != nil {
			tblHistory.deselectRowAtIndexPath(tblHistory.indexPathForSelectedRow()!, animated: true)
		}
		
		segControl = HMSegmentedControl(sectionTitles: ["Others", "You", "Groups"])
		segControl.frame = CGRectMake(0, 20, self.view.frame.width, 60)
		segControl.addTarget(self, action: "changedSegment", forControlEvents: UIControlEvents.ValueChanged)
		segControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown
		segControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe
		segControl.backgroundColor = UIColor.clearColor()
		self.view.addSubview(segControl)
	}
	
	func changedSegment() {
		fadeTableViewOut()
		switch (segControl.selectedSegmentIndex) {
		case 0:
			break;
			
		case 1:
			break;
			
		case 2:
			break;
			
		default:
			break;
		}
//		fadeTableViewIn()
	}
	
	func fadeTableViewIn() {
		self.tblHistory.hidden = false
		UIView.animateWithDuration(0.3, animations: {
			self.tblHistory.alpha = 1.0 })
	}
	
	func fadeTableViewOut() {
		UIView.animateWithDuration(0.3, animations: {
			self.tblHistory.alpha = 0.0 }, completion: {
				(finished: Bool) -> Void in
				self.fadeTableViewIn()
		})
	}
	
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return global.panicHistoryLocal.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
        
        let objectId = global.panicHistoryLocal[indexPath.row].objectId
        let dateStarted = global.panicHistoryLocal[indexPath.row].createdAt
        let dateEnded = global.panicHistoryLocal[indexPath.row].updatedAt
        let location = global.panicHistoryLocal[indexPath.row]["location"] as! PFGeoPoint
        
        dateFormatter.dateFormat = "dd MMMM yyyy"
		
        let dateString = dateFormatter.stringFromDate(dateStarted!)
        
        dateFormatter.dateFormat = "HH:mm"
        
        let startTimeString = dateFormatter.stringFromDate(dateStarted!)
        let endTimeString = dateFormatter.stringFromDate(dateEnded!)
        
        var duration : String!
        
        if round(abs(dateEnded!.timeIntervalSinceDate(dateStarted!))) < 60 {
            duration = "Less than 1 Min"
        } else {
            let tempDurationString = NSString(format: "%.0f", round(abs(dateEnded!.timeIntervalSinceDate(dateStarted!)/60)))
            duration = "\(tempDurationString) Mins"
        }
        
        cell.textLabel?.text = dateString
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.detailTextLabel?.text = "\(startTimeString)  -  \(endTimeString)        \(duration)"
        cell.detailTextLabel?.textColor = UIColor.whiteColor()
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		println("Selected cell")
		var storyboard = UIStoryboard(name: "Main", bundle: nil)
		var vc: HistoryDetailsViewController = storyboard.instantiateViewControllerWithIdentifier("historyDetailsViewController")as! HistoryDetailsViewController
		vc.placemarkObject = global.panicHistoryLocal[indexPath.row]
		self.presentViewController(vc, animated: true, completion: nil)
	}
	
	func reloadTable() {
		if global.panicHistoryLocal.count == 0 {
			let timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "reloadTable", userInfo: nil, repeats: false)
		} else {
			tblHistory.reloadData()
		}
	}
	
	// Tutorial
	
	func closeTutorial() {
		UIView.animateWithDuration(0.5, animations: {
			self.viewTutorial.alpha = 0.0 }, completion: {
				(finished: Bool) -> Void in
				self.viewTutorial.hidden = true
		})
		tutorial.localHistory = true
		tutorial.save()
	}
	
	func animateTutorial() {
		self.imageTap.layer.shadowColor = UIColor.whiteColor().CGColor
		self.imageTap.layer.shadowRadius = 5.0
		self.imageTap.layer.shadowOffset = CGSizeZero
		
		var animate = CABasicAnimation(keyPath: "shadowOpacity")
		animate.fromValue = 0.0
		animate.toValue = 1.0
		animate.autoreverses = true
		animate.duration = 1
		
		self.imageTap.layer.addAnimation(animate, forKey: "shadowOpacity")
		
		if tutorial.localHistory == false {
			let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "animateTutorial", userInfo: nil, repeats: false)
		}
		
	}
}
