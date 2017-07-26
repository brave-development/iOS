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
    
    @IBOutlet weak var lblInstruction: UILabel!
    
    let pages = [Reg_Email_VC(), Reg_Password_VC(), Reg_Done_VC()]
    var pageDots: UIPageControl!
    
    let currentUser = PFUser()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        titleScrollerHidden = true
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        zoomOutAnimationDisabled = true
        pagingEnabled = true
        
        for view in view.subviews {
            if view is UIPageControl {
                
                pageDots = (view as! UIPageControl)
                
//                let origin_y = CGFloat(UIScreen.main.bounds.height-37)
                pageDots.frame = CGRect(x: 0, y: 33, width: pageDots.frame.width, height: pageDots.frame.height)
                pageDots.backgroundColor = UIColor.clear
                pageDots.isUserInteractionEnabled = false
            }
            
            if view is UIScrollView {
                (view as! UIScrollView).isScrollEnabled = false
                (view as! UIScrollView).delegate = self
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didScrollToView(at: 0)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }

    // SCROLLVIEW STUFF
    
    func nextPage() {
        let nextPageIndex = self.getCurrentDisplayedPage()+1
        performManualScrolling(toIndex: nextPageIndex)
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
        
        if Int(toIndex) == pages.count || Int(toIndex) == -1 {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        scroll(toPage: toIndex, animated: true)
        didScrollToView(at: UInt(toIndex))
    }
    
    func numberOfPages(forSlidingPagesViewController source: TTScrollSlidingPagesController!) -> Int32 {
        return Int32(3)
    }
    
    func page(forSlidingPagesViewController source: TTScrollSlidingPagesController!, at index: Int32) -> TTSlidingPage! {
        view.bringSubview(toFront: pageDots)
        return TTSlidingPage(contentViewController: pages[Int(index)])
    }
    
    func title(forSlidingPagesViewController source: TTScrollSlidingPagesController!, at index: Int32) -> TTSlidingPageTitle! {
        return TTSlidingPageTitle(headerText: "")
    }
    
    func didScrollToView(at index: UInt) {
        var colour = UIColor.flatSkyBlue
        
        switch index {
        case 0:
            colour = UIColor.flatSkyBlue
        case 1:
            colour = UIColor.flatGreen
        case 2:
            colour = UIColor.flatTeal
        default:
            colour = UIColor.white
        }
        
        UIView.animate(withDuration: 0.4, animations: {
            self.view.backgroundColor = colour
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
