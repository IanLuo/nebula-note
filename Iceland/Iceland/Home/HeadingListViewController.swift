//
//  HeadingListViweController.swift
//  Iceland
//
//  Created by ian luo on 2019/2/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol HeadingListViewControllerDelegate: class {
    
}

public class HeadingListViewController: UIViewController {
    public weak var delegate: HeadingListViewControllerDelegate?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
    }
    
    private let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint), for: .normal)
        button.tintColor = InterfaceTheme.Color.interactive
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }()
    
    private func setupUI() {
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        self.view.addSubview(self.backButton)
        
        self.backButton.sideAnchor(for: [.left, .top], to: self.view, edgeInset: 30)
        self.backButton.sizeAnchor(width: 40, height: 40)
        
        self.backButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    }
    
    @objc private func cancel() {
        self.navigationController?.popViewController(animated: true)
    }
}
