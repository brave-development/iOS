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
	var segControl : HMSegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		global.getPublicHistory()
        global.dateFormatter.locale = NSLocale.currentLocale()
		
		let decrementSegIndexRecognizer = UISwipeGestureRecognizer(target: self, action: "decrementSegIndex")
		decrementSegIndexRecognizer.direction = .Right
		let incrementSegIndexRecognizer = UISwipeGestureRecognizer(target: self, action: "incrementSegIndex")
		incrementSegIndexRecognizer.direction = .Left
		tblHistory.addGestureRecognizer(decrementSegIndexRecognizer)
		tblHistory.addGestureRecognizer(incrementSegIndexRecognizer)
		
		let statusBarSpacer = UIView(frame: CGRectMake(0, 0, self.view.frame.width, 20))
		statusBarSpacer.backgroundColor = UIColor(white: 0, alpha: 0.5)
		self.view.addSubview(statusBarSpacer)
		
		segControl = HMSegmentedControl(sectionTitles: ["Others", "You"])
		segControl.frame = CGRectMake(0, 20, self.view.frame.width, 50)
		segControl.addTarget(self, action: "changedSegment", forControlEvents: UIControlEvents.ValueChanged)
		segControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown
		segControl.selectionIndicatorColor = UIColor(white: 1, alpha: 0.7)
		segControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe
		segControl.verticalDividerEnabled = true
		segControl.verticalDividerColor = UIColor(white: 1, alpha: 0.3)
		segControl.verticalDividerWidth = 1
		segControl.backgroundColor = UIColor(white: 0, alpha: 0.5)
		segControl.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
		segControl.setSelectedSegmentIndex(0, animated: true)
		self.view.addSubview(segControl)
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
	}
	
	func changedSegment() {
		UIView.animateWithDuration(0.3, animations: {
			self.tblHistory.alpha = 0.0 }, completion: {
				(finished: Bool) -> Void in
				self.reloadTable()
				UIView.animateWithDuration(0.3, animations: {
					self.tblHistory.alpha = 1.0 })
		})
	}
	
	func decrementSegIndex() {
		if segControl.selectedSegmentIndex > 0 {
			segControl.setSelectedSegmentIndex(UInt(segControl.selectedSegmentIndex - 1), animated: true)
			changedSegment()
		}
	}
	
	func incrementSegIndex() {
		if segControl.selectedSegmentIndex < segControl.sectionTitles.count - 1 {
			segControl.setSelectedSegmentIndex(UInt(segControl.selectedSegmentIndex + 1), animated: true)
			changedSegment()
		}
	}
	
	
//	func fadeTableViewIn() {
//		self.tblHistory.hidden = false
//		UIView.animateWithDuration(0.3, animations: {
//			self.tblHistory.alpha = 1.0 })
//	}
//	
//	func fadeTableViewOut() {
//		UIView.animateWithDuration(0.3, animations: {
//			self.tblHistory.alpha = 0.0 }, completion: {
//				(finished: Bool) -> Void in
//				self.fadeTableViewIn()
//		})
//	}
	
//	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//		let statusBarSpacer = UIView(frame: CGRectMake(0, 0, self.view.frame.width, 20))
//		statusBarSpacer.backgroundColor = UIColor.clearColor()
//		return statusBarSpacer
//	}
	
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if segControl != nil {
			switch (segControl.selectedSegmentIndex) {
			case 0:
				return global.panicHistoryPublic.count
				
			case 1:
				return global.panicHistoryLocal.count
				
			case 2:
				return 6
				
			default:
				return 20
			}
		}
		return 0
//        return global.panicHistoryLocal.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if segControl != nil {
			switch (segControl.selectedSegmentIndex) {
			case 0:
				let object = global.panicHistoryPublic[indexPath.row]
				var cell = tblHistory.dequeueReusableCellWithIdentifier("localHistoryCell", forIndexPath: indexPath) as! LocalHistoryTableViewCell
				cell.type = "public"
				cell.setup(object)
				return cell
				
			case 1:
				let object = global.panicHistoryLocal[indexPath.row]
				var cell = tblHistory.dequeueReusableCellWithIdentifier("localHistoryCell", forIndexPath: indexPath) as! LocalHistoryTableViewCell
				cell.type = "local"
				cell.setup(object)
				return cell
				
			case 2:
				var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
				cell.backgroundColor = UIColor.clearColor()
				cell.textLabel?.text = "No Data"
				return cell
				
			default:
				var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
				cell.backgroundColor = UIColor.clearColor()
				return cell
			}
		}
		var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
		return cell
//        var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
//
//        let objectId = global.panicHistoryLocal[indexPath.row].objectId
//        let dateStarted = global.panicHistoryLocal[indexPath.row].createdAt
//        let dateEnded = global.panicHistoryLocal[indexPath.row].updatedAt
//        let location = global.panicHistoryLocal[indexPath.row]["location"] as! PFGeoPoint
//        
//        dateFormatter.dateFormat = "dd MMMM yyyy"
//		
//        let dateString = dateFormatter.stringFromDate(dateStarted!)
//        
//        dateFormatter.dateFormat = "HH:mm"
//        
//        let startTimeString = dateFormatter.stringFromDate(dateStarted!)
//        let endTimeString = dateFormatter.stringFromDate(dateEnded!)
//        
//        var duration : String!
//        
//        if round(abs(dateEnded!.timeIntervalSinceDate(dateStarted!))) < 60 {
//            duration = "Less than 1 Min"
//        } else {
//            let tempDurationString = NSString(format: "%.0f", round(abs(dateEnded!.timeIntervalSinceDate(dateStarted!)/60)))
//            duration = "\(tempDurationString) Mins"
//        }
//        
//        cell.textLabel?.text = dateString
//        cell.textLabel?.textColor = UIColor.whiteColor()
//        cell.detailTextLabel?.text = "\(startTimeString)  -  \(endTimeString)        \(duration)"
//        cell.detailTextLabel?.textColor = UIColor.whiteColor()
//        cell.backgroundColor = UIColor.clearColor()
    }
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		println("Selected cell")
		var storyboard = UIStoryboard(name: "Main", bundle: nil)
		var vc: HistoryDetailsViewController = storyboard.instantiateViewControllerWithIdentifier("historyDetailsViewController")as! HistoryDetailsViewController
		vc.placemarkObject = global.panicHistoryLocal[indexPath.row]
		self.presentViewController(vc, animated: true, completion: nil)
	}
	
	func reloadTable() {
		var count = 0
		if segControl != nil {
			switch (segControl.selectedSegmentIndex) {
			case 0:
				count = global.panicHistoryPublic.count
				
			case 1:
				count = global.panicHistoryLocal.count
				
			default:
				count = 0
			}
		}

		if count == 0 {
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
