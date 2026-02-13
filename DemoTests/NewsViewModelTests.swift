import XCTest
import Combine
import SwiftData
@testable import Demo

@MainActor
final class NewsViewModelTests: XCTestCase {
    var viewModel: NewsViewModel!
    var mockService: MockNewsService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockService = MockNewsService()
        viewModel = NewsViewModel(newsService: mockService)
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockService = nil
        super.tearDown()
    }
    
    func testLoadTopHeadlinesSuccess() {
        let expectation = XCTestExpectation(description: "Articles loaded")
        let mockArticles = createMockArticles(count: 5)
        mockService.mockResponse = NewsResponse(status: "ok", totalResults: 5, articles: mockArticles)
        
        viewModel.$newsArticles
            .dropFirst()
            .sink { articles in
                if !articles.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadTopHeadlines(refresh: true)
        
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(viewModel.newsArticles.count, 5)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadTopHeadlinesFailure() {
        let expectation = XCTestExpectation(description: "Loading completed")
        mockService.shouldFail = true
        
        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadTopHeadlines(refresh: true)
        
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(viewModel.newsArticles.isEmpty)
    }
    
    func testPagination() {
        let expectation = XCTestExpectation(description: "Pagination works")
        expectation.expectedFulfillmentCount = 2
        
        var callCount = 0
        mockService.onRequest = {
            callCount += 1
            if callCount == 2 {
                expectation.fulfill()
            }
        }
        
        mockService.mockResponse = NewsResponse(
            status: "ok",
            totalResults: 40,
            articles: createMockArticles(count: 20)
        )
        
        viewModel.loadTopHeadlines(refresh: true)
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                self.viewModel.loadMoreArticles()
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertGreaterThan(callCount, 1)
    }
    
    func testSearchNews() async {
        let expectation = XCTestExpectation(description: "Search completed")
        let mockArticles = createMockArticles(count: 10)
        mockService.mockResponse = NewsResponse(status: "ok", totalResults: 10, articles: mockArticles)
        
        viewModel.$newsArticles
            .dropFirst()
            .sink { articles in
                if !articles.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.searchNews(query: "test", refresh: true)
        
        await fulfillment(of: [expectation], timeout: 3.0)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(viewModel.searchQuery, "test")
        XCTAssertFalse(viewModel.newsArticles.isEmpty)
    }
    
    func testToggleBookmark() async {
        let schema = Schema([NewsArticleModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        
        viewModel.updateModelContext(context)
        
        let article = createMockArticle()
        
        viewModel.toggleBookmark(for: article)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        let isBookmarked = viewModel.isBookmarked(articleId: article.id)
        XCTAssertTrue(isBookmarked)
        
        viewModel.toggleBookmark(for: article)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        let isStillBookmarked = viewModel.isBookmarked(articleId: article.id)
        XCTAssertFalse(isStillBookmarked)
    }
    
    private func createMockArticles(count: Int) -> [Article] {
        return (0..<count).map { index in
            createMockArticle(id: "\(index)")
        }
    }
    
    private func createMockArticle(id: String = "1") -> Article {
        let source = Source(id: "test", name: "Test Source")
        return Article(
            source: source,
            author: "Test Author",
            title: "Test Title \(id)",
            description: "Test Description",
            url: "https://test.com/\(id)",
            urlToImage: "https://test.com/image.jpg",
            publishedAt: Date(),
            content: "Test Content"
        )
    }
}

final class MockNewsService: NewsServiceProtocol {
    var mockResponse: NewsResponse?
    var shouldFail = false
    var onRequest: (() -> Void)?
    
    func fetchTopHeadlines(country: String?, category: String?, page: Int, pageSize: Int) -> AnyPublisher<NewsResponse, Error> {
        onRequest?()
        
        if shouldFail {
            return Fail(error: APIError.invalidResponse)
                .eraseToAnyPublisher()
        }
        
        return Just(mockResponse ?? NewsResponse(status: "ok", totalResults: 0, articles: []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func searchNews(query: String, page: Int, pageSize: Int) -> AnyPublisher<NewsResponse, Error> {
        onRequest?()
        
        if shouldFail {
            return Fail(error: APIError.invalidResponse)
                .eraseToAnyPublisher()
        }
        
        return Just(mockResponse ?? NewsResponse(status: "ok", totalResults: 0, articles: []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
