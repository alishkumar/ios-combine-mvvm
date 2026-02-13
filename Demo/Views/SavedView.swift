//
//  SavedView.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//


import SwiftUI

struct SavedView: View {
    @State private var selectedTab = 0
    private let tabs = ["Saved properties", "Search alerts"]
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    var body: some View {
        VStack(spacing: 16) {
            // Segmented Control
            Picker("", selection: $selectedTab) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Text(tabs[index])
                        .tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            ScrollView {
                if selectedTab == 0 {
                    // Saved Properties Tab
                    LazyVGrid(columns: columns, spacing: 16) {
                        CreateListCard()
                    }
                    .padding()
                } else {
                    // Search Alerts Tab
                    VStack(alignment: .leading, spacing: 16) {
                        Text("No search alerts yet.")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                }
            }
        }
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}
#Preview {
    SavedView()
}


struct CreateListCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("+")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.purple)
            
            Text("Create a new list")
                .foregroundColor(.purple)
                .font(.body)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
