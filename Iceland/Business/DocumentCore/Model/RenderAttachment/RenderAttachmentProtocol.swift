//
//  AttachmentProtocol.swift
//  Business
//
//  Created by ian luo on 2019/2/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public protocol RenderAttachmentProtocol {
    var rawString: String { get }
    var value: String { get }
    var type: String { get }
    
    init(rawString: String, ranges: [String: NSRange])
    
    func serialize() -> String
}

public class RenderAttachment: NSTextAttachment, RenderAttachmentProtocol {
    public var rawString: String
    public var type: String = ""
    public var value: String = ""
    
    public var url: URL?
    
    required public init(rawString: String, ranges: [String: NSRange]) {
        self.rawString = rawString
        super.init(data: nil, ofType: nil)
        
        let location = ranges[OutlineParser.Key.Node.attachment]!.location
        if let typeRange = ranges[OutlineParser.Key.Element.Attachment.type]?.offset(location),
            let valueRange = ranges[OutlineParser.Key.Element.Attachment.value]?.offset(location) {
            let type = rawString.substring(typeRange)
            let value = rawString.substring(valueRange)

            self.type = type
            self.value = value
            
            self.url = URL.attachmentURL.appendingPathComponent(value)
            
            self.createImage(type: type)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func serialize() -> String {
        return OutlineParser.Values.Attachment.serialize(type: self.type, value: self.value)
    }
    
    private func createImage(type: String) {
        switch type {
        case Attachment.AttachmentType.image.rawValue:
            let size = CGSize(width: UIScreen.main.bounds.width,
                              height: UIScreen.main.bounds.width)
            self.image = UIImage(contentsOfFile: self.url?.path ?? "")?.resize(upto: size)
            self.bounds = CGRect(origin: .zero, size: size)
        default: break
        }
    }
}
