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
    
    @IBOutlet var useDarkThemeLabel: UILabel!
    @IBOutlet var isDarkThemeEnabledSwitch: UISwitch!
    
    public override init(style: UITableView.Style) {
        super.init(style: style)
        
        self.modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.modalPresentationStyle = .overCurrentContext
    }
    
    public override func viewDidLoad() {
        self._setupUI()
        self._setupObserver()
    }
    
    private func _setupUI() {
        self.title = L10n.Setting.title
        
        self.tableView.separatorStyle = .none
        self.isSyncEnabledLabel.text = L10n.Setting.storeIniCloud
        self.isSyncEnabledSwitch.isOn = self.viewModel.isSyncEnabled
        
        self.useDarkThemeLabel.text = L10n.Setting.IsUseDarkInterface.title
        self.isDarkThemeEnabledSwitch.isOn = self.viewModel.isDarkInterfaceOn
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.Assets.down.image,
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(self._cancel))
        
        self.interface { [weak self] (me, theme) in
            self?.view.backgroundColor = theme.color.background1
            self?.isSyncEnabledLabel.textColor = theme.color.interactive
            self?.isSyncEnabledSwitch.onTintColor = theme.color.spotlight
            
            self?.useDarkThemeLabel.textColor = theme.color.interactive
            self?.isDarkThemeEnabledSwitch.onTintColor = theme.color.spotlight
        }
    }
    
    @objc private func _cancel() {
        self.viewModel.coordinator?.stop()
    }
    
    private func _setupObserver() {
        self.isSyncEnabledSwitch.addTarget(self, action: #selector(_iCloudSwitchTapped), for: .touchUpInside)
        self.isDarkThemeEnabledSwitch.addTarget(self, action: #selector(_isDarkInterfaceSwitchButtonTapped), for: .touchUpInside)
    }
    
    @objc private func _iCloudSwitchTapped(_ switchButton: UISwitch) {
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
    
    @objc private func _isDarkInterfaceSwitchButtonTapped(_ switchButton: UISwitch) {
        self.viewModel.setDarkInterfaceOn(switchButton.isOn)
    }
    
    private func _showLandingTabNamesSelector() {
        let selector = SelectorViewController()
        let tabs = self._landingTabNames

        for tabName in tabs {
            selector.addItem(title: tabName)
        }
        
        selector.currentTitle = tabs[self.viewModel.currentLandigTabIndex]
        
        self.present(selector, animated: true, completion: nil)
    }
    
    
    private var _landingTabNames: [String] {
        return [
            L10n.Agenda.title,
            L10n.CaptureList.title,
            L10n.Search.title,
            L10n.Browser.title
        ]
    }
}

extension SettingsViewController: SettingsViewModelDelegate {
    public func didSetInterfaceTheme(isOn: Bool) {
        let newTheme:InterfaceThemeProtocol = isOn ? DarkInterfaceTheme() : LightInterfaceTheme()
        InterfaceThemeSelector.shared.changeTheme(newTheme)
    }
    
    public func didSetLandingTabIndex(index: Int) {
        
    }
    
    public func didSetIsSyncEnabled(_ enabled: Bool) {
        
    }
    
    public func didUpdateFinishedPlanning() {
        
    }
    
    public func didUpdateUnfinishedPlanning() {
        
    }
}
