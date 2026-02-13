//
//  HomeViewModel.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//


import Foundation
import Combine

protocol PropertyServiceProtocol {
    func getProperty() -> AnyPublisher<GenericModel<[PropertyItem]?>, Error>
}
class PropertyService: PropertyServiceProtocol {
    let apiClient = URLSessionAPIClient<AppEndPoint>()
    func getProperty() -> AnyPublisher<GenericModel<[PropertyItem]?>, Error> {
        return apiClient.request(.getProperty)
    }
}

class HomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var items: [String] = []
    @Published private var propertyApiResponse: GenericModel<[PropertyItem]?>?
    @Published var propertyResponse: [PropertyItem]?
    let propertyService: PropertyServiceProtocol
    private var currentPage = 0
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    
    init(propertyService: PropertyServiceProtocol) {
        self.propertyService = propertyService
    }
    
    func loadMoreData() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simulate data appending
            let start = self.currentPage * self.pageSize + 1
            let end = start + self.pageSize
            let newItems = (start..<end).map { "Item \($0)" }
            
            self.items.append(contentsOf: newItems)
            self.currentPage += 1
            self.isLoading = false
        }
    }
    
    func clearFilter() {
        items.removeAll()
        currentPage = 0
    }
    
    func getPropertyList() {
        propertyService.getProperty()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { data in
                
            }, receiveValue: {[weak self] data in
                guard let weakSelf = self else {return}
                weakSelf.propertyApiResponse = data
                if let response = weakSelf.propertyApiResponse?.response {
                    weakSelf.propertyResponse = response
                } else {
                    weakSelf.errorMessage = data.message
                }
                weakSelf.isLoading = false
            }).store(in: &cancellables)
    }
}
