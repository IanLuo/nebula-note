//
//  File.swift
//  Storage
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

enum FileError: Error {
    case fail
}

public struct File {
    public enum Path {
        case temp(String)
        case document(String)
        case cache(String)
        case custom(String)
        
        public var path: String {
            switch self {
            case let .temp(relatePath):
                let tempDir = NSTemporaryDirectory()
                return "\(tempDir)\(relatePath)"
            case let .document(relatePath):
                let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                return "\(documentDir)/\(relatePath)"
            case let .cache(relatePath):
                let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
                return "\(cacheDir)/\(relatePath)"
            case let .custom(customPath):
                return customPath
            }
        }
    }
    
    public enum Folder {
        case temp(String)
        case document(String)
        case cache(String)
        case custom(String)
        
        public var path: String {
            switch self {
            case let .temp(relatePath):
                let tempDir = NSTemporaryDirectory()
                var relatePath = relatePath.hasPrefix("/") ? String(relatePath.dropFirst()) : relatePath
                relatePath = relatePath.hasSuffix("/") ? String(relatePath.dropLast()) : relatePath
                return "\(tempDir)\(relatePath)/"
            case let .document(relatePath):
                let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                var relatePath = relatePath.hasPrefix("/") ? String(relatePath.dropFirst()) : relatePath
                relatePath = relatePath.hasSuffix("/") ? String(relatePath.dropLast()) : relatePath
                return "\(documentDir)/\(relatePath)/"
            case let .cache(relatePath):
                let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
                var relatePath = relatePath.hasPrefix("/") ? String(relatePath.dropFirst()) : relatePath
                relatePath = relatePath.hasSuffix("/") ? String(relatePath.dropLast()) : relatePath
                return "\(cacheDir)/\(relatePath)/"
            case let .custom(customPath):
                return customPath.hasSuffix("/") ? customPath : customPath + "/"
            }
            
        }
        
        public var url: URL {
            return URL(fileURLWithPath: self.path)
        }
        
        public func remove() {
            var isDIR = ObjCBool(true)
            if Foundation.FileManager.default.fileExists(atPath: path, isDirectory: &isDIR) {
                do { try Foundation.FileManager.default.removeItem(atPath: path) }
                catch { print("Error when removing dir for path: \(path): error") }
            }
        }
        
        public func createFolderIfNeeded() {
            var isDIR = ObjCBool(true)
            if !Foundation.FileManager.default.fileExists(atPath: path, isDirectory: &isDIR) {
                do { try Foundation.FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil) }
                catch { print("Error when touching dir for path: \(path): error") }
            }
        }
        
        // 文件夹大小
        public var size: Double {
            return getDirSize(dirPath: path)
        }
        
        //
        public func getDirSize(dirPath: String) -> Double {
            
            let fileManager = FileManager.default
            let curPath = dirPath
            var sum: Double = 0
            
            //
            do {
                let arr = try fileManager.contentsOfDirectory(atPath: curPath)
                if arr.count == 0 {
                    return sum
                }
                
                //
                for index in 0 ..< arr.count {
                    let fullPath =  curPath.hasSuffix("/") ? curPath + arr[index] : curPath + "/" + arr[index]
                    var isDIR = ObjCBool(false)
                    if fileManager.fileExists(atPath: fullPath, isDirectory: &isDIR) {
                        let fileAttributeDic = try fileManager.attributesOfItem(atPath: fullPath)
                        sum += (fileAttributeDic[FileAttributeKey.size] as? Double)!
                    } else {
                        sum += getDirSize(dirPath: fullPath)
                    }
                }
            }
            catch {
                return sum
            }
            
            return sum
        }
    }
    
    public init(_ folder: File.Folder, fileName: String, createFolderIfNeeded: Bool = false) {
        if createFolderIfNeeded {
            folder.createFolderIfNeeded()
        }
        self.folder = folder
        self.fileName = fileName
    }
    
    public init(path: File.Path) {
        let fileName = (path.path as NSString).lastPathComponent
        var folder: File.Folder!
        
        switch path {
        case .cache(let rpath): folder = File.Folder.cache((rpath as NSString).deletingLastPathComponent)
        case .temp(let rpath): folder = File.Folder.temp((rpath as NSString).deletingLastPathComponent)
        case .document(let rpath): folder = File.Folder.document((rpath as NSString).deletingLastPathComponent)
        case .custom(let rpath): folder = File.Folder.custom((rpath as NSString).deletingLastPathComponent)
        }
        
        self.init(folder, fileName: fileName)
    }
    
    public let folder: Folder
    public let fileName: String
    
    public var filePath: String {
        return folder.path + fileName
    }
    
    public func write(value: Data, completion: @escaping (Error?) -> Void) {
        if Settings.isLogEnabled {
            print("writing file at: \(filePath)")
        }
        
        folder.createFolderIfNeeded()
        
        let fileCoordinator = NSFileCoordinator()
        let intent = NSFileAccessIntent.writingIntent(with: self.url, options: NSFileCoordinator.WritingOptions.forMerging)
        let queue = OperationQueue()
        fileCoordinator.coordinate(with: [intent], queue: queue) { error in
            if error != nil {
                completion(error)
            } else {
                do {
                    try value.write(to: URL(fileURLWithPath: self.filePath))
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    public func write(accessor: @escaping (Error?) -> Void) {
        if Settings.isLogEnabled {
            print("writing file at: \(filePath)")
        }
        
        folder.createFolderIfNeeded()
        
        let fileCoordinator = NSFileCoordinator()
        let intent = NSFileAccessIntent.writingIntent(with: self.url, options: NSFileCoordinator.WritingOptions.forMerging)
        let queue = OperationQueue()
        fileCoordinator.coordinate(with: [intent], queue: queue) { error in
            accessor(error)
        }
    }
    
    public func read(completion: @escaping (Data?, Error?) -> Void) {
        let fm = Foundation.FileManager.default
        guard fm.fileExists(atPath: filePath) != false else {
            completion(nil, FileError.fail)
            return
        }
        
        guard fm.isReadableFile(atPath: filePath) != false else {
            completion(nil, FileError.fail)
            return
        }
        
        let fileCoordinator = NSFileCoordinator()
        let intent = NSFileAccessIntent.readingIntent(with: self.url, options: NSFileCoordinator.ReadingOptions.Element())
        let queue = OperationQueue()
        fileCoordinator.coordinate(with: [intent], queue: queue) { error in
            if error != nil {
                completion(nil, error)
            } else {
                completion(fm.contents(atPath: self.filePath), nil)
            }
        }
    }
    
    public func delete(completion: @escaping (Error?) -> Void) {
        let fileCoordinator = NSFileCoordinator()
        let intent = NSFileAccessIntent.readingIntent(with: self.url, options: NSFileCoordinator.ReadingOptions.Element())
        let queue = OperationQueue()
        fileCoordinator.coordinate(with: [intent], queue: queue) { error in
            if error != nil {
                completion(error)
            } else {
                do {
                    try Foundation.FileManager.default.removeItem(atPath: self.filePath)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    public func delete(accessor: @escaping (Error?) -> Void) {
        let fileCoordinator = NSFileCoordinator()
        let intent = NSFileAccessIntent.readingIntent(with: self.url, options: NSFileCoordinator.ReadingOptions.Element())
        let queue = OperationQueue()
        fileCoordinator.coordinate(with: [intent], queue: queue) { error in
            accessor(error)
        }
    }
    
    public var url: URL {
        return URL(fileURLWithPath: self.filePath)
    }
    
    // 是否存在
    public func isExit() -> Bool {
        return Foundation.FileManager.default.fileExists(atPath: filePath)
    }
}
