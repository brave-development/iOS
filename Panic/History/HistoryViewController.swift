//
//  LocalHistoryViewController.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/03/15.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import Mapbox

class HistoryViewController: UIViewController {
    
    @IBOutlet weak var colHistory: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var lblNoHistory: UILabel!
    
    let test: String = ""
    var map : MGLMapView!
    
    var alerts: [Sub_PFAlert] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initCollectionView()
        initMap()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadAlerts()
    }

    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}
