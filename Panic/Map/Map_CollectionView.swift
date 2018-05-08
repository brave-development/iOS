//
//  Map_CollectionView.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/05/06.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit

extension MapViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func initCollectionView() {
        colHistory.dataSource = self
        colHistory.delegate = self
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        //ensure that the end of scroll is fired.
        perform(#selector(self.scrollViewDidEndScrollingAnimation), with: self, afterDelay: 0.3)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        var visibleRect = CGRect()
        
        visibleRect.origin = colHistory.contentOffset
        visibleRect.size = colHistory.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        guard let indexPath = colHistory.indexPathForItem(at: visiblePoint) else { return }
        guard let cell = colHistory.cellForItem(at: indexPath) as? History_Cell else { return }
        
        moveToAlert(alert: cell.alert)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = colHistory.cellForItem(at: indexPath) as? History_Cell else { return }
        
        openChat(withAlert: cell.alert)
    }
    
    func openChat(withAlert alert: Sub_PFAlert) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "alertStage_2_VC") as! AlertStage_2_VC
        vc.alert = alert
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        map.userTrackingMode = alerts.count == 0 ? .follow : .none
        return alerts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = colHistory.dequeueReusableCell(withReuseIdentifier: "history_cell", for: indexPath) as! History_Cell
        cell.setup(alert: alerts[indexPath.row])
        return cell
    }
}
