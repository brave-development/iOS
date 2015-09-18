//
//  GroupsTableViewCell.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/06/10.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

class GroupsTableViewCell: UITableViewCell {
	
	var alreadyJoined = true
	var object: PFObject?
	var subsCount: Int = 0
	private var gradient: CAGradientLayer?
	var parent: GroupsViewController!
	let OffsetSpeed: CGFloat = 35.0
	var imgBackground: UIImageView!

	
	@IBOutlet weak var btnMore: UIButton!
	@IBOutlet weak var imgLock: UIImageView!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var lblCountry: UILabel!
	@IBOutlet weak var lblSubs: UILabel!
	@IBOutlet weak var btnLeave: UIButton!
	
    override func awakeFromNib() {
        super.awakeFromNib()
		self.clipsToBounds = true
    }
	
	func setup() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseStarted", name: "purchaseStarted", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseEnded", name: "purchaseEnded", object: nil)
		let yOffset = ((parent.tblGroups.contentOffset.y - self.frame.origin.y) / 320) * OffsetSpeed
		if imgBackground != nil {
			imgBackground.frame = CGRectMake(0, yOffset, self.frame.width, 320)
		} else {
			imgBackground = UIImageView(frame: CGRectMake(0, yOffset, self.frame.width, 320))
			self.insertSubview(imgBackground, atIndex: 0)
		}
		imgBackground.contentMode = UIViewContentMode.ScaleAspectFill 
		setImage()
		
		let groupName = object!["name"] as! String
		
		lblName.text = groupName
		
		if object!["subscriberObjects"] != nil {
			subsCount = (object!["subscriberObjects"] as? [String])!.count
		}
		
		if object?["description"] != nil {
			lblCountry.text = object?["description"] as? String
		} else {
			lblCountry.text = object?["country"] as? String
		}
		
		if (object!["public"] as? Bool) == true {
			imgLock.hidden = true
//			if subsCount > 2 { subsCount = subsCount + Int(floor(subsCount*0.3)) }
		} else {
			imgLock.hidden = false
		}
		
		lblSubs.text = "\(subsCount)"
		
		imgBackground.clipsToBounds = true
		
		btnMore = drawing.buttonBorderCircle(btnMore, borderWidth: 1, borderColour: UIColor.whiteColor().CGColor)
		btnMore.backgroundColor = UIColor(white: 0, alpha: 0.3)
		
		if groupsHandler.purchaseRunning == true { purchaseStarted() }
		btnLeave.layer.cornerRadius = 5
		btnLeave.layer.borderColor = UIColor.whiteColor().CGColor
		btnLeave.layer.borderWidth = 1
		btnLeave.clipsToBounds = true
		btnLeave.backgroundColor = UIColor(white: 0, alpha: 0.3)
		
		if find(groupsHandler.joinedGroups, groupName) == nil {
			btnLeave.setTitle("JOIN", forState: .Normal)
			alreadyJoined = false
		} else {
			btnLeave.setTitle("LEAVE", forState: .Normal)
			alreadyJoined = true
		}
		
		if gradient == nil {
			gradient = drawing.gradient(contentView, colours: [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor], locations: [0.0 , 1.0], opacity: 0.5)
			contentView.layer.insertSublayer(gradient, atIndex: 1)
		}
	}
	
	@IBAction func more(sender: AnyObject) {
		var options = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
		
		// EDIT
		let editAction = UIAlertAction(title: "Edit", style: .Default) { (_) in
			let vc = self.parent.storyboard?.instantiateViewControllerWithIdentifier("createNewGroupViewController") as! CreateGroupViewController
//			vc.fillData(self.object!)
			vc.group = self.object!
			vc.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
			self.parent.presentViewController(vc, animated: true, completion: nil)
		}
		
		// REPORT
		let reportAction = UIAlertAction(title: "Report", style: .Default) { (_) in
		}
		
		// LEAVE / JOIN
		let leaveJoinAction = UIAlertAction(title: btnLeave.titleLabel!.text!.capitalizedString, style: .Default) { (_) in
			self.btnLeave.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
		}
		
		// HIDE
//		let deleteAction = UIAlertAction(title: "Hide", style: .Destructive) { (_) in
//		}
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
		
		options.addAction(editAction)
		options.addAction(reportAction)
		options.addAction(leaveJoinAction)
//		options.addAction(deleteAction)
		options.addAction(cancelAction)
		
		self.parent.presentViewController(options, animated: true, completion: nil)
	}
	
	@IBAction func joinLeave(sender: AnyObject) {
		let groupName = self.object!["name"] as! String
		if alreadyJoined == true {
			var deleteAlert = UIAlertController(title: "Leave \(groupName)?", message: "Are you sure you want to leave this group?", preferredStyle: UIAlertControllerStyle.Alert)
			deleteAlert.addAction(UIAlertAction(title: "Leave", style: .Destructive, handler: { (action: UIAlertAction!) in
				groupsHandler.removeGroup(groupName)
//				groupsHandler.joinedGroupsObject[self.object?["flatValue"] as! String] = nil
				self.parent.populateDataSource()
				if groupsHandler.joinedGroupsObject.count == 0 {
					self.parent.tblGroups.reloadData()
				} else {
					let indexPath = self.parent.tblGroups.indexPathForCell(self)
					self.parent.tblGroups.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
				}
			}))
			deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in }))
			self.parent.presentViewController(deleteAlert, animated: true, completion: nil)
		} else {
			if groupsHandler.joinedGroups.count >= PFUser.currentUser()!["numberOfGroups"] as! Int {
				NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseSuccessful", name: "purchaseSuccessful", object: nil)
				NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseFail", name: "purchaseFail", object: nil)
				groupsHandler.handlePurchase(parent)
			} else {
				purchaseSuccessful()
			}
		}
	}
	
	func purchaseSuccessful() {
		groupsHandler.addGroup(lblName.text!)
		groupsHandler.getNearbyGroups(parent.manager.location, refresh: true)
		parent.populateDataSource()
		parent.checkForGroupDetails()
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "purchaseSuccess", object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "purchaseFail", object: nil)
	}
	
	func purchaseFail() {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "purchaseSuccess", object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "purchaseFail", object: nil)
	}
	
	func purchaseStarted() {
		btnLeave.alpha = 0.3
		btnLeave.enabled = false
	}
	
	func purchaseEnded() {
		btnLeave.alpha = 1
		btnLeave.enabled = true
	}
	
	func getImage() {
		var imageFile: UIImage?
		let getImageDispatch: dispatch_queue_t = dispatch_queue_create("getImageDispatch", nil)
		dispatch_async(getImageDispatch, {
			if self.object!["imageFile"] != nil {
				
				let image: PFFile = self.object!["imageFile"] as! PFFile
				image.getDataInBackgroundWithBlock {
					(imageData: NSData?, error: NSError?) -> Void in
					if error == nil {
						self.finishedDownload(UIImage(data:imageData!)!)
					}
				}
			} else if self.object!["image"] != nil {
				let imageUrl: String = self.object!["image"] as! String
				let url = NSURL(string: imageUrl)
				if let imageData = NSData(contentsOfURL: url!){
					self.finishedDownload(UIImage(data:imageData)!)
				}
			}
		})
	}
	
	func finishedDownload(image: UIImage) {
		let groupName = self.object!["flatValue"] as! String
		let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
		
		imgBackground.image = image
		let destinationPath = documentsPath.stringByAppendingPathComponent("\(groupName).jpg")
		UIImageJPEGRepresentation(image,1.0).writeToFile(destinationPath, atomically: true)
	}
	
	func setImage() {
		self.imgBackground.backgroundColor = UIColor.whiteColor()
		self.imgBackground.image = nil
		
		let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
		let groupName = self.object!["flatValue"] as! String
		let getImagePath = documentsPath.stringByAppendingPathComponent("\(groupName).jpg")
		
		var checkValidation = NSFileManager.defaultManager()
		if (checkValidation.fileExistsAtPath(getImagePath)) {
			let image = UIImage(contentsOfFile: getImagePath)
			self.imgBackground.image = image
			let fileAttrs = NSFileManager.defaultManager().attributesOfItemAtPath(getImagePath, error: nil)
			if fileAttrs != nil {
				let modDate = fileAttrs![NSFileModificationDate] as! NSDate
				if NSDate().timeIntervalSinceDate(modDate) > 86400 {
					println("Fetching new image for \(groupName)")
					getImage()
				}
			}
		} else {
			getImage()
		}
	}
	
	func offset() {
		var yOffset = ((parent.tblGroups.contentOffset.y - self.frame.origin.y) / self.imgBackground.frame.height) * OffsetSpeed
		imgBackground.frame = CGRectOffset(self.imgBackground.bounds, 0, yOffset)
	}

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
