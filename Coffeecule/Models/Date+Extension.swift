//
//  Date+Extension.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 8/28/23.
//

import Foundation

extension Date {
    
    /// round date to nearest day
    var roundedToNearestDay: Date? {
        let dateComponents = Calendar.autoupdatingCurrent.dateComponents([.calendar,.day,.month,.year], from: self)
        return Calendar.autoupdatingCurrent.date(from: dateComponents)
    }
}
