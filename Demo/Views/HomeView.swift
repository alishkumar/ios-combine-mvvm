//
//  HomeView.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//


import SwiftUI
struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel(propertyService: PropertyService())
    @State private var isPresenting: Bool = false
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBarView()
                FilterBarView(isPresenting: $isPresenting)
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.items, id: \.self) { item in
                            PropertyCardView()
                                .onAppear {
                                    if item == viewModel.items.last {
                                        viewModel.loadMoreData()
                                    }
                                }
                        }
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
            .sheet(isPresented: $isPresenting) {
                SheetView()
            }
            .navigationBarHidden(true)
        }
        .onAppear() {
            viewModel.loadMoreData()
        }
    }
}
#Preview {
    HomeView()
}

struct SearchBarView: View {
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("City, area or building", text: .constant(""))
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
    }
}

struct FilterBarView: View {
    @Binding var isPresenting: Bool
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(title: "Rent", isNew: true)
                    .onTapGesture {
                        isPresenting = true
                    }
                FilterChip(title: "Property Type")
                FilterChip(title: "Price")
                FilterChip(title: "Beds")
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChip: View {
    var title: String
    var isNew: Bool = false
    
    var body: some View {
        ZStack {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "chevron.down")
            }
            .padding(8)
            .background(Color(.systemGray5))
            .cornerRadius(8)
            if isNew {
                Text("NEW")
                    .font(.caption2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(.bottom, 36)
                    .padding(.leading, 60)
            }
        }
    }
}

struct PropertyCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                TabView {
                    ForEach(1..<5) { index in
                        AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&q=80")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(height: 220)
                        .cornerRadius(12)
                        .clipped()
                    }
                }
                .frame(height: 200)
                .tabViewStyle(PageTabViewStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Badge(text: "VERIFIED", color: .green)
                    Badge(text: "SUPERAGENT", color: .accent)
                }
                .padding([.top, .leading], 8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Villa")
                    .font(.headline)
                Text("26,00,000 AED/year")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Cluster 10, Jumeirah Islands, Dubai")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    Label("4", systemImage: "bed.double.fill")
                    Label("5", systemImage: "shower.fill")
                    Label("817 m²", systemImage: "ruler.fill")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            
            Divider()
            
            HStack {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .renderingMode(.template)
                            .foregroundColor(Color.accentColor)
                        Text("Call")
                            .foregroundColor(Color.accentColor)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.background)
                    .cornerRadius(8)
                }
                Button(action: {}) {
                    HStack {
                        Image(systemName: "message.fill")
                            .renderingMode(.template)
                            .foregroundColor(Color.accentColor)
                        Text("WhatsApp")
                            .foregroundColor(Color.accentColor)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.background)
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
            .padding([.horizontal, .bottom], 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 4)
    }
}

struct Badge: View {
    var text: String
    var color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}
