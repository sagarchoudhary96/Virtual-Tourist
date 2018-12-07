//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Sagar Choudhary on 04/12/18.
//  Copyright © 2018 Sagar Choudhary. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    //MARK: outlets
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK: fetchedResultController
    var resultController:NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // map Delegate
        mapView.delegate = self
        
        // setup Initial Views
        deleteLabel.isHidden = true
        navigationItem.rightBarButtonItem = editButtonItem
        addGestureToMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultController()
        setMapRegion()
        setupMarkers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resultController = nil
    }
    
    //MARK: Edit Button
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        deleteLabel.isHidden = !editing
    }
    
    //MARK: Setup FetchedResultController
    fileprivate func setupFetchedResultController() {
        
        // create fetch request
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        // sort descriptor
        fetchRequest.sortDescriptors = []
        
        resultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // fetch data
        do {
            try resultController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: setup markers on map
    fileprivate func setupMarkers() {
        
        // get the pins from coreData
        let pins = resultController.fetchedObjects
        
        // remove previous pins
        mapView.removeAnnotations(mapView.annotations)
        
        // add new pins to map
        for pin in pins! {
            addMarkerToMap(coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
        }
    }
    
    // setup map Region as user zoom/move on map
    fileprivate func setMapRegion() {
        if let mapRegion = UserDefaults.standard.dictionary(forKey: "mapRegion") {
            let center = CLLocationCoordinate2DMake(mapRegion["lat"] as! Double, mapRegion["long"] as! Double)
            let span = MKCoordinateSpan(latitudeDelta: mapRegion["latDelta"] as! Double, longitudeDelta: mapRegion["longDelta"] as! Double)
            
            let region = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(region, animated: true)
        }
    }
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? DetailViewController {
            let pin = sender as! Pin
            vc.pinTapped = pin
        }
    }
}

//MARK: additional Functions
extension MapViewController {
    
    // longTap gesture
    private func addGestureToMap() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addMarker(gesture:)))
        gestureRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    // add marker on longTap
    @objc func addMarker(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let pinLocation = gesture.location(in: mapView)
            let pinCoordinate = mapView.convert(pinLocation, toCoordinateFrom: mapView)
            addMarkerToMap(coordinate: pinCoordinate)
            addPin(coordinate: pinCoordinate)
        }
    }
    
    // add marker to map
    func addMarkerToMap(coordinate: CLLocationCoordinate2D) {
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        mapView.addAnnotation(pin)
    }
    
    // add pin to coreData
    func addPin(coordinate: CLLocationCoordinate2D) {
        let pinToAdd = Pin(context: DataController.shared.viewContext)
        pinToAdd.latitude = coordinate.latitude
        pinToAdd.longitude = coordinate.longitude
        saveViewContext()
    }
    
    // fetch pin from coreData
    func getPin(latitude: Double, longitude: Double) -> Pin? {
        // create fetch request
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        // predicate
        let predicate = NSPredicate(format: "latitude == %lf AND longitude == %lf", latitude, longitude)
        fetchRequest.predicate = predicate
        
        // search for the pin
        guard let pin = (try? DataController.shared.viewContext.fetch(fetchRequest))!.first else {
            return nil
        }
        
        return pin
    }
    
    // save Context
    func saveViewContext() {
        try? DataController.shared.viewContext.save()
    }
}


//MARK: MAP Delegate functions
extension MapViewController : MKMapViewDelegate {
    
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pin = getPin(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!) else {
            self.showAlertMessage(message: "Pin not found in db")
            return
        }
        
        if isEditing {
            DataController.shared.viewContext.delete(pin)
            saveViewContext()
            mapView.removeAnnotation(view.annotation!)

        } else {
            performSegue(withIdentifier: "detailView", sender: pin)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let defaults = UserDefaults.standard
        let locationData = ["lat":mapView.centerCoordinate.latitude
            , "long":mapView.centerCoordinate.longitude
            , "latDelta":mapView.region.span.latitudeDelta
            , "longDelta":mapView.region.span.longitudeDelta]
        defaults.set(locationData, forKey: "mapRegion")
    }
}
