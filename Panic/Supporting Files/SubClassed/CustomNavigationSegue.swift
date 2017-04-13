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
        
        let mainViewController = self.source as! MainViewController
        let destinationController = self.destination 
        
        switch (destinationController.title!) {
            
        case "Panic":
            let main = destinationController as! PanicButtonViewController
            main.mainViewController = mainViewController
            mainViewController.showTabbar()
//			mainViewController.tapRecognizer.enabled = true
            break;
            
        case "Groups":
            mainViewController.hideTabbar()
//			mainViewController.tapRecognizer.enabled = true
            break;
            
        case "Settings":
            let settings = destinationController as! SettingsTableViewController
            settings.mainViewController = mainViewController
//			mainViewController.tapRecognizer.enabled = true
            break;
			
		case "Public History":
//			mainViewController.tapRecognizer.enabled = false
			break
			
		case "Local History":
//			mainViewController.tapRecognizer.enabled = false
			break
            
        default:
//			mainViewController.tapRecognizer.enabled = true
            break;
        }
        
        for view in mainViewController.placeholderView.subviews {
            view.removeFromSuperview()
        }
        mainViewController.currentViewController = destinationController
        mainViewController.placeholderView.addSubview(destinationController.view)
        mainViewController.placeholderView.clipsToBounds = true
    }
    
}
