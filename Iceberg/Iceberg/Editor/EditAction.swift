//
//  EditAction.swift
//  Iceberg
//
//  Created by ian luo on 2019/11/2.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Core

public enum EditAction {
    case toggleCheckboxStatus(Int, String)
    case addAttachment(NSRange, String, String)
    case updateDateAndTime(Int, DateAndTimeType?)
    case addTag(String, Int)
    case removeTag(String, Int)
    case changePlanning(String, Int)
    case changePriority(String?, Int)
    case removePlanning(Int)
    case insertText(String, Int)
    case archive(Int)
    case unarchive(Int)
    case insertSeparator(Int)
    case textMark(OutlineParser.MarkType, NSRange)
    case increaseIndent(Int)
    case decreaseIndent(Int)
    case quoteBlock(NSRange)
    case codeBlock(NSRange)
    case unorderedListSwitch(Int)
    case orderedListSwitch(Int)
    case checkboxSwitch(Int)
    case moveLineUp(Int)
    case moveLineDown(Int)
    case updateHeadingLevel(Int, Int)
    case updateLink(Int, String)
    case convertToHeading(Int)
    case convertHeadingToParagraph(Int)
    case addNewLineBelow(location: Int)
    case replaceText(NSRange, String)
    case removeParagraph(Int)
    case addSameLevelHeadingAbove(Int)
    case addSameLevelHeadingAfterCurrentHeading(Int)
    case addSubHeadingAfterCurrentHeading(Int)
    case addHeadingAtBottom
    case deleteSection(Int)
    case addFileLink(NSRange, URL)
    case setProperty(Int, [String: String])
    
    public var commandComposer: DocumentContentCommandComposer {
        switch self {
        case .toggleCheckboxStatus(let location, let checkbox):
            return CheckboxStatusCommandComposer(location: location, checkboxString: checkbox)
        case let .addAttachment(range, attachmentId, kind):
            return AddAttachmentCommandComposer(attachmentId: attachmentId, range: range, kind: kind)
        case let .addTag(tag, location):
            return TagCommandComposer(location: location, kind: .add(tag))
        case let .removeTag(tag, location):
            return TagCommandComposer(location: location, kind: .remove(tag))
        case let .changePlanning(planning, location):
            return PlanningCommandComposer(location: location, kind: .addOrUpdate(planning))
        case let .changePriority(priority, location):
            return PriorityCommandComposer(location: location, priority: priority)
        case let .removePlanning(location):
            return PlanningCommandComposer(location: location, kind: .remove)
        case let .insertText(text, location):
            return InsertTextToHeadingCommandComposer(location: location, textToInsert: text)
        case let .archive(location):
            return ArchiveCommandComposer(location: location)
        case let .unarchive(location):
            return UnarchiveCommandComposer(location: location)
        case .insertSeparator(let location):
            return AddSeparatorCommandComposer(location: location)
        case .textMark(let markType, let range):
            return TextMarkCommandComposer(markType: markType, range: range)
        case .increaseIndent(let location):
            return IncreaseIndentCommandComposer(location: location)
        case .decreaseIndent(let location):
            return DecreaseIndentCommandComposer(location: location)
        case .quoteBlock(let range):
            return QuoteBlockCommandComposer(range: range)
        case .codeBlock(let range):
            return CodeBlockCommandComposer(range: range)
        case let .updateDateAndTime(location, dateAndTime):
            return UpdateDateAndTimeCommandComposer(location: location, dateAndTime: dateAndTime)
        case let .unorderedListSwitch(location):
            return UnorderdListSwitchCommandComposer(location: location)
        case let .orderedListSwitch(location):
            return OrderedListSwitchCommandComposer(location: location)
        case let .checkboxSwitch(location):
            return CheckboxSwitchCommandComposer(location: location)
        case .moveLineUp(let location):
            return MoveLineUpCommandComposer(location: location)
        case .moveLineDown(let location):
            return MoveLineDownCommandComposer(location: location)
        case .updateHeadingLevel(let location, let newLevel):
            return HeadingLevelChangeCommandComposer(location: location, newLevel: newLevel)
        case .updateLink(let location, let link):
            return UpdateLinkCommandCompser(location: location, link: link)
        case .convertToHeading(let location):
            return ConvertLineToHeadingCommandComposer(location: location)
        case .convertHeadingToParagraph(let location):
            return ConvertHeadingLineToParagragh(location: location)
        case .addNewLineBelow(let location):
            return AddNewLineBelowCommandComposer(location: location)
        case .replaceText(let range, let textToReplace):
            return ReplaceContentCommandComposer(range: range, textToReplace: textToReplace)
        case .removeParagraph(let location):
            return RemoveParagraphCommandComposer(location: location)
        case .addSameLevelHeadingAbove(let location):
            return addNewSameLevelHeadingAboveCurrentHeadingCommandComposer(location: location)
        case .addSameLevelHeadingAfterCurrentHeading(let location):
            return AddNewHeadingAfterCurrentHeadingWithSameLevelCommandComposer(location: location)
        case .addSubHeadingAfterCurrentHeading(let location):
            return AddNewSubHeadingAfterCurrentHeading(location: location)
        case .deleteSection(let location):
            return DeleteSectionCommpandComposer(location: location)
        case .addFileLink(let range, let url):
            return AddDocumentLinkCommpandComposer(range: range, url: url)
        case .setProperty(let location, let pair):
            return SetHeadingPropertyComposer(location: location, property: pair)
        case .addHeadingAtBottom:
            return AddNewHeadingAtBottomCommandComposer()
        }
    }
}
