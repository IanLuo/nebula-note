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
import Business

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
        self.viewModel.coordinator?.stop()
    }
    
    private func _setupObserver() {
        self.isSyncEnabledSwitch.addTarget(self, action: #selector(_switched(_:)), for: .touchUpInside)
    }
    
    @objc private func _switched(_ switchButton: UISwitch) {
        switchButton.isEnabled = false
        switchButton.showProcessingAnimation()
        
        self.viewModel.setSyncEnabled(switchButton.isOn, completion: { [weak self] result in
            switch result {
            case .failure(let error):
                switchButton.isOn = !switchButton.isOn
                
                if case let error = error as? SyncError, error == .iCloudIsNotAvailable {
                    self?.showAlert(title: "iCloud is not enabled",
                                    message: "Please login your iCloud account")
                } else {
                    self?.showAlert(title: "Fail to configure sync", message: "\(error)")
                }
                
            default: break
            }
            
            switchButton.hideProcessingAnimation()
            switchButton.isEnabled = true
        })
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
