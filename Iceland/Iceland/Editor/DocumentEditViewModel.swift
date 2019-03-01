//
//  PageViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/1.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public protocol DocumentEditViewModelDelegate: class {
    func showLink(url: URL)
    func updateHeadingInfo(heading: HeadingToken?)
    func documentStatesChange(state: UIDocument.State)
    func didReadyToEdit()
}

public class DocumentEditViewModel {
    public weak var delegate: DocumentEditViewModelDelegate? {
        didSet {
            if self.isReadyToEdit {
                self.delegate?.didReadyToEdit()
            }
        }
    }
    public var onLoadingLocation: Int = 0 // 打开文档的时候默认的位置
    public weak var coordinator: EditorCoordinator?
    private let editorService: EditorService
    public var isReadyToEdit: Bool = false {
        didSet {
            if isReadyToEdit {
                self.delegate?.didReadyToEdit()
            }
        }
    }
    
    public init(editorService: EditorService) {
        self.editorService = editorService
        self.addStatesObservers()
        editorService.open {
            self.isReadyToEdit = $0 != nil
        }
    }
    
    deinit {
        self.removeObservers()
    }
    
    public var url: URL {
        return self.editorService.fileURL
    }
    
    public var container: NSTextContainer {
        return self.editorService.container
    }
    
    public var cover: UIImage? {
        get { return self.editorService.cover }
        set { self.editorService.cover = newValue }
    }
    
    public var headings: [HeadingToken] {
        return self.editorService.headings
    }
    
    public func changeFoldingStatus(location: Int) {
        self.editorService.changeFoldingStatus(location: location)
    }
    
    public func changeCheckboxStatus(range: NSRange) {
        self.editorService.changeCheckboxStatus(range: range)
    }
    
    public func save(completion: @escaping () -> Void) {
        editorService.save { _  in
            completion()
        }
    }
    
    public func headingString(index: Int) -> String {
        let heading = self.headings[index]
        let length = [heading.tags, heading.due, heading.schedule]
            .map { $0?.location ?? Int.max }
            .reduce(heading.range.upperBound, min) - heading.range.location - heading.level + 1
        
        let location = [heading.range.location + heading.level, heading.planning?.upperBound]
            .map { $0 ?? -Int.max }
            .reduce(heading.range.location, max)
        
        return self.editorService.trim(string: self.editorService.string, range: NSRange(location: location, length: length))
    }
    
    public func level(index: Int) -> Int {
        return self.headings[index].level
    }
    
    /// 删除 due date
    public func removeDue(at headingLocation: Int) {
        self.editorService.removeDue(at: headingLocation)
    }
    
    public func removeSchedule(at headingLocation: Int) {
        self.editorService.removeSchedule(at: headingLocation)
    }
    
    public func remove(tag: String, at headingLocation: Int) {
        self.editorService.remove(tag: tag, at: headingLocation)
    }
    
    public func removePlanning(at headingLocation: Int) {
        self.editorService.removePlanning(at: headingLocation)
    }
    
    public func update(planning: String, at headingLocation: Int) {
        self.editorService.update(planning: planning, at: headingLocation)
    }

    public func update(schedule: DateAndTimeType, at headingLocation: Int) {
        self.editorService.update(schedule: schedule, at: headingLocation)
    }
    
    public func update(due: DateAndTimeType, at headingLocation: Int) {
        self.editorService.update(due: due, at: headingLocation)
    }
    
    /// 添加 tag 到 heading
    public func add(tag: String, at headingLocation: Int) {
        self.editorService.add(tag: tag, at: headingLocation)
    }
    
    public func archive(headingLocation: Int) {
        self.editorService.archive(headingLocation: headingLocation)
    }
    
    public func unArchive(headingLocation: Int) {
        self.editorService.unArchive(headingLocation: headingLocation)
    }
    
    public func insert(content: String, headingLocation: Int) {
        self.editorService.insert(content: content, headingLocation: headingLocation)
    }
    
    public func rename(newTitle: String, completion: ((Error?) -> Void)? = nil) {
        self.editorService.rename(newTitle: newTitle, completion: completion)
    }
    
    public func delete(completion: ((Error?) -> Void)? = nil) {
        self.editorService.delete(completion: completion)
    }
    
    public func find(target: String, found: @escaping ([NSRange]) -> Void) {
        do {
            try self.editorService.find(target: target, found: found)
        }
        catch {
            log.error("\(error)")
        }
    }
    
    /// 交换两个 paragraph 的内容
    public func replace(heading: HeadingToken, with: HeadingToken) {
        self.editorService.replace(heading: heading, with: with)
    }
}

// MARK: - EditorControllerDelegate
extension DocumentEditViewModel: EditorControllerDelegate {
    public func didUpdate() {
        self.editorService.markAsContentUpdated()
    }
    
    public func didTapLink(url: String, title: String, point: CGPoint) {
        if let url = URL(string: url) {
            self.delegate?.showLink(url: url)
        }
    }
    
    public func currentHeadingDidChange(heading: HeadingToken?) {
        self.delegate?.updateHeadingInfo(heading: heading)
    }
}

extension DocumentEditViewModel {
    fileprivate func addStatesObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleStatesChanges),
                                               name: UIDocument.stateChangedNotification,
                                               object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleStatesChanges(notification: Notification) {
        if let state = notification.object as? UIDocument.State {
            self.delegate?.documentStatesChange(state: state)
        }
    }
}
