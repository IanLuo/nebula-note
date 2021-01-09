// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Dashboard
  public static let dashboard = L10n.tr("Localizable", "dashboard")

  public enum Activity {
    public enum Document {
      public enum CaptureTextActivity {
        /// Capture some ideas with words
        public static let description = L10n.tr("Localizable", "activity.document.CaptureTextActivity.description")
        /// Capture text
        public static let phrase = L10n.tr("Localizable", "activity.document.CaptureTextActivity.phrase")
        /// Capture Text
        public static let title = L10n.tr("Localizable", "activity.document.CaptureTextActivity.title")
      }
      public enum CaptureAudioActivity {
        /// Capture idea with voice
        public static let description = L10n.tr("Localizable", "activity.document.captureAudioActivity.description")
        /// Capture Voice
        public static let phrase = L10n.tr("Localizable", "activity.document.captureAudioActivity.phrase")
        /// Capture Voice
        public static let title = L10n.tr("Localizable", "activity.document.captureAudioActivity.title")
      }
      public enum CaptureImageLibraryActivity {
        /// Capture idea with image
        public static let description = L10n.tr("Localizable", "activity.document.captureImageLibraryActivity.description")
        /// Capture Image
        public static let phrase = L10n.tr("Localizable", "activity.document.captureImageLibraryActivity.phrase")
        /// Capture Image
        public static let title = L10n.tr("Localizable", "activity.document.captureImageLibraryActivity.title")
      }
      public enum CaptureLinkActivity {
        /// Capture idea by input a link
        public static let description = L10n.tr("Localizable", "activity.document.captureLinkActivity.description")
        /// Capture link
        public static let phrase = L10n.tr("Localizable", "activity.document.captureLinkActivity.phrase")
        /// Capture Link
        public static let title = L10n.tr("Localizable", "activity.document.captureLinkActivity.title")
      }
      public enum CaptureLocationActivity {
        /// Capture the location you are at
        public static let description = L10n.tr("Localizable", "activity.document.captureLocationActivity.description")
        /// Capture Location
        public static let phrase = L10n.tr("Localizable", "activity.document.captureLocationActivity.phrase")
        /// Capture Location
        public static let title = L10n.tr("Localizable", "activity.document.captureLocationActivity.title")
      }
      public enum CaptureSketchActivity {
        /// Cappture idea with drawing something
        public static let description = L10n.tr("Localizable", "activity.document.captureSketchActivity.description")
        /// Capture with Sketch
        public static let phrase = L10n.tr("Localizable", "activity.document.captureSketchActivity.phrase")
        /// Capture with Sketch
        public static let title = L10n.tr("Localizable", "activity.document.captureSketchActivity.title")
      }
      public enum CaptureVideoActivity {
        /// Capture idea with video
        public static let description = L10n.tr("Localizable", "activity.document.captureVideoActivity.description")
        /// Capture Videoc
        public static let phrase = L10n.tr("Localizable", "activity.document.captureVideoActivity.phrase")
        /// Capture Video
        public static let title = L10n.tr("Localizable", "activity.document.captureVideoActivity.title")
      }
      public enum CreateDocument {
        /// Create an empty new document
        public static let description = L10n.tr("Localizable", "activity.document.createDocument.description")
        /// New Document
        public static let phrase = L10n.tr("Localizable", "activity.document.createDocument.phrase")
        /// Create new document
        public static let title = L10n.tr("Localizable", "activity.document.createDocument.title")
      }
    }
  }

  public enum Agenda {
    /// in %@ days
    public static func daysAfter(_ p1: Any) -> String {
      return L10n.tr("Localizable", "agenda.daysAfter", String(describing: p1))
    }
    /// %@ days ago
    public static func daysBefore(_ p1: Any) -> String {
      return L10n.tr("Localizable", "agenda.daysBefore", String(describing: p1))
    }
    /// Due today
    public static let dueToday = L10n.tr("Localizable", "agenda.dueToday")
    /// Overdue %@ days
    public static func overdueDaysWihtPlaceHolder(_ p1: Any) -> String {
      return L10n.tr("Localizable", "agenda.overdueDaysWihtPlaceHolder", String(describing: p1))
    }
    /// Due yesterday
    public static let overdueYesterdayWihtPlaceHolder = L10n.tr("Localizable", "agenda.overdueYesterdayWihtPlaceHolder")
    /// Started %@ days ago
    public static func startDaysAgoWithPlaceHodler(_ p1: Any) -> String {
      return L10n.tr("Localizable", "agenda.startDaysAgoWithPlaceHodler", String(describing: p1))
    }
    /// Start in %@ days
    public static func startInDaysWithPlaceHolder(_ p1: Any) -> String {
      return L10n.tr("Localizable", "agenda.startInDaysWithPlaceHolder", String(describing: p1))
    }
    /// Start today
    public static let startToday = L10n.tr("Localizable", "agenda.startToday")
    /// Start tomorrow
    public static let startTomorrowWithPlaceHolder = L10n.tr("Localizable", "agenda.startTomorrowWithPlaceHolder")
    /// Started yesterday
    public static let startYesterdayWithPlaceHodlerYesterday = L10n.tr("Localizable", "agenda.startYesterdayWithPlaceHodlerYesterday")
    /// Agenda
    public static let title = L10n.tr("Localizable", "agenda.title")
    /// Today
    public static let today = L10n.tr("Localizable", "agenda.today")
    /// Tomorrow
    public static let tomorrow = L10n.tr("Localizable", "agenda.tomorrow")
    /// Will due in %@ days
    public static func willOverduInDaysWithPlaceHolder(_ p1: Any) -> String {
      return L10n.tr("Localizable", "agenda.willOverduInDaysWithPlaceHolder", String(describing: p1))
    }
    /// Will due tomorrow
    public static let willOverduTomorrowWithPlaceHolder = L10n.tr("Localizable", "agenda.willOverduTomorrowWithPlaceHolder")
    /// Yesterday
    public static let yesterday = L10n.tr("Localizable", "agenda.yesterday")
    public enum Sub {
      /// No tag
      public static let noTag = L10n.tr("Localizable", "agenda.sub.noTag")
      /// Overdue
      public static let overdue = L10n.tr("Localizable", "agenda.sub.overdue")
      /// Overdue soon
      public static let overdueSoon = L10n.tr("Localizable", "agenda.sub.overdueSoon")
      /// Status
      public static let planning = L10n.tr("Localizable", "agenda.sub.planning")
      /// Scheduled
      public static let scheduled = L10n.tr("Localizable", "agenda.sub.scheduled")
      /// Start soon
      public static let startSoon = L10n.tr("Localizable", "agenda.sub.startSoon")
      /// Tags
      public static let tags = L10n.tr("Localizable", "agenda.sub.tags")
      /// Today
      public static let today = L10n.tr("Localizable", "agenda.sub.today")
    }
  }

  public enum Attachment {
    /// Export
    public static let share = L10n.tr("Localizable", "attachment.share")
    public enum Kind {
      /// All
      public static let all = L10n.tr("Localizable", "attachment.kind.all")
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

  public enum Audio {
    public enum Player {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "audio.player.continue")
      /// Pause
      public static let pause = L10n.tr("Localizable", "audio.player.pause")
      /// Play
      public static let play = L10n.tr("Localizable", "audio.player.play")
      /// Stop
      public static let stop = L10n.tr("Localizable", "audio.player.stop")
    }
    public enum Recorder {
      /// Continue recording
      public static let `continue` = L10n.tr("Localizable", "audio.recorder.continue")
      /// Pause record
      public static let pause = L10n.tr("Localizable", "audio.recorder.pause")
      /// Restart record
      public static let restart = L10n.tr("Localizable", "audio.recorder.restart")
      /// Start record
      public static let start = L10n.tr("Localizable", "audio.recorder.start")
      /// Stop
      public static let stop = L10n.tr("Localizable", "audio.recorder.stop")
    }
  }

  public enum Browser {
    /// Folder is empty
    public static let empty = L10n.tr("Localizable", "browser.empty")
    /// File not exists
    public static let fileNotExisted = L10n.tr("Localizable", "browser.file-not-existed")
    /// Document management help
    public static let help = L10n.tr("Localizable", "browser.help")
    /// Documents
    public static let title = L10n.tr("Localizable", "browser.title")
    public enum Action {
      /// Create New Document
      public static let new = L10n.tr("Localizable", "browser.action.new")
      public enum MoveTo {
        /// Choose a parent
        public static let msg = L10n.tr("Localizable", "browser.action.moveTo.msg")
        /// Move to
        public static let title = L10n.tr("Localizable", "browser.action.moveTo.title")
      }
      public enum Rename {
        /// New name
        public static let newName = L10n.tr("Localizable", "browser.action.rename.newName")
        public enum Warning {
          /// Name is taken
          public static let nameIsTaken = L10n.tr("Localizable", "browser.action.rename.warning.nameIsTaken")
        }
      }
    }
    public enum Actions {
      /// Edit Cover
      public static let cover = L10n.tr("Localizable", "browser.actions.cover")
      /// Delete
      public static let delete = L10n.tr("Localizable", "browser.actions.delete")
      /// Duplicate
      public static let duplicate = L10n.tr("Localizable", "browser.actions.duplicate")
      /// New Sub Document
      public static let newSub = L10n.tr("Localizable", "browser.actions.newSub")
      /// Rename
      public static let rename = L10n.tr("Localizable", "browser.actions.rename")
      /// Perform Actions
      public static let title = L10n.tr("Localizable", "browser.actions.title")
      public enum Delete {
        /// Are you sure you want to delete '%@' and it's all child documents?
        public static func confirm(_ p1: Any) -> String {
          return L10n.tr("Localizable", "browser.actions.delete.confirm", String(describing: p1))
        }
      }
    }
    public enum FileNotExisted {
      /// Please check if the file is renamed or moved
      public static let message = L10n.tr("Localizable", "browser.file-not-existed.message")
    }
    public enum Outline {
      /// Document begining
      public static let beginingOfDocument = L10n.tr("Localizable", "browser.outline.beginingOfDocument")
      /// Document ending
      public static let endOfDocument = L10n.tr("Localizable", "browser.outline.endOfDocument")
    }
    public enum Title {
      /// Copy
      public static let copyExt = L10n.tr("Localizable", "browser.title.copyExt")
      /// Untitled
      public static let untitled = L10n.tr("Localizable", "browser.title.untitled")
    }
  }

  public enum CaptureLink {
    /// Add link
    public static let title = L10n.tr("Localizable", "captureLink.title")
    public enum Title {
      /// The tile of the link
      public static let placeholder = L10n.tr("Localizable", "captureLink.title.placeholder")
      /// Title
      public static let title = L10n.tr("Localizable", "captureLink.title.title")
    }
    public enum Url {
      /// The link address
      public static let placeholder = L10n.tr("Localizable", "captureLink.url.placeholder")
      /// URL
      public static let title = L10n.tr("Localizable", "captureLink.url.title")
    }
  }

  public enum CaptureList {
    /// All ideas are handled
    public static let empty = L10n.tr("Localizable", "captureList.empty")
    /// Ideas
    public static let title = L10n.tr("Localizable", "captureList.title")
    public enum Action {
      /// Copy to document
      public static let copyToDocument = L10n.tr("Localizable", "captureList.action.copyToDocument")
      /// Delete idea
      public static let delete = L10n.tr("Localizable", "captureList.action.delete")
      /// Are your sure de delete this idea?
      public static let deleteConfirm = L10n.tr("Localizable", "captureList.action.deleteConfirm")
      /// Move to document
      public static let moveToDocument = L10n.tr("Localizable", "captureList.action.moveToDocument")
      /// Open link
      public static let openLink = L10n.tr("Localizable", "captureList.action.openLink")
      /// Open location
      public static let openLocation = L10n.tr("Localizable", "captureList.action.openLocation")
      /// Refile
      public static let refile = L10n.tr("Localizable", "captureList.action.refile")
      /// Action
      public static let title = L10n.tr("Localizable", "captureList.action.title")
    }
    public enum Choose {
      /// Choose idea
      public static let title = L10n.tr("Localizable", "captureList.choose.title")
    }
    public enum Confirm {
      /// Refile done, do you want to delete this idea?
      public static let delete = L10n.tr("Localizable", "captureList.confirm.delete")
    }
  }

  public enum CaptureText {
    /// Add text
    public static let title = L10n.tr("Localizable", "captureText.title")
    public enum Text {
      /// text
      public static let title = L10n.tr("Localizable", "captureText.text.title")
    }
  }

  public enum Document {
    public enum Browser {
      public enum Delete {
        /// Delete this file?
        public static let confirm = L10n.tr("Localizable", "document.browser.delete.confirm")
      }
    }
    public enum DateAndTime {
      /// Due
      public static let due = L10n.tr("Localizable", "document.dateAndTime.due")
      /// Schedule
      public static let schedule = L10n.tr("Localizable", "document.dateAndTime.schedule")
      /// Date and time
      public static let title = L10n.tr("Localizable", "document.dateAndTime.title")
      /// Update date and time
      public static let update = L10n.tr("Localizable", "document.dateAndTime.update")
      public enum Repeat {
        /// Day
        public static let daily = L10n.tr("Localizable", "document.dateAndTime.repeat.daily")
        /// Month
        public static let monthly = L10n.tr("Localizable", "document.dateAndTime.repeat.monthly")
        /// Dont‘s Repeat
        public static let `none` = L10n.tr("Localizable", "document.dateAndTime.repeat.none")
        /// Quarter
        public static let quarterly = L10n.tr("Localizable", "document.dateAndTime.repeat.quarterly")
        /// Repeat
        public static let title = L10n.tr("Localizable", "document.dateAndTime.repeat.title")
        /// Week
        public static let weekly = L10n.tr("Localizable", "document.dateAndTime.repeat.weekly")
        /// Year
        public static let yearly = L10n.tr("Localizable", "document.dateAndTime.repeat.yearly")
      }
    }
    public enum Edit {
      /// Backlink
      public static let backlink = L10n.tr("Localizable", "document.edit.backlink")
      /// Keep this one
      public static let remoteEditingArrivedKeepThisOne = L10n.tr("Localizable", "document.edit.remote_editing_arrived_keep_this_one")
      /// Which version do you want to keep?
      public static let remoteEditingArrivedMessage = L10n.tr("Localizable", "document.edit.remote_editing_arrived_message")
      /// Found newer version from another device, reload?
      public static let remoteEditingArrivedTitle = L10n.tr("Localizable", "document.edit.remote_editing_arrived_title")
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
        /// Status
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
        public enum Help {
          /// Date and time help
          public static let dateAndTime = L10n.tr("Localizable", "document.edit.action.help.dateAndTime")
        }
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
        public enum Paragraph {
          /// Section actions
          public static let title = L10n.tr("Localizable", "document.edit.action.paragraph.title")
        }
        public enum Section {
          /// Delete current section
          public static let delete = L10n.tr("Localizable", "document.edit.action.section.delete")
        }
      }
      public enum Conflict {
        /// Current device
        public static let current = L10n.tr("Localizable", "document.edit.conflict.current")
        /// Choose the version you want to keep
        public static let description = L10n.tr("Localizable", "document.edit.conflict.description")
        /// Detect confliction
        public static let found = L10n.tr("Localizable", "document.edit.conflict.found")
        /// Sure to keep this version?
        public static let warning = L10n.tr("Localizable", "document.edit.conflict.warning")
      }
      public enum Create {
        /// Failed to create document
        public static let failed = L10n.tr("Localizable", "document.edit.create.failed")
      }
      public enum Date {
        /// All day
        public static let allDay = L10n.tr("Localizable", "document.edit.date.all-day")
      }
      public enum DocumentLink {
        /// Edit document link title
        public static let title = L10n.tr("Localizable", "document.edit.document_link.title")
      }
      public enum Image {
        /// Use as cover
        public static let useAsCover = L10n.tr("Localizable", "document.edit.image.use-as-cover")
      }
      public enum RemoteEditingArrivedKeepRemote {
        /// Keep remote one
        public static let one = L10n.tr("Localizable", "document.edit.remote_editing_arrived_keep_remote.one")
      }
      public enum Sketch {
        /// Brush
        public static let brush = L10n.tr("Localizable", "document.edit.sketch.brush")
        /// Color
        public static let color = L10n.tr("Localizable", "document.edit.sketch.color")
        /// Pick brush size
        public static let pickBrushSize = L10n.tr("Localizable", "document.edit.sketch.pickBrushSize")
        /// Pick color
        public static let pickColor = L10n.tr("Localizable", "document.edit.sketch.pickColor")
      }
      public enum Tag {
        /// Add new tag
        public static let add = L10n.tr("Localizable", "document.edit.tag.add")
        /// Choose
        public static let choose = L10n.tr("Localizable", "document.edit.tag.choose")
        /// New tag name
        public static let placeHolder = L10n.tr("Localizable", "document.edit.tag.place-holder")
        /// Edit tag
        public static let title = L10n.tr("Localizable", "document.edit.tag.title")
        /// Don't use special characters in tag
        public static let validation = L10n.tr("Localizable", "document.edit.tag.validation")
      }
    }
    public enum Export {
      /// HTML
      public static let html = L10n.tr("Localizable", "document.export.html")
      /// Mark Down
      public static let md = L10n.tr("Localizable", "document.export.md")
      /// Choose a file format
      public static let msg = L10n.tr("Localizable", "document.export.msg")
      /// Org mode
      public static let org = L10n.tr("Localizable", "document.export.org")
      /// Export
      public static let title = L10n.tr("Localizable", "document.export.title")
    }
    public enum Heading {
      /// Create section entry above
      public static let addHeadingAboveIt = L10n.tr("Localizable", "document.heading.addHeadingAboveIt")
      /// Create section entry below
      public static let addHeadingBelowIt = L10n.tr("Localizable", "document.heading.addHeadingBelowIt")
      /// Create sub section entry
      public static let addSubHeadingBelow = L10n.tr("Localizable", "document.heading.addSubHeadingBelow")
      /// Fold this section
      public static let fold = L10n.tr("Localizable", "document.heading.fold")
      /// Move section
      public static let moveTo = L10n.tr("Localizable", "document.heading.moveTo")
      /// Move to another document
      public static let moveToAnotherDocument = L10n.tr("Localizable", "document.heading.moveToAnotherDocument")
      /// Heading
      public static let title = L10n.tr("Localizable", "document.heading.title")
      /// Convert to section heading
      public static let toHeading = L10n.tr("Localizable", "document.heading.toHeading")
      /// Convert to plain content
      public static let toParagraphContent = L10n.tr("Localizable", "document.heading.toParagraphContent")
      /// Unfold this section
      public static let unfold = L10n.tr("Localizable", "document.heading.unfold")
    }
    public enum Help {
      /// Understand heading entrance
      public static let entrance = L10n.tr("Localizable", "document.help.entrance")
      /// Marks syntax help
      public static let markSyntax = L10n.tr("Localizable", "document.help.markSyntax")
      /// More help topics
      public static let more = L10n.tr("Localizable", "document.help.more")
      /// Text editor help
      public static let textEditor = L10n.tr("Localizable", "document.help.textEditor")
    }
    public enum Info {
      /// Character count
      public static let characterCount = L10n.tr("Localizable", "document.info.characterCount")
      /// Create date
      public static let createDate = L10n.tr("Localizable", "document.info.createDate")
      /// Edit date
      public static let editDate = L10n.tr("Localizable", "document.info.editDate")
      /// Section count
      public static let paragraphCount = L10n.tr("Localizable", "document.info.paragraphCount")
      /// Word count
      public static let wordCount = L10n.tr("Localizable", "document.info.wordCount")
    }
    public enum Link {
      /// Edit link
      public static let edit = L10n.tr("Localizable", "document.link.edit")
      /// Change Document
      public static let editDocumentLink = L10n.tr("Localizable", "document.link.editDocumentLink")
      /// Open link in browser
      public static let `open` = L10n.tr("Localizable", "document.link.open")
      /// Go to document
      public static let openDocumentLink = L10n.tr("Localizable", "document.link.openDocumentLink")
    }
    public enum Menu {
      /// Capture an idea
      public static let capture = L10n.tr("Localizable", "document.menu.capture")
      /// Editing mode
      public static let enableEditingMode = L10n.tr("Localizable", "document.menu.enableEditingMode")
      /// Reading mode
      public static let enableReadingMode = L10n.tr("Localizable", "document.menu.enableReadingMode")
      /// Fold all
      public static let foldAll = L10n.tr("Localizable", "document.menu.foldAll")
      /// Full screen
      public static let fullScreen = L10n.tr("Localizable", "document.menu.fullScreen")
      /// Document Info
      public static let info = L10n.tr("Localizable", "document.menu.info")
      /// Show outline
      public static let outline = L10n.tr("Localizable", "document.menu.outline")
      /// Menu
      public static let title = L10n.tr("Localizable", "document.menu.title")
      /// Unfold all
      public static let unfoldAll = L10n.tr("Localizable", "document.menu.unfoldAll")
    }
    public enum Outlet {
      /// No heading
      public static let noHeading = L10n.tr("Localizable", "document.outlet.noHeading")
    }
    public enum Planning {
      /// Status
      public static let title = L10n.tr("Localizable", "document.planning.title")
    }
    public enum Priority {
      /// Remove priority
      public static let remove = L10n.tr("Localizable", "document.priority.remove")
      /// Priority
      public static let title = L10n.tr("Localizable", "document.priority.title")
    }
    public enum Record {
      /// Record voice
      public static let title = L10n.tr("Localizable", "document.record.title")
    }
  }

  public enum Fail {
    /// Network error, please try again
    public static let network = L10n.tr("Localizable", "fail.network")
    /// Upload error, please try again
    public static let upload = L10n.tr("Localizable", "fail.upload")
  }

  public enum General {
    /// Fail
    public static let fail = L10n.tr("Localizable", "general.fail")
    /// Help
    public static let help = L10n.tr("Localizable", "general.help")
    /// Success
    public static let success = L10n.tr("Localizable", "general.success")
    public enum Button {
      /// OK
      public static let ok = L10n.tr("Localizable", "general.button.ok")
      public enum Title {
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "general.button.title.cancel")
        /// Close
        public static let close = L10n.tr("Localizable", "general.button.title.close")
        /// Delete
        public static let delete = L10n.tr("Localizable", "general.button.title.delete")
        /// Open
        public static let `open` = L10n.tr("Localizable", "general.button.title.open")
        /// Save
        public static let save = L10n.tr("Localizable", "general.button.title.save")
        /// Select
        public static let select = L10n.tr("Localizable", "general.button.title.select")
      }
    }
    public enum Loading {
      /// Loading...
      public static let title = L10n.tr("Localizable", "general.loading.title")
    }
  }

  public enum Guide {
    public enum Document {
      public enum Edit {
        /// Tap on heading button to create an heading entry
        public static let headingEntry = L10n.tr("Localizable", "guide.document.edit.headingEntry")
      }
    }
  }

  public enum ImagePicker {
    /// Add image
    public static let add = L10n.tr("Localizable", "imagePicker.add")
    /// Camera
    public static let camera = L10n.tr("Localizable", "imagePicker.camera")
    /// Files
    public static let files = L10n.tr("Localizable", "imagePicker.files")
    /// Photo library
    public static let library = L10n.tr("Localizable", "imagePicker.library")
  }

  public enum Key {
    public enum Command {
      /// Insert New Attachment
      public static let addAttachment = L10n.tr("Localizable", "key.command.addAttachment")
      /// Show Agenda
      public static let agendaTab = L10n.tr("Localizable", "key.command.agendaTab")
      /// Bold Text
      public static let boldText = L10n.tr("Localizable", "key.command.boldText")
      /// Show Documents
      public static let browserTab = L10n.tr("Localizable", "key.command.browserTab")
      /// Capture Ideas
      public static let captureTab = L10n.tr("Localizable", "key.command.captureTab")
      /// Toggle Checkbox
      public static let checkbox = L10n.tr("Localizable", "key.command.checkbox")
      /// Insert Code Block
      public static let codeBlock = L10n.tr("Localizable", "key.command.codeBlock")
      /// Show Date And Time Menu
      public static let dateAndTime = L10n.tr("Localizable", "key.command.dateAndTime")
      /// Insert Document Link
      public static let fileLink = L10n.tr("Localizable", "key.command.fileLink")
      /// Fold All
      public static let foldAll = L10n.tr("Localizable", "key.command.foldAll")
      /// Toggle Fold/Unfold
      public static let foldOrUnfoldHeading = L10n.tr("Localizable", "key.command.foldOrUnfoldHeading")
      /// Fold Others
      public static let foldOthersExcpet = L10n.tr("Localizable", "key.command.foldOthersExcpet")
      /// Show Headings Action
      public static let headingMenu = L10n.tr("Localizable", "key.command.headingMenu")
      /// Highlight Text
      public static let highlightText = L10n.tr("Localizable", "key.command.highlightText")
      /// Show Ideas
      public static let ideaTab = L10n.tr("Localizable", "key.command.ideaTab")
      /// Show Inspector
      public static let inspector = L10n.tr("Localizable", "key.command.inspector")
      /// Italic Text
      public static let italicText = L10n.tr("Localizable", "key.command.italicText")
      /// Toggle Bullet List
      public static let list = L10n.tr("Localizable", "key.command.list")
      /// Move Down
      public static let moveDown = L10n.tr("Localizable", "key.command.moveDown")
      /// Move Left
      public static let moveLeft = L10n.tr("Localizable", "key.command.moveLeft")
      /// Move Right
      public static let moveRight = L10n.tr("Localizable", "key.command.moveRight")
      /// Move Up
      public static let moveUp = L10n.tr("Localizable", "key.command.moveUp")
      /// Toggle Ordered List
      public static let orderedList = L10n.tr("Localizable", "key.command.orderedList")
      /// Show Outline
      public static let outline = L10n.tr("Localizable", "key.command.outline")
      /// Show Paragraph Action
      public static let paragraphMenu = L10n.tr("Localizable", "key.command.paragraphMenu")
      /// Picker From Attachments
      public static let pickerAttachmentMenu = L10n.tr("Localizable", "key.command.pickerAttachmentMenu")
      /// Insert From Ideas
      public static let pickIdeaMenu = L10n.tr("Localizable", "key.command.pickIdeaMenu")
      /// Show Priority Actions
      public static let priorityMenu = L10n.tr("Localizable", "key.command.priorityMenu")
      /// Insert Quote Block
      public static let quoteBlock = L10n.tr("Localizable", "key.command.quoteBlock")
      /// Save
      public static let save = L10n.tr("Localizable", "key.command.save")
      /// Show Search
      public static let searchTab = L10n.tr("Localizable", "key.command.searchTab")
      /// Insert Separator
      public static let seperator = L10n.tr("Localizable", "key.command.seperator")
      /// Show Status Actions
      public static let statusMenu = L10n.tr("Localizable", "key.command.statusMenu")
      /// Strike Through Text
      public static let strikeThroughText = L10n.tr("Localizable", "key.command.strikeThroughText")
      /// Show Tag Actions
      public static let tagMenu = L10n.tr("Localizable", "key.command.tagMenu")
      /// Toggle Full Width Editor
      public static let toggleFullWidth = L10n.tr("Localizable", "key.command.toggleFullWidth")
      /// Toggle Left Part
      public static let toggleLeftPart = L10n.tr("Localizable", "key.command.toggleLeftPart")
      /// Toggle Middle Part
      public static let toggleMiddlePart = L10n.tr("Localizable", "key.command.toggleMiddlePart")
      /// Underscore Text
      public static let underscoreText = L10n.tr("Localizable", "key.command.underscoreText")
      /// Unfold All
      public static let unfoldAll = L10n.tr("Localizable", "key.command.unfoldAll")
      public enum Group {
        /// Action
        public static let action = L10n.tr("Localizable", "key.command.group.action")
        /// Attachment
        public static let attachment = L10n.tr("Localizable", "key.command.group.attachment")
        /// Capture
        public static let capture = L10n.tr("Localizable", "key.command.group.capture")
        /// Edit
        public static let edit = L10n.tr("Localizable", "key.command.group.edit")
        /// Insert
        public static let insert = L10n.tr("Localizable", "key.command.group.insert")
        /// Other
        public static let other = L10n.tr("Localizable", "key.command.group.other")
        /// Text
        public static let text = L10n.tr("Localizable", "key.command.group.text")
        /// View
        public static let view = L10n.tr("Localizable", "key.command.group.view")
      }
    }
  }

  public enum Location {
    /// Current location
    public static let current = L10n.tr("Localizable", "location.current")
    /// Add a location
    public static let title = L10n.tr("Localizable", "location.title")
  }

  public enum Membership {
    /// If you enjoy using x3 note, please consider joining membership, to unlock all advanced functions, support the continuous development, and bring you more powerfurl and useful functions.
    public static let letter = L10n.tr("Localizable", "membership.letter")
    /// About member subscription
    public static let moreHelp = L10n.tr("Localizable", "membership.moreHelp")
    /// Ordered
    public static let ordered = L10n.tr("Localizable", "membership.ordered")
    /// Restore purchase
    public static let restore = L10n.tr("Localizable", "membership.restore")
    /// Membership plan
    public static let title = L10n.tr("Localizable", "membership.title")
    public enum Function {
      /// Advanced attachments, including Location, Audio and Video
      public static let advancedAttachments = L10n.tr("Localizable", "membership.function.advancedAttachments")
      /// And more to come
      public static let andMoreToCome = L10n.tr("Localizable", "membership.function.andMoreToCome")
      /// Custom section status
      public static let customStatus = L10n.tr("Localizable", "membership.function.customStatus")
      /// Move section to other document
      public static let moveToOtherDocument = L10n.tr("Localizable", "membership.function.moveToOtherDocument")
      /// Refile from capturelist
      public static let refile = L10n.tr("Localizable", "membership.function.refile")
      /// Remove export waterprint
      public static let removeExportWaterprint = L10n.tr("Localizable", "membership.function.removeExportWaterprint")
      /// As a member, you will be able to access advanced features as follow:
      public static let title = L10n.tr("Localizable", "membership.function.title")
      /// Unlimited level of sub documents
      public static let unlimitedLevelOfSubDocuments = L10n.tr("Localizable", "membership.function.unlimitedLevelOfSubDocuments")
    }
    public enum Monthly {
      /// (1 bonus week) unlimited function access
      public static let description = L10n.tr("Localizable", "membership.monthly.description")
      /// Order membership monthly
      public static let title = L10n.tr("Localizable", "membership.monthly.title")
    }
    public enum Price {
      /// $1.49 USD
      public static let monthly = L10n.tr("Localizable", "membership.price.monthly")
      /// $13.49 USD
      public static let yearly = L10n.tr("Localizable", "membership.price.yearly")
    }
    public enum Yearly {
      /// (1 bonus month) unlimited function access
      public static let description = L10n.tr("Localizable", "membership.yearly.description")
      /// Order membership yearly
      public static let title = L10n.tr("Localizable", "membership.yearly.title")
    }
  }

  public enum Publish {
    /// Choose
    public static let choose = L10n.tr("Localizable", "publish.choose")
    /// Successflully published to %@
    public static func complete(_ p1: Any) -> String {
      return L10n.tr("Localizable", "publish.complete", String(describing: p1))
    }
    /// Clear saved publish related login info
    public static let deleteSavedPublishInfo = L10n.tr("Localizable", "publish.delete-saved-publish-info")
    /// Publish
    public static let title = L10n.tr("Localizable", "publish.title")
    public enum Attachment {
      /// Chosse Attachment Storage Service
      public static let storageService = L10n.tr("Localizable", "publish.attachment.storage-service")
      public enum StorageService {
        /// If you have attachments used in your document that about to publish, there need a place to store the attachments, such as images, videos, audios, otherwise it will not be able to display in your article on that platform, if you want the attachment be visiable on those platforms, you should choose a service to use, and if you can't find the service you like, you can give us feedback on the forum or through the feedback in this app.
        public static let description = L10n.tr("Localizable", "publish.attachment.storage-service.description")
      }
    }
    public enum DeleteSavedPublishInfo {
      /// Clear all login info？
      public static let confirm = L10n.tr("Localizable", "publish.delete-saved-publish-info.confirm")
      /// All login info cleared
      public static let feedback = L10n.tr("Localizable", "publish.delete-saved-publish-info.feedback")
    }
    public enum Platform {
      /// Platform is where your article will be post to, more platforms will be added in the future, if you can't find the platform you are using, please try to feedback us on the forum or through the feedback
      public static let description = L10n.tr("Localizable", "publish.platform.description")
      /// Choose Platform
      public static let pick = L10n.tr("Localizable", "publish.platform.pick")
    }
  }

  public enum Search {
    /// Search
    public static let title = L10n.tr("Localizable", "search.title")
  }

  public enum Selector {
    /// No item
    public static let empty = L10n.tr("Localizable", "selector.empty")
  }

  public enum Setting {
    /// Feedback
    public static let feedback = L10n.tr("Localizable", "setting.feedback")
    /// Privicy policy
    public static let privacy = L10n.tr("Localizable", "setting.privacy")
    /// Store location
    public static let storeLocation = L10n.tr("Localizable", "setting.storeLocation")
    /// Syncing in progress
    public static let syncingInProgress = L10n.tr("Localizable", "setting.syncingInProgress")
    /// Terms of service
    public static let terms = L10n.tr("Localizable", "setting.terms")
    /// Settings
    public static let title = L10n.tr("Localizable", "setting.title")
    public enum Alert {
      /// Fail to configure sync
      public static let failToStoreIniCloud = L10n.tr("Localizable", "setting.alert.failToStoreIniCloud")
      public enum IcloudIsNotEnabled {
        /// Please login your iCloud account
        public static let msg = L10n.tr("Localizable", "setting.alert.icloudIsNotEnabled.msg")
        /// iCloud is not enabled
        public static let title = L10n.tr("Localizable", "setting.alert.icloudIsNotEnabled.title")
      }
    }
    public enum Editor {
      /// Fold all entries when open
      public static let foldAllWhenOpen = L10n.tr("Localizable", "setting.editor.foldAllWhenOpen")
      /// Editor
      public static let title = L10n.tr("Localizable", "setting.editor.title")
    }
    public enum Export {
      /// Show index
      public static let showIndex = L10n.tr("Localizable", "setting.export.showIndex")
      /// Export
      public static let title = L10n.tr("Localizable", "setting.export.title")
    }
    public enum Feedback {
      /// I want to join the forum
      public static let forum = L10n.tr("Localizable", "setting.feedback.forum")
      /// I want to share to others
      public static let promot = L10n.tr("Localizable", "setting.feedback.promot")
      /// I want to give x3 note a 5 star
      public static let rate = L10n.tr("Localizable", "setting.feedback.rate")
      /// How do you think of x3 note?
      public static let title = L10n.tr("Localizable", "setting.feedback.title")
    }
    public enum General {
      /// General
      public static let title = L10n.tr("Localizable", "setting.general.title")
    }
    public enum InterfaceStyle {
      /// Auto
      public static let auto = L10n.tr("Localizable", "setting.interfaceStyle.auto")
      /// Dark
      public static let dark = L10n.tr("Localizable", "setting.interfaceStyle.dark")
      /// Light
      public static let light = L10n.tr("Localizable", "setting.interfaceStyle.light")
      /// Interface style
      public static let title = L10n.tr("Localizable", "setting.interfaceStyle.title")
    }
    public enum LandingTab {
      /// Choose landing tab
      public static let title = L10n.tr("Localizable", "setting.landingTab.title")
    }
    public enum ManageAttachment {
      /// Manage attachments
      public static let title = L10n.tr("Localizable", "setting.manageAttachment.title")
      public enum Choose {
        /// All attachments
        public static let title = L10n.tr("Localizable", "setting.manageAttachment.choose.title")
      }
      public enum Delete {
        /// Delete selected attachments?
        public static let title = L10n.tr("Localizable", "setting.manageAttachment.delete.title")
      }
    }
    public enum Planning {
      /// Customized status
      public static let title = L10n.tr("Localizable", "setting.planning.title")
      public enum Add {
        public enum Error {
          /// Status name is taken, Use a different one
          public static let nameTaken = L10n.tr("Localizable", "setting.planning.add.error.nameTaken")
        }
      }
      public enum Finish {
        /// New Finish status
        public static let add = L10n.tr("Localizable", "setting.planning.finish.add")
        /// Finish
        public static let title = L10n.tr("Localizable", "setting.planning.finish.title")
      }
      public enum Unfinish {
        /// New Unfinish status
        public static let add = L10n.tr("Localizable", "setting.planning.unfinish.add")
        /// Unfinish
        public static let title = L10n.tr("Localizable", "setting.planning.unfinish.title")
      }
    }
    public enum Store {
      /// Store
      public static let title = L10n.tr("Localizable", "setting.store.title")
    }
    public enum StoreLocation {
      /// On iCloud
      public static let iCloud = L10n.tr("Localizable", "setting.storeLocation.iCloud")
      /// On device
      public static let onDevice = L10n.tr("Localizable", "setting.storeLocation.onDevice")
    }
  }

  public enum Sync {
    public enum Alert {
      public enum Account {
        /// After turning off iCloud, all you documents can only be accessed from this device. cloud backup, and documents on other devices, will all be deleted. You can switch back on later. Continue?
        public static let switchOff = L10n.tr("Localizable", "sync.alert.account.switchOff")
        public enum Changed {
          /// You have login another iCloud account, your document is now access from that account's storage
          public static let msg = L10n.tr("Localizable", "sync.alert.account.changed.msg")
          /// iCloud account changed
          public static let title = L10n.tr("Localizable", "sync.alert.account.changed.title")
        }
        public enum Closed {
          /// You have turned off iCloud on this app, your documents are stored on the iCloud stoage safely, if you want to access them, please turn iCloud on
          public static let msg = L10n.tr("Localizable", "sync.alert.account.closed.msg")
          /// iCloud account closed
          public static let title = L10n.tr("Localizable", "sync.alert.account.closed.title")
        }
      }
      public enum Status {
        public enum Off {
          /// Now everything is stored locally on your iPhone, you can turn on iCloud later in the configuration
          public static let msg = L10n.tr("Localizable", "sync.alert.status.off.msg")
          /// Not using iCloud storage
          public static let title = L10n.tr("Localizable", "sync.alert.status.off.title")
        }
        public enum On {
          /// Now everything is stored using iCloud, you can access them on all of your devices
          public static let msg = L10n.tr("Localizable", "sync.alert.status.on.msg")
          /// Using iCloud storage
          public static let title = L10n.tr("Localizable", "sync.alert.status.on.title")
        }
      }
    }
    public enum Confirm {
      /// Do you want use iCloud to store, your documents. If so, you will be able to access the contents from any device with your iCloud account, and they will be kept safe if you remove the app, or even lose your device.
      public static let useiCloud = L10n.tr("Localizable", "sync.confirm.useiCloud")
    }
  }

  public enum Trash {
    /// Delete
    public static let delete = L10n.tr("Localizable", "trash.delete")
    /// Put Back the file
    public static let recover = L10n.tr("Localizable", "trash.recover")
    /// Delete All
    public static let removeAll = L10n.tr("Localizable", "trash.removeAll")
    /// Trash
    public static let title = L10n.tr("Localizable", "trash.title")
    public enum Delete {
      /// File will be deleted and won't be able to recover
      public static let warning = L10n.tr("Localizable", "trash.delete.warning")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
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
