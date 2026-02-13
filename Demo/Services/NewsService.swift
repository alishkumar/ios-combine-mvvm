//
//  NewsService.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import Foundation
import Combine

protocol NewsServiceProtocol {
    func fetchTopHeadlines(country: String?, category: String?, page: Int, pageSize: Int) -> AnyPublisher<NewsResponse, Error>
    func searchNews(query: String, page: Int, pageSize: Int) -> AnyPublisher<NewsResponse, Error>
    func fetchTopHeadlinesAsync(country: String?, category: String?, page: Int, pageSize: Int) async throws -> NewsResponse
    func searchNewsAsync(query: String, page: Int, pageSize: Int) async throws -> NewsResponse
}

class NewsService: NewsServiceProtocol {
    private let apiClient = URLSessionAPIClient<NewsEndPoint>()
    
    func fetchTopHeadlines(country: String?, category: String?, page: Int, pageSize: Int) -> AnyPublisher<NewsResponse, Error> {
        let endpoint = NewsEndPoint.topHeadlines(country: country, category: category, page: page, pageSize: pageSize)
        return apiClient.request(endpoint)
            .eraseToAnyPublisher()
    }
    
    func searchNews(query: String, page: Int, pageSize: Int) -> AnyPublisher<NewsResponse, Error> {
        let endpoint = NewsEndPoint.search(query: query, page: page, pageSize: pageSize)
        return apiClient.request(endpoint)
            .eraseToAnyPublisher()
    }
    
    func fetchTopHeadlinesAsync(country: String?, category: String?, page: Int, pageSize: Int) async throws -> NewsResponse {
        let endpoint = NewsEndPoint.topHeadlines(country: country, category: category, page: page, pageSize: pageSize)
        return try await apiClient.requestAsync(endpoint)
    }
    
    func searchNewsAsync(query: String, page: Int, pageSize: Int) async throws -> NewsResponse {
        let endpoint = NewsEndPoint.search(query: query, page: page, pageSize: pageSize)
        return try await apiClient.requestAsync(endpoint)
    }
}
