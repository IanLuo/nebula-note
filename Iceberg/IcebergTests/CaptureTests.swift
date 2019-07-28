//
//  CaptureTests.swift
//  IcelandTests
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import XCTest
@testable import Iceberg
import Business
import RxSwift

public class CaptureTests: XCTestCase {
    public override func tearDown() {
        KeyValueStoreFactory.store(type: .plist(.custom("capture"))).clear {}
    }
    
//    func testInsertCapture() throws {
//        let service = CaptureService()
//        
//        let ex = expectation(description: "")
//        
//        service.save(content: "some text", type: .text, description: "text", completion: { _ in
//            service.loadAll(completion:{
//                XCTAssert($0.count == 1)
//                ex.fulfill()
//            }, failure: { _ in
//                XCTAssert(false)
//            })
//        }, failure: { _ in
//            XCTAssert(false)
//        })
//        
//        wait(for: [ex], timeout: 5)
//    }
//    
//    func testLoadCapture() {
//        let service = CaptureService()
//        
//        service.save(content: "some text", type: .text, description: "text", completion: { _ in }, failure: { _ in })
//        service.save(content: "some text", type: .text, description: "text", completion: { _ in }, failure: { _ in })
//        service.save(content: "some text", type: .text, description: "text", completion: { _ in }, failure: { _ in })
//        service.save(content: "some text", type: .text, description: "text", completion: { _ in }, failure: { _ in })
//        
//        let ex = expectation(description: "")
//        
//        service.loadAll(completion: {
//            XCTAssert($0.count == 4)
//            ex.fulfill()
//        }, failure: { _ in
//            XCTAssert(false)
//        })
//        
//        wait(for: [ex], timeout: 5)
//    }
//    
//    
//    func testRemoveCapture() {
//        let service = CaptureService()
//        
//        service.save(content: "some text", type: .text, description: "text", completion: { _ in }, failure: { _ in })
//        service.save(content: "some text", type: .text, description: "text", completion: { _ in }, failure: { _ in })
//        service.save(content: "some text", type: .text, description: "text", completion: { _ in }, failure: { _ in })
//        service.save(content: "some text", type: .text, description: "text", completion: { _ in }, failure: { _ in })
//        
//        let ex = expectation(description: "")
//        
//        service.loadAll(completion: {
//            $0.forEach {
//                service.delete(key: $0.key)
//            }
//        }, failure: { _ in
//            XCTAssert(false)
//        })
//        
//        service.loadAll(completion: {
//            XCTAssert($0.count == 0)
//            ex.fulfill()
//        }, failure: { (_) in
//            XCTAssert(false)
//        })
//        
//        wait(for: [ex], timeout: 5)
//    }
}
