//
//  RegistrationController_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/07/21.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import UIScrollSlidingPages
import Parse

class RegistrationController_VC: TTScrollSlidingPagesController, TTSlidingPagesDataSource, TTSliddingPageDelegate {
    
    @IBOutlet weak var btnBack: UIButton!
    
    var pages: [Reg_IndividualScreen_VC] = []
    
    var pageDots: UIPageControl!
    var scrollView: UIScrollView!
    
    var currentUser : PFUser!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        titleScrollerHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if PFUser.current() == nil {
            currentUser = PFUser()
        } else {
            currentUser = PFUser.current()
        }
        
        loadPages()
        
        delegate = self
        dataSource = self
        zoomOutAnimationDisabled = true
        pagingEnabled = true
        
        btnBack.alpha = 0
        
        for view in view.subviews {
            if view is UIPageControl {
                
                pageDots = (view as! UIPageControl)
                
                pageDots.frame = CGRect(x: 0, y: 33, width: pageDots.frame.width, height: pageDots.frame.height)
                pageDots.backgroundColor = UIColor.clear
                pageDots.isUserInteractionEnabled = false
            }
            
            if view is UIScrollView {
                scrollView = (view as! UIScrollView)
                scrollView.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                
                scrollView.isScrollEnabled = false
                scrollView.delegate = self
                
                scrollView.alpha = 0
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didScrollToView(at: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5, animations: {_ in
            self.scrollView.alpha = 1
            self.btnBack.alpha = 1
        })
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func loadPages() {
        if currentUser["name"] == nil { pages.append(Reg_Name_VC()) }
        if currentUser["email"] == nil { pages.append(Reg_Email_VC()) }
        if currentUser["password"] == nil { pages.append(Reg_Password_VC()) }
        if currentUser["cellNumber"] == nil { pages.append(Reg_CellNumber_VC()) }
        
        pages.append(Reg_Permissions_VC())
        pages.append(Reg_Done_VC())
    }

    // SCROLLVIEW STUFF
    
    func nextPage() {
        let nextPageIndex = self.getCurrentDisplayedPage()+1
        performManualScrolling(toIndex: nextPageIndex)
    }
    
    @IBAction func back(_ sender: Any) {
        previousPage()
    }
    
    func previousPage() {
        let previousPageIndex = self.getCurrentDisplayedPage()-1
        performManualScrolling(toIndex: previousPageIndex)
    }
    
    func getIndexOfViewControllerType(VCType: AnyClass) -> Int32 {
        var index: Int32 = 0
        
        for page in pages {
            if page.classForCoder == VCType { return index }
            index += 1
        }
        
        return 0
    }
    
    func performManualScrolling(toIndex: Int32) {
        
        if Int(toIndex) == pages.count {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        if Int(toIndex) == -1 {
            PFUser.logOut()
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        scroll(toPage: toIndex, animated: true)
        didScrollToView(at: UInt(toIndex))
    }
    
    func numberOfPages(forSlidingPagesViewController source: TTScrollSlidingPagesController!) -> Int32 {
        return Int32(pages.count)
    }
    
    func page(forSlidingPagesViewController source: TTScrollSlidingPagesController!, at index: Int32) -> TTSlidingPage! {
        view.bringSubview(toFront: pageDots)
        view.bringSubview(toFront: btnBack)
        
        return TTSlidingPage(contentViewController: pages[Int(index)])
    }
    
    func title(forSlidingPagesViewController source: TTScrollSlidingPagesController!, at index: Int32) -> TTSlidingPageTitle! {
        return TTSlidingPageTitle(headerText: "")
    }
    
    func didScrollToView(at index: UInt) {
        var colour = UIColor.flatSkyBlue
        
        colour = UIColor.init(randomFlatColorOf: .dark)
        
        if Int(index) == pages.count-1 {
            colour = UIColor.init(averageColorFrom: UIImage(named: "Background")!)
        }
        
//        colour = UIColor.init(averageColorFrom: UIImage(named: "Background")!)
        
//        let percentage = Double(arc4random_uniform(5)+5)/10
//        let lightDark = arc4random_uniform(1)
//        
//        if lightDark == 0 {
//            colour = colour.darken(byPercentage: CGFloat(percentage))!
//        } else {
//            colour = colour.lighten(byPercentage: CGFloat(percentage))!
//        }
        
        UIView.animate(withDuration: 0.4, animations: {
            self.view.backgroundColor = colour
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
