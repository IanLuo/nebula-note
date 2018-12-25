//
//  AgendaCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

/// 用户的活动中心
/// 1. 每天的任务安排显示在此处
/// 2. capture 的内容显示在此处

/// 不管是任务，还是 capture 的内容，都可以直接编辑，可以使用 document 中的格式，方便临时的任务记录
public class AgendaCoordinator: Coordinator {
    public var viewController: UIViewController
    
    public override init(stack: UINavigationController) {
        let viewModel = AgendaViewModel()
        let viewController = AgendaViewController(viewModel: viewModel)
        self.viewController = viewController
        super.init(stack: stack)
        viewModel.delegate = viewController
        viewModel.dependency = self
    }
    
    public override func start() {
        self.stack.pushViewController(viewController, animated: true)
    }
}

extension AgendaCoordinator {
    public func openDocument(url: URL, location: Int) {
        let docCood = DocumentCoordinator(stack: self.stack, usage: .editor(url, location))
        self.addChild(docCood)
        docCood.start()
    }
    
    public func search(due: Date,
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failure: @escaping (Error) -> Void) {
        let searchCood = DocumentCoordinator(stack: self.stack, usage: .search)
        self.addChild(searchCood)
        searchCood.searchHeadings(by: .due(due), resultAdded: resultAdded, complete: {
            self.remove(searchCood)
            complete()
        }) {
            self.remove(searchCood)
            failure($0)
        }
    }
    
    public func search(schedule: Date,
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failure: @escaping (Error) -> Void) {
        let searchCood = DocumentCoordinator(stack: self.stack, usage: .search)
        self.addChild(searchCood)
        searchCood.searchHeadings(by: .schedule(schedule), resultAdded: resultAdded, complete: {
            self.remove(searchCood)
            complete()
        }) {
            self.remove(searchCood)
            failure($0)
        }
    }
    
    public func search(planning: [String],
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failure: @escaping (Error) -> Void) {
        let searchCood = DocumentCoordinator(stack: self.stack, usage: .search)
        self.addChild(searchCood)
        searchCood.searchHeadings(by: .planning(planning), resultAdded: resultAdded, complete: {
            self.remove(searchCood)
            complete()
        }) {
            self.remove(searchCood)
            failure($0)
        }
    }
    
    public func search(tags: [String],
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failure: @escaping (Error) -> Void) {
        let searchCood = DocumentCoordinator(stack: self.stack, usage: .search)
        self.addChild(searchCood)
        searchCood.searchHeadings(by: .tags(tags), resultAdded: resultAdded, complete: {
            self.remove(searchCood)
            complete()
        }) {
            self.remove(searchCood)
            failure($0)
        }
    }
    
    public func refileTo(url: URL,
                         content: String,
                         headingLocation: Int,
                         complete: @escaping () -> Void,
                         failure: @escaping (Error) -> Void) {
        let docCood = DocumentCoordinator(stack: self.stack, usage: .refile)
        self.addChild(docCood)
        docCood.insert(content: content, url: url, headingLocation: headingLocation, complete: {
            self.remove(docCood)
            complete()
        }, failure: {
            self.remove(docCood)
            failure($0)
        })
    }
    
    public func changePlanning(to: String,
                               url: URL,
                               headingLocation: Int,
                               complete: @escaping () -> Void,
                               failure: @escaping (Error) -> Void) {
        let docCood = DocumentCoordinator(stack: self.stack, usage: .headless)
        self.addChild(docCood)
        docCood.changePlanning(to: to, url: url, headingLocation: headingLocation, completion: {
            self.remove(docCood)
            complete()
        }, failure: {
            self.remove(docCood)
            failure($0)
        })
    }
    
    public func reschedule(to: DateAndTimeType,
                           url: URL,
                           headingLocation: Int,
                           complete: @escaping () -> Void,
                           failure: @escaping (Error) -> Void) {
        let docCood = DocumentCoordinator(stack: self.stack, usage: .headless)
        self.addChild(docCood)
        docCood.reschedule(newSchedule: to, url: url, headingLocation: headingLocation, complete: {
            self.remove(docCood)
            complete()
        }, failure: {
            self.remove(docCood)
            failure($0)
        })
    }
    
    public func changeDue(to: DateAndTimeType,
                          url: URL,
                          headingLocation: Int,
                          complete: @escaping () -> Void,
                          failure: @escaping (Error) -> Void) {
        let docCood = DocumentCoordinator(stack: self.stack, usage: .headless)
        self.addChild(docCood)
        docCood.changeDue(newDue: to, url: url, headingLocation: headingLocation, complete: {
            self.remove(docCood)
            complete()
        }, failure: {
            self.remove(docCood)
            failure($0)
        })
    }
}
