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
	var indexPath: NSIndexPath!

	@IBOutlet weak var viewBar: UIView! 
	@IBOutlet weak var imgBackground: UIImageView!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var lblCountry: UILabel!
	@IBOutlet weak var lblSubs: UILabel!
	@IBOutlet weak var btnLeave: UIButton!
	
    override func awakeFromNib() {
        super.awakeFromNib()
    }
	
	func setup() {
		setImage()
		
		self.clipsToBounds = true
		
		let groupName = object!["name"] as! String
		
		lblName.text = groupName
		if object?["description"] != nil {
			lblCountry.text = object?["description"] as? String
		} else {
			lblCountry.text = object?["country"] as? String
		}
		lblSubs.text = "\(subsCount)"
		
//		if (object!["public"] as? Bool) == true {
//			if subsCount > 2 { subsCount += 12 }
//			lblSubs.text = "\(subsCount)"
//			viewBar.backgroundColor = UIColor(red: 40/255, green: 185/255, blue: 38/255, alpha: 1)
//		} else {
//			viewBar.backgroundColor = UIColor(red: 14/255, green: 142/255, blue: 181/255, alpha: 1)
//		}
		
		imgBackground.clipsToBounds = true
		
		btnLeave.layer.cornerRadius = 5
		btnLeave.layer.borderColor = UIColor.whiteColor().CGColor
		btnLeave.layer.borderWidth = 1
		btnLeave.clipsToBounds = true
		btnLeave.backgroundColor = UIColor(white: 0, alpha: 0.2)
		
//		println(lblName.text!)
//		println(find(groupsHandler.joinedGroups, groupName))
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
	
	@IBAction func joinLeave(sender: AnyObject) {
		let groupName = self.object!["name"] as! String
		if alreadyJoined == true {
			var deleteAlert = UIAlertController(title: "Leave \(groupName)?", message: "Are you sure you want to leave this group?", preferredStyle: UIAlertControllerStyle.Alert)
			deleteAlert.addAction(UIAlertAction(title: "Leave", style: .Destructive, handler: { (action: UIAlertAction!) in
				groupsHandler.removeGroup(groupName)
				groupsHandler.joinedGroupsObject[self.object?["flatValue"] as! String] = nil
				self.parent.populateDataSource()
				if groupsHandler.joinedGroupsObject.count == 0 {
					self.parent.tblGroups.reloadData()
				} else {
					self.parent.tblGroups.deleteRowsAtIndexPaths([self.indexPath], withRowAnimation: .Automatic)
				}
			}))
			deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in }))
			self.parent.presentViewController(deleteAlert, animated: true, completion: nil)
		}
	}
	
	func getImage() {
		let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
		let groupName = self.object!["flatValue"] as! String
		let getImageDispatch: dispatch_queue_t = dispatch_queue_create("getImageDispatch", nil)
		dispatch_async(getImageDispatch, {
			if self.object!["image"] != nil {
				let imageUrl: String = self.object!["image"] as! String
				let url = NSURL(string: imageUrl)
				if let data = NSData(contentsOfURL: url!){
					let image = UIImage(data: data)
					self.imgBackground.image = image
					let destinationPath = documentsPath.stringByAppendingPathComponent("\(groupName).jpg")
					UIImageJPEGRepresentation(image,1.0).writeToFile(destinationPath, atomically: true)
				}
			}
		})
		//		}
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
		} else {
			getImage()
		}
	}
	
	func offset() {
		let OffsetSpeed: CGFloat = 35.0
		var yOffset = ((parent.tblGroups.contentOffset.y - self.frame.origin.y) / self.imgBackground.frame.height) * OffsetSpeed
		imgBackground.frame = CGRectOffset(self.imgBackground.bounds, 0, yOffset)
	}

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
