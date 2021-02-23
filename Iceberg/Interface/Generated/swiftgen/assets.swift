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
    public static let capture = ImageAsset(name: "capture")
    public static let fileLink = ImageAsset(name: "fileLink")
    public static let foldAll = ImageAsset(name: "fold-all")
    public static let fullscreen = ImageAsset(name: "fullscreen")
    public static let heading = ImageAsset(name: "heading")
    public static let leftPart = ImageAsset(name: "left_part")
    public static let markerPen = ImageAsset(name: "marker-pen")
    public static let master = ImageAsset(name: "master")
    public static let middlePart = ImageAsset(name: "middle_part")
    public static let moreV = ImageAsset(name: "more-v")
    public static let planning = ImageAsset(name: "planning")
    public static let proLabel = ImageAsset(name: "pro_label")
    public static let scheduled = ImageAsset(name: "scheduled")
    public static let separator = ImageAsset(name: "separator")
    public static let smallIcon = ImageAsset(name: "small-icon")
    public static let unfoldAll = ImageAsset(name: "unfold-all")
  }
  public enum Colors {
    public static let blue = ColorAsset(name: "Blue")
    public static let green = ColorAsset(name: "Green")
  }
  public enum SFSymbols {
    public static let arrowClockwise = ImageAsset(name: "arrow.clockwise")
    public static let arrowDownToLine = ImageAsset(name: "arrow.down.to.line")
    public static let arrowLeft = ImageAsset(name: "arrow.left")
    public static let arrowLeftToLine = ImageAsset(name: "arrow.left.to.line")
    public static let arrowRight = ImageAsset(name: "arrow.right")
    public static let arrowRightToLine = ImageAsset(name: "arrow.right.to.line")
    public static let arrowUpDoc = ImageAsset(name: "arrow.up.doc")
    public static let arrowUpToLine = ImageAsset(name: "arrow.up.to.line")
    public static let arrowUturnLeft = ImageAsset(name: "arrow.uturn.left")
    public static let arrowUturnRight = ImageAsset(name: "arrow.uturn.right")
    public static let bell = ImageAsset(name: "bell")
    public static let bellSlash = ImageAsset(name: "bell.slash")
    public static let bold = ImageAsset(name: "bold")
    public static let bookClosed = ImageAsset(name: "book.closed")
    public static let calendarBadgeClock = ImageAsset(name: "calendar.badge.clock")
    public static let calendarBadgeExclamationmark = ImageAsset(name: "calendar.badge.exclamationmark")
    public static let calendarBadgeMinus = ImageAsset(name: "calendar.badge.minus")
    public static let calendarBadgePlus = ImageAsset(name: "calendar.badge.plus")
    public static let calendarCircle = ImageAsset(name: "calendar.circle")
    public static let calendar = ImageAsset(name: "calendar")
    public static let camera = ImageAsset(name: "camera")
    public static let checkmark = ImageAsset(name: "checkmark")
    public static let checkmarkSquare = ImageAsset(name: "checkmark.square")
    public static let chevronCompactDown = ImageAsset(name: "chevron.compact.down")
    public static let chevronCompactLeft = ImageAsset(name: "chevron.compact.left")
    public static let chevronCompactRight = ImageAsset(name: "chevron.compact.right")
    public static let chevronCompactUp = ImageAsset(name: "chevron.compact.up")
    public static let chevronDown = ImageAsset(name: "chevron.down")
    public static let chevronLeft = ImageAsset(name: "chevron.left")
    public static let chevronLeftSlashChevronRight = ImageAsset(name: "chevron.left.slash.chevron.right")
    public static let chevronRight = ImageAsset(name: "chevron.right")
    public static let chevronUpChevronDown = ImageAsset(name: "chevron.up.chevron.down")
    public static let chevronUp = ImageAsset(name: "chevron.up")
    public static let clear = ImageAsset(name: "clear")
    public static let deleteLeft = ImageAsset(name: "delete.left")
    public static let docAppend = ImageAsset(name: "doc.append")
    public static let docBadgePlus = ImageAsset(name: "doc.badge.plus")
    public static let doc = ImageAsset(name: "doc")
    public static let docOnClipboard = ImageAsset(name: "doc.on.clipboard")
    public static let docOnDoc = ImageAsset(name: "doc.on.doc")
    public static let docPlaintext = ImageAsset(name: "doc.plaintext")
    public static let docText = ImageAsset(name: "doc.text")
    public static let docTextMagnifyingglass = ImageAsset(name: "doc.text.magnifyingglass")
    public static let ellipsis = ImageAsset(name: "ellipsis")
    public static let envelope = ImageAsset(name: "envelope")
    public static let exclamationmark = ImageAsset(name: "exclamationmark")
    public static let eye = ImageAsset(name: "eye")
    public static let eyeSlash = ImageAsset(name: "eye.slash")
    public static let filemenuAndSelection = ImageAsset(name: "filemenu.and.selection")
    public static let gear = ImageAsset(name: "gear")
    public static let heartFill = ImageAsset(name: "heart.fill")
    public static let heart = ImageAsset(name: "heart")
    public static let icloud = ImageAsset(name: "icloud")
    public static let info = ImageAsset(name: "info")
    public static let italic = ImageAsset(name: "italic")
    public static let lightbulb = ImageAsset(name: "lightbulb")
    public static let link = ImageAsset(name: "link")
    public static let listBullet = ImageAsset(name: "list.bullet")
    public static let listNumber = ImageAsset(name: "list.number")
    public static let location = ImageAsset(name: "location")
    public static let magnifyingglass = ImageAsset(name: "magnifyingglass")
    public static let map = ImageAsset(name: "map")
    public static let mappin = ImageAsset(name: "mappin")
    public static let mic = ImageAsset(name: "mic")
    public static let minus = ImageAsset(name: "minus")
    public static let musicMic = ImageAsset(name: "music.mic")
    public static let paperclip = ImageAsset(name: "paperclip")
    public static let paragraph = ImageAsset(name: "paragraph")
    public static let pause = ImageAsset(name: "pause")
    public static let pencilCircle = ImageAsset(name: "pencil.circle")
    public static let pencil = ImageAsset(name: "pencil")
    public static let photoOnRectangle = ImageAsset(name: "photo.on.rectangle")
    public static let pin = ImageAsset(name: "pin")
    public static let play = ImageAsset(name: "play")
    public static let plus = ImageAsset(name: "plus")
    public static let power = ImageAsset(name: "power")
    public static let recordCircle = ImageAsset(name: "record.circle")
    public static let scribble = ImageAsset(name: "scribble")
    public static let sliderHorizontal3 = ImageAsset(name: "slider.horizontal.3")
    public static let sparkles = ImageAsset(name: "sparkles")
    public static let squareAndArrowDown = ImageAsset(name: "square.and.arrow.down")
    public static let square = ImageAsset(name: "square")
    public static let starFill = ImageAsset(name: "star.fill")
    public static let star = ImageAsset(name: "star")
    public static let stop = ImageAsset(name: "stop")
    public static let strikethrough = ImageAsset(name: "strikethrough")
    public static let tag = ImageAsset(name: "tag")
    public static let textBadgeCheckmark1 = ImageAsset(name: "text.badge.checkmark-1")
    public static let textBadgeCheckmark = ImageAsset(name: "text.badge.checkmark")
    public static let textQuote = ImageAsset(name: "text.quote")
    public static let timer = ImageAsset(name: "timer")
    public static let trash = ImageAsset(name: "trash")
    public static let trayAndArrowDown = ImageAsset(name: "tray.and.arrow.down")
    public static let underline = ImageAsset(name: "underline")
    public static let video = ImageAsset(name: "video")
    public static let xmark = ImageAsset(name: "xmark")
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
