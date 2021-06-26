//
//  EventObserver.swift
//  Business
//
//  Created by ian luo on 2019/3/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public protocol EventObserverProtocol {
    func registerForEvent<E: Event>(on: AnyObject,
                                    eventType: E.Type,
                                    queue: OperationQueue?,
                                    send by: AnyObject?,
                                    action: @escaping (E) -> Void)
    func unregister<E: Event>(for observer: AnyObject, eventType: E.Type?)
    func emit(_ event: Event, send by: AnyObject?)
}

public class EventObserver: EventObserverProtocol {
    public func registerForEvent<E>(on: AnyObject,
                                    eventType: E.Type,
                                    queue: OperationQueue?,
                                    send by: AnyObject? = nil,
                                    action: @escaping (E) -> Void) where E : Event {
        self.eventObserverImpl.registerForEvent(on: on, eventType: eventType, queue: queue, send: by, action: action)
    }
    
    public func unregister<E: Event>(for observer: AnyObject,
                                     eventType: E.Type?) {
        self.eventObserverImpl.unregister(for: observer, eventType: eventType)
    }
    
    public func emit(_ event: Event,
                     send by: AnyObject? = nil) {
        self.eventObserverImpl.emit(event, send: by)
    }
    
    private let eventObserverImpl: EventObserverProtocol

    public init() {
        self.eventObserverImpl = DefaultEventObserverImpl()
    }
}

public class DefaultEventObserverImpl: EventObserverProtocol {
    private let defaultQueue = OperationQueue()
    public func registerForEvent<E: Event>(on: AnyObject,
                                           eventType: E.Type,
                                           queue: OperationQueue?,
                                           send by: AnyObject?,
                                           action: @escaping (E) -> Void) {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("\(eventType)"), object: by, queue: queue ?? defaultQueue) { notification in
            action(notification.userInfo!["event"] as! E)
        }
    }
    
    public func unregister<E: Event>(for observer: AnyObject,
                                     eventType: E.Type?) {
        if let eventType = eventType {
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name("\(eventType)"), object: nil)
        } else {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    public func emit(_ event: Event,
                     send by: AnyObject?) {
        NotificationCenter.default.post(name: NSNotification.Name("\(type(of: event))"), object: by, userInfo: ["event": event])
    }
    
    public init() {
        self.defaultQueue.qualityOfService = .background
    }
}
