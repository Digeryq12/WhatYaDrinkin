//
//  Beverage.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 09. 06..
//

import SwiftUI
import SwiftData

enum BeverageCategory: String, Codable, CaseIterable {
    case water = "water"
    case milk = "milk"
    case tea = "tea"
    case coffee = "coffee"
    case juice = "juice"
    case soda = "soda"
    case sports_energy = "sports_energy"
    case alcohol = "alcohol"
    case dairy_blended = "dairy_blended"
}

@Model final class BeverageContainer {
    @Attribute(.unique) var id = UUID()
    @Attribute(.externalStorage) var image: Data
    
    init(image: Data) {
        self.image = image
    }
}

@Model final class GalleryImage {
    @Attribute(.unique) var id = UUID()
    @Attribute(.externalStorage) var image: Data
    var beverageId: UUID
    var captureTime: Date
    
    init(image: Data, beverageId: UUID, captureTime: Date) {
        self.image = image
        self.beverageId = beverageId
        self.captureTime = captureTime
    }
}

@Model final class ConsumedBeverage { // only kept the current day
    @Attribute(.unique) var id = UUID()
    var beverageId: UUID
    var calories: Float
    var sugar: Float
    var serving: ServingSize
    var consumptionTime: Date
    
    init(beverageId: UUID, calories: Float, sugar: Float, serving: ServingSize, consumptionTime: Date) {
        self.beverageId = beverageId
        self.calories = calories
        self.sugar = sugar
        self.serving = serving
        self.consumptionTime = consumptionTime
    }
}

@Model final class StoredBeverage {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: BeverageCategory
    @Attribute(.externalStorage) var icon: Data
    var calories: Float // only changed from Int so it can be displayed in multiple measurement systems
    var sugar: Float
    var userCreated: Bool
    
    init(id: UUID, name: String, category: BeverageCategory, icon: Data, calories: Float, sugar: Float, userCreated: Bool) {
        self.id = id
        self.name = name
        self.category = category
        self.icon = icon
        self.calories = calories
        self.sugar = sugar
        self.userCreated = userCreated
    }
    
    // https://claude.ai/chat/960a330f-997f-4108-a782-271a595f77a6
    init(copy: StoredBeverage) {
        self.id = copy.id
        self.name = copy.name
        self.category = copy.category
        self.icon = copy.icon
        self.calories = copy.calories
        self.sugar = copy.sugar
        self.userCreated = copy.userCreated
    }
}

struct Beverage: Codable {
    var id: String
    var name: String
    var category: String
    var icon: String
    var calories: Float
    var sugar: Float
}

@Model final class SyncVersion {
    var current: Version
    
    init(current: Version) {
        self.current = current
    }
}
