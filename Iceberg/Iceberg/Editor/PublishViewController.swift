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
    private let viewModel: DocumentEditViewModel
    
    private let platform: BehaviorRelay<PublishFactory.Publisher?> = BehaviorRelay(value: nil)
    private let uploader: BehaviorRelay<PublishFactory.Uploader?> = BehaviorRelay(value: nil)
    
    public init(url: URL, viewModel: DocumentEditViewModel) {
        self.url = url
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.close, target: nil, action: nil)
        closeButton.rx.tap.subscribe(onNext: {
            self.dismiss(animated: true)
        }).disposed(by: self.disposeBag)
        
        self.navigationItem.rightBarButtonItem = closeButton
        
        let titleLabel = UILabel(text: L10n.Publish.title).font(InterfaceTheme.Font.largeTitle).textColor(InterfaceTheme.Color.interactive)
        
        self.view.addSubview(titleLabel)
        titleLabel.sideAnchor(for: .top, to: self.view, edgeInset: Layout.innerViewEdgeInsets.top, considerSafeArea: true)
        titleLabel.centerAnchors(position: .centerX, to: self.view)
        
        let choosePlatformLabel = UILabel(text: L10n.Publish.Platform.pick)
            .font(InterfaceTheme.Font.title)
            .textColor(InterfaceTheme.Color.interactive)
        
        let choosePlatformButton = UIButton().roundConer(radius: 8)
        choosePlatformButton.sizeAnchor(width: 200, height: 80)
        
        let chooseUploadServiceLabel = UILabel(text: L10n.Publish.Attachment.storageService)
            .font(InterfaceTheme.Font.title)
            .textColor(InterfaceTheme.Color.interactive)
        
        let chooseUploadServiceButton = UIButton().roundConer(radius: 8)
        chooseUploadServiceButton.sizeAnchor(width: 200, height: 80)
        
        self.interface { (me, interface) in
            choosePlatformButton.backgroundImage(interface.color.spotlight, for: .normal)
            chooseUploadServiceButton.backgroundImage(interface.color.spotlight, for: .normal)
        }
        
        self.view.addSubview(choosePlatformLabel)
        self.view.addSubview(choosePlatformButton)
        titleLabel.columnAnchor(view: choosePlatformLabel, space: 30, alignment: .centerX)
        choosePlatformLabel.columnAnchor(view: choosePlatformButton, space: 12, alignment: .centerX)
        
        
        self.view.addSubview(chooseUploadServiceLabel)
        self.view.addSubview(chooseUploadServiceButton)
        choosePlatformButton.columnAnchor(view: chooseUploadServiceLabel, space: 30, alignment: .centerX)
        chooseUploadServiceLabel.columnAnchor(view: chooseUploadServiceButton, space: 12, alignment: .centerX)
        
        // -- observers
        
        choosePlatformButton.rx.tap.subscribe(onNext: {
            
        }).disposed(by: self.disposeBag)
        
        self.platform.map({ publisher in
            if let publisher = publisher {
                return publisher.title
            } else {
                return "Choose"
            }
        }).bind(to: choosePlatformButton.rx.title(for: .normal)).disposed(by: self.disposeBag)
        
        self.uploader.map({ uploader in
            if let uploader = uploader {
                return uploader.title
            } else {
                return "Choose"
            }
        }).bind(to: chooseUploadServiceButton.rx.title(for: .normal)).disposed(by: self.disposeBag)
        
    }
    
    
}


