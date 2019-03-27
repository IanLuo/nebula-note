//
//  NSDateExtension.swift
//  Pig
//
//  Created by ian luo on 15/7/28.
//  Copyright (c) 2015年 WOD. All rights reserved.
//

import Foundation
#if os(iOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif

public struct TimeValue {
  public static let Minute:Double = 60
  public static let Hour:Double = Minute * 60
  public static let Day:Double = Hour * 24
  public static let Week:Double = Day * 7
  public static let Month:Double = Week * 4
  public static let Year:Double = Month * 12
}

fileprivate class DateConstants {
  static var calendar: Calendar {
    get {
      return _calendar
    }
  }
  
  fileprivate static var _calendar: Calendar = Calendar.current
}

public extension Date {
  static func updateDateConstant(firstWeekday: Int) {
    DateConstants._calendar.firstWeekday = firstWeekday
  }
  
  //return a string that represent the date
  var dateKeyString: String {
    let cal = DateConstants.calendar
    let components = cal.dateComponents([Calendar.Component.year, Calendar.Component.month, Calendar.Component.day], from: self)
    let year = components.value(for: Calendar.Component.year) ?? 0
    let month = components.value(for: Calendar.Component.month) ?? 0
    let day = components.value(for: Calendar.Component.day) ?? 0
    return "\(year)-\(month)-\(day)"
  }
    
    var weekDayString: String {
        let cal = DateConstants.calendar
        return cal.weekdaySymbols[cal.component(Calendar.Component.weekday, from: self) - 1]
    }
    
    var weekDayShortString: String {
        let cal = DateConstants.calendar
        return cal.shortWeekdaySymbols[cal.component(Calendar.Component.weekday, from: self) - 1]
    }
    
    var weekOfYearString: String {
        let cal = DateConstants.calendar
        return "W\(cal.component(Calendar.Component.weekOfYear, from: self))"
    }
    
    var monthStringLong: String {
        let cal = DateConstants.calendar
        return cal.standaloneMonthSymbols[cal.component(Calendar.Component.month, from: self) - 1]
    }
    
    var monthStringShort: String {
        let cal = DateConstants.calendar
        return cal.shortMonthSymbols[cal.component(Calendar.Component.month, from: self) - 1]
    }
}

extension Date {
  public static var TodayDate: Date {
    get {
      let cal = DateConstants.calendar
      let dateComponents = (cal as NSCalendar).components([NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day], from: Date())
      return cal.date(from: dateComponents)!
    }
  }
  
  public func dayBefore(_ daysCount:Int) -> Date {
    let value1 = CGFloat(self.timeIntervalSinceReferenceDate)
    let value2 = CGFloat(Double(daysCount) * TimeValue.Day)
    let timeInterval = value1 - value2
    let date = Date(timeIntervalSinceReferenceDate: Double(timeInterval) as TimeInterval)
    return date
  }
  
  public func dayAfter(_ daysCount:Int) -> Date {
    return self.dayBefore(-daysCount)
  }
  
  public static var Yesterday: Date{
    return Date(timeIntervalSinceNow: -TimeValue.Day)
  }
  
  public static var LastWeekDay: Date{
    return Date(timeIntervalSinceNow: -TimeValue.Week)
  }
  
  public static var ThirtydaysAgo: Date {
    return Date(timeIntervalSinceNow: -TimeValue.Month)
  }
  
  public static var AYearAgo: Date {
    return Date(timeIntervalSinceNow: -TimeValue.Year)
  }
}

extension Date {
  public var dayBegin:Date {
    let cal = DateConstants.calendar
    if let date = ((cal as NSCalendar).components([.year, .month, .day], from: self) as NSDateComponents).date {
        return date
    } else {
        return cal.startOfDay(for: self)
    }
  }
  
  public var dayEnd:Date {
    let dayBegin = self.dayBegin
    let timeInterval = dayBegin.timeIntervalSinceReferenceDate
    let dayEndTimeInterval = timeInterval + TimeValue.Day - 1
    return Date(timeIntervalSinceReferenceDate: dayEndTimeInterval)
  }
  
  public var nextDay:Date {
    return self.addingTimeInterval(TimeValue.Day).dayBegin
  }
  
  public var preDay:Date {
    return self.addingTimeInterval(-TimeValue.Day).dayBegin
  }
}

public extension Date {
  func isSameDay(_ date:Date) -> Bool {
    let calendar = DateConstants.calendar
    return (calendar as NSCalendar).isDate(self, equalTo: date, toUnitGranularity: NSCalendar.Unit.day)
  }
  
  func isSameWeek(_ date:Date) -> Bool {
    let calendar = DateConstants.calendar
    return (calendar as NSCalendar).compare(self, to: date, toUnitGranularity: [NSCalendar.Unit.weekOfYear]) == ComparisonResult.orderedSame
  }
  
  func isSameMonth(_ date:Date) -> Bool {
    let calendar = DateConstants.calendar
    return (calendar as NSCalendar).compare(self, to: date, toUnitGranularity: [NSCalendar.Unit.month]) == ComparisonResult.orderedSame
  }
  
  func isSameYear(_ date:Date) -> Bool {
    let calendar = Calendar.current
    return (calendar as NSCalendar).compare(self, to: date, toUnitGranularity: [NSCalendar.Unit.year]) == ComparisonResult.orderedSame
  }
  
  func isToday() -> Bool {
    return isSameDay(Date())
  }
  
  func isYesterday() -> Bool {
    return isSameDay(Date.Yesterday)
  }
  
  func daysFrom(_ date:Date) -> Int {
    let timeIntervalSelf = self.timeIntervalSinceReferenceDate
    let timeIntervalCompareDay = date.timeIntervalSinceReferenceDate
    return Int(ceil((timeIntervalSelf - timeIntervalCompareDay) / Double(TimeValue.Day)))
  }
}

public extension Date {
  public var firstDayOfThisWeek: Date {
    get {
      let cal = DateConstants.calendar
      let weekday = (cal as NSCalendar).component(NSCalendar.Unit.weekday, from: self)
      
      if cal.firstWeekday == 1 {
        return self.dayBefore(weekday - 1).dayBegin
      } else {
        let shiftedWeekdayValue = weekday - 2 >= 0 ? weekday - 2 : 6 // when shifted weekday > 0, return it, otherwise return 6
        return dayBefore(shiftedWeekdayValue).dayBegin
      }
    }
  }
  
  public var firstDayThisMonth: Date {
    get {
      let cal = DateConstants.calendar
      let day = (cal as NSCalendar).component(NSCalendar.Unit.day, from: self)
      return self.dayBefore(day - 1).dayBegin
    }
  }
  
  public var firstDayThisYear: Date {
    let cal = DateConstants.calendar
    let day = (cal as NSCalendar).date(era: (cal as NSCalendar).component(NSCalendar.Unit.era, from: self), year: (cal as NSCalendar).component(NSCalendar.Unit.year, from: self), month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0)
    return day!
  }
  
  public var dateRangeOfMonth: (startDate:Date, endDate:Date) {
    let cal = Calendar.current
    var startDate: Date = Date()
    var timeInterval: TimeInterval = 0
    
    _ = cal.dateInterval(of: Calendar.Component.month, start: &startDate, interval: &timeInterval, for: self)
    let endDate = startDate.addingTimeInterval(timeInterval)
    return (startDate, endDate)
  }
  
  public var dateRangeOfWeek: (startDate:Date, endDate:Date) {
    let cal = Calendar.current
    var startDate: Date = Date()
    var timeInterval: TimeInterval = 0
    
    _ = cal.dateInterval(of: Calendar.Component.weekOfMonth, start: &startDate, interval: &timeInterval, for: self)
    let endDate = startDate.addingTimeInterval(timeInterval)
    return (startDate, endDate)
  }
}

// assemble

public extension Date {
  public var year: Int {
    return Calendar.current.component(Calendar.Component.year, from: self)
  }
  
  public var month: Int {
    return Calendar.current.component(Calendar.Component.month, from: self)
  }
  
  public var weak: Int {
    return Calendar.current.component(Calendar.Component.weekOfYear, from: self)
  }
  
  public var day: Int {
    return Calendar.current.component(Calendar.Component.day, from: self)
  }
}

private func int(_ i: Int?) -> Int {
  return i ?? 0
}

//MARK: - format
public extension Date {
  public var shortDateString: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = DateFormatter.Style.medium
    return dateFormatter.string(from: self)
  }
}


//MARK: formatter
public extension Date {
  public func format(_ format: String) -> String {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate(format)
    return formatter.string(from: self)
  }
  
  public func format(_ dateStyle:DateFormatter.Style, timeStyle:DateFormatter.Style) -> String {
    return DateFormatter.localizedString(from: self, dateStyle: dateStyle, timeStyle: timeStyle)
  }
}

extension Date {}

public func <(lhs: Date, rhs: Date) -> Bool {
  return lhs.compare(rhs) == ComparisonResult.orderedAscending
}

public func <=(lhs: Date, rhs: Date) -> Bool {
  let comparisionResult = lhs.compare(rhs)
  return comparisionResult == ComparisonResult.orderedAscending || comparisionResult == ComparisonResult.orderedSame
}

public func >=(lhs: Date, rhs: Date) -> Bool {
  let comparisionResult = lhs.compare(rhs)
  return comparisionResult == ComparisonResult.orderedDescending || comparisionResult == ComparisonResult.orderedSame
}

public func >(lhs: Date, rhs: Date) -> Bool {
  return lhs.compare(rhs) == ComparisonResult.orderedDescending
}
