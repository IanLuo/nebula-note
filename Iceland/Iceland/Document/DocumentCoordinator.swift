//
//  DocumentCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class DocumentCoordinator: Coordinator {
    public enum DocumentError: Error {
        case failToInsert
        case failToOpenFile
        case failToReschedule
        case failToChangeDueDate
    }
    
    public enum HeadingSearchBy {
        case planning([String])
        case tags([String])
        case schedule(Date)
        case due(Date)
    }
    
    public let viewController: UIViewController
    
    /// 初始界面为文件浏览器
    public override init(stack: UINavigationController) {
        let viewModel = DocumentBrowserViewModel()
        self.viewController = DocumentBrowserViewController(viewModel: viewModel)
        super.init(stack: stack)
        viewModel.dependency = self
    }
    
    /// 初始界面为文件编辑器
    public init(stack: UINavigationController, url: URL, location: Int) {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: Document(fileURL: url))
        self.viewController = DocumentEditViewController(viewModel: viewModel)
        super.init(stack: stack)
        viewModel.dependency = self
    }
    
    public override func start() {
        self.stack.pushViewController(self.viewController, animated: true)
    }
    
    public func searchHeadings(by: HeadingSearchBy,
                               resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                               complete: @escaping () -> Void,
                               failed: @escaping (Error) -> Void) {
        let viewModel = DocumentSearchViewModel()
        viewModel.dependency = self
        
        switch by {
        case .due(let date): viewModel.search(due: date, resultAdded: resultAdded, complete: complete, failed: failed)
        case .schedule(let date): viewModel.search(schedule: date, resultAdded: resultAdded, complete: complete, failed: failed)
        case .planning(let plannings): viewModel.search(plannings: plannings, resultAdded: resultAdded, complete: complete, failed: failed)
        case .tags(let tags): viewModel.search(tags: tags, resultAdded: resultAdded, complete: complete, failed: failed)
        }
    }
    
    /// 插入指定字符串到指定位置为 heading 开头的 heading 尾部，新起一行
    public func insert(content: String, url: URL, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: Document(fileURL: url))
        viewModel.dependency = self
        viewModel.open { text in
            if text != nil {
                viewModel.insert(content: content, headingLocation: headingLocation) { success in
                    if success {
                        complete()
                    } else {
                        failure(DocumentError.failToInsert)
                    }
                }
            } else {
                failure(DocumentError.failToOpenFile)
            }
        }
    }
    
    /// 修改指定位置为 heading 开头的 heading 的 planning
    public func changePlanning(to: String, url: URL, completion: () -> Void, failure: @escaping (Error) -> Void) {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: Document(fileURL: url))
        viewModel.dependency = self
        viewModel.open {
            if $0 != nil {

            } else {
                failure(DocumentError.failToOpenFile)
            }
        }
    }
    
    /// 查看指定位置为 heading 开头位置的 heading 的内容
    public func peekParagraph(url: URL, headingLocation: Int, complete: @escaping (String) -> Void, failure: @escaping (Error) -> Void) {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: Document(fileURL: url))
        viewModel.dependency = self
        viewModel.open {
            if $0 != nil {
                if let heading = viewModel.heading(at: headingLocation) {
                    let range = NSRange(location: heading.range.location, length: heading.contentLength)
                    complete((viewModel.editorController.string as NSString).substring(with: range))
                }
            } else {
                failure(DocumentError.failToOpenFile)
            }
        }
    }
    
    /// 修改指定位置为 heading 开头的 schedule 日期
    public func reschedule(newSchedule: DateAndTimeType, url: URL, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: Document(fileURL: url))
        viewModel.dependency = self
        viewModel.open { [weak viewModel] in
            if $0 != nil {
                viewModel?.update(schedule: newSchedule, at: headingLocation) {
                    if $0 {
                        complete()
                    } else {
                        failure(DocumentError.failToReschedule)
                    }
                }
            } else {
                failure(DocumentError.failToOpenFile)
            }
        }
    }
    
    /// 修改指定位置为 heading 开头的 due 日期
    public func changeDue(newDue: DateAndTimeType, url: URL, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: Document(fileURL: url))
        viewModel.dependency = self
        viewModel.open { [weak viewModel] in
            if $0 != nil {
                viewModel?.update(due: newDue, at: headingLocation) {
                    if $0 {
                        complete()
                    } else {
                        failure(DocumentError.failToChangeDueDate)
                    }
                }
            } else {
                failure(DocumentError.failToOpenFile)
            }
        }
    }
    
    /// 打开文件
    public func openDocument(url: URL, location: Int) {
        self.openDocument(document: Document(fileURL: url), location: location)
    }
    
    /// 打开文件
    private func openDocument(document: Document, location: Int) {
        let editViewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: document)
        editViewModel.dependency = self
        editViewModel.onLoadingLocation = location
        let viewController = DocumentEditViewController(viewModel: editViewModel)
        stack.pushViewController(viewController, animated: true)
    }
}

extension DocumentCoordinator {
    public func didSelectDocument(document: Document, location: Int) {
        self.openDocument(document: document, location: location)
    }
    
    public func didSelectDocument(document: Document) {
        self.openDocument(document: document, location: 0)
    }
}
