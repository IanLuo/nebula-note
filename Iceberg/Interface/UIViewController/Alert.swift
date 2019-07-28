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
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
