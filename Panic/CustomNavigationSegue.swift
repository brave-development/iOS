//
//  CustomSegue.swift
//  Panic
//
//  Created by Byron Coetsee on 2014/12/01.
//  Copyright (c) 2014 Byron Coetsee. All rights reserved.
//

import UIKit

class CustomNavigationSegue: UIStoryboardSegue {
    
    override func perform() {
        
        let tabBarController = self.source as! TabBarViewController
        let destinationController = self.destination 
        
        switch (destinationController.title!) {
            
        case "Panic":
            let main = destinationController as! MainViewController
            main.tabbarViewController = tabBarController
            tabBarController.showTabbar()
//			tabBarController.tapRecognizer.enabled = true
            break;
            
        case "Groups":
            tabBarController.hideTabbar()
//			tabBarController.tapRecognizer.enabled = true
            break;
            
        case "Settings":
            let settings = destinationController as! SettingsTableViewController
            settings.tabbarViewController = tabBarController
//			tabBarController.tapRecognizer.enabled = true
            break;
			
		case "Public History":
//			tabBarController.tapRecognizer.enabled = false
			break
			
		case "Local History":
//			tabBarController.tapRecognizer.enabled = false
			break
            
        default:
//			tabBarController.tapRecognizer.enabled = true
            break;
        }
        
        for view in tabBarController.placeholderView.subviews {
            view.removeFromSuperview()
        }
        tabBarController.currentViewController = destinationController
        tabBarController.placeholderView.addSubview(destinationController.view)
        tabBarController.placeholderView.clipsToBounds = true
    }
    
}
