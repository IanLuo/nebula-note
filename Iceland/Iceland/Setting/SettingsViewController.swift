//
//  SettingsViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface

public protocol SettingsViewControllerDelegate: class {
    
}

public class SettingsViewController: UITableViewController {
    public var viewModel: SettingsViewModel!
    
    @IBOutlet var isSyncEnabledLabel: UILabel!
    @IBOutlet var isSyncEnabledSwitch: UISwitch!
    
    public override func viewDidLoad() {
        self._setupUI()
        self._setupObserver()
    }
    
    private func _setupUI() {
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        self.title = "Settings"
        
        self.tableView.separatorStyle = .none
        
        self.isSyncEnabledLabel.text = "Enable Sync"
        self.isSyncEnabledLabel.textColor = InterfaceTheme.Color.interactive
        self.isSyncEnabledSwitch.isOn = self.viewModel.isSyncEnabled
        self.isSyncEnabledSwitch.onTintColor = InterfaceTheme.Color.spotlight
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.Assets.down.image.fill(color: InterfaceTheme.Color.interactive),
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(_cancel))
    }
    
    @objc private func _cancel() {
        self.viewModel.coordinator.stop()
    }
    
    private func _setupObserver() {
        self.isSyncEnabledSwitch.onValueChanged { [weak self] switchButton, isOn in
            switchButton.isEnabled = false
            switchButton.showProcessingAnimation()
            self?.viewModel.setSyncEnabled(isOn, completion: {
                switchButton.isEnabled = true
                switchButton.hideProcessingAnimation()
            })
        }
    }
}

extension SettingsViewController: SettingsViewModelDelegate {
    public func didSetIsSyncEnabled(_ enabled: Bool) {
        
    }
    
    public func didUpdateFinishedPlanning() {
        
    }
    
    public func didUpdateUnfinishedPlanning() {
        
    }
}
