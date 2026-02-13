
# instruction.md

## App Name
CalorieCam (AI Food Analyzer)

## Purpose
Take a photo of food → Analyze with OpenAI Vision → Get ingredients + calories → Edit → Save to history.

## Core Features
- Camera capture (using SwiftUI + UIKit bridge)
- Image analysis via OpenAI Vision API
- Parsed JSON → [FoodItem] model
- Editable ingredient list with live calorie total
- History log with date grouping
- MVVM architecture
- AI-assisted development with Cursor and SweetPad

## Data Models

### FoodItem
```swift
struct FoodItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var calories: Int
}
