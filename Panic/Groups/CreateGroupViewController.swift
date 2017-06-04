//
//  CreateGroupViewController.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/08/31.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import SDWebImage

class CreateGroupViewController: UIViewController, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate {
	
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
		
		NotificationCenter.default.addObserver(self, selector: #selector(CreateGroupViewController.keyboardUp(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDown), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
		
		imagePicker.delegate = self
		txtName.delegate = self
		txtDescription.delegate = self
		
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		imgBackground.addGestureRecognizer(tapGesture)
		blurView.addGestureRecognizer(tapGesture)
		
		self.view.backgroundColor = UIColor.clear
		viewContent.layer.cornerRadius = 5
		viewContent.layer.shadowRadius = 4
		viewContent.layer.shadowColor = UIColor.black.cgColor
		viewContent.layer.shadowOffset = CGSize.zero
		viewContent.layer.shadowOpacity = 0.4
		viewContent.layer.borderColor = UIColor.white.cgColor
		viewContent.layer.borderWidth = 1.0
		
		imgBackground.layer.cornerRadius = 5
		imgBackground.clipsToBounds = true
		imgBackground.layer.shadowOffset = CGSize.zero
		imgBackground.layer.shadowRadius = 4
		imgBackground.layer.shadowOpacity = 0.4
//		imgBackground.contentMode = .ScaleAspectFill
		
		btnLeave.layer.cornerRadius = 5
		btnLeave.layer.borderColor = UIColor.white.cgColor
		btnLeave.layer.borderWidth = 1
		btnLeave.clipsToBounds = true
		btnLeave.isEnabled = false
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
		imgBackground.contentMode = .scaleAspectFill
		txtName.text = group!["name"] as! String
		txtName.isHidden = true
		lblName.text = txtName.text
		
		if group!["description"] != nil {
			txtDescription.text = group!["description"] as? String
		} else {
			txtDescription.text = group!["country"] as? String
		}
		lblDescription.text = txtDescription.text
		
		if (group!["public"] as? Bool) == false {
			btnLock.setImage(UIImage(named: "lock"), for: UIControlState())
			publicGroup = false
		}
		
		setImage()
		btnFinish.setTitle(NSLocalizedString("save", value: "Save", comment: ""), for: UIControlState())
	}
	
	@IBAction func choseBackground(_ sender: AnyObject) {
		tooltipPicture.hide()
		imagePicker.allowsEditing = true
		imagePicker.sourceType = .photoLibrary
		
		present(imagePicker, animated: true, completion: nil)
	}
	
	@IBAction func privatePublic(_ sender: AnyObject) {
		publicGroup = !publicGroup
		
		if publicGroup == true {
			btnLock.setImage(UIImage(named: "unlock"), for: UIControlState())
			tooltipLock.setText(NSLocalizedString("open_comm", value: "Open community", comment: ""))
		} else {
			btnLock.setImage(UIImage(named: "lock"), for: UIControlState())
			tooltipLock.setText(NSLocalizedString("closed_group", value: "Closed group", comment: ""))
		}
	}
	
	@IBAction func finish(_ sender: AnyObject) {
		if validate() == true {
			if group != nil {
				editGroup()
			} else {
				newGroup()
			}
//			NotificationCenter.default.post(name: Notification.Name(rawValue: "gotNearbyGroups"), object: nil)
		}
	}
	
	func newGroup() {
		var message: String = NSLocalizedString("group_set_to_private_text", value: "This group is set to private. It will therfore NOT SHOW in any searches or nearby suggestions.", comment: "")  // If set to PRIVATE
		if self.publicGroup == true { message = NSLocalizedString("group_set_to_public_text", value: "This group is set to public. It will therfor SHOW in all searches and nearby suggestions and anyone will be able to join it", comment: "")}
		let saveAlert = UIAlertController(title: NSLocalizedString("are_you_sure", value: "Are you sure?", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
		saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
			// Clicked YES
            self.prepareForUpload()
            
            let newGroup = self.createGroupObject()
			if groupsHandler.checkIfGroupExists(newGroup) == false {
				groupsHandler.createGroup(newGroup, parent: self)
			} else {
                self.uploadFinished()
			}
		}))
		saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
			self.tooltipLock.show()
		}))
		present(saveAlert, animated: true, completion: nil)
	}
	
	func editGroup() {
        prepareForUpload()
        
        let edittedGroup = createGroupObject()
		edittedGroup.saveInBackground(block: {
			(result, error) in
			if error != nil {
				global.showAlert("", message: NSLocalizedString("error_update_failed", value: "Something went wrong during the update. Please try again.", comment: ""))
			} else {
				global.showAlert("", message: NSLocalizedString("update_successful", value: "Updated successfully", comment: ""))
                self.uploadFinished()
			}
		})
	}
    
    func prepareForUpload() {
        self.spinner.startAnimating()
        self.btnClose.isEnabled = false
        self.btnFinish.isEnabled = false
        self.txtName.isUserInteractionEnabled = false
        self.txtDescription.isUserInteractionEnabled = false
        self.btnEditBackground.isEnabled = false
        self.btnLock.isEnabled = false
    }
    
    func uploadFinished() {
        self.spinner.stopAnimating()
        self.btnClose.isEnabled = true
        self.btnFinish.isEnabled = true
        self.txtName.isUserInteractionEnabled = true
        self.txtDescription.isUserInteractionEnabled = true
        self.btnEditBackground.isEnabled = true
        self.btnLock.isEnabled = true
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotNearbyGroups"), object: nil)
        dismiss(animated: true, completion: nil)
    }
    
    func createGroupObject() -> PFObject {
        let image: PFFile = PFFile(data: UIImageJPEGRepresentation(self.imgBackground.image!, 0.4)! , contentType: "image")
        group!["name"] = self.txtName.text.trim().lowercased().capitalized
        group!["description"] = self.txtDescription.text.trim()
        group!["flatValue"] = self.txtName.text.trim().formatGroupForFlatValue()
        group!["country"] = PFUser.current()!.object(forKey: "country")
        group!["admin"] = PFUser.current()
        if self.publicGroup == true {
            group!["public"] = true
        } else {
            group!["public"] = false
        }
        group!["imageFile"] = image
        
        return group!
    }
	
	//
	let groupNameLocalized = NSLocalizedString("group_name", value: "Group Name", comment: "")
	let groupDescriptionLocalized = NSLocalizedString("group_description", value: "Group Description", comment: "")
	//
	
	func validate() -> Bool {
		var message: String = ""
		if txtName.text.trim().characters.count < 3 || txtName.text == groupNameLocalized { message = message + NSLocalizedString("error_name_3_chars", value: "Name must be 3 or more characters", comment: "") + "\n" }
		if txtDescription.text.trim().characters.count < 10 || txtDescription.text == groupDescriptionLocalized { message = message + NSLocalizedString("error_description_10_chars", value: "Description must be 10 or more characters", comment: "") + "\n" }
		if imageChosen == false { message = message + NSLocalizedString("error_choose_image", value: "Please choose an image", comment: "") + "\n"; tooltipPicture.show() }
		
		if message.trim().characters.count > 0 {
			global.showAlert("", message: message)
			return false
		}
		return true
	}
	
	func dismissKeyboard() {
		self.view.endEditing(true)
	}
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		switch (textView.tag) {
		case 0: if txtName.text == groupNameLocalized { txtName.text = "" }
        case 1: if txtDescription.text == groupDescriptionLocalized { txtDescription.text = "" }
        default: break
		}
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		switch (textView.tag) {
		case 0: if txtName.text == "" { txtName.text = groupNameLocalized }
        case 1: if txtDescription.text == "" { txtDescription.text = groupDescriptionLocalized }
        default: break
		}
	}
	
	func textViewDidChange(_ textView: UITextView) {
		switch (textView.tag) {
		case 0: lblName.text = txtName.text
        case 1: lblDescription.text = txtDescription.text
        default: break
		}
	}
	
	func keyboardUp(_ notification: Notification) {
		let info  = notification.userInfo!
		let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]! as AnyObject
		
		let rawFrame = value.cgRectValue
		let keyboardFrame = view.convert(rawFrame!, from: nil)
		layoutTxtDescriptionBottom.constant = keyboardFrame.height + 20
		UIView.animate(withDuration: 0.3, animations: {
			self.layoutSubview()
		})
	}
	
	func keyboardDown() {
		layoutTxtDescriptionBottom.constant = 0
		UIView.animate(withDuration: 0.3, animations: {
			self.layoutSubview()
		})
	}
	
	func layoutSubview() {
		for view in self.view.subviews {
			view.layoutIfNeeded()
		}
	}
	
	func setImage() {
		self.imgBackground.backgroundColor = UIColor.white
		self.imgBackground.image = nil
		imageChosen = true
		
		let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
		let groupName = self.group!["flatValue"] as! String
		let getImagePath = URL(string: documentsPath)?.appendingPathComponent("\(groupName).jpg", isDirectory: true)
		
		let checkValidation = FileManager.default
		if (checkValidation.fileExists(atPath: getImagePath!.absoluteString)) {
			let image = UIImage(contentsOfFile: getImagePath!.absoluteString)
			self.imgBackground.image = image
		} else {
            if let imageUrl = (self.group!["imageFile"] as! PFFile).url {
                self.imgBackground.sd_setIndicatorStyle(.white)
                self.imgBackground.sd_showActivityIndicatorView()
                self.imgBackground.sd_setImage(with: URL(string: imageUrl))
            }
		}
	}
	
	@IBAction func close(_ sender: AnyObject) {
		if txtName.text != groupNameLocalized || txtDescription.text != groupDescriptionLocalized || imageChosen == true {
			let saveAlert = UIAlertController(title: NSLocalizedString("are_you_sure_title", value: "Are you sure?", comment: ""), message: NSLocalizedString("are_you_sure_text", value: "You will loose any unsaved information", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            
            // YES
			saveAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
				self.dismiss(animated: true, completion: nil)
			}))
            
            // NO
			saveAlert.addAction(UIAlertAction(title: NSLocalizedString("no", value: "No", comment: ""), style: .default, handler: { (action: UIAlertAction!) in }))
            
            // PRESENT
			present(saveAlert, animated: true, completion: nil)
		} else {
			self.dismiss(animated: true, completion: nil)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


// ==============
// Image Picker
// ==============



extension CreateGroupViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            imgBackground.image = pickedImage
            imgBackground.alpha = 1
            imgBackground.contentMode = .scaleAspectFill
            viewContent.layer.borderWidth = 0.0
            btnLeave.backgroundColor = UIColor(white: 0, alpha: 0.3)
            imageChosen = true
            
            let gradient = drawing.gradient(viewContent, colours: [UIColor.clear.cgColor, UIColor.black.cgColor], locations: [0.0 , 1.0], opacity: 0.5)
            viewContent.layer.insertSublayer(gradient, at: 1)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
