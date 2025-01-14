1. Project Overview
App Name: SeeFood

Description:
SeeFood is an iOS application that lets users take a photo of a meal and automatically analyzes the contents (e.g., ingredients, estimated calories, macros) using a multimodal AI model (OpenAI GPT-4.0 mini with JSON Schema). Users can then edit results and view daily consumption history.

Objectives:

Automate food tracking by leveraging an AI image recognition service.
Present comprehensive daily totals (calories, carbs, protein, fat).
Provide manual corrections to improve accuracy and user control.
Target Platform: iOS 16+

2. Features
Take a Picture

Capture/confirm images from the device’s camera or photo library.
Analyze Food

Convert the image to a base64 string, send it to GPT-4.0 mini, parse the structured JSON response, and show detected ingredients.
Let the user edit or add missing items, recalculate totals.
Daily History View

Show prior logs with total daily calories/macros.
Allow navigation by date, detailing each meal’s breakdown.
3. Requirements for Each Feature
3.1. Take a Picture
Functional Requirements

Camera/Photo Library: Prompt the user to snap a photo or select from library.
Permissions: Handle NSCameraUsageDescription and photo library permissions.
Image Handling: Convert the final selected image to base64 for the API call.
Technical Details

Dependencies: AVFoundation (camera), UIImagePickerController or SwiftUI PhotosPicker, plus Info.plist usage strings.
Variables:
selectedImage: UIImage?
encodedImageData: String (base64 encoded)
Edge Cases

Permission denied.
User cancels the flow.
3.2. Analyze Food
Functional Requirements

Send Request: Once an image is selected, encode it as base64 (data:image/png;base64,...) and POST to the GPT-4.0 mini endpoint.
Structured Response: Parse the JSON response (meal_analysis) to get:
A list of ingredients, each with calories, macros, and confidence.
totalCalories, timestamp, and confidenceScore.
User Edits: Provide an interface for modifying ingredient details.
Recalculation: Dynamically recalc totals if the user changes macros/calories.
Technical Details

Networking: Use URLSession or Alamofire.
JSON Parsing: Implement Swift Codable with the MealAnalysis and Ingredient models.
Variables:
mealAnalysis: MealAnalysis? – an in-memory object.
Edge Cases

Network failure, or empty AI response.
Low confidence results or no ingredients returned.
3.3. Daily History View
Functional Requirements

Daily Log: For a selected date, show total daily macros and each meal.
Meal Detail: Tap on a meal to see its ingredients.
Date Navigation: Switch between days.
Technical Details

Data Storage: Could use Core Data / SQLite or a cloud store (e.g., Firebase).
UI: SwiftUI List or ScrollView with a daily summary view.
Edge Cases

No meals on a given day → display an empty state.
4. Data Models
4.1. MealAnalysis
swift
Copy code
struct MealAnalysis: Codable {
    let ingredients: [Ingredient]
    let totalCalories: Double
    let timestamp: String
    let confidenceScore: Double
}
4.2. Ingredient
swift
Copy code
struct Ingredient: Codable, Identifiable {
    let id: String
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let confidence: Double
}
4.3. DailyLog
swift
Copy code
struct DailyLog: Codable {
    let date: String // "YYYY-MM-DD"
    var meals: [MealAnalysis]
    var totalCalories: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
}
5. API Contract
We are using OpenAI GPT-4.0 mini with structured output based on a JSON Schema. Below is the updated request and response including the exact final JSON you provided.

5.1. Endpoint: https://api.openai.com/v1/chat/completions
Method: POST

Headers:

http
Copy code
Content-Type: application/json
Authorization: Bearer <OPENAI_API_KEY>
Request Body (JSON):

jsonc
Copy code
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "image_url",
          "image_url": {
            // Base64-encoded image
            "url": "data:image/png;base64,<ENCODED_IMAGE_STRING>"
          }
        },
        {
          "type": "text",
          "text": ""
        }
      ]
    }
  ],
  "response_format": {
    "type": "json_schema",
    "json_schema": {
      "name": "analyze_meal",
      "strict": true,
      "schema": {
        "type": "object",
        "properties": {
          "meal_analysis": {
            "type": "object",
            "description": "Contains details about the analysis of a meal.",
            "properties": {
              "ingredients": {
                "type": "array",
                "description": "Array of detected ingredients or user-modified list.",
                "items": {
                  "$ref": "#/$defs/ingredient"
                }
              },
              "totalCalories": {
                "type": "number",
                "description": "Sum of all ingredient calories."
              },
              "timestamp": {
                "type": "string",
                "description": "Timestamp of when the meal was analyzed."
              },
              "confidenceScore": {
                "type": "number",
                "description": "Overall confidence for the recognized meal."
              }
            },
            "required": [
              "ingredients",
              "totalCalories",
              "timestamp",
              "confidenceScore"
            ],
            "additionalProperties": false
          }
        },
        "$defs": {
          "ingredient": {
            "type": "object",
            "description": "Details about a specific ingredient detected in the meal.",
            "properties": {
              "id": {
                "type": "string",
                "description": "Unique ID for the ingredient."
              },
              "name": {
                "type": "string",
                "description": "Name of the ingredient."
              },
              "calories": {
                "type": "number",
                "description": "Number of calories for the quantity detected."
              },
              "protein": {
                "type": "number",
                "description": "Estimated grams of protein."
              },
              "carbs": {
                "type": "number",
                "description": "Estimated grams of carbohydrates."
              },
              "fat": {
                "type": "number",
                "description": "Estimated grams of fat."
              },
              "confidence": {
                "type": "number",
                "description": "Confidence score for this ingredient’s identification."
              }
            },
            "required": [
              "id",
              "name",
              "calories",
              "protein",
              "carbs",
              "fat",
              "confidence"
            ],
            "additionalProperties": false
          }
        },
        "required": [
          "meal_analysis"
        ],
        "additionalProperties": false
      }
    }
  },
  "temperature": 1,
  "max_completion_tokens": 2048,
  "top_p": 1,
  "frequency_penalty": 0,
  "presence_penalty": 0
}
Example cURL
bash
Copy code
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "image_url",
            "image_url": {
              "url": "data:image/png;base64,<ENCODED_IMAGE_STRING>"
            }
          },
          {
            "type": "text",
            "text": ""
          }
        ]
      }
    ],
    "response_format": {
      "type": "json_schema",
      "json_schema": {
        "name": "analyze_meal",
        "strict": true,
        "schema": {
          "type": "object",
          "properties": {
            "meal_analysis": {
              "type": "object",
              "description": "Contains details about the analysis of a meal.",
              "properties": {
                "ingredients": {
                  "type": "array",
                  "description": "Array of detected ingredients or user-modified list.",
                  "items": {
                    "$ref": "#/$defs/ingredient"
                  }
                },
                "totalCalories": {
                  "type": "number",
                  "description": "Sum of all ingredient calories."
                },
                "timestamp": {
                  "type": "string",
                  "description": "Timestamp of when the meal was analyzed."
                },
                "confidenceScore": {
                  "type": "number",
                  "description": "Overall confidence for the recognized meal."
                }
              },
              "required": [
                "ingredients",
                "totalCalories",
                "timestamp",
                "confidenceScore"
              ],
              "additionalProperties": false
            }
          },
          "$defs": {
            "ingredient": {
              "type": "object",
              "description": "Details about a specific ingredient detected in the meal.",
              "properties": {
                "id": {
                  "type": "string",
                  "description": "Unique ID for the ingredient."
                },
                "name": {
                  "type": "string",
                  "description": "Name of the ingredient."
                },
                "calories": {
                  "type": "number",
                  "description": "Number of calories for the quantity detected."
                },
                "protein": {
                  "type": "number",
                  "description": "Estimated grams of protein."
                },
                "carbs": {
                  "type": "number",
                  "description": "Estimated grams of carbohydrates."
                },
                "fat": {
                  "type": "number",
                  "description": "Estimated grams of fat."
                },
                "confidence": {
                  "type": "number",
                  "description": "Confidence score for this ingredient’s identification."
                }
              },
              "required": [
                "id",
                "name",
                "calories",
                "protein",
                "carbs",
                "fat",
                "confidence"
              ],
              "additionalProperties": false
            }
          },
          "required": [
            "meal_analysis"
          ],
          "additionalProperties": false
        }
      }
    },
    "temperature": 1,
    "max_completion_tokens": 2048,
    "top_p": 1,
    "frequency_penalty": 0,
    "presence_penalty": 0
  }'
5.2. Example Response (Latest)
Below is the final JSON output returned by GPT-4.0 mini for an example breakfast image:

json
Copy code
{
  "meal_analysis": {
    "ingredients": [
      {
        "id": "1",
        "name": "French toast",
        "calories": 300,
        "protein": 10,
        "carbs": 45,
        "fat": 10,
        "confidence": 0.8
      },
      {
        "id": "2",
        "name": "strawberries",
        "calories": 30,
        "protein": 0.6,
        "carbs": 7,
        "fat": 0.3,
        "confidence": 0.9
      },
      {
        "id": "3",
        "name": "blueberries",
        "calories": 20,
        "protein": 0.3,
        "carbs": 5,
        "fat": 0.1,
        "confidence": 0.9
      },
      {
        "id": "4",
        "name": "banana",
        "calories": 90,
        "protein": 1.1,
        "carbs": 23,
        "fat": 0.3,
        "confidence": 0.8
      },
      {
        "id": "5",
        "name": "pistachios",
        "calories": 170,
        "protein": 6,
        "carbs": 8,
        "fat": 14,
        "confidence": 0.7
      },
      {
        "id": "6",
        "name": "yogurt",
        "calories": 100,
        "protein": 5,
        "carbs": 10,
        "fat": 5,
        "confidence": 0.8
      },
      {
        "id": "7",
        "name": "maple syrup",
        "calories": 50,
        "protein": 0,
        "carbs": 13,
        "fat": 0,
        "confidence": 0.7
      },
      {
        "id": "8",
        "name": "powdered sugar",
        "calories": 30,
        "protein": 0,
        "carbs": 8,
        "fat": 0,
        "confidence": 0.7
      }
    ],
    "totalCalories": 790,
    "timestamp": "2023-10-06T12:00:00Z",
    "confidenceScore": 0.85
  }
}
Key Points

The ingredients array lists each recognized food component with estimated macros (calories, protein, carbs, fat) and a confidence score.
totalCalories represents the sum of all ingredient calories (790).
A timestamp indicates when the meal was analyzed, and confidenceScore gives an overall recognition confidence (0.85).
6. Additional Notes & Considerations
Integration Flow:
Capture the image → Base64 encode → Send to GPT-4.0 mini → Parse JSON → Display to user → Let user modify if needed.
Data Validation:
Ensure the AI response adheres to the schema. If the JSON is malformed, handle gracefully (e.g., show an error).
Data Persistence:
Store the final, user-approved MealAnalysis in local or cloud storage.
Performance:
Compress images to reduce network overhead.
Cache results to avoid re-calling the model for the same photo if reselected.