//
//  CaptureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import RxSwift

public protocol CaptureListViewModelDelegate: class {
    func didLoadData()
    func didDeleteCapture(index: Int)
    func didFail(error: Error)
    func didRefileAttachment(index: Int)
    func didRefileFile(index: Int)
}

public class CaptureListViewModel {
    public typealias Dependency = CaptureCoordinator
    public weak var delegate: CaptureListViewModelDelegate?
    public weak var dependency: Dependency?
    
    private let service: CaptureServiceProtocol
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    public var data: [Attachment] = []
    
    public init(service: CaptureServiceProtocol) {
        self.service = service
    }
    
    public func loadAllCapturedData() {
        self.service
            .loadAll()
            .subscribe(onNext: { [weak self] data in
                self?.data = data
                self?.delegate?.didLoadData()
            }, onError: { [weak self] error in
                self?.delegate?.didFail(error: error)
            }
        ).disposed(by: self.disposeBag)
    }
    
    public func delete(index: Int) {
        self.service
            .delete(key: self.data[index].key)
            .subscribe(onNext: { [weak self] in
                self?.delegate?.didDeleteCapture(index: index)
                }, onError: { [weak self] error in
                    self?.delegate?.didFail(error: error)
                }
            )
            .disposed(by: self.disposeBag)
    }
    
    public func refile(attachmentIndex: Int) {
        self.dependency?.openDocumentBrowserForRefile()
    }
}
