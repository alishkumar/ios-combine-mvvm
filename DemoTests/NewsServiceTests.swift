import XCTest
import Combine
@testable import Demo

final class NewsServiceTests: XCTestCase {
    var service: NewsService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        service = NewsService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        service = nil
        super.tearDown()
    }
    
    func testFetchTopHeadlinesEndpoint() {
        let expectation = XCTestExpectation(description: "API call completed")
        
        service.fetchTopHeadlines(country: "us", category: "technology", page: 1, pageSize: 10)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        expectation.fulfill()
                    }
                },
                receiveValue: { response in
                    XCTAssertNotNil(response)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testSearchNewsEndpoint() {
        let expectation = XCTestExpectation(description: "Search completed")
        
        service.searchNews(query: "apple", page: 1, pageSize: 10)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        expectation.fulfill()
                    }
                },
                receiveValue: { response in
                    XCTAssertNotNil(response)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
}
