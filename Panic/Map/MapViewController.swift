//
//  MapViewController.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/05/06.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import Mapbox
import ParseLiveQuery
import Parse

class MapViewController: UIViewController {

    @IBOutlet weak var colHistory: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var lblNoHistory: UILabel!
    
    let test: String = ""
    var map : MGLMapView!
    
    var alerts: [Sub_PFAlert] = []
    
    let queryAlerts : PFQuery = PFQuery(className: "Alerts")
    var subscription_victim_added : Subscription<PFObject>!
    var subscription_victim_updated : Subscription<PFObject>!
    var subscription_victim_removed : Subscription<PFObject>!
    var subscription_victim_entered : Subscription<PFObject>!
    var subscription_victim_left : Subscription<PFObject>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initCollectionView()
        initMap()
        addSubscriptions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadAlerts()
    }
    
    func addSubscriptions() {
        let query = PFQuery(className: "Alerts")
        query.includeKey("user")
        query.whereKeyExists("details")
//        query.whereKey("active", equalTo: true)
        
        subscription_victim_added = Client.shared.subscribe(query).handle(Event.created) { _, alert in self.handleVictimUpdate(alert: alert as! Sub_PFAlert) }
        subscription_victim_updated = Client.shared.subscribe(query).handle(Event.updated) { _, alert in self.handleVictimUpdate(alert: alert as! Sub_PFAlert) }
        subscription_victim_removed = Client.shared.subscribe(query).handle(Event.deleted) { _, alert in self.handleVictimUpdate(alert: alert as! Sub_PFAlert) }
        subscription_victim_entered = Client.shared.subscribe(query).handle(Event.entered) { _, alert in self.handleVictimUpdate(alert: alert as! Sub_PFAlert) }
        subscription_victim_left = Client.shared.subscribe(query).handle(Event.left) { _, alert in self.handleVictimUpdate(alert: alert as! Sub_PFAlert) }
    }
    
    func handleVictimUpdate(alert: Sub_PFAlert) {
        
        func update() {
            DispatchQueue.main.async {
                guard let tabbar = global.mainTabbar as? Main_Tabbar_NC else { return }
                tabbar.updateTabbarAlertCount(alerts: self.alerts)
                
                self.colHistory.reloadData()
            }
        }
        
        if !alert.isActive {
            if let index = alerts.index(of: alert) {
                alerts.remove(at: index)
            }
            update()
        } else {
            let query = Sub_PFAlert.query()!.whereKey("objectId", equalTo: alert.objectId!)
            query.includeKey("user")
            query.getFirstObjectInBackground(block: {
                alertFilled, error in
                
                if alertFilled != nil {
                    if let index = self.alerts.index(of: alertFilled as! Sub_PFAlert) {
                        self.alerts.remove(at: index)
                        self.alerts.insert(alertFilled as! Sub_PFAlert, at: index)
                    } else {
                        self.alerts.append(alertFilled as! Sub_PFAlert)
                    }
                    update()
                }
            })
        }
    }

    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}
