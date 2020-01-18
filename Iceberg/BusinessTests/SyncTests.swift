//
//  SyncTests.swift
//  BusinessTests
//
//  Created by ian luo on 2019/3/26.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import XCTest
@testable import Core

class SyncTests: XCTestCase {
    
    override func setUp() {
        
    }
    
    func testMoveLocalFilesToiCloud() {
        let syncManager = iCloudDocumentManager(eventObserver: EventObserver())
        
        let ex = self.expectation(description: "")
        
        syncManager.geticloudContainerURL { [unowned syncManager] _ in
            syncManager.moveLocalFilesToIcloud { error in
                if let error = error {
                    ex.fulfill()
                    XCTAssert(false)
                    print(error)
                } else {
                    ex.fulfill()
                }
            }
        }
        
        self.wait(for: [ex], timeout: 10)
    }
    
    func testMoveiCloudFilesToLocal() {
        let syncManager = iCloudDocumentManager(eventObserver: EventObserver())
        
        let ex = self.expectation(description: "")
        
        syncManager.geticloudContainerURL { [unowned syncManager] _ in
            syncManager.moveiCloudFilesToLocal { error in
                if let error = error {
                    ex.fulfill()
                    XCTAssert(false)
                    print(error)
                } else {
                    ex.fulfill()
                }
            }
        }
        
        self.wait(for: [ex], timeout: 10)
    }
}
