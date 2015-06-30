//
//  AddGroupTableViewCell.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/06/24.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit

class AddGroupTableViewCell: UITableViewCell {
	
	@IBOutlet weak var viewBackground: UIView!
	@IBOutlet weak var spinner: UIActivityIndicatorView!
	@IBOutlet weak var imgAdd: UIImageView!
	
	var gesture: UITapGestureRecognizer!
	
	var parent : GroupsViewController!
	
    override func awakeFromNib() {
        super.awakeFromNib()
		
		gesture = UITapGestureRecognizer(target: self, action: "addGroup")
		viewBackground.addGestureRecognizer(gesture)
//		NSNotificationCenter.defaultCenter().addObserver(self, selector: "addSuccess", name: "addSuccess", object: nil)
        // Initialization code
    }
	
	func addGroup() {
		if parent.purchaseRunning == false {
			parent.btnAdd.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
		} else {
			global.showAlert("Please wait", message: "Processing your request. Please be patient.")
		}
//		viewBackground.removeGestureRecognizer(gesture)
//		imgAdd.hidden = true
//		spinner.startAnimating()
	}
	
	func addSuccess() {
//		viewBackground.addGestureRecognizer(gesture)
//		spinner.stopAnimating()
//		imgAdd.hidden = false
	}

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
