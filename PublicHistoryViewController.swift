//
//  PublicHistoryViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/19.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

class PublicHistoryViewController: UIViewController, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var viewLoading: UIView!
    @IBOutlet weak var tblHistory: UITableView!
	
	// Tutorial 
	
	@IBOutlet weak var viewTutorial: UIView!
	@IBOutlet weak var imageTap: UIView!
    
    let dateFormatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getPublicHistory()
        viewLoading.backgroundColor = UIColor.clearColor()
        tblHistory.backgroundColor = UIColor.clearColor()
        
        dateFormatter.locale = NSLocale.currentLocale()
        dateFormatter.dateFormat = "MMM dd, yyyy, HH:mm"
        
        if global.panicHistoryPublic.count > 0 {
            viewLoading.hidden = true
            tblHistory.hidden = false
        } else {
            viewLoading.hidden = false
            tblHistory.hidden = true
        }
        
        // Do any additional setup after loading the view.
    }
	
	override func viewDidAppear(animated: Bool) {
		if tutorial.publicHistory == false {
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return global.panicHistoryPublic.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "default")
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.detailTextLabel?.textColor = UIColor.whiteColor()
        cell.backgroundColor = UIColor.clearColor()
		
        if global.panicHistoryPublic.count > 0 {
            let date = dateFormatter.stringFromDate(global.panicHistoryPublic[indexPath.row].createdAt!)
            let userObject : PFUser = global.panicHistoryPublic[indexPath.row]["user"] as! PFUser
            let name = userObject["name"] as! String
            let number = userObject["cellNumber"] as! String
            
            cell.textLabel?.text = date
            cell.detailTextLabel?.text = "\(name) - \(number)"
			
//			if global.panicHistoryPublic[indexPath.row]["active"] as? Bool == true {
//				cell.accessoryType = UITableViewCellAccessoryType.Checkmark
//			}
			
        } else {
            cell.textLabel?.text = "Loading..."
        }
        
        return cell
    }
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		println("Tapped row")
		var storyboard = UIStoryboard(name: "Main", bundle: nil)
		var vc: HistoryDetailsViewController = storyboard.instantiateViewControllerWithIdentifier("historyDetailsViewController") as! HistoryDetailsViewController
		vc.placemarkObject = global.panicHistoryPublic[indexPath.row]
		self.presentViewController(vc, animated: true, completion: nil)
	}
	
    func getPublicHistory() {
        var queryHistory = PFQuery(className: "Panics")
        queryHistory.orderByDescending("createdAt")
        queryHistory.limit = 20
        queryHistory.includeKey("user")
        queryHistory.findObjectsInBackgroundWithBlock({
            (objects : [AnyObject]?, error : NSError?) -> Void in
            if error == nil {
				global.panicHistoryPublic = []
                for objectRaw in objects! {
                    let object = objectRaw as! PFObject
                    global.panicHistoryPublic.append(object)
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.tblHistory.reloadData()
                    self.tblHistory.hidden = false
                    self.viewLoading.hidden = true
                })
                self.tblHistory.reloadData()
            } else {
                println(error)
            }
            println("DONE getting public history")
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// Tutorial
	
	func closeTutorial() {
		UIView.animateWithDuration(0.5, animations: {
			self.viewTutorial.alpha = 0.0 }, completion: {
				(finished: Bool) -> Void in
				self.viewTutorial.hidden = true
		})
		tutorial.publicHistory = true
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
		
		if tutorial.publicHistory == false {
			let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "animateTutorial", userInfo: nil, repeats: false)
		}
		
	}
}
