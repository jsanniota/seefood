import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        VStack {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                
                VStack {
                    if viewModel.isAnalyzing {
                        ProgressView("Analyzing food...")
                    } else if let analysis = viewModel.mealAnalysis {
                        AnalysisResultView(analysis: analysis)
                    } else {
                        Button("Analyze Food") {
                            viewModel.encodeImage()
                            viewModel.analyzeFoodImage()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            
            HStack(spacing: 20) {
                Button("Scan Food") {
                    viewModel.sourceType = .camera
                    viewModel.checkCameraPermission()
                }
                .buttonStyle(.bordered)
                
                Button("Choose Photo") {
                    viewModel.sourceType = .photoLibrary
                    viewModel.showImagePicker = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage,
                       sourceType: viewModel.sourceType)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct AnalysisResultView: View {
    let analysis: MealAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Total Calories: \(Int(analysis.totalCalories))")
                .font(.headline)
            
            Text("Ingredients:")
                .font(.headline)
            
            ForEach(analysis.ingredients) { ingredient in
                HStack {
                    Text(ingredient.name)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(Int(ingredient.calories)) cal")
                        Text("P: \(Int(ingredient.protein))g C: \(Int(ingredient.carbs))g F: \(Int(ingredient.fat))g")
                            .font(.caption)
                    }
                }
            }
            
            Text("Confidence: \(Int(analysis.confidenceScore * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// ImagePicker using UIViewControllerRepresentable
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    CameraView()
} 