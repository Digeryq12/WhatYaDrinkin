//
//  BeveragesTab.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 08. 30..
//

import SwiftData
import SwiftUI

//temporary

enum BeverageMenuTab {
    case selector
    case new
    case log
}

enum BTField {
    case consumedBeverageSugar
    case consumedBeverageCalories
    case customServingSize
    
    case customBeverageName
    case customBeverageSugar
    case customBeverageCalories
}

struct BeveragesTab: View {
    @Environment(MainVM.self) var mainVM
    @Environment(BeveragesVM.self) var vm
    @Environment(\.modelContext) var modelContext
    
    @Query var storedVersion: [SyncVersion]
    @Query var storedBeverages: [StoredBeverage]
    @Query(sort: \ConsumedBeverage.consumptionTime, order: .reverse) var consumedBeverages: [ConsumedBeverage]
    @Query var beverageContainers: [BeverageContainer]
    @Query var servingSizes: [ServingSizes]
    
    @State private var capturedImage: UIImage?
    @State private var cameraOpen = false
    @FocusState private var focusedField: BTField?
    
    private func filteredBeverages(by category: BeverageCategory) -> [StoredBeverage] {
        return storedBeverages.filter { $0.category == category }
    }
    
    private func limitDecimals(to limit: Int, on f: Float) -> String {
        // https://share.gemini.google/TOeG6gd2F3iF
        return f.formatted(.number.precision(.fractionLength(0...limit)))
    }
    
    private func selectBeverage(beverage: StoredBeverage) {
        if selectedBeverages.isEmpty {
            vm.selectedBeverage = StoredBeverage(copy: beverage)
            vm.selectedBeverage.sugar = (vm.selectedBeverage.sugar * mainVM.selectedSystem.mass.c) / mainVM.selectedSystem.volume.c // <-- 1dl
            // ONLY actually changed and not just displayed in a different measurement system since it can be changed by the user!
            // xg/1dl to y(oz/fl oz)
            vm.selectedBeverage.calories /= mainVM.selectedSystem.volume.c
            vm.addingServingSize = false
            vm.customServingSize = 0
            mainVM.currentMenuTab = .log
        }
    }
    
    private func saveConsumedBeverage() {
        let convertedSugar = (vm.selectedBeverage.sugar / mainVM.selectedSystem.mass.c) * mainVM.selectedSystem.volume.c
        let convertedCalories = vm.selectedBeverage.calories * mainVM.selectedSystem.volume.c
        
        modelContext.insert(ConsumedBeverage(beverageId: vm.selectedBeverage.id, calories: convertedCalories, sugar: convertedSugar, serving: vm.currentServing, consumptionTime: Date.now))
        
        if let codedImage = capturedImage?.pngData() {
            modelContext.insert(GalleryImage(image: codedImage, beverageId: vm.selectedBeverage.id, captureTime: Date.now))
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save")
        }
        
        mainVM.currentMenuTab = .selector
        capturedImage = nil
    }
    
    private func addCustomServingSize() {
        vm.addingServingSize = false
        let serving = vm.customServingSize / mainVM.selectedSystem.volume.c * 100
        if let ss = servingSizes.first?.all {
            if !ss.contains(serving) { // id is set to self, meaning each size has to be unique
                servingSizes.first?.all.insert(serving)
            }
        }
        vm.customServingSize = 0
        print(servingSizes.first!.all)
    }
    
    private func createCustomBeverage() {
        vm.customBeverage = StoredBeverage(id: UUID(), name: "My beverage", category: .water, icon: Data(), calories: 0, sugar: 0.0, userCreated: true)
        
        if let random = beverageContainers.randomElement()?.image {
            vm.customBeverage.icon = random
        }
        
        mainVM.currentMenuTab = .new
    }
    
    private var intakeToday: Float {
        var intake: Float = 0
        consumedBeverages.forEach { intake += $0.serving / 100 }
        return intake
    }
    
    private var caloriesToday: Float {
        var calories: Float = 0
        consumedBeverages.forEach { calories += $0.calories * ($0.serving / 100) }
        return calories
    }
    
    private var sugarToday: Float {
        var sugar: Float = 0
        consumedBeverages.forEach { sugar += $0.sugar * ($0.serving / 100) }
        return sugar
    }
    
    private var consumptionLabel: String {
        let intake = limitDecimals(
            to: 2,
            on: intakeToday * mainVM.selectedSystem.volume.c
        )
        
        let goal = limitDecimals(
            to: 2,
            on: mainVM.dailyGoal * mainVM.selectedSystem.volume.c
        )
        
        let measurement = mainVM.selectedSystem.volume.n
        
        return "You drank \(intake)/\(goal) \(measurement) \n of liquid today"
    }
    
    private var intakeLabel: String {
        let calories = limitDecimals(
            to: 2,
            on: caloriesToday
        )
        
        let sugar = limitDecimals(
            to: 2,
            on: sugarToday * mainVM.selectedSystem.mass.c
        )
        
        let measurement = mainVM.selectedSystem.mass.n
        
        return "An intake of \(calories) kcal & \(sugar)\(measurement) of sugar"
    }
    
    private var servingSizeLabel: (ServingSize) -> (String) {
        { servingSize in
            let serving = limitDecimals(
                to: 2,
                on: servingSize / 100 * mainVM.selectedSystem.volume.c
            )
            
            let measurement = mainVM.selectedSystem.volume.n
            
            return "\(serving)\(measurement)"
        }
    }
    
    private var propertiesLabel: String {
        let calories = limitDecimals(to: 1, on: vm.selectedBeverage.calories * (vm.currentServing / 100) * mainVM.selectedSystem.volume.c)
        
        let sugar = limitDecimals(to: 2, on: vm.selectedBeverage.sugar * (vm.currentServing / 100)  * mainVM.selectedSystem.volume.c)
        
        return "\(calories)kcal + \(sugar)\(mainVM.selectedSystem.mass.n) of sugar"
    }
    
    // https://claude.ai/share/5023e84b-a5f1-4aab-b11b-298d6cb2f5e2
    private var availableServingSizes: Set<ServingSize> {
        servingSizes.first?.all ?? ServingSizes().all
    }
    
    private var servingTint: (ServingSize) -> (Color) {
        { serving in
            return serving == vm.currentServing ? .blue : .gray
        }
    }
    
    private var currentTopBar: String {
        switch mainVM.currentMenuTab {
        case .selector:
            return "Select your beverage"
        case .log:
            return "Got it?"
        case .new:
            return "We forgot something?"
        }
    }
    
    @State private var selectedConsumptions = Set<ConsumedBeverage>()
    @State private var selectedBeverages = Set<StoredBeverage>()
    
    var body: some View {
        // https://developer.apple.com/documentation/swiftui/bindable
        @Bindable var vm = vm
        
        ZStack {
            Color(.blue)
                .ignoresSafeArea()
            
            VStack {
                VStack(spacing: 10) {
                    Text(consumptionLabel)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                    
                    Text(intakeLabel)
                        .font(.title)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white)
                }
                .padding(20)
                
                if !selectedConsumptions.isEmpty {
                    HStack {
                        Spacer()
                        
                        DeleteSelectionButton(selectedItems: $selectedConsumptions, modelContext: modelContext)
                            .buttonStyle(.glass)
                            .padding(.trailing)
                    }
                    .padding(.bottom, 10)
                }
                
                ScrollView {
                    LazyVGrid(columns: SharedResources.shared.generateVGridColumns(amount: 5)) {
                        ForEach(consumedBeverages, id: \ConsumedBeverage.id) { beverage in
                            VStack {
                                Image(uiImage: UIImage(data: SharedResources.shared.getBeverageById(beverage.beverageId, storedBeverages: storedBeverages).icon) ?? UIImage(named: "beverage-placeholder")!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 70)
                                    .padding(.top, 10)
                                    .modifier(SelectableMod(selectedItems: $selectedConsumptions, currentItem: beverage, offset: (x: 15, y: 35), interactable: { true }))
                                
                                VStack {
                                    Text(SharedResources.shared.getBeverageById(beverage.beverageId, storedBeverages: storedBeverages).name)
                                        .lineLimit(2, reservesSpace: true)
                                        .foregroundStyle(.white)
                                        .bold()
                                        .multilineTextAlignment(.center)
                                    
                                    Text(servingSizeLabel(beverage.serving))
                                        .lineLimit(1)
                                        .foregroundStyle(.white)
                                    
                                    Text(beverage.consumptionTime.formatted(date: .omitted, time: .shortened))
                                        .lineLimit(1)
                                        .foregroundStyle(.white)
                                }
                                .padding(.top, 10)
                            }
                        }
                    }
                }
                .frame(height: 340)
                .padding(.horizontal, 20)
                
                Spacer()
                
                if !vm.beverageMenuOpen {
                    Button {
                        mainVM.currentMenuTab = .selector
                        vm.beverageMenuOpen = true
                    } label: {
                        Image(systemName: "plus")
                            .scaleEffect(2)
                            .padding(.vertical, 5.5)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.extraLarge)
                    .padding(.bottom, 30)
                }
            }
        }
        .overlay {
            if vm.beverageMenuOpen {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(.white)
                    
                    VStack() {
                        HStack {
                            if mainVM.currentMenuTab != .selector {
                                Button {
                                    mainVM.currentMenuTab = .selector
                                    capturedImage = nil
                                    vm.editingBeverageProperties = false
                                } label: {
                                    Image(systemName: "arrow.left")
                                        .imageScale(.large)
                                        .foregroundStyle(.black)
                                }
                                .padding(.leading, 15)
                            }
                            
                            Text(currentTopBar)
                                .font(.title2)
                                .padding(.leading, 15)
                                .foregroundStyle(.black)
                            
                            Spacer()
                            
                            if !selectedBeverages.isEmpty {
                                DeleteSelectionButton(selectedItems: $selectedBeverages, modelContext: modelContext, showingText: false)
                                    .tint(.black)
                                    .padding(.trailing, 10)
                            }
                            
                            Button {
                                vm.beverageMenuOpen = false
                                mainVM.currentMenuTab = .selector // measurement system picker locks otherwise
                                capturedImage = nil
                                selectedBeverages = []
                            } label: {
                                Image(systemName: "xmark")
                                    .imageScale(.large)
                                    .foregroundStyle(.black)
                            }
                            .padding(.trailing, 15)
                        }
                        .padding(.top, 18)
                        
                        Spacer()
                        
                        switch mainVM.currentMenuTab {
                        case .selector:
                            
                            ScrollView {
                                VStack(alignment: .leading) {
                                    ForEach(BeverageCategory.allCases, id: \.self) { category in
                                        VStack(alignment: .leading) {
                                            Text(vm.snakeCaseFormatter(input: category.rawValue))
                                                .padding(.leading, 10)
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.black)
                                            
                                            LazyVGrid(columns: SharedResources.shared.generateVGridColumns(amount: 5)) {
                                                ForEach(filteredBeverages(by: category), id: \StoredBeverage.id) { beverage in
                                                    Button {
                                                        selectBeverage(beverage: beverage)
                                                    } label: {
                                                        VStack {
                                                            Image(uiImage: UIImage(data: beverage.icon) ?? UIImage(named: "beverage-placeholder")!)
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fit)
                                                                .frame(width: 70)
                                                                .padding(.top, 10)
                                                                .modifier(SelectableMod(selectedItems: $selectedBeverages, currentItem: beverage, offset: (x: 15, y: 35), interactable: { beverage.userCreated }))
                                                            
                                                            Text(beverage.name)
                                                                .lineLimit(2, reservesSpace: true)
                                                                .padding(.top, 10)
                                                                .foregroundStyle(.gray)
                                                                .multilineTextAlignment(.center)
                                                        }
                                                    }
                                                }
                                            }
                                        }.padding(.vertical)
                                    }
                                    
                                    Button {
                                        createCustomBeverage()
                                    } label: {
                                        Label("Create beverage", systemImage: "plus.app.fill")
                                            .imageScale(.large)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.gray)
                                    .padding(.vertical, 25)
                                }
                                .padding(.leading, 20)
                            }
                            .frame(height: 440)
                        
                        case .log:
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(uiImage: UIImage(data: vm.selectedBeverage.icon) ?? UIImage(named: "beverage-placeholder")!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 70)
                                    
                                    VStack(alignment: .leading) {
                                        Text("I just drank...")
                                            .font(.title3)
                                            .foregroundStyle(.gray)
                                        
                                        Text(vm.selectedBeverage.name)
                                            .font(.title)
                                            .foregroundStyle(.black)
                                    }
                                }
                                .padding(.bottom, 15)
                                
                                HStack {
                                    Button {
                                        vm.editingBeverageProperties.toggle()
                                    } label: {
                                        Image(systemName: "square.and.pencil")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .tint(.gray)
                                            .frame(width: 30)
                                    }
                                    .padding(.trailing, 5)
                                    
                                    if vm.editingBeverageProperties {
                                        TextField("kcal", value: $vm.selectedBeverage.calories, format: .number)
                                            .keyboardType(.decimalPad)
                                            .focused($focusedField, equals: .consumedBeverageCalories)
                                            .frame(width: 40, height: 30)
                                            .glassEffect()
                                        
                                        Text("Calories")
                                            .foregroundStyle(.gray)
                                            .font(.title3)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                            .frame(width: 10)
                                        
                                        TextField(mainVM.selectedSystem.mass.n, value: $vm.selectedBeverage.sugar, format: .number)
                                            .keyboardType(.decimalPad)
                                            .focused($focusedField, equals: .consumedBeverageSugar)
                                            .frame(width: 40, height: 30)
                                            .glassEffect()
                                        
                                        Text("Sugar / 1\(mainVM.selectedSystem.volume.n)")
                                            .foregroundStyle(.gray)
                                            .font(.title3)
                                            .lineLimit(1)
                                        
                                    } else {
                                        Text(propertiesLabel)
                                            .foregroundStyle(.gray)
                                            .font(.title2)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.bottom, 15)
                                
                                VStack(alignment: .leading) {
                                    Text("Serving Size")
                                        .font(.title2)
                                        .foregroundStyle(.black)
                                    
                                    ScrollView(.horizontal) {
                                        HStack {
                                            ForEach(Array(availableServingSizes).sorted(), id: \.self) { serving in
                                                Button {
                                                    vm.currentServing = serving
                                                } label: {
                                                    Text(servingSizeLabel(serving))
                                                        .onLongPressGesture {
                                                            if !ServingSizes().all.contains(serving) { // also makes sure we are removing from the model
                                                                servingSizes.first?.all.remove(serving)
                                                            }
                                                        }
                                                }
                                                .buttonStyle(.bordered)
                                                .tint(servingTint(serving))
                                            }
                                            
                                            if !vm.addingServingSize {
                                                Button {
                                                    vm.addingServingSize = true
                                                } label: {
                                                    Text("+")
                                                }
                                                .buttonStyle(.bordered)
                                                .tint(.gray)
                                            } else {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .frame(width: 70, height: 35)
                                                        .foregroundStyle(.gray.opacity(0.22))
                                                    
                                                    HStack {
                                                        TextField(mainVM.selectedSystem.volume.n, value: $vm.customServingSize, format: .number)
                                                            .keyboardType(.decimalPad)
                                                            .focused($focusedField, equals: .customServingSize)
                                                            .frame(width: 30, height: 30)
                                                            .foregroundStyle(.gray)
                                                        //.glassEffect()
                                                        
                                                        Button {
                                                            addCustomServingSize()
                                                        } label: {
                                                            Image(systemName: "checkmark")
                                                        }
                                                        //.buttonStyle(.bordered)
                                                        //.tint(.blue)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom, 15)
                                
                                HStack {
                                    if let capturedImage {
                                        
                                        Image(uiImage: capturedImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 85, height: 85)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .padding(.trailing, 10)
                                            .onTapGesture {
                                                cameraOpen = true
                                            }
                                        
                                    } else {
                                        
                                        Button {
                                            cameraOpen = true
                                        } label: {
                                            Image(systemName: "camera.viewfinder")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 60)
                                        }
                                        .buttonStyle(.glass)
                                        .buttonBorderShape(.roundedRectangle(radius: 20))
                                        .controlSize(.large)
                                        .padding(.trailing, 10)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Capture your drink!")
                                            .font(.title2)
                                            .foregroundStyle(.black)
                                        
                                        Text("Your screenshot will be saved to the in-app gallery.")
                                            .font(.title3)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .padding(.bottom, 25)
                                
                                HStack {
                                    Spacer()
                                    
                                    Button {
                                        saveConsumedBeverage()
                                        
                                    } label: {
                                        Text("Confirm")
                                            .font(.title3)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.blue)
                                }
                                
                            }
                            .padding()
                            
                        case .new:
                            
                            VStack(alignment: .leading) {
                                Text("Create new beverage")
                                    .font(.title)
                                    .foregroundStyle(.black)
                                    .padding(.top, 15)
                                
                                HStack {
                                    Image(uiImage: UIImage(data: vm.customBeverage.icon) ?? UIImage(named: "beverage-placeholder")!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .overlay {
                                            Button {
                                                vm.showingContainers.toggle()
                                            } label: {
                                                Image(systemName: "arrow.trianglehead.2.clockwise")
                                            }
                                            .buttonStyle(.glass)
                                            .controlSize(.mini)
                                            .offset(x: 20, y: 40)
                                        }
                                        .frame(width: 70)
                                    
                                    VStack(alignment: .leading) {
                                        TextField("Beverage name", text: $vm.customBeverage.name)
                                            .autocorrectionDisabled()
                                            .focused($focusedField, equals: .customBeverageName)
                                            .frame(width: 150, height: 30)
                                            .padding(.horizontal, 10)
                                            .glassEffect()
                                        
                                        Picker("Category", selection: $vm.customBeverage.category) {
                                            ForEach(BeverageCategory.allCases, id: \.self) { category in
                                                Text(vm.snakeCaseFormatter(input: category.rawValue))
                                            }
                                        }
                                        .tint(.gray)
                                    }
                                }
                                .padding(.bottom, 20)
                                
                                if vm.showingContainers {
                                    ScrollView(.horizontal) {
                                        HStack {
                                            ForEach(beverageContainers, id: \BeverageContainer.id) { container in
                                                
                                                Button {
                                                    vm.customBeverage.icon = container.image
                                                } label: {
                                                    Image(uiImage: UIImage(data: container.image) ?? UIImage(named: "beverage-placeholder")!)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 50)
                                                }
                                                .buttonStyle(.bordered)
                                                .tint(vm.customBeverage.icon == container.image ? .blue : .gray)
                                            }
                                        }
                                    }
                                    .padding(.bottom, 20)
                                }
                                
                                HStack {
                                    // https://developer.apple.com/documentation/swiftui/textfield/init(_:value:format:prompt:)
                                    TextField("kcal", value: $vm.customBeverage.calories, format: .number)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedField, equals: .customBeverageCalories)
                                        .frame(width: 50, height: 30)
                                        .padding(.horizontal, 10)
                                        .glassEffect()
                                    
                                    Text("Calories / 1\(mainVM.selectedSystem.volume.n)")
                                        .foregroundStyle(.black)
                                        .padding(.trailing, 10)
                                    
                                    TextField(mainVM.selectedSystem.mass.n, value: $vm.customBeverage.sugar, format: .number)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedField, equals: .customBeverageSugar)
                                        .frame(width: 50, height: 30)
                                        .padding(.horizontal, 10)
                                        .glassEffect()
                                    
                                    Text("Sugar / 1\(mainVM.selectedSystem.volume.n)")
                                        .foregroundStyle(.black)
                                }
                                
                                Spacer()
                                
                                HStack {
                                    Spacer()
                                    
                                    Button {
                                        vm.customBeverage.sugar = (vm.customBeverage.sugar / mainVM.selectedSystem.mass.c) * mainVM.selectedSystem.volume.c
                                        vm.customBeverage.calories *= mainVM.selectedSystem.volume.c
                                        modelContext.insert(vm.customBeverage)
                                        mainVM.currentMenuTab = .selector
                                    } label: {
                                        Text("Create")
                                            .font(.title3)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.blue)
                                }
                            }
                            .padding()
                            
                        /*
                        default:
                            
                            Label("Something's not right...", systemImage: "hammer.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.black)
                            
                            Spacer()
                        */
                        }
                    }
                }
                .offset(y: 70)
                .frame(height: 500)
                .padding(.horizontal, 20)
            }
        }
        .modifier(KeyboardReturnMod(
            offset: -24,
            keyboardOpen: focusedField != nil,
            returnAction: { focusedField = nil })
        )
        .sheet(isPresented: $cameraOpen) {
            CameraView(image: $capturedImage)
        }
        .task {
            await vm.loadBeverages(modelContext: modelContext, storedVersion: storedVersion, storedBeverages: storedBeverages, beverageContainers: beverageContainers)
            
            vm.checkConsumedBeverages(modelContext: modelContext, consumedBeverages: consumedBeverages)
            
            if servingSizes.first == nil {
                modelContext.insert(ServingSizes())
            }
        }
    }
}

#Preview {
    BeveragesTab()
}
