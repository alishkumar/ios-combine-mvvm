//
//  PhotoFaceService.swift
//  Demo
//
//  Created by AI on 13/03/26.
//

import Foundation
import Photos
import Vision
import UIKit
import ImageIO

protocol PhotoFaceServiceProtocol {
    func scanLibrary(progress: @escaping (Double) -> Void) async throws -> [(PHAsset, [DetectedFace])]
}

final class PhotoFaceService: PhotoFaceServiceProtocol {
    
    func scanLibrary(progress: @escaping (Double) -> Void) async throws -> [(PHAsset, [DetectedFace])] {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            return []
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard assets.count > 0 else { return [] }
        
        var results: [(PHAsset, [DetectedFace])] = []
        results.reserveCapacity(assets.count)
        
        for index in 0 ..< assets.count {
            let asset = assets.object(at: index)
            if let faces = try await detectFaces(in: asset), !faces.isEmpty {
                results.append((asset, faces))
            }
            let currentProgress = Double(index + 1) / Double(assets.count)
            await MainActor.run {
                progress(currentProgress)
            }
        }
        
        return results
    }
    
    private func detectFaces(in asset: PHAsset) async throws -> [DetectedFace]? {
        guard asset.mediaType == .image else { return nil }
        
        guard let image = try await requestImage(for: asset) else {
            return nil
        }
        
        guard let cgImage = image.cgImage else { return nil }
        
        let request = VNDetectFaceRectanglesRequest()
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results as? [VNFaceObservation], !observations.isEmpty else {
            return []
        }
        
        let faces: [DetectedFace] = observations.map { observation in
            DetectedFace(boundingBox: observation.boundingBox, tag: nil)
        }
        return faces
    }
    
    private func requestImage(for asset: PHAsset) async throws -> UIImage? {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            options.resizeMode = .fast
            
            let targetSize = CGSize(width: 300, height: 300)
            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFill,
                                                  options: options) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

fileprivate extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}


