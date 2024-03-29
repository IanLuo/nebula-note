//
//  PublishViewController.swift
//  x3Note
//
//  Created by ian luo on 2020/11/8.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import RxSwift
import RxCocoa
import Core

public class PublishViewController: UIViewController {
    public let url: URL
    private let disposeBag: DisposeBag = DisposeBag()
    private let viewModel: DocumentEditorViewModel
    
    private let platform: BehaviorRelay<PublishFactory.Publisher?> = BehaviorRelay(value: nil)
    private let uploader: BehaviorRelay<PublishFactory.Uploader?> = BehaviorRelay(value: nil)
    
    public init(url: URL, viewModel: DocumentEditorViewModel) {
        self.url = url
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: nil, action: nil)
        closeButton.rx.tap.subscribe(onNext: {
            self.dismiss(animated: true)
        }).disposed(by: self.disposeBag)
        
        self.navigationItem.rightBarButtonItem = closeButton
        
        let container: UIScrollView = UIScrollView()
        
        self.view.addSubview(container)
        container.allSidesAnchors(to: self.view, edgeInset: 0, considerSafeArea: true)
        
        let titleLabel = UILabel(text: L10n.Publish.title).font(InterfaceTheme.Font.largeTitle).textColor(InterfaceTheme.Color.interactive)
        
        container.addSubview(titleLabel)
        titleLabel.sideAnchor(for: .top, to: container, edgeInset: Layout.innerViewEdgeInsets.top)
        titleLabel.centerAnchors(position: .centerX, to: container)
        
        let choosePlatformLabel = UILabel(text: L10n.Publish.Platform.pick)
            .font(InterfaceTheme.Font.title)
            .textColor(InterfaceTheme.Color.interactive)
        
        let choosePlatformDescriptionLabel = UILabel(text: L10n.Publish.Platform.description)
            .font(InterfaceTheme.Font.title)
            .numberOfLines(0)
            .textAlignment(.center)
            .textColor(InterfaceTheme.Color.descriptive)
        
        let choosePlatformButton = UIButton().roundConer(radius: 8).titleColor(InterfaceTheme.Color.interactive, for: .normal)
        choosePlatformButton.sizeAnchor(width: 200, height: 80)
        
        let chooseUploadServiceLabel = UILabel(text: L10n.Publish.Attachment.storageService)
            .font(InterfaceTheme.Font.title)
            .textColor(InterfaceTheme.Color.interactive)
        
        let chooseUploadServiceDescriptionLabel = UILabel(text: L10n.Publish.Attachment.StorageService.description)
            .font(InterfaceTheme.Font.title)
            .numberOfLines(0)
            .textAlignment(.center)
            .textColor(InterfaceTheme.Color.descriptive)
        
        let chooseUploadServiceButton: UIButton = UIButton().roundConer(radius: 8).titleColor(InterfaceTheme.Color.interactive, for: .normal)
        chooseUploadServiceButton.sizeAnchor(width: 200, height: 80)
        
        self.interface { (me, interface) in
            choosePlatformButton.backgroundImage(interface.color.background2, for: .normal)
            chooseUploadServiceButton.backgroundImage(interface.color.background2, for: .normal)
        }
        
        container.addSubview(choosePlatformLabel)
        container.addSubview(choosePlatformDescriptionLabel)
        container.addSubview(choosePlatformButton)
        titleLabel.columnAnchor(view: choosePlatformLabel, space: 30, alignment: .centerX)
        choosePlatformLabel.columnAnchor(view: choosePlatformDescriptionLabel, space: 20, alignment: .centerX)
        choosePlatformDescriptionLabel.columnAnchor(view: choosePlatformButton, space: 20, alignment: .centerX)
        choosePlatformDescriptionLabel.sideAnchor(for: [.left, .right], to: container, edgeInset: 50)
        
        let submitButton: UIButton = UIButton(title: L10n.Publish.title, for: .normal)
            .roundConer(radius: 8)
            .backgroundImage(InterfaceTheme.Color.spotlight, for: .normal)
            .titleColor(InterfaceTheme.Color.spotlitTitle, for: .normal)
        container.addSubview(submitButton)
        submitButton.sideAnchor(for: .bottom, to: container, edgeInset: 50)
        submitButton.sizeAnchor(width: 300, height: 60)
        
        if self.viewModel.attachments.count > 0 {
            container.addSubview(chooseUploadServiceLabel)
            container.addSubview(chooseUploadServiceDescriptionLabel)
            container.addSubview(chooseUploadServiceButton)
            choosePlatformButton.columnAnchor(view: chooseUploadServiceLabel, space: 30, alignment: .centerX)
            chooseUploadServiceLabel.columnAnchor(view: chooseUploadServiceDescriptionLabel, space: 30, alignment: .centerX)
            chooseUploadServiceDescriptionLabel.columnAnchor(view: chooseUploadServiceButton, space: 20, alignment: .centerX)
            chooseUploadServiceDescriptionLabel.sideAnchor(for: [.left, .right], to: container, edgeInset: 50)
            chooseUploadServiceButton.columnAnchor(view: submitButton, space: 70, alignment: .centerX)
        } else {
            choosePlatformButton.columnAnchor(view: submitButton, space: 70, alignment: .centerX)
        }
        
        
        // -- observers
        submitButton.rx.tap.subscribe(onNext: { _ in
            guard let platform = self.platform.value else { return }
            self.view.showProcessingAnimation(true)
            
            self.viewModel.dependency.exportManager.export(isMember: true, url: self.viewModel.url, type: platform.exportFileType, useDefaultStyle: false) { [unowned self] url in
                do {
                    let attachments = self.viewModel.attachments
                    
                    let publishable = self.viewModel
                        .dependency
                        .publishFactory
                        .createPublishBuilder(publisher: platform,
                                              uploader: self.uploader.value,
                                              from: self)
                    
                    publishable(url.packageName, try String(contentsOf: url), attachments)
                        .observeOn(MainScheduler())
                        .subscribe(onNext: {
                            self.view.hideProcessingAnimation()
                            self.showAlert(title: L10n.General.success, message: "\"\(self.viewModel.url.packageName)\" \(L10n.Publish.complete(platform.title))")
                        }, onError: { error in
                            var errorMessage = error.localizedDescription
                            
                            if errorMessage.contains("Network") {
                                errorMessage = L10n.Fail.network
                            } else if errorMessage.contains("failToUpload") {
                                errorMessage = L10n.Fail.upload
                            }
                            
                            self.showAlert(title: L10n.General.fail, message: "\(errorMessage)")
                            self.view.hideProcessingAnimation()
                        })
                        .disposed(by: self.disposeBag)
                } catch {
                    self.showAlert(title: L10n.General.fail, message: "\(error)")
                    self.view.hideProcessingAnimation()
                }
            } failure: { error in
                self.showAlert(title: L10n.General.fail, message: "\(error)")
                self.view.hideProcessingAnimation()
            }
        }).disposed(by: self.disposeBag)
        
        choosePlatformButton.rx.tap.subscribe(onNext: { [unowned choosePlatformButton] in
            let selector = SelectorViewController()
            for item in PublishFactory.Publisher.allCases.map({ $0.title }) {
                selector.addItem(title: item)
            }
            selector.onCancel = {
                $0.dismiss(animated: true)
            }
            selector.onSelection = { index, viewController in
                viewController.dismiss(animated: true) {
                    self.platform.accept(PublishFactory.Publisher.allCases[index])
                }
            }

            selector.present(from: self, at: choosePlatformButton)
        }).disposed(by: self.disposeBag)
        
        chooseUploadServiceButton.rx.tap.subscribe(onNext: { [unowned chooseUploadServiceButton] in
            let selector = SelectorViewController()
            for item in PublishFactory.Uploader.allCases.map({ $0.title }) {
                selector.addItem(title: item)
            }
            selector.onCancel = {
                $0.dismiss(animated: true)
            }
            selector.onSelection = { index, viewController in
                viewController.dismiss(animated: true) {
                    self.uploader.accept(PublishFactory.Uploader.allCases[index])
                }
            }

            selector.present(from: self, at: chooseUploadServiceButton)
        }).disposed(by: self.disposeBag)
        
        self.platform.map({ publisher in
            if let publisher = publisher {
                return publisher.title
            } else {
                return L10n.Publish.choose
            }
        }).bind(to: choosePlatformButton.rx.title(for: .normal)).disposed(by: self.disposeBag)
        
        self.uploader.map({ uploader in
            if let uploader = uploader {
                return uploader.title
            } else {
                return L10n.Publish.choose
            }
        }).bind(to: chooseUploadServiceButton.rx.title(for: .normal)).disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.platform, self.uploader).map ({ (publisher, uploader) -> Bool in
            return publisher != nil && (self.viewModel.attachments.count == 0 || uploader != nil)
        }).bind(to: submitButton.rx.isEnabled).disposed(by: self.disposeBag)
        
    }
    
    
}


