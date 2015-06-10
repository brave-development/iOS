//
//  GroupsTableViewCell.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/06/10.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit

class GroupsTableViewCell: UITableViewCell {

	@IBOutlet weak var viewBar: UIView!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var lblCountry: UILabel!
	@IBOutlet weak var lblSubs: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
