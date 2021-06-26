//
//  FormSheet.swift
//  Interface
//
//  Created by ian luo on 2021/6/26.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation

struct FormTemplateKey<ValueType> {
    var value: ValueType
    var title: String
}

protocol FormModel {
    
}

public protocol Validatable {
    associatedtype ValueType
    
    func isValid() -> Bool
    var condition: Condition<ValueType> { get set }
}

public protocol Visable {
    associatedtype FormModel
    var isVisiable: ((FormModel) -> Bool)? { get set }
}

public protocol Editable {
    associatedtype FormModel
    var isEditable: ((FormModel) -> Bool)? { get set }
}

public protocol FormSheet {
    associatedtype FormModel
    func addSection(_ section: FormSheetSection)
}

public protocol FormSheetSection {
    var title: String { get set }
    func addRow<FormModel, ValueType>(_ row: FormSheetSectionRow<FormModel, ValueType>)
}

public struct FormSheetSectionRow<FormModel, ValueType>: Validatable, Visable, Editable {
    public var isVisiable: ((FormModel) -> Bool)?
    
    public var isEditable: ((FormModel) -> Bool)?
    
    public func isValid() -> Bool {
        return self.condition.run(value: self.value)
    }
    
    public var value: ValueType
    public var condition: Condition<ValueType>
}

public struct Condition<ValueType> {
    private let condition: (ValueType) -> Bool
    public func run(value: ValueType) -> Bool {
        return condition(value)
    }
}

protocol RowBuilder {
    func build<FormModel, ValueType>(type: ValueType) -> FormSheetSectionRow<FormModel, ValueType>
}


