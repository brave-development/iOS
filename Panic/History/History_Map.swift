//
//  History_Map.swift
//  Brave
//
//  Created by Byron Coetsee on 2018/03/26.
//  Copyright © 2018 Byron Coetsee. All rights reserved.
//

import UIKit
import Mapbox
import SwiftLocation

extension HistoryViewController {
    
    func initMap() {
        
        map = MGLMapView(frame: self.view.bounds, styleURL: MGLStyle.darkStyleURL(withVersion: 9))
        //        map = MGLMapView(frame: self.view.bounds, styleURL: MGLStyle.lightStyleURL(withVersion: 9))
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        map.setCenter(CLLocationCoordinate2DMake(-33, 18), zoomLevel: 4, animated: true)
        map.delegate = self
        map.showsUserLocation = true
        map.isRotateEnabled = false
        view.insertSubview(map, at: 0)
        
        Locator.currentPosition(accuracy: .house, onSuccess: {
            location in
            self.map.setCenter(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), zoomLevel: 15, animated: true)
        }) {
            error, _ in
            print(error)
        }
    }
    
    func moveToAlert(alert: Sub_PFAlert) {
        guard let location = alert.location else { return }
        
        if map.annotations != nil { map.removeAnnotations(map.annotations!) }
        
        let newAnnot = MGLPointAnnotation()
        newAnnot.title = alert.details
        newAnnot.coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        map.addAnnotation(newAnnot)
        
        map.setCenter(CLLocationCoordinate2DMake(location.latitude, location.longitude), zoomLevel: 13, animated: true)
    }
}

extension HistoryViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool { return true }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        // Assign a reuse identifier to be used by both of the annotation views, taking advantage of their similarities.
        let reuseIdentifier = "reusableDotView"
        
        // For better performance, always try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            annotationView?.layer.cornerRadius = (annotationView?.frame.size.width)! / 2
            annotationView?.layer.borderWidth = 2.0
            annotationView?.layer.borderColor = UIColor.white.cgColor
            annotationView!.backgroundColor = UIColor(red:0.03, green:0.80, blue:0.69, alpha:1.0)
        }
        
        return annotationView
    }
}
