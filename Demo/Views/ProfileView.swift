//
//  ProfileView.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//


import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Text("My Account")
                    .font(.title2.bold())
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Login Prompt
                        LoginCard()
                        
                        // Settings
                        SettingsCard()
                        
                        // Find an Agent
                        NavigationLink(destination: Text("Find an Agent View")) {
                            IconRow(icon: "person.3.fill", label: "Find an agent")
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // About, Rate Us, Help
                        VStack(spacing: 0) {
                            NavigationLinkRow(icon: "info.circle", label: "About")
                            Divider()
                            NavigationLinkRow(icon: "message", label: "Rate us")
                            Divider()
                            NavigationLinkRow(icon: "questionmark.circle", label: "Need help?")
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Sign up / Log In Button
                Button(action: {
                    // Handle login
                }) {
                    Text("Sign up / Log In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding([.horizontal, .bottom])
            }
            .background(Color(UIColor.systemGray6).ignoresSafeArea())
        }
    }
}

#Preview {
    ProfileView()
}

struct LoginCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text("Sign up / Log In")
                    .foregroundColor(.accent)
                    .font(.headline)
                
                Text("Save searches, sync saved properties, and more.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct SettingsCard: View {
    var body: some View {
        VStack(spacing: 0) {
            NavigationLinkRow(icon: "textformat.size", label: "Language", value: "English")
            Divider()
            NavigationLinkRow(icon: "globe", label: "Country", value: "United Arab Emirates")
            Divider()
            NavigationLinkRow(icon: "ruler", label: "Measurement system", value: "Metric")
            Divider()
            NavigationLinkRow(icon: "bell", label: "Notifications")
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct NavigationLinkRow: View {
    var icon: String
    var label: String
    var value: String? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accent)
                .frame(width: 24)
            
            Text(label)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct IconRow: View {
    var icon: String
    var label: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accent)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
    }
}
