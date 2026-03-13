//
//  PhotoAssetImageCache.swift
//  Demo
//
//  Created by AI on 13/03/26.
//

import Photos
import UIKit

final class PhotoAssetImageCache {
    static let shared = PhotoAssetImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 300
        cache.totalCostLimit = 60 * 1024 * 1024
    }

    func image(for asset: PHAsset,
               targetSize: CGSize,
               contentMode: PHImageContentMode = .aspectFill,
               completion: @escaping (UIImage?) -> Void) {
        let key = NSString(string: "\(asset.localIdentifier)|\(Int(targetSize.width))x\(Int(targetSize.height))")

        if let cached = cache.object(forKey: key) {
            DispatchQueue.main.async {
                completion(cached)
            }
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(for: asset,
                                              targetSize: targetSize,
                                              contentMode: contentMode,
                                              options: options) { [weak self] image, _ in
            if let image = image {
                self?.cache.setObject(image, forKey: key)
            }
            completion(image)
        }
    }
}
