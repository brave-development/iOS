//
//  RegisterTableViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/18.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit

class RegisterTableViewController: UITableViewController, countryDelegate {
    
    @IBOutlet var tblDetails: UITableView!

    @IBOutlet weak var viewName: UITableViewCell!
    @IBOutlet weak var txtName: UITextField!
    
    @IBOutlet weak var viewUsername: UITableViewCell!
    @IBOutlet weak var txtUsername: UITextField!
    
    @IBOutlet weak var viewCellNumber: UITableViewCell!
    @IBOutlet weak var txtCellNumber: UITextField!
	
	@IBOutlet weak var viewEmail: UITableViewCell!
	@IBOutlet weak var txtEmail: UITextField!
	
    @IBOutlet weak var viewCountry: UITableViewCell!
    @IBOutlet weak var btnCountry: UIButton!
    
    @IBOutlet weak var viewPassword: UITableViewCell!
    @IBOutlet weak var txtPassword: UITextField!
    
    @IBOutlet weak var viewConfirmPassword: UITableViewCell!
    @IBOutlet weak var txtConfirmPassword: UITextField!
    
    var countrySelected = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblDetails.separatorStyle = UITableViewCellSeparatorStyle.None
		
        viewName.backgroundColor = UIColor(white: 1, alpha: 0.1)
        viewUsername.backgroundColor = UIColor(white: 1, alpha: 0.1)
        viewCellNumber.backgroundColor = UIColor(white: 1, alpha: 0.1)
		viewEmail.backgroundColor = UIColor(white: 1, alpha: 0.1)
        viewCountry.backgroundColor = UIColor(white: 1, alpha: 0.1)
        viewPassword.backgroundColor = UIColor(white: 1, alpha: 0.1)
        viewConfirmPassword.backgroundColor = UIColor(white: 1, alpha: 0.1)
        
        txtName.attributedPlaceholder = NSAttributedString(string:"Name and Surname",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        txtUsername.attributedPlaceholder = NSAttributedString(string:"Username",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        txtCellNumber.attributedPlaceholder = NSAttributedString(string:"Contact Number",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
		txtEmail.attributedPlaceholder = NSAttributedString(string:"Email",
			attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        txtPassword.attributedPlaceholder = NSAttributedString(string:"Password",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        txtConfirmPassword.attributedPlaceholder = NSAttributedString(string:"Confirm Password",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        
    }
    
    @IBAction func chooseCountry(sender: AnyObject) {
        var storyboard = UIStoryboard(name: "Main", bundle: nil)
        var vc: CountriesViewController = storyboard.instantiateViewControllerWithIdentifier("countriesViewController") as! CountriesViewController
        vc.delegate = self
        vc.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.presentViewController(vc, animated: true, completion: nil)
    }
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if cell.reuseIdentifier == "blank" {
			cell.backgroundColor = UIColor.clearColor()
		}
	}
	
    func didSelectCountry(country: String) {
        btnCountry.setTitle(country, forState: UIControlState.Normal)
        countrySelected = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
