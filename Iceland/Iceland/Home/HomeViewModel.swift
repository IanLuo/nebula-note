//
//  HomeViewModel.swift
//  Iceland
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public class HomeViewModel {
    public weak var dependency: HomeCoordinator?
    
    public func showbrowser() {
        dependency?.showBrowser()
    }
    
    public func showCaptureImage() {
        dependency?.showImageCapture()
    }
}
