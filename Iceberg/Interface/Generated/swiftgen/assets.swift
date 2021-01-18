// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum Asset {
  public enum Assets {
    public static let add = ImageAsset(name: "add")
    public static let agenda = ImageAsset(name: "agenda")
    public static let attachment = ImageAsset(name: "attachment")
    public static let audio = ImageAsset(name: "audio")
    public static let bold = ImageAsset(name: "bold")
    public static let calendar = ImageAsset(name: "calendar")
    public static let camera = ImageAsset(name: "camera")
    public static let capture = ImageAsset(name: "capture")
    public static let checkMark = ImageAsset(name: "check-mark")
    public static let checkboxChecked = ImageAsset(name: "checkbox-checked")
    public static let checkboxUnchecked = ImageAsset(name: "checkbox-unchecked")
    public static let code = ImageAsset(name: "code")
    public static let cross = ImageAsset(name: "cross")
    public static let document = ImageAsset(name: "document")
    public static let down = ImageAsset(name: "down")
    public static let due = ImageAsset(name: "due")
    public static let edit = ImageAsset(name: "edit")
    public static let fileLink = ImageAsset(name: "fileLink")
    public static let foldAll = ImageAsset(name: "fold-all")
    public static let folded = ImageAsset(name: "folded")
    public static let fullscreen = ImageAsset(name: "fullscreen")
    public static let heading = ImageAsset(name: "heading")
    public static let imageLibrary = ImageAsset(name: "image library")
    public static let infomation = ImageAsset(name: "infomation")
    public static let inspiration = ImageAsset(name: "inspiration")
    public static let italic = ImageAsset(name: "italic")
    public static let `left` = ImageAsset(name: "left")
    public static let leftPart = ImageAsset(name: "left_part")
    public static let link = ImageAsset(name: "link")
    public static let list = ImageAsset(name: "list")
    public static let location = ImageAsset(name: "location")
    public static let markerPen = ImageAsset(name: "marker-pen")
    public static let master = ImageAsset(name: "master")
    public static let middlePart = ImageAsset(name: "middle_part")
    public static let minus1 = ImageAsset(name: "minus-1")
    public static let minus = ImageAsset(name: "minus")
    public static let moreV = ImageAsset(name: "more-v")
    public static let more = ImageAsset(name: "more")
    public static let moveDown = ImageAsset(name: "move-down")
    public static let moveUp = ImageAsset(name: "move-up")
    public static let newDocument = ImageAsset(name: "newDocument")
    public static let next = ImageAsset(name: "next")
    public static let orderedList = ImageAsset(name: "ordered-list")
    public static let paragraph = ImageAsset(name: "paragraph")
    public static let pause = ImageAsset(name: "pause")
    public static let planning = ImageAsset(name: "planning")
    public static let play = ImageAsset(name: "play")
    public static let priority = ImageAsset(name: "priority")
    public static let proLabel = ImageAsset(name: "pro_label")
    public static let quote = ImageAsset(name: "quote")
    public static let record = ImageAsset(name: "record")
    public static let redo = ImageAsset(name: "redo")
    public static let refresh = ImageAsset(name: "refresh")
    public static let `right` = ImageAsset(name: "right")
    public static let save = ImageAsset(name: "save")
    public static let scheduled = ImageAsset(name: "scheduled")
    public static let separator = ImageAsset(name: "separator")
    public static let seperator = ImageAsset(name: "seperator")
    public static let settings = ImageAsset(name: "settings")
    public static let sketch = ImageAsset(name: "sketch")
    public static let smallIcon = ImageAsset(name: "small-icon")
    public static let sourcecode = ImageAsset(name: "sourcecode")
    public static let stop = ImageAsset(name: "stop")
    public static let strikethrough = ImageAsset(name: "strikethrough")
    public static let tag = ImageAsset(name: "tag")
    public static let tapAdd = ImageAsset(name: "tap-add")
    public static let tapMinus = ImageAsset(name: "tap-minus")
    public static let text = ImageAsset(name: "text")
    public static let trash = ImageAsset(name: "trash")
    public static let underline = ImageAsset(name: "underline")
    public static let undo = ImageAsset(name: "undo")
    public static let unfoldAll = ImageAsset(name: "unfold-all")
    public static let unfoldButton = ImageAsset(name: "unfold-button")
    public static let unfolded = ImageAsset(name: "unfolded")
    public static let up = ImageAsset(name: "up")
    public static let video = ImageAsset(name: "video")
    public static let zoom = ImageAsset(name: "zoom")
  }
  public enum Colors {
    public static let blue = ColorAsset(name: "Blue")
    public static let green = ColorAsset(name: "Green")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

public final class ColorAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  public private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

public struct ImageAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Image = UIImage
  #endif

  public var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
}

public extension ImageAsset.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
