//
//  Alert.swift
//  Interface
//
//  Created by ian luo on 2019/5/14.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import PKHUD

extension UIViewController {
    public func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: L10n.General.Button.ok, style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func toastError(title: String, subTitle: String? = nil) {
        HUD.flash(HUDContentType.labeledError(title: title, subtitle: subTitle), delay: 1.5)
    }
    
    public func toastSuccess() {
        HUD.flash(HUDContentType.success)
    }
}
