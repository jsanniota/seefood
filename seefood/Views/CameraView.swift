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
                
                Button("Analyze Food") {
                    // TODO: Implement food analysis
                }
                .buttonStyle(.borderedProminent)
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