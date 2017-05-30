//
//  GroupsTableViewCell.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/06/10.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import MessageUI

class GroupsTableViewCell: UITableViewCell, MFMailComposeViewControllerDelegate {
	
	var alreadyJoined = true
	var object: PFObject?
	var subsCount: Int = 0
	fileprivate var gradient: CAGradientLayer?
	var parentVC: GroupsViewController!
	let OffsetSpeed: CGFloat = 35.0
	var imgBackground: UIImageView!

	
	@IBOutlet weak var btnMore: UIButton!
	@IBOutlet weak var imgLock: UIImageView!
	@IBOutlet weak var lblName: UILabel!
	@IBOutlet weak var lblCountry: UILabel!
	@IBOutlet weak var lblSubs: UILabel!
	@IBOutlet weak var btnLeave: UIButton!
	
    override func awakeFromNib() {
        super.awakeFromNib()
		self.clipsToBounds = true
    }
	
	func setup() {
		NotificationCenter.default.addObserver(self, selector: #selector(purchaseStarted), name: NSNotification.Name(rawValue: "purchaseStarted"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(purchaseEnded), name: NSNotification.Name(rawValue: "purchaseEnded"), object: nil)
		let yOffset = ((parentVC.tblGroups.contentOffset.y - self.frame.origin.y) / 320) * OffsetSpeed
		if imgBackground != nil {
			imgBackground.frame = CGRect(x: 0, y: yOffset, width: self.frame.width, height: 320)
		} else {
			imgBackground = UIImageView(frame: CGRect(x: 0, y: yOffset, width: self.frame.width, height: 320))
			self.insertSubview(imgBackground, at: 0)
		}
		imgBackground.contentMode = UIViewContentMode.scaleAspectFill 
		setImage()
		
		let groupName = object!["name"] as! String
		
		lblName.text = groupName
		
		if object!["subscriberObjects"] != nil {
			subsCount = (object!["subscriberObjects"] as? [String])!.count
		}
		
		if object?["description"] != nil {
			lblCountry.text = object?["description"] as? String
		} else {
			lblCountry.text = object?["country"] as? String
		}
		
		if (object!["public"] as? Bool) == true {
			imgLock.isHidden = true
//			if subsCount > 2 { subsCount = subsCount + Int(floor(subsCount*0.3)) }
		} else {
			imgLock.isHidden = false
		}
		
		lblSubs.text = "\(subsCount)"
		
		imgBackground.clipsToBounds = true
		
		btnMore = drawing.buttonBorderCircle(btnMore, borderWidth: 1, borderColour: UIColor.white.cgColor)
		btnMore.backgroundColor = UIColor(white: 0, alpha: 0.3)
		
		if groupsHandler.purchaseRunning == true { purchaseStarted() }
		btnLeave.layer.cornerRadius = 5
		btnLeave.layer.borderColor = UIColor.white.cgColor
		btnLeave.layer.borderWidth = 1
		btnLeave.clipsToBounds = true
		btnLeave.backgroundColor = UIColor(white: 0, alpha: 0.3)
		
		if groupsHandler.joinedGroups.index(of: groupName) == nil {
			btnLeave.setTitle("JOIN", for: UIControlState())
			alreadyJoined = false
		} else {
			btnLeave.setTitle("LEAVE", for: UIControlState())
			alreadyJoined = true
		}
		
		if gradient == nil {
			gradient = drawing.gradient(contentView, colours: [UIColor.clear.cgColor, UIColor.black.cgColor], locations: [0.0 , 1.0], opacity: 0.5)
			contentView.layer.insertSublayer(gradient!, at: 1)
		}
		
		let lockTapGesture = UITapGestureRecognizer(target: self, action: #selector(shareCode))
		imgLock.addGestureRecognizer(lockTapGesture)
		imgLock.isUserInteractionEnabled = true
	}
	
	@IBAction func more(_ sender: AnyObject) {
		let options = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
		
		// EDIT
		if (object!["admin"] as? PFUser)?.objectId == PFUser.current()?.objectId || (object!["admin"] as? PFUser)?.objectId! ==  "3ryzx2MVKU" {
			let editAction = UIAlertAction(title: "Edit", style: .default) { (_) in
				let vc = self.parentVC.storyboard?.instantiateViewController(withIdentifier: "createNewGroupViewController") as! CreateGroupViewController
				//			vc.fillData(self.object!)
				vc.group = self.object!
				vc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
				self.parentVC.present(vc, animated: true, completion: nil)
			}
			options.addAction(editAction)
		}
		
		// REPORT
		let reportAction = UIAlertAction(title: "Report", style: .default) { (_) in
			let mail = MFMailComposeViewController()
			if(MFMailComposeViewController.canSendMail()) {
				
				mail.mailComposeDelegate = self
				mail.setSubject("Panic - Report Group")
				mail.setToRecipients(["byron@panic-sec.org"])
				mail.setBccRecipients(["byroncoetsee@gmail.com", "bevpaly@gmail.com", "lawrencesuss@gmail.com"])
				self.parentVC.present(mail, animated: true, completion: nil)
			}
			else {
				global.showAlert(NSLocalizedString("unsuccessful", value: "Unsuccessful", comment: "tester"), message: "Your device could not send e-mail.  Please check e-mail configuration and try again.")
			}
		}
		
		// LEAVE / JOIN
		let leaveJoinAction = UIAlertAction(title: btnLeave.titleLabel!.text!.capitalized, style: .default) { (_) in
			self.btnLeave.sendActions(for: UIControlEvents.touchUpInside)
		}
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
		
		// SHARE - if private
		if object!["public"] as! Bool == false {
			let reportAction = UIAlertAction(title: "Share Code", style: .default) { (_) in
				self.shareCode()
			}
			options.addAction(reportAction)
		}
		
		options.addAction(reportAction)
		options.addAction(leaveJoinAction)
		options.addAction(cancelAction)
		
		options.popoverPresentationController?.sourceView = self.btnMore
		options.popoverPresentationController?.sourceRect = self.btnMore.frame
		self.parentVC.present(options, animated: true, completion: nil)
	}
	
	@IBAction func joinLeave(_ sender: AnyObject) {
		let groupName = self.object!["name"] as! String
		if alreadyJoined == true {
			let deleteAlert = UIAlertController(title: String(format: NSLocalizedString("leave_group_confirmation_title", value: "Leave %@?", comment: "tester2"), groupName), message: "Are you sure you want to leave this group?", preferredStyle: UIAlertControllerStyle.alert)
			deleteAlert.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: { (action: UIAlertAction!) in
				groupsHandler.removeGroup(groupName)
				self.parentVC.populateDataSource()
				if groupsHandler.joinedGroupsObject.count == 0 {
					self.parentVC.tblGroups.reloadData()
				} else {
					let indexPath = self.parentVC.tblGroups.indexPath(for: self)
					self.parentVC.tblGroups.deleteRows(at: [indexPath!], with: .automatic)
				}
			}))
			deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in }))
			self.parentVC.present(deleteAlert, animated: true, completion: nil)
		} else {
			if groupsHandler.joinedGroups.count >= PFUser.current()!["numberOfGroups"] as! Int {
				NotificationCenter.default.addObserver(self, selector: #selector(purchaseSuccessful), name: NSNotification.Name(rawValue: "purchaseSuccessful"), object: nil)
				NotificationCenter.default.addObserver(self, selector: #selector(purchaseFail), name: NSNotification.Name(rawValue: "purchaseFail"), object: nil)
				groupsHandler.handlePurchase(parentVC)
			} else {
				purchaseSuccessful()
			}
		}
	}
	
	func shareCode() {
		global.showAlert(self.object!.objectId!, message: NSLocalizedString("share_code_text", value: "Share this code with others wanting to join this group", comment: ""))
	}
	
	func purchaseSuccessful() {
		NotificationCenter.default.post(name: Notification.Name(rawValue: "didJoinGroup"), object: nil)
		groupsHandler.addGroup(lblName.text!)
		groupsHandler.getNearbyGroups(parentVC.manager.location!, refresh: true)
		parentVC.populateDataSource()
		parentVC.checkForGroupDetails()
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "purchaseSuccess"), object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "purchaseFail"), object: nil)
	}
	
	func purchaseFail() {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "purchaseSuccess"), object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "purchaseFail"), object: nil)
	}
	
	func purchaseStarted() {
		btnLeave.alpha = 0.3
		btnLeave.isEnabled = false
	}
	
	func purchaseEnded() {
		btnLeave.alpha = 1
		btnLeave.isEnabled = true
	}
	
	func getImage() {
		let getImageDispatch: DispatchQueue = DispatchQueue(label: "getImageDispatch", attributes: [])
		getImageDispatch.async(execute: {
			if let image: PFFile = self.object!["imageFile"] as? PFFile {
				image.getDataInBackground {
					(imageData, error) in
					if error == nil { self.finishedDownload(UIImage(data:imageData!)!) }
				}
			} else if let imageUrl: String = self.object!["image"] as? String {
				let url = URL(string: imageUrl)
				if let imageData = try? Data(contentsOf: url!){
					self.finishedDownload(UIImage(data:imageData)!)
				}
			} else {
				DispatchQueue.main.async(execute: {
					self.imgBackground.backgroundColor = UIColor(white: 1, alpha: 0.7)
					self.imgBackground.image = UIImage(named: "noImage")
					self.imgBackground.contentMode = UIViewContentMode.center
				})
			}
		})
	}
	
	func finishedDownload(_ image: UIImage) {
		let groupName = self.object!["flatValue"] as! String
		let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
		
		imgBackground.image = image
		let destinationPath = URL(string: documentsPath)?.appendingPathComponent("\(groupName).jpg", isDirectory: true)
		try? UIImageJPEGRepresentation(image,1.0)!.write(to: URL(fileURLWithPath: destinationPath!.absoluteString), options: [.atomic])
	}
	
	func setImage() {
		self.imgBackground.backgroundColor = UIColor.white
		self.imgBackground.image = nil
		
		let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
		let groupName = self.object!["flatValue"] as! String
		let getImagePath = URL(string: documentsPath)?.appendingPathComponent("\(groupName).jpg", isDirectory: true)
		
		let checkValidation = FileManager.default
		if (checkValidation.fileExists(atPath: getImagePath!.absoluteString)) {
			let image = UIImage(contentsOfFile: getImagePath!.absoluteString)
			self.imgBackground.image = image
			do {
				let fileAttrs = try FileManager.default.attributesOfItem(atPath: getImagePath!.absoluteString)
				let modDate = fileAttrs[FileAttributeKey.modificationDate] as! Date
				if Date().timeIntervalSince(modDate) > 86400 {
					print("Fetching new image for \(groupName)")
					getImage()
				}
			} catch { }
		} else {
			getImage()
		}
	}
	
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		switch(result){
		case MFMailComposeResult.sent:
			print("Email sent")
			
		default:
			print("Whoops")
		}
		parentVC.dismiss(animated: true, completion: nil)
	}
	
	func offset(_ tableViewContentOffsetY: CGFloat) {
		let yOffset = ((tableViewContentOffsetY - self.frame.origin.y) / self.imgBackground.frame.height) * OffsetSpeed
		imgBackground.frame = self.imgBackground.bounds.offsetBy(dx: 0, dy: yOffset)
	}

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
