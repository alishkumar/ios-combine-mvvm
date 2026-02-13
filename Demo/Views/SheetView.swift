//
//  SheetView.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//
import SwiftUI

struct SheetView: View {
    
    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                // Search Alerts Tab
                VStack(alignment: .leading, spacing: 16) {
                    Text("Rent Sheet Screen")
                        .foregroundColor(Color.accent)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}
