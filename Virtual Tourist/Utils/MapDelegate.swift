//
//  MapDelegate.swift
//  Virtual Tourist
//
//  Created by Sagar Choudhary on 04/12/18.
//  Copyright © 2018 Sagar Choudhary. All rights reserved.
//

import UIKit
import MapKit

class MapDelegate: UIViewController, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // make reusable pinView
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView?.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}
