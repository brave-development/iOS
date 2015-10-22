//
//  CreateGroupViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/08/31.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

class CreateGroupViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate {
	
	let imagePicker = UIImagePickerController()
	var publicGroup = true
	var imageChosen = false
	var group: PFObject?
	
	@IBOutlet weak var blurView: UIVisualEffectView!
	@IBOutlet weak var btnClose: UIButton!
	@IBOutlet weak var btnFinish: UIButton!
	@IBOutlet weak var viewContent: UIView!
	@IBOutlet weak var btnLeave: UIButton!
	
	@IBOutlet weak var imgBackground: UIImageView!
	@IBOutlet weak var btnEditBackground: UIButton!
	@IBOutlet weak var btnLock: UIButton!
	@IBOutlet weak var txtName: UITextView!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var txtDescription: UITextView!
	@IBOutlet weak var lblDescription: UILabel!
	@IBOutlet weak var spinner: UIActivityIndicatorView!
	
	// tutorial
	
	var tooltipPicture: Tooltip!
	var tooltipLock: Tooltip!
	var tooltipSubs: Tooltip!
	var tooltipJoinButton: Tooltip!
	@IBOutlet weak var tutorialImgChoosePhotoUp: UIImageView!
	@IBOutlet weak var tutorialViewChoosePhoto: UIView!
	@IBOutlet weak var tutorialViewLock: UIView!
	@IBOutlet weak var tutorialImgLock: UIImageView!
	@IBOutlet weak var tutorialViewSubs: UIView!
	@IBOutlet weak var tutorialImgSubs: UIImageView!
	@IBOutlet weak var tutorialViewButton: UIView!
	@IBOutlet weak var tutorialImgButton: UIImageView!
	
	
	@IBOutlet weak var layoutTxtDescriptionBottom: NSLayoutConstraint!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardUp:", name: UIKeyboardDidShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDown", name: UIKeyboardWillHideNotification, object: nil)
		
		imagePicker.delegate = self
		txtName.delegate = self
		txtDescription.delegate = self
		
		let tapGesture = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
		imgBackground.addGestureRecognizer(tapGesture)
		blurView.addGestureRecognizer(tapGesture)
		
		self.view.backgroundColor = UIColor.clearColor()
		viewContent.layer.cornerRadius = 5
		viewContent.layer.shadowRadius = 4
		viewContent.layer.shadowColor = UIColor.blackColor().CGColor
		viewContent.layer.shadowOffset = CGSizeZero
		viewContent.layer.shadowOpacity = 0.4
		viewContent.layer.borderColor = UIColor.whiteColor().CGColor
		viewContent.layer.borderWidth = 1.0
		
		imgBackground.layer.cornerRadius = 5
		imgBackground.clipsToBounds = true
		imgBackground.layer.shadowOffset = CGSizeZero
		imgBackground.layer.shadowRadius = 4
		imgBackground.layer.shadowOpacity = 0.4
//		imgBackground.contentMode = .ScaleAspectFill
		
		btnLeave.layer.cornerRadius = 5
		btnLeave.layer.borderColor = UIColor.whiteColor().CGColor
		btnLeave.layer.borderWidth = 1
		btnLeave.clipsToBounds = true
		btnLeave.enabled = false
		btnLeave.alpha = 0.7
		
		txtName.layer.cornerRadius = 5
		txtName.clipsToBounds = true
		txtDescription.layer.cornerRadius = 5
		txtDescription.clipsToBounds = true
		
		txtName.backgroundColor = UIColor(white: 1, alpha: 0.5)
		txtDescription.backgroundColor = UIColor(white: 1, alpha: 0.5)
		
		lblName.text = ""
		lblDescription.text = ""
		
		// Tutorial stuff
		
		tooltipPicture = Tooltip(view: tutorialViewChoosePhoto, arrow: tutorialImgChoosePhotoUp)
		tooltipLock = Tooltip(view: tutorialViewLock, arrow: tutorialImgLock)
		tooltipSubs = Tooltip(view: tutorialViewSubs, arrow: tutorialImgSubs, hidden: true)
		tooltipJoinButton = Tooltip(view: tutorialViewButton, arrow: tutorialImgButton, hidden: true)
		
		if group != nil {
			fillData()
		}
    }
	
	func fillData() {
		imgBackground.contentMode = .ScaleAspectFill
		txtName.text = group!["name"] as! String
		txtName.hidden = true
		lblName.text = txtName.text
		
		if group!["description"] != nil {
			txtDescription.text = group!["description"] as? String
		} else {
			txtDescription.text = group!["country"] as? String
		}
		lblDescription.text = txtDescription.text
		
		if (group!["public"] as? Bool) == false {
			btnLock.setImage(UIImage(named: "lock"), forState: .Normal)
			publicGroup = false
		}
		
		setImage()
		btnFinish.setTitle(NSLocalizedString("save", value: "Save", comment: ""), forState: UIControlState.Normal)
	}
	
	@IBAction func choseBackground(sender: AnyObject) {
		tooltipPicture.hide()
		imagePicker.allowsEditing = true
		imagePicker.sourceType = .PhotoLibrary
		
		presentViewController(imagePicker, animated: true, completion: nil)
	}
	
	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
		
		if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
			
			imgBackground.image = pickedImage
			imgBackground.alpha = 1
			imgBackground.contentMode = .ScaleAspectFill
			viewContent.layer.borderWidth = 0.0
			btnLeave.backgroundColor = UIColor(white: 0, alpha: 0.3)
			imageChosen = true
			
			let gradient = drawing.gradient(viewContent, colours: [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor], locations: [0.0 , 1.0], opacity: 0.5)
			viewContent.layer.insertSublayer(gradient, atIndex: 1)
		}
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	func imagePickerControllerDidCancel(picker: UIImagePickerController) {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func privatePublic(sender: AnyObject) {
		publicGroup = !publicGroup
		
		if publicGroup == true {
			btnLock.setImage(UIImage(named: "unlock"), forState: .Normal)
			tooltipLock.setText(NSLocalizedString("open_comm", value: "Open community", comment: ""))
		} else {
			btnLock.setImage(UIImage(named: "lock"), forState: .Normal)
			tooltipLock.setText(NSLocalizedString("closed_group", value: "Closed group", comment: ""))
		}
	}
	
	@IBAction func finish(sender: AnyObject) {
		if validate() == true {
			if group != nil {
				editGroup()
			} else {
				newGroup()
			}
			NSNotificationCenter.defaultCenter().postNotificationName("gotNearbyGroups", object: nil)
		}
	}
	
	func newGroup() {
		var message: String = NSLocalizedString("group_set_to_private_text", value: "This group is set to private. It will therfore NOT SHOW in any searches or nearby suggestions.", comment: "")  // If set to PRIVATE
		if self.publicGroup == true { message = NSLocalizedString("group_set_to_public_text", value: "This group is set to public. It will therfor SHOW in all searches and nearby suggestions and anyone will be able to join it", comment: "")}
		var saveAlert = UIAlertController(title: NSLocalizedString("are_you_sure", value: "Are you sure?", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.Alert)
		saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
			// Clicked YES
			self.spinner.startAnimating()
			self.btnClose.enabled = false
			self.btnFinish.enabled = false
			self.txtName.userInteractionEnabled = false
			self.txtDescription.userInteractionEnabled = false
			self.btnEditBackground.enabled = false
			self.btnLock.enabled = false
			
			var image: PFFile = PFFile(data: UIImageJPEGRepresentation(self.imgBackground.image!, 0.7) , contentType: "image")
			var newGroupObject : PFObject = PFObject(className: "Groups")
			newGroupObject["name"] = self.txtName.text.trim().lowercaseString.capitalizedString
			newGroupObject["flatValue"] = self.txtName.text.trim().formatGroupForFlatValue()
			newGroupObject["country"] = PFUser.currentUser()!.objectForKey("country")
			newGroupObject["admin"] = PFUser.currentUser()
			if self.publicGroup == true {
				newGroupObject["public"] = true
			} else {
				newGroupObject["public"] = false
			}
			newGroupObject["imageFile"] = image
			if groupsHandler.checkIfGroupExists(newGroupObject) == false {
				groupsHandler.createGroup(newGroupObject, parent: self)
			} else {
				self.spinner.stopAnimating()
				self.btnClose.enabled = true
				self.btnFinish.enabled = true
				self.txtName.userInteractionEnabled = true
				self.txtDescription.userInteractionEnabled = true
				self.btnEditBackground.enabled = true
				self.btnLock.enabled = true
			}
		}))
		saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
			self.tooltipLock.show()
		}))
		presentViewController(saveAlert, animated: true, completion: nil)
	}
	
	func editGroup() {
		self.spinner.startAnimating()
		self.btnClose.enabled = false
		self.btnFinish.enabled = false
		self.txtName.userInteractionEnabled = false
		self.txtDescription.userInteractionEnabled = false
		self.btnEditBackground.enabled = false
		self.btnLock.enabled = false
		
		let groupName = group!["flatValue"] as! String
		let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
		let destinationPath = documentsPath.stringByAppendingPathComponent("\(groupName).jpg")
		UIImageJPEGRepresentation(imgBackground.image,1.0).writeToFile(destinationPath, atomically: true)
		
		var image: PFFile = PFFile(data: UIImageJPEGRepresentation(self.imgBackground.image!, 0.7) , contentType: "image")
		group!["name"] = self.txtName.text.trim().lowercaseString.capitalizedString
		group!["description"] = self.txtDescription.text.trim()
		group!["flatValue"] = self.txtName.text.trim().formatGroupForFlatValue()
		group!["country"] = PFUser.currentUser()!.objectForKey("country")
		group!["admin"] = PFUser.currentUser()
		if self.publicGroup == true {
			group!["public"] = true
		} else {
			group!["public"] = false
		}
		group!["imageFile"] = image
		group!.saveInBackgroundWithBlock({
			(result: Bool, error: NSError?) -> Void in
			if error != nil {
				global.showAlert("", message: NSLocalizedString("error_update_failed", value: "Something went wrong during the update. Please try again.", comment: ""))
			} else {
				global.showAlert("", message: NSLocalizedString("update_successful", value: "Updated successfully", comment: ""))
				self.dismissViewControllerAnimated(true, completion: nil)
			}
		})
	}
	
	//
	let groupNameLocalized = NSLocalizedString("group_name", value: "Group Name", comment: "")
	let groupDescriptionLocalized = NSLocalizedString("group_description", value: "Group Description", comment: "")
	//
	
	func validate() -> Bool {
		var message: String = ""
		if count(txtName.text.trim()) < 3 || txtName.text == groupNameLocalized { message = message + NSLocalizedString("error_name_3_chars", value: "Name must be 3 or more characters", comment: "") + "\n" }
		if count(txtDescription.text.trim()) < 10 || txtDescription.text == groupDescriptionLocalized { message = message + NSLocalizedString("error_description_10_chars", value: "Description must be 10 or more characters", comment: "") + "\n" }
		if imageChosen == false { message = message + NSLocalizedString("error_choose_image", value: "Please choose an image", comment: "") + "\n"; tooltipPicture.show() }
		
		if count(message.trim()) > 0 {
			global.showAlert("", message: message)
			return false
		}
		return true
	}
	
	func dismissKeyboard() {
		self.view.endEditing(true)
	}
	
	func textViewDidBeginEditing(textView: UITextView) {
		switch (textView.tag) {
		case 0:
			if txtName.text == groupNameLocalized { txtName.text = "" }
			break
			
		case 1:
			if txtDescription.text == groupDescriptionLocalized { txtDescription.text = "" }
			break
			
		default:
			break
		}
	}
	
	func textViewDidEndEditing(textView: UITextView) {
		switch (textView.tag) {
		case 0:
			if txtName.text == "" { txtName.text = groupNameLocalized }
			break
			
		case 1:
			if txtDescription.text == "" { txtDescription.text = groupDescriptionLocalized }
			break
			
		default:
			break
		}
	}
	
	func textViewDidChange(textView: UITextView) {
		switch (textView.tag) {
		case 0:
			lblName.text = txtName.text
			break
			
		case 1:
			lblDescription.text = txtDescription.text
			break
			
		default:
			break
		}
	}
	
	func keyboardUp(notification: NSNotification) {
		let info  = notification.userInfo!
		let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]!
		
		let rawFrame = value.CGRectValue()
		let keyboardFrame = view.convertRect(rawFrame, fromView: nil)
		layoutTxtDescriptionBottom.constant = keyboardFrame.height + 20
		UIView.animateWithDuration(0.3, animations: {
			self.layoutSubview()
		})
	}
	
	func keyboardDown() {
		layoutTxtDescriptionBottom.constant = 0
		UIView.animateWithDuration(0.3, animations: {
			self.layoutSubview()
		})
	}
	
	func layoutSubview() {
		for view in self.view.subviews {
			view.layoutIfNeeded()
		}
	}
	
	func setImage() {
		self.imgBackground.backgroundColor = UIColor.whiteColor()
		self.imgBackground.image = nil
		imageChosen = true
		
		let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
		let groupName = self.group!["flatValue"] as! String
		let getImagePath = documentsPath.stringByAppendingPathComponent("\(groupName).jpg")
		
		var checkValidation = NSFileManager.defaultManager()
		if (checkValidation.fileExistsAtPath(getImagePath)) {
			let image = UIImage(contentsOfFile: getImagePath)
			self.imgBackground.image = image
		} else {
			NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "setImage", userInfo: nil, repeats: false)
		}
	}
	
	@IBAction func close(sender: AnyObject) {
		if txtName.text != groupNameLocalized || txtDescription.text != groupDescriptionLocalized || imageChosen == true {
			var saveAlert = UIAlertController(title: NSLocalizedString("are_you_sure_title", value: "Are you sure?", comment: ""), message: NSLocalizedString("are_you_sure_text", value: "You will loose any unsaved information", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
			saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
				// Clicked YES
				self.dismissViewControllerAnimated(true, completion: nil)
			}))
			saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in }))
			presentViewController(saveAlert, animated: true, completion: nil)
		} else {
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
