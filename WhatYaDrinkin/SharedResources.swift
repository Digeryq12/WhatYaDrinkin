//
//  SharedResources.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 09. 20..
//

import SwiftUI

final class SharedResources {
    static let shared = SharedResources()
    
    private init() {}
    
    func generateVGridColumns(amount: Int) -> [GridItem] {
        var items: [GridItem] = []
        for _ in 1...amount {
            items.append(GridItem(.flexible()))
        }
        return items
    }
    
    func getBeverageById(_ id: UUID, storedBeverages: [StoredBeverage]) -> StoredBeverage {
        let array = storedBeverages.filter { $0.id == id }
        return array.first ?? StoredBeverage(id: UUID(), name: "Unknown beverage", category: .water, icon: Data(), calories: 0, sugar: 0.0, userCreated: false)
    }
}
