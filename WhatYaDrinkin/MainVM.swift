//
//  MainVM.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 10. 13..
//

import SwiftUI

@Observable final class MainVM {
    var currentMenuTab: BeverageMenuTab = .selector
    
    var selectedSystem: MeasurementSystem = .metric // all measures were already defined in metric
    var dailyGoal: Float = 15
}
