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
    @IBOutlet weak var btnCallEmergency: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblScript.dataSource = self
        
        btnCallEmergency.layer.shadowRadius = 4
        btnCallEmergency.layer.shadowOpacity = 1
        btnCallEmergency.layer.shadowOffset = .zero
    }

    @IBAction func callEmergency(_ sender: Any) {
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
