//
//  Attachment.swift
//  Iceland
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import Interface
import CoreLocation

/*
 1. 文本
 2. 音频
 3. 照片
 4. 视频
 5. 链接
 6. 涂鸦
 7. 位置
 */

/// 附件对象
public struct Attachment: Codable {
    public init(date: Date,
                fileName: String,
                key: String,
                description: String,
                kind: Kind) {
        self.date = date
        self.fileName = fileName
        self.key = key
        self.description = description
        self.kind = kind
    }

    /// 附件的类型
    public enum Kind: String, CaseIterable {
        case text, link, image, sketch, audio, video, location
        
        public var isMemberFunction: Bool {
            switch self {
            case .audio, .video, .location: return true
            default: return false
            }
        }
        
        public var displayAsPureText: Bool {
            switch self {
            case .text, .link: return true
            default: return false
            }
        }
    }
    
    /// 序列化的 key
    private enum _CodingKeys: CodingKey {
        case fileName
        case date
        case kind
        case description
        case key
    }
    
    public var wrapperURL: URL {
        return AttachmentManager.wrappterURL(key: self.key.unescaped)
    }
    
    /// 附件创建的日期
    public let date: Date
    
    /// 附件类型
    public let kind: Attachment.Kind
    
    /// 附件位置
    public var url: URL {
        return self.wrapperURL.appendingPathComponent(self.fileName)
    }
    
    public let fileName: String
    
    /// 附件描述
    public let description: String
    
    /// 附件在描述文件中的 key
    public var key: String
    
    // MARK: - 序列化反序列化
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: _CodingKeys.self)
        kind = try Attachment.Kind(rawValue: values.decode(String.self, forKey: .kind))!
        date = try values.decode(Date.self, forKey: .date)
        fileName = try values.decode(String.self, forKey: .fileName)
        description = try values.decode(String.self, forKey: .description)
        key = try values.decode(String.self, forKey: .key)
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: _CodingKeys.self)
        try encoder.encode(kind.rawValue, forKey: .kind)
        try encoder.encode(fileName, forKey: .fileName)
        try encoder.encode(date, forKey: .date)
        try encoder.encode(description, forKey: .description)
        try encoder.encode(key, forKey: .key)
    }
    
    public var duration: Double? {
        switch self.kind {
        case .audio, .video:
            let asset = AVURLAsset(url: self.url, options: nil)
            return asset.duration.seconds
        default: return nil
        }
    }
        
    public var durationString: String {
        return convertDuration(self.duration ?? 0)
    }
    
    public var linkInfo: (String, String)? {
        do {
            let jsonDecoder = JSONDecoder()
            let data = try Data(contentsOf: self.url)
            let dic = try jsonDecoder.decode(Dictionary<String, String>.self, from: data)
            
            return (dic["title"] ?? "", dic["link"] ?? "")
        } catch {
            return nil
        }
    }
    
    public var linkTitle: String? {
        return self.linkInfo?.0
    }
    
    public var linkValue: String? {
        return self.linkInfo?.1
    }
    
    public var coordinator: CLLocationCoordinate2D? {
        do {
            let jsonDecoder = JSONDecoder()
            let coord = try jsonDecoder.decode(CLLocationCoordinate2D.self, from: try Data(contentsOf: self.url))
            return coord
        } catch {
            log.error(error)
            return nil
        }
    }
    
    public var size: UInt64 {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: self.url.path)
            if let fileSize = fileAttributes[FileAttributeKey.size]  {
                return (fileSize as! NSNumber).uint64Value
            } else {
                print("Failed to get a size attribute from path: \(self.wrapperURL.path)")
            }
        } catch {
            print("Failed to get file attributes for local path: \(self.wrapperURL.path) with error: \(error)")
        }
        return 0
    }
    
    public var sizeString: String {
        var convertedValue: Double = Double(self.size)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }
    
    private func convertDuration(_ duration: Double) -> String {
        switch duration {
        case ..<3600:
            let m = Int(duration / 60)
            let s = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(m):\(s)"
        case 3600...:
            let h = Int(duration / 3600)
            let m = Int((duration.truncatingRemainder(dividingBy: 3600) / 60))
            let s = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(h):\(m):\(s)"
        default:
            return "??:??"
        }
    }
    
    public var thumbnail: Observable<UIImage?> {
        return Observable.create { (observer) -> Disposable in
            
            switch self.kind {
            case .video:
                let asset = AVAsset(url: self.url)
                let assetImgGenerate = AVAssetImageGenerator(asset: asset)
                assetImgGenerate.appliesPreferredTrackTransform = true
                let time = CMTimeMakeWithSeconds(Float64(1), preferredTimescale: 100)
                do {
                    let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                    let thumbnail = UIImage(cgImage: img).resize(upto: CGSize(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7))
                    let topImage = Asset.SFSymbols.video.image.fill(color: InterfaceTheme.Color.descriptive).fill(color: InterfaceTheme.Color.interactive)
                    observer.onNext(thumbnail.addSubImage(topImage))
                } catch {
                    observer.onNext(Asset.SFSymbols.video.image.fill(color: InterfaceTheme.Color.descriptive).fill(color: InterfaceTheme.Color.interactive))
                }
            case .image, .sketch:
                let image = UIImage(contentsOfFile: self.url.path)?.resize(upto: CGSize(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7))
                observer.onNext(image)
            case .location:
                let image = Asset.SFSymbols.location.image.fill(color: InterfaceTheme.Color.descriptive).fill(color: InterfaceTheme.Color.interactive)
                observer.onNext(image)
            case .audio:
                let image = Asset.SFSymbols.mic.image.fill(color: InterfaceTheme.Color.descriptive).fill(color: InterfaceTheme.Color.interactive)
                observer.onNext(image)
            case .link:
                let image = Asset.SFSymbols.link.image.fill(color: InterfaceTheme.Color.descriptive).fill(color: InterfaceTheme.Color.interactive)
                observer.onNext(image)
            case .text:
                let image = Asset.SFSymbols.docPlaintext.image.fill(color: InterfaceTheme.Color.descriptive).fill(color: InterfaceTheme.Color.interactive)
                observer.onNext(image)
            }
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    public var serialize: String {
        return OutlineParser.Values.Attachment.serialize(kind: self.kind.rawValue, value: self.key)
    }
}

extension Attachment {
    /// 保存附件
    /// - Parameter content:
    /// 序列化后的附件 json
    /// - Parameter type
    /// 附件类型
    /// - Parameter description
    /// 附件描述
//    public static func save(content: String,
//                            kind: Attachment.Kind,
//                            description: String,
//                            complete: @escaping (String) -> Void,
//                            failure: @escaping (Error) -> Void) {
//        let manager = AttachmentManager()
//        manager.insert(content: content,
//                                  kind: kind,
//                                  description: description,
//                                  complete: complete,
//                                  failure: failure)
//    }
}

extension CLLocationCoordinate2D: Codable {
    public enum Keys: CodingKey {
        case longitude
        case latitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        self.init()
        self.latitude = try container.decode(Double.self, forKey: CLLocationCoordinate2D.Keys.latitude)
        self.longitude = try container.decode(Double.self, forKey: CLLocationCoordinate2D.Keys.longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(self.latitude, forKey: CLLocationCoordinate2D.Keys.latitude)
        try container.encode(self.longitude, forKey: CLLocationCoordinate2D.Keys.longitude)
    }
}
