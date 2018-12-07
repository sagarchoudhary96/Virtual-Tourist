//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Sagar Choudhary on 05/12/18.
//  Copyright © 2018 Sagar Choudhary. All rights reserved.
//

import Foundation
import CoreData

// MARK: Data Controller
class DataController {
    
    // create persistant container
    let persistantContainer: NSPersistentContainer
    
    static let shared = DataController(modelName: "VirtualTourist")
    
    // store context
    var viewContext: NSManagedObjectContext {
        return persistantContainer.viewContext
    }
    var backgroundContext: NSManagedObjectContext!
    
    // initialize container
    init(modelName: String) {
        persistantContainer = NSPersistentContainer(name: modelName)
    }
    
    private func configureContexts() {
        backgroundContext = persistantContainer.newBackgroundContext()
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    // load the store
    func load(completionHandler: (() -> Void)? = nil) {
        persistantContainer.loadPersistentStores() {
            (storeDescription, error) in
            // guard for error loading container
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            // enable autosave
            self.autosaveViewContext()
            self.configureContexts()
        }
    }
}

//MARK: AutoSave CoreData ViewContext
extension DataController {
    func autosaveViewContext(interval:TimeInterval = 30) {
        guard interval > 0 else {
            return
        }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autosaveViewContext()
        }
    }
}
