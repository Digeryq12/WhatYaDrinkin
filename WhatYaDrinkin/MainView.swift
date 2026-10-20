//
//  ContentView.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 08. 30..
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            Tab("Beverages", systemImage: "wineglass") {
                BeveragesTab()
                    .environment(BeveragesVM())
            }
            Tab("Gallery", systemImage: "photo.on.rectangle.angled") {
                GalleryTab()
                    .environment(GalleryVM())
            }
            Tab("Settings", systemImage: "gear") {
                SettingsTab()
            }
        }
    }
}

#Preview {
    MainView()
}
