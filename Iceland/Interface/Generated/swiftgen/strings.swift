// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
public enum L10n {

  public enum Document {
    public enum Action {
      /// Create New Document
      public static let new = L10n.tr("Localizable", "document.action.new")
    }
    public enum Actions {
      /// Edit Cover
      public static let cover = L10n.tr("Localizable", "document.actions.cover")
      /// Delete
      public static let delete = L10n.tr("Localizable", "document.actions.delete")
      /// Duplicate
      public static let duplicate = L10n.tr("Localizable", "document.actions.duplicate")
      /// New Sub Document
      public static let newSub = L10n.tr("Localizable", "document.actions.new-sub")
      /// Rename
      public static let rename = L10n.tr("Localizable", "document.actions.rename")
      /// Perform Actions
      public static let title = L10n.tr("Localizable", "document.actions.title")
    }
    public enum Title {
      /// Untitled
      public static let untitled = L10n.tr("Localizable", "document.title.untitled")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
