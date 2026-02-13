//
//  PrimaryButton.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//


import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appFont(.headline))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.App.primary)
                .cornerRadius(12)
        }
    }
}
