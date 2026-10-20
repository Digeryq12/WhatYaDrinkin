//
//  GalleryVM.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 09. 21..
//

import SwiftUI

@Observable final class GalleryVM {
    func galleryByDate(galleryImages: [GalleryImage]) -> Gallery {
        var result: [Double: [GalleryImage]] = [:]
        
        for image in galleryImages {
            if UIImage(data: image.image) != nil {
                let creationDayStart = image.captureTime.daysSince1970
                
                if result[creationDayStart] == nil {
                    result[creationDayStart] = []
                }
                
                print(Date(daysSince1970: creationDayStart))
                
                result[creationDayStart]!.append(image)
            }
        }
        
        var groups: [GalleryGroup] = []
        result.keys.forEach { groups.append(GalleryGroup(day: $0, images: result[$0]!)) }
        let gallery = Gallery(groups: groups.sorted { $0.day > $1.day })
        return gallery
    }
    
    struct GalleryGroup {
        var day: Double
        var images: [GalleryImage]
    }

    struct Gallery {
        var groups: [GalleryGroup]
    }
}
