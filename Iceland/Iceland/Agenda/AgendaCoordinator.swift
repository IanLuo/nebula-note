//
//  AgendaCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

/*
 用户的活动中心
 1. 每天的任务安排显示在此处
 2. capture 的内容显示在此处
 
 不管是任务，还是 capture 的内容，都可以直接编辑，可以使用 document 中的格式，方便临时的任务记录
 */
import Foundation
import UIKit

public class AgendaCoordinator: Coordinator {
    public var viewController: UIViewController
    
    public override init(stack: UINavigationController) {
        let viewModel = AgendaViewModel()
        self.viewController = AgendaViewController(viewModel: viewModel)
        super.init(stack: stack)
        viewModel.delegate = self
    }
    
    public override func start() {
        self.stack.pushViewController(viewController, animated: true)
    }
}

extension AgendaCoordinator: AgendaViewModelDelegate {
    public func openDocument(url: URL, location: Int) {
        let docCood = DocumentCoordinator(stack: self.stack, url: url, location: location)
        self.addChild(docCood)
        docCood.start()
    }
    
    public func search(due: Date, resultAdded: @escaping ([DocumentSearchResult]) -> Void, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let searchCood = DocumentCoordinator(stack: self.stack)
        self.addChild(searchCood)
        searchCood.searchHeadings(by: .due(due), resultAdded: resultAdded, complete: {
            self.remove(searchCood)
            complete()
        }) {
            self.remove(searchCood)
            failure($0)
        }
    }
    
    public func search(schedule: Date, resultAdded: @escaping ([DocumentSearchResult]) -> Void, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let searchCood = DocumentCoordinator(stack: self.stack)
        self.addChild(searchCood)
        searchCood.searchHeadings(by: .schedule(schedule), resultAdded: resultAdded, complete: {
            self.remove(searchCood)
            complete()
        }) {
            self.remove(searchCood)
            failure($0)
        }
    }
    
    public func search(planning: [String], resultAdded: @escaping ([DocumentSearchResult]) -> Void, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let searchCood = DocumentCoordinator(stack: self.stack)
        self.addChild(searchCood)
        searchCood.searchHeadings(by: .planning(planning), resultAdded: resultAdded, complete: {
            self.remove(searchCood)
            complete()
        }) {
            self.remove(searchCood)
            failure($0)
        }
    }
    
    public func search(tags: [String], resultAdded: @escaping ([DocumentSearchResult]) -> Void, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let searchCood = DocumentCoordinator(stack: self.stack)
        self.addChild(searchCood)
        searchCood.searchHeadings(by: .tags(tags), resultAdded: resultAdded, complete: {
            self.remove(searchCood)
            complete()
        }) {
            self.remove(searchCood)
            failure($0)
        }
    }
    
    public func refileTo(url: URL, content: String, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let docCood = DocumentCoordinator(stack: self.stack)
        self.addChild(docCood)
        docCood.insert(content: content, url: url, headingLocation: headingLocation, complete: {
            self.remove(docCood)
            complete()
        }, failure: {
            self.remove(docCood)
            failure($0)
        })
    }
    
    public func changePlanning(to: String, url: URL, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let docCood = DocumentCoordinator(stack: self.stack)
        self.addChild(docCood)
        docCood.changePlanning(to: to, url: url, completion: {
            self.remove(docCood)
            complete()
        }, failure: {
            self.remove(docCood)
            failure($0)
        })
    }
    
    public func reschedule(to: Date, includeTime: Bool, url: URL, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let docCood = DocumentCoordinator(stack: self.stack)
        self.addChild(docCood)
        docCood.reschedule(newSchedule: to, includeTime: includeTime, url: url, headingLocation: headingLocation, complete: {
            self.remove(docCood)
            complete()
        }, failure: {
            self.remove(docCood)
            failure($0)
        })
    }
    
    public func changeDue(to: Date, includeTime: Bool, url: URL, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let docCood = DocumentCoordinator(stack: self.stack)
        self.addChild(docCood)
        docCood.changeDue(newDue: to, url: url, includeTime: includeTime, headingLocation: headingLocation, complete: {
            self.remove(docCood)
            complete()
        }, failure: {
            self.remove(docCood)
            failure($0)
        })
    }
}
