////
////  LocalHistoryViewController.swift
////  Panic
////
////  Created by Byron Coetsee on 2014/12/10.
////  Copyright (c) 2014 Byron Coetsee. All rights reserved.
////
//
import UIKit
//import Parse
//import HMSegmentedControl
//
class LocalHistoryViewController_OLD: UIViewController, UITableViewDelegate, UIGestureRecognizerDelegate {
//
//    @IBOutlet weak var tblHistory: UITableView!
//
//    // Tutorial
//
//    @IBOutlet weak var viewTutorial: UIView!
//    @IBOutlet weak var imageTap: UIView!
//    @IBOutlet weak var spinner: UIActivityIndicatorView!
//    @IBOutlet weak var lblNoHistory: UILabel!
//
//    var records : [String : [AnyObject]]!
//    var segControl : HMSegmentedControl!
//
//    // Tutorial
//
//    @IBOutlet weak var lblTutorialTextTop: UILabel!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        global.getPublicHistory()
//        global.dateFormatter.locale = Locale.current
//
//        let decrementSegIndexRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(decrementSegIndex))
//        decrementSegIndexRecognizer.direction = .right
//        let incrementSegIndexRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(LocalHistoryViewController.incrementSegIndex))
//        incrementSegIndexRecognizer.direction = .left
//        tblHistory.addGestureRecognizer(decrementSegIndexRecognizer)
//        tblHistory.addGestureRecognizer(incrementSegIndexRecognizer)
//
//        let statusBarSpacer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 20))
//        statusBarSpacer.backgroundColor = UIColor(white: 0, alpha: 0.5)
//        self.view.addSubview(statusBarSpacer)
//
//        segControl = HMSegmentedControl(sectionTitles: ["Others", "You"])
//        segControl.frame = CGRect(x: 0, y: 20, width: self.view.frame.width, height: 50)
//        segControl.addTarget(self, action: #selector(changedSegment), for: UIControlEvents.valueChanged)
//        segControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocation.down
//        segControl.selectionIndicatorColor = UIColor(white: 1, alpha: 0.7)
//        segControl.selectionStyle = HMSegmentedControlSelectionStyle.fullWidthStripe
//        segControl.isVerticalDividerEnabled = true
//        segControl.verticalDividerColor = UIColor(white: 1, alpha: 0.3)
//        segControl.verticalDividerWidth = 1
//        segControl.backgroundColor = UIColor(white: 0, alpha: 0.5)
//        segControl.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
//        segControl.setSelectedSegmentIndex(0, animated: true)
//        self.view.addSubview(segControl)
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//
//        reloadTable()
//        if tutorial.localHistory == false {
//            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeTutorial))
//            tapRecognizer.delegate = self
//            viewTutorial.addGestureRecognizer(tapRecognizer)
//            viewTutorial.isHidden = false
//            animateTutorial()
//        }
//
//        if tblHistory.indexPathForSelectedRow != nil {
//            tblHistory.deselectRow(at: tblHistory.indexPathForSelectedRow!, animated: true)
//        }
//    }
//
//    func changedSegment() {
//        UIView.animate(withDuration: 0.3, animations: {
//            self.tblHistory.alpha = 0.0 }, completion: {
//                (finished: Bool) -> Void in
//                self.tblHistory.scrollRectToVisible(CGRect(x: 0, y: 0, width: 0, height: 0), animated: false)
//                self.reloadTable()
//                UIView.animate(withDuration: 0.3, animations: {
//                    self.tblHistory.alpha = 1.0 })
//        })
//    }
//
//    func decrementSegIndex() {
//        if segControl.selectedSegmentIndex > 0 {
//            segControl.setSelectedSegmentIndex(UInt(segControl.selectedSegmentIndex - 1), animated: true)
//            changedSegment()
//        }
//    }
//
//    func incrementSegIndex() {
//        if segControl.selectedSegmentIndex < segControl.sectionTitles.count - 1 {
//            segControl.setSelectedSegmentIndex(UInt(segControl.selectedSegmentIndex + 1), animated: true)
//            changedSegment()
//        }
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if segControl != nil {
//            switch (segControl.selectedSegmentIndex) {
//            case 0:
//                return global.panicHistoryPublic.count
//
//            case 1:
//                return global.panicHistoryLocal.count
//
//            case 2:
//                return 6
//
//            default:
//                return 20
//            }
//        }
//        return 0
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
//        if segControl != nil {
//            switch (segControl.selectedSegmentIndex) {
//            case 0:
//                if indexPath.row < global.panicHistoryPublic.count {
//                    let object = global.panicHistoryPublic[indexPath.row]
//                    let cell = tblHistory.dequeueReusableCell(withIdentifier: "localHistoryCell", for: indexPath) as! LocalHistoryTableViewCell
//                    cell.type = "public"
//                    cell.setup(object)
//                    return cell
//                }
//
//            case 1:
//                if indexPath.row < global.panicHistoryLocal.count {
//                    let object = global.panicHistoryLocal[indexPath.row]
//                    let cell = tblHistory.dequeueReusableCell(withIdentifier: "localHistoryCell", for: indexPath) as! LocalHistoryTableViewCell
//                    cell.type = "local"
//                    cell.setup(object)
//                    return cell
//                }
//
//            case 2:
//                let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Default")
//                cell.backgroundColor = UIColor.clear
//                cell.textLabel?.text = NSLocalizedString("no_data", value: "No Data", comment: "")
//                return cell
//
//            default:
//                let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Default")
//                cell.backgroundColor = UIColor.clear
//                return cell
//            }
//        }
//        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Default")
//        cell.backgroundColor = UIColor.clear
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("Selected cell")
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let vc: HistoryDetailsViewController = storyboard.instantiateViewController(withIdentifier: "historyDetailsViewController")as! HistoryDetailsViewController
//        switch (segControl.selectedSegmentIndex) {
//        case 0:
//            vc.placemarkObject = global.panicHistoryPublic[indexPath.row]
//            break
//
//        case 1:
//            vc.placemarkObject = global.panicHistoryLocal[indexPath.row]
//            break
//
//        default:
//            break
//        }
//        self.present(vc, animated: true, completion: nil)
//    }
//
//    func reloadTable() {
//        var count = 0
//        if segControl != nil {
//            switch (segControl.selectedSegmentIndex) {
//            case 0:
//                lblTutorialTextTop.text = NSLocalizedString("public_panics_20", value: "Last 20 activations by other people.", comment: "")
//                lblNoHistory.isHidden = true
//                if global.publicHistoryFetched == true {
//                    count = global.panicHistoryPublic.count
//                    spinner.stopAnimating()
//                } else {
//                    spinner.startAnimating()
//                }
//
//            case 1:
//                lblTutorialTextTop.text = NSLocalizedString("private_panics_50", value: "Last 50 of your own activations.", comment: "")
//                spinner.stopAnimating()
//                if global.privateHistoryFetched == true {
//                    count = global.panicHistoryLocal.count
//                    if count == 0 {
//                        lblNoHistory.isHidden = false
//                        count = 1
//                    } else {
//                        lblNoHistory.isHidden = true
//                    }
//                }
//
//            default:
//                count = 0
//            }
//        }
//
//        if count == 0 {
//            print("Starting timer")
////            _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(LocalHistoryViewController.reloadTable), userInfo: nil, repeats: false)
//        } else {
//            tblHistory.reloadData()
//        }
//    }
//
//    // Tutorial
//
//    func closeTutorial() {
//        UIView.animate(withDuration: 0.5, animations: {
//            self.viewTutorial.alpha = 0.0 }, completion: {
//                (finished: Bool) -> Void in
//                self.viewTutorial.isHidden = true
//        })
//        tutorial.localHistory = true
//        tutorial.save()
//    }
//
//    func animateTutorial() {
//        self.imageTap.layer.shadowColor = UIColor.white.cgColor
//        self.imageTap.layer.shadowRadius = 5.0
//        self.imageTap.layer.shadowOffset = CGSize.zero
//
//        let animate = CABasicAnimation(keyPath: "shadowOpacity")
//        animate.fromValue = 0.0
//        animate.toValue = 1.0
//        animate.autoreverses = true
//        animate.duration = 1
//
//        self.imageTap.layer.add(animate, forKey: "shadowOpacity")
//
//        if tutorial.localHistory == false {
//            _ = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(LocalHistoryViewController.animateTutorial), userInfo: nil, repeats: false)
//        }
//
//    }
}

