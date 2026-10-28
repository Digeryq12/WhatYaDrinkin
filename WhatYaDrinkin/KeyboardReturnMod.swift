//
//  KeyboardReturnMod.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 10. 28..
//

import SwiftUI

struct KeyboardReturnMod: ViewModifier {
    // Claude clutched this one
    // https://claude.ai/share/2bc49397-0a67-4732-99a4-627ff0f7da2f
    
    let offset: CGFloat
    let keyboardOpen: Bool
    let returnAction: () -> ()
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if keyboardOpen {
                    Spacer()
                    
                    Button {
                        returnAction()
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                        Text("Return")
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .offset(y: offset)
                }
            }
    }
}
