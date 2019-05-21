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
        
        self.title = L10n.Setting.title
        
        self.tableView.separatorStyle = .none
        
        self.isSyncEnabledLabel.text = L10n.Setting.storeIniCloud
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
            
            switchButton.hideProcessingAnimation()
            switchButton.isEnabled = true
            
            switch result {
            case .failure(let error):
                switchButton.isOn = !switchButton.isOn
                
                if case let error = error as? SyncError, error == .iCloudIsNotAvailable {
                    self?.showAlert(title: L10n.Setting.Alert.IcloudIsNotEnabled.title,
                                    message: L10n.Setting.Alert.IcloudIsNotEnabled.msg)
                } else {
                    self?.showAlert(title: L10n.Setting.Alert.failToStoreIniCloud, message: "\(error)")
                }
                
            default: break
            }
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
