//
//  NewsView.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import SwiftUI

struct NewsView: UIViewControllerRepresentable {
    let viewModel: NewsViewModel
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let newsVC = NewsListViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: newsVC)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
