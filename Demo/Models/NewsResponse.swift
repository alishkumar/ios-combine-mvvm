//
//  NewsResponse.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import Foundation

struct NewsResponse: Codable {
    let status: String?
    let totalResults: Int?
    let articles: [Article]?
}

struct Article: Codable, Identifiable {
    var id: String { url }
    let source: Source?
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: Date?
    let content: String?
    
    enum CodingKeys: String, CodingKey {
        case source, author, title, description, url, urlToImage, publishedAt, content
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        source = try? container.decode(Source.self, forKey: .source)
        author = try? container.decodeIfPresent(String.self, forKey: .author)
        title = try container.decode(String.self, forKey: .title)
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        url = try container.decode(String.self, forKey: .url)
        urlToImage = try? container.decodeIfPresent(String.self, forKey: .urlToImage)
        content = try? container.decodeIfPresent(String.self, forKey: .content)
        
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .publishedAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            publishedAt = formatter.date(from: dateString) ?? {
                let fallbackFormatter = ISO8601DateFormatter()
                return fallbackFormatter.date(from: dateString)
            }()
        } else {
            publishedAt = nil
        }
    }
    
    init(source: Source?, author: String?, title: String, description: String?, url: String, urlToImage: String?, publishedAt: Date?, content: String?) {
        self.source = source
        self.author = author
        self.title = title
        self.description = description
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.content = content
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(urlToImage, forKey: .urlToImage)
        try container.encodeIfPresent(content, forKey: .content)
        
        if let publishedAt = publishedAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: publishedAt), forKey: .publishedAt)
        }
    }
}

struct Source: Codable {
    let id: String?
    let name: String
}
