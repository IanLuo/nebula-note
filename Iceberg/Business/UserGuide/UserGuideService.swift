//
//  UserGuideService.swift
//  Business
//
//  Created by ian luo on 2020/1/7.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import RxSwift

public struct UserGuideService {
    public func creaetGuideDocument(content: String, url: URL) -> Observable<Void> {
        return Observable.create { observer in
            
            
            
            return Disposables.create()
        }
    }
    
    private var localizedGuideFileContents: [String] {
        return []
    }
}
