//
//  Task.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public enum TaskStatus {
    case todo
    case processing
    case done
    case cancled
    case pending
}

public struct Task {
    let schedule: Date?
    let deadline: Date?
    let effort: Double?
    let ref: Any // TODO: 关联到对应的 document header，要求 document 能够通过 url 关联到 header
    let title: String
    let content: String?
    let status: TaskStatus
    let isArchived: Bool
}
