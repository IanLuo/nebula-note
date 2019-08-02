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
    
    @IBOutlet var interfaceStyleLabel: UILabel!
    @IBOutlet var interfaceStyleButton: UIButton!
    
    @IBOutlet var landingTabTitleLabel: UILabel!
    @IBOutlet var chooseLandingTabButton: UIButton!
    @IBOutlet var landingTabRow: UITableViewCell!
    
    @IBOutlet var planningFinishLabel: UILabel!
    @IBOutlet var planningFinishButton: UIButton!
    @IBOutlet var planningUnfinishLabel: UILabel!
    @IBOutlet var planningUnfinishButton: UIButton!
    
    public override init(style: UITableView.Style) {
        super.init(style: style)
        
        self.modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if #available(iOS 13.0, *) {
            // ignroe
        } else {
            self.modalPresentationStyle = .overCurrentContext
        }
    }
    
    public override func viewDidLoad() {
        self._setupUI()
        self._setupObserver()
        
        self.isSyncEnabledLabel.text = L10n.Setting.storeIniCloud
        self.landingTabTitleLabel.text = L10n.Setting.LandingTab.title
        self.isSyncEnabledSwitch.isOn = self.viewModel.isSyncEnabled
        self.chooseLandingTabButton.setTitle(LandingTab.allCases[self.viewModel.currentLandigTabIndex].name, for: .normal)
        
        self.interfaceStyleLabel.text = L10n.Setting.InterfaceStyle.title
        self.interfaceStyleButton.setTitle(self.viewModel.interfaceStyle.localizedTitle, for: .normal)
        
        self.planningFinishLabel.text = L10n.Setting.Planning.Finish.title
        self.planningFinishButton.setTitle(self.viewModel.getPlanning(isForFinished: true).joined(separator: ","), for: .normal)
        self.planningUnfinishLabel.text = L10n.Setting.Planning.Unfinish.title
        self.planningUnfinishButton.setTitle(self.viewModel.getPlanning(isForFinished: false).joined(separator: ","), for: .normal)
    }
    
    private func _setupUI() {
        self.tableView.contentInset = .init(top: 0, left: 0, bottom: 80, right: 0)
        self.title = L10n.Setting.title
        
        self.tableView.separatorStyle = .none
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.Assets.down.image,
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(self._cancel))
        
        self.interface { [weak self] (me, theme) in
            me.setNeedsStatusBarAppearanceUpdate()
            self?.view.backgroundColor = theme.color.background1
            self?.isSyncEnabledLabel.textColor = theme.color.interactive
            self?.isSyncEnabledSwitch.onTintColor = theme.color.spotlight
            
            self?.interfaceStyleLabel.textColor = theme.color.interactive
            self?.interfaceStyleButton.setTitleColor(theme.color.spotlight, for: .normal)
            
            self?.landingTabTitleLabel.textColor = theme.color.interactive
            self?.chooseLandingTabButton.setTitleColor(theme.color.spotlight, for: .normal)
            self?.landingTabRow.tintColor = theme.color.descriptive
            
            self?.planningFinishLabel.textColor = theme.color.interactive
            self?.planningFinishButton.setTitleColor(theme.color.spotlight, for: .normal)
            self?.planningUnfinishLabel.textColor = theme.color.interactive
            self?.planningUnfinishButton.setTitleColor(theme.color.spotlight, for: .normal)
        }
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return InterfaceTheme.statusBarStyle
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return L10n.Setting.General.title
        case 1: return L10n.Setting.Planning.title
        case 2: return L10n.Setting.Store.title
        default: return nil
        }
    }
    
    @objc private func _cancel() {
        self.viewModel.coordinator?.stop()
    }
    
    private func _setupObserver() {
        self.isSyncEnabledSwitch.addTarget(self, action: #selector(_iCloudSwitchTapped), for: .touchUpInside)
        self.interfaceStyleButton.addTarget(self, action: #selector(_interfaceStyleButtonTapped), for: .touchUpInside)
        self.chooseLandingTabButton.addTarget(self, action: #selector(_showLandingTabNamesSelector), for: .touchUpInside)
        self.planningFinishButton.addTarget(self, action: #selector(_planningManageFinish), for: .touchUpInside)
        self.planningUnfinishButton.addTarget(self, action: #selector(_planningManageUnfinish), for: .touchUpInside)
    }
    
    @objc private func _iCloudSwitchTapped(_ switchButton: UISwitch) {
        switchButton.isEnabled = false
        switchButton.showProcessingAnimation()
        self.showLoading()
        self.viewModel.setSyncEnabled(switchButton.isOn, completion: { [weak self] result in
            self?.hideLoading { [weak self] in
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
            }
        })
    }
    
    /// user interface style
    @objc private func _interfaceStyleButtonTapped(_ button: UIButton) {
        let selector = SelectorViewController()
        selector.title = L10n.Setting.InterfaceStyle.title
        let dependency = self.viewModel.coordinator?.dependency
        
        selector.fromView = button.superview
        
        let styles = [SettingsAccessor.InterfaceStyle.dark,
        SettingsAccessor.InterfaceStyle.light,
        SettingsAccessor.InterfaceStyle.auto]
        
        selector.addItem(title: styles[0].localizedTitle)
        selector.addItem(title: styles[1].localizedTitle)
        
        if #available(iOS 13, *) {
            selector.addItem(title: styles[2].localizedTitle)
        }
        
        selector.onCancel = { viewController in
            viewController.dismiss(animated: true)
            dependency?.globalCaptureEntryWindow?.show()
        }
        
        selector.onSelection = { index, viewController in
            viewController.dismiss(animated: true)
            self.viewModel.setInterfaceStyle(styles[index])
            dependency?.globalCaptureEntryWindow?.show()
            self.interfaceStyleButton.setTitle(styles[index].localizedTitle, for: .normal)
        }
        
        self.present(selector, animated: true)
        dependency?.globalCaptureEntryWindow?.hide()
    }
    
    @objc private func _showLandingTabNamesSelector() {
        let dependency = self.viewModel.coordinator?.dependency
        
        let selector = SelectorViewController()
        let tabs = LandingTab.allCases

        for tab in tabs {
            selector.addItem(icon: tab.icon, title: tab.name)
        }
        
        selector.fromView = self.landingTabRow
        selector.title = L10n.Setting.LandingTab.title
        
        selector.onCancel = { viewController in
            viewController.dismiss(animated: true, completion: nil)
            dependency?.globalCaptureEntryWindow?.show()
        }
        
        selector.onSelection = { index, viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.setLandingTabIndex(index)
            self.chooseLandingTabButton.setTitle(tabs[index].name, for: .normal)
            dependency?.globalCaptureEntryWindow?.show()
        }
        
        selector.currentTitle = tabs[self.viewModel.currentLandigTabIndex].name
        
        self.present(selector, animated: true, completion: nil)
        dependency?.globalCaptureEntryWindow?.hide()
    }
    
    @objc func _planningManageFinish() {
        self._planningManage(isFinish: true)
    }
    
    @objc func _planningManageUnfinish() {
        self._planningManage(isFinish: false)
    }
    
    private func _planningManage(isFinish: Bool) {
        let plannings = self.viewModel.getPlanning(isForFinished: isFinish)
        
        let actionsViewController = ActionsViewController()
        
        actionsViewController.title = isFinish
        ? self.planningFinishLabel.text
        : self.planningUnfinishLabel.text
        
        for planning in plannings {
            let canDelete = !self.viewModel.defaultPlannings.contains(planning)
            let icon =  canDelete ? Asset.Assets.cross.image.fill(color: InterfaceTheme.Color.warning) : nil
            actionsViewController.addAction(icon: icon, title: planning) { viewController in
                if canDelete {
                    self.viewModel.removePlanning(planning, completion: {
                        viewController.removeAction(with: planning)
                        
                        let buttonToUpdate = isFinish ?
                            self.planningFinishButton : self.planningUnfinishButton
                        
                        buttonToUpdate?.setTitle(self.viewModel.getPlanning(isForFinished: isFinish).joined(separator: ","), for: .normal)
                    })
                }
            }
        }
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        let addTitle = isFinish ? L10n.Setting.Planning.Finish.add :  L10n.Setting.Planning.Unfinish.add
        actionsViewController.addAction(icon: Asset.Assets.add.image.fill(color: InterfaceTheme.Color.spotlight), title: addTitle, style: .highlight) { viewController in
            viewController.dismiss(animated: true, completion: {
                let formViewController = ModalFormViewController()
                
                formViewController.addTextFied(title: addTitle, placeHoder: "", defaultValue: nil)
                formViewController.onValidating = {
                    if let data = $0[addTitle] as? String {
                        if plannings.contains(data) {
                            return [addTitle: L10n.Setting.Planning.Add.Error.nameTaken]
                        }
                    }
                    
                    return [:]
                }
                
                
                formViewController.title = addTitle
                
                formViewController.onCancel = { viewController in
                    viewController.dismiss(animated: true, completion: nil)
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                }
                
                formViewController.onSaveValue = { data, viewController in
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    
                    if let newPlanning = data[addTitle] as? String {
                        self.viewModel.addPlanning(newPlanning, isForFinished: isFinish, completion: {
                            viewController.dismiss(animated: true, completion: { [weak self] in
                                guard let strongSelf = self else { return }
                                let buttonToUpdate = isFinish ?
                                strongSelf.planningFinishButton : strongSelf.planningUnfinishButton
                                
                                buttonToUpdate?.setTitle(strongSelf.viewModel.getPlanning(isForFinished: isFinish).joined(separator: ","), for: .normal)
                                
                                strongSelf.viewModel.coordinator?.dependency.editorContext.reloadParser() // 因为解析器的常亮以改变，需要重载解析器
                            })
                        })
                    }
                }
                
                self.present(formViewController, animated: true, completion: nil)
            })
        }
        
        self.present(actionsViewController, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    enum LandingTab: CaseIterable {
        case agenda, captureList, search, browser
        
        var name: String {
            switch self {
            case .agenda: return  L10n.Agenda.title
            case .captureList: return L10n.CaptureList.title
            case .search: return L10n.Search.title
            case .browser: return L10n.Browser.title
            }
        }
        
        var icon: UIImage {
            switch self {
            case .agenda: return Asset.Assets.agenda.image.fill(color: InterfaceTheme.Color.interactive)
            case .captureList: return Asset.Assets.inspiration.image.fill(color: InterfaceTheme.Color.interactive)
            case .search: return Asset.Assets.zoom.image.fill(color: InterfaceTheme.Color.interactive)
            case .browser: return Asset.Assets.document.image.fill(color: InterfaceTheme.Color.interactive)
            }
        }
    }
}

extension SettingsViewController: SettingsViewModelDelegate {
    public func didSetInterfaceStyle(newStyle: SettingsAccessor.InterfaceStyle) {
        self.setupTheme()
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

// MARK: -
extension SettingsAccessor.InterfaceStyle {
    public var localizedTitle: String {
        switch self {
        case .auto:
            return L10n.Setting.InterfaceStyle.auto
        case .dark:
            return L10n.Setting.InterfaceStyle.dark
        case .light:
            return L10n.Setting.InterfaceStyle.light
        }
    }
}