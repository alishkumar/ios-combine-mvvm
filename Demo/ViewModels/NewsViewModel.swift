//
//  NewsViewModel.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import Foundation
import Combine
import SwiftData

@MainActor
final class NewsViewModel: ObservableObject {
    @Published var newsArticles: [Article] = []
    @Published var bookmarkedArticles: [Article] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var selectedCategory: String?
    @Published var searchQuery: String = ""
    
    private let newsService: NewsServiceProtocol
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private let pageSize = 20
    private var hasMorePages = true
    
    init(newsService: NewsServiceProtocol, modelContext: ModelContext? = nil) {
        self.newsService = newsService
        self.modelContext = modelContext
    }
    
    func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func loadTopHeadlines(category: String? = nil, refresh: Bool = false) {
        if refresh {
            currentPage = 1
            hasMorePages = true
            Task {
                self.isLoadingMore = false
                self.newsArticles.removeAll()
            }
            
            if !NetworkMonitor.shared.isConnected {
                loadOfflineArticles()
                return
            }
        }
        
        guard !isLoading && !isLoadingMore && hasMorePages else { return }
        
        Task {
            if self.currentPage == 1 {
                self.isLoading = true
            } else {
                self.isLoadingMore = true
            }
            self.selectedCategory = category
        }
        
        let pageToLoad = currentPage
        
        Task {
            do {
                let response = try await newsService.fetchTopHeadlinesAsync(
                    country: "us",
                    category: category,
                    page: pageToLoad,
                    pageSize: pageSize
                )
                
                await MainActor.run {
                    if let newArticles = response.articles, !newArticles.isEmpty {
                        let isRefresh = pageToLoad == 1
                        self.syncArticlesWithAPI(newArticles, isRefresh: isRefresh)
                        self.hasMorePages = newArticles.count == self.pageSize
                        self.currentPage = pageToLoad + 1
                        
                        if isRefresh {
                            OfflineCache.shared.saveArticlesForOffline(newArticles)
                            NotificationManager.shared.scheduleTrendingNewsNotification(articles: newArticles)
                        }
                    } else {
                        self.hasMorePages = false
                    }
                    
                    self.isLoading = false
                    self.isLoadingMore = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.isLoadingMore = false
                    
                    if case APIError.noConnection = error {
                        if self.newsArticles.isEmpty {
                            self.loadOfflineArticles()
                        }
                    }
                    self.hasMorePages = false
                }
            }
        }
    }
    
    private func loadOfflineArticles() {
        let cached = OfflineCache.shared.loadCachedArticles()
        Task {
            if !cached.isEmpty {
                self.newsArticles = cached
            }
            self.isLoading = false
        }
    }
    
    func searchNews(query: String, refresh: Bool = false) {
        guard !query.isEmpty else {
            loadTopHeadlines(refresh: true)
            return
        }
        
        if refresh {
            currentPage = 1
            hasMorePages = true
            Task {
                self.isLoadingMore = false
                self.newsArticles.removeAll()
            }
            
            if !NetworkMonitor.shared.isConnected {
                loadOfflineArticles()
                return
            }
        }
        
        guard !isLoading && !isLoadingMore && hasMorePages else { return }
        
        Task {
            if self.currentPage == 1 {
                self.isLoading = true
            } else {
                self.isLoadingMore = true
            }
            self.searchQuery = query
        }
        
        let pageToLoad = currentPage
        
        Task {
            do {
                let response = try await newsService.searchNewsAsync(
                    query: query,
                    page: pageToLoad,
                    pageSize: pageSize
                )
                
                await MainActor.run {
                    if let newArticles = response.articles, !newArticles.isEmpty {
                        let isRefresh = pageToLoad == 1
                        self.syncArticlesWithAPI(newArticles, isRefresh: isRefresh)
                        self.hasMorePages = newArticles.count == self.pageSize
                        self.currentPage = pageToLoad + 1
                    } else {
                        self.hasMorePages = false
                    }
                    
                    self.isLoading = false
                    self.isLoadingMore = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.isLoadingMore = false
                    
                    if case APIError.noConnection = error {
                        if self.newsArticles.isEmpty {
                            self.loadOfflineArticles()
                        }
                    }
                    self.hasMorePages = false
                }
            }
        }
    }
    
    func loadMoreArticles() {
        guard !isLoading && !isLoadingMore && hasMorePages else { return }
        
        if searchQuery.isEmpty {
            loadTopHeadlines(category: selectedCategory, refresh: false)
        } else {
            searchNews(query: searchQuery, refresh: false)
        }
    }
    
    private func syncArticlesWithAPI(_ apiArticles: [Article], isRefresh: Bool) {
        Task {
            if isRefresh {
                self.newsArticles = apiArticles.sorted { article1, article2 in
                    let date1 = article1.publishedAt ?? Date.distantPast
                    let date2 = article2.publishedAt ?? Date.distantPast
                    return date1 > date2
                }
            } else {
                let existingIds = Set(self.newsArticles.map { $0.id })
                let newArticles = apiArticles.filter { !existingIds.contains($0.id) }
                self.newsArticles.append(contentsOf: newArticles)
                
                self.newsArticles.sort { article1, article2 in
                    let date1 = article1.publishedAt ?? Date.distantPast
                    let date2 = article2.publishedAt ?? Date.distantPast
                    return date1 > date2
                }
            }
        }
    }
    
    
    func toggleBookmark(for article: Article) {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<NewsArticleModel>(
            predicate: #Predicate { $0.id == article.id }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            if existing.isBookmarked {
                modelContext.delete(existing)
            } else {
                existing.isBookmarked = true
            }
        } else {
            let articleModel = NewsArticleModel(from: article)
            articleModel.isBookmarked = true
            modelContext.insert(articleModel)
        }
        
        try? modelContext.save()
        loadBookmarkedArticles()
    }
    
    func isBookmarked(articleId: String) -> Bool {
        guard let modelContext = modelContext else { return false }
        
        let descriptor = FetchDescriptor<NewsArticleModel>(
            predicate: #Predicate { $0.id == articleId && $0.isBookmarked == true }
        )
        
        return (try? modelContext.fetch(descriptor).first) != nil
    }
    
    func loadBookmarkedArticles() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<NewsArticleModel>(
            predicate: #Predicate { $0.isBookmarked == true },
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        
        let bookmarked = try? modelContext.fetch(descriptor)
        let articles = bookmarked?.map { $0.toArticle() } ?? []
        
        Task {
            self.bookmarkedArticles = articles
        }
    }
}
