// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
public enum L10n {

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
    public static func daysAfter(_ p1: String) -> String {
      return L10n.tr("Localizable", "agenda.daysAfter", p1)
    }
    /// %@ days ago
    public static func daysBefore(_ p1: String) -> String {
      return L10n.tr("Localizable", "agenda.daysBefore", p1)
    }
    /// Due today
    public static let dueToday = L10n.tr("Localizable", "agenda.dueToday")
    /// Overdue %@ days
    public static func overdueDaysWihtPlaceHolder(_ p1: String) -> String {
      return L10n.tr("Localizable", "agenda.overdueDaysWihtPlaceHolder", p1)
    }
    /// Due yesterday
    public static let overdueYesterdayWihtPlaceHolder = L10n.tr("Localizable", "agenda.overdueYesterdayWihtPlaceHolder")
    /// Started %@ days ago
    public static func startDaysAgoWithPlaceHodler(_ p1: String) -> String {
      return L10n.tr("Localizable", "agenda.startDaysAgoWithPlaceHodler", p1)
    }
    /// Start in %@ days
    public static func startInDaysWithPlaceHolder(_ p1: String) -> String {
      return L10n.tr("Localizable", "agenda.startInDaysWithPlaceHolder", p1)
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
    public static func willOverduInDaysWithPlaceHolder(_ p1: String) -> String {
      return L10n.tr("Localizable", "agenda.willOverduInDaysWithPlaceHolder", p1)
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
    }
  }

  public enum Attachment {
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
        public static func confirm(_ p1: String) -> String {
          return L10n.tr("Localizable", "browser.actions.delete.confirm", p1)
        }
      }
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
    /// Captured ideas
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
    }
    public enum Edit {
      /// Keep this one
      public static let remoteEditingArrivedKeepThisOne = L10n.tr("Localizable", "document.edit.remote_editing_arrived_keep_this_one")
      /// Which version do you want to keep?
      public static let remoteEditingArrivedMessage = L10n.tr("Localizable", "document.edit.remote_editing_arrived_message")
      /// Another device modified this document
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
          /// Paragraph actions
          public static let title = L10n.tr("Localizable", "document.edit.action.paragraph.title")
        }
      }
      public enum Create {
        /// Failed to create document
        public static let failed = L10n.tr("Localizable", "document.edit.create.failed")
      }
      public enum Date {
        /// All day
        public static let allDay = L10n.tr("Localizable", "document.edit.date.all-day")
      }
      public enum Image {
        /// Use as cover
        public static let useAsCover = L10n.tr("Localizable", "document.edit.image.use-as-cover")
      }
      public enum RemoteEditingArrivedKeepRemote {
        /// Keep remote one
        public static let one = L10n.tr("Localizable", "document.edit.remote_editing_arrived_keep_remote.one")
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
      /// Fold this paragaph
      public static let fold = L10n.tr("Localizable", "document.heading.fold")
      /// Move to ..
      public static let moveTo = L10n.tr("Localizable", "document.heading.moveTo")
      /// Move to other document ..
      public static let moveToAnotherDocument = L10n.tr("Localizable", "document.heading.moveToAnotherDocument")
      /// Heading
      public static let title = L10n.tr("Localizable", "document.heading.title")
      /// Convert to heading
      public static let toHeading = L10n.tr("Localizable", "document.heading.toHeading")
      /// Convert to content
      public static let toParagraphContent = L10n.tr("Localizable", "document.heading.toParagraphContent")
      /// Unfold this paragraph
      public static let unfold = L10n.tr("Localizable", "document.heading.unfold")
    }
    public enum Info {
      /// Character count
      public static let characterCount = L10n.tr("Localizable", "document.info.characterCount")
      /// Create date
      public static let createDate = L10n.tr("Localizable", "document.info.createDate")
      /// Edit date
      public static let editDate = L10n.tr("Localizable", "document.info.editDate")
      /// Paragraph count
      public static let paragraphCount = L10n.tr("Localizable", "document.info.paragraphCount")
      /// Word count
      public static let wordCount = L10n.tr("Localizable", "document.info.wordCount")
    }
    public enum Link {
      /// Edit link
      public static let edit = L10n.tr("Localizable", "document.link.edit")
      /// Open link in browser
      public static let `open` = L10n.tr("Localizable", "document.link.open")
    }
    public enum Menu {
      /// Capture an idea
      public static let capture = L10n.tr("Localizable", "document.menu.capture")
      /// Fold all
      public static let foldAll = L10n.tr("Localizable", "document.menu.foldAll")
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
  }

  public enum General {
    public enum Button {
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
      }
    }
    public enum Loading {
      /// Loading...
      public static let title = L10n.tr("Localizable", "general.loading.title")
    }
  }

  public enum ImagePicker {
    /// Add image
    public static let add = L10n.tr("Localizable", "imagePicker.add")
    /// Camera
    public static let camera = L10n.tr("Localizable", "imagePicker.camera")
    /// Photo library
    public static let library = L10n.tr("Localizable", "imagePicker.library")
  }

  public enum Location {
    /// Current location
    public static let current = L10n.tr("Localizable", "location.current")
    /// Add a location
    public static let title = L10n.tr("Localizable", "location.title")
  }

  public enum Membership {
    /// Dear customer, if you feel enjoy using Icetea, please consider join our membership, to use more advanced functions, and help to bring Icetea to more platforms and become better, Icetea will become more strong, powerful, and useful to you.
    public static let letter = L10n.tr("Localizable", "membership.letter")
    /// Ordered
    public static let ordered = L10n.tr("Localizable", "membership.ordered")
    /// Membershipt
    public static let title = L10n.tr("Localizable", "membership.title")
    public enum Monthly {
      /// (1 extra week) unlimited function access
      public static let description = L10n.tr("Localizable", "membership.monthly.description")
      /// Order membership monthly
      public static let title = L10n.tr("Localizable", "membership.monthly.title")
    }
    public enum Yearly {
      /// (1 extra month) unlimited function access
      public static let description = L10n.tr("Localizable", "membership.yearly.description")
      /// Order membership yearly
      public static let title = L10n.tr("Localizable", "membership.yearly.title")
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
    /// Store location
    public static let storeLocation = L10n.tr("Localizable", "setting.storeLocation")
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
      /// Editor
      public static let title = L10n.tr("Localizable", "setting.editor.title")
      /// Unfold all entries when open
      public static let unfoldAllWhenOpen = L10n.tr("Localizable", "setting.editor.unfoldAllWhenOpen")
    }
    public enum Export {
      /// Show index
      public static let showIndex = L10n.tr("Localizable", "setting.export.showIndex")
      /// Export
      public static let title = L10n.tr("Localizable", "setting.export.title")
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
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
