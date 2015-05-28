//
//  PrivateGroupsTableViewCell.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/05.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//


// UNUSED

import UIKit

class PrivateGroupsTableViewCell: UITableViewCell {

    @IBOutlet weak var lblGroupName: UILabel!
    @IBOutlet weak var lblNumberOfSubs: UILabel!
    @IBOutlet weak var lblAdmin: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
