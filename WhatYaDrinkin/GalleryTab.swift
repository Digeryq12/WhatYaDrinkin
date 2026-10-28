//
//  GalleryTab.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 08. 30..
//

import SwiftData
import SwiftUI

struct GalleryTab: View {
    @Environment(GalleryVM.self) var vm
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \GalleryImage.captureTime, order: .forward) var galleryImages: [GalleryImage]
    @Query var storedBeverages: [StoredBeverage]
    
    @State private var selectedImages = Set<GalleryImage>()
    @State private var previewedImage: GalleryImage?
    
    var body: some View {
        if galleryImages.isEmpty {
            
            Spacer()
            
            VStack {
                Image(systemName: "photo.badge.magnifyingglass")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .frame(width: 100)
                
                Text("Nothing to see here...")
                    .font(.largeTitle)
            }
            
            Spacer()
            
        } else {
            
            NavigationStack {
                ScrollView() {
                    VStack(alignment: .leading) {
                        ForEach(vm.galleryByDate(galleryImages: galleryImages).groups, id: \GalleryVM.GalleryGroup.day) { group in
                            
                            Text(Date(daysSince1970: group.day).formatted(date: .abbreviated, time: .omitted))
                                .font(.title)
                                .padding(.bottom, 10)
                            
                            LazyVGrid(columns: SharedResources.shared.generateVGridColumns(amount: 3)) {
                                ForEach(group.images, id: \GalleryImage.id) { image in
                                    VStack {
                                        Image(uiImage: UIImage(data: image.image)!) // checked in vm
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                            .padding(.bottom, 10)
                                            .modifier(SelectableMod(selectedItems: $selectedImages, currentItem: image, offset: (x: 0, y: 0), interactable: { previewedImage == nil }))
                                            .onTapGesture {
                                                if selectedImages.isEmpty && previewedImage == nil {
                                                    previewedImage = image
                                                }
                                            }
                                        
                                        Text(image.captureTime.formatted(date: .omitted, time: .shortened))
                                            .font(.title3)
                                        
                                        Label {
                                            Text(SharedResources.shared.getBeverageById(image.beverageId, storedBeverages: storedBeverages).name)
                                        } icon: {
                                            Image(uiImage: UIImage(data: SharedResources.shared.getBeverageById(image.beverageId, storedBeverages: storedBeverages).icon) ?? UIImage(named: "beverage-placeholder")!)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 30)
                                        }
                                    }
                                    .padding(.bottom, 30)
                                }
                            }
                        }
                    }
                }
                .toolbar {
                    if !selectedImages.isEmpty {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            DeleteSelectionButton(selectedItems: $selectedImages, modelContext: modelContext)
                        }
                    }
                }
                .blur(radius: previewedImage != nil ? 1 : 0)
                .overlay {
                    if let image = UIImage(data: previewedImage?.image ?? Data()) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 350, height: 350)
                    }
                }
                .onTapGesture {
                    previewedImage = nil
                }
                .padding()
            }
        }
    }
}

#Preview {
    GalleryTab()
}
