//
//  Reg_Done_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/07/21.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import ChameleonFramework
import Parse

class Reg_Done_VC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear
    }
    
    @IBAction func next(_ sender: Any) {
        if let parent = self.parent as? RegistrationController_VC {
            checkForCompletion()
        }
    }
    
    @IBAction func back(_ sender: Any) {
        if let parent = self.parent as? RegistrationController_VC {
            parent.previousPage()
        }
    }
    
    func checkForCompletion() -> Bool {
        if let controller = self.parent as? RegistrationController_VC {
            if controller.currentUser["email"] == nil {
                controller.performManualScrolling(toIndex: controller.getIndexOfViewControllerType(VCType: Reg_Email_VC.classForCoder()))
                return false
            }
            return true
        } else {
            return false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
