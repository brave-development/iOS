//
//  AddNewGroupViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/05.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import Social

class AddNewGroupViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var joinTopLayout: NSLayoutConstraint!
	@IBOutlet weak var joinHeightLayout: NSLayoutConstraint!
	@IBOutlet weak var joinWidthLayout: NSLayoutConstraint!
	
    
    @IBOutlet weak var textBoxContainerView: UIView!
    @IBOutlet weak var tblGroups: UITableView!
    @IBOutlet weak var viewLoading: UIVisualEffectView!
    @IBOutlet weak var btnJoin: UIButton!
    @IBOutlet weak var viewPrivate: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var switchPrivate: UISwitch!
	@IBOutlet weak var lblPublicInstruction: UILabel!
	@IBOutlet weak var lblInstruction: UILabel!
	@IBOutlet weak var lblPrivatePublic: UILabel!
	
	// Tutorial
	
	@IBOutlet weak var viewTutorial: UIVisualEffectView!
	@IBOutlet weak var lblTutorial: UILabel!
	@IBOutlet weak var segTutorial: UISegmentedControl!
    
    var selectedTextField : UITextField!
    var searching : Bool = false
    var groups : NSArray = []
    var privateGroups : [String] = []
    var groupsDuringSearch : NSArray = []
    var query : PFQuery!
	var searchSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		switchPrivate.backgroundColor = UIColor(hue:0.39, saturation:1, brightness:0.87, alpha:1)
		switchPrivate.layer.cornerRadius = 16.0
		
		searchBar.setShowsCancelButton(false, animated: true)
		tblGroups.hidden = true
		query = PFQuery(className: "Groups")
        viewLoading.hidden = true
        searchBar.tintColor = UIColor.whiteColor()
        viewPrivate.backgroundColor = UIColor.clearColor()
        viewPrivate.hidden = true
        btnJoin.hidden = true
        tblGroups.backgroundColor = UIColor.clearColor()
		
		searchSpinner.startAnimating()
		searchSpinner.frame.origin = CGPointMake(searchBar.frame.width - 120, 12)
		
		btnJoin.layer.cornerRadius = 0.5 * btnJoin.bounds.size.width
		btnJoin.layer.borderWidth = 2
		btnJoin.layer.borderColor = UIColor.whiteColor().CGColor
		btnJoin.backgroundColor = UIColor(white: 0, alpha: 0.3)
		
		if tutorial.addNewGroupView == false {
			viewTutorial.hidden = false
		}
    }
	
	override func viewDidAppear(animated: Bool) {
		if groupsHandler.referalGroup != nil {
			if groupsHandler.referalType == "publicGroup" {
				searchBar.selectedScopeButtonIndex = 0
			} else {
				searchBar.selectedScopeButtonIndex = 1
			}
			searchBar.text = groupsHandler.referalGroup
			groupsHandler.referalGroup = nil
			groupsHandler.referalType = nil
			groupsHandler.referalMember = nil
		}
	}
	
    func fetchGroups(initFetch : Bool = false) {
        if query != nil { query.cancel() }
		searchBar.addSubview(searchSpinner)
        query.whereKey("flatValue", hasPrefix: searchBar.text.formatGroupForFlatValue())
        query.orderByDescending("name")
        query.findObjectsInBackgroundWithBlock({
            (objects: [AnyObject]?, error: NSError?) -> Void in
            println("Running fetch")
            if error == nil && objects != nil {
                println("Fetch returned something")
                var tempGroupArray : [String] = []
                self.groups = []
                for groupRaw in objects! {
                    var groupObject = groupRaw as! PFObject
                    var groupString : String = groupObject["name"] as! String
                    if groupObject["public"] as! Bool == false {
                        self.privateGroups.append(groupString)
                    } else {
                        tempGroupArray.append(groupString)
                    }
                }
                self.groups = tempGroupArray as AnyObject as! [String]
                dispatch_async(dispatch_get_main_queue(), {
					self.searching = false
                    self.tblGroups.reloadData()
                    self.viewLoading.hidden = true
					self.searchSpinner.removeFromSuperview()
                })
            } else {
                global.showAlert("Error fetching groups", message: "There was an error retrieving the list of groups. Possibly check you internet connection.")
                self.viewLoading.hidden = true
				self.searchSpinner.removeFromSuperview()
            }
        })
    }
	
	func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
		switch (selectedScope) {
		case 0:
			println("Public")
			tblGroups.hidden = false
			tblGroups.reloadData()
			btnJoin.hidden = true
			viewPrivate.hidden = true
			break;
			
		case 1:
			println("Private")
			tblGroups.hidden = true
			btnJoin.hidden = false
			viewPrivate.hidden = true
			btnJoin.setTitle("Join", forState: UIControlState.Normal)
			animateChange(btnJoin, controlLayout: joinTopLayout, number: 170)
			animateChange(btnJoin, controlLayout: joinHeightLayout, number: 65)
			animateChange(btnJoin, controlLayout: joinWidthLayout, number: 65)
			btnJoin.layer.cornerRadius = 0.5 * btnJoin.bounds.size.width
			lblPublicInstruction.hidden = true
			break;
			
		case 2:
			println("New")
			tblGroups.hidden = true
			btnJoin.setTitle("Create", forState: UIControlState.Normal)
			btnJoin.hidden = false
			viewPrivate.hidden = false
			animateChange(btnJoin, controlLayout: joinTopLayout, number: 290)
			animateChange(btnJoin, controlLayout: joinHeightLayout, number: 65)
			animateChange(btnJoin, controlLayout: joinWidthLayout, number: 65)
			btnJoin.layer.cornerRadius = 0.5 * btnJoin.bounds.size.width
			lblPublicInstruction.hidden = true
			break;
			
		default:
			break;
		}
	}
	
	func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
		searchBar.setShowsCancelButton(true, animated: true)
		return true
	}
	
	func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
		searchBar.setShowsCancelButton(false, animated: true)
		return true
	}
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.selectedScopeButtonIndex == 0) {
            if count(searchBar.text) == 3 {
                fetchGroups(initFetch: false)
				if tblGroups.hidden == true {
					tblGroups.hidden = false
					lblInstruction.hidden = true
				}
				lblPublicInstruction.hidden = true
            } else if count(searchBar.text) > 3 { searching = true }
			var pred: NSPredicate = NSPredicate(format: "SELF contains[c] %@", searchText)
			groupsDuringSearch = groups.filteredArrayUsingPredicate(pred)
			tblGroups.reloadData()
        }
        if searchText.isEmpty {
            searching = false
			tblGroups.hidden = true
			lblInstruction.text = "Type at least 3 characters to search"
            tblGroups.reloadData()
        }
    }
	
	@IBAction func changePrivatePublicLabel(sender: AnyObject) {
		if switchPrivate.on == true {
			lblPrivatePublic.text = "Private"
		} else {
			lblPrivatePublic.text = "Public"
		}
	}
	
    
	@IBAction func join(sender: AnyObject) {
		if count(searchBar.text) > 2 {
			let index = advance(searchBar.text.startIndex, 1)
			let firstLetter = searchBar.text.substringToIndex(index)
			if (firstLetter.stringByTrimmingCharactersInSet(NSCharacterSet.letterCharacterSet()) == "") {
				if checkIfAlreadyContainsGroup() == false {
					if searchBar.selectedScopeButtonIndex == 1 {
						joinPrivateGroup()
					} else if searchBar.selectedScopeButtonIndex == 2 {
						createGroup()
					}
				}
			} else {
				global.showAlert("", message: "Group must begin with a letter")
			}
		} else {
			global.showAlert("", message: "Groups require 3 or more characters in their name")
		}
	}
	
	// Joins a private group
	func joinPrivateGroup() {
		if checkIfAlreadyContainsGroup() == false {
			btnJoin.enabled = false
			query.whereKey("flatValue", equalTo: searchBar.text.formatGroupForFlatValue())
			query.findObjectsInBackgroundWithBlock({
				(object : [AnyObject]?, error : NSError?) -> Void in
				if error == nil && object != nil {
					if object!.count > 0 {
						let pfObject = object?.first as! PFObject
						dispatch_async(dispatch_get_main_queue(), {
							let name = pfObject["name"] as! String
							groupsHandler.addGroup(name)
							global.showAlert("Successful", message: "You have joined the group \(name)")
							self.btnJoin.enabled = true
							self.dismissViewControllerAnimated(true, completion: nil)
						})
					} else {
						self.btnJoin.enabled = true
						global.showAlert("", message: "The group '\(self.searchBar.text)' does not exist. Check the spelling or use the New tab to create it")
					}
				}
			})
			self.btnJoin.enabled = true
		}
	}
	
	// CHANGED
	// Creates a new group
	func createGroup() {
		if checkIfAlreadyContainsGroup() == false {
			var error : NSErrorPointer?
			let tempGroupsArray : [String] = groups as! [String] // Used because you cannot run contains() on an NSArray. Converted to [String]
			if query != nil { query.cancel() }
			btnJoin.enabled = false
			switchPrivate.enabled = false
			searchBar.sizeToFit()
			
			var queryAddNewGroupCheckFlat = PFQuery(className: "Groups")
			query.whereKey("flatValue", equalTo: searchBar.text.formatGroupForFlatValue())
			query.findObjectsInBackgroundWithBlock({
				(object : [AnyObject]?, error : NSError?) -> Void in
				if object != nil {
					if object!.count == 0 {
						var newGroupObject : PFObject = PFObject(className: "Groups")
						newGroupObject["name"] = self.searchBar.text.lowercaseString.capitalizedString
						newGroupObject["flatValue"] = self.searchBar.text.formatGroupForFlatValue()
						newGroupObject["country"] = PFUser.currentUser()!.objectForKey("country")
						newGroupObject["admin"] = PFUser.currentUser()
						if self.switchPrivate.on {
							newGroupObject["public"] = false
						} else {
							newGroupObject["public"] = true
						}
						newGroupObject.saveInBackgroundWithBlock({
							(result: Bool, error: NSError?) -> Void in
							if result == true {
								dispatch_async(dispatch_get_main_queue(), {
									global.showAlert("Successful", message: "Group \(self.searchBar.text.lowercaseString.capitalizedString) created successfully. Please note - Private groups will not show up when someone searches for it. They will need to enter the groups name in the 'Private' tab and tap join.")
									self.btnJoin.enabled = true
									self.searchBar.showsScopeBar = true
									self.searchBar.sizeToFit()
									groupsHandler.addGroup(self.searchBar.text.lowercaseString.capitalizedString)
									self.dismissViewControllerAnimated(true, completion: nil)
								})
							} else {
								global.showAlert("Oops", message: error!.localizedFailureReason!)
								self.btnJoin.enabled = true
								//							self.searchBar.showsScopeBar = true
								self.searchBar.sizeToFit()
								self.switchPrivate.enabled = true
							}
						})
					} else {
						let pfObject = object?.first as! PFObject
						let name = pfObject["name"] as! String
						let country = pfObject["country"] as! String
						let privateGroup = pfObject["public"] as! Bool
						global.showAlert("Unseccessful", message: "Group '\(self.searchBar.text)' already exists\n\nName: \(name)\nCountry:\(country)\nPublic: \(privateGroup)")
						self.btnJoin.enabled = true
						//					self.searchBar.showsScopeBar = true
						self.searchBar.sizeToFit()
						self.switchPrivate.enabled = true
					}
				}
			})
		}
	}
	
	func checkIfAlreadyContainsGroup() -> Bool {
		for channel in global.installation.channels as! [String] {
			println(channel.formatGroupForFlatValue())
			println(searchBar.text.formatGroupForFlatValue())
			if channel.formatGroupForFlatValue() == searchBar.text.formatGroupForFlatValue() {
				return true
			}
		}
		return false
	}
	
    func animateChange(control : AnyObject, controlLayout : NSLayoutConstraint, number : CGFloat) {
        controlLayout.constant = number
        UIView.animateWithDuration(0.3, animations: {
            control.layoutIfNeeded()
        })
    }
	
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if searching == false {
            groupsHandler.addGroup(groups.objectAtIndex(indexPath.row) as! String)
            global.showAlert("Successful", message: "You have joined the group \(groups.objectAtIndex(indexPath.row))")
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            groupsHandler.addGroup(groupsDuringSearch.objectAtIndex(indexPath.row) as! String)
            global.showAlert("Successful", message: "You have joined the group \(groupsDuringSearch.objectAtIndex(indexPath.row))")
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching == true {
			if searchBar.text.isEmpty {
				tblGroups.hidden = true
				lblInstruction.text = "Type at least 3 characters to search"
				lblInstruction.hidden = false
			} else if groupsDuringSearch.count == 0 {
				tblGroups.hidden = true
				lblInstruction.text = "No results"
				lblInstruction.hidden = false
			} else {
				tblGroups.hidden = false
				lblInstruction.hidden = true
			}
			
            return groupsDuringSearch.count
        } else {
			if searchBar.text.isEmpty {
				tblGroups.hidden = true
				lblInstruction.text = "Type at least 3 characters to search"
				lblInstruction.hidden = false
			} else if groups.count == 0 {
				tblGroups.hidden = true
				lblInstruction.text = "No results"
				lblInstruction.hidden = false
			} else {
				tblGroups.hidden = false
				lblInstruction.hidden = true
			}
			
            return groups.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.backgroundColor = UIColor.clearColor()
        
        if searching == true {
            if groupsDuringSearch.objectAtIndex(indexPath.row) as! String == "" {
                cell.textLabel?.text = "Nil"
            } else {
                cell.textLabel?.text = (groupsDuringSearch.objectAtIndex(indexPath.row) as! String)
            }
            return cell
        } else {
            if groups.objectAtIndex(indexPath.row) as! NSString == "" {
                cell.textLabel?.text = "Nil"
            } else {
                cell.textLabel?.text = (groups.objectAtIndex(indexPath.row) as! String)
            }
            return cell
        }
    }
	
	// Tutorial
	
	@IBAction func changedSegmentTutorial(sender: AnyObject) {
		switch (segTutorial.selectedSegmentIndex) {
		case 0:
			lblTutorial.text = "Search for public groups here. Entering 3 or more characters will start a search for all public groups starting with those characters in your country."
			break;
			
		case 1:
			lblTutorial.text = "Use this tab to join a private group. To do this, enter the name of the group and tap the join button."
			break;
			
		case 2:
			lblTutorial.text = "If you wish to create a group that does not already exist, enter a name for the group, select whether you would like it to be a public or private group and tap 'create'."
			break;
			
		default:
			break;
		}
	}
	
	@IBAction func done(sender: AnyObject) {
		UIView.animateWithDuration(0.5, animations: {
			self.viewTutorial.alpha = 0.0 }, completion: {
				(finished: Bool) -> Void in
				self.viewTutorial.hidden = true
		})
		tutorial.addNewGroupView = true
		tutorial.save()
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
    
    @IBAction func back(sender: AnyObject) {
		if query != nil { query.cancel() }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
