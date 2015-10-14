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
	@IBOutlet weak var spinner: UIActivityIndicatorView!
	@IBOutlet weak var lblNoHistory: UILabel!
    
    var records : [String : [AnyObject]]!
	var segControl : HMSegmentedControl!
	
	// Tutorial
	
	@IBOutlet weak var lblTutorialTextTop: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		global.getPublicHistory()
        global.dateFormatter.locale = NSLocale.currentLocale()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishedGettingPublicHistory", name:"gotPublicHistory", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishedGettingPrivateHistory", name:"gotLocalHistory", object: nil)
		
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
		
		reloadTable()
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
				self.tblHistory.scrollRectToVisible(CGRectMake(0, 0, 0, 0), animated: false)
				self.reloadTable()
//				self.tblHistory.scrollEnabled = false
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
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if segControl != nil {
			switch (segControl.selectedSegmentIndex) {
			case 0:
				if indexPath.row < global.panicHistoryPublic.count {
					let object = global.panicHistoryPublic[indexPath.row]
					var cell = tblHistory.dequeueReusableCellWithIdentifier("localHistoryCell", forIndexPath: indexPath) as! LocalHistoryTableViewCell
					cell.type = "public"
					cell.setup(object)
					return cell
				}
				
			case 1:
				if indexPath.row < global.panicHistoryLocal.count {
					let object = global.panicHistoryLocal[indexPath.row]
					var cell = tblHistory.dequeueReusableCellWithIdentifier("localHistoryCell", forIndexPath: indexPath) as! LocalHistoryTableViewCell
					cell.type = "local"
					cell.setup(object)
					return cell
				}
				
			case 2:
				var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
				cell.backgroundColor = UIColor.clearColor()
				cell.textLabel?.text = NSLocalizedString("no_data", value: "No Data", comment: "")
				return cell
				
			default:
				var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
				cell.backgroundColor = UIColor.clearColor()
				return cell
			}
		}
		var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
		cell.backgroundColor = UIColor.clearColor()
		return cell
    }
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		println("Selected cell")
		var storyboard = UIStoryboard(name: "Main", bundle: nil)
		var vc: HistoryDetailsViewController = storyboard.instantiateViewControllerWithIdentifier("historyDetailsViewController")as! HistoryDetailsViewController
		switch (segControl.selectedSegmentIndex) {
		case 0:
			vc.placemarkObject = global.panicHistoryPublic[indexPath.row]
			break
			
		case 1:
			vc.placemarkObject = global.panicHistoryLocal[indexPath.row]
			break
			
		default:
			break
		}
		self.presentViewController(vc, animated: true, completion: nil)
	}
	
	func reloadTable() {
		var count = 0
		if segControl != nil {
			switch (segControl.selectedSegmentIndex) {
			case 0:
				lblTutorialTextTop.text = NSLocalizedString("public_panics_20", value: "Last 20 Panic activations by other people.", comment: "")
				lblNoHistory.hidden = true
				if global.publicHistoryFetched == true {
					count = global.panicHistoryPublic.count
					spinner.stopAnimating()
				} else {
					spinner.startAnimating()
				}
				
			case 1:
				lblTutorialTextTop.text = NSLocalizedString("private_panics_50", value: "Last 50 of your own Panic activations.", comment: "")
				spinner.stopAnimating()
				if global.privateHistoryFetched == true {
					count = global.panicHistoryLocal.count
					if count == 0 {
						lblNoHistory.hidden = false
						count = 1
					} else {
						lblNoHistory.hidden = true
					}
				}
				
			default:
				count = 0
			}
		}

		if count == 0 {
			println("Starting timer")
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
