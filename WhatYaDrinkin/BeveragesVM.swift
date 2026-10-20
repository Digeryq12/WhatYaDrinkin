//
//  MainVM.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 09. 06..
//

import SwiftData
import SwiftUI

@Observable @MainActor final class BeveragesVM {  // guaranteeing this runs on main
    
    var shownAlert: String?
    
    var beverageMenuOpen = false
    var selectedBeverage = StoredBeverage(id: UUID(), name: "Unknown beverage", category: .water, icon: Data(), calories: 0, sugar: 0.0, userCreated: false) // only defined here so that the textfield bindings for calories and sugar work
    
    var currentServing: ServingSize = .extraSmall
    var editingBeverageProperties = false
    
    var customBeverage = StoredBeverage(id: UUID(), name: "My beverage", category: .water, icon: Data(), calories: 0, sugar: 0.0, userCreated: true)
    
    var showingContainers = false
    
    func checkVersion() async -> [Version]? {
        return await getRequest(url: "https://yktpydxytsylmfwgxxlh.supabase.co/rest/v1/sync_data?id=eq.1", object: [Version].self)
    }
    
    func getBeverages() async -> [Beverage]? {
        return await getRequest(url: "https://yktpydxytsylmfwgxxlh.supabase.co/rest/v1/beverage_list", object: [Beverage].self)
    }
    
    func getBeverageIcon(icon: String) async -> Data? {
        await getRequest(url: "https://yktpydxytsylmfwgxxlh.supabase.co/storage/v1/object/beverage_icons/\(icon)", object: Data.self)
    }
    
    func loadBeverages(modelContext: ModelContext, storedVersion: [SyncVersion], storedBeverages: [StoredBeverage], beverageContainers: [BeverageContainer]) async {
        
        let versions = await checkVersion()
        
        guard let currentVersion = versions?.first else {
            shownAlert = "Whoops"
            return
        }
        
        if storedVersion.first == nil {
            print("current" + currentVersion.version)
            for version in storedVersion {
                modelContext.delete(version)
            }
            await saveBeverages()
        } else if storedVersion.first!.current.version != currentVersion.version {
            print("stored" + storedVersion.first!.current.version)
            modelContext.delete(storedVersion.first!)
            for storedB in storedBeverages {
                if !storedB.userCreated {
                    modelContext.delete(storedB)
                }
            }
            for container in beverageContainers {
                modelContext.delete(container)
            }
            await saveBeverages()
        } else {
            print("stored" + storedVersion.first!.current.version + "current" + currentVersion.version)
        }
        
        func saveBeverages() async {
            let beverages = await getBeverages()
            
            guard let beverages else {
                print("dang")
                return
            }
            
            for bev in beverages {
                guard let category = BeverageCategory(rawValue: bev.category) else {
                    print("God")
                    return
                }
                
                guard let iconData = await getBeverageIcon(icon: bev.icon) else {
                    print("Damn")
                    return
                }
                
                modelContext.insert(
                    StoredBeverage(id: UUID(uuidString: bev.id) ?? UUID(), name: bev.name, category: category, icon: iconData, calories: bev.calories, sugar: bev.sugar, userCreated: false)
                )
            }
            
            for i in 26..<38 {
                guard let containerData = await getBeverageIcon(icon: "drink-\(i).png") else {
                    print("Damn2")
                    return
                }
                
                modelContext.insert(BeverageContainer(image: containerData))
            }
            
            modelContext.insert(
                SyncVersion(current: currentVersion)
            )
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to save")
            }
        }
    }
    
    func getRequest<T: Codable>(url: String, object: T.Type) async -> T? {
        do {
            return try await NetworkManager.shared.get(url: url, object: T.self)
        } catch let error as NetworkError {
            switch error {
                case .invalidURL:
                    shownAlert = "Invalid URL"
                case .invalidResponse:
                    shownAlert = "Invalid response"
                case .invalidData:
                    shownAlert = "Invalid data"
            }
        } catch {
            shownAlert = "An unknown error occured"
        }
        return nil
    }
    
    func snakeCaseFormatter(input: String) -> String {
        let matches = input.matches(of: /[A-Za-z]+/)
        
        if matches.count == 0 {
            return "[ Unable to format snake case ]"
        }
        
        var result = ""
        
        for m in matches {
            let output = m.output
            let rest = output.index(after: output.startIndex)..<output.endIndex
            result = result + output[output.startIndex].uppercased() + output[rest] + " & "
        }
        
        result = String(result[result.startIndex..<result.index(result.endIndex, offsetBy: -3)])
        
        return result
    }
    
    func checkConsumedBeverages(modelContext: ModelContext, consumedBeverages: [ConsumedBeverage]) {
        for beverage in consumedBeverages {
            let consumptionDay = beverage.consumptionTime.daysSince1970
            let currentDay = Date.now.daysSince1970
            
            if currentDay - consumptionDay >= 1 {
                modelContext.delete(beverage)
                print("A day has already passed")
            } else {
                print("A day hasn't passed yet.")
            }
        }
    }
}
