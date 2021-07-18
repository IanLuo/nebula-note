//
//  FormSheet.swift
//  Interface
//
//  Created by ian luo on 2021/6/26.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation

public typealias FormItem = UIView

public protocol Validatable {
    associatedtype ValueType
    var isValid: ((ValueType) -> ValidateResult)? { get set }
}

public protocol Visiable {
    associatedtype ValueType
    var isVisiable: ((ValueType) -> Bool)? { get set }
}

public protocol Editable {
    associatedtype ValueType
    var isEditable: ((ValueType) -> Bool)? { get set }
}

public class FormElementGroup {
    internal init(title: String,
                  direction: NSLayoutConstraint.Axis,
                  distribute: UIStackView.Distribution,
                  alignment: UIStackView.Alignment,
                  space: CGFloat) {
        self.title = title
        self.direction = direction
        self.distribute = distribute
        self.alignment = alignment
        self.space = space
    }
    
    public let title: String
    public let direction: NSLayoutConstraint.Axis
    public let distribute: UIStackView.Distribution
    public let alignment: UIStackView.Alignment
    public let space: CGFloat
    
    private let stackView: UIStackView = UIStackView()
    
    @discardableResult
    public func addElement<ValueType>(_ element: FormElement<ValueType>) -> FormElementGroup {
        stackView.addArrangedSubview(FormItemView(configure: element))
        return self
    }
}

public class FormElement<ValueType>: Validatable, Visiable, Editable {
    public var isVisiable: ((ValueType) -> Bool)?
    public var isEditable: ((ValueType) -> Bool)?
    public var isValid: ((ValueType) -> ValidateResult)?
    
    public init(value: ValueType) {
        self.value = value
    }
    
    public var value: ValueType

    @discardableResult
    public func visiabilityWhen(_ action: @escaping (ValueType) -> Bool) -> Self {
        self.isVisiable = action
        return self
    }
    
    @discardableResult
    public func editableWhen(_ action: @escaping (ValueType) -> Bool) -> Self {
        self.isEditable = action
        return self
    }
    
    @discardableResult
    public func validateWhen(_ action: @escaping (ValueType) -> ValidateResult) -> Self {
        self.isValid = action
        return self
    }
}

public enum ValidateResult {
    case Pass
    case Fail(String)
}

public class FormItemView<ValueType>: FormItem {
    public init(configure: FormElement<ValueType>) {
        self.configure = configure
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let configure: FormElement<ValueType>
}
