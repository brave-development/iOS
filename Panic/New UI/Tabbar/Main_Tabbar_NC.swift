//
//  Main_Tabbar_NC.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/01/29.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import ESTabBarController_swift
import ChameleonFramework

class Main_Tabbar_NC: ESTabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.backgroundColor = .red
        tabBar.isTranslucent = false
        tabBar.barTintColor = UIColor.flatBlack
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let v1 = storyboard.instantiateViewController(withIdentifier: "mapViewController") as! MapViewController
        let v2 = storyboard.instantiateViewController(withIdentifier: "localHistoryViewController") as! LocalHistoryViewController
        let v3 = storyboard.instantiateViewController(withIdentifier: "panicViewController") as! PanicButtonViewController
        let v4 = storyboard.instantiateViewController(withIdentifier: "conversationScript_vc") as! ConversationScript_VC
        let v5 = storyboard.instantiateViewController(withIdentifier: "settingsViewController") as! SettingsTableViewController
        
        v1.tabBarItem = ESTabBarItem.init(StandardESTabbarButton(), title: nil, image: UIImage(named: "map_unselected"), selectedImage: UIImage(named: "map_selected"))
        v2.tabBarItem = ESTabBarItem.init(StandardESTabbarButton(), title: "???", image: UIImage(named: "find"), selectedImage: UIImage(named: "find_1"))
        v3.tabBarItem = ESTabBarItem.init(LargeESTabbarButton(), title: nil, image: UIImage(named: "alert"), selectedImage: UIImage(named: "alert"))
        v4.tabBarItem = ESTabBarItem.init(StandardESTabbarButton(), title: nil, image: UIImage(named: "conversationScript_unselected"), selectedImage: UIImage(named: "conversationScript_selected"))
        v5.tabBarItem = ESTabBarItem.init(StandardESTabbarButton(), title: nil, image: UIImage(named: "profile_unselected"), selectedImage: UIImage(named: "profile_selected"))
        
        viewControllers = [v1, v2, v3, v4, v5]
        
        global.mainTabbar = self
    }
    
    func updateTabbarAlertCount(alerts: [Sub_PFAlert]) {
        viewControllers![0].tabBarItem.badgeValue = alerts.count == 0 ? nil : "\(alerts.count)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
