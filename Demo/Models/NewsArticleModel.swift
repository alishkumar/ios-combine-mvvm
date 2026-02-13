//
//  NewsArticleModel.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import Foundation
import SwiftData

@Model
final class NewsArticleModel {
    @Attribute(.unique) var id: String
    var sourceId: String?
    var sourceName: String
    var author: String?
    var title: String
    var articleDescription: String?
    var url: String
    var urlToImage: String?
    var publishedAt: Date?
    var content: String?
    var savedAt: Date
    var isBookmarked: Bool
    
    init(id: String, sourceId: String?, sourceName: String, author: String?, title: String, articleDescription: String?, url: String, urlToImage: String?, publishedAt: Date?, content: String?, isBookmarked: Bool = false) {
        self.id = id
        self.sourceId = sourceId
        self.sourceName = sourceName
        self.author = author
        self.title = title
        self.articleDescription = articleDescription
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.content = content
        self.savedAt = Date()
        self.isBookmarked = isBookmarked
    }
    
    convenience init(from article: Article) {
        self.init(
            id: article.id,
            sourceId: article.source?.id,
            sourceName: article.source?.name ?? "Unknown",
            author: article.author,
            title: article.title,
            articleDescription: article.description,
            url: article.url,
            urlToImage: article.urlToImage,
            publishedAt: article.publishedAt,
            content: article.content
        )
    }
    
    func toArticle() -> Article {
        let source = Source(id: sourceId, name: sourceName)
        return Article(
            source: source,
            author: author,
            title: title,
            description: articleDescription,
            url: url,
            urlToImage: urlToImage,
            publishedAt: publishedAt,
            content: content
        )
    }
}
