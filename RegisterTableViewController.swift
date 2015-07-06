//
//  RegisterTableViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/18.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit

class RegisterTableViewController: UITableViewController, countryDelegate, UITextFieldDelegate {
    
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
	var textFields : [UITextField] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()
		textFields.append(txtName)
		textFields.append(txtUsername)
		textFields.append(txtCellNumber)
		textFields.append(txtEmail)
		textFields.append(txtPassword)
		textFields.append(txtConfirmPassword)
		
		txtName.delegate = self
		txtUsername.delegate = self
		txtCellNumber.delegate = self
		txtEmail.delegate = self
		txtPassword.delegate = self
		txtConfirmPassword.delegate = self
		
        tblDetails.separatorStyle = UITableViewCellSeparatorStyle.None
		let backgroundColour = UIColor(white: 0, alpha: 0.3)
		let placeholderTextColour = UIColor(white: 1, alpha: 1)
		
        viewName.backgroundColor = backgroundColour
        viewUsername.backgroundColor = backgroundColour
        viewCellNumber.backgroundColor = backgroundColour
		viewEmail.backgroundColor = backgroundColour
        viewCountry.backgroundColor = backgroundColour
        viewPassword.backgroundColor = backgroundColour
        viewConfirmPassword.backgroundColor = backgroundColour
        
        txtName.attributedPlaceholder = NSAttributedString(string:"Name and Surname",
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        txtUsername.attributedPlaceholder = NSAttributedString(string:"Username",
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        txtCellNumber.attributedPlaceholder = NSAttributedString(string:"Contact Number",
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
		txtEmail.attributedPlaceholder = NSAttributedString(string:"Email",
			attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        txtPassword.attributedPlaceholder = NSAttributedString(string:"Password",
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        txtConfirmPassword.attributedPlaceholder = NSAttributedString(string:"Confirm Password",
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        
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
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		let index = find(textFields, textField)
		if index != nil {
			if textFields.count - 1 > index {
				textFields[index! + 1].becomeFirstResponder()
			} else if textFields.count - 1 == index {
				textField.resignFirstResponder()
			}
		}
		return true
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
