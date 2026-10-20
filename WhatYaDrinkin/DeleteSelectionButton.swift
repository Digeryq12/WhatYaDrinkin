//
//  DeleteSelectionButton.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 09. 24..
//

import SwiftData
import SwiftUI

struct DeleteSelectionButton<T: PersistentModel>: View {
    @Binding var selectedItems: Set<T>
    var modelContext: ModelContext
    var showingText = true
    
    var body: some View {
        Button {
            for item in selectedItems {
                selectedItems.remove(item)
                modelContext.delete(item)
            }
        } label: {
            HStack {
                Text(showingText ? "Delete selected" : "")
                Image(systemName: "xmark.bin.fill")
                    .imageScale(.large)
            }
        }
    }
}
