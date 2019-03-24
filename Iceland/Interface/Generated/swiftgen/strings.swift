// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
public enum L10n {

  public enum Agenda {
    public enum Actions {
      /// Archieve
      public static let archive = L10n.tr("Localizable", "agenda.actions.archive")
      /// Change status
      public static let changeStatus = L10n.tr("Localizable", "agenda.actions.change-status")
      /// Due
      public static let due = L10n.tr("Localizable", "agenda.actions.due")
      /// Schedule
      public static let schedule = L10n.tr("Localizable", "agenda.actions.schedule")
      /// Choose an action
      public static let title = L10n.tr("Localizable", "agenda.actions.title")
    }
  }

  public enum Attachment {
    public enum Kind {
      /// Audio
      public static let audio = L10n.tr("Localizable", "attachment.kind.audio")
      /// Image
      public static let image = L10n.tr("Localizable", "attachment.kind.image")
      /// Link
      public static let link = L10n.tr("Localizable", "attachment.kind.link")
      /// Location
      public static let location = L10n.tr("Localizable", "attachment.kind.location")
      /// Sketch
      public static let sketch = L10n.tr("Localizable", "attachment.kind.sketch")
      /// Text
      public static let text = L10n.tr("Localizable", "attachment.kind.text")
      /// Video
      public static let video = L10n.tr("Localizable", "attachment.kind.video")
    }
  }

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
    public enum Browser {
      public enum Delete {
        /// Delete this file?
        public static let confirm = L10n.tr("Localizable", "document.browser.delete.confirm")
      }
    }
    public enum Edit {
      public enum Action {
        /// Arrow down
        public static let arrowDown = L10n.tr("Localizable", "document.edit.action.arrow-down")
        /// Arrow left
        public static let arrowLeft = L10n.tr("Localizable", "document.edit.action.arrow-left")
        /// Arrow right
        public static let arrowRight = L10n.tr("Localizable", "document.edit.action.arrow-right")
        /// Arrow up
        public static let arrowUp = L10n.tr("Localizable", "document.edit.action.arrow-up")
        /// Attachment
        public static let attachment = L10n.tr("Localizable", "document.edit.action.attachment")
        /// Code block
        public static let codeBlock = L10n.tr("Localizable", "document.edit.action.code-block")
        /// Tab left
        public static let decreaseIndent = L10n.tr("Localizable", "document.edit.action.decrease-indent")
        /// Due
        public static let due = L10n.tr("Localizable", "document.edit.action.due")
        /// Tab right
        public static let increaseIndent = L10n.tr("Localizable", "document.edit.action.increase-indent")
        /// Move down
        public static let moveDown = L10n.tr("Localizable", "document.edit.action.move-down")
        /// Move up
        public static let moveUp = L10n.tr("Localizable", "document.edit.action.move-up")
        /// Planning
        public static let planning = L10n.tr("Localizable", "document.edit.action.planning")
        /// Quote block
        public static let quoteBlock = L10n.tr("Localizable", "document.edit.action.quote-block")
        /// Redo
        public static let redo = L10n.tr("Localizable", "document.edit.action.redo")
        /// Schedule
        public static let schedule = L10n.tr("Localizable", "document.edit.action.schedule")
        /// Separator
        public static let separator = L10n.tr("Localizable", "document.edit.action.separator")
        /// Tag
        public static let tag = L10n.tr("Localizable", "document.edit.action.tag")
        /// Undo
        public static let undo = L10n.tr("Localizable", "document.edit.action.undo")
        public enum Mark {
          /// Bold
          public static let bold = L10n.tr("Localizable", "document.edit.action.mark.bold")
          /// Code
          public static let code = L10n.tr("Localizable", "document.edit.action.mark.code")
          /// Italic
          public static let italic = L10n.tr("Localizable", "document.edit.action.mark.italic")
          /// Strikthrough
          public static let strikthrough = L10n.tr("Localizable", "document.edit.action.mark.strikthrough")
          /// Underscore
          public static let underscore = L10n.tr("Localizable", "document.edit.action.mark.underscore")
          /// Verbatim
          public static let verbatim = L10n.tr("Localizable", "document.edit.action.mark.verbatim")
        }
      }
      public enum Date {
        /// All day
        public static let allDay = L10n.tr("Localizable", "document.edit.date.all-day")
      }
    }
    public enum Title {
      /// Untitled
      public static let untitled = L10n.tr("Localizable", "document.title.untitled")
    }
  }

  public enum General {
    public enum Button {
      public enum Title {
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "general.button.title.cancel")
        /// Delete
        public static let delete = L10n.tr("Localizable", "general.button.title.delete")
        /// Open
        public static let `open` = L10n.tr("Localizable", "general.button.title.open")
        /// Save
        public static let save = L10n.tr("Localizable", "general.button.title.save")
      }
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
