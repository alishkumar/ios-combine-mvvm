import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    func scheduleTrendingNewsNotification(articles: [Article]) {
        guard !articles.isEmpty else { return }
        
        let topArticle = articles.first!
        let content = UNMutableNotificationContent()
        content.title = "📰 Trending News"
        content.body = topArticle.title
        content.sound = .default
        content.userInfo = ["articleUrl": topArticle.url]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: true)
        let request = UNNotificationRequest(identifier: "trending-news", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelTrendingNewsNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["trending-news"])
    }
}
