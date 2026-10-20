//
//  SelectableMod.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 09. 24..
//

import SwiftUI

struct SelectableMod<T: Hashable>: ViewModifier {
    @Binding var selectedItems: Set<T>
    let currentItem: T
    let offset: (x: CGFloat, y: CGFloat)
    let interactable: () -> (Bool)
    
    func body(content: Content) -> some View {
        content
        .overlay {
            if !selectedItems.isEmpty && interactable() {
                Button {
                    if selectedItems.contains(currentItem) {
                        selectedItems.remove(currentItem)
                    } else {
                        selectedItems.insert(currentItem)
                    }
                    
                } label: {
                    Image(systemName: selectedItems.contains(currentItem) ? "checkmark.circle.fill" : "circle")
                        .scaleEffect(1.2)
                }
                .buttonStyle(.glass)
                .offset(x: offset.x, y: offset.y)
            }
        }
        .onLongPressGesture {
            if interactable() {
                selectedItems.insert(currentItem)
            }
        }
    }
}
