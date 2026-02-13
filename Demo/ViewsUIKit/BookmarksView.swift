//
//  BookmarksView.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import SwiftUI

struct BookmarksView: UIViewControllerRepresentable {
    let viewModel: NewsViewModel
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let bookmarksVC = BookmarksViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: bookmarksVC)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
