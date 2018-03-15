//
//  ConversationScript_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/03/13.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit

class ConversationScript_VC: UIViewController {

    @IBOutlet weak var tblScript: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblScript.dataSource = self
        addFloatingButton()
    }

    func callEmergency() {
        guard let number = URL(string: "tel://911") else { return }
        UIApplication.shared.open(number)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ConversationScript_VC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.textLabel?.text = "Do something, yo! This is your chance to save a life blah blah blah blah blah dead. Some more stuff to write."
        cell.textLabel?.numberOfLines = 3
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tblScript.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tblScript.cellForRow(at: indexPath)?.accessoryType = .none
    }
}

extension ConversationScript_VC: floatMenuDelegate {
    func addFloatingButton() {
        let buttonRect = CGRect(x: self.view.frame.width - 100, y: self.view.frame.height - 145, width: 65, height: 65)
        let floatingButton = VCFloatingActionButton(frame: buttonRect, normalImage: UIImage(named: "plus"), andPressedImage: UIImage(named: "cross"), withScrollview: tblScript)
        floatingButton?.normalImageView.frame = CGRect(x: (floatingButton?.normalImageView.frame.width)!/2 - 10, y: (floatingButton?.normalImageView.frame.height)!/2 - 10, width: 20, height: 20)
        floatingButton?.pressedImageView.frame = CGRect(x: (floatingButton?.pressedImageView.frame.width)!/2 - 10, y: (floatingButton?.pressedImageView.frame.height)!/2 - 10, width: 20, height: 20)
        floatingButton?.layer.cornerRadius  = 0.5 * ((floatingButton?.frame.width)!)
        floatingButton?.layer.shadowColor = UIColor.black.cgColor
        floatingButton?.layer.shadowOffset = CGSize.zero
        floatingButton?.layer.shadowOpacity = 0.6
        floatingButton?.layer.shadowRadius = 3
        floatingButton?.backgroundColor = UIColor.red
        floatingButton?.delegate = self
        floatingButton?.hideWhileScrolling = true
        
        let optionsImages: [String] = ["create", "RespondersIcon"]
        let optionsTitles = [NSLocalizedString("call_911", value: "Call 911", comment: ""), NSLocalizedString("close_case", value: "Close Case", comment: "")]
        floatingButton?.labelArray = optionsTitles
        floatingButton?.imageArray = optionsImages
        
        self.view.addSubview(floatingButton!)
    }
    
    func didSelectMenuOption(at: Int) {
        switch(at) {
        case 0:
            //Call 911
            callEmergency()
            break
            
        case 3:
            // Showen to admins - close case
            break
            
        default:
            break
        }
    }
}
