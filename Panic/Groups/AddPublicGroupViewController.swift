//
//  AddPublicGroupViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/09/23.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class AddPublicGroupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
	
	@IBOutlet weak var btnBack: UIButton!
	var searchGroups : [String : PFObject] = [:]
	var searchedGroupsIdHolder : [String] = []
	var nearbyGroupIdHolder : [String] = []
	
	var query : PFQuery<PFObject>!
	var parentVC: GroupsViewController!
	
	@IBOutlet weak var notificationBar: UIView!
	@IBOutlet weak var lblNotificationText: UILabel!
	@IBOutlet weak var notificationSpinner: UIActivityIndicatorView!
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var tableView: UITableView!
	
	@IBOutlet weak var layoutNotificationTop: NSLayoutConstraint!
	@IBOutlet weak var layoutBackTop: NSLayoutConstraint!
	@IBOutlet weak var layoutSearchBarTop: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
		query = PFQuery(className: "Groups")
		searchBar.delegate = self
//        searchBar.text.
		hideNotificationBar()
		tableView.layer.shadowOffset = CGSize.zero
		tableView.layer.shadowRadius = 10
		tableView.layer.shadowOpacity = 1
		NotificationCenter.default.addObserver(self, selector: #selector(backBecauseOfGroupJoined), name: NSNotification.Name(rawValue: "didJoinGroup"), object: nil)
    }
	
	func fetchGroups() {
		if query != nil { query.cancel() }
		showNotificationBar(NSLocalizedString("searching_groups", value: "Searching groups", comment: ""))
		query.whereKey("flatValue", hasPrefix: searchBar.text!.formatGroupForFlatValue())
		query.order(byDescending: "flatValue")
		query.findObjectsInBackground(block: {
			(objects, error) in
			print("Running fetch - AddPublicViewController - 51")
			if error == nil && objects != nil {
				print("Fetch returned something")
				self.searchGroups = [:]
				for groupRaw in objects! {
					let groupObject = groupRaw 
					let groupName = groupObject["name"] as! String
					if groupObject["public"] as! Bool == true {
						self.searchGroups[groupName] = groupObject
					}
				}
				DispatchQueue.main.async(execute: {
					self.tableView.reloadData()
					self.hideNotificationBar()
				})
			} else {
				global.showAlert(NSLocalizedString("error_fetching_groups_title", value: "Error fetching groups", comment: ""), message: NSLocalizedString("error_fetching_groups_text", value: "There was an error retrieving the list of groups. Possibly check you internet connection.", comment: ""))
			}
		})
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		if searchGroups.count == 0 { return 1 }
		return 2
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 1 { return 0 } // REMOVE FOR A VIEW
		return 40
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
		let label = UILabel(frame: view.bounds)
		label.textAlignment = NSTextAlignment.center
		label.font = UIFont(name: "Arial", size: 11)
		view.backgroundColor = UIColor(white: 1, alpha: 0.95)
		
		if section == 0 {
			label.text = NSLocalizedString("results", value: "RESULTS", comment: "")
		} else {
			label.text = NSLocalizedString("nearby", value: "NEARBY", comment: "")
		}
		view.addSubview(label)
		return view
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0{
			if searchGroups.count == 0 { return 1 }
			return searchGroups.count
		} else {
			return nearbyGroupIdHolder.count
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if searchGroups.count == 0 && indexPath.section == 0 { return 60 }
		return 260
	}
	
	 func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if searchGroups.count == 0 && indexPath.section == 0 {
			if searchBar.text?.characters.count >= 3 {
				let cellNoGroupsFound = tableView.dequeueReusableCell(withIdentifier: "noGroupsFound", for: indexPath) 
				return cellNoGroupsFound
			}
			let cellNoGroups = tableView.dequeueReusableCell(withIdentifier: "noGroups", for: indexPath) 
			return cellNoGroups
		}
		
		var group: PFObject!
		let cell = tableView.dequeueReusableCell(withIdentifier: "newCell", for: indexPath) as! GroupsTableViewCell
		
		if indexPath.section == 0 {
			group = searchGroups[Array(searchGroups.keys)[indexPath.row]]!
		} else {
			group = groupsHandler.nearbyGroupObjects[nearbyGroupIdHolder[indexPath.row]]!
		}
		var subsCount: Int!
		if group["subscriberObjects"] != nil {
			subsCount = (group["subscriberObjects"] as? [String])!.count
		} else {
			subsCount = 0
		}
		cell.object = group
		cell.subsCount = subsCount
		cell.parentVC = parentVC
		cell.setup()
		
		return cell
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		for cell in tableView.visibleCells {
			if cell is GroupsTableViewCell && cell.frame.size.height != 60 {
				(cell as! GroupsTableViewCell).offset(tableView.contentOffset.y)
			}
		}
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		if searchBar.text?.characters.count >= 3 { fetchGroups() }
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	@IBAction func hideKeyboard(_ sender: AnyObject) {
		searchBar.resignFirstResponder()
	}
	
	func backBecauseOfGroupJoined() {
		self.dismiss(animated: true, completion: nil)
	}
	
	// Notification bar
	
	func showNotificationBar(_ text: String = "") {
		layoutNotificationTop.constant = 0
		layoutBackTop.constant = 0
		layoutSearchBarTop.constant = 0
		lblNotificationText.text = text
		if text == "" { notificationSpinner.startAnimating() }
		UIView.animate(withDuration: 0.3, animations: {
			self.notificationBar.layoutIfNeeded()
			self.searchBar.layoutIfNeeded()
			self.tableView.layoutIfNeeded()
		})
	}
	
	func hideNotificationBar() {
		lblNotificationText.text = ""
		layoutNotificationTop.constant = -notificationBar.frame.height// + 20
		layoutBackTop.constant = 20
		layoutSearchBarTop.constant = 20
		notificationSpinner.stopAnimating()
		UIView.animate(withDuration: 0.3, animations: {
			self.notificationBar.layoutIfNeeded()
			self.searchBar.layoutIfNeeded()
			self.tableView.layoutIfNeeded()
		})
	}
	
	@IBAction func close(_ sender: AnyObject) {
		self.dismiss(animated: true, completion: nil)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
