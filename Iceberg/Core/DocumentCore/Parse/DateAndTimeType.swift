//
//  DateAndTimeType.swift
//  Business
//
//  Created by ian luo on 2019/4/3.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Interface

public class DateAndTimeType {
    public enum RepeatMode {
        case none
        case day(Int)
        case week(Int)
        case month(Int)
        case quarter(Int)
        case year(Int)
        
        public func updatingValue(_ newValue: Int) -> RepeatMode {
            switch self {
            
            case .none:
                return .none
            case .day(_):
                return .day(newValue)
            case .week(_):
                return .week(newValue)
            case .month(_):
                return .month(newValue)
            case .quarter(_):
                return .quarter(newValue)
            case .year(_):
                return .year(newValue)
            }
        }
        
        public static func create(type: String, count: String) -> RepeatMode {
            let c = Int(count)!
            switch type {
            case "d": return RepeatMode.day(c)
            case "w": return RepeatMode.week(c)
            case "m": return RepeatMode.month(c)
            case "y": return RepeatMode.year(c)
            case "q": return RepeatMode.quarter(c)
            default: return RepeatMode.none
            }
        }
        
        public var mark: String? {
            switch self {
            case let .day(count): return "+\(count)d"
            case let .week(count): return "+\(count)w"
            case let .month(count): return "+\(count)m"
            case let .year(count): return "+\(count)y"
            case let .quarter(count): return "+\(count)q"
            case .none: return nil
            }
        }
                
        public var content: String {
            switch self {
            case .none:
                return L10n.Document.DateAndTime.Repeat.none
            case .day(let value):
                return  L10n.Document.DateAndTime.Repeat.title + " \(value) " + L10n.Document.DateAndTime.Repeat.daily
            case .week(let value):
                return L10n.Document.DateAndTime.Repeat.title + " \(value) " +  L10n.Document.DateAndTime.Repeat.weekly
            case .month(let value):
                return L10n.Document.DateAndTime.Repeat.title + " \(value) " +  L10n.Document.DateAndTime.Repeat.monthly
            case .quarter(let value):
                return L10n.Document.DateAndTime.Repeat.title + " \(value) " +  L10n.Document.DateAndTime.Repeat.quarterly
            case .year(let value):
                return L10n.Document.DateAndTime.Repeat.title + " \(value) " +  L10n.Document.DateAndTime.Repeat.yearly
            }
        }
        
        public var title: String {
            switch self {
            case .none:
                return L10n.Document.DateAndTime.Repeat.none
            case .day(_):
                return L10n.Document.DateAndTime.Repeat.daily
            case .week(_):
                return L10n.Document.DateAndTime.Repeat.weekly
            case .month(_):
                return L10n.Document.DateAndTime.Repeat.monthly
            case .quarter(_):
                return L10n.Document.DateAndTime.Repeat.quarterly
            case .year(_):
                return L10n.Document.DateAndTime.Repeat.yearly
            }
        }
    }
    
    public var isDue: Bool
    public var isSchedule: Bool
    public let duration: TimeInterval
    public let date: Date
    public var includeTime: Bool // 是否包含时间
    public var repeateMode: RepeatMode = .none // 如果 repate 不为空，这个字段有值
    
    public var description: String {
        if includeTime {
            return "\(date.monthStringShort) \(date.day) \(date.format("hh:mm"))"
        } else {
            return "\(date.monthStringShort) \(date.day)"
        }
    }
    
    public var isRepeatable: Bool {
        switch self.repeateMode {
        case .none:
            return false
        default:
            return true
        }
    }
    
    public init(date: Date,
                includeTime: Bool,
                repeateMode: RepeatMode = .none,
                isDue: Bool = false,
                isSchedule: Bool = false,
                duration: TimeInterval = 0) {
        self.date = date
        self.includeTime = includeTime
        self.repeateMode = repeateMode
        self.isDue = isDue
        self.isSchedule = isSchedule
        self.duration = duration
    }
    
    public convenience init?(_ string: String) {
        let range = NSRange(location: 0, length: string.nsstring.length)
        let dateFormatter = DateFormatter()
        
        let extractDate: (String, NSRange) -> (Date, Bool, RepeatMode)? = { string, range in
            if let dateAndTimeMatchResult = OutlineParser.Matcher.Element.DateAndTime.dateAndTimeWhole.firstMatch(in: string, options: [], range: range) {
                let dateRange = dateAndTimeMatchResult.range(at: 1)
                
                dateFormatter.dateFormat = "yyyy-MM-dd"
                var date = dateFormatter.date(from: string.nsstring.substring(with: dateRange))!
                
                var includeTime = false
                if let timeResult = OutlineParser.Matcher.Element.DateAndTime.time.firstMatch(in: string, options: [], range: range) {
                    includeTime = true
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                    date = dateFormatter.date(from: "\(string.nsstring.substring(with: dateRange)) \(string.nsstring.substring(with: timeResult.range))")!
                }
                
                var repeatMode: RepeatMode = .none
                if let repeatResult = OutlineParser.Matcher.Element.DateAndTime.repeat.firstMatch(in: string, options: [], range: range) {
                    let countRange = repeatResult.range(at: 1)
                    let typeRange = repeatResult.range(at: 2)
                    repeatMode = RepeatMode.create(type: string.nsstring.substring(with: typeRange), count: string.nsstring.substring(with: countRange))
                }
                
                return (date, includeTime, repeatMode)
            } else {
                return nil
            }
        }
        
        // 1. find whole string as date and time
        if let dateAndTimeInfo = extractDate(string, range) {
            self.init(date: dateAndTimeInfo.0, includeTime: dateAndTimeInfo.1, repeateMode: dateAndTimeInfo.2)
        }
        // 2. find as schedule
        else if let scheduleResult =  OutlineParser.Matcher.Element.DateAndTime.schedule.firstMatch(in: string, options: [], range: range) {
            let dateInfo = extractDate(string, scheduleResult.range(at: 1))!
            self.init(date: dateInfo.0, includeTime: dateInfo.1, repeateMode: dateInfo.2, isSchedule: true)
        }
        // 3. find as due
        else if let dueResult =  OutlineParser.Matcher.Element.DateAndTime.due.firstMatch(in: string, options: [], range: range) {
            let dateInfo = extractDate(string, dueResult.range(at: 1))!
            self.init(date: dateInfo.0, includeTime: dateInfo.1, repeateMode: dateInfo.2, isDue: true)
        }
        // 4. find as time range
        else if let timeRangeResult =  OutlineParser.Matcher.Element.DateAndTime.timeRange.firstMatch(in: string, options: [], range: range) {
            if let rangePartResult = OutlineParser.Matcher.Element.DateAndTime.timeRangePart.firstMatch(in: string, options: [], range: timeRangeResult.range) {
                let times = string.nsstring.substring(with: rangePartResult.range).components(separatedBy: "-")
                let date1String = (string as NSString).replacingCharacters(in: rangePartResult.range, with: times[0])
                let date2String = (string as NSString).replacingCharacters(in: rangePartResult.range, with: times[1])
                
                let dateInfo1 = extractDate(date1String, NSRange(location: 0, length: date1String.count))!
                let dateInfo2 = extractDate(date2String, NSRange(location: 0, length: date2String.count))!
                
                self.init(date: dateInfo1.0,
                          includeTime: dateInfo1.1,
                          repeateMode: dateInfo1.2,
                          duration: dateInfo2.0.timeIntervalSince1970 - dateInfo1.0.timeIntervalSince1970)
            } else {
                return nil
            }
        }
        // 5. find as date and time range
        else if let dateRangeResult =  OutlineParser.Matcher.Element.DateAndTime.dateRange.firstMatch(in: string, options: [], range: range) {
            let seperatorRange = (string as NSString).range(of: "--")
            let dateInfo1 = extractDate(string, dateRangeResult.range.head(seperatorRange.location))!
            let dateInfo2 = extractDate(string, dateRangeResult.range.tail(dateRangeResult.range.length - seperatorRange.upperBound))!
            self.init(date: dateInfo1.0,
                      includeTime: dateInfo1.1,
                      repeateMode: dateInfo1.2,
                      duration: dateInfo2.0.timeIntervalSince1970 - dateInfo1.0.timeIntervalSince1970)
        } else {
            return nil
        }
    }
    
    public func closestDate(to destination: Date, after: Bool) -> Date {
        let adjustment = after ? 1 : 0
        
        var components: DateComponents!
        switch  self.repeateMode {
        case .day(let count):
            let c = Calendar.current.dateComponents([.day], from: self.date, to: destination)
            let totalValue = c.value(for: Calendar.Component.day) ?? 0
            let value = totalValue / count
            components = DateComponents(day: (value + adjustment) * count)
        case .week(let count):
            let c = Calendar.current.dateComponents([.day], from: self.date, to: destination)
            let totalValue = c.value(for: Calendar.Component.day) ?? 0
            let value = totalValue / (count * 7)
            components = DateComponents(day: (value + adjustment) * count * 7)
        case .month(let count):
            let c = Calendar.current.dateComponents([.month], from: self.date, to: destination)
            let totalValue = c.value(for: Calendar.Component.month) ?? 0
            let value = totalValue / count
            components = DateComponents(month: (value + adjustment) * count)
        case .quarter(let count):
            let c = Calendar.current.dateComponents([.quarter], from: self.date, to: destination)
            let totalValue = c.value(for: Calendar.Component.quarter) ?? 0
            let value = totalValue / count
            components = DateComponents(quarter: (value + adjustment) * count)
        case .year(let count):
            let c = Calendar.current.dateComponents([.year], from: self.date, to: destination)
            let totalValue = c.value(for: Calendar.Component.year) ?? 0
            let value = totalValue / count
            components = DateComponents(year: (value + adjustment) * count)
        case .none:
            return self.date
        }
        
        return Calendar.current.date(byAdding: components!, to: self.date) ?? self.date
    }
    
    public struct DateAndTimeNotice {
        public enum AlertLevel {
            case normal, attention, urgent
            public var color: UIColor {
                switch self {
                case .normal:
                    return InterfaceTheme.Color.finished
                case .attention:
                    return InterfaceTheme.Color.unfinished
                case .urgent:
                    return InterfaceTheme.Color.warning
                }
            }
        }
        public enum Kind { case start, overDue }
        
        public let daysCount: Int
        public let kind: Kind
        
        public var alertLevel: AlertLevel {
            switch self.daysCount {
            case ..<0: return .urgent
            case 1..<3: return .attention
            case 3...: return .normal
            default: return .normal
            }
        }
        
        public var message: String {
            switch self.kind {
            case .overDue:
                if self.daysCount == 0 {
                    return L10n.Agenda.dueToday
                } else if self.daysCount == 1 {
                    return L10n.Agenda.willOverduTomorrowWithPlaceHolder
                } else if self.daysCount > 1 {
                    return L10n.Agenda.willOverduInDaysWithPlaceHolder(self.daysCount)
                } else if self.daysCount == -1 {
                    return L10n.Agenda.overdueYesterdayWihtPlaceHolder
                } else if self.daysCount < 0 {
                    return L10n.Agenda.overdueDaysWihtPlaceHolder(-self.daysCount)
                }
            case .start:
                if self.daysCount == 0 {
                    return L10n.Agenda.startToday
                } else if self.daysCount == 1 {
                    return L10n.Agenda.startTomorrowWithPlaceHolder
                } else if self.daysCount > 1 {
                    return L10n.Agenda.startInDaysWithPlaceHolder(self.daysCount)
                } else if self.daysCount == -1 {
                    return L10n.Agenda.startYesterdayWithPlaceHodlerYesterday
                } else if self.daysCount < -1 {
                    return L10n.Agenda.startDaysAgoWithPlaceHodler(-self.daysCount)
                }
            }
            
            return ""
        }
    }
    
    public var isJustDate: Bool {
        return !(self.isDue || self.isSchedule)
    }
    
    /// for **schedule**
    /// 1.  should past date count, 2. show upcoming date count (3 days)
    /// for **due**
    /// 1. show past date count, 2. show upcoming date count(3 days)
    /// for **repeat**
    /// 1. last cirle will show past date count, 2. next circle show upcoming date count (3 days)
    public func checkNotice(relative current: Date) -> DateAndTimeNotice? {
        let past = self.closestDate(to: current, after: false)
        let after = self.closestDate(to: current, after: true)
        
        var date: Date = self.date
        
        if self.isRepeatable {
            date = (abs(past.timeIntervalSince1970 - current.timeIntervalSince1970) > abs(after.timeIntervalSince1970 - current.timeIntervalSince1970)) ? after : past
        }
        
        var notice: DateAndTimeNotice?
        
        // check past
        if date.timeIntervalSince1970 < current.timeIntervalSince1970 {
            if self.isDue {
                notice = .init(daysCount: date.daysFrom(current), kind: .overDue)
            } else {
                notice = .init(daysCount: date.daysFrom(current), kind: .start)
            }
        }
        
        // check upcoming
        if date.dayBefore(3).timeIntervalSince1970 < current.timeIntervalSince1970
            && date.timeIntervalSince1970 > current.timeIntervalSince1970 {
            if self.isDue {
                notice = .init(daysCount: date.daysFrom(current), kind: .overDue)
            } else {
                notice = .init(daysCount: date.daysFrom(current), kind: .start)
            } 
        }
                
        return notice
    }
}

extension DateAndTimeType {
    private func _markStringWithoutDuration(date: Date) -> String {
        var string: String = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        string = dateFormatter.string(from: date)
        
        if self.includeTime {
            dateFormatter.dateFormat = "HH:mm"
            string.append(" \(dateFormatter.string(from: date))")
        }
        
        switch self.repeateMode {
        case .none: break
        default:
            string.append(" \(self.repeateMode.mark ?? "")")
        }

        return "<\(string)>"
    }
    
    public var markString: String {
        if self.isSchedule {
            return "\(OutlineParser.Values.Other.scheduled): \(self._markStringWithoutDuration(date: self.date))"
        }
        
        if self.isDue {
            return "\(OutlineParser.Values.Other.due): \(self._markStringWithoutDuration(date: self.date))"
        }
        
        if self.duration > 0 {
            let string1 = self._markStringWithoutDuration(date: self.date)
            let string2 = self._markStringWithoutDuration(date: Date(timeInterval: self.duration, since: self.date))
            
            return "\(string1)--\(string2)"
        }
        
        return self._markStringWithoutDuration(date: self.date)
    }
}

extension DateAndTimeType: Equatable {
    public static func ==(lhs: DateAndTimeType, rhs: DateAndTimeType) -> Bool {
        return lhs.date == rhs.date
            && lhs.repeateMode.mark == rhs.repeateMode.mark
            && lhs.duration == rhs.duration
            && lhs.isSchedule == rhs.isSchedule
            && lhs.isDue == rhs.isDue
    }
}

extension Date {
    public static func ==(lhs: Date, rhs: Date) -> Bool {
        let calendar = Calendar.current
        
        let lhsComps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: lhs)
        let rhsComps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: rhs)
        
        return lhsComps.year == rhsComps.year
            && lhsComps.month == rhsComps.month
            && lhsComps.day == rhsComps.day
            && lhsComps.hour == rhsComps.hour
            && lhsComps.minute == rhsComps.minute
    }
}
