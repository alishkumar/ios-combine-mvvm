//
//  ProfileViewModel.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//


import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func getProfile() {
        isLoading = true
        errorMessage = nil
    }
}
