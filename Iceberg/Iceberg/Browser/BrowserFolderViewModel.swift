//
//  BrowserFolderViewModel.swift
//  Iceberg
//
//  Created by ian luo on 2019/9/12.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift

public class BrowserFolderViewModel {
    public let url: URL
    public weak var coordinator: BrowserCoordinator!
    
    init(url: URL, coordinator: BrowserCoordinator) {
        self.url = url
        self.coordinator = coordinator
    }
    
    public let files: Variable<[DocumentBrowserCellModel]> = Variable([])
    
    public let onError: PublishSubject<Error> = PublishSubject()
    
    public func loadFiles() {
        do {
            let files = try self.coordinator.dependency.documentManager.query(in: URL.documentBaseURL).map { [unowned self] (url: URL) -> DocumentBrowserCellModel in
                let cellModel = DocumentBrowserCellModel(url: url)
                cellModel.shouldShowActions = self.shouldShowActions
                cellModel.shouldShowChooseHeadingIndicator = self.shouldShowHeadingIndicator
                cellModel.cover = self.coordinator.dependency.documentManager.cover(url: url)
                return cellModel
            }
            self.files.value = files
        } catch {
            log.error(error)
            self.onError.on(.next(error))
        }
    }
    
    public var shouldShowActions: Bool {
        return self.coordinator?.usage == .chooseDocument
    }
    
    public var shouldShowHeadingIndicator: Bool {
        return self.coordinator?.usage == .chooseHeading
    }
}
