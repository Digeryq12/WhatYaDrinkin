//
//  MeasurementSystem.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 10. 13..
//

import Foundation

enum MeasurementSystem: String, CaseIterable {
    case metric = "Metric"
    case imperial = "Imperial"
    case customary = "Customary"
}

extension MeasurementSystem {
    var volume: (n: String, c: Float) {
        switch self {
        case .metric:
            return ("dl", 1)
        case .imperial:
            return ("fl oz", 3.51950797279)
        case .customary:
            return ("fl oz", 3.38140227018)
        }
    }
    
    var mass: (n: String, c: Float) {
        switch self {
        case .metric:
            return ("g", 1)
        case .imperial:
            fallthrough
        case .customary:
            return ("oz", 0.0352739619)
        }
    }
}
