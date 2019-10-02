//
//  BrowserCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import RxSwift

public protocol BrowserCoordinatorDelegate: class {
    func didSelectDocument(url: URL, coordinator: BrowserCoordinator)
    func didSelectHeading(url: URL, heading: DocumentHeading, coordinator: BrowserCoordinator)
    func didCancel(coordinator: BrowserCoordinator)
}

public class BrowserCoordinator: Coordinator {
    public enum Usage {
        case browseDocument
        case chooseHeader
        
        var browserFolderMode: BrowserFolderViewModel.Mode {
            switch self {
            case .browseDocument: return .browser
            case .chooseHeader: return .chooser
            }
        }
    }
    
    public let usage: Usage
    public weak var delegate: BrowserCoordinatorDelegate?
    
    public var didSelectDocumentAction: ((URL) -> Void)?
    public var didSelectHeadingAction: ((URL, DocumentHeading) -> Void)?
    public var didCancelAction: (() -> Void)?
    
    private let disposeBag = DisposeBag()
    
    public init(stack: UINavigationController, dependency: Dependency, usage: Usage) {
        let browserFolderViewModel = BrowserFolderViewModel(url: URL.documentBaseURL, mode: usage.browserFolderMode)
        let browserFolderViewController = BrowserFolderViewController(viewModel: browserFolderViewModel)
        
        let browseRecentViewModel = BrowserRecentViewModel()
        let browseRecentViewController = BrowserRecentViewController(viewModel: browseRecentViewModel)
        
        let browseViewController = BrowserViewController(recentViewController: browseRecentViewController,
                                                         browserFolderViewController: browserFolderViewController)
        
        self.usage = usage
        super.init(stack: stack, dependency: dependency)
        
        browserFolderViewModel.coordinator = self
        browseRecentViewModel.coordinator = self
        
        self.viewController = browseViewController
        
        // binding
        browserFolderViewController.output.onSelectDocument.subscribe(onNext: { url in
            switch self.usage {
            case .browseDocument:
                self.delegate?.didSelectDocument(url: url, coordinator: self)
                self.didSelectDocumentAction?(url)
            case .chooseHeader:
                self.showOutlineHeadings(url: url)
            }
        }).disposed(by: self.disposeBag)
        
        browseViewController.output.canceld.subscribe(onNext: {
            self.delegate?.didCancel(coordinator: self)
            self.didCancelAction?()
        }).disposed(by: self.disposeBag)
        
        browseRecentViewController.output.choosenDocument.subscribe(onNext: { url in
            switch self.usage {
            case .browseDocument:
                self.delegate?.didSelectDocument(url: url, coordinator: self)
                self.didSelectDocumentAction?(url)
            case .chooseHeader:
                self.showOutlineHeadings(url: url)
            }
        }).disposed(by: self.disposeBag)
    }
    
    public func showOutlineHeadings(url: URL) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        navigationController.isNavigationBarHidden = true
        
        let editorCoord = EditorCoordinator(stack: navigationController,
                                            dependency: self.dependency,
                                            usage: .outline(url, nil))
        editorCoord.delegate = self
        editorCoord.start(from: self)
    }
}

extension BrowserCoordinator: EditorCoordinatorSelectHeadingDelegate {
    public func didSelectHeading(url: URL, heading: DocumentHeading, coordinator: EditorCoordinator) {
        coordinator.stop {
            self.delegate?.didSelectHeading(url: url, heading: heading, coordinator: self)
            self.didSelectHeadingAction?(url, heading)
        }
    }
    
    public func didCancel(coordinator: EditorCoordinator) {
        coordinator.stop()
    }
}
