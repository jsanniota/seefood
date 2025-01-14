import SwiftUI
import AVFoundation

// Rule applied: Debug logs
class CameraViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var showImagePicker = false
    @Published var sourceType: UIImagePickerController.SourceType = .camera
    @Published var encodedImageData: String = ""
    @Published var isAnalyzing = false
    @Published var mealAnalysis: MealAnalysis?
    @Published var errorMessage: String?
    
    private let analysisService = FoodAnalysisService()
    
    // Debug logging function
    private func log(_ message: String) {
        #if DEBUG
        print("📸 CameraViewModel: \(message)")
        #endif
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            log("Camera access authorized")
            showImagePicker = true
        case .notDetermined:
            log("Requesting camera permission")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.log("Camera permission granted")
                        self?.showImagePicker = true
                    } else {
                        self?.log("Camera permission denied")
                    }
                }
            }
        case .denied, .restricted:
            log("Camera access denied or restricted")
            // Handle showing alert to user about camera access
        @unknown default:
            break
        }
    }
    
    func encodeImage() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.7) else {
            log("Failed to encode image")
            return
        }
        
        encodedImageData = imageData.base64EncodedString()
        log("Image successfully encoded to base64")
    }
    
    @MainActor
    func analyzeFoodImage() {
        guard !encodedImageData.isEmpty else {
            log("No image data to analyze")
            return
        }
        
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                mealAnalysis = try await analysisService.analyzeFood(imageBase64: encodedImageData)
                log("Analysis completed successfully")
            } catch {
                errorMessage = "Failed to analyze food: \(error.localizedDescription)"
                log("Analysis failed: \(error)")
            }
            isAnalyzing = false
        }
    }
} 