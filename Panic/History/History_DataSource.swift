//
//  History_DataSource.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/03/26.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import Parse

extension HistoryViewController {
    
    func loadAlerts() {
        fetchAll_remote {
            success, alerts in
            
            DispatchQueue.main.async {
                if alerts.count > 0 {
                    self.colHistory.isHidden = false
                    self.colHistory.reloadData()
                    
                    self.perform(#selector(self.scrollViewDidEndScrollingAnimation), with: self, afterDelay: 0.3)
                } else {
                    self.colHistory.isHidden = true
                }
            }
        }
    }
    
    func fetchAll_remote(completionHandler handler: @escaping (Bool, [Sub_PFAlert]) -> Void) {
        let query = PFQuery(className: "Alerts")
        query.order(byAscending: "updatedAt")
        query.includeKey("user")
        query.whereKey("active", equalTo: false)
        query.limit = 20
        query.findObjectsInBackground {
            (alerts, error) in
            
            if error == nil {
                self.alerts = alerts as! [Sub_PFAlert]
                handler(true, alerts as! [Sub_PFAlert])
            } else {
                handler(false, [])
            }
        }
    }
    
    
}
