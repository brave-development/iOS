//
//  RegisterTableViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/18.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit
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
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


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
    
    @IBOutlet weak var viewBetaCode: UITableViewCell!
    @IBOutlet weak var txtBetaCode: UITextField!
    
    
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
        textFields.append(txtBetaCode)
		
		txtName.delegate = self
		txtUsername.delegate = self
		txtCellNumber.delegate = self
		txtEmail.delegate = self
		txtPassword.delegate = self
		txtConfirmPassword.delegate = self
        txtBetaCode.delegate = self
		
        tblDetails.separatorStyle = UITableViewCellSeparatorStyle.none
		let backgroundColour = UIColor(white: 0, alpha: 0.3)
		let placeholderTextColour = UIColor(white: 1, alpha: 1)
		
        viewName.backgroundColor = backgroundColour
        viewUsername.backgroundColor = backgroundColour
        viewCellNumber.backgroundColor = backgroundColour
		viewEmail.backgroundColor = backgroundColour
        viewCountry.backgroundColor = backgroundColour
        viewPassword.backgroundColor = backgroundColour
        viewConfirmPassword.backgroundColor = backgroundColour
        viewBetaCode.backgroundColor = backgroundColour
        
        txtName.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("name_surname", value: "Name and Surname", comment: "Asking for ..."),
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        txtUsername.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("username", value: "Username", comment: "Asking for..."),
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        txtCellNumber.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("contact_number", value: "Contact Number", comment: "Asking for..."),
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
		txtEmail.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("email", value: "Email", comment: "Asking for..."),
			attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        txtPassword.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("password", value: "Password", comment: "Asking for..."),
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        txtConfirmPassword.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("password_confirm", value: "Confirm Password", comment: "Asking for..."),
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        txtBetaCode.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("beta_code", value: "Referral Code (optional)", comment: "Asking for..."),
            attributes:[NSForegroundColorAttributeName: placeholderTextColour])
        
    }
    
    @IBAction func chooseCountry(_ sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc: CountriesViewController = storyboard.instantiateViewController(withIdentifier: "countriesViewController") as! CountriesViewController
        vc.delegate = self
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        self.present(vc, animated: true, completion: nil)
    }
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if cell.reuseIdentifier == "blank" {
			cell.backgroundColor = UIColor.clear
		}
	}
	
    func didSelectCountry(_ country: String) {
        btnCountry.setTitle(country, for: UIControlState())
        countrySelected = true
    }
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		let index = textFields.index(of: textField)
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
