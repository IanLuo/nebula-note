//
//  CaptureTests.swift
//  IcelandTests
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import XCTest
@testable import Iceland
import Storage
import RxSwift
import Storage

public class CaptureTests: XCTestCase {
    public override func tearDown() {
        KeyValueStoreFactory.store(type: .plist(.custom("capture"))).clear()
        File.Folder.document("attachment").remove()
        File.Folder.document("capture").remove()
    }
    
    func testInsertCapture() throws {
        let service = CaptureService()
        
        let disposeBag = DisposeBag()
        service.save(content: "some text", type: .text, description: "text").subscribe().disposed(by: disposeBag)
        
        let ex = expectation(description: "")
        
        service.loadAll().subscribe(onNext: {
            XCTAssert($0.count == 1)
            ex.fulfill()
        }, onError: { _ in
            XCTAssert(false)
        }).disposed(by: disposeBag)
        
        wait(for: [ex], timeout: 5)
    }
    
    func testLoadCapture() {
        let service = CaptureService()
        let disposeBag = DisposeBag()
        
        service.save(content: "some text", type: .text, description: "text").subscribe().disposed(by: disposeBag)
        service.save(content: "some text", type: .text, description: "text").subscribe().disposed(by: disposeBag)
        service.save(content: "some text", type: .text, description: "text").subscribe().disposed(by: disposeBag)
        service.save(content: "some text", type: .text, description: "text").subscribe().disposed(by: disposeBag)
        
        let ex = expectation(description: "")
        
        service.loadAll().subscribe(onNext: {
            XCTAssert($0.count == 4)
            ex.fulfill()
        }, onError: { _ in
            XCTAssert(false)
        }).disposed(by: disposeBag)
        
        wait(for: [ex], timeout: 5)
    }
    
    
    func testRemoveCapture() {
        let service = CaptureService()
        let disposeBag = DisposeBag()
        
        service.save(content: "some text", type: .text, description: "text").subscribe().disposed(by: disposeBag)
        service.save(content: "some text", type: .text, description: "text").subscribe().disposed(by: disposeBag)
        service.save(content: "some text", type: .text, description: "text").subscribe().disposed(by: disposeBag)
        service.save(content: "some text", type: .text, description: "text").subscribe().disposed(by: disposeBag)
        
        let ex = expectation(description: "")
        
        service.loadAll().subscribe(onNext: {
            $0.forEach {
                service.delete(key: $0.key).subscribe().disposed(by: disposeBag)
            }
        }, onError: { _ in
            XCTAssert(false)
        }).disposed(by: disposeBag)
        
        service.loadAll().subscribe(onNext: {
            XCTAssert($0.count == 0)
            ex.fulfill()
        }, onError: { _ in
            XCTAssert(false)
        }).disposed(by: disposeBag)
        
        wait(for: [ex], timeout: 5)
    }
}
