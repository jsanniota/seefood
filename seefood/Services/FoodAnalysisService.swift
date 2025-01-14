import Foundation

// Rule applied: Debug logs
class FoodAnalysisService {
    private let apiKey = Secrets.openAIKey
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    private func log(_ message: String) {
        #if DEBUG
        print("🍽️ FoodAnalysisService: \(message)")
        #endif
    }
    
    func analyzeFood(imageBase64: String) async throws -> MealAnalysis {
        log("Preparing request with image size: \(imageBase64.count) characters")
        
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "meal_analysis": [
                    "type": "object",
                    "description": "Contains details about the analysis of a meal.",
                    "properties": [
                        "ingredients": [
                            "type": "array",
                            "description": "Array of detected ingredients or user-modified list.",
                            "items": [
                                "$ref": "#/$defs/ingredient"
                            ]
                        ],
                        "totalCalories": [
                            "type": "number",
                            "description": "Sum of all ingredient calories."
                        ],
                        "timestamp": [
                            "type": "string",
                            "description": "Timestamp of when the meal was analyzed."
                        ],
                        "confidenceScore": [
                            "type": "number",
                            "description": "Overall confidence for the recognized meal."
                        ]
                    ],
                    "required": ["ingredients", "totalCalories", "timestamp", "confidenceScore"],
                    "additionalProperties": false
                ]
            ],
            "$defs": [
                "ingredient": [
                    "type": "object",
                    "description": "Details about a specific ingredient detected in the meal.",
                    "properties": [
                        "id": [
                            "type": "string",
                            "description": "Unique ID for the ingredient."
                        ],
                        "name": [
                            "type": "string",
                            "description": "Name of the ingredient."
                        ],
                        "calories": [
                            "type": "number",
                            "description": "Number of calories for the quantity detected."
                        ],
                        "protein": [
                            "type": "number",
                            "description": "Estimated grams of protein."
                        ],
                        "carbs": [
                            "type": "number",
                            "description": "Estimated grams of carbohydrates."
                        ],
                        "fat": [
                            "type": "number",
                            "description": "Estimated grams of fat."
                        ],
                        "confidence": [
                            "type": "number",
                            "description": "Confidence score for this ingredient's identification."
                        ]
                    ],
                    "required": ["id", "name", "calories", "protein", "carbs", "fat", "confidence"],
                    "additionalProperties": false
                ]
            ],
            "required": ["meal_analysis"],
            "additionalProperties": false
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(imageBase64)"
                            ]
                        ],
                        [
                            "type": "text",
                            "text": "Analyze this food image and provide nutritional information."
                        ]
                    ]
                ]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "analyze_meal",
                    "strict": true,
                    "schema": schema
                ]
            ],
            "max_tokens": 4096,
            "temperature": 1,
            "top_p": 1,
            "frequency_penalty": 0,
            "presence_penalty": 0
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            log("Request body prepared successfully")
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                log("Request JSON: \(jsonString)")
            }
        } catch {
            log("Error preparing request body: \(error)")
            throw error
        }
        
        log("Sending request to OpenAI API...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            log("Received response with status code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                log("Response body: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                log("Error: Invalid response status code")
                throw URLError(.badServerResponse)
            }
        }
        
        do {
            // First decode the outer response structure
            struct ChatResponse: Codable {
                struct Choice: Codable {
                    struct Message: Codable {
                        let content: String
                    }
                    let message: Message
                }
                let choices: [Choice]
            }
            
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            log("Successfully decoded chat response")
            
            // Then decode the content string which contains our meal analysis
            if let contentData = chatResponse.choices.first?.message.content.data(using: .utf8) {
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: contentData)
                log("Successfully decoded meal analysis from content")
                return apiResponse.meal_analysis
            } else {
                log("Error: Could not get content data")
                throw URLError(.cannotDecodeContentData)
            }
        } catch {
            log("Error decoding response: \(error)")
            throw error
        }
    }
} 