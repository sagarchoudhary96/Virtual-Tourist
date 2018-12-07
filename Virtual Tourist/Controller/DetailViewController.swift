//
//  DetailViewController.swift
//  Virtual Tourist
//
//  Created by Sagar Choudhary on 05/12/18.
//  Copyright © 2018 Sagar Choudhary. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class DetailViewController: UIViewController {
    
    // MARK: Tapped Pin
    var pinTapped: Pin!
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var editLabel: UILabel!
    @IBOutlet weak var reloadButton: UIButton!
    
    //MARK: fetchedResultController
    var resultController:NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup mapview region to tapped pin
        let pin = MKPointAnnotation()
        pin.coordinate = CLLocationCoordinate2DMake(pinTapped.latitude, pinTapped.longitude)
        mapView.addAnnotation(pin)
        mapView.setRegion(MKCoordinateRegion(center: pin.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)), animated: true)
        
        // setup initial views
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.title = "Photo Album"
        editLabel.isHidden = true
        
        // collectionView Delegate and dataSource
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultController()
        
        if (resultController.fetchedObjects?.count)! < 1  {
            reloadImageCollection(nil)
        }
        collectionView.reloadData()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resultController = nil
    }
    
    //MARK: Edit Button
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        editLabel.isHidden = !editing
        reloadButton.isHidden = editing
    }
    
    //MARK: Setup FetchedResultController
    fileprivate func setupFetchedResultController() {
        // create fetch request
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        // predicate
        let predicate = NSPredicate(format: "pin == %@", pinTapped)
        fetchRequest.predicate = predicate
        
        // sort descriptor
        fetchRequest.sortDescriptors = []
        
        resultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // set delegate
        resultController.delegate = self
        
        // fetch data
        do {
            try resultController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: load Imagees from Flickr API
    @IBAction func reloadImageCollection(_ sender: Any?) {
        
        // delete photos from coreData if present
        deletePhotos()
        
        // setup inital state for collectionView
        showNoImageLabel(show: false)
        reloadButtonEnabled(isEnabled: false)
        
        // create request
        let request = APIClient.shared.createRequest(pin: pinTapped)
        
        // make the request
        APIClient.shared.makeRequest(request: request) {
            (result, error) in
            
            // guard for the error
            guard error == nil else {
                self.showAlertMessage(message: error!)
                self.showNoImageLabel(show: true)
                self.reloadButtonEnabled(isEnabled: true)
                return
            }
            
            // guard if no image found
            guard result!.count > 0 else {
                self.showNoImageLabel(show: true)
                self.reloadButtonEnabled(isEnabled: true)
                return
            }
            
            // add phootos to coreData
            self.addPhotos(photos: result!)
            self.reloadButtonEnabled(isEnabled: true)
        }
    }
    
    // MARK: Add photo to CoreData
    fileprivate func addPhotos(photos: NSArray) {
        for _ in 1...15 {
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photos.count)))
            let photo = photos[randomPhotoIndex] as! [String:AnyObject]
            guard let imageUrl = photo[Constants.FlickrResponseKeys.ImageUrl] as? String else {
                return
            }
            let photoToAdd = Photo(context: DataController.shared.viewContext)
            photoToAdd.pin = pinTapped
            photoToAdd.imageUrl = imageUrl
            saveViewContext()
        }
    }
    
    // MARK: Delete photos from coreData
    fileprivate func deletePhotos() {
        for photo in (resultController!.fetchedObjects)! {
            DataController.shared.viewContext.delete(photo)
            saveViewContext()
        }
    }
    
    // save context
    func saveViewContext() {
        try? DataController.shared.viewContext.save()
    }
    
    // MARK: no image label
    fileprivate func showNoImageLabel(show: Bool) {
        DispatchQueue.main.async {
            self.noImageLabel.isHidden = !show
        }
    }
    
    // Mark: Handle reload Collection button state
    fileprivate func reloadButtonEnabled(isEnabled: Bool) {
        DispatchQueue.main.async {
            self.reloadButton.isEnabled = isEnabled
        }
    }
}


// MARK: CollectionView Delegate Methods
extension DetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return resultController.sections?.count ?? 1
    }
    
    // number of cells to be generated
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultController.sections?[section].numberOfObjects ?? 0
    }
    
    // setup each cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // get the photo
        let photo = resultController.object(at: indexPath)
        
        // initialize cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        
        if photo.image == nil {
            APIClient.shared.downloadImage(imageUrl: photo.imageUrl!) {
                (image, error) in
                guard error == nil else {
                    self.showAlertMessage(message: error!)
                    return
                }
                DispatchQueue.main.async {
                    photo.image = image
                    self.saveViewContext()
                    cell.activityIndicator.stopAnimating()
                }
            }
        } else {
            cell.imageView.image = UIImage(data: photo.image!)
            cell.activityIndicator.stopAnimating()
        }
        
        return cell
    }
    
    // onTap handler
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditing {
            let photo = resultController.object(at: indexPath)
            DataController.shared.viewContext.delete(photo)
            saveViewContext()
        }
    }
}

// MARK: fetchedResultController Delegate
extension DetailViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
            break
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        default:
            break
        }
    }
}
