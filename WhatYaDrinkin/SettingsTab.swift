//
//  SettingsTab.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 08. 30..
//

import SwiftUI

enum AuthScreen {
    case login
    case signUp
}

enum STField {
    case dailyGoal
}

struct SettingsTab: View {
    @Environment(MainVM.self) var mainVM
    @State private var vm = SettingsVM()
    
    @FocusState var focusedField: STField?
    
    var body: some View {
        @Bindable var mainVM = mainVM
        @Bindable var vm = vm
        
        NavigationStack {
            Form {
                Section("User") {
                    VStack {
                         // https://www.magnific.com/free-photo/refreshing-fruity-drink-with-ice-mint-berries-smoky-setting_426969412.htm#fromView=search&page=1&position=11&uuid=3d3b7141-7d5e-463e-afc7-b5e6bbb3fcef&track=ais_hybrid&query=drink
                        Image("default-pfp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Circle())
                            .frame(width: 100)
                        
                        Text("User")
                            .font(.title2)
                        Text("#000001")
                            .font(.title3)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    
                    
                    Button {
                        focusedField = nil
                        vm.chosenAuth = .login
                    } label: {
                        Text("Log in")
                    }
                    
                    Button {
                        focusedField = nil
                        vm.chosenAuth = .signUp
                    } label: {
                        Text("Sign up")
                    }
                }
                
                Section("Options") {
                    Picker("Measurement system used", selection: $mainVM.selectedSystem) {
                        ForEach(MeasurementSystem.allCases, id: \.self) { system in
                            Text(system.rawValue)
                        }
                    }
                    .disabled(mainVM.currentMenuTab == .selector ? false : true)
                    
                    // maybe someday I will add proper conversions... not today though!
                    
                    HStack {
                        Text("Daily goal (Intake)")
                        Spacer()
                        TextField(mainVM.selectedSystem.volume.n, value: $mainVM.dailyGoal, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .dailyGoal)
                            .foregroundStyle(Color(.secondaryLabel))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 75)
                    }
                }
            }
            .modifier(KeyboardReturnMod(
                offset: -5,
                keyboardOpen: focusedField != nil,
                returnAction: { focusedField = nil })
            )
            .navigationTitle("Settings")
            .navigationDestination(item: $vm.chosenAuth) { auth in
                VStack(spacing: 10) {
                    Image(systemName: "long.text.page.and.pencil.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100)
                    
                    Text("There's nothing to see here yet :(")
                        .font(.largeTitle)
                }
                .padding()
            }
        }
    }
}

#Preview {
    SettingsTab()
}
