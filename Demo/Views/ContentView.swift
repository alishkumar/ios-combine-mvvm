//
//  ContentView.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var newsViewModel = NewsViewModel(newsService: NewsService(), modelContext: nil)
    
    var body: some View {
        TabView {
            NewsView(viewModel: newsViewModel)
                .tabItem {
                    Label("News", systemImage: "newspaper")
                }
            BookmarksView(viewModel: newsViewModel)
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark")
                }

            HomeView()
                .navigationTitle("Home")
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }            
                        
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "binoculars")
                }
            
            ProfileView()
                .tabItem {
                    Label("My Account", systemImage: "person")
                }
        }
        .preferredColorScheme(.light)
        .onAppear {
            newsViewModel.updateModelContext(modelContext)
        }
    }
}

#Preview {
    ContentView()
}
