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
import Core
import RxSwift
import StoreKit
import Doorbell

public protocol SettingsViewControllerDelegate: class {
    
}   

public class SettingsViewController: UITableViewController {
    public var viewModel: SettingsViewModel!
    
    @IBOutlet var isSyncEnabledLabel: UILabel!
    @IBOutlet var storeLocationButton: UIButton!
    
    @IBOutlet weak var attachmentManagerLabel: UILabel!
    
    
    @IBOutlet var interfaceStyleLabel: UILabel!
    @IBOutlet var interfaceStyleButton: UIButton!
    
    @IBOutlet var landingTabTitleLabel: UILabel!
    @IBOutlet var chooseLandingTabButton: UIButton!
    @IBOutlet var landingTabRow: UITableViewCell!
    
    @IBOutlet weak var browserStyleLabel: UILabel!
    @IBOutlet weak var browserStyleButton: UIButton!
    
    @IBOutlet var planningFinishLabel: UILabel!
    @IBOutlet var planningFinishButton: UIButton!
    @IBOutlet var planningUnfinishLabel: UILabel!
    @IBOutlet var planningUnfinishButton: UIButton!
    
    @IBOutlet var exportShowIndexLabel: UILabel!
    @IBOutlet var exportShowIndexSwitch: UISwitch!
    
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var termsOfServiceButton: UIButton!
    
    @IBOutlet weak var resetPublishLoginInfo: UILabel!
    
    @IBOutlet weak var feedbackLabel: UILabel!
    @IBOutlet weak var feedbackButton: UIButton!
    
    
    private let disposeBag = DisposeBag()
    
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
    
    deinit {
        print("deinit")
    }
    
    public override func viewDidLoad() {
        self._setupUI()
        self._setupObserver()
        
        // initial status
        self.isSyncEnabledLabel.text = L10n.Setting.storeLocation
        self.landingTabTitleLabel.text = L10n.Setting.LandingTab.title
        self.storeLocationButton.setTitle(self.viewModel.isSyncEnabled ? L10n.Setting.StoreLocation.iCloud : L10n.Setting.StoreLocation.onDevice, for: .normal)
        self.chooseLandingTabButton.setTitle(TabIndex.allCases[self.viewModel.currentLandigTabIndex].name, for: .normal)
        
        self.interfaceStyleLabel.text = L10n.Setting.InterfaceStyle.title
        self.interfaceStyleButton.setTitle(self.viewModel.interfaceStyle.localizedTitle, for: .normal)
        
        self.browserStyleLabel.text = L10n.Setting.Browser.Style.title
        self.browserStyleButton.setTitle(self.viewModel.currentBrowserStyle, for: .normal)
        
        self.planningFinishLabel.text = L10n.Setting.Planning.Finish.title
        self.planningFinishButton.setTitle(self.viewModel.getPlanning(isForFinished: true).joined(separator: ","), for: .normal)
        self.planningUnfinishLabel.text = L10n.Setting.Planning.Unfinish.title
        self.planningUnfinishButton.setTitle(self.viewModel.getPlanning(isForFinished: false).joined(separator: ","), for: .normal)
        
        self.exportShowIndexLabel.text = L10n.Setting.Export.showIndex
        self.exportShowIndexSwitch.isOn = self.viewModel.exportShowIndex
        
        self.attachmentManagerLabel.text = L10n.Setting.ManageAttachment.title
        
        self.resetPublishLoginInfo.text = L10n.Publish.deleteSavedPublishInfo
        
        self.feedbackLabel.text = L10n.Setting.feedback
        self.feedbackButton.setTitle("", for: .normal)
    }
    
    private func _setupUI() {
        self.tableView.contentInset = .init(top: 0, left: 0, bottom: 80, right: 0)
        self.title = L10n.Setting.title
        
        self.tableView.separatorStyle = .none
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.SFSymbols.chevronDown.image,
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(self._cancel))
        
        self.interface { [weak self] (me, theme) in
            me.setNeedsStatusBarAppearanceUpdate()
            self?.view.backgroundColor = theme.color.background1
            self?.isSyncEnabledLabel.textColor = theme.color.interactive
            self?.storeLocationButton.setTitleColor(theme.color.descriptive, for: .normal)
            
            self?.interfaceStyleLabel.textColor = theme.color.interactive
            self?.interfaceStyleButton.setTitleColor(theme.color.descriptive, for: .normal)
            
            self?.browserStyleLabel.textColor = theme.color.interactive
            self?.browserStyleButton.setTitleColor(theme.color.descriptive, for: .normal)
            
            self?.landingTabTitleLabel.textColor = theme.color.interactive
            self?.chooseLandingTabButton.setTitleColor(theme.color.descriptive, for: .normal)
            self?.landingTabRow.tintColor = theme.color.descriptive
            
            self?.planningFinishLabel.textColor = theme.color.interactive
            self?.planningFinishButton.setTitleColor(theme.color.descriptive, for: .normal)
            self?.planningUnfinishLabel.textColor = theme.color.interactive
            self?.planningUnfinishButton.setTitleColor(theme.color.descriptive, for: .normal)
            
            self?.exportShowIndexLabel.textColor = theme.color.interactive
            self?.exportShowIndexSwitch.onTintColor = theme.color.spotlight
            
            self?.attachmentManagerLabel.textColor = theme.color.interactive
            
            self?.attachmentManagerLabel.textColor = theme.color.interactive

            self?.resetPublishLoginInfo.textColor = theme.color.interactive
        }
        
        let button = UIButton()
        button.setImage(UIImage(named: "AppIcon")?.resize(upto: CGSize(width: 44, height: 44)), for: .normal)
        let rightButton = UIBarButtonItem(customView: button)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            self?._showFeedbackOptions(from: button)
        }).disposed(by: self.disposeBag)
        self.navigationItem.rightBarButtonItem = rightButton
        
        self.privacyButton.setTitle(L10n.Setting.privacy, for: .normal)
        self.privacyButton.rx.tap.subscribe(onNext: {
            HelpPage.privacyPolicy.open(from: self)
        }).disposed(by: self.disposeBag)
        
        self.privacyButton.interface { (view, theme) in
            let button = view as! UIButton
            button.setTitleColor(theme.color.spotlight, for: .normal)
        }
        
        self.browserStyleButton.rx.tap.subscribe(onNext: { [weak self] in
            if let strongSelf = self {
                strongSelf.showBrowserStyleSelector(from: strongSelf.browserStyleButton)
            }
        }).disposed(by: self.disposeBag)
        
        self.feedbackButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?._showFeedbackOptions(from: button)
        }).disposed(by: self.disposeBag)
        
        self.termsOfServiceButton.setTitle(L10n.Setting.terms, for: .normal)
        self.termsOfServiceButton.rx.tap.subscribe(onNext: {
            HelpPage.termsOfService.open(from: self)
        }).disposed(by: self.disposeBag)
        self.termsOfServiceButton.interface { (view, theme) in
            let button = view as! UIButton
            button.setTitleColor(theme.color.spotlight, for: .normal)
        }
    }
    
//    public override var preferredStatusBarStyle: UIStatusBarStyle {
//        return InterfaceTheme.statusBarStyle
//    }
    
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return L10n.Setting.General.title
        case 2: return L10n.Setting.Planning.title
        case 3: return L10n.Setting.Store.title
        case 4: return L10n.Setting.Export.title
        default: return nil
        }
    }
    
    private func _showFeedbackOptions(from: UIView) {
        let selector = SelectorViewController()
        selector.title = L10n.Setting.Feedback.title
        selector.addItem(title: L10n.Setting.feedback)
        selector.addItem(title: L10n.Setting.Feedback.rate)
        selector.addItem(title: L10n.Setting.Feedback.promot)
        selector.addItem(title: L10n.Setting.Feedback.forum)
        selector.onCancel = { viewController in
            viewController.dismiss(animated: true)
        }
        
        selector.onSelection = { selection, viewController in
            switch selection {
            case 0:
                let appId = "11641"
                let appKey = "k2q6pHh2ekAbQjELagm2VZ3rHJFHEj3bl1GI529FjaDO29hfwLcn5sJ9jBSVA24Q"
                
                viewController.dismiss(animated: true) {
                    let feedback = Doorbell.init(apiKey: appKey, appId: appId)
                    feedback!.showFeedbackDialog(in: self, completion: { (error, cancelled) -> Void in
                        if (error?.localizedDescription != nil) {
                            print(error!.localizedDescription);
                        }
                    })
                }
            case 1:
                SKStoreReviewController.requestReview()
            case 2:
                if let name = URL(string: "https://itunes.apple.com/app/id1501111134"), !name.absoluteString.isEmpty {
                    let objectsToShare = [name]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    activityVC.popoverPresentationController?.sourceView = viewController.view
                    activityVC.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 500, height: 600)
                    viewController.present(activityVC, animated: true, completion: nil)
                }
            case 3:
                UIApplication.shared.open(URL(string: "https://forum.nebulaapp.net/")!, options: [:], completionHandler: nil)
            default: break
            }
        }
        
        selector.present(from: self, at: from)
    }
        
    @objc private func _cancel() {
        self.viewModel.context.coordinator?.stop()
    }
    
    private func _setupObserver() {
        self.storeLocationButton.addTarget(self, action: #selector(_storeLocationButtonTapped), for: .touchUpInside)
        self.interfaceStyleButton.addTarget(self, action: #selector(_interfaceStyleButtonTapped), for: .touchUpInside)
        self.chooseLandingTabButton.addTarget(self, action: #selector(_showLandingTabNamesSelector), for: .touchUpInside)
        self.planningFinishButton.addTarget(self, action: #selector(_planningManageFinish), for: .touchUpInside)
        self.planningUnfinishButton.addTarget(self, action: #selector(_planningManageUnfinish), for: .touchUpInside)
    }
    
    @objc private func _storeLocationButtonTapped(_ button: UIButton) {
        let titles = [L10n.Setting.StoreLocation.iCloud, L10n.Setting.StoreLocation.onDevice]
        let selector = SelectorViewController()
        
        let isUsingiCloud = button.titleLabel?.text == L10n.Setting.StoreLocation.iCloud
        let isSyncingInprogress = self.viewModel.dependency.syncManager.isThereAnyFileDownloading
        let shouldDisableSelections = isUsingiCloud && isSyncingInprogress
        
        titles.forEach {
            var title = $0
            
            if title == L10n.Setting.StoreLocation.iCloud && shouldDisableSelections {
                title = title + " (\(L10n.Setting.syncingInProgress))"
            }
            
            selector.addItem(title: title, enabled: !shouldDisableSelections)
        }

        selector.currentTitle = button.titleLabel?.text
        selector.onCancel = { $0.dismiss(animated: true) }
        selector.title = L10n.Setting.storeLocation
        selector.fromView = button.superview
        selector.onSelection = { index, viewController in
            
            let doSwitchAction = {
                button.showProcessingAnimation()
                
                self.showLoading()
                self.viewModel.setSyncEnabled(index == 0, completion: { [weak self] result in
                    self?.hideLoading { [weak self] in
                        button.hideProcessingAnimation()
                        
                        switch result {
                        case .failure(let error):
                            
                            if case let error = error as? SyncError, error == .iCloudIsNotAvailable {
                                self?.showAlert(title: L10n.Setting.Alert.IcloudIsNotEnabled.title,
                                                message: L10n.Setting.Alert.IcloudIsNotEnabled.msg)
                            } else {
                                self?.showAlert(title: L10n.Setting.Alert.failToStoreIniCloud, message: "\(error.localizedDescription)")
                            }
                            
                        case .success:
                            button.setTitle(titles[index], for: .normal)
                        }
                    }
                })
            }
            
            viewController.dismiss(animated: true) {
                
                if index == 1 {
                    let confirm = ConfirmViewController(contentText: L10n.Sync.Alert.Account.switchOff, onConfirm: { viewController in
                        viewController.dismiss(animated: true) {
                            doSwitchAction()
                        }
                    }) { viewController in
                        viewController.dismiss(animated: true)
                    }
                    
                    confirm.present(from: self, at: button)
                } else {
                    doSwitchAction()
                }
                
            }
            
        }
        
        self.present(selector, animated: true)
    }
    
    /// user interface style
    @objc private func _interfaceStyleButtonTapped(_ view: UIView) {
        let selector = SelectorViewController()
        selector.title = L10n.Setting.InterfaceStyle.title
        
        selector.fromView = view
        
        let styles = [SettingsAccessor.InterfaceStyle.dark,
        SettingsAccessor.InterfaceStyle.light,
        SettingsAccessor.InterfaceStyle.auto]
        
        selector.currentTitle = self.viewModel.interfaceStyle.localizedTitle
        
        selector.addItem(title: styles[0].localizedTitle)
        selector.addItem(title: styles[1].localizedTitle)
        
        if #available(iOS 13, *) {
            selector.addItem(title: styles[2].localizedTitle)
        }
        
        selector.onCancel = { viewController in
            viewController.dismiss(animated: true)
        }
        
        selector.onSelection = { index, viewController in
            viewController.dismiss(animated: true)
            self.viewModel.setInterfaceStyle(styles[index])
            self.interfaceStyleButton.setTitle(styles[index].localizedTitle, for: .normal)
        }
        
        selector.present(from: self, at: view)
    }
    
    private func showBrowserStyleSelector(from: UIView) {
        let selector = SelectorViewController()
        
        selector.addItem(title: BrowserViewModel.listSmall.title)
        selector.addItem(title: BrowserViewModel.icon.title)
        selector.currentTitle = self.viewModel.currentBrowserStyle
        
        selector.onCancel = {
            $0.dismiss(animated: true)
        }
        
        selector.onSelection = { index, viewController in
            viewController.dismiss(animated: true) {
                switch index {
                case 0: self.viewModel.dependency.settingAccessor.setSetting(item: .browserCellMode, value: BrowserViewModel.listSmall.title, completion: { [weak self] in
                    DispatchQueue.main.async {
                        self?.browserStyleButton.setTitle(BrowserViewModel.listSmall.title, for: .normal)
                    }
                })
                case 1: self.viewModel.dependency.settingAccessor.setSetting(item: .browserCellMode, value: BrowserViewModel.icon.title, completion: { [weak self] in
                    DispatchQueue.main.async {
                        self?.browserStyleButton.setTitle(BrowserViewModel.icon.title, for: .normal)
                    }
                })
                default: break
                }
            }
        }
                    
        selector.present(from: self, at: from)
    }
    
    @objc private func _showLandingTabNamesSelector(from: UIView) {
        let selector = SelectorViewController()
        let tabs = TabIndex.allCases

        for tab in tabs {
            selector.addItem(icon: tab.icon, title: tab.name)
        }
        
        selector.fromView = self.landingTabRow
        selector.title = L10n.Setting.LandingTab.title
        
        selector.onCancel = { viewController in
            viewController.dismiss(animated: true)
        }
        
        selector.onSelection = { index, viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.setLandingTabIndex(tabs[index].index)
            self.chooseLandingTabButton.setTitle(tabs[index].name, for: .normal)
        }
        
        selector.currentTitle = tabs[self.viewModel.currentLandigTabIndex].name
        
        selector.present(from: self, at: from)
    }
    
    @objc func _planningManageFinish(from: UIView) {
        self._planningManage(isFinish: true, from: from)
    }
    
    @objc func _planningManageUnfinish(from: UIView) {
        self._planningManage(isFinish: false, from: from)
    }
    
    @IBAction func exportShowIndex(_ sender: UISwitch) {
        self.viewModel.setExportShowIndex(sender.isOn) {}
    }
    private func _planningManage(isFinish: Bool, from: UIView) {
        let plannings = self.viewModel.getPlanning(isForFinished: isFinish)
        
        let actionsViewController = ActionsViewController()
        
        actionsViewController.title = isFinish
        ? self.planningFinishLabel.text
        : self.planningUnfinishLabel.text
        
        for planning in plannings {
            let canDelete = !self.viewModel.defaultPlannings.contains(planning)
            let icon =  canDelete ? Asset.SFSymbols.xmark.image.fill(color: InterfaceTheme.Color.warning) : nil
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
            viewController.dismiss(animated: true)
        }
        
        let addTitle = isFinish ? L10n.Setting.Planning.Finish.add :  L10n.Setting.Planning.Unfinish.add

        let icon = self.viewModel.isMember ? Asset.SFSymbols.plus.image.fill(color: InterfaceTheme.Color.spotlight) : Asset.Assets.proLabel.image
        actionsViewController.addAction(icon: icon, title: addTitle, style: .highlight) { [unowned self] viewController in
            viewController.dismiss(animated: true, completion: {
                
                if !self.viewModel.isMember {
                    self.viewModel.context.coordinator?.showMembership()
                    return
                }
                
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
                }
                
                formViewController.onSaveValue = { [unowned self] data, viewController in
                    
                    if let newPlanning = data[addTitle] as? String {
                        self.viewModel.addPlanning(newPlanning, isForFinished: isFinish, completion: {
                            viewController.dismiss(animated: true, completion: { [weak self] in
                                guard let strongSelf = self else { return }
                                let buttonToUpdate = isFinish ?
                                strongSelf.planningFinishButton : strongSelf.planningUnfinishButton
                                
                                buttonToUpdate?.setTitle(strongSelf.viewModel.getPlanning(isForFinished: isFinish).joined(separator: ","), for: .normal)
                                
                                strongSelf.viewModel.dependency.editorContext.reloadParser() // 因为解析器的常亮以改变，需要重载解析器
                            })
                        })
                    }
                }
                
                self.present(formViewController, animated: true, completion: nil)
            })
        }
        
        actionsViewController.present(from: self, at: from)
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            self._showFeedbackOptions(from: cell)
        case (1, 0):
            self._showLandingTabNamesSelector(from: cell)
        case (1, 1):
            self._interfaceStyleButtonTapped(cell)
        case (1, 2):
            self.showBrowserStyleSelector(from: cell)
        case (2, 0):
            self._planningManageFinish(from: cell)
        case (2, 1):
            self._planningManageUnfinish(from: cell)
        case (3, 0):
            self._storeLocationButtonTapped(self.storeLocationButton)
        case (3, 1):
            self.viewModel.context.coordinator?.showAttachmentManager()
        case (4, 1):
            let viewController = ConfirmViewController(contentText: L10n.Publish.DeleteSavedPublishInfo.confirm) { (viewController) in
                viewController.dismiss(animated: true) {
                    self.viewModel.clearAllTokens {
                        self.showAlert(title: L10n.Publish.DeleteSavedPublishInfo.feedback, message: "")
                    }
                }
            } onCancel: { viewController in
                viewController.dismiss(animated: true)
            }
                
            viewController.present(from: self, at: cell, completion: nil)
        default: break
        }
    }
}

extension SettingsViewController: SettingsViewModelDelegate {
    public func didUpdateUnfoldWhenOpen(unfold: Bool) {
        
    }
    
    public func didSetInterfaceStyle(newStyle: SettingsAccessor.InterfaceStyle) {
        // avoid dead lock for file coordiantor
        DispatchQueue.main.async {
            self.setupTheme()
        }
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
