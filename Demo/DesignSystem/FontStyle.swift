//
//  FontStyle.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//


import SwiftUI

enum FontStyle {
    case largeTitle
    case title
    case title2
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
}

extension Font {
    static func appFont(_ style: FontStyle) -> Font {
        switch style {
        case .largeTitle:
            return .system(size: 34, weight: .bold, design: .default)
        case .title:
            return .system(size: 28, weight: .semibold, design: .default)
        case .title2:
            return .system(size: 22, weight: .semibold, design: .default)
        case .headline:
            return .system(size: 18, weight: .semibold, design: .default)
        case .body:
            return .system(size: 16, weight: .regular, design: .default)
        case .callout:
            return .system(size: 14, weight: .medium, design: .default)
        case .subheadline:
            return .system(size: 14, weight: .regular, design: .default)
        case .footnote:
            return .system(size: 12, weight: .medium, design: .default)
        case .caption:
            return .system(size: 12, weight: .regular, design: .default)
        }
    }
}
