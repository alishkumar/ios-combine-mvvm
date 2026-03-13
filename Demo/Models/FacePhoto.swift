//
//  FacePhoto.swift
//  Demo
//
//  Created by AI on 13/03/26.
//

import Foundation
import Photos
import CoreGraphics

struct DetectedFace: Identifiable, Hashable {
    let id = UUID()
    let boundingBox: CGRect
    var tag: String?
}

struct FacePhoto: Identifiable {
    let id: String
    let asset: PHAsset
    var faces: [DetectedFace]
}

