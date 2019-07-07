//
//  LoadingViewController.swift
//  Interface
//
//  Created by ian luo on 2019/7/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    public func showLoading() {
        let alertController = UIAlertController(title: L10n.General.Loading.title, message: nil, preferredStyle: .alert)
        let indicator = UIActivityIndicatorView()
        alertController.view.addSubview(indicator)
        indicator.centerAnchors(position: [.centerX, .centerY], to: alertController.view)
        indicator.startAnimating()
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func hideLoading(completion: (() -> Void)? = nil) {
        if let c = self.presentedViewController {
            if c is UIAlertController {
                c.dismiss(animated: true, completion: completion)
            }
        }
    }
}
