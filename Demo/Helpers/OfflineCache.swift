import Foundation
import SwiftData

final class OfflineCache {
    static let shared = OfflineCache()
    
    private let cacheKey = "cached_news_articles"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    func saveArticlesForOffline(_ articles: [Article]) {
        guard let encoded = try? JSONEncoder().encode(articles) else { return }
        userDefaults.set(encoded, forKey: cacheKey)
        userDefaults.set(Date(), forKey: "\(cacheKey)_timestamp")
    }
    
    func loadCachedArticles() -> [Article] {
        guard let data = userDefaults.data(forKey: cacheKey),
              let articles = try? JSONDecoder().decode([Article].self, from: data) else {
            return []
        }
        return articles
    }
    
    func clearCache() {
        userDefaults.removeObject(forKey: cacheKey)
        userDefaults.removeObject(forKey: "\(cacheKey)_timestamp")
    }
    
    func isCacheValid(maxAge: TimeInterval = 3600) -> Bool {
        guard let timestamp = userDefaults.object(forKey: "\(cacheKey)_timestamp") as? Date else {
            return false
        }
        return Date().timeIntervalSince(timestamp) < maxAge
    }
}
