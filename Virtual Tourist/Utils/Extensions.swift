//
//  Extensions.swift
//  Virtual Tourist
//
//  Created by Sagar Choudhary on 08/12/18.
//  Copyright © 2018 Sagar Choudhary. All rights reserved.
//

import UIKit

extension UIViewController {
    // show alert message
    func showAlertMessage(message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Error!", message: message, preferredStyle: UIAlertController.Style.alert)
            let alertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alertController.addAction(alertAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
