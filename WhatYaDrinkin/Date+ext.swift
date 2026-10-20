//
//  Date+ext.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 09. 21..
//

import Foundation

extension Date {
    
    // gets the exact amount of days in the time interval from 1970 up to the specified date (time zone dependent)
    var daysSince1970: Double {
        return floor((self.timeIntervalSince1970 + Double(TimeZone.current.secondsFromGMT())) / (24 * pow(60, 2)))
    }
    
    // initializer to reverse daysSince1970 (time zone dependent)
    init(daysSince1970: Double) {
        self = Date(timeIntervalSince1970: daysSince1970 * (24 * pow(60, 2)))
    }
}
