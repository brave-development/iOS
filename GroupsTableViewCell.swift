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
	
	var object: PFObject?
	var subsCount: Int = 0

	@IBOutlet weak var viewBar: UIView!
	@IBOutlet weak var imgBackground: UIImageView!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var lblCountry: UILabel!
	@IBOutlet weak var lblSubs: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
		
		if object != nil {
		}
		
        // Initialization code
    }
	
	func setup() {
		getImage()
		
		lblName.text = object?["name"] as? String
		lblCountry.text = object?["country"] as? String
		lblSubs.text = "\(subsCount)"
		
		if (object!["public"] as? Bool) == true {
			if subsCount > 2 { subsCount += 12 }
			lblSubs.text = "\(subsCount)"
			viewBar.backgroundColor = UIColor(red: 40/255, green: 185/255, blue: 38/255, alpha: 1)
		} else {
			viewBar.backgroundColor = UIColor(red: 14/255, green: 142/255, blue: 181/255, alpha: 1)
		}
	}
	
	func getImage() {
		let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
		let groupName = self.object!["flatValue"] as! String
		let getImagePath = documentsPath.stringByAppendingPathComponent("\(groupName).jpg")
		
		var checkValidation = NSFileManager.defaultManager()
		if (checkValidation.fileExistsAtPath(getImagePath)) {
			let image = UIImage(contentsOfFile: getImagePath)
			self.imgBackground.image = image
		} else {
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
		}
	}

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
