//
//  Alert.swift
//  Interface
//
//  Created by ian luo on 2019/5/14.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    public func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: L10n.General.Button.ok, style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func toastError(title: String, subTitle: String? = nil) {
        let alertController = UIAlertController(title: title, message: subTitle, preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            alertController.dismiss(animated: true)
        }
    }
    
    public func toastSuccess() {
        let alertController = UIAlertController(title: "Success", message: nil, preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            alertController.dismiss(animated: true)
        }
    }
}
