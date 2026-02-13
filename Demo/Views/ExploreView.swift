//
//  ExploreView.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//


import SwiftUI

struct ExploreView: View {
    @State private var cityName: String = "Dubai"
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Header
                    VStack(spacing: Spacing.lg) {
                        HStack(spacing: 4) {
                            Text("Explore")
                                .font(.title3.bold())
                            
                            Menu {
                                Button("Dubai", action: {
                                    cityName = "Dubai"
                                })
                                Button("Abu Dhabi", action: {
                                    cityName = "Abu Dhabi"
                                })
                            } label: {
                                HStack {
                                    Text(cityName)
                                        .foregroundColor(.purple)
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.purple)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        ImageTitle()
                            .padding(.top, 8)
                        
                        Text("Explore property prices, community and residential insights, to make informed decisions when buying or renting property in UAE.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    // Cards
                    VStack(spacing: 16) {
                        ExploreCardView(
                            imageName: "construction",
                            title: "New projects",
                            subtitle: "Are you looking for new and upcoming properties? View all new projects in the UAE."
                        )
                        
                        ExploreCardView(
                            imageName: "document",
                            title: "Historical transactions",
                            subtitle: "View transaction records in any location of Dubai."
                        )
                        
                        ExploreCardView(
                            imageName: "price_map",
                            title: "Price map",
                            subtitle: "Not sure in which area you can afford to rent or buy? View the prices by different areas."
                        )
                        
                        ExploreCardView(
                            imageName: "cloud_analysis",
                            title: "Community Insights",
                            subtitle: "View ratings, safety, noise, family friendliness and more for each community."
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .background(Color(UIColor.systemGray6))
            .navigationBarHidden(true)
        }
    }
}
#Preview {
    ExploreView()
}

struct ExploreCardView: View {
    var imageName: String
    var title: String
    var subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .padding(.top, 6)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
struct ImageTitle: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("DataGuru")
                .font(.title2.bold())
            
            Image(systemName: "lightbulb.max")
                .foregroundColor(.red)
        }
    }
}

