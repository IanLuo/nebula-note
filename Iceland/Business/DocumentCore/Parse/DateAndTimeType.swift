//
//  DateAndTimeType.swift
//  Business
//
//  Created by ian luo on 2019/4/3.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public class DateAndTimeType {
    public enum RepeatMode {
        case none
        case day(Int)
        case week(Int)
        case month(Int)
        case year(Int)
        
        public static func create(type: String, count: String) -> RepeatMode {
            let c = Int(count)!
            switch type {
            case "d": return RepeatMode.day(c)
            case "w": return RepeatMode.week(c)
            case "m": return RepeatMode.month(c)
            case "y": return RepeatMode.year(c)
            default: return RepeatMode.none
            }
        }
    }
    
    public let isDue: Bool
    public let isSchedule: Bool
    public let duration: TimeInterval
    public let date: Date
    public let includeTime: Bool // 是否包含时间
    public let repeateMode: RepeatMode // 如果 repate 不为空，这个字段有值
    
    public var description: String {
        if includeTime {
            return "\(date.monthStringShort) \(date.day) \(date.format("hh:mm"))"
        } else {
            return "\(date.monthStringShort) \(date.day)"
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
        let range = NSRange(location: 0, length: string.count)
        let dateFormatter = DateFormatter()
        
        let extractDate: (String, NSRange) -> (Date, Bool, RepeatMode)? = { string, range in
            if let dateAndTimeMatchResult = OutlineParser.Matcher.Element.DateAndTime.dateAndTimeWhole.firstMatch(in: string, options: [], range: range) {
                let dateRange = dateAndTimeMatchResult.range(at: 1)
                
                dateFormatter.dateFormat = "yyyy-MM-dd"
                var date = dateFormatter.date(from: string.substring(dateRange))!
                
                var includeTime = false
                if let timeResult = OutlineParser.Matcher.Element.DateAndTime.time.firstMatch(in: string, options: [], range: range) {
                    includeTime = true
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                    date = dateFormatter.date(from: "\(string.substring(dateRange)) \(string.substring(timeResult.range))")!
                }
                
                var repeatMode: RepeatMode = .none
                if let repeatResult = OutlineParser.Matcher.Element.DateAndTime.repeat.firstMatch(in: string, options: [], range: range) {
                    let countRange = repeatResult.range(at: 1)
                    let typeRange = repeatResult.range(at: 2)
                    repeatMode = RepeatMode.create(type: string.substring(typeRange), count: string.substring(countRange))
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
        // 2. find as due
        else if let dueResult =  OutlineParser.Matcher.Element.DateAndTime.due.firstMatch(in: string, options: [], range: range) {
            let dateInfo = extractDate(string, dueResult.range(at: 1))!
            self.init(date: dateInfo.0, includeTime: dateInfo.1, repeateMode: dateInfo.2, isDue: true)
        }
        // 3. find as schedule
        else if let scheduleResult =  OutlineParser.Matcher.Element.DateAndTime.schedule.firstMatch(in: string, options: [], range: range) {
            let dateInfo = extractDate(string, scheduleResult.range(at: 1))!
            self.init(date: dateInfo.0, includeTime: dateInfo.1, repeateMode: dateInfo.2, isSchedule: true)
        }
        // 4. find as time range
        else if let timeRangeResult =  OutlineParser.Matcher.Element.DateAndTime.timeRange.firstMatch(in: string, options: [], range: range) {
            if let rangePartResult = OutlineParser.Matcher.Element.DateAndTime.timeRangePart.firstMatch(in: string, options: [], range: timeRangeResult.range) {
                let times = string.substring(rangePartResult.range).components(separatedBy: "-")
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
}

extension DateAndTimeType {
    public func toScheduleString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = self.includeTime ? "yyyy-MM-dd EEE HH:mm" : "yyyy-MM-dd EEE"
        return "SCHEDULED: <\(formatter.string(from: self.date))>"
    }
    
    public func toDueDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = self.includeTime ? "yyyy-MM-dd EEE HH:mm" : "yyyy-MM-dd EEE"
        return "DEADLINE: <\(formatter.string(from: self.date))>"
    }
}
