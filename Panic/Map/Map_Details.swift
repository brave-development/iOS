//
//  Map_Details.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/02/20.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import CoreLocation
import Parse

extension MapViewController {
    
    func showDetailsView() {
        self.viewDetails.isHidden = false
        populateDetails()
        UIView.animate(withDuration: 0.5, animations: {
            self.viewDetails.alpha = 1.0
        })
    }
    
    func populateDetails() {
        let objectId = selectedVictim!.objectId!
        let panicDetails = victimDetails[objectId]! as PFObject
        
        let victimInfo = (victimDetails[objectId]! as PFObject)["user"] as! PFUser
        lblName.text = victimInfo["name"] as? String
        lblContact.text = victimInfo["cellNumber"] as? String
        
        detailsTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(getDetails), userInfo: nil, repeats: true)
        getDetails()
        
        if panicDetails["responders"] != nil {
            let numberOfResponders = (panicDetails["responders"] as! [PFUser]).count
            lblResponders.text = "\(numberOfResponders)"
        } else {
            lblResponders.text = "0"
        }
        
        lblTime.text = dateFormatter.string(from: panicDetails.createdAt!)
        getAddress()
        
        if isResponding() {
            btnRespond.setTitle(NSLocalizedString("stop_responding", value: "Stop Responding", comment: ""), for: UIControlState())
            btnRespond.backgroundColor = UIColor(red:0.91, green:0.3, blue:0.24, alpha:1)
            alertHandler.currentAlert = Sub_PFAlert(parseObject: selectedVictim!)
            btnChat.isEnabled = true
        } else {
            btnRespond.setTitle(NSLocalizedString("respond", value: "Respond", comment: ""), for: UIControlState())
            btnRespond.backgroundColor = UIColor(red:0.18, green:0.8, blue:0.44, alpha:1)
            btnChat.isEnabled = false
        }
    }
    
    func getDetails() {
        if let panicDetails = victimDetails[selectedVictim!.objectId!] {
            if panicDetails["details"] != nil {
                lblDetails.text = panicDetails["details"] as? String
            } else {
                lblDetails.text = "No details"
            }
        } else {
            detailsTimer.invalidate()
            closeDetails(btnCloseDetails)
            selectedVictim = nil
        }
    }
    
    func isResponding() -> Bool {
        let responders = selectedVictim!["responders"] as! [String]
        let currentUserObjectId = PFUser.current()!.objectId
        if responders.index(of: currentUserObjectId!) != nil {
            return true
        }
        return false
    }
    
    // Getting address
    func getAddress() {
        let geocode = CLGeocoder()
        let location = CLLocation(latitude: (selectedVictim?["location"] as! PFGeoPoint).latitude , longitude: (selectedVictim?["location"] as! PFGeoPoint).longitude)
        geocode.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            if error != nil {
                print("Error in reverse geocode... \(error!)")
            }
            
            if placemarks != nil {
                if placemarks!.count > 0 {
                    let pm = placemarks![0]
                    var address: [String] = []
                    if pm.thoroughfare != nil { address.append(pm.thoroughfare! as String) }
                    if pm.subLocality != nil { address.append(pm.subLocality! as String) }
                    if pm.subAdministrativeArea != nil { address.append(pm.subAdministrativeArea! as String) }
                    if pm.country != nil { address.append(pm.country! as String) }
                    
                    for element in address {
                        self.lblAddress.text = "\(self.lblAddress.text!)\n\(element)"
                    }
                }
            } else {
                print("Error in reverse geocode... placemarks = nil")
            }
        })
    }
    
    @IBAction func chat(_ sender: AnyObject) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "alertStage_2_VC") as! AlertStage_2_VC
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func respond(_ sender: AnyObject) {
        if isResponding() == true {
            
//            selectedVictim!.removeObjects(in: [PFUser.current()!.objectId!], forKey: "responders")
            selectedVictim!.remove(PFUser.current()!.objectId!, forKey: "responders")
            btnRespond.setTitle(NSLocalizedString("respond", value: "Respond", comment: ""), for: UIControlState())
            btnRespond.backgroundColor = UIColor(red:0.18, green:0.8, blue:0.44, alpha:1)
            panicHandler.respondingAlertObjectId = nil
            panicHandler.respondingAlertObject = nil
            
            alertHandler.currentAlert!.removeResponder()
            alertHandler.currentAlert = nil
            btnChat.isEnabled = false
        } else {
            selectedVictim!.addUniqueObject(PFUser.current()!.objectId!, forKey: "responders")
            btnRespond.setTitle(NSLocalizedString("stop_responding", value: "Stop Responding", comment: ""), for: UIControlState())
            btnRespond.backgroundColor = UIColor(red:0.91, green:0.3, blue:0.24, alpha:1)
            panicHandler.respondingAlertObjectId = selectedVictim!.objectId
            panicHandler.respondingAlertObject = selectedVictim
            
            alertHandler.currentAlert = Sub_PFAlert(parseObject: selectedVictim!)
            alertHandler.currentAlert!.addResponder()
            btnChat.isEnabled = true
        }
        
        selectedVictim!.saveInBackground(block: {
            result, error in
            if result {
                print("Saved Responder status to Victim object")
            } else if error != nil {
                global.showAlert("", message: String(format: NSLocalizedString("error_becoming_a_responder", value: "%@\nWill try again in a few seconds.", comment: ""), arguments: [error!.localizedDescription]))
            }
        })
        
        // Add current user object to array... Use same way as adding channels to installation. "AddUnique" or something
    }

    @IBAction func closeDetails(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.5, animations: {
            self.viewDetails.alpha = 0.0
        }, completion: {
            (result: Bool) -> Void in
            self.viewDetails.isHidden = true
            self.detailsTimer.invalidate()
        })
    }
}
