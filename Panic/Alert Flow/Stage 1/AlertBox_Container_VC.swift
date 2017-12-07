//
//  AlertBox_Container_VC.swift
//  Brave
//
//  Created by Byron Coetsee on 2017/11/28.
//  Copyright © 2017 Byron Coetsee. All rights reserved.
//

import UIKit
import UIScrollSlidingPages

class AlertBox_Container_VC: TTScrollSlidingPagesController, TTSlidingPagesDataSource {
    
    var pages: [AlertBox_Individual_VC] = []
    
    var pageDots: UIPageControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        pagingEnabled = true
        
        loadPages()
        modifyPageController()
    }
    
    func loadPages() {
        pages.append(AlertBox_Text_VC())
        pages.append(AlertBox_Text_VC())
        pages.append(AlertBox_Text_VC())
    }
    
    func modifyPageController() {
        for view in view.subviews {
            if view is UIPageControl {
                
                pageDots = (view as! UIPageControl)
                
                pageDots.frame = CGRect(x: 0, y: 33, width: pageDots.frame.width, height: pageDots.frame.height)
                pageDots.backgroundColor = UIColor.clear
                pageDots.pageIndicatorTintColor = UIColor.blue
                pageDots.currentPageIndicatorTintColor = UIColor.green
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}



// ======================
//
// Delegate Methods
// Other scollView and page methods
//
// ======================



extension AlertBox_Container_VC: TTSliddingPageDelegate {
    
//    func nextPage() {
//        let nextPageIndex = self.getCurrentDisplayedPage()+1
//        performManualScrolling(toIndex: nextPageIndex)
//    }
//
//    @IBAction func back(_ sender: Any) {
//        previousPage()
//    }
//
//    func previousPage() {
//        let previousPageIndex = self.getCurrentDisplayedPage()-1
//        performManualScrolling(toIndex: previousPageIndex)
//    }
    
    func getIndexOfViewControllerType(VCType: AnyClass) -> Int32 {
        var index: Int32 = 0
        
        for page in pages {
            if page.classForCoder == VCType { return index }
            index += 1
        }
        
        return 0
    }
    
//    func performManualScrolling(toIndex: Int32) {
//
//        // Scroll forward past the final page
//        if Int(toIndex) == pages.count { return }
//
//        // Scroll back past the first page
//        if Int(toIndex) == -1 { return }
//
//        scroll(toPage: toIndex, animated: true)
//        didScrollToView(at: UInt(toIndex))
//    }
    
    func numberOfPages(forSlidingPagesViewController source: TTScrollSlidingPagesController!) -> Int32 {
        return Int32(pages.count)
    }
    
    func page(forSlidingPagesViewController source: TTScrollSlidingPagesController!, at index: Int32) -> TTSlidingPage! {
        view.bringSubview(toFront: pageDots)
//        view.bringSubview(toFront: btnBack)
        
        return TTSlidingPage(contentViewController: pages[Int(index)])
    }
    
    func title(forSlidingPagesViewController source: TTScrollSlidingPagesController!, at index: Int32) -> TTSlidingPageTitle! {
        return TTSlidingPageTitle(headerText: "")
    }
    
    func didScrollToView(at index: UInt) {
//        var colour = UIColor.flatSkyBlue
//
//        colour = UIColor.init(randomFlatColorOf: .dark)
//
//        if Int(index) == pages.count-1 {
//            colour = UIColor.init(averageColorFrom: UIImage(named: "Background")!)
//        }
//
//        UIView.animate(withDuration: 0.4, animations: {
//            self.view.backgroundColor = colour
//        })
        
//        openKeyboard(forPage: Int(index))
    }
    
}
