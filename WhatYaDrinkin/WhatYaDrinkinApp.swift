//
//  WhatYaDrinkinApp.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 08. 30..
//

import SwiftData
import SwiftUI

@main
struct WhatYaDrinkinApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(MainVM())
        }
        .modelContainer(for: [StoredBeverage.self, SyncVersion.self, ConsumedBeverage.self, GalleryImage.self, BeverageContainer.self])
    }
}
