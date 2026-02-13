//
//  NewsEndPoint.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import Foundation

enum NewsEndPoint: ApiEndPointDelegate {
    case topHeadlines(country: String?, category: String?, page: Int, pageSize: Int)
    case search(query: String, page: Int, pageSize: Int)
    
    var baseURL: URL {
        return URL(string: "https://newsapi.org")!
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json"
        ]
    }
    
    var path: String {
        switch self {
        case .topHeadlines:
            return "/v2/top-headlines"
        case .search:
            return "/v2/everything"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var queryParameters: [String: String] {
        var params: [String: String] = [:]
        
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "NEWS_API_KEY") as? String, !apiKey.isEmpty {
            params["apiKey"] = apiKey
        } else {
            params["apiKey"] = "fb74cc3458c1401cad5723acfc88a7d5"
        }
        
        switch self {
        case .topHeadlines(let country, let category, let page, let pageSize):
            if let country = country {
                params["country"] = country
            }
            if let category = category {
                params["category"] = category
            }
            params["page"] = "\(page)"
            params["pageSize"] = "\(pageSize)"
            
        case .search(let query, let page, let pageSize):
            params["q"] = query
            params["page"] = "\(page)"
            params["pageSize"] = "\(pageSize)"
            params["sortBy"] = "publishedAt"
        }
        
        return params
    }
}
