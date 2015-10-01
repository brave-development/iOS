//
//  AddPublicGroupViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/09/23.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

class AddPublicGroupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
	
	var searchGroups : [String : PFObject] = [:]
	var searchedGroupsIdHolder : [String] = []
	var nearbyGroupIdHolder : [String] = []
	
	var query : PFQuery!
	var parent: GroupsViewController!
	
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
		hideNotificationBar()
		tableView.layer.shadowOffset = CGSizeZero
		tableView.layer.shadowRadius = 10
		tableView.layer.shadowOpacity = 1
    }
	
	func fetchGroups() {
		if query != nil { query.cancel() }
//		searchBar.addSubview(searchSpinner)
		showNotificationBar(text: "Searching groups")
		query.whereKey("flatValue", hasPrefix: searchBar.text.formatGroupForFlatValue())
		query.orderByDescending("flatValue")
		query.findObjectsInBackgroundWithBlock({
			(objects: [AnyObject]?, error: NSError?) -> Void in
			println("Running fetch - AddPublicViewController - 34")
			if error == nil && objects != nil {
				println("Fetch returned something")
//				var tempGroupArray : [String] = []
				self.searchGroups = [:]
				for groupRaw in objects! {
					var groupObject = groupRaw as! PFObject
					var groupName = groupObject["name"] as! String
					if groupObject["public"] as! Bool == true {
						self.searchGroups[groupName] = groupObject
					}
				}
				dispatch_async(dispatch_get_main_queue(), {
//					self.searching = false
					self.tableView.reloadData()
					self.hideNotificationBar()
//					self.viewLoading.hidden = true
//					self.searchSpinner.removeFromSuperview()
				})
			} else {
				global.showAlert("Error fetching groups", message: "There was an error retrieving the list of groups. Possibly check you internet connection.")
//				self.viewLoading.hidden = true
//				self.searchSpinner.removeFromSuperview()
			}
		})
	}
	
//	func populateDataSource() {
//		searchedGroupsIdHolder = []
//		for (id, group) in groupsHandler.joinedGroupsObject {
//			searchedGroupsIdHolder.append(id)
//		}
//		
//		nearbyGroupIdHolder = []
//		for (id, group) in groupsHandler.nearbyGroupObjects {
//			nearbyGroupIdHolder.append(id)
//		}
//	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if searchGroups.count == 0 { return 1 }
		return 2
	}
	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 1 { return 0 } // REMOVE FOR A VIEW
		return 40
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		var view = UIView(frame: CGRectMake(0, 0, tableView.frame.width, 40))
		let label = UILabel(frame: view.bounds)
		label.textAlignment = NSTextAlignment.Center
		label.font = UIFont(name: "Arial", size: 11)
		view.backgroundColor = UIColor(white: 1, alpha: 0.95)
		
		if section == 0 {
			label.text = "RESULTS"
		} else {
			label.text = "NEARBY"
		}
		view.addSubview(label)
		return view
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0{
			if searchGroups.count == 0 { return 1 }
			return searchGroups.count
		} else {
			return nearbyGroupIdHolder.count
		}
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if searchGroups.count == 0 && indexPath.section == 0 { return 60 }
		return 260
	}
	
	 func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if searchGroups.count == 0 && indexPath.section == 0 {
			if count(searchBar.text) >= 3 {
				let cellNoGroupsFound = tableView.dequeueReusableCellWithIdentifier("noGroupsFound", forIndexPath: indexPath) as! UITableViewCell
				return cellNoGroupsFound
			}
			let cellNoGroups = tableView.dequeueReusableCellWithIdentifier("noGroups", forIndexPath: indexPath) as! UITableViewCell
			return cellNoGroups
		}
		
		var group: PFObject!
		var cell = tableView.dequeueReusableCellWithIdentifier("newCell", forIndexPath: indexPath) as! GroupsTableViewCell
		
		if indexPath.section == 0 {
			group = searchGroups[searchGroups.keys.array[indexPath.row]]!
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
		cell.parent = parent
		cell.setup()
		
		return cell
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		for cell in tableView.visibleCells() {
			if cell is GroupsTableViewCell && cell.frame.size.height != 60 {
				(cell as! GroupsTableViewCell).offset(tableView.contentOffset.y)
			}
		}
	}
	
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		if count(searchBar.text) >= 3 { fetchGroups() }
		
//		var pred: NSPredicate = NSPredicate(format: "SELF contains[c] %@", searchText)
//		groupsDuringSearch = groups.filteredArrayUsingPredicate(pred)
//		tblGroups.reloadData()
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	@IBAction func hideKeyboard(sender: AnyObject) {
		searchBar.resignFirstResponder()
	}
	
	// Notification bar
	
	func showNotificationBar(text: String = "") {
		layoutNotificationTop.constant = 0
		layoutBackTop.constant = 0
		layoutSearchBarTop.constant = 0
		lblNotificationText.text = text
		if text == "" { notificationSpinner.startAnimating() }
		UIView.animateWithDuration(0.3, animations: {
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
		UIView.animateWithDuration(0.3, animations: {
			self.notificationBar.layoutIfNeeded()
			self.searchBar.layoutIfNeeded()
			self.tableView.layoutIfNeeded()
		})
	}
	
	
	@IBAction func close(sender: AnyObject) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
