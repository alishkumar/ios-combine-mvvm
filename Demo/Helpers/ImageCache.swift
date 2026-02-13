//
//  ImageCache.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import UIKit

final class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let session = URLSession.shared
    private let placeholderImage: UIImage?
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        placeholderImage = UIImage(named: "dummyImage")
    }
    
    func image(for urlString: String?, completion: @escaping (UIImage) -> Void) {
        guard let urlString = urlString, !urlString.isEmpty, let url = URL(string: urlString) else {
            let placeholder = placeholderImage ?? UIImage()
            DispatchQueue.main.async {
                completion(placeholder)
            }
            return
        }
        
        let key = NSString(string: urlString)
        
        if let cachedImage = cache.object(forKey: key) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {
                let placeholder = ImageCache.shared.placeholderImage ?? UIImage()
                DispatchQueue.main.async {
                    completion(placeholder)
                }
                return
            }
            
            if let data = data, let image = UIImage(data: data), error == nil {
                self.cache.setObject(image, forKey: key)
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(self.placeholderImage ?? UIImage())
                }
            }
        }.resume()
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
