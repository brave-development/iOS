//
//  PublicHistoryTableViewCell.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/04.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

// UNUSED

import UIKit
import Parse

class PublicHistoryTableViewCell: UITableViewCell {
    
	@IBOutlet weak var lblDate: UILabel!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var spinner: UIActivityIndicatorView!
	@IBOutlet weak var btnDisclosure: UIButton!
	
//	let object : PFObject!
	
	
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
	
	@IBAction func showDetails(sender: AnyObject) {
		btnDisclosure.hidden = true
		spinner.startAnimating()
	}
	
	func cancelDetailFetch() {
		
	}
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
