import Foundation

struct APIResponse: Codable {
    let meal_analysis: MealAnalysis
}

struct MealAnalysis: Codable {
    let ingredients: [Ingredient]
    let totalCalories: Double
    let timestamp: String
    let confidenceScore: Double
}

struct Ingredient: Codable, Identifiable {
    let id: String
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let confidence: Double
} 