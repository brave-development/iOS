//
//  History_AlertDetails.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/03/27.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse
import ChameleonFramework
import SwiftLocation
import MapKit
import ParseLiveQuery
import SCLAlertView

class AlertDetails_XIB: UIViewController {
    
    @IBOutlet weak var lblStatusMessage: UILabel!
    
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var viewBlur: UIVisualEffectView!
    
    @IBOutlet weak var viewSection_0: UIView!
    @IBOutlet weak var viewSection_1: UIView!
    @IBOutlet weak var viewSection_2: UIView!
    @IBOutlet weak var viewSection_3: UIView!
    
    @IBOutlet weak var imgDetails: UIImageView!
    @IBOutlet weak var imgAddress: UIImageView!
    @IBOutlet weak var imgChat: UIImageView!
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    
    @IBOutlet weak var lblDetails: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblChatInfo: UILabel!
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnCall: UIButton!
    @IBOutlet weak var btnNavigate: UIButton!
    @IBOutlet weak var btnChat: UIButton!
    
    var alert: Sub_PFAlert!
    
    var subscription_alertChanges: Subscription<PFObject>!
    
    var formatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupInformation()
        setupLiveQuery()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor.clear
        lblStatusMessage.text = ""
        
        viewSection_0.backgroundColor = UIColor(gradientStyle: .topToBottom, withFrame: viewSection_0.frame, andColors: [UIColor(hex: "#34495e"), UIColor(hex: "#2c3e50")])
        viewSection_1.backgroundColor = UIColor(gradientStyle: .topToBottom, withFrame: viewSection_0.frame, andColors: [UIColor(hex: "34495e"), UIColor(hex: "#2c3e50")])
        viewSection_2.backgroundColor = UIColor(gradientStyle: .topToBottom, withFrame: viewSection_0.frame, andColors: [UIColor(hex: "34495e"), UIColor(hex: "#2c3e50")])
        viewSection_3.backgroundColor = UIColor(gradientStyle: .topToBottom, withFrame: viewSection_0.frame, andColors: [UIColor(hex: "34495e"), UIColor(hex: "#2c3e50")])
        
        imgDetails.tintColor = UIColor.white
        imgAddress.tintColor = UIColor.white
        imgChat.tintColor = UIColor.white
        
        roundView(view: btnClose)
        roundView(view: btnCall)
        roundView(view: btnNavigate)
        roundView(view: btnChat)
        
        addShadow(view: btnClose)
        addShadow(view: btnCall)
        addShadow(view: btnNavigate)
        addShadow(view: btnChat)
        addShadow(view: viewSection_0)
        addShadow(view: viewSection_1)
        addShadow(view: viewSection_2)
        addShadow(view: viewSection_3)
        
        viewContainer.layer.cornerRadius = 8
        viewContainer.clipsToBounds = true
    }
    
    func setupInformation() {
        lblName.text = alert.user["name"] as! String
        
        formatter.dateFormat = "d MMMM yyy"
        lblDate.text = formatter.string(from: alert.createdAt!)
        formatter.dateFormat = "h:mm a"
        lblTime.text = formatter.string(from: alert.createdAt!)
        
        lblDetails.text = "Drug being used: \(alert.details ?? "unknown")"
        
        setAddress()
        
        lblChatInfo.text = "\(alert.responders.count) responders"
        lblStatusMessage.text = alert.isResponding() ? "You are a responder to this alert" : ""
        
        if !alert.isActive { closeAlert() }
    }
    
    func closeAlert() {
        lblStatusMessage.text = "This alert is no longer active"
        btnCall.isHidden = true
    }
    
    func setAddress() {
        Locator.location(fromCoordinates: CLLocationCoordinate2D(latitude: alert.location.latitude, longitude: alert.location.longitude), onSuccess: {
            place in
            print(place)
            
            self.lblAddress.text = "\(place[0].name ?? "")\n\(place[0].city ?? "")\n\(place[0].country ?? "")"
        }, onFail: {
            error in
            print(error.localizedDescription)
            self.lblAddress.text = "Couldn't find address"
        })
    }
    
    func setupLiveQuery() {
        let query = Sub_PFAlert.query()!
        query.whereKey("objectId", equalTo: alert.objectId!)
        subscription_alertChanges = Client.shared.subscribe(query).handle(Event.updated) {
            _, alert in
            
            (alert as! Sub_PFAlert).user.fetchIfNeededInBackground(block: {
                user, error in
                
                self.alert = (alert as! Sub_PFAlert)
                self.setupUI()
                self.setupInformation()
            })
        }
    }
    
    @IBAction func call(_ sender: Any) {
        shouldBecomeResponder {
            
            if $0 {
                guard let alerterNumber = (self.alert["user"] as! PFObject)["cellNumber"] as? String else {
                    SCLAlertView().showInfo("Hmm", subTitle: "The alerters number doesn't seem to be valid... Try message them in the chat.")
                    return
                }
                guard let number = URL(string: "tel://\(alerterNumber)") else { return }
                UIApplication.shared.open(number)
            }
        }
    }
    
    @IBAction func navigate(_ sender: Any) {
        let coordinate = CLLocationCoordinate2D(latitude: alert.location.latitude, longitude: alert.location.longitude)
        let url = URL(string: "http://maps.apple.com/maps?saddr=&daddr=\(coordinate.latitude),\(coordinate.longitude)")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func openChat(_ sender: Any) {
        shouldBecomeResponder {
            
            if $0 {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "alertStage_2_VC") as! AlertStage_2_VC
                vc.modalTransitionStyle = .crossDissolve
                vc.modalPresentationStyle = .overCurrentContext
                vc.alert = self.alert
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func shouldBecomeResponder(_ becomeResponder: @escaping (Bool)->Void) {
        
        if self.alert.isResponding() {
            becomeResponder(true)
            return
        }
        
        let appearance = SCLAlertView.SCLAppearance( showCloseButton: false )
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Become Responder") {
            becomeResponder(true)
            self.alert.addResponder()
        }
        
        alert.addButton("Cancel") { becomeResponder(false) }
        alert.showWarning("Become a responder", subTitle: "In order to continue, you will need to become a responder for this event.")
    }
    
    @IBAction func close(_ sender: Any) { self.dismiss(animated: true, completion: nil) }
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}



// =====================
/// UI Helper Functions
// =====================



extension AlertDetails_XIB {
    func roundView(view: Any) {
        (view as! UIView).layer.cornerRadius = (view as! UIView).frame.width/2
    }
    
    func addShadow(view: Any) {
        (view as! UIView).layer.shadowOffset = .zero
        (view as! UIView).layer.shadowRadius = 3
        (view as! UIView).layer.shadowOpacity = 0.4
    }
}
